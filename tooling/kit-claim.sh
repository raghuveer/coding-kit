#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-claim.sh --vocab                           prints the accepted vocabularies
# kit-claim.sh --contract                        prints the shape of a claim
# kit-claim.sh --census ID --unit NAME --json    captures one auditor reply, VERBATIM
#
# THE VOCABULARY HOME FOR A CENSUS CLAIM. A claim is not a finding and must never be recorded
# as one. A finding says "this code is defective". A claim says "this document asserts X; the
# tree says Y". The subject of a finding is code; the subject of a claim is a CLAIM. Recording
# roadmap assertions in the `finding` table would flood the criticals gate with rows that are
# not defects -- see T-20260826-a-verified-claim-about-the-tree-has-no-a.
#
# ARTEFACT CAPTURE IS STEP 1, AND IT DELIBERATELY DOES NOT VALIDATE. The store's own sequence
# puts capture first and derivation second, as separate commits, and says of step 1: "Durability
# is complete at this step and nothing is locked in." F12 is why validation is not here: "The raw
# reply is saved BEFORE validation, so a unit that fails validation still has its data." A capture
# that refused a malformed reply would lose the ~35k BTE that produced it, which is the loss this
# store exists to stop. So the bytes on stdin are written unexamined.
#
# MANIFEST CREATION IS NOT IMPLEMENTED HERE, AND THAT IS THE DESIGN RATHER THAN AN OMISSION.
# Step 1 is "writes the reply verbatim ... AFTER manifest creation". census_id is allocated by the
# operator when a census begins, and D4's `purpose` "must be a recorded field set by the operator"
# because nothing in the tree can compute it. So this command REFUSES when the manifest is absent
# and prints the shape it needs, rather than inventing a census on the operator's behalf. F1c
# requires the same of an undeclared unit -- "refused rather than created" -- because intake
# choosing a plausible name and SUCCEEDING is the failure mode here, not intake crashing.
#
# THE STORE ITSELF STILL RECORDS NOTHING, AND THAT IS DELIBERATE. It answers "what may an
# auditor send you" and nothing else. The store -- table, intake, `kit-status.sh` reporting,
# census-to-census diffing -- is T-20260826-a-verified-claim-about-the-tree-has-no-a, which is
# `blocked_by` the contract this file serves. Building the store first would fit the schema to
# whatever one hand-written prompt happened to emit; that is the mistake this ordering exists to
# prevent. When the store lands it extends THIS script rather than adding a second door, exactly
# as `kit-finding.sh` holds both its vocabulary and its intake.
#
# WHY A SCRIPT AT ALL, WHEN NOTHING HERE IS EXECUTED BY AN AGENT. Agents have no Bash -- see
# `tools:` in every agent's frontmatter -- so `claim-auditor` cannot run `--vocab` and the list
# is inlined in its instructions. Inlining is the only form an agent can use, and it is exactly
# the duplication that already bit once: the FINDING vocabulary was restated in the schema
# comment, in two skills and in three agent contracts, all four drifted, and the agents emitted
# values the recorder rejected outright, so most findings never recorded. The lesson taken was
# not "stop inlining" but "inline against one printed home, and check the copies". This file is
# that home; `tests/conformance.sh` is that check.
set -uo pipefail

# ---- the one definition -----------------------------------------------------------------------
#
# VERDICTS. These five are not invented here: they are the vocabulary two reconciliation runs
# actually used, on highper-gateway (303 claims) and aeon (489 claims). A vocabulary its own
# producers do not use is a vocabulary that silently discards their output.
#
#   CONFIRMED       the document's assertion holds against the tree
#   STALE-CITATION  the assertion is true but its cited location has moved or gone
#   OVERSTATED      the tree does less than the document claims
#   UNDERSTATED     the tree does more than the document claims
#   UNVERIFIABLE    the claim cannot be checked from this checkout, with a stated reason
#
# UNDERSTATED earns its place rather than being symmetry for its own sake: 31 of 303 and 14 of
# 489 claims came back understated across the two runs. A four-verdict vocabulary would have
# forced 45 real observations into CONFIRMED and lost the fact that the document undersells the
# code -- which is the one class of drift a reader would otherwise never go looking for.
#
# UNVERIFIABLE IS A FIRST-CLASS VERDICT, NOT AN ABSENCE. The 2026-08-26 run needed it on its
# first subject: `src/ha` and `src/health` are described as "empty directories", git cannot track
# an empty directory, and so the claim is unobservable from a clone. A vocabulary that forces a
# true/false answer there does not get silence -- it gets a manufactured verdict, which is worse
# than a gap because nothing marks it as one. 64 of aeon's 489 claims landed here.
VERDICTS="CONFIRMED STALE-CITATION OVERSTATED UNDERSTATED UNVERIFIABLE"

# LOCATION PROVENANCE. Whether the auditor re-derived the location itself or copied it out of the
# document under audit. This is a separate axis from the verdict and it is not decoration: on the
# 2026-08-26 subject a `cargo fmt --all` had invalidated every line citation in the roadmap six
# hours after it was written. An auditor that copies locations produces a census whose evidence
# column is unusable the moment the tree is reformatted, and nothing downstream can tell which
# rows are safe. Recording the provenance makes that answerable instead of assumed.
LOCATIONS="RE-DERIVED COPIED"

case "${1:-}" in
  --vocab)
    printf 'verdict:  %s\nlocation: %s\n' "$VERDICTS" "$LOCATIONS"; exit 0 ;;
  --contract)
    cat <<'CONTRACT'
A claim-auditor returns ONE JSON object:

{
  "source":  "docs/ROADMAP.md",       the document audited
  "subject": "UC4 API GW ratelimit",  the unit within it (phase, use case, section)
  "narrative": "markdown ...",        everything a human reads
  "claims": [
    {
      "claim":      "one line, <=200 chars, what the document asserts",
      "source_loc": "docs/ROADMAP.md:412",     where the assertion is written
      "verdict":    "OVERSTATED",              from the verdict vocabulary
      "location":   "RE-DERIVED",              from the location vocabulary
      "evidence":   "src/ratelimit/mod.rs:88", where the tree answers
      "note":       "why, in one line"
    }
  ]
}

REQUIRED on every claim: claim, source_loc, verdict, location.
  evidence  REQUIRED unless verdict is UNVERIFIABLE -- there is nothing to point at.
  note      REQUIRED when verdict is UNVERIFIABLE  -- the reason is the whole content of
            that verdict, and without it the row is indistinguishable from an agent that
            gave up.

"claims": [] is a MEASUREMENT and is accepted. Omitting the key is a different statement
and is rejected -- the same rule findings already follow, for the same reason: an absent
list and an empty list mean different things and only one of them is a result.

Validation is ALL OR NONE. One bad value and the batch records nothing, because a
half-stored census is a table that disagrees with the audit it came from.
CONTRACT
    exit 0 ;;
esac

# ---- artefact capture, step 1 ---------------------------------------------------------------
case "${1:-}" in
  --census|--unit|--json)
  . "$(dirname "$0")/kit-lib.sh"
  ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 1; }
  kit_active "$ROOT" || { kit_warn "kit not adopted here (no .claude/project-profile.md)"; exit 1; }
  PROFILE=$(kit_profile "$ROOT")
  STATE_DIR=$(kit_cfg "$PROFILE" paths.state ".project")

  census=""; unit=""; want_json=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --census) census=${2:-}; shift; shift ;;
      --unit)   unit=${2:-};   shift; shift ;;
      --json)   want_json=1; shift ;;
      *) kit_warn "unknown argument: $1"; exit 2 ;;
    esac
  done
  [ -n "$census" ] || { kit_warn "--census ID is required"; exit 2; }
  [ -n "$unit" ]   || { kit_warn "--unit NAME is required"; exit 2; }
  [ "$want_json" = 1 ] || { kit_warn "--json is required: the reply is read from stdin"; exit 2; }

  # F1b. Both become PATH COMPONENTS and, under D5, part of the committed identity a disposition
  # references -- so a bad value is not an ugly directory, it is a forged anchor that outlives the
  # run. Refused, never rewritten, for the reason kit-plan.sh gives about goal ids: a silently
  # rewritten id is a second name for the operator's census.
  #
  # THE CHARSET ALONE IS NOT ENOUGH, and that was measured rather than assumed. kit-plan.sh's
  # [A-Za-z0-9._-] includes the dot, so `.` and `..` pass it -- verified against its own pattern
  # on 2026-09-08. Either would resolve the census directory to its own parent, so both are
  # refused as whole values in addition to the charset.
  for _pair in "census:$census" "unit:$unit"; do
    _n=${_pair%%:*}; _v=${_pair#*:}
    case "$_v" in
      ''|*[!A-Za-z0-9._-]*)
        kit_warn "--$_n must contain only letters, digits, dot, underscore or hyphen: '$_v'"
        kit_warn "  It becomes a directory name and, under D5, part of a committed record, so it"
        kit_warn "  is refused rather than rewritten into a second name for the same census."
        exit 2 ;;
    esac
    case "$_v" in
      .|..)
        kit_warn "--$_n may not be '.' or '..': '$_v'"
        kit_warn "  The charset admits both, and either resolves the census directory to its own"
        kit_warn "  parent. Refused."
        exit 2 ;;
    esac
  done

  CDIR="$ROOT/$STATE_DIR/census/$census"
  MAN="$CDIR/manifest.json"
  if [ ! -f "$MAN" ]; then
    kit_warn "no manifest at ${MAN#$ROOT/} -- a census is not created by capturing into it"
    kit_warn "  Step 1 writes a reply AFTER manifest creation. census_id is allocated by the"
    kit_warn "  operator, and D4's purpose cannot be derived from the tree, so this refuses"
    kit_warn "  rather than inventing a census. The manifest must carry at least:"
    kit_warn '    { "purpose": "<why this census exists>", "units": ["<unit>", ...] }'
    exit 1
  fi

  # The manifest is read by python3, which is already a dependency of this repository's WRITE
  # path -- kit-finding.sh, kit-resolve.sh and kit-review-record.sh all invoke kit_findings.py.
  # It is NOT a dependency of the derive path and nothing here changes that.
  # T-20260809-one-json-reader-and-one-json-writer-at-t governs folding this into that one
  # reader; this is a second call site, named here rather than left to be found.
  command -v python3 >/dev/null 2>&1 || { kit_warn "python3 is required to read the manifest"; exit 1; }
  _verdict=$(MAN="$MAN" UNIT="$unit" python3 "$(dirname "$0")/kit_manifest.py") \
    || { kit_warn "could not read ${MAN#$ROOT/}"; exit 1; }

  case "$_verdict" in
    OK) ;;
    NOPURPOSE)
      # D4: purpose is DECLARED, not derived -- "Nothing in the tree can compute is this subject
      # being used to evaluate the kit". Unset is refused rather than defaulted, because
      # defaulting either way silently misfiles the census.
      kit_warn "${MAN#$ROOT/} has no non-empty 'purpose'"
      kit_warn "  D4 keys the census's storage location on purpose, and nothing in the tree can"
      kit_warn "  compute it. Unset is refused rather than defaulted."
      exit 1 ;;
    NOUNITS)
      kit_warn "${MAN#$ROOT/} has no 'units' array"
      kit_warn "  F1c: a unit is an INPUT to an audit, not a discovery of one, so the manifest"
      kit_warn "  declares it before the auditor runs."
      exit 1 ;;
    UNDECLARED)
      kit_warn "unit '$unit' is not declared in ${MAN#$ROOT/}"
      kit_warn "  F1c refuses an undeclared unit rather than creating it: intake choosing a"
      kit_warn "  plausible name and SUCCEEDING is the failure mode, not intake crashing."
      exit 1 ;;
    BADJSON*)
      kit_warn "${MAN#$ROOT/} is not readable as JSON: ${_verdict#BADJSON }"; exit 1 ;;
    *) kit_warn "unexpected manifest verdict: $_verdict"; exit 1 ;;
  esac

  # VERBATIM, and read whole before the destination is touched. A partial write leaving a
  # truncated artefact beside a manifest that declares it is worse than no write at all: the
  # store's entire claim is that the raw reply survives. Empty input is refused -- an auditor that
  # returned nothing is not a unit with no claims, and the contract says "claims": [] is how the
  # latter is stated.
  _body=$(cat) || { kit_warn "could not read the reply from stdin"; exit 1; }
  [ -n "$_body" ] || { kit_warn "empty reply on stdin; refusing to write an empty artefact"; exit 1; }

  _dest="$CDIR/$unit.json"
  if ! printf '%s\n' "$_body" > "$_dest"; then
    kit_warn "could not write ${_dest#$ROOT/} -- NOTHING was captured"
    exit 1
  fi
  printf 'kit: captured %s\n' "${_dest#$ROOT/}" >&2
  printf '  verbatim and unvalidated by design (F12): a reply that fails validation keeps its data.\n' >&2
  exit 0 ;;
esac

printf 'kit-claim.sh: --vocab | --contract | --census ID --unit NAME --json\n' >&2
printf '  The store -- table, derivation, reporting, diff -- is not implemented; see the header.\n' >&2
exit 2

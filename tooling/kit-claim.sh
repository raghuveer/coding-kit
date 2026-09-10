#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-claim.sh --vocab                           prints the accepted vocabularies
# kit-claim.sh --contract                        prints the shape of a claim
# kit-claim.sh --census ID --init [fields]       allocates a census: writes its manifest
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
# MANIFEST CREATION IS `--init`, AND WHAT IT MAY DERIVE IS THE WHOLE DESIGN OF IT. Step 1 is
# "writes the reply verbatim ... AFTER manifest creation", so allocation is its own act. D3 names
# three attribution variables -- the subject tree, the auditor, and the kit -- and says a diff in
# which more than one moved is uninterpretable. Two of those the kit MAY compute about itself
# (`kit_sha`, `kit_version`). The third it must NOT: the design is explicit that `subject_sha` and
# `subject_dirty` are "captured by the operator from the subject tree ... not `git rev-parse HEAD`
# in the kit, which would record the kit's own SHA". A census whose subject_sha is silently the
# kit's is worse than one with none, because it looks attributable.
#
# So `--init` derives exactly what is about the kit and REFUSES everything else that is missing.
# D4's `purpose` cannot be computed from any tree and is refused when unset rather than defaulted,
# because defaulting either way silently misfiles the census.
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

REQUIRED on the object: "source", and it must equal the census manifest's
`source_document`. A census audits ONE document (F1d). Capture writes your reply either
way -- nothing you return is ever discarded -- and then REFUSES the unit when the two
disagree, so a mismatch costs a re-run. If the unit you were given belongs to a different
document, say so in `narrative` and return it under its real `source`; the operator
allocates a second census.

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

# ---- census allocation: the manifest writer ---------------------------------------------------
case "$*" in
  *--init*)
  . "$(dirname "$0")/kit-lib.sh"
  ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 1; }
  kit_active "$ROOT" || { kit_warn "kit not adopted here (no .claude/project-profile.md)"; exit 1; }
  PROFILE=$(kit_profile "$ROOT")
  STATE_DIR=$(kit_cfg "$PROFILE" paths.state ".project")

  census=""
  MAN_PURPOSE=""; MAN_SUBJECT_REPO=""; MAN_SUBJECT_SHA=""; MAN_SUBJECT_DIRTY=""
  MAN_SOURCE_DOCUMENT=""; MAN_AUDITOR_MODEL=""; MAN_UNITS=""
  MAN_SUBJECT_REMOTE=""; MAN_AUDITED_AT=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --census)          census=${2:-}; shift; shift ;;
      --init)            shift ;;
      --purpose)         MAN_PURPOSE=${2:-}; shift; shift ;;
      --subject-repo)    MAN_SUBJECT_REPO=${2:-}; shift; shift ;;
      --subject-sha)     MAN_SUBJECT_SHA=${2:-}; shift; shift ;;
      --subject-dirty)   MAN_SUBJECT_DIRTY=${2:-}; shift; shift ;;
      --subject-remote)  MAN_SUBJECT_REMOTE=${2:-}; shift; shift ;;
      --source-document) MAN_SOURCE_DOCUMENT=${2:-}; shift; shift ;;
      --auditor-model)   MAN_AUDITOR_MODEL=${2:-}; shift; shift ;;
      --audited-at)      MAN_AUDITED_AT=${2:-}; shift; shift ;;
      --units)           MAN_UNITS=${2:-}; shift; shift ;;
      *) kit_warn "unknown argument: $1"; exit 2 ;;
    esac
  done
  [ -n "$census" ] || { kit_warn "--census ID is required"; exit 2; }

  # F1b, the same rule capture applies, applied here too. A census_id that capture would later
  # refuse produces a directory nothing can ever be captured into.
  case "$census" in
    ''|*[!A-Za-z0-9._-]*)
      kit_warn "--census must contain only letters, digits, dot, underscore or hyphen: '$census'"
      exit 2 ;;
  esac
  case "$census" in
    .|..) kit_warn "--census may not be '.' or '..': '$census'"; exit 2 ;;
  esac

  CDIR="$ROOT/$STATE_DIR/census/$census"
  MAN="$CDIR/manifest.json"
  # A census is allocated ONCE. Overwriting a manifest would silently re-point every artefact and
  # every disposition already filed under this id at a different subject, and D5 makes that id part
  # of a committed record. Refuse; a corrected census is a new census_id, which is what makes two
  # of them diffable.
  if [ -e "$MAN" ]; then
    kit_warn "${MAN#$ROOT/} already exists -- a census is allocated once"
    kit_warn "  Overwriting it would re-point artefacts and dispositions already filed under"
    kit_warn "  this id at a different subject. A corrected census is a NEW census_id."
    exit 1
  fi

  # THE TWO THE KIT MAY COMPUTE ABOUT ITSELF. Derived from the kit's own checkout, not the
  # subject's -- see the header. If either cannot be determined the manifest is refused rather
  # than written with a blank: D3's diff reports which variables moved, and a blank one is
  # indistinguishable from one that did not.
  MAN_KIT_VERSION=$(kit_version 2>/dev/null)
  MAN_KIT_SHA=$(git -C "$(dirname "$0")" rev-parse HEAD 2>/dev/null)
  [ -n "$MAN_KIT_VERSION" ] || { kit_warn "could not read the kit version; refusing to write a manifest with a blank attribution variable"; exit 1; }
  [ -n "$MAN_KIT_SHA" ] || { kit_warn "could not resolve the kit's HEAD; refusing to write a manifest with a blank attribution variable"; exit 1; }
  MAN_RECORDED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
  [ -n "$MAN_RECORDED_AT" ] || { kit_warn "could not read the clock"; exit 1; }

  command -v python3 >/dev/null 2>&1 || { kit_warn "python3 is required to write the manifest"; exit 1; }
  export MAN_PURPOSE MAN_SUBJECT_REPO MAN_SUBJECT_SHA MAN_SUBJECT_DIRTY MAN_SUBJECT_REMOTE
  export MAN_SOURCE_DOCUMENT MAN_AUDITOR_MODEL MAN_AUDITED_AT MAN_UNITS
  export MAN_KIT_SHA MAN_KIT_VERSION MAN_RECORDED_AT
  _json=$(python3 "$(dirname "$0")/kit_manifest.py" --write) || exit 1

  mkdir -p "$CDIR" || { kit_warn "could not create ${CDIR#$ROOT/}"; exit 1; }
  # TEMP FILE THEN RENAME. A half-written manifest beside artefacts that reference it is worse
  # than none: capture would read it, fail to parse, and report the census unusable without
  # saying why. rename is atomic on the same filesystem, so a reader sees the old file or the
  # whole new one. (The capture path does NOT yet do this -- open finding 9995b290.)
  _tmp="$CDIR/.manifest.json.$$"
  if ! printf '%s' "$_json" > "$_tmp"; then
    rm -f "$_tmp"; kit_warn "could not write ${MAN#$ROOT/} -- NOTHING was allocated"; exit 1
  fi
  if ! mv "$_tmp" "$MAN"; then
    rm -f "$_tmp"; kit_warn "could not place ${MAN#$ROOT/} -- NOTHING was allocated"; exit 1
  fi
  printf 'kit: allocated %s\n' "${MAN#$ROOT/}" >&2
  printf '  kit_sha %s  kit_version %s  (derived)\n' "${MAN_KIT_SHA%${MAN_KIT_SHA#???????}}" "$MAN_KIT_VERSION" >&2
  printf '  subject_sha and subject_dirty came from you, by design: deriving them here would\n' >&2
  printf '  record the kit HEAD as the subject and make every diff unattributable.\n' >&2
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
    kit_warn '    { "purpose": "...", "source_document": "<path>", "units": ["<unit>"] }'
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
    NOSOURCEDOC)
      # F1d. `--init` always writes this field, so a manifest without it was hand-written. The
      # constraint is the whole content of the field: a census whose source_document is unset
      # cannot hold its units to anything, and accepting it would make the check unreachable
      # exactly where it is needed. Refused before the write, so nothing is captured.
      kit_warn "${MAN#$ROOT/} has no non-empty 'source_document'"
      kit_warn "  F1d: it is a CONSTRAINT -- every unit's 'source' must equal it, and a census"
      kit_warn "  audits one document. Unset, capture has nothing to check the reply against."
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

  # F1d, and the ORDER is the whole design. The bytes are on disk before this runs, so every
  # branch below decides an EXIT STATUS and none of them decides whether the reply survives.
  # `3e76f904`: the manifest names one source_document per census while each unit names its own
  # source, so until this check a census spanning two documents recorded a manifest that
  # contradicted its own units -- in the committed artefact, with no derivation involved.
  _sv=$(MAN="$MAN" ART="$_dest" python3 "$(dirname "$0")/kit_manifest.py" --source) \
    || { kit_warn "the F1d source check could not run; ${_dest#$ROOT/} was KEPT"; exit 1; }
  case "$_sv" in
    OK) exit 0 ;;
    UNPARSED*)
      # THE HOLE, PRINTED RATHER THAN HIDDEN. Conformance asserts that a malformed reply is
      # captured and NOT refused (F12), so a reply this cannot parse cannot be held to F1d.
      # It enters the census unchecked, and the operator is told so in the same breath.
      printf '  source NOT CHECKED (F1d): %s\n' "${_sv#UNPARSED }" >&2
      printf '  The bytes are kept and the unit is in the census unverified. Re-derive it.\n' >&2
      exit 0 ;;
    NOSOURCE)
      kit_warn "the reply parses but carries no 'source' -- REFUSED"
      kit_warn "  ${_dest#$ROOT/} was KEPT (F12); nothing you paid for is lost."
      kit_warn "  F1d is checkable only against a source. Omitting the field would otherwise be"
      kit_warn "  a way to opt out of the constraint, so it is refused rather than skipped."
      exit 1 ;;
    SOURCEMISMATCH*)
      _TAB=$(printf '\t')
      _rest=${_sv#SOURCEMISMATCH$_TAB}
      _decl=${_rest%%$_TAB*}
      _got=${_rest#*$_TAB}
      kit_warn "this unit audits a different document from the census -- REFUSED"
      kit_warn "  manifest source_document: $_decl"
      kit_warn "  reply source:             $_got"
      kit_warn "  ${_dest#$ROOT/} was KEPT (F12); nothing you paid for is lost."
      kit_warn "  F1d: a census audits ONE document. Two documents are two censuses -- allocate"
      kit_warn "  a second with --init and capture this unit there."
      exit 1 ;;
    BADJSON*)
      kit_warn "${MAN#$ROOT/} became unreadable between the two checks: ${_sv#BADJSON }"
      kit_warn "  ${_dest#$ROOT/} was KEPT (F12)."
      exit 1 ;;
    *)
      kit_warn "unexpected F1d verdict: $_sv"
      kit_warn "  ${_dest#$ROOT/} was KEPT (F12)."
      exit 1 ;;
  esac ;;
esac

printf 'kit-claim.sh: --vocab | --contract | --census ID --init ... | --census ID --unit NAME --json\n' >&2
printf '  The store -- table, derivation, reporting, diff -- is not implemented; see the header.\n' >&2
exit 2

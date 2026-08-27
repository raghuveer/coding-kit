#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-claim.sh --vocab       prints the accepted vocabularies
# kit-claim.sh --contract    prints the shape of a claim
#
# THE VOCABULARY HOME FOR A CENSUS CLAIM. A claim is not a finding and must never be recorded
# as one. A finding says "this code is defective". A claim says "this document asserts X; the
# tree says Y". The subject of a finding is code; the subject of a claim is a CLAIM. Recording
# roadmap assertions in the `finding` table would flood the criticals gate with rows that are
# not defects -- see T-20260826-a-verified-claim-about-the-tree-has-no-a.
#
# THIS SCRIPT DOES NOT YET RECORD ANYTHING, AND THAT IS DELIBERATE. It answers "what may an
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

printf 'kit-claim.sh: --vocab | --contract\n' >&2
printf '  Recording is not implemented yet; see the header.\n' >&2
exit 2

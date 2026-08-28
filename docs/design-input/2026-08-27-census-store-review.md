<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Approach review — census store design

**Verdict: REVISE.** 5 critical, 9 major, 3 minor. Reviewer: `approach-reviewer` contract, opus,
read-only, 21 tool calls. Findings recorded against
`T-20260826-a-verified-claim-about-the-tree-has-no-a`.

Reviews `docs/design-input/2026-08-27-census-store.md`. The reviewer verified the design's
characterisations against the code rather than accepting them, and found one of them false.

## Verified accurate

`tooling/kit-claim.sh` (merged) records nothing and says the store extends it rather than adding a
second door — the design honours that. `agents/claim-auditor.md:113-149` matches the design's
summary of the producer. `tests/conformance.sh:224-261` exists and passes. **AC2 and AC3 are
already satisfied by merged work**, and the design correctly does not re-litigate them.

## Critical

**F1 — `census_id` is undefined, and every candidate fails.** The design calls the identity scheme
load-bearing and leaves half of it a free variable. Tree SHA: then step 2 ("audit one unit twice")
is impossible — same tree, same `census_id`, same keys, run 2 replaces run 1. **The key destroys
the measurement chosen to validate it.** Intake timestamp: `claim-auditor` splits a census across
~18 subagents and `--json` reads one object, so each subagent becomes its own census and
"census-to-census diff" compares fragments. Operator-supplied flag is the only survivor and is not
in the design.

**F3 — identical claim text in one subject collides.** `claim_key` excludes `source_loc`, so two
claims with the same wording on different lines produce one key. Not exotic: `claim-auditor.md:140`
instructs *"keep the document's own framing"* and roadmaps repeat phrasing across use cases. The
design cites the finding-id precedent but takes half of it — `kit-index.sh:881-904` suffixes
byte-identical lines and sets `collbase[]`, which propagates to `finding.id_ambiguous`
(`schema.sql:156-161`) and a `finding_id_collisions` meta counter. The design has no suffix, no
flag, no counter. **A claim costing ~35k BTE disappears silently.** The tension to resolve: adding
`source_loc` restores uniqueness and destroys re-run stability, because line citations move — the
entire `STALE-CITATION` story.

**F4 — `normalise` unspecified, and who computes the key is unstated.** If `kit_claims.py` writes
the key it is frozen into an append-only committed log and re-normalisation is impossible forever.
If `kit-index.sh` computes it, `normalise` must be reimplemented in awk and agree byte-for-byte —
in the language where `LC_ALL=C` already had to be forced for this class of reason
(`kit-index.sh:812-815`). Also interacts with an existing transform: `kit_findings.py:97-101`
already collapses whitespace and maps `"`/`\` before anything reaches the log, so hashing the raw
claim keys a string that exists nowhere.

**F5 — the sequence is inverted.** The design says the variance measurement *"decides everything"*
and schedules it **after** the step that freezes the event format. High variance would demand
different normalisation, or no claim-level keying at all — and every committed line already carries
a key computed under the old rule. Permanent split-brain, or two `claim_key` fields forever. The
design files this as "known weakness 1"; **it is an ordering defect.**

**F6 — the design never says where a census is stored, and the verified state says it cannot be.**
Both measured censuses audited *foreign* repositories. The reviewer checked: the highper-gateway
trial copy has no `.claude/` and no `project-profile.md` within three levels. So either record in
the audited repo — where `kit-finding.sh:51-58`'s mirrored guard refuses `--json` outright, loudly
and correctly — or record in the kit repo, where `STATUS.generated.md` then reports a foreign
tree's drift as this project's. **Neither is addressed. No `subject_repo` column exists.** This is
the difference between a design that fits the two runs that motivated it and one that does not.

## Major

**F2 — the pair-key rationale is false about the code it cites.** The design argues *"findings use
`INSERT OR REPLACE` on a content id, which is right for findings — re-recording the same finding
should dedupe."* It does not dedupe. `kit-index.sh:879-880` hashes the **whole event line**,
including `"at"`, `"agent_id"` and `"model"`; `kit_findings.py:261` stamps `at` at emit time. A
finding re-recorded a second later yields a different hash and a **second row**; within the same
second, the occurrence suffix gives two rows as well. The indexer says so: *"the id is stable for
as long as the event is"* (`kit-index.sh:872`). `INSERT OR REPLACE` buys **idempotent rebuild of
one log**, not dedup. The conclusion may still be right; the only reasoning offered is not.

**F11 — the single-append atomicity argument does not hold at census size.** `kit-finding.sh:144`
is one `printf >>` and its comment argues correctness from "one append" — true at a few hundred
bytes. Today's log averages 385 bytes/line; a 28-claim unit is ~15KB and a full census ~270KB.
Above the stdio buffer `printf` issues multiple `write()` calls, and **there is no lock anywhere**
— the reviewer checked all seven appenders. The concurrent writer is not hypothetical: `spend`
events are written when a subagent stops, and a census runs 18 subagents. A spend line landing
between chunks splits a claim line in an append-only committed log. `_assert_flat` cannot catch it
— it validates the line, and the corruption happens at the file.

**F12 — "reuse the pipeline exactly" omits the retry half, which is the expensive half.**
`kit-review-record.sh:106-155` turns a refused reply into a corrected one via
`kit_findings.py --correction`, up to `$max` attempts. Without an equivalent, one rejected claim in
a 28-claim unit destroys the unit and nothing re-asks — **~1M BTE per rejected unit.** `claim-gap`
records the loss; it does not prevent it.

**F13 — nobody has measured what a census does to the index.** `.project/events.ndjson` is
616 lines / 236,867 bytes across the project's entire life. **One census adds ~270KB — more than
doubling the committed log in a single commit.** Every `kit-index.sh` run re-reads, re-sorts and
re-hashes it, and `fnv1a` is a 32-iteration inner loop per byte in interpreted awk.

**F14 — the alternative that dissolves the conflict is missing: commit the auditor's raw JSON
verbatim, one file per unit.** It achieves step 1's stated goal — *"a census survives permanently
even if nothing can query it"* — **completely**, and freezes **nothing**: no `census_id`, no
`claim_key`, no field set, no `normalise`. Strictly better on step 1's own criterion, and it lets
the variance measurement precede every locked decision. The blanket *"a second pipeline would be a
second truth"* does not refute it: task files are already this shape — authoritative text,
disposable projection. A second uncosted alternative: `(census_id, source, subject, ordinal)`,
where the finding counter's defect was that it was **global** and an ordinal scoped to one
immutable unit cannot be moved by another event.

**F7 — "record the tree SHA" is not implementable as stated.** Whose tree (the recorder's is the
kit's); captured when (the auditor has no Bash, so at intake — hours later across an 18-subagent
run, and a commit in between makes it silently wrong); and dirty-worktree unhandled, though
`kit-checkpoint.sh:17` already records a dirty flag.

**F15 — the variance measurement is not operationalised.** No metric, no threshold, no decision
rule; n=1 unit with no notion of spread; and it measures **same-document noise**, a floor, while
AC6's condition is *re-running on a later commit* where tree and document have both moved.

## Acceptance criteria not satisfied

| AC | Status |
|---|---|
| AC1 recordable fields | Met by the merged contract |
| AC2 one vocabulary home + conformance | Met — merged |
| AC3 `UNVERIFIABLE` first-class | Met |
| **AC4** claim *may reference a finding* | **Partially unmet** — no `finding_id`, no edge, no mention |
| **AC5** drift rate **as a fraction with its denominator** | **Unmet** — never defined; `UNVERIFIABLE` was 64 of 489, so /489 and /425 differ materially. The AC exists to force this choice |
| **AC6** comparable re-run | **At risk** — blocked on F1 |
| **AC7** mutation proof | **Unmet** — no test plan; `conformance.sh:2003-2097` is the ready template |

**F17, minor:** the task frontmatter says `tier: T2` and omits `kit-index.sh` from `paths:`, so the
derived `tier_floor` cannot see the T3 trigger the design correctly claims.

## Questions for the operator

1. **Is a census recorded in the audited repo or the kit repo?** Everything downstream turns on it.
2. One `--json` per audited unit, or an aggregation step first? (Same question as F1.)
3. What happens to `claim-auditor`'s `narrative`? `kit_findings.py:212-215` accepts and **discards**
   it. For a census the narrative is the ranked analysis a human actually reads — discarding it
   repeats this task's own complaint at a smaller scale.
4. Is a claim ever superseded or dispositioned? Findings needed four verbs, each added after a gate
   became unsatisfiable.

## What the reviewer did not check

Did not run `kit-index.sh` or conformance (read-only) — **F13's figures are computed from file
sizes and code inspection, not measured.** Did not verify aeon: `D:/personal-github/aeon` no longer
exists on this machine, so F6's filesystem evidence covers **highper-gateway only**. Did not read
`kit-status.sh` beyond the findings sections, so cannot say whether a new table needs registration
in the readability guard. Did not audit `conformance.sh` in full. Did not evaluate whether a
489-claim reply fits in one subagent response — a real constraint on batch granularity bearing on
F1.

## Recommended ADR, if the revision holds

**"Census claim identity: `(census_id, claim_key)` and where the key is computed"** — the Decision
must record the source of `census_id` and that the key is derived at index time rather than
authored into the log, per the derived-tables rule. Alternatives must include raw-artefact-first
sequencing and the within-unit ordinal, both uncosted in the reviewed design.

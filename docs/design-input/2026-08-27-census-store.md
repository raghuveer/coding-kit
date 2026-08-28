<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — the census store

**Task:** `T-20260826-a-verified-claim-about-the-tree-has-no-a`
**Tier:** T3 — trigger `tier.rule: tooling/kit-index.sh T3`.
**Blocked-by, satisfied:** the `claim-auditor` contract, merged in PR #27 (`38e648c`).

**Revision 2, 2026-08-28.** Revision 1 was reviewed by `approach-reviewer` and returned **REVISE**
— 5 critical, 9 major, 3 minor, recorded as 17 findings against this task and narrated in
`2026-08-27-census-store-review.md`. This revision answers them. Where a finding is dissolved
rather than solved, that is said, because the difference matters to whoever reads this next.

## Two decisions made by the operator, recorded as his

**D1 — the census is recorded IN THE KIT REPO.**

The rationale is his and is not a storage convenience. highper-gateway and aeon were used as
**brownfield project candidates**, evaluated to validate the kit's strengths and to identify
improvement areas explicitly. What the audits produced is therefore *"findings of evaluation of
both brownfield project candidates"* — data belonging to the kit's own development record, to be
tested against as the kit improves. Secondarily it is of use when those projects are actually
developed with this kit, in a **token-economics context, to prevent duplicate work**. Millions of
tokens and clock time were spent; neither is free.

This settles review finding **F6**, which the reviewer correctly identified as unaddressed and
unaddressable by the design as written.

**D2 — claims carry dispositions, and discarding is a recorded act.**

Once findings are data, they can be shown, and opinions, inputs and feedback can be logged **on
specific points**. A false positive, or one judged less important, **may be discarded — and the
discarding is itself recorded as such**, never a deletion. The purpose is that when more developers
contribute later, they have the history clearly.

This answers the reviewer's open question 4 and is the same principle the finding vocabulary
already embodies: `--unassessable` and `--superseded` leave the gate and stay in the record
permanently, because a mark that clears a gate without saying why is the laundering the gate exists
to prevent.

## The problem, measured

**792 verified claims across two runs; none survives at claim granularity.** highper-gateway's 303
became a 16-row count table; aeon's 489 became a 157-line narrative. All 35 subagent transcripts
are gone — the `spend` rows preserve every `agent_id`, and a search across all 15 project
transcript directories found 0 of 35. Cost to produce: 11,066,325 and 17,015,010 BTE, stable at
~35k BTE per claim.

## The architecture change: raw artefact first, everything else derived

Revision 1 proposed writing claims straight into `.project/events.ndjson` as the durable form. The
reviewer's **F14** identified the alternative it never costed, and D1/D2 independently demand it:

> **Commit the auditor's raw JSON verbatim, one file per audited unit. Derive everything else.**

```
.project/census/<census_id>/
    manifest.json          subject repo, subject SHA, dirty flag, document, operator, dates
    <subject>.json         the auditor's reply, VERBATIM — narrative and claims, unmodified
    ...                    one per audited unit
                                    │
                                    ▼  derived, disposable, rebuildable
              .project/index.db     claim table + claim_disposition
                                    │
                                    ▼
                          kit-status.sh, census diff
```

The artefact directory is **committed**. The table is **derived** and may be dropped and rebuilt,
exactly as `ADR 0004` requires of every derived thing in this repository.

### What this dissolves rather than solves

| review finding | status under revision 2 |
|---|---|
| **F4** `normalise` unspecified; writer-or-indexer unstated | **Dissolved.** The committed artefact carries only the auditor's raw fields. `claim_key` is computed **at index time**, so re-keying stays free forever. There is nothing to freeze. |
| **F5** sequence inverted — step 2 decides what step 1 froze | **Dissolved.** Step 1 freezes nothing. The variance measurement can now run before, during or after without penalty. |
| **F11** torn writes: 15KB–270KB batch, no lock, concurrent `spend` appenders | **Dissolved.** A unit is one file written once, not an append to a log shared with 18 subagents' `spend` hooks. There is no interleaving to protect against. |
| **F13** one census adds ~270KB to a 237KB log the awk hot loop re-hashes every run | **Dissolved for the log.** Artefacts are separate files; `events.ndjson` does not grow per claim. The derived-table build cost remains and is budgeted below. |
| **F16** `sanitise` maps `\`→`'`, mangling Windows evidence paths | **Reduced to recoverable.** The raw artefact preserves the original byte-for-byte; only the derived row is sanitised, and the original is always one file read away. |
| **F12** no retry loop; a rejected unit loses ~1M BTE | **Reduced.** The raw reply is saved **before** validation, so a unit that fails validation still has its data. Validation failure becomes a re-derivation problem, not a data-loss event. A correction loop is still wanted and is now an optimisation rather than a safeguard. |

Six of fourteen dissolved or materially reduced by one structural choice. That is the argument for
it, and it is the reviewer's, not mine.

### F1 — `census_id`, now defined

**`census_id` is the directory name, allocated by the operator when a census begins.** Slug form,
`<subject>-<date>`: `aeon-2026-08-27`.

It is not derived from content, and could not be. The reviewer proved every derived candidate
fails: the subject tree SHA makes a repeat audit of the same tree indistinguishable from the first,
destroying the very measurement meant to validate the key; an intake timestamp makes each of ~18
subagents its own census, so a "census-to-census diff" compares fragments.

Consequences, stated:

- A unit re-run mid-census **overwrites its own file** in the same `census_id` directory. That is
  correct — a corrected audit of one unit replaces the failed one, and git holds the prior version.
- Two audits of the same subject are **two directories**, which is what makes them diffable.
- `census_id` uniqueness is a directory-creation collision. Refuse, do not merge.

### F3 — collision, now handled by adopting the whole precedent

`claim_key = hash(subject_repo, source, subject, normalise(claim_text))` still collides when a
document repeats wording across units — which `claim-auditor.md:140` actively encourages by
instructing the agent to keep the document's own framing.

Revision 1 cited the finding-id precedent and took half of it. Revision 2 takes all of it:

- a byte-identical repeat gets an **occurrence suffix**, as `kit-index.sh:881-904` does;
- a true collision sets an **`id_ambiguous` flag** on the row, as `finding.id_ambiguous`
  (`schema.sql:156-161`) does;
- and a **meta counter** `claim_id_collisions` is exposed, as `finding_id_collisions`
  (`kit-index.sh:1001`) is, so the ambiguity is said out loud rather than silently absorbed.

Because the artefact is a per-unit file with an **ordered** `claims` array, the within-unit
**ordinal** is available for free as the disambiguator — the reviewer's second uncosted
alternative. It is safe here in a way the old finding counter was not: that counter was *global*,
so an unrelated event renumbered every finding after it; an ordinal scoped to one immutable unit
file cannot be moved by anything.

`normalise` is specified as: lowercase, collapse internal whitespace, strip trailing punctuation.
It is defined **once, in `kit_claims.py`, and applied only at index time** — never in awk, never
in the committed artefact.

### F2 — the rationale, corrected

Revision 1 argued the pair key was needed because *"findings use `INSERT OR REPLACE` on a content
id — re-recording the same finding should dedupe."* **That is false about the code it cited.**
`kit-index.sh:879-880` hashes the whole event line including `"at"`, which `kit_findings.py:261`
stamps at emit time; a finding re-recorded a second later produces a different id and a second row.
The indexer says so itself at line 872: *"the id is stable for as long as the event is."*

The true reason for `(census_id, claim_key)`: **a census is an observation, not a fact.** Two
audits of the same document are two observations of it, and both must persist for either to be
comparable. `INSERT OR REPLACE` buys idempotent rebuild of one artefact set — nothing more, and
nothing about dedup.

### F6/F7 — foreign subjects, now first-class

Because the census lives in the kit repo (D1) while describing another tree, **every claim carries
its subject**. The manifest records, per census:

`subject_repo` · `subject_remote` · `subject_sha` · `subject_dirty` · `source_document` ·
`audited_at` · `recorded_at` · `auditor_model`

`subject_sha` and `subject_dirty` are captured **by the operator from the subject tree** and
written into the manifest — not `git rev-parse HEAD` in the kit, which would record the kit's own
SHA, and not by the auditor, which has `Read, Grep, Glob` and no Bash. `subject_dirty` follows
`kit-checkpoint.sh:17`, which already records exactly this alongside HEAD.

**The trap this creates, and the control for it.** A census about aeon must never make
`STATUS.generated.md` report aeon's 35% drift as the kit's. `kit-status.sh` reports census figures
**per `subject_repo`, always named, never aggregated into this project's own numbers**, and a
census whose `subject_repo` is the kit itself is the only one that may appear unqualified. This
needs a conformance step that fails if a foreign census leaks into an unqualified total — a control
that can fail, not a convention.

### F10/AC5 — the drift rate and its denominator, now decided

Reported as **two fractions, both with explicit denominators, never as an adjective**:

```
drift        173/489   (35%)   verdicts other than CONFIRMED, over all claims
drift-judged 173/425   (41%)   the same numerator, over claims that could be judged
unverifiable  64/489   (13%)   reported alongside, never folded into either
```

The reviewer was right that this is genuinely ambiguous and that the AC exists to force the choice.
Both are printed because they answer different questions — how much of the document is wrong, and
how much of the checkable document is wrong — and printing one silently picks an argument.

### F15 — the variance measurement, operationalised and demoted

Revision 1 said it *"decides everything"* and scheduled it before the design was fixed. Both were
wrong. Under revision 2 nothing depends on it being done first, because nothing is frozen.

It is now specified rather than gestured at: **metric** = Jaccard similarity over normalised claim
text within one unit, plus per-claim verdict agreement on the intersection; **n** = 3 units × 2 runs
rather than 1 × 2, so spread is visible; **decision rule** = below 0.8 mean similarity, claim-level
diffing is reported as best-effort only and per-subject verdict counts become the headline.

And its status is stated honestly: it measures the **same-document noise floor**, not AC6's
condition, which is a re-run against a *later commit* where tree and document have both moved. It
bounds the matcher's best case. It does not decide everything.

### AC4 — a claim may reference a finding

Unaddressed in revision 1. A `claim.finding_id` column, nullable, referencing `finding.id`. A claim
that leads to a defect points at it; the claim does not become one. This is the AC's second half
and it was simply missed.

### AC7 — the mutation proof, committed to

`tests/conformance.sh:2003-2097` is the template: it proves `before == after` on a poisoned batch,
round-trips hostile input in every field, and asserts empty differs from absent. The claim
equivalent proves: an invalid verdict rejects the **whole unit** and records nothing; an invalid
`location` likewise; a claim over 200 characters rejects the batch; `"claims": []` records a
measurement while an absent key is refused; and a foreign-subject census does not appear in an
unqualified status total.

## Dispositions (D2)

A second vocabulary, in `kit-claim.sh --vocab` beside the verdicts, and **operator-only** for the
same reason `--fixed` is: a session certifying its own output is the one signature carrying no
information.

| disposition | meaning |
|---|---|
| `accepted` | the claim stands; it is real and worth acting on |
| `false-positive` | the audit was wrong about the tree — a finding about the auditor |
| `low-value` | true but not worth acting on, with the reason |
| `actioned` | a task or finding was raised from it; carries the id |
| `deferred` | real, not now, with the reason |

Every disposition carries a required reason and is recorded as a `claim-disposition` event —
append-only, never a deletion, never an edit to the claim row. An undispositioned claim is
**neither accepted nor discarded**, and `kit-status.sh` reports that count as a standing figure the
same way unassessable findings are, rather than folding it into zero.

This is what makes the census usable the way D2 describes: opinions and feedback logged on specific
points, discards recorded as discards, and a history a later contributor can read.

## Sequence, revised

The old "durability first, then measure, then freeze" ordering is gone — it was an artefact of a
design that froze things.

1. **Artefact capture** — `kit-claim.sh --census ID --unit NAME --json` writes the reply verbatim
   under `.project/census/<census_id>/`, after manifest creation. T2. **Durability is complete at
   this step and nothing is locked in.**
2. **Derivation** — `kit_claims.py` + schema + `kit-index.sh` ingestion, reading artefacts, not
   events. T3, its own commit, `security-reviewer` per the profile.
3. **Dispositions** — `kit-claim.sh --disposition`, operator-only, `claim-disposition` events.
4. **Reporting and diff** — `kit-status.sh` per-subject figures, both drift fractions, the census
   diff.
5. **Variance measurement** — whenever; it now informs the diff's presentation rather than gating
   the design.

## Still open, and named rather than buried

- **F12's correction loop** is reduced but not built. A rejected unit keeps its data; re-deriving
  is manual until something automates it.
- **Derived-table build cost** at ~489 rows per census is bounded but unmeasured. It no longer
  touches the `events.ndjson` hot loop, which was the reviewer's actual concern.
- **The reviewer's question 3**, the auditor's `narrative`: answered by architecture. The raw
  artefact holds it verbatim. Whether the derived table also surfaces it is a reporting decision,
  not a durability one.
- **Whether a 489-claim reply fits one subagent response** — the reviewer flagged it as unchecked
  and it remains unchecked. It bears on unit granularity, not on this design.
- **F17**: the task frontmatter says `tier: T2` and omits `kit-index.sh` from `paths:`, so the
  derived `tier_floor` cannot see the T3 trigger. Fixed alongside this revision.

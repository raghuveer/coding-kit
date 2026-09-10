<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# ADR 0011: Claims are recorded in committed artefacts, and the index does not carry them

- **Date:** 2026-09-09   **Status:** **Accepted**   **Accepted:** 2026-09-09 by the operator
- **Supersedes:** the derivation half of `design-input/2026-08-27-census-store.md`
- **Related:** [[0004-where-the-plan-lives]], [[0008-the-task-state-vocabulary-and-its-partitions]]

**0007 is still not used.** ADR 0006's rejection banner reserves it for the disposition-evidence
successor that was never written, and taking the number would claim work that does not exist.

Every number below was produced by a command on this repository on 2026-09-09 and the command is
named. ADR 0005, ADR 0006 and ADR 0010 were each rejected for a load-bearing claim that was
confident, checkable and false; the discipline is a response to that.

## Context

### The census store shipped in halves, and only the first half exists

`tooling/kit-claim.sh` (329 lines) and `tooling/kit_manifest.py` (147 lines) implement **step 1**,
artefact capture and manifest allocation, with **52 references in `tests/conformance.sh`**. The
script says so itself: *"ARTEFACT CAPTURE IS STEP 1 … capture first and derivation second, as
separate commits."*

**Step 2, derivation into the index, does not exist.** Verified:

```sh
ls tooling/kit_claims.py                                  # absent
grep -cE 'CREATE TABLE (census|claim)' tooling/schema.sql  # 0
grep -c python3 tooling/kit-index.sh                       # 0
```

### Step 1 had captured nothing until today

`.project/census/` did not exist between 2026-08-28 and 2026-09-09. Meanwhile the `claim-auditor`
had produced **303, 489 and 46 claims** across three reconciliation trials — 838 in total, costing
6,547,551 and 13,853,224 BTE on two of them per `docs/MODELS.md` — and every one of them came back
as **prose in a trial document**. The store existed and the data went past it.

The first census was captured on 2026-09-09:
`.project/census/handoff-invariants-2026-09-09/`, nine claims about `docs/HANDOFF.md` §11.

### The measurement that decides this ADR

Validating that artefact against the shipped contract — required fields, both closed vocabularies
(`kit-claim.sh:75`), evidence required unless `UNVERIFIABLE`, the 200-character bound — took
**about twenty lines of Python reading a committed JSON file**. It returned **9 claims, 0
violations**. No index, no `awk`, no `kit-index.sh`.

### Three of the criticals holding the trial pre-flight object to derivation, not to the store

| finding | objection |
|---|---|
| `65e3d2a2` | `normalise` is specified to run at index time, and `kit-index.sh` contains zero `python3` invocations; F4 is relocated, not fixed |
| `cd31c6bf` | the derive path has no JSON parser — `jf()` is a single-line regex blind past an escaped quote — so ingestion is forced regardless of `normalise` |
| `e71bd25e` | step 2 specifies no per-artefact isolation while F12 guarantees committed artefacts may be malformed, so one bad artefact fails the whole index build |

All three are objections to a design decision that had not been taken. None is an objection to
capturing claims, and none survives the decision below.

## Decision

**A claim is recorded in a committed artefact under `.project/census/`. The index does not carry
claims, and no `claim` or `census` table is added to `schema.sql`.**

Three parts:

1. **The artefact is the record.** It is tracked, diffable, and readable by anything that reads
   JSON. `validate.py` already treats `.project/census` as a declared artefact root.
2. **Validation is a reader over artefacts**, not a stage of `kit-index.sh`. It may refuse; it does
   not ingest.
3. **`kit-index.sh` is untouched.** Its `--if-stale` path runs at the start of every session, and
   nothing about claims should be able to make that path slower, fail, or need a JSON parser.

**This follows the rule the kit already applies everywhere else.** `docs/HANDOFF.md` §4.1: text is
truth, the index is derived and disposable. Claims in committed artefacts are text. The question
was never *artefact or index* — it was **whether the index needs to cache claims yet**, and with
one artefact and a twenty-line validator, it does not.

## Options considered

**A — derive claims into the index, as `design-input/2026-08-27-census-store.md` proposed.**
Rejected. It is what produced the three findings above. Its cost is a JSON parser in a shell
indexer, a `python3` dependency inside the one path that runs at every session start, and
per-artefact isolation so that one malformed committed file cannot take the index down. All of
that is paid before a single report is written, and no reader has yet asked for a join.

**B — artefacts only, with a reader. Chosen.** The validator exists as twenty lines. The artefacts
are already tracked. Nothing in `kit-index.sh` changes.

**D — claims as EVENTS, appended to `.project/events.ndjson`.**

> **Added by amendment 2026-09-09, the day this ADR was accepted, because omitting it was a
> defect.** This ADR shipped with three options and none of them was the events route, which is the
> **same omission** `6a07968d` and `65e35340` file against `census-store.md`: that route excluded
> without being costed. Two findings say so and neither was superseded by this ADR as first written
> — it repeated their complaint one document later. Amended in place, matching the convention ADR
> 0001 set and ADR 0004 followed.

The route is real and its machinery ships. Verified 2026-09-09:

- `tooling/kit_findings.py` writes compact single-line JSON at three sites
  (`json.dumps(..., separators=(",", ":"))`) — the writer exists.
- `.gitattributes:20` marks the log `merge=union text eol=lf`, and it already carries **901 lines
  across 12 distinct event kinds** — heterogeneous records are the norm there, not an exception.
- `jf()` in `kit-spend.sh` and `kit-index.sh` reads those lines — the reader exists.

**Rejected, and on a discriminator neither prior document stated: F12.** Capture must write the
auditor's reply **verbatim, before validation** — `kit-claim.sh` prints it on every capture, and the
reason is that a reply which fails validation must keep its data, because it cost real tokens to
produce. An append-only line-oriented log cannot take an unvalidated blob: every other reader of
`events.ndjson` parses it line by line, so a malformed reply would either have to be validated
first — which F12 forbids at that step — or corrupt a log that eleven other event kinds depend on.

Two lesser reasons, stated so the rejection does not rest on one point:

- **An artefact is a nested document; an event is a flat record.** A reply carries `source`,
  `subject`, a `narrative`, and a `claims[]` array. As events it becomes N lines plus a homeless
  narrative, and the atomic unit — *one auditor reply* — stops being addressable.
- **Blast radius.** `events.ndjson` is the authoritative log for findings, spend, and task
  transitions. A census of 489 claims would multiply it by half again, and every consumer of that
  file pays for a subject none of them read.

**So the decision below is unchanged and its argument is now complete.** That distinction matters:
the conclusion was right and the reasoning had a hole, which is exactly the shape ADR 0005, 0006
and 0010 were rejected for. Being right by luck is not a standard this repository accepts.

**C — hybrid: capture verbatim, derive a narrow projection later.** Not rejected on merit, and it
is what B becomes if a reader needs it. Named here so it is not re-derived as a new idea: **B and C
differ only in when**, which is the whole reason B is safe.

## Consequences

**The decision is reversible at MINOR cost, and that is why it can be taken now.** `VERSIONING.md`
classes any `index.db` schema change as MINOR **because delete-and-rebuild is lossless** — the
index is derived, gitignored, and reaches no user. So adding a claims projection later is a minor
version, not a migration. Choosing B now forecloses nothing.

**Three criticals are superseded rather than fixed**, and the distinction is the point:
`65e3d2a2`, `cd31c6bf` and `e71bd25e` were real, and being real is why their subject died. They
leave the criticals gate, stay in the record permanently, and `kit-status.sh` counts them
separately rather than folding them into zero.

**Claim identity does not go away, but it does not survive intact either — and this ADR first
said it did.**

> **Amended 2026-09-09, the second amendment to this document on the day it was accepted.** The
> paragraph here originally read that `26925ff4`, `e1c2ce2b` and `3e76f904` are *"not superseded by
> this ADR"* and all come due at the second census. **That is wrong on two of the three**, and it is
> wrong by conflating *the question is alive* with *the finding's subject is alive* — the same
> conflation this ADR criticises elsewhere. Corrected in place, per the convention ADR 0001 set.

The question — *how is a claim identified across censuses* — is alive and belongs to
`T-20260828-census-diff-and-the-attribution-control-`. The **mechanism** those findings criticise is
not. Checked rather than reasoned:

- `census-store.md:310` (F4) specifies `claim_key` as **computed at index time**. Index-time
  derivation is what this ADR withdraws.
- `kit-claim.sh --contract` emits **no key at all** — `grep -c claim_key` on it returns **0**. The
  shipped artefact was never going to carry one; it was to be derived.

So the split is two and one:

| finding | subject | standing |
|---|---|---|
| `26925ff4` | `claim_key` undefined, three candidates, an ordinal breaking AC6 | **superseded** — the key it criticises is the index-time key |
| `e1c2ce2b` | the occurrence suffix is positional, so an ordinal-free key is not position-free | **superseded** — same key, same withdrawal |
| `3e76f904` | `source_document` per census against `source` per unit | **Was OPEN, and it was a shipped defect. Settled 2026-09-10** by `census-store.md` F1d — `source_document` is a CONSTRAINT and a census audits one document. This ADR's insistence that it not leave with the other two is what kept it in the gate until it was fixed rather than dispositioned |

**`3e76f904` is not a keying question and must not leave with the other two.** Both fields exist in
shipped code today — `source_document` is REQUIRED in `kit_manifest.py:44`, `source` is per-unit at
`kit-claim.sh:93` — so a census spanning two documents records a manifest-level source that
contradicts its own units, **in the artefact, with no derivation involved**. That is a defect in the
format this ADR just made authoritative, which makes it more urgent under this decision rather than
less.

**Settled 2026-09-10, and the way it was settled is the point.** F1d makes `source_document` a
constraint every unit's `source` must equal, enforced at capture **after** the write so F12 still
holds, with a conformance step over the committed censuses and five mutations proving each branch.
This ADR's split — two superseded, one open — is what made that possible: had `3e76f904` left with
the two keying findings, the defect would have been dispositioned instead of fixed, in the format
this ADR had just made authoritative.

**When identity does come due**, it is decided against a second census and not this one.
`docs/design-input/2026-09-08-claim-identity.md` was **REJECTED with 9 criticals** for settling it
too early, and nothing here reopens that.

**No SQL join between a claim and a task, finding, tier or spend row.** This is the real cost and
it is not hypothetical: `kit-status.sh` cannot report claims beside findings without a reader
doing the join in code. Accepted, because no such report has been asked for, and because inventing
the schema for a report nobody has specified is how `plan_item` acquired a second writer.

**Reading every artefact costs one file read each.** At one census this is nothing. If a report
ever walks hundreds, that is the signal to revisit — and option C is waiting.

## What this does not cover

- **Whether a census store is ever indexed.** This ADR says *not yet* and names the trigger: a
  reader that needs a join, or a walk over enough artefacts to be slow.
- **Claim identity, and census diff.** Above. Both stay open and both are filed.
- **The four rationale findings** against `census-store.md` — `b032ddaf`, `6a07968d`, `65e35340`,
  `322f03aa`. They are arguments in a document refuted by measurements in the same document, and
  they are untouched by this decision.
- **Whether step 1's contract is right.** It shipped, it captured a census, and its refusals fired
  correctly twice on 2026-09-09 — once on a `subject_dirty` of `false` where `0` or `1` is
  required, once on a mistyped finding id. That is evidence it works, not that it is finished.

## References

- `.project/census/handoff-invariants-2026-09-09/` — the first census, and the artefact this ADR
  was decided against
- `docs/design-input/2026-08-27-census-store.md` — the design, whose derivation half this supersedes
- `docs/MODELS.md` — the BTE figures for the two reconciliation runs
- `docs/VERSIONING.md` — why an index schema change is MINOR

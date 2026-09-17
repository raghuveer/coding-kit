---
id: T-20260914-every-finding-consumer-still-counts-rows
title: Every finding consumer still counts rows, so one defect can hold a gate open twice
epic: feedback-loop
tier: T3
lang: sql
paths: tooling/kit-accel.sh, tooling/kit-status.sh, tooling/kit-resolve.sh
state: completed
---

## Intent

`finding.carries_over` exists and links a repeated finding to the row it repeats. **Only one
summary line reads it.** Every consumer that acts on finding counts still counts rows:

- **`kit-accel.sh:104`** earns an accelerator rule on `HAVING COUNT(*) >= $MIN`. A defect seen in
  three review rounds is three rows, so it can earn a rule on its own.
- **`kit-status.sh`'s criticals gate** counts unfixed critical *rows*. A carried-over critical
  marked fixed on one row leaves the other rows unfixed, so **the gate stays open for a defect
  that was addressed** — and the same generated file then says `N row(s) over M distinct
  defect(s)` in its header while its gate counts N.
- **`kit-resolve.sh --list`** lists rows, so an operator dispositioning a carried-over defect
  sees it once per round and must mark each.

Found by the blind second reviewer (rung 5) on the change that added the column, as
`false-rationale`: that change's own schema comment justified the column by accelerator seeding
and escape rate while leaving both counting rows. The comment is corrected; the behaviour is this
task.

## Acceptance criteria

- [x] The accelerator earning rule counts distinct defects, not rows, or states in the query why
      rows are the right unit there.
- [x] A carried-over critical, marked fixed once, leaves the criticals gate. Today it does not.
- [x] One generated `STATUS.generated.md` cannot contain two counts of the same findings that
      disagree. That self-contradiction is the symptom that makes this findable.
- [x] A check that can fail: a fixture with one defect across two rounds, one `--fixed` mark, and
      an assertion that the gate reads zero.


### Evidence, 2026-09-15 — all four met; the rule now has one home

**`finding.defect_id` is derived in `kit-index.sh`, not computed per consumer.** A recursive CTE
resolves each `carries_over` chain to its root once per rebuild. Two base cases, and the second is
the one that matters: a row whose link **dangles** is its own defect. Without it such a row reaches
no base case, its `defect_id` is NULL, and it drops out of the criticals gate — a gate may fail
closed and may never fail open. The `COALESCE` wrapper applies the same argument to a cycle, which
nothing writes today.

Every consumer reads `COALESCE(defect_id, id)`, so **an index built before the column behaves
exactly as it did**. Left as a bare comparison, NULLs make it never true, `NOT EXISTS` always true,
and the fixed test silently stops applying.

| AC | evidence |
|---|---|
| 1 — accelerator earns on defects | `kit-accel.sh`, all 17 row counts; the threshold line now says *"at least N DISTINCT DEFECTS"* |
| 2 — carried-over critical fixed once leaves the gate | `kit-preflight.sh --criticals` and the four gate populations in `kit-status.sh` share one `UNFIXED` predicate: a defect is addressed when **any** of its rounds is |
| 3 — one file cannot hold two disagreeing counts | the header's defect count was `rows - links`, a second formula that happened to agree. It now reads `COUNT(DISTINCT defect_id)` — the same column the gate reads, so agreement is by construction |
| 4 — a check that can fail | two steps, three mutations, each run alone |

**The mutations, separately, because a combined revert can pass while one slips through:**

| mutation | result |
|---|---|
| `defect_id` stops following the chain | FAIL — *"distinct defects=2, wanted 1 — defect_id is not derived"* |
| the gate returns to `f.fixed_at IS NULL` | FAIL — *"the gate reads 1 after the defect was addressed once, wanted 0"* |
| the earning rule returns to `COUNT(*)` | FAIL — *"one defect seen twice earned a rule"* |

**Two things the work found that the task did not name.**

*"All marked addressed"* became false the moment a defect spanned two rounds: one mark addresses the
**defect** and leaves the other **row** unmarked, so the sentence asserted a disposition nobody
recorded. That is the same false claim this section had to remove once before for `unassessable`.
It now prints *"N critical finding row(s) over M defect(s), every defect addressed"* when the two
differ, and the step asserts `all marked addressed` is **absent**.

The accelerator step's first assertion passed for the wrong reason — a bare `grep race` matched the
proposal's **below-threshold** section, where `race` correctly appears. Scoped to `[earned]` lines,
and the fixture now also carries a pair that **must** earn, so deleting the query outright cannot
pass the step.

**The open question in the Notes is untouched and stays open:** whether a carry-over chain should
collapse to its root for **severity** as well as for counting. Severity is still read per row here.

## Closed 2026-09-17 — what the close does and does not cover

All four criteria verified against the merged tree rather than against their own checkboxes:
`kit-accel.sh` (19 `defect_id` sites), the shared `UNFIXED` predicate in `kit-preflight.sh` and
`kit-status.sh`, `COUNT(DISTINCT defect_id)` at `kit-status.sh:94`, and the conformance steps.

**The Intent named three row-counting consumers and one is still untouched.**
`tooling/kit-resolve.sh` has zero references to `defect_id` or `carries_over`, so `--list` still
shows an operator one row per review round for a single defect. **No criterion covered it**, which
is why this closes rather than staying open — but the close is by contract, not by Intent, and
saying so here is the difference between a closed task and a forgotten one. It is benign for the
gate: any marked round now clears the defect, so nobody is blocked. Filing it separately is
proposed and awaiting the operator; it is not filed by this commit.

**No finding rows were recorded on 2026-09-15**, the day this work was done. The Notes below assert
"neither reviewer raised it". That assertion is not corroborated by the record, and a T3 closing
with no recorded review is worth seeing rather than inferring.

**Nothing on this repository changes numerically.** 0 of 635 findings carry a `carries_over` link,
so every count is identical before and after; the behaviour is fixture-only until a review round
records one.

## Notes

**Deliberately not fixed in the change that created the column.** Rewriting what a gate counts is
a behaviour change to a control, and folding it into a change that adds a column would have made
one commit both add a mechanism and alter what an existing gate admits. The link had to exist
before any consumer could use it; this is the consumer half.

**Tier T3 on the gate, not on the query.** `tooling/**` floors at T2 here, but the criticals gate
decides whether a trial may start at all, and a change that makes it admit *more* is the failure
direction that cannot be caught by a green suite.

**One open question, for whoever takes it:** whether a carry-over chain should collapse to its
root for severity as well as for counting. A minor carried over from a critical, or the reverse,
has no obvious answer and neither reviewer raised it.

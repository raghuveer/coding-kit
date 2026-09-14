---
id: T-20260914-every-finding-consumer-still-counts-rows
title: Every finding consumer still counts rows, so one defect can hold a gate open twice
epic: feedback-loop
tier: T3
lang: sql
paths: tooling/kit-accel.sh, tooling/kit-status.sh, tooling/kit-resolve.sh
state: created
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

- [ ] The accelerator earning rule counts distinct defects, not rows, or states in the query why
      rows are the right unit there.
- [ ] A carried-over critical, marked fixed once, leaves the criticals gate. Today it does not.
- [ ] One generated `STATUS.generated.md` cannot contain two counts of the same findings that
      disagree. That self-contradiction is the symptom that makes this findable.
- [ ] A check that can fail: a fixture with one defect across two rounds, one `--fixed` mark, and
      an assertion that the gate reads zero.

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

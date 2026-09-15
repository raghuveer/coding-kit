---
id: T-20260914-a-finding-that-was-never-a-defect-has-no
title: A finding that was never a defect has no disposition and vindicate is too coarse to give it one
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-vindicate.sh, tooling/kit-resolve.sh, tooling/kit-status.sh, tests/conformance.sh
state: created
---

## Intent

A finding row that was **never a defect** — a probe, a reviewer's false positive, a row written to
prove the instrument works — cannot be dispositioned. All four existing doors make a different
claim, and `.claude/CLAUDE.md` is explicit that they are not synonyms:

| door | the claim it makes | why it is wrong here |
|---|---|---|
| `kit-resolve.sh --fixed` | it was addressed | nothing was addressed |
| `kit-resolve.sh --unassessable` | nobody can tell what it said | these are perfectly legible |
| `kit-resolve.sh --superseded` | its subject was withdrawn | nothing was withdrawn, and the guard needs a `Superseded-by:` marker |
| `kit-vindicate.sh --false` | it was not real — **the right claim** | **keyed on `(task, class)`, not on a finding** |

So the only command that makes the right claim cannot be aimed at the row that needs it.

### Measured 2026-09-14, and the coarseness is not an edge case

    findings  fixed  refuted  confirmed
       635      79       0         0

    (task, class) pairs holding more than one finding      53
    findings living in such a pair                        604   -- 95% of the table

`kit-status.sh` already knows this and guards against it: *"`kit-vindicate.sh` keys on (task, class)
and updates every finding matching both, so on a task carrying two `fail-open` findings a single
`--false` about the harmless one ALSO refutes the critical"*. Its gate therefore honours a
refutation **only when the finding is the sole one of its class on its task**.

**That predicate is satisfiable for 31 of 635 rows.** For the other 95% the command either does
nothing the gate will believe, or silently refutes findings nobody judged. The guard is correct and
it is not a substitute for row-level granularity.

**`vindicated` has never been written. 0 refuted, 0 confirmed, across 635 rows.** The mechanism has
existed for weeks and has never carried a single value — which is the same shape as `agent_id`
(54 set, 0 joining), `carries_over` (0 of 635) and `Fixes-Escape-Of:` (0 commits). A field that
passes a conformance fixture is not a field anyone can use.

### The two rows that produced this

Both are from trial 2, both are probes of mine, and they divide exactly on the coarseness:

- `2026-09-14T17:51:52Z:f8f0b135` — `(T-20260914-kit-finding-accepts-any-agent-id-so-54-o, correctness)`
  holds **1** finding, so `--false` is safe and unambiguous. Proposed to the operator.
- `2026-09-14T14:03:11Z:133edeee` — `(T-20260808-trial-the-kit-on-one-unfamiliar-brownfie, fail-open)`
  holds **8**, and the other seven are real trial findings. **There is no way to retire this one
  row**, and laundering seven real findings to tidy one probe is worse than leaving it open.

## Acceptance criteria

- [x] A finding can be marked *not a defect* **by its own id**, with a required reason, making the
      same claim `kit-vindicate.sh --false` makes at `(task, class)`. Whether that is a new flag on
      `kit-resolve.sh` or a `--finding` mode on `kit-vindicate.sh` is the decision to make; the two
      commands answer deliberately different questions and merging them is not obviously right.
- [x] `kit-status.sh` counts these **apart** from fixed and apart from unassessable, and never folds
      them into zero — as it already does for the other two permanent marks.
- [x] The existing `(task, class)` behaviour is **kept**, not replaced. It is the right granularity
      for a reviewer whose whole class of finding on a task was noise, and the accelerator ladder
      reads it.
- [x] A conformance step marks one finding of several sharing a `(task, class)` pair and asserts
      that **only that row** is refuted. Mutation-proved: widen the key back to `(task, class)` and
      the step goes red.
- [x] Operator-reserved, like `--fixed` and `--unassessable`, for the reason `.claude/CLAUDE.md`
      gives: a session certifying its own output is the signature that carries no information.

## Notes

Filed 2026-09-14 from dispositioning trial 2's findings. **Found by trying to do the paperwork**,
not by reading the code — every door was read in turn and each made a claim that was false about the
row in hand.

Related: `T-20260820-marking-findings-is-one-at-a-time-so-the` is the throughput half of the same
write-only record — *how many* marks get applied. This is the vocabulary half: **a mark that does
not exist cannot be applied at any rate.** They are worth doing together and neither blocks the
other.

**Not proposed here:** whether a probe should be recordable at all. The row that prompted this was
written by testing a record-time warning through the real door, in the kit's own repository, which
is the same contamination mistake the trial-2 pre-flight made against the subject. A rule against
probing through the real door would prevent the row; it would not give the 604 existing ones a
disposition.

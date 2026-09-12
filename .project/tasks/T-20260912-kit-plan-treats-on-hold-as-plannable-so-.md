---
id: T-20260912-kit-plan-treats-on-hold-as-plannable-so-
title: kit-plan treats on-hold as plannable so parking a task has no effect on the plan
epic: planning
tier: T3
lang: bash
paths: tooling/kit-lib.sh, tooling/kit-plan.sh, tooling/kit-status.sh, docs/adr/0008-the-task-state-vocabulary-and-its-partitions.md, tests/conformance.sh
state: created
---

## Intent

**ADR 0008 left this question open, and this task is the evidence it said was missing.**
`docs/adr/0008-the-task-state-vocabulary-and-its-partitions.md:305-307`: *"Whether `kit-plan.sh`
should surface `on-hold` differently from `created` in its layering — both are open, both are
plannable, and no evidence here says they should differ."*

**The evidence.** The operator parked `T-20260826-a-verified-claim-about-the-tree-has-no-a` on
2026-09-09 (commit `5103188`, 22:03). It had already been rank 1 at score 20.000 in the plan
committed at `80b95fc`, earlier the same day, when its state was still `created`. On 2026-09-11,
`kit-plan.sh --next 12` still put it first. **Parking changed nothing.** The planner drops only
closed states (`kit-plan.sh:160-189`), and ADR 0008 classes `on-hold` as open.

So the operator's only way to say "not now" is invisible to the planner, and a session that
takes the top of `kit-plan.sh --next` starts the parked task.

**Where the score comes from** (`kit-plan.sh:314-325`, `:348`): `w_unblocks × unblocks + w_escapes ×
escapes + w_tier × tier`. `unblocks` counts *transitive*, open, non-withheld dependents — here 6,
because none of the six has dependents of its own. 6 × 3 = 18, plus tier 2 × 1 = 2, and escapes are
0. The index holds the task at T2, from a `Tier:` trailer, although its frontmatter says `tier: T3`.

**A second gap in the same place.** `kit_plan_digest` (`kit-lib.sh:105-107`) hashes the open tasks
only. So parking or un-parking a task never marks the plan stale, even once parked tasks are
excluded from it.

## Acceptance criteria

- [ ] ADR 0008 is amended to record the decision: `on-hold` is not plannable. "Plannable" is defined
      once, as a `kit_state_*` partition in `kit-lib.sh` — the home ADR 0008 gives state partitions,
      from which `state_class` is derived. The plannable decision names no state anywhere:
      `kit-plan.sh` and `kit-status.sh` ask the partition. (Counts of the closed states by name,
      such as `kit-status.sh:63-65`, are not this decision and stay as they are.)
- [ ] A parked task, and every task that depends on it transitively, are absent from the plan rows.
      They are withheld through the existing withholding path (`kit-plan.sh:283-309`, `:394-396`),
      counted and named together with their parked root. They are reported separately from
      unresolved-blocker and cycle withholding, which `kit-status.sh` treats as an alarm.
- [ ] The fix does not treat `on-hold` as a closed state. Doing that drops the `blocked_by` edge
      (`kit-plan.sh:163-164`), and the dependents then land in layer 0 as though nothing blocked
      them.
- [ ] `kit_plan_digest` partitions on the same property, so parking a task and un-parking it each
      mark the plan stale.
- [ ] `kit-status.sh` labels each parked task as parked and shows how many tasks wait on it. It
      already lists `on-hold` tasks under Open (`kit-status.sh:52-55`); the label and the count are
      the only additions.
- [ ] Conformance fixture: an `on-hold` task with two dependents, one of which has a dependent of
      its own. Assert that the parked task and all three dependents are absent from the plan file's rows
      — not merely from `--next`, whose output is capped (`LIMIT $NEXT`, `kit-plan.sh:618`) — and
      are reported under the parked root, and that parking the task marks the plan stale. Mutations,
      each of which must fail the step: (a) removing the exclusion, which puts the parked task back
      into the layer; (b) treating `on-hold` as closed, which drops the edge and puts the dependents
      in layer 0; (c) restoring the closed-only filter in `kit_plan_digest`, which leaves parking
      without a stale notice.

## Notes

**T3 on risk, not because of a floor.** The declared paths floor at T2 (`tooling/**`). But the
planner decides what auto-mode works on, and both ways of getting this wrong are quiet. Treating
`on-hold` as closed mis-orders its dependents into layer 0 (the third criterion). The correct
fix, withholding, removes work from the plan — and `kit-plan.sh:304-308` warns that a plan which
has lost work reads exactly like a finished one unless the loss is counted and named (the second
criterion).

Related: `T-20260818-nothing-reviews-the-plan-so-a-wrong-orde`, since nothing reviews the plan.
`T-20260808-task-state-cannot-express-no-longer-rele` asked for a "no longer relevant" state, and
ADR 0008 added `cancelled` for that — so that task may already be satisfied, which is worth checking
separately.

Reviewed before filing by an independent reviewer, who reproduced the defect in a fresh repository:
a parked T1 task with two dependents scored 7.000 and ranked first, ahead of a free T3 task at
3.000. Found on 2026-09-11 when the operator asked the planner what to do next. Filed before any fix.

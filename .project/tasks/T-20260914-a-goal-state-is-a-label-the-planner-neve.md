---
id: T-20260914-a-goal-state-is-a-label-the-planner-neve
title: A goal state is a label the planner never reads
epic: planning
tier: T2
lang: bash
paths: tooling/kit-plan.sh, tooling/kit-status.sh
state: created
---

## Intent

`#goal_state` gives a milestone a state in text and derives it into `goal.state`, which is what
`schema.sql` asked for and it is all it does. **Nothing in the kit reads that state back.** Two
consequences, measured on a two-goal fixture on 2026-09-14, the day the header shipped:

**A `completed` goal still plans and packs.** Marking `trial-2` completed changed nothing:
`kit-plan.sh --goal trial-2 --next 3` wrote three cluster packs and listed all three tasks as
next work. Whether that is right is a decision nobody has taken — a finished milestone might
reasonably freeze, or might keep planning because "completed" describes the milestone and not
the backlog behind it — but today it is not a decision, it is an absence.

**`--goal-state` runs a full replan, and that is worst exactly where it matters.** Setting a
state recomputes the ordering and rewrites the packs, so a milestone cannot be marked finished
without also re-ordering it. A completed milestone is precisely the one whose ordering should
stop moving. `--packs` already exists as a mode that reads the plan on disk without recomputing,
so the shape of a fix is in the file already.

## Acceptance criteria

- [ ] What a closed goal means to the planner is **decided and written down**, not left to the
      absence. Either its tasks leave the plan, or they do not and the reason is recorded where
      the next reader will look.
- [ ] A state can be set **without recomputing the ordering**. The ordering and the milestone's
      state are separate facts and one must not silently rewrite the other.
- [ ] A check that can fail for whichever way the first criterion is decided. "It plans" and "it
      does not plan" are both testable; an undecided state is not.
- [ ] `kit-status.sh` distinguishes a closed goal's counts from an open one's. It prints the
      state today and nothing else changes, so a completed milestone's open tasks still land in
      the aggregate as though the milestone were running.

## Notes

Filed 2026-09-14 from an audit of the change that introduced `#goal_state`, at the operator's
direction, before any fix. The header itself is not in question — it does what it claims and is
proven on three platforms.

**Deliberately one task and not two.** Both symptoms are the same root cause: the state has no
relationship to planner behaviour. Filing them separately would put one fact in two artefacts,
which is `T-20260826-two-artefacts-carrying-one-fact-with-not` and which this backlog has nine
instances of already.

**Not filed, because it already exists:** that two goals share every task —
`--goal` names a plan file and there is no membership, so a second goal is a second full
ordering of the same backlog. That is `T-20260819-goals-are-the-milestone-mechanism-and-on`
AC1 verbatim, and the two-goal fixture that produced these findings is recorded there as the
evidence that criterion asked for.

---
id: T-20260819-goals-are-the-milestone-mechanism-and-on
title: Goals are the milestone mechanism and only default has ever existed
epic: planning
tier: T2
lang: bash
paths: tooling/kit-plan.sh, tooling/kit-status.sh, skills/task-context/SKILL.md
state: open
---

## Intent

`goal` plus `plan_item.goal_id` **is** a milestone: a named subset of the backlog with its own
ordering and its own packs. Verified 2026-08-19 — the `goal` table holds exactly one row,
`default`, and it always has. The mechanism has never been used for the thing it is.

This matters now because ADR 0004 made it viable on 2026-08-17. Before that a rebuild deleted the
plan, so a second goal would have survived exactly as badly as the first. Durable, committed goals
are the precondition, and it has only just been met.

**MVP is one OPTIONAL use of this, not a stage every project passes through** (operator, 2026-08-18).
Some projects go straight to v1.0; a brownfield adoption may have no MVP; a modernization runs in
phases that are not "MVP" in any sense. The mechanism must carry any of those without privileging
one, and nothing in the kit should require a milestone to be named "MVP" to behave correctly.

**The greenfield→brownfield transition is computable and name-independent.** Greenfield has no
`touches` edges, an empty co-change graph, and no findings; when those fill, the project is
brownfield whatever the milestone is called.
`T-20260814-one-entry-mechanism-brownfield-is-the-ge` already argues brownfield is the general case
and the other two are its starting conditions — this is that same argument over time rather than
at adoption, and the kit currently decides entry mode once and never revisits it.

## Acceptance criteria

- [ ] A second goal can be planned, packed and worked without the first being disturbed —
      demonstrated, not asserted. Two goals sharing a task is the interesting case, and what
      happens then must be decided rather than discovered.
      **Demonstrated 2026-09-14, and the answer is that they share EVERYTHING.** A fixture with
      three tasks, `default` and `trial-2`, indexed: `plan_item` holds `T-a,T-b,T-c` under each.
      `--goal` names a plan FILE and there is no membership anywhere, so a second goal is a
      second full ordering of the same backlog rather than a subset of it. The states are
      genuinely independent (`default: in-progress`, `trial-2: completed`) and the packs are
      written per goal, so the mechanism carries a milestone's identity — it just does not carry
      its scope. **This criterion is therefore not met and is now blocked on a decision rather
      than on an experiment:** what SELECTS a task into a goal. **PROPOSED 2026-09-18 as ADR 0013:
      a goal is an independently ordered VIEW of the whole backlog, not a subset; membership is
      deferred, with a named trigger that reopens it. If accepted, this criterion is already
      satisfied on that reading — but reading a criterion as met is the operator's call, so the
      box stays unticked until the ADR is accepted.** Discovered while auditing
      `#goal_state`; the ordering half of that is `T-20260914-a-goal-state-is-a-label-the-planner-neve`.
- [ ] `kit-status.sh` reports per goal. Today every figure is implicitly `default`, so a second
      goal would silently merge into aggregate counts and no one would see it.
- [ ] The **project's entry mode is derived, not fixed at adoption** — the predicate above run on
      current state, so a project that has become brownfield is reported as brownfield.
- [ ] Nothing requires a milestone to be called MVP, v1, or anything else. A naming convention
      that changes behaviour is a second vocabulary, and this repository has paid for those.
- [ ] `skills/task-context` step 4 resolves the pack for the task's **own** goal. It reads
      `goal_id` from `plan_item` already; confirm that survives a second goal rather than assuming
      it, since every existing execution has had exactly one to choose from.
- [ ] A check that can fail, with two goals in the fixture — every existing conformance step
      builds a single-goal fixture, so this whole surface is currently unexercised.

### Decision, 2026-09-14 — operator: a goal is a ROOT TASK plus its `blocked_by` closure

AC1 asked what happens when two goals share a task, and the 2026-09-14 demonstration answered
that today they share *everything*: `--goal` names a plan FILE and no membership exists anywhere.
The operator's decision closes that question by deriving membership rather than declaring it.

**A goal is named by one task, and contains that task plus everything reachable through
`blocked_by`.** Nothing else selects into it.

Three things recommended it over the alternatives, and they are worth keeping because the
alternatives will look attractive again:

- **No new frontmatter key.** A `goal:` field on every task would be a second place to say what
  `blocked_by` already says, and this backlog carries nine instances of
  `T-20260826-two-artefacts-carrying-one-fact-with-not`.
- **No second vocabulary.** `blocked_by` is already the one edge `kit-plan.sh` reads. Membership
  derived from it cannot drift from the ordering, because it *is* the ordering.
- **The case already exists.** `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` plus its
  13 blockers is exactly this shape, and it exists because a real milestone needed it rather
  than because a design imagined one. AC1's own note asked for a real project with phases.

**Two goals sharing a task is therefore legal and means what it says** — the task is reachable
from both roots, and neither goal owns it. What must NOT follow is a second ordering for that
task: the plan still holds one row per task per goal, and `plan_item`'s primary key already
enforces it.

**Not decided here, deliberately:** whether a closed goal withholds its members from the plan.
That is `T-20260914-a-goal-state-is-a-label-the-planner-neve`, and it is a different question —
this one is about what a goal CONTAINS, that one about what its state DOES.

## Notes

Filed 2026-08-19 from an audit of `docs/design-input/2026-08-18-authoring-chain-and-review-economics.md`
§5 against the backlog, which found the section had no task.

**Unblocked, but low value until something needs two milestones.** The honest sequencing is that
this waits for a real project with phases — most likely the brownfield trial or a modernization
subject — rather than being built speculatively against an imagined second goal. Building it now
would mean inventing the two-goal semantics with no case to check them against.

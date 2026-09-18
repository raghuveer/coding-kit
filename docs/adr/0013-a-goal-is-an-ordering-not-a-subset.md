<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# ADR 0013: A goal is an independently ordered view of the whole backlog, not a subset of it

- **Date:** 2026-09-18   **Status:** **Proposed**   **Accepted:** not yet — an ADR here is
  accepted by the operator
- **Related:** [[0004-where-the-plan-lives]], [[0012-which-ordering-governs-what-to-do-next]]
- **Answers:** the decision `T-20260819-goals-are-the-milestone-mechanism-and-on` AC1 is blocked
  on — *what selects a task into a goal*

## What the experiment already settled

The 2026-09-14 fixture (three tasks, `default` and `trial-2`) established that a goal carries
**four of the five properties a milestone needs**, and is missing one:

| property | works today |
|---|---|
| identity — a goal is named and durable | **yes**, since ADR 0004 made the plan survive a rebuild |
| ordering — its own rank over the backlog | **yes**, `plan_item.goal_id` |
| state — independent of other goals | **yes**, `default: in-progress` beside `trial-2: completed` |
| packs — written per goal | **yes**, `.project/packs/<goal_id>/` |
| **scope** — which tasks are IN it | **no**, and that is the whole question |

So the decision is not *how to implement membership*. It is **whether a goal needs scope at all,
yet.**

## Decision

**A goal is a named, independently ordered, independently stated view of the WHOLE backlog.
Membership is not implemented, and is deferred until a real milestone demands it.**

## Why not the obvious mechanisms

**Not by epic.** 199 of 216 tasks carry one, so coverage is not the problem — the axis is.
`measurement`, `validation`, `planning`, `portability` are **categories**; a milestone is a
**time slice**. An MVP is not "all of `measurement`". Conflating them would make every goal either
a category or a lie.

**Not by dependency closure from named outcomes.** Elegant, computable, name-independent — and
dead on arrival here: **26 of 216 tasks carry any `blocked_by` at all.** A goal defined as the
closure of its outcomes would come out nearly empty, and would silently grow the day someone added
an edge for an unrelated reason.

**Not yet by an explicit `goals:` field on the task.** This is the one that would work, and it is
what to build **if** the trigger below fires. It puts membership where this kit says truth lives —
in the task file — and a list handles a task serving two milestones. It is deferred rather than
rejected.

## Why deferral rather than building the field now

**The `goal` table has held exactly one row, `default`, for its entire existence.** No second
milestone has ever been run. Designing scope for a use nobody has attempted is the failure this
repository has paid for most often and most recently — nine blind reviews rejected four mechanisms
in a single day, and `docs/LESSONS.md` §1 and §12 are both about controls and harnesses built
ahead of the thing they were meant to serve.

Deferring costs nothing that can be pointed at today. Building costs a schema field, an ingest
path, a planner filter, a conformance step, and a migration for 216 task files — spent against a
requirement nobody has stated.

## The cost of this decision, stated so it is not rediscovered as a defect

**Scope-by-parking is GLOBAL.** Today the only way to hold a task out of a plan is its state
(`on-hold`), and state is a property of the task, not of the task-in-a-goal. So:

> **A task cannot be in milestone A and out of milestone B.** Parking removes it from every goal
> at once.

That is the precise limitation this ADR accepts. It is invisible while one goal exists and becomes
sharp the moment two disagree.

## The trigger that reopens this

**The first time two goals must disagree about whether a given task is in scope.** At that point
build the explicit `goals:` list on the task file, informed by the actual milestone that needed it
rather than by this document's guess at one.

Not a date, and not "when we have time". A named condition, so the deferral cannot quietly become
a decision nobody revisits — which is the other failure mode this repository records, as folklore
in `T-20260822`'s "an open investigation with no owner becomes folklore".

## What this does not decide

It does not tick `T-20260819` AC1. That criterion asks for a second goal *planned, packed and
worked without the first being disturbed*, and under this ADR that is **already true** — but
reading a criterion as satisfied is the operator's call, not a consequence this ADR may assert.

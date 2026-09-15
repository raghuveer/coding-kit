---
id: T-20260915-divergence-is-computable-for-no-class-of
title: Divergence is computable for no class of definition and has never been proven to fire
epic: components
tier: T3
lang: markdown
paths: docs/design-input
state: created
---

## Intent

`docs/design-input/2026-08-22-auto-mode-is-a-graduation.md` §6 lists seven things a project must
have before it can be run unattended. Item 2 is:

> **Divergence is computable** for each class of definition, and has been **proven to trigger** at
> least once. An escalation path that has never fired is not known to work.

§6 then names it outright: *"Item 2 is the one with no mechanism at all today."* §7 lists divergence
detection under *"New, and absent from the previous roadmap entirely."*

**It is also absent from the backlog, which is why this exists.** Measured 2026-09-15 across all
211 task files: `grep -ril graduat .project/tasks/` returns **zero**; "divergence" appears in six
files and every occurrence is incidental — a glob resolving differently on two floor paths, plan
ordering, the awk surface. No task is about the mechanism. So the roadmap named this the first
graduation blocker and nothing in the backlog could ever surface it: the planner orders what
exists.

**What the requirement rests on.** §3 makes the interrupt budget the constraint, and reads the
operator's words as a rule: *an escalation must name which recorded definition was breached* — not
uncertainty, not risk, not confirming-before-proceeding. That forces definitions to be **checkable
artifacts rather than prose**. Today only tier floors are computed. Approach, plan-adherence and
acceptance criteria have no divergence mechanism at all, which produces the failure §3 names: **an
under-specified project runs quietly and wrongly, because a definition that does not exist cannot
be diverged from.**

## Acceptance criteria

- [ ] The classes of definition are enumerated from what the kit already records, not invented —
      §3 names approach, plan, acceptance criteria and tier floors, and only the last is computed.
- [ ] For each class it is stated whether divergence is computable today, and if not, what the
      cheapest reading would be. **A class that cannot be computed is recorded as such**; an
      absence stated is the point, per absent-is-not-zero.
- [ ] Nothing is designed in this task. It is a filing, and the mechanism is a separate decision —
      see Notes for why that boundary is drawn here.
- [ ] A check that can fail, when a mechanism does land: divergence is **proven to trigger once**
      against a planted breach, the way the recorded-zero proof works for spend. An escalation path
      that has never fired is not known to work, and a green suite cannot distinguish the two.

## Notes

Filed 2026-09-15 on the operator's instruction, after a check established that three of the seven
graduation-checklist items — this one, `T-20260915-no-budget-cap-binds-so-an-unattended-run` and
`T-20260915-disposition-delegation-is-undecided-so-e` — had **no task at all**. Filed together and
deliberately as **filings only, with no mechanism proposed.**

**Why no design is attached, and this is the load-bearing part.** On 2026-09-09 four mechanisms
were designed for one operator ruling and nine blind reviews returned REJECT x7 / REVISE x2, while
every measurement underneath them held exactly. That day produced 947 lines of design prose and 0
lines of shell. Divergence detection designed today would be the fifth such mechanism, and it would
be designed against instruments currently reading `0/0` escape rate, `0` refuted, `0` confirmed and
`0` joinable findings. The recorded lesson is to build the smallest reporting thing first and let
use name the vocabulary — so the first move here is a report of which definitions exist, not a
gate.

Related: `T-20260819-goals-are-the-milestone-mechanism-and-on` (item 6, the unit of delegation),
`T-20260811-restore-session-state-from-checkpoint-co` (item 7, the resume path).

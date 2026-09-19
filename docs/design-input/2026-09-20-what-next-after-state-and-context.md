<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# What governs "what next" after the state-and-context document runs out

**Status: PROPOSED. Not governing until the operator accepts it.** ADR 0012 makes a named
ordering document the thing that decides sequencing, and its clause 5 says that when the current
one runs out the answer is a successor or an amendment -- not a quiet fall-through to
`kit-plan.sh`. Section 6 of `2026-09-14-state-and-context.md` has run out. This is the successor
it asks for, offered to be argued with rather than obeyed.

## 1. Section 6 is finished, item by item

Re-derived from `index.db` on 2026-09-20, not from any earlier summary:

| item | subject | outcome |
|---|---|---|
| 1 | the spend instrument | completed |
| 2 | spend as-of time | completed |
| 3 | `#goal_state` | **was already built** -- shipped `abdbefe` on 2026-09-14, the day section 6 was written. Found, not done |
| 4 | `paths.state` moves everything | completed, #154 |
| 5 | vocabularies in shell constants | split to T2 and landed as #157; the T3 projection design remains under its parent |
| 6 | reduce peak context | **the one item left**, 1 of 4 criteria |
| 7 | cluster-pack ROI | unblocked by #158 |
| 8 | pack file list | completed, #158 |

Item 3 is worth keeping in view: a governing document listed as work something that had shipped
the same day it was written. That is not an argument against ordering documents. It is an argument
for re-deriving state when you read one.

## 2. The principle this order uses, and where it comes from

**Fix the instruments, then measure with them.** This is not invented here. Section 6 opens with
*"First -- the instrument, because everything after it is measured against a series"* and puts the
spend instrument ahead of everything else. This document keeps that principle and applies it to a
different set of instruments, because the last change exposed three that cannot fail.

The evidence comes from the branch that closed items 7 and 8, on 2026-09-19:

- **The conformance suite stayed green through four consecutive core dumps of the indexer.**
  `kit-index.sh` crashed under mawk on `ubuntu-latest` on every commit of that branch -- twice
  `malloc_consolidate`, twice a segmentation fault -- while `conformance (ubuntu-latest)` passed
  on the same runner in the same workflow each time. Only the job that indexes the real backlog
  saw it, and it saw it by accident.
- **Findings still cannot be joined to the runs that produced them.** 580 of 635 carry no agent id.
- **A declared verify rung that fails has no disposition**, so work can complete unverified. That
  is how trial 1 recorded COMPLETE for a change that does not compile.

A trial measures the kit *through* these. Running the next one first produces numbers carrying the
same defect trial 1's numbers had, which is the thing trial 2's blocker list was written to
prevent.

## 3. The order

**First -- finish what section 6 left, so the successor starts from a clean boundary.**

1. `T-20260912-reduce-peak-context-per-session-and-meas` -- 1 of 4, recorded **T2 against a T3
   floor**, so it carries a two-reviewer cost its recorded tier does not advertise. Its blocker
   closed when the spend instrument landed. Leaving one item of a finished document behind is how
   an ordering becomes ambiguous about which document governs.

**Second -- the three instruments the next trial reads through.**

2. `T-20260919-conformance-fixtures-are-too-small-to-ex` -- the suite cannot fail at real scale.
   Until it can, every other check in this list is trusted further than it has earned.
3. `T-20260911-a-finding-recorded-by-hand-carries-no-ag` -- a trial-3 blocker, and the
   580-of-635 join gap. "What did this reviewer cost and what did it find" is unanswerable for
   every run in the repository.
4. `T-20260912-a-declared-rung-whose-tooling-fails-has-` -- the other trial-3 blocker, T3. It
   decides whether a verdict means anything.

**Third -- the trial those three unblock.**

5. `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` -- **in-progress**, 4 of 11 criteria, and
   its blocker list is down to the two named above. Trial 2's own *"What was NOT exercised"*
   section is the trial-3 agenda: the verify ladder on a real code change, reviewer agents as
   kit-installed agents, `kit-task.sh` from a candidate line, and anything writing to the
   subject's tracked tree.

**Fourth -- the record a graduation needs, which blocks nothing and is therefore always
postponable.**

6. `T-20260919-operator-decisions-have-no-index-so-a-se` -- decisions live in four shapes with no
   index. ADR 0013 measured the cost: written, accepted and superseded within hours because the
   decision already existed, four days old, eleven lines below the criteria in a task file. In
   auto-mode a run that cannot enumerate what was decided cannot tell an escalation from a
   re-ask, so it must either interrupt too often or proceed against a decision it never saw.

## 4. What is deliberately NOT in this order, and why

**The two graduation blockers, because they are decisions rather than work.**
`T-20260915-divergence-is-computable-for-no-class-of` and
`T-20260915-disposition-delegation-is-undecided-so-e` are items 2 and 5 of the graduation
checklist, and that document names them as *the* two blockers -- one with no mechanism at all, one
pure design. Both are T3. Sequencing them behind a trial would be wrong; sequencing them ahead of
one commits the operator to a design pass. They need a ruling on scope before they can be ordered
at all.

**The two declared-path consumers**, `T-20260919-blast-radius-for-tier-classify-still-rea` and
`T-20260919-cluster-assignment-is-touches-only-so-a`. Both change what feeds `tier-classify` or
the planner's clustering, which is to say how deeply future work is reviewed. That is a behaviour
change to the control governing every other control, and it wants its own decision rather than a
slot in a list.

**The planner's rank 1.** `T-20260808-make-the-security-assurance-cadence-a-po` scores 11.0, the
only task above 5.0, and is absent from this order exactly as it was absent from section 6. Under
ADR 0012 it stays not-next until an ordering document names it. **That is a consequence worth
seeing rather than a conclusion this document argues** -- ADR 0012's own sentence, and it still
applies.

## 5. What would falsify this

- **Section 2's principle**, if the three instrument tasks land and trial 3 still produces a
  number nobody can read. Then the problem was never the instruments and this was a detour.
- **Item 1**, if peak context needs its reduction half designed rather than measured. It is placed
  first because it is small and finishes a document, not because it is urgent. If it is not small,
  it belongs after the instruments.
- **Item 2**, if a scale fixture cannot reproduce the mawk crash. That task requires the failure to
  be said rather than worked around, and if it cannot be reproduced then a scale step is a weaker
  control than this document assumes.
- **Section 4's deferral of the graduation blockers**, if the operator rules that graduation work
  leads and trials follow. That inverts the whole order and is a legitimate reading of the goal
  chain: the terminal goal is multiple projects in auto-mode, and trials are evidence toward it
  rather than the thing itself.

## 6. How to use this, and how to depart from it

ADR 0012's clauses carry over unchanged. The planner answers **what is eligible** and ranks within
whatever this selects; it is not consulted for "what next" on its own. A departure is allowed and
is argued **in the commit that departs**, not in a summary afterwards. Neither this order nor
section 6 becomes `blocked_by` edges -- a mistyped id once withheld 20 of 22 open tasks, and an
ordering that is wrong should misdirect one session rather than silently empty a backlog.

**When this document runs out, the same clause applies to it.**

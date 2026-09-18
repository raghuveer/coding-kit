<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# ADR 0012: Which ordering governs "what next", and what the planner is for

- **Date:** 2026-09-18   **Status:** **Proposed**   **Accepted:** not yet — this records a
  proposal, and an ADR here is accepted by the operator
- **Related:** [[0004-where-the-plan-lives]], [[0008-the-task-state-vocabulary-and-its-partitions]]
- **Answers:** the question `design-input/2026-09-14-state-and-context.md` §6.1 left open

## The problem, stated as a disagreement rather than a preference

Two orderings exist and they disagree. On 2026-09-18:

| | rank 1 | where S6's items sit |
|---|---|---|
| `kit-plan.sh` | `T-20260808-make-the-security-assurance-cadence-a-po`, score 11.0 | items 3, 4, 5 at ranks **61, 62, 114** |
| §6 of the state-and-context document | the spend instrument, then "the rule made total" | the planner's rank 1 appears **nowhere in S6** |

Neither is wrong. They answer different questions: the planner scores tasks; §6 sorts by **what
unblocks what**. The failure is not having said which one an agent should obey, and this
repository has already paid for that — §6.1 says so in its own words:

> an ordering argued in a document and an ordering the planner obeys are different claims, and
> this repository has paid for confusing them

**The planner cannot answer the question past about rank 13.** Measured over the planned tasks:
one at 11.0, five at 6.0, six at 5.0, one at 4.0, then **28 tied at 3.0 and 84 tied at 2.0**.
Below that, rank is a tiebreak and not a judgement — so "the planner says X is next" is a true
statement about a sort and a false one about priority.

## Proposal

**1. A named ordering document governs sequencing; the planner does not.** Where a current
design-input document states an order, that order decides what is next. Today that is §6 of
`2026-09-14-state-and-context.md`.

**2. The planner answers a different question and keeps it.** It is for *what is eligible* —
what is unblocked, unparked, and above its tier floor — and for ranking **within** whatever the
governing document selects. It is not consulted for "what should I do next" on its own.

**3. A departure is allowed and must be argued in the commit that departs.** Not in a summary,
not in a task file written afterwards. The commit that does the work says which item it skipped
and why, so the departure is reviewable in the same diff as the work. Precedent set 2026-09-18 by
the peak-context change, which took §6 item 6 ahead of item 4 and said so.

**4. Neither ordering becomes `blocked_by` edges.** §6.1 declined to convert its order into
blockers, and this does not overturn that. A mistyped id in a `blocked_by` once withheld 20 of 22
open tasks; an ordering that is wrong should misdirect one session, not silently empty a backlog.

**5. When the governing document runs out, say so rather than falling through to the planner.**
Four of §6's eight items are done or decision-blocked. A successor document, or an amendment,
is the answer — not a quiet switch to rank 1.

## What this does not decide

**It does not rank `T-20260808-make-the-security-assurance-cadence-a-po`.** The planner's only
task above 5.0 is absent from §6 entirely — 15 acceptance criteria, 0 met, T2. Under this ADR it
is not next, and that is a consequence worth seeing rather than a conclusion this ADR argues. If
it should be next, §6 is what needs amending.

**It does not claim §6 is correct.** It claims §6 is the thing to disagree WITH — in the open,
in a commit — rather than a document an agent may quietly out-rank by citing a score.

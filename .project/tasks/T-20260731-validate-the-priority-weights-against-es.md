---
id: T-20260731-validate-the-priority-weights-against-es
title: Validate the priority weights against escape data
epic: measurement
tier: T1
state: open
---

## Intent


## Acceptance criteria

- [ ] enough vindicated escapes exist to test the ordering
- [ ] the current weighting is compared against at least one simpler alternative
- [ ] the chosen weights are recorded with the data that justified them

## Notes

From HANDOFF §8. `unblocks x3 + escapes x2 + tier` is defensible, not proven. It was
chosen before any escape data existed. Recalibrate once the findings table has enough
vindicated escapes to test whether the ordering it produces beats the alternatives --
including the null hypothesis that a simpler weighting does as well.


---

## Folded in 2026-08-11: a second routing axis (R-15)

Recalibrating the weights is one half. The other is that a single axis is currently doing two
jobs, which is why T3 gets over-selected.

Split them: **blast radius decides how much process** (which tier), **change type decides which
reviewers** (user-facing, developer-facing, architectural). `skills/tier-classify` implements the
first axis only.

Acceptance to add: the tier distribution shifts toward T1/T2 without a rise in findings escaping
to T3-worthy incidents. Both halves must be measured — a shift alone is just under-tiering.

Depends on the same evidence this task already waits for: enough vindicated escapes in the
finding table to tell calibration from wishful thinking.

**2026-09-11 — the current scores barely order the backlog, and new weights alone will not fix
that.** `kit-plan.sh` was refreshed over the 145 open tasks on 2026-09-11, before the batch filed
alongside this note (plan digest `2096380340-10757`). It put 135 tasks in layer 0 and 10 in layer 1.

Scores across both layers (`score` column of `.project/plans/default.tsv`):

| score | all 145 tasks | layer 0 only |
|---|---|---|
| 20.000 | 1 | 1 |
| 8.000 | 1 | 1 |
| 6.000 | 2 | 2 |
| 3.000 | 31 | 27 |
| 2.000 | 85 | 80 |
| 1.000 | 22 | 21 |
| 0.000 | 3 | 3 |

Within a layer, `kit-plan.sh` orders tasks by the strongest cluster first, then by score, then by
id (`kit-plan.sh:204-211`). With 80 of the 135 layer-0 tasks on 2.000, most of that order comes
from cluster and id, not from the score.

**Recalibrating the weights will not break those ties, because they come from the inputs.**
`unblocks` and `escapes` are zero for most tasks, so the score is mostly tier alone (1 to 3). This
task's criteria cover the weights only. Breaking the ties needs inputs that vary: declared
dependencies and vindicated escapes. Today, 14 open tasks declare `blocked_by`, with 20 edges
between them; only 10 of those edges point at an open task, and just 4 open tasks have any open
dependent.

The single 20.000 is a parked task at the head of a chain: six dependents × `w_unblocks` 3, plus
its tier. That defect is filed as `T-20260912-kit-plan-treats-on-hold-as-plannable-so-`.

**Why this matters now:** the operator has asked for the whole backlog to be evaluated and
prioritised by dependencies, and that ranking cannot rely on these scores.

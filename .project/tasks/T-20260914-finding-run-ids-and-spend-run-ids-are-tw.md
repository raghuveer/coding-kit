---
id: T-20260914-finding-run-ids-and-spend-run-ids-are-tw
title: Finding run ids and spend run ids are two different id spaces
epic: measurement
tier: T2
lang: sql
paths: tooling/kit-finding.sh, tooling/kit-status.sh, tooling/schema.sql
state: created
---

## Intent

`finding.agent_id` now exists and is derived, so a finding can be joined to the spend row of the
reviewer run that produced it. **48 findings in this repository carry an id and none of them
joins**, because the two columns hold values from different spaces:

| | values |
|---|---|
| `finding.agent_id` | `blind-second`, `design2`, `entry-final`, `entry-impl` — operator-chosen run labels |
| `spend.agent_id` | `a070ab68df6ac0287` — the harness's Agent-tool subagent id, read by `kit-spend.sh` from `<session>/subagents/agent-<id>.jsonl` |

Measured 2026-09-14 on `main`: 628 findings, 580 with no id at all, 48 with an id matching no
spend row, **0 joinable**.

Both usages are defensible on their own. A label survives the session and is what a human writing
a review by hand would reach for; the harness id is what actually identifies the run that spent
the tokens. What is not defensible is one column holding both, because a join that silently
returns nothing reads exactly like a join over data nobody recorded.

## Acceptance criteria

- [ ] It is decided and written down which space `agent_id` holds, and the other one either gets
      its own column or is refused at the writer. A column that accepts both is the state this
      task exists to end.
- [ ] The 48 existing rows are dispositioned rather than left to look like failures — they were
      recorded correctly against the convention of their day.
- [ ] `kit-status.sh` keeps reporting the two faults apart. "No id" and "an id that matches
      nothing" have different remedies, and collapsing them would hide this defect class again.
- [ ] A check that can fail: a finding recorded with the harness id joins; one recorded with a
      label is reported, not silently dropped.

## Notes

Filed 2026-09-14 while wiring `finding.agent_id`, at the operator's direction, before any fix.

**This is not the gap `T-20260911-a-finding-recorded-by-hand-carries-no-ag` named.** That task
read the trial's 11 unattributed findings as a documentation gap — the flag existed, the usage
header and the skill did not mention it. That was half of it: the flag wrote into an event field
the indexer had nowhere to store, because `finding` had no `agent_id` column at all. The column
and the documentation are done; this is the third layer, and it is the one that needs a decision
rather than an edit.

**Deliberately not resolved by guessing.** Rewriting the 48 labels to harness ids is impossible —
those runs are gone — and widening the join to match either space would make an unjoinable
finding indistinguishable from a joined one, which is the fault itself.

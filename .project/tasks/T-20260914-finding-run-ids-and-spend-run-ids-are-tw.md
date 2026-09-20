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

- [x] It is decided and written down which space `agent_id` holds, and the other one either gets
      its own column or is refused at the writer. A column that accepts both is the state this
      task exists to end.
- [x] The 48 existing rows are dispositioned rather than left to look like failures — they were
      recorded correctly against the convention of their day.
      **DISPOSITIONED 2026-09-20 by the operator. They are legacy, not errors, and they are
      permanently unjoinable.** See the disposition below — and note the count is no longer 48.
- [x] `kit-status.sh` keeps reporting the two faults apart. "No id" and "an id that matches
      nothing" have different remedies, and collapsing them would hide this defect class again.
- [x] A check that can fail: a finding recorded with the harness id joins; one recorded with a
      label is reported, not silently dropped.

### Decision, 2026-09-14 — operator: `agent_id` holds the HARNESS id

`finding.agent_id` and `spend.agent_id` hold values from two spaces — operator-chosen run labels
(`blind-second`, `design2`) against the harness's subagent id (`a070ab68df6ac0287`) — so 0 of 628
findings join today.

**The column holds the harness id.** That is the value `spend` carries, and joining to the
reviewer run that produced a finding is the column's entire purpose: a label that cannot join
answers no question the column was added for.

**The 48 rows carrying labels are legacy, not errors.** They were recorded correctly against the
convention of their day, and they are dispositioned as such rather than rewritten — the runs they
name are gone, so no rewrite could recover the ids they would need.

**`kit-status.sh` keeps reporting the two faults apart** — no id at all, versus an id matching no
spend row. Collapsing them would hide exactly this defect class the next time it appears, and the
second count is what made this one visible.


### Evidence, 2026-09-15 — three of four verified and ticked; AC2 is the operator's

- **AC1** — the decision is recorded in this file and is now in the tool: `kit-finding.sh:5`
  states `--agent-id` is the reviewer RUN, distinguishes it from `--agent` (the role), and names
  `<session>/subagents/agent-<id>.jsonl` as where the value comes from. PR #132 made a
  non-resolving id say so at record time.
- **AC3** — `STATUS.generated.md` reports the two faults apart: *"580 of 635 carry no agent id,
  and 55 carry one that matches no spend row"*. Collapsing them would hide this defect class.
- **AC4** — `tests/conformance.sh`, step *"a finding joins the reviewer run that produced it, or
  is reported as unjoinable"*.

**AC2 is NOT met and is not the agent's to meet.** Dispositioning the 55 legacy rows means
marking them, and every mark that retires a finding is operator-reserved — `.claude/CLAUDE.md`
is explicit. `kit-vindicate.sh --finding ID --false --note TEXT` now exists to make it possible
at all (`T-20260914-a-finding-that-was-never-a-defect-has-no`); before it, the rows could not be
aimed at. The marks themselves are proposed, not run.

### Disposition of the non-joining rows, 2026-09-20 — operator

**Re-derived rather than carried forward: the count is 55, not 48, and they are THREE faults, not
one.** The 48 in this task's Intent was the label class alone, and seven more rows have landed
since it was written.

| id | rows | what it is |
|---|---|---|
| `blind-second` | 16 | operator-chosen run label |
| `design2` | 15 | operator-chosen run label |
| `entry-final` | 12 | operator-chosen run label |
| `entry-impl` | 5 | operator-chosen run label |
| `aa8f5759-c366-4687-b752-400b012601f0` | 3 | **a SESSION id** |
| `aa8f5759-…-audit` | 3 | a session id with a suffix |
| `preflight-probe` | 1 | a probe label |

**The 48 labels are legacy and are dispositioned as such.** They were recorded correctly against
the convention of their day, the decision of 2026-09-14 changed that convention, and the runs they
name are gone — so no rewrite could recover the ids they would need. They stay in the record and
are reported as a standing count rather than folded into zero.

**The 6 session-id rows are a DIFFERENT fault and should not be filed under the same heading.** A
session id covers every agent in the session and so identifies no single run;
`kit-finding.sh`'s help says exactly this and says it was written because five rows here had been
given one. They are equally unjoinable and equally unrewritable, but the *remedy* differs: a label
needs a convention, a session id needs the writer to refuse it. `kit-finding.sh` has refused a
non-resolving id at record time since PR #132, so this class is closed going forward — these six
predate it.

**No `kit-resolve.sh` mark is used, deliberately.** Its four marks are `--fixed`, `--unassessable`,
`--superseded` and `--false`, and **none of them means "recorded correctly, permanently
unjoinable"**. `--fixed` would claim something was addressed and nothing was; `--unassessable`
says nobody can tell what the finding said, and these are perfectly legible; `--false` says it was
never a defect, and they were real. Reaching for the nearest mark would destroy the distinction
this task exists to preserve. The disposition is this written record plus the standing count
`kit-status.sh` already prints apart from the no-id count.


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

---
id: T-20260919-the-goal-state-comment-says-unwritten-an
title: The goal.state comment says unwritten and it has been written since 2026-09-14
epic: reporting
tier: T2
paths: tooling/schema.sql
state: created
---

## Intent

**`tooling/schema.sql` tells the next reader that `goal.state` is dead, and it has been live for
five days.** The comment on the column says, in the present tense:

> *"RESERVED AND CURRENTLY UNWRITTEN. Nothing sets it and nothing reads it, and section 3c's
> `INSERT OR REPLACE` omits it, so every rebuild resets it to 'open'."*

**Every clause of that is now false**, and each was falsified by commit `abdbefe` (2026-09-14,
*"planning: a milestone's state is text in the plan, derived like every other column"*), which is
on `main`:

| the comment says | the tree says |
|---|---|
| nothing sets it | `kit-plan.sh:45` takes `--goal-state`, validates it at `:80` against `kit_state_written`, writes `#goal_state` at `:531` |
| nothing reads it | `kit-index.sh:1180,1232,1238` parses, validates and inserts it; `kit-status.sh:129` renders it and its own comment explains that it used to be invisible |
| `INSERT OR REPLACE` omits it | it is the fourth column of that INSERT |
| every rebuild resets it to `'open'` | it does not |

**Proved by round trip 2026-09-19, not by reading the diff:**

    bash tooling/kit-plan.sh --goal-state in-progress
    grep -m1 '#goal_state' .project/plans/default.tsv   ->  #goal_state  in-progress
    bash tooling/kit-index.sh
    sqlite3 .project/index.db "SELECT id,state FROM goal;" ->  default|in-progress

**Why this is worth a task rather than a silent edit.** The comment is not decoration: it is the
spec for the column, it names the condition under which the column may be used, and it points at
`T-20260819-goals-are-the-milestone-mechanism-and-on` as the task that would use it. A reader who
trusts it concludes that work is still to do. That is the same defect shape as ADR 0013 — an
artefact asserting the opposite of a decision that had already landed — and `docs/design-input/2026-09-14-state-and-context.md`
§3.2.1 records a third instance in `kit-lib.sh`, where a standing instruction still quotes a grep
count of 19 against a tree that answers 4.

## Acceptance criteria

- [x] The comment describes the column as written and derived, and names its text source
- [x] The condition it used to impose — a text source first, per ADR 0004 — is recorded as **met**,
      with what met it, rather than deleted. The constraint is still the reason the design is safe
- [x] The round-trip conformance step that selects `state` is confirmed to still cover it, so the
      guarantee the old comment claimed is shown to exist rather than assumed
- [x] No behaviour changes: `sqlite3 .project/index.db "SELECT id,state FROM goal;"` returns the
      same row before and after

### Evidence, 2026-09-19

The conformance step `a goal's state is text in the plan and survives a replan` was run against
this change and passed -- *"set, preserved across a replan, normalised from a legacy spelling,
refused at both doors"*. A filtered run is not a conformance pass and the suite says so; the full
matrix runs in CI.

`SELECT id,state FROM goal;` returned `default|in-progress` before the edit and after a rebuild
following it.

## Notes

Found 2026-09-19 while verifying whether §6 item 3 of the state-and-context document was still
work. It was not: item 3 asked for `#goal_state` and `#goal_state` shipped the same day the
document was written. The stale comment is what remains of it.

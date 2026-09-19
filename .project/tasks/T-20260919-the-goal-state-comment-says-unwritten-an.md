---
id: T-20260919-the-goal-state-comment-says-unwritten-an
title: The goal.state comment says unwritten and it has been written since 2026-09-14
epic: reporting
tier: T3
paths: tooling/schema.sql, tooling/kit-index.sh
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
| nothing sets it | `kit-plan.sh:45` takes `--goal-state`, validates it at `:80` against `kit_state_written`, writes `#goal_state` at `:532` |
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
- [x] The fifth instance, found by the blind second reader 2026-09-19 and not by me:
      `schema.sql:39` said *"130 task files carry `open` or `done`"* against a tree answering
      **112**, fifteen lines from the comment this task rewrote, in a file this task's own
      `paths:` names. Replaced with the command. The adjacent *"127 commits already carry
      `Task-Status: started|progress|done`"* is deliberately KEPT as a number: it describes
      immutable git history and cannot drift, which is the distinction that separates a figure
      worth writing from one that rots
- [x] The fourth instance of the same defect, folded in on the operator's instruction 2026-09-19:
      `kit-index.sh` carried *"115 of 130 say `open` today"* in the comment above the state
      normalisation, against a tree that answers **97 of 215**. Replaced with the command that
      answers it rather than with a fresher number, following the precedent
      `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` set in its own note: *"The number is
      deliberately not written here -- run it."* A corrected count resets the clock; a command
      cannot go stale

### Evidence, 2026-09-19

The conformance step `a goal's state is text in the plan and survives a replan` was run against
this change and passed -- *"set, preserved across a replan, normalised from a legacy spelling,
refused at both doors"*. A filtered run is not a conformance pass and the suite says so; the full
matrix runs in CI.

`SELECT id,state FROM goal;` returned `default|in-progress` before the edit and after a rebuild
following it.

**The task is T3, not the T2 it was filed as, and the reason is mechanical.** Folding in the
`kit-index.sh` comment brought the change under `tier.rule: tooling/kit-index.sh T3`, so the floor
is T3 whatever the change contains. It contains comments only and `bash -n` parses; the full task
state distribution and the goal row are byte-identical across a rebuild before and after. The
floor is path-based by design and has no notion of change kind, so a comment-only edit to that
file pays a T3 review. That is the rule working as written rather than a misfile, and it is
recorded here so the cost is visible rather than quietly avoided by splitting the commit.

### Review, 2026-09-19 — two blind implementation readers, both REVISE

Run per rung 5 at T3: two readers, neither given sight of the other's findings. Both returned
**REVISE**. Every finding below was re-verified against the tree before being acted on.

| # | severity | finding | disposition |
|---|---|---|---|
| 1 | major | `kit-index.sh` comment hardcoded `.project/tasks`, the literal `kit_tasks_dir` exists to eliminate | fixed — the example now uses `$TASKS_DIR` and names the defect it would have reintroduced |
| 2 | minor | `schema.sql:39` carried a fifth stale count, 130 against 112 | fixed — replaced with the command |
| 3 | minor | this file cited `kit-plan.sh:531`; the `printf` is at `:532` | fixed |
| 4 | minor | the rewrite dropped the concrete "silently 'open' again, no symptom" illustration | restored |
| 5 | nit | *"the same split"* overstated what `kit-status.sh` reports | fixed — it reports the legacy subset |

**The two readers disagreed twice, which is the reason the second one exists.** On finding 1 the
first reader raised the hardcoded path and chose not to file it — *"a worked example in a comment,
not code"* — while the second filed it major, citing the seven-script history in `kit-lib.sh`. The
second is right: a worked example is copied and run. On finding 4 they took opposite views, one
calling the illustration lost, the other holding that nothing of value was deleted; restoring one
sentence satisfies both at no cost.

**What the first reader added that the second did not:** it re-ran the round-trip conformance step
itself rather than trusting the commit, and it re-derived the `97 of 215` figure against the tree
at the commit it was written for. It then observed that HEAD had already drifted to 220 task files
within the same session — so the number in this task file went stale within hours while the
command in `kit-index.sh` did not. That is the clearest possible demonstration of why the fix takes
the shape it does.

**Stated because an unstated gap reads as a pass:** mutation testing generates no mutants against a
comment-only diff, so nothing automated could have caught any of these five. Both readers said so
independently.

## Notes

Found 2026-09-19 while verifying whether §6 item 3 of the state-and-context document was still
work. It was not: item 3 asked for `#goal_state` and `#goal_state` shipped the same day the
document was written. The stale comment is what remains of it.

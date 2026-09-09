<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — milestones as data, and readiness per goal

**Tier:** T2 — it gives an existing table a text source and adds a report. No new vocabulary.
**Status:** design input. Nothing here is implemented and nothing is filed by this document.
**Serves:** `T-20260819-goals-are-the-milestone-mechanism-and-on`, which is filed, unblocked, and
carries a note saying it should wait. §1 argues the condition it was waiting for is now met.

## 0. The question this comes from

The operator, 2026-09-09:

> *"I am unsure about current status of the coding kit … How do you suggest we evaluate current
> status of the coding kit, its to do steps, to completion."*

**The charter already answers the last part, and the answer is that the question has no denominator
as asked.** `docs/CHARTER.md` §1:

> *"Auto-mode is switched on per project, against that project's own roadmap — **and per goal**
> within it, not per repository. **There is no single date on which the kit is ready.**"*

So *"the kit, to completion"* is not a measurable object. **Readiness is a property of a goal**, and
the kit has exactly one goal, called `default`, which has never meant anything. That is why status
reads as a wall rather than a path: the unit the charter defines readiness over does not exist in
the data.

## 1. Why now, when the task itself says wait

`T-20260819`'s own note is a direct objection to building this, and it is quoted rather than
skirted:

> *"Unblocked, but low value until something needs two milestones. The honest sequencing is that
> this waits for a real project with phases — most likely the brownfield trial or a modernization
> subject — rather than being built speculatively against an imagined second goal. Building it now
> would mean inventing the two-goal semantics with no case to check them against."*

**That reasoning holds and is not withdrawn. What changed is the fact it rests on: the case
arrived, and it is this repository.** The kit is now a project whose operator is asking which phase
it is in and what remains — which is the two-goal case, arriving from the direction the note did not
anticipate. The semantics can be checked against a real second goal instead of an imagined one.

This is a change of fact, not a change of opinion, and it belongs on the task rather than only here.

## 2. Measured, 2026-09-09, each command named

| fact | value | command |
|---|---|---|
| rows in `goal` | **1** (`default`, state `open`) | `sqlite3 .project/index.db "SELECT * FROM goal;"` |
| planned tasks in layer 0 | **120** | `SELECT layer, COUNT(*) FROM plan_item GROUP BY layer;` |
| planned tasks in layer 1 | **10** | as above |
| open tasks | 130 | `state NOT IN (completed,cancelled,abandoned)` |
| cluster share of the largest cluster | **85 of 130 (65%)**, cap 60%, packs withheld | `bash tooling/kit-plan.sh` |
| escape rate | `0 / 0 via:kit` in every tier | `bash tooling/kit-status.sh` |

**92% of the backlog is in layer 0.** The plan is not a path; it is a scored flat list, because
almost nothing declares a dependency. Milestones are the other axis that can give it shape, and
they are absent.

**`goal.state` is reserved and unwritten, and the schema says so** (`tooling/schema.sql`):

> *"RESERVED AND CURRENTLY UNWRITTEN. Nothing sets it and nothing reads it, and section 3c's
> `INSERT OR REPLACE` omits it, so every rebuild resets it to 'open' … The condition for using it
> is a TEXT SOURCE first — a header in the plan file, derived like every other column — for the
> reason ADR 0004 records: a table nothing can rebuild from text is the second source of truth this
> design exists to avoid."*

**The condition is named in the schema. This document proposes meeting it, and nothing more
ambitious.**

## 3. The text source

`kit-plan.sh:426-430` already writes a header into the plan file, and the plan file is tracked:

```
#version   1
#goal      default
#created   2026-08-17T02:49:19Z
#tasks_digest  1126301845-9751
```

**One goal per plan file already, keyed by `#goal`.** So the text source for a goal's state is one
more header line in the file that already declares the goal:

```
#state     active
```

- **Derived like every other column**, from text that is committed and diffable — ADR 0004's rule.
- **No new file, no new parser**, and the round-trip conformance step that already selects
  `goal.state` starts asserting something instead of asserting a default.
- **A goal's state is the operator's**, written into the header by hand or by `kit-plan.sh --state`,
  and never inferred from whether its tasks happen to be closed. A goal that is *finished* and a
  goal that is *abandoned with everything closed* are different facts, which is the same argument
  ADR 0008 makes for keeping `cancelled` and `abandoned` apart.

**Deliberately NOT proposed: a goal state vocabulary.** `kit_state_vocab` is for tasks. Whether a
goal needs more than `active`/`reached` is a question for the first project that has two, and
inventing it here is what `T-20260819`'s note warns against. **One value with a text source beats
five values without one.**

## 4. The instrument: readiness per goal

The mechanism above is worth nothing on its own — it is a column with a source. What makes it answer
the operator's question is a report, and the report's rows are **already written**: `CHARTER.md` §5's
six dimensions, which the charter states are *"the ones on which a competitor's advantage is a real
finding"*.

**`kit-status.sh --readiness [--goal ID]`** — one row per dimension, each carrying a value **or the
words `no reading`**, never a blank and never an adjective:

| # | dimension (CHARTER §5) | what a reading is | today |
|---|---|---|---|
| 1 | does the record survive the tool | task files, trailers, `events.ndjson` present and rebuildable | **has a reading** |
| 2 | is cost measured or asserted | spend rows per task; the denominator | **mechanism present, denominator absent** — the charter's own words |
| 3 | is the outcome bounded without the text being fixed | conformance steps passing on the goal's tasks | partial |
| 4 | does reuse cross projects | accelerator references across ≥2 projects | **no reading, and structurally impossible from n=1** |
| 5 | does it stay hidden | interrupts, footprint removability, resident token cost | **no reading** |
| 6 | one mechanism across three starting conditions | entry mode derived on current state | **no reading** |

**The point of the report is the `no reading` cells, not the scores.** CHARTER §5 already says the
kit's value is a delta *"measurable in two places … Neither is measured today."* A report that says
so per goal is the difference between a known gap and an unknown status — and it is exactly the
evidence §1 says the kit's job is to produce, *"cheaply enough that judging stays affordable"*.

**Auto-mode readiness is then a judgement a person makes against that table, per goal.** Not a score,
not a threshold the kit computes for them. §1 is explicit that a person switches it on.

## 5. What this does NOT propose

- **No milestone naming convention.** `T-20260819`'s criteria already require that nothing behaves
  differently because a goal is called `MVP` — the operator's decision of 2026-08-18, that MVP is
  one optional use and not a stage every project passes through.
- **No second source of truth.** The header is text; `goal` stays derived.
- **No automatic goal closure.** §3.
- **No change to `kit_state_vocab`.** Task states are ADR 0010's subject, not this one.
- **No new survey of competing tools.** CHARTER §5 already gives the rule: an advantage on one of
  the six is a finding; an advantage outside them is not automatically a gap, and the charter
  records that this error was made here once and corrected.

## 6. Open, and they are the operator's

1. **What are the kit's own goals?** This document argues the mechanism and deliberately does not
   name them, because a milestone set is a roadmap decision. The obvious first split is *what has
   readings* against *what the charter names as designed-but-not-built*, but that is a suggestion,
   not a proposal.
2. **Does a goal's state need more than one value?** §3 says decide it on the second real case.
3. **Does `--readiness` belong in `kit-status.sh` or its own script?** `kit-status.sh` already
   regenerates a whole file; a per-goal report that a human reads on demand may not want to live
   inside it.

## 7. Acceptance criteria, if this is built

1. A `#state` header in a plan file survives a rebuild — **asserted with a case that fails on the
   pre-change tree**, since today every rebuild resets `goal.state` to `open` and nothing notices.
2. A plan file with **no** `#state` header still indexes, and the goal reads as its default rather
   than as an error — the existing `default.tsv` has none.
3. A second goal is planned, packed and reported **without disturbing the first** — this is
   `T-20260819`'s own first criterion and is not restated as new work.
4. `--readiness` prints every dimension it knows, and prints `no reading` for the ones without one.
   **A dimension that is silently omitted is the failure this report exists to prevent**, so the row
   count is asserted against the dimension list rather than against whatever produced output.
5. The report is per goal, and a goal with no tasks reports `no reading` on every row rather than
   an empty table or a spurious 100%.

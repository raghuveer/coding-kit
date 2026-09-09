<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# ADR 0010: A task reaches `completed` through `validated`, and the rule lives on the transition

- **Date:** 2026-09-09   **Status:** **Proposed — not accepted**   **Supersedes:** —   **Related:** [[0008-the-task-state-vocabulary-and-its-partitions]], [[0009-contribution-is-a-set-assignment-is-a-declaration]]

> **Status is `Proposed` and no other ADR in this repository carries that value.** The seven before
> it are `Accepted` or `REJECTED`. It is used here because acceptance is the operator's and this
> document was written by an agent; recording it as `Accepted` would be the same self-certification
> `.claude/CLAUDE.md` refuses for `Via:` and for `--fixed`.

**Why a new ADR rather than an amendment to 0008.** The house convention is in-place amendment —
ADR 0004 amended itself the same day *"matching the convention ADR 0001 set"*. But both precedents
corrected **the same decision**: 0004 swapped option C for option D on the question it had just
answered. This is a different question. **ADR 0008 decided what states exist and what partitions
they fall in; this decides what must be true before a transition is allowed** — and 0008's own
Fact 3 is that *"a trailer records a transition a commit made, and frontmatter records the state a
task rests in"*, i.e. that these are different objects. Amending 0008 to carry a transition rule
would blur the distinction 0008 drew. ADR 0009 is the precedent that fits: its own number,
`Related:` to 0008, citing 0008's evidence without editing it.

**0007 is deliberately not used.** ADR 0006's rejection banner records that findings against it
*"cite the rejection commit rather than an ADR 0007"*, because the disposition-evidence successor
was never written. Taking that number would claim work that does not exist.

## Context

### What this comes from

The operator's ruling of 2026-09-09, recorded in
`docs/design-input/2026-09-09-design-closure-and-implementation-conformance.md` §1:

> *"A design-stage finding is considered as closed when the design is fixed, in planning stage. The
> implementation of the application is considered as correctly implemented, only when the design is
> implemented contextually."*

Sentence 1 is served by the existing `--fixed` disposition. Sentence 2 has no home: nothing in the
kit can say *the application implements the design*, withhold that claim, or notice its absence.
A design-input revision proposing a separate obligation ledger for it was reviewed by two
`approach-reviewer` runs, blind to each other, and **both returned REJECT**. The operator then
decided: *"use the task record, no second ledger."* This ADR is that decision's mechanism.

### Measured on this repository, 2026-09-09, each command named

Against `.project/index.db` after `bash tooling/kit-index.sh --if-stale`, and by reading
`.project/tasks/*.md` directly.

| fact | value |
|---|---|
| task files | 169 |
| open tasks (`state NOT IN (completed, cancelled, abandoned)`) | 130 |
| open tasks with **no** `## Acceptance criteria` section | **0** |
| open tasks whose criteria have **zero** boxes | **0** |
| open tasks with every box ticked | **1** |
| open tasks partly ticked | 2 |
| open tasks with **no** box ticked | **127** |
| unticked boxes across open tasks | **675** (median 5 per task) |
| open tasks whose criteria name a design document | **1** |
| open tasks by tier | T0 3, T1 22, T2 73, T3 32 |

Two of those decide options below on their own: a rule scoped to tasks naming a design would reach
**one** task, and a rule applied to every open task would block **129 of 130**.

### What already exists, verified rather than assumed

- **The vocabulary has one home.** `tooling/kit-lib.sh:163-186` defines `kit_state_vocab` and its
  three partitions. `tooling/schema.sql:6` says the table is *"DERIVED FROM kit-lib.sh, never
  authored here"*; `kit-index.sh:1187-1190` projects it; `kit-trailers.sh:190`, `kit-task.sh:46`
  and `kit-entry.sh:149` all read it rather than restating it. **Adding a state is one line plus
  its partition memberships.**
- **Checkbox syntax is already parsed and already refused when malformed** — `kit-entry.sh:79`
  refuses a checkbox on a question, `:100` refuses one after the candidate section.
- **`kit-trailers.sh` already validates `Task-Status` against the vocabulary** and runs in CI as
  its own required check.
- **`completed` is terminal and not retracted** (ADR 0008), and **39 tasks are already in it**.
- **The partitions are asserted by `tests/conformance.sh:3013-3090`**, which is NOT derived and
  must move in the same commit.

## Options

### Option A — redefine `completed` to mean validated

Rejected. It retroactively asserts something about the 39 existing `completed` tasks that nobody
checked, and ADR 0008 makes `completed` terminal precisely so history is not rewritten.

### Option B — a new state, rule applied to every open task immediately

Rejected on this repository's own recorded reasoning. `tooling/kit-preflight.sh:78`:

> *"Returning non-zero would make it a gate, and **a gate nobody can ever satisfy is the failure
> the unassessable route was built to remove.**"*

It would block **129 of 130** open tasks behind **675** boxes written when they gated nothing.

### Option C — a new state, rule scoped to tasks whose criteria name a design

Rejected. It reaches **one** task, which is how `blocked`/`unblocked` died — ADR 0008 records them
at zero uses across 130 tasks. It also requires inferring scope from a document's content, and it
pays an author to *not* name a design.

### Option D — a new state, rule scoped by tier (T2/T3)

Rejected. T2+T3 is **105 of 130** — it inherits option B's wall without option B's simplicity.

### Option E — a new state, rule applied prospectively — **chosen**

The state and its entry check ship now and apply to everything. The **transition refusal** applies
only to tasks created after it ships. This is how ADR 0008 handled its own legacy: old spellings
became aliases, **nothing was rewritten**, and 127 files still carry them.

## Decision

**1. An eighth state, `validated`** — the implementation exists and has been checked against the
task's acceptance criteria.

| partition | value | reason |
|---|---|---|
| `is_closed` | 0 | the work is not finished; this is the last state before it is |
| `is_activity` | 1 | its actor is the task's owner, as with `in-progress` and `on-hold` |
| `is_measured` | 1 | work in flight is still work; only `cancelled` is unmeasured |

**Its consumer is named, because ADR 0008 makes that the price of admission.** `planned` survived
review only by naming the next agent as its reader; `blocked` and `unblocked` did not and died at
zero uses. `validated`'s consumer is the transition rule in part 3: it is the only state from which
`completed` may be reached.

**2. The entry check, and it applies universally from day one.**

> **A task may not enter `validated` while any acceptance criterion is unticked.**

It costs nothing today — no task is in `validated` and entering it is voluntary — and it can fail:
`T-20260826-a-verified-claim-about-the-tree-has-no-a` carries six criteria, all unticked, and
would be refused today.

**A task with no criteria, or a criteria section with no boxes, is REFUSED — not passed.** Zero
open tasks are in that shape today, so this guard is for the future rather than the present. It is
stated because *"no unticked criterion"* is satisfied vacuously by having none, which is the
green-but-meaningless check this repository files against itself.

**3. The refusal lives on the transition, not on the state.**

> **`Task-Status: done` is refused when the task's current state is not `validated`.**

Per ADR 0008 Fact 3, states and transitions are different objects. It lands in `kit-trailers.sh` —
the writer, already in CI — rather than in a report nobody runs, which is the third of the four
still-open `--superseded` defects ADR 0006's banner lists (*"the guard lives in the caller rather
than the writer"*), deliberately not repeated.

**4. Prospective, and scope is DECLARED rather than inferred.**

The refusal applies to a task only if the task says it does. `kit-task.sh` writes the marker at
creation; tasks that predate it are unmarked and unaffected.

**Not derived from the task id's date prefix**, though `T-YYYYMMDD-` makes that free. A name is not
a fact about the work, and deriving policy from one is the inference this ADR's own design input
refuses elsewhere. This is ADR 0009's distinction — **assignment is a declaration** — applied to
policy scope.

## Consequences

- **`completed` keeps its meaning** and the 39 tasks already in it are untouched.
- **The 130 open tasks are unaffected by the refusal** and may still be completed as they are today.
  They are affected by the entry check only if someone chooses to move one to `validated`.
- **Two populations exist until the open backlog drains** — marked and unmarked tasks. This is the
  cost of option E and it is real. It is bounded: it shrinks as tasks close and cannot grow, because
  every new task is marked.
- **`tests/conformance.sh:3013-3090` must move in the same commit.** The partitions are asserted
  there and are not derived; adding the state without them is a red suite, which is intended.
- **A checkbox parser is new code in shell** reading a file format — the class this repository has
  filed defects against repeatedly. It is the real work in this ADR, not the vocabulary change.
- **The entry check is a floor, not a proof.** It shows someone answered every criterion; it cannot
  show the answer is right. What *"contextually"* admits as evidence for ticking a design criterion
  is **not decided here** and is the next question, not a detail of this one.
- **`kit-status.sh` gains a `validated` count.** `kit-preflight.sh:112-118`: *"Adding an exclusion
  to the gate without adding the report that exposes it is how a gate quietly stops meaning what
  its reader thinks it means."*

## What this does not cover

- Whether the ruling reopens findings already marked `--superseded` — it would change that verb
  across **32** superseded criticals and belongs in its own document.
- Who may move a task to `validated`. `--fixed` is human-gated by convention; this is the stronger
  claim and the convention may not be enough.
- The evidence standard for ticking a criterion that names a design.

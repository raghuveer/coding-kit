<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — a criterion carries a disposition, not a box

**Tier:** T2 — a report, a text convention, and one validator check. No new task state, no gate.
**Status:** design input. Nothing implemented, nothing filed, no ADR proposed yet.
**Chosen by the operator, 2026-09-09:** *"option F looks as better option."*

> **Written as a design input rather than an ADR on purpose.** Three mechanisms were rejected on
> 2026-09-09 — an obligation ledger, the same ledger revised, and ADR 0010's state gate — by five
> blind approach reviews. In every case the *measurements* survived re-derivation and the
> *mechanism* did not. So this one is reviewed before it is promoted, not after.

## 1. The decision this replaces

ADR 0010 proposed an eighth task state and a transition refusal. **REJECTED**, both reviews, and the
number that killed it was one it never took: **12 of the 39 `completed` tasks — 31% — carry unticked
acceptance criteria and would have been refused.** The assumption underneath, that checkboxes are
maintained, is false on this repository's own history.

The reframing came from the second review and the operator accepted it:

> Is the ruling of 2026-09-09 a claim about **transitions**, or about **evidence attached to a
> completion**? The 31% suggests the latter — the work was done; what was never written is the
> record of *why it counts as done*.

**A gate can only refuse. A disposition records.**

## 2. This is not a new design. It is already happening, twice, in the operator's own hand

Measured across all 169 task files — box glyphs actually in use:

| glyph | count |
|---|---|
| `- [ ]` | 713 |
| `- [x]` | 156 |
| **`- [~]`** | **2** |

Both `[~]` uses were written by the operator, and they are the two values this document proposes:

**`T-20260814-one-entry-mechanism-brownfield-is-the-ge:97`**

> `- [~] Modernization's source→target delta is expressible without a second mechanism.`
> **"DEFERRED by the operator, 2026-08-16, and this task closes without it."** The delta lives in
> the solution overlay … which is unbuilt, so there is nothing to express it against.

**`T-20260815-security-md-claims-allowedtools-enforces:43`**

> `- [~] If a gate is built it can FAIL, and a test proves it …`
> preceded by: *"No gate was built; see the next criterion for why that is a **deliberate choice and
> not a shortfall**."*

**One is a deferral; one is a not-applicable.** The boolean could not carry either, so a third glyph
was invented in prose and a paragraph was written beside it to say what it meant. That is exactly
how the finding vocabulary grew: `--unassessable` and `--superseded` exist *because `--fixed` and
`--open` could not carry "real, but not addressable here"*.

**And note what did not happen: neither criterion blocked its task.** `T-20260814` says *"this task
closes without it"*. The report-don't-refuse posture is already the practice too.

## 3. The proposal

**3.1 — one glyph for "not met and dispositioned", with a required marker naming which.**

```
- [x] met — the criterion is satisfied
- [ ] open — nobody has answered it
- [~] not met, and dispositioned; the marker says which and is REQUIRED
```

Two markers, because they are two different facts about who still owes the work — the same argument
ADR 0008 makes for keeping `cancelled` and `abandoned` apart:

| marker | meaning | required evidence |
|---|---|---|
| `` `deferred: T-…` `` | the work is real and belongs to another task | a task id that resolves |
| `` `n/a: <reason>` `` | nobody owes it; the criterion does not apply | a non-empty reason |

`deferred` names a task for the same reason `--superseded` requires `--by`: *a mark that clears
something without saying what carried it is a clearance, not a record.* `n/a` requires a reason for
the same reason `--unassessable` refuses a blank one.

**One glyph, not two, and the alternative is named rather than hidden.** `[~]` + marker keeps the
two existing uses valid with a marker added, and puts the *fact* in text where a reader sees it
rather than in a glyph they must decode. The alternative — `[~]` for n/a and `[>]` for deferred — is
one character cheaper to parse and needs one of the two existing lines re-glyphed. **Either is
defensible and this document does not pretend otherwise;** the recommendation is the marker, because
this repository has twice chosen a required-evidence field over a terser code.

**3.2 — the posture is REPORT, and there is no gate.**

`kit-status.sh` gains a criteria section: per task, counts of `met` / `n/a` / `deferred` / `open`,
and a list of tasks that are `completed` with `open` criteria remaining.

**Nothing is refused. No new task state. No transition rule.** Everything both reviews killed in ADR
0010 is absent here, and the reason is `kit-preflight.sh:112-118`, which ADR 0010 quoted and did not
apply to itself:

> *"Adding an exclusion to the gate without adding the report that exposes it is how a gate quietly
> stops meaning what its reader thinks it means."*

It surfaces all 12 historical cases on day one with no risk of a stuck task — and there *was* a stuck
task: `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` requires a real unfamiliar repository, so
under ADR 0010 it could never have completed, and its cheapest exit was `cancelled`, which is
`is_measured=0` and removes real work from the escape-rate denominator.

**3.3 — the check that can fail, and it fails on the pre-change tree today.**

A report with no failing check is decoration. Two refusals, in the validator that already reads task
files:

1. **A `[~]` box with no marker is refused.** *Both existing `[~]` lines have no marker*, so this
   check is red on the current tree before anything is written — the `LESSONS.md` §1 obligation, met
   by the population rather than by a contrived fixture.
2. **A `deferred:` naming a task id that does not resolve is refused** — the same class as
   `kit-resolve.sh`'s refusal of an id no finding has.

**A `[~]` with a marker is never refused, whatever the reason says.** Judging the reason is not
mechanisable and pretending otherwise is the green-but-meaningless check this repository keeps
filing against itself.

## 4. What is measured, and the parser question stated rather than buried

ADR 0010 was found to have quoted figures that moved with an unstated parser choice. The rule is
stated here first, and both answers are given.

**Rule: the criteria section runs from `## Acceptance criteria` to the next heading of ANY level.**

| | section ends at any heading | ends at level-1/2 only |
|---|---|---|
| boxes in open tasks | 671 | 686 |
| unticked in open tasks | **664** | **675** |

The looser rule counts a `### Added 2026-08-19` block as still inside the criteria, which it visibly
is. **The stricter rule is chosen anyway**, because a rule that reads sub-sections has to decide
which sub-sections, and this repository has paid for section-scoping ambiguity before —
`kit-entry.sh:83-88` records it: *"two wrong numbers agreeing is the failure mode."* The cost is
named: 15 boxes in two tasks fall outside the section and are invisible to the report until those
tasks are edited.

**The format is more uniform than feared, and that is measured rather than hoped:** across all 871
boxes in all 169 task files, the bullet marker is `-` in **871 of 871** cases and the leading
indentation is **0 in 871 of 871**. There are no nested criteria and no `*` bullets. The parser ADR
0010 called "the real work" is smaller than it claimed.

**The population this describes:** 39 completed tasks carry 185 criteria, **38 still unticked**.

## 5. What this does not do, said plainly

- **It does not enforce the operator's sentence 2.** Nothing refuses a completion. The kit records
  what was claimed about each criterion and who claimed it; a person judges. That is
  `CHARTER.md` §1's own division of labour — *"It is switched on by a person who has judged the
  outcomes appropriate. So the kit's job is to produce **evidence that supports that judgement**"* —
  and it is the answer to the self-certification objection that killed the previous two mechanisms:
  **the disposition lives in a committed file and is reviewable in a diff**, which is the same
  ground on which `--superseded` requires a tree marker rather than trusting the operator's typing.
- **It does not give criteria identity.** Nothing keys a disposition to a criterion — the
  disposition *is* part of the criterion's text. That is deliberate: keying them would walk into the
  claim-identity problem, whose design document was REJECTED on 2026-09-08 with 9 criticals and is
  still unresolved.
- **It does not change any task state, vocabulary, or transition.**
- **It does not read acceptance criteria for adapter-sourced tasks.** `ingest.tasks` may be `none` or
  an executable (`kit-index.sh:311`), in which case there are no task files. Those tasks report
  **`no criteria recorded`** — a third outcome, never a pass and never a failure.

## 6. Open — the operator's

1. **One glyph with a marker, or two glyphs?** §3.1. Recommendation is the marker; both are
   defensible and the existing two lines are affected differently.
2. **Does a `completed` task with `open` criteria get reported forever, or is there a way to say
   "closed anyway, deliberately"?** The 12 historical cases need an answer, and `[~] n/a:` may
   already be it — in which case the report's job is to prompt that edit rather than to persist.
3. **Who writes a disposition?** Same convention as `--fixed`: an agent proposes and stops. Weaker
   consequences here, because nothing is gated.

## 7. Acceptance criteria, if this is built

1. A conformance case that **fails on the pre-change tree**: the two existing `[~]` lines have no
   marker, so the validator is red until they are given one. No fixture is contrived.
2. A case asserting a `deferred:` naming an unresolvable task id is refused.
3. A case asserting a `[~]` **with** a marker is accepted regardless of the reason's content.
4. The report's row count is asserted **against the task count**, so a task the parser fails to read
   appears as `no criteria recorded` rather than vanishing. A report that silently omits a row is
   this document's own fail-open.
5. The 12 completed tasks with open criteria appear in the report on the first run — asserted, not
   assumed.
6. Nothing in `kit_state_vocab`, `kit-trailers.sh` or the task state machine changes; asserted by
   the existing partition steps still passing unmodified.

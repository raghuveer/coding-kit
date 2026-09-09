<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — when a design-stage finding closes, and what the implementation still owes

**Tier:** T3 — it changes what `fixed_at` means and proposes a new surface.
**Status:** design input, **revision 3**. Nothing here is implemented. No finding is marked by this
document.

> **DECIDED BY THE OPERATOR, 2026-09-09 — the fork in revision 2 §9.1 is closed.**
>
> > *"use the task record, no second ledger."*
>
> So there is no obligation table, no `--conformant` verb and no `(design, blob, finding)` key.
> Revision 2's §5.1-§5.3 are **withdrawn**; they are summarised in §5.0 rather than deleted,
> because two reviews were spent on them and the reasons they failed are what shaped this
> revision. §5 is rewritten around the task record.

> **Revision 1 was REJECTED on the day it was written by two `approach-reviewer` runs launched
> concurrently and blind to each other — both REJECT.** Revision 1 promised in §4 that every number
> would name its command, cited ADR 0005 and ADR 0006 as worked examples of a load-bearing claim
> that was confident, checkable and false, and then made four of its own. They are listed here
> rather than edited out of sight, because that is the same standard those two ADRs are held to.
>
> 1. **§8 proposed marking `4d5170af` fixed. It is not in the gate.** It was marked
>    `--superseded --by docs/design-input/2026-08-27-census-store.md` on 2026-09-08T17:09:05Z. The
>    gate moves 12 → **11**, not 12 → 10. Verified: `SELECT COUNT(*) … AND id LIKE '%4d5170af%'`
>    over the gate's own predicate returns **0**.
> 2. **§2 said §F1b records a validator split on both findings.** `grep -c 4d5170af
>    docs/design-input/2026-08-27-census-store.md` returns **0**. F1b names `5c1284da` only;
>    `4d5170af` is anchored in `docs/design-input/2026-09-08-claim-identity.md`, which is REJECTED.
> 3. **§5.1 said blob-SHA pinning was "an option neither ADR considered".** ADR 0006 §A2 considers
>    it by name and calls it *"the strongest alternative"*. It is answered in §5.1 below instead of
>    being claimed as new.
> 4. **§5.1 said the pin "needs no normalisation".** It receives normalisation silently; §5.1.
>
> **One reviewer claim is REFUTED and is not carried into this revision:** reviewer B recorded that
> `5c1284da` and `4d5170af` are *both* in the 12. The query above says otherwise, and reviewer A
> independently said otherwise. The blind pair disagreed and the tree settled it.

**Settles:** the precedent-setting question left open on 2026-09-08, recorded in
`2026-08-27-census-store.md` §F1b as a validator split on `5c1284da`.

## 1. The operator's ruling, 2026-09-09, recorded as his

> "A design-stage finding is considered as closed when the design is fixed, in planning stage.
> The implementation of the application is considered as correctly implemented, only when the
> design is implemented contextually."

Two sentences, two different subjects, and the whole mechanism below follows from keeping them
apart:

| | subject | closes when |
|---|---|---|
| sentence 1 | the **finding** | the design is fixed, at planning stage |
| sentence 2 | the **application** | the fixed design is implemented contextually |

**A finding is not an application.** §F1b's question — *"does a design-stage finding close when the
design is fixed, or only when something enforces it?"* — presented these as one question with two
answers. The ruling says they are two questions with one answer each, and the second question was
never a property of the finding at all.

**What the ruling is, grammatically, and revision 1 got this wrong in §5.3.** It defines a
*predicate* — when the application may be called correctly implemented. It does not impose a
*schedule*. A predicate supports a report that says *"18 designs closed, 0 asserted implemented"*.
Turning it into a repo-wide stop with no scope and no deadline manufactures a failing gate out of
honouring sentence 1, which is the opposite of what sentence 1 does. §5.3 is rewritten accordingly.

## 2. What it settles, and what it does not

**`5c1284da` closes.** It is anchored in a design document, F1b states the refusal rule it asks
for, and under the ruling that is closure. The proposed mark is in §8 — proposed, not run, per
`.claude/CLAUDE.md`.

**`4d5170af` is not reopened by this document.** It was superseded on 2026-09-08 by
`census-store.md`, and its anchor document is REJECTED. Whether a ruling can reopen a finding
already marked `--superseded` is a much larger question — it would change the meaning of that verb
across **32** superseded criticals — and it is not asked here.

**Running the §8 mark requires amending F1b in the same commit.** `census-store.md:397-403` says,
in the tree, today:

> *"States the rule `5c1284da` asks for. **It does not close it, and the difference is the point.**
> The finding remains OPEN in the index as of 2026-09-09, deliberately … A design does not get to
> mark its own findings."*

That paragraph landed at 08:36 today in `f7c06a2`, *"fix: the design claimed a closure the record
never showed"*. The ruling overrides its reasoning — a design still does not get to mark its own
findings, but the operator does. What it does not do on its own is update the file a future reader
opens. Leaving the record saying *closed* and the design saying *deliberately open* is the exact
disagreement `--superseded` requires a tree marker to prevent.

## 3. What the ruling does NOT do, and this is the load-bearing half

It does not say the implementation is correct. It says the opposite: correctness of the
implementation is a **separate assertion**, made later, about a different subject, and it is
unavailable until the design has been implemented contextually.

**Today the kit cannot express that assertion as a disposition, and does not notice its absence
there.** `fixed_at` clears the criticals gate and nothing in the finding record distinguishes a
finding closed by editing a design document from one closed by editing code.

**But the kit is not silent about it**, and revision 1 implied it was. See §5.4: the task record
already carries "the design is fixed and the application owes an implementation of it", and is
carrying it for this very population right now. What §4 measured is narrower than what it claimed.

## 4. Measured on this repository, 2026-09-09, commands named

Against `.project/index.db` rebuilt by `bash tooling/kit-index.sh --if-stale` at `e42067c`. Both
reviewers re-ran every query in this section independently and both reproduced them exactly; the
numbers below are the part of revision 1 that survived.

```sql
-- sqlite3 .project/index.db
SELECT CASE WHEN file_path LIKE 'docs/adr/%' THEN 'docs/adr'
            WHEN file_path LIKE 'docs/design-input/%' THEN 'docs/design-input'
            WHEN file_path LIKE 'docs/%' THEN 'docs/other'
            WHEN file_path IS NULL OR file_path='' THEN '(none)'
            ELSE 'code/other' END AS area, COUNT(*) FROM finding GROUP BY area;
```

| area | findings |
|---|---|
| code/other | 225 |
| docs/design-input | 176 |
| (none) — pre-`summary`, pre-`file_path` era | 114 |
| docs/adr | 56 |
| docs/other | 50 |

**282 of 621 findings are anchored in a document.** Revision 1 bolded this as *"the ruling governs
45% of the finding record"*, and that is not what the query returns — `docs/other` includes
`TRIAL-PROTOCOL.md` and `ENTRY-PROPOSAL.md`, which §6 itself names as not-designs, and §6 forbids
inferring stage from a path at all. **The governed population is unknown, and today it is zero: no
existing mark declares a stage.** 282 is the upper bound on how much of the record the question
could reach, and nothing more.

**The whole current criticals gate is design-anchored.** All **12** actionable criticals
(`bash tooling/kit-preflight.sh --criticals`, exit 1) sit in `docs/design-input/2026-08-27-census-store.md`.

**Closure-by-editing-a-document is already the practice, applied 16 times.**

```sql
SELECT id, file_path, COALESCE(fixed_commit,'(no commit)'), fixed_note
  FROM finding WHERE fixed_at IS NOT NULL AND file_path LIKE 'docs/%';
```

16 rows, whose own `fixed_note`s say an edit to a document closed them — *"Option D added to the
Options section and chosen"*, *"revision 2 F1 defines census_id as…"*. **Four carry no
`fixed_commit`.** Five of the sixteen are in `TRIAL-PROTOCOL.md` and `ENTRY-PROPOSAL.md`, so this
population is *document-anchored*, not *design-stage*: it is what a path rule would catch, which is
why §6 refuses one, and why the migration in §7 cannot be sized from this number alone.

## 5. The mechanism - the task record, and one state

**5.0 - what is withdrawn, and what survived from it**

Revision 2 proposed a separate obligation ledger: a design closure pinned by `git hash-object`, a
`--conformant` discharge, and a `kit-preflight.sh --conformance` report. **Withdrawn by the
operator's decision above.** Three things it taught survive into §5.2, and they are why this
revision does not simply repeat the same shape one layer up:

- **A mark a human types is not a check.** Both reviewers rejected `--conformant` as an unchecked
  assertion whose evidence standard was left undecided. A task *state* set by hand is the same
  thing wearing a different hat, and §5.2 exists so this revision does not reproduce it.
- **A stop nobody can satisfy is the failure to avoid** - `tooling/kit-preflight.sh:78`.
- **The normalisation problem is real** and lands on any content-addressed evidence this design
  might later add. Open critical `38f178a2` is the same hazard, one document over.

**5.1 - the state, and it costs one line**

The operator's question - *"when we can create a task with acceptance criteria, cannot we mark its
status as verifiable & validated implementation?"* - is answered **yes**, and the vocabulary is
already built to take it.

ADR 0008 gave the state vocabulary **one home**: `tooling/kit-lib.sh:163-186`. `schema.sql:6` says
it is *"DERIVED FROM kit-lib.sh, never authored here"*; `kit-index.sh:1187-1190` projects the
partition table from those functions; `kit-trailers.sh:190`, `kit-task.sh:46` and
`kit-entry.sh:149` all read the vocabulary rather than spelling it out. **Adding a state is one
line plus its partition memberships, and every derived surface follows.**

Proposed: **`validated`** - the implementation exists and has been checked against the task's
acceptance criteria.

| partition | value | why |
|---|---|---|
| `is_closed` | **0** | the work is not finished; this is the last state before it is |
| `is_activity` | **1** | its actor is the task's owner, like `in-progress` and `on-hold` |
| `is_measured` | **1** | work in flight is still work; only `cancelled` is unmeasured |

**Its consumer is named, because that is the price of admission.** ADR 0008 records that
`blocked`/`unblocked` died with **zero uses across 130 tasks**, and that `planned` survived review
only by naming the next agent as its consumer. `validated`'s consumer is the **transition rule in
§5.3**: it is the only state from which `completed` may be reached. A state nothing reads would go
the way of `blocked`.

**`completed` is not redefined, and that is deliberate.** ADR 0008 makes `completed` terminal and
not retracted, and **39 tasks are already in it**. Redefining it to mean *validated* would
retroactively assert something about those 39 that nobody checked - the same
back-fill-a-certificate objection §7 raises against the migration. `completed` keeps meaning
*implementation finished*. What changes is how a task is allowed to get there.

**5.2 - what makes the state mean something, and it must be able to fail**

A state a human types is exactly the unchecked assertion both reviewers rejected. The check:

> **A task may not enter `validated` while any acceptance criterion is unticked.**

This is available today and needs no new record. Acceptance criteria are `- [ ]` / `- [x]` markdown
checkboxes under a `## Acceptance criteria` heading - the shape `templates/task.md` ships. **The
kit already parses checkbox syntax and already refuses malformed ones**: `kit-entry.sh:79` refuses
a checkbox on a question, `:100` refuses one after the candidate section. The parsing is precedent,
not new machinery.

It can fail, and on the pre-change tree: `T-20260826-a-verified-claim-about-the-tree-has-no-a`
carries six acceptance criteria, all unticked, and would be refused entry to `validated` today.

**For the design-conformance case specifically** - the half of §1's ruling this document exists for
- the rule is that **the criterion names the design it implements**. The obligation then lives
where the work lives, is reviewable in the same diff, and is discharged by ticking a box that says
what was checked. That is the task record carrying it, which is what the operator decided.

**5.3 - the transition, not the state, is where the rule is enforced**

ADR 0008 Fact 3: *"a trailer records a transition a commit made, and frontmatter records the state
a task rests in."* States and transitions are different objects, so the rule belongs on the
transition:

> **`Task-Status: done` is refused on a task whose current state is not `validated`.**

`kit-trailers.sh` already validates `Task-Status` against `kit_state_vocab` at `:190`, and runs in
CI as its own job - so the refusal lands in the writer rather than in a report nobody runs. That is
the third of the four still-open `--superseded` defects ADR 0006's rejection banner lists
(*"the guard lives in the caller rather than the writer"*), deliberately not repeated here.

**This constrains future transitions only.** Nothing rewrites the 39 existing `completed` tasks and
nothing re-opens them.

**5.4 - the one thing that is not free**

`validated` is a new value in a vocabulary whose partitions are asserted by
`tests/conformance.sh:3013-3090`, which checks that every getter is non-empty and that every state
appears in the projection. It has to be added to the conformance expectations in the same commit or
the suite goes red - which is the behaviour ADR 0008 wanted, and is why the vocabulary was given one
home in the first place.

## 6. Two things deliberately refused

**Not a fifth disposition verb on the finding.** Under the ruling there is no fifth answer to *"was
this finding addressed"* — it was addressed. The new fact is about the application, so it does not
become a column on `finding`.

**The stage is never inferred from the path.** `docs/TRIAL-PROTOCOL.md` and `docs/ENTRY-PROPOSAL.md`
are documents and not designs — 5 of §4's 16 are exactly those — and an adopting repository may put
designs anywhere. A `docs/%` rule would be right here and silently wrong in the first adopting repo.
Both reviewers tested this refusal and neither broke it; it is the one part of revision 1 that
survives unchanged.

## 7. What it costs, and what is not costed

The ledger's costs went with the ledger. What is left is smaller, and one item is larger than it
looks.

- **The vocabulary change is one line** in `tooling/kit-lib.sh` plus two partition memberships, and
  the schema, the projection, the trailer validator, the task writer and the entry linter all
  derive from it. This is ADR 0008's one-home decision paying for itself.
- **The conformance expectations are NOT derived** and must move in the same commit
  (`tests/conformance.sh:3013-3090`). Adding the state without them is a red suite, which is the
  intended behaviour.
- **The checkbox parser is the real work.** It must read a `## Acceptance criteria` section out of
  a task file and decide ticked from unticked. `kit-entry.sh:79` and `:100` are precedent for the
  syntax but not a parser for this shape, and this is a file-format read in shell - the class of
  code this repository has filed defects against repeatedly.
- **Refusing an empty criteria list is not an edge case.** A task with no `## Acceptance criteria`
  section, or a section with no boxes, would otherwise satisfy *"no unticked criterion"* vacuously
  and pass. That is the green-but-meaningless shape, and §10.3 makes it a case.
- **No process spawns are added.** The check reads files the indexer already reads. This is the one
  place revision 2's cost analysis is simply obsolete rather than corrected - and worth noting that
  it turned on two figures this repository states as fact and that disagree by 5x:
  `docs/TRIAL-PROTOCOL.md:255` measures **1,015 ms per process creation** with its benchmark
  printed beside it, while `docs/ADAPTERS.md:75` states **~0.2s on Windows**. Nothing reconciles
  them. **That disagreement is worth filing on its own** and is not resolved here.
- **Not costed: the 130 open task files.** (169 exist; 39 are already `completed` and untouched.) Every one carries acceptance criteria written before any
  of them gated anything - many are prose, aspirational, or already satisfied without being ticked.
  Under §5.3 none of those tasks can reach `completed` until someone reads and ticks them. Whether
  that is the point or an unacceptable stop is **§9.1**, and it is the largest uncosted item in
  this document.

## 8. The proposed mark — for the operator, not to be run by an agent

One mark, not two. It takes the criticals gate **12 → 11** (verified by running the gate's own
predicate with this id excluded). Per §2 it should land in the same commit as the F1b amendment.

```sh
bash tooling/kit-resolve.sh --finding '2026-08-28T02:07:03Z:5c1284da' --fixed \
  --note 'F1b states the refusal rule. Closed at design stage per the 2026-09-09 ruling; implementation conformance is a separate assertion about the application.'
```

It carries no design pin: under the operator's decision there is no pin, and the design a
closure refers to belongs in the task's acceptance criterion instead (§5.2).

## 9. Open - the operator's, and ordered

**Answered 2026-09-09:** *second ledger or task record* - **the task record**. See §5.

1. **Does `completed` require `validated` for every task, or only for tasks that name a design?**
   A one-line change either way, and it is the difference between a rule and a special case. §5.3
   as written is universal; a narrower version needs a way to tell which tasks are in scope, and
   §6's refusal to infer stage from a path applies there too.
2. **Does the ruling reopen findings already marked `--superseded`?** §2. It would change that
   verb's meaning across **32** superseded criticals and belongs in its own document.
3. **What does "contextually" admit as evidence for ticking a design criterion?** The ruling's
   word. An agent reading design against diff is judgement; the verify-ladder is deterministic and
   covers less. §5.2's checkbox rule is a floor - it proves someone answered, not that the answer
   is right - and this document says so rather than claiming otherwise.
4. **Who may move a task to `validated`?** `--fixed` is human-gated by convention. This is the
   stronger claim and the convention may not be enough.
5. **Does this need its own ADR, or an amendment to ADR 0008?** It changes that ADR's decision
   table. The repository has no ADR 0007 - the slot was left for the disposition-evidence successor
   that was never written - so the number is not free by default.

## 10. Acceptance criteria, if this is built

Written here because revision 1 offered one criterion and it was a cost measurement, against
`docs/adr/0008-...md:287`'s rule - *"a conformance case that fails on the pre-change tree"*.

1. A conformance case that **fails on the pre-change tree**: a task with an unticked acceptance
   criterion is refused entry to `validated`.
2. A case asserting `Task-Status: done` is refused on a task that is not `validated`.
3. A case asserting a task with **no** `## Acceptance criteria` section is refused rather than
   passing vacuously - an empty criteria list must not be a green check.
4. The partition projection at `kit-index.sh:1187-1190` yields the new state with all three
   booleans, and `tests/conformance.sh:3013-3090` still passes.
5. The 39 existing `completed` tasks are untouched - asserted, not assumed.

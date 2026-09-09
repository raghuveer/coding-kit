<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — when a design-stage finding closes, and what the implementation still owes

**Tier:** T3 — it changes what `fixed_at` means and proposes a new surface.
**Status:** design input, **revision 2**. Nothing here is implemented. No finding is marked by this
document.

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

## 5. The mechanism

**5.1 — closure records its stage, and the stage is declared, not sniffed.**

```
kit-resolve.sh --finding ID --fixed --design <path> [--commit SHA] [--note TEXT]
```

Writes the existing `finding-fixed` event with `stage:"design"` and `design_blob`
(`git hash-object <path>` at mark time). The finding closes exactly as today; sentence 1 is
honoured without delay.

**ADR 0006 §A2 already considered this and rejected it. Quoted, and answered:**

> *"**A2 — pin evidence by git blob or tree SHA.** Not rejected on merit and worth naming
> precisely, because it is the strongest alternative. Content-addressed, rename-immune, one batched
> spawn to verify. It loses to the chosen option on one point only: a blob SHA pins the *bytes*, so
> any edit to the subject — a typo fix, a reflow — invalidates the evidence and lapses the
> exclusion."*

Revision 1 took that sentence, unquoted, and sold it as the feature that makes the mechanism a
control. **A2's objection stands and is not answered by relabelling it.** A file-level pin on a
document that took 10 commits in 12 days is stale as a steady state, and "stale" would then mean
"someone reflowed a paragraph". Two ways out, and this document does not choose between them:

- **pin a section** — a heading anchor plus the blob of that section's bytes, so staleness means
  *the part I certified against changed*; or
- **accept the false-positive rate** and state it as a cost, on A2's own terms.

**"Needs no normalisation" was false.** `git hash-object <path>` applies the attributes-driven
clean filter. Demonstrated on this tree: `.gitattributes` hashes `ff32dea1…` with filters and
`d9df030d…` with `--no-filters`. It is stable here only because `.gitattributes:15` pins
`*.md text eol=lf` and `core.autocrlf=true`. §6 then widens the path space to *"anywhere"*, which is
exactly where neither guarantee holds. **This is open critical `38f178a2` on the census store,
one document over** — *"`core.autocrlf=true` with no `.gitattributes` rule for `.json` makes an
on-disk hash platform-dependent"*. Any pin proposed here inherits it: the design glob needs a
`text eol=lf` rule, or the mechanism is platform-dependent by construction.

**5.2 — a design closure mints an obligation, and the discharge carries its own pin.**

```
kit-resolve.sh --finding ID --conformant --design <path> --commit SHA --note TEXT
```

Revision 1 gave the discharge no blob, and §5.3 then read *"the `design_blob` the discharge was
made against"* — a value nothing wrote. **Both reviewers found this independently**, and it is the
defect that would have made the mechanism fire on correct work: the normal sequence is close at
design stage → revise the design → implement the revision → certify, which §4's own history shows
this repository doing, and against a closure-time pin every such certificate is stale at birth. The
discharge re-pins. What re-opens an obligation is then a real question and is answered in §5.3.

**5.3 — a REPORT, not a stop.**

`kit-preflight.sh --conformance` — **exit 0 either way**, printing the count and the rows. Revision
1 chose exit 1 and that contradicts this repository's own recorded rule, at
`tooling/kit-preflight.sh:78`:

> *"Exit 0 either way, deliberately: a standing blind spot is not a stop, it is something the report
> must carry. Returning non-zero would make it a gate, and **a gate nobody can ever satisfy is the
> failure the unassessable route was built to remove.**"*

With 16 existing closures carrying no pin and four carrying no commit, an exit-1 gate is red on the
day it ships for a reason nobody has decided. It reports two conditions:

1. **Undischarged** — a design closure with no `--conformant` mark. **This is bookkeeping and the
   document says so**: `--conformant` is a human assertion, §9.3 leaves its evidence standard
   undecided, and until that is decided the condition detects that nobody typed a sentence, not
   that an implementation diverges. Revision 1's §5 promised "a part that cannot fail is not
   proposed" and then proposed this; it is kept only because a count of unasserted designs is worth
   printing, and it is labelled for what it is.
2. **Stale** — `git hash-object <path>` today differs from the discharge's pin.

**An unhashable design denies.** A missing or unreadable path is reported as *undischarged*, never
skipped — the `--superseded` precedent, where absence is refused outright *because deleting the
evidence must not be the cheapest way out of the gate*.

**5.4 — the alternative that already ships, and the fork it forces**

Reviewer B named it and it is the strongest objection in either review: **"the design is fixed and
the application owes an implementation of it" is what an open task with acceptance criteria already
is.** Verified — `T-20260826-a-verified-claim-about-the-tree-has-no-a` is `state: created` with an
`## Acceptance criteria` section, and it is the task all 12 open criticals are anchored on.
`6aafecf` (*"tasks: split the census store into three after a second review returned REVISE"*) is
this operator recording exactly that fact in exactly that mechanism.

So §4's *"the conformance half was never recorded once"* is too strong. What is true is narrower:
**it was never recorded as a finding disposition.** A second ledger keyed on
`(design, blob, finding)`, with nothing reconciling it against the task that carries the same
obligation, is two records of one fact that can disagree — which is a shape this repository files
against itself elsewhere.

**This is a fork the operator has to settle, and everything downstream depends on it — see §9.1.**

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

- **Hashing.** One `git hash-object` per mark, and one per obligation at report time.
  `git hash-object` accepts multiple paths in one invocation, so the report is **one batched
  spawn**, which is also what ADR 0006 §A2 says. Revision 1 costed 16 sequential spawns and got the
  spawn figure from nowhere.
- **The spawn figure, and a disagreement inside this repository.** `docs/TRIAL-PROTOCOL.md:255`
  measures **1,015 ms per process creation on this machine**, with the PowerShell benchmark printed
  beside it and Defender ruled out at 1,016 ms vs 1,015 ms. `docs/ADAPTERS.md:75` states **~0.2s on
  Windows**. Both are stated as fact, they differ 5×, and nothing reconciles them. Reviewer B read
  the second and called the first unsourced; the first names its command. **The disagreement is
  itself worth filing** and is not resolved here. Batched, the report is one spawn either way, so
  the choice does not change this design.
- **The indexer shape, which revision 1 got wrong in kind.** *"A fifth follows the same shape at
  `kit-index.sh:947-970`"* is false: those four are deferred **UPDATE**s on `finding`, keyed by
  finding id, released at `END` behind an orphan check (`:992`) and a collision check (`:990`). An
  obligation is an **INSERT** into a new table with a composite key, and inherits neither guard. An
  orphan or id-ambiguous design closure would mint an obligation naming a finding that does not
  exist. **The guards have to be written, not inherited.**
- **`kit-event.sh:25-41` reserves acted-on kinds** so the generic recorder cannot mint them, and
  `tests/conformance.sh:1090` derives that list from the indexer. A new acted-on kind that is not
  reserved ships a writable discharge and a red suite.
- **Retraction is unspecified and must not be.** `kit-index.sh:946-949` already accepts `"fixed":0` to
  reopen a finding; nothing retires the obligation its earlier closure minted, leaving a
  permanently undischargeable row. Re-marking with a different `--design` mints a second obligation
  without retiring the first.
- **Observability.** An obligation count needs a `kit-status.sh` line. `kit-preflight.sh:112-118`:
  *"Adding an exclusion to the gate without adding the report that exposes it is how a gate quietly
  stops meaning what its reader thinks it means."*
- **Not costed: the migration** of the existing document-anchored closures. §4 shows the population
  is uneven and not all of it is design-stage. Back-filling a pin from today's tree would certify a
  revision nobody reviewed.

## 8. The proposed mark — for the operator, not to be run by an agent

One mark, not two. It takes the criticals gate **12 → 11** (verified by running the gate's own
predicate with this id excluded). Per §2 it should land in the same commit as the F1b amendment.

```sh
bash tooling/kit-resolve.sh --finding '2026-08-28T02:07:03Z:5c1284da' --fixed \
  --note 'F1b states the refusal rule. Closed at design stage per the 2026-09-09 ruling; implementation conformance is a separate assertion about the application.'
```

It carries no `--design` pin, because the flag does not exist and §9 has not been settled.

## 9. Open — the operator's, and ordered

1. **Second ledger, or the task record?** §5.4. If the task record carries the obligation, most of
   §5 dissolves and what remains is a report over task state. If a ledger is wanted, it needs a
   reconciliation rule against the task. **Nothing else should be built until this is answered.**
2. **Does the ruling reopen findings already marked `--superseded`?** §2. It would change that
   verb's meaning across 32 superseded criticals and belongs in its own document.
3. **File-level pin or section-level?** §5.1, on ADR 0006 §A2's terms.
4. **What does "contextually" admit as evidence?** The ruling's word. An agent reading design
   against diff is judgement; the verify-ladder is deterministic and covers less. Until this is
   answered, condition 1 of the report is bookkeeping — which the document now says out loud rather
   than claiming otherwise.
5. **Who may discharge?** `--fixed` is human-gated by convention; `--conformant` is the stronger
   claim and the convention may not be enough.

## 10. Acceptance criteria, if this is built

Written here because revision 1 offered one criterion and it was a cost measurement, against
`docs/adr/0008-…md:287`'s rule — *"a conformance case that fails on the pre-change tree"*.

1. A conformance case that **fails on the pre-change tree**: seed a design closure, discharge it,
   edit the design, and assert the report says *stale* rather than *clear*.
2. A case asserting a missing design path reports **undischarged**, not skipped.
3. A case asserting a `"fixed":0` reopen retires the obligation.
4. A case asserting an orphan or id-ambiguous finding id mints **no** obligation.
5. The report's spawn count is measured, not estimated, and recorded beside
   `TRIAL-PROTOCOL.md:255`.

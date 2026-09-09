<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — when a design-stage finding closes, and what the implementation still owes

**Tier:** T3 — it changes what `fixed_at` means for 282 of 621 findings and adds a gate.
**Status:** design input. Nothing here is implemented. No finding is marked by this document.
**Settles:** the precedent-setting question left open on 2026-09-08 by two validators splitting
PARTLY/ADDRESSED on `5c1284da` and `4d5170af`, recorded in `2026-08-27-census-store.md` §F1b.

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

## 2. What it settles

`5c1284da` (census_id/unit refusal rule) and `4d5170af` (`unit` defined nowhere) are both anchored
in a design document, and both had their design fixed — F1b states the refusal rule, F1c defines
`unit` as a manifest-declared slug. **Under the ruling they close.** The proposed marks are in §8;
they are not run here, per `.claude/CLAUDE.md` — an agent proposes a mark and stops.

The unanimity rule that left them unmarked did its job: it did not guess, and the guess would have
been right for the wrong reason. What closed them is a ruling about vocabulary, not a second
reading of the evidence.

## 3. What the ruling does NOT do, and this is the load-bearing half

It does not say the implementation is correct. It says the opposite: correctness of the
implementation is a **separate assertion**, made later, about a different subject, and it is
unavailable until the design has been implemented contextually.

**Today the kit cannot express that assertion, cannot withhold it, and does not notice its
absence.** `fixed_at` clears the criticals gate and nothing downstream distinguishes a finding
closed by editing a design document from one closed by editing code. So the moment sentence 1 is
honoured, sentence 2 becomes silently unenforceable — the record shows a closed finding and says
nothing about an application that may implement none of it.

## 4. Measured on this repository, 2026-09-09, commands named

Both ADR 0005 and ADR 0006 were rejected on load-bearing claims that were confident, checkable and
false. Every number here names the command that produced it, against `.project/index.db` rebuilt by
`bash tooling/kit-index.sh --if-stale` at `e42067c`.

**The ruling governs 45% of the finding record.**

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

282 of 621 are anchored in a document. Not all of those are design-stage — `docs/other` includes
`TRIAL-PROTOCOL.md` and `ENTRY-PROPOSAL.md` — which is exactly why §6 refuses to infer the stage
from the path.

**The whole current criticals gate is design-stage.** All **12** actionable criticals
(`bash tooling/kit-preflight.sh --criticals`, exit 1) are anchored in one file,
`docs/design-input/2026-08-27-census-store.md`. So this ruling is not a future-facing nicety: it
governs every open critical in the repository today.

**The ruling is already the de facto practice, applied 16 times, and the conformance half was never
recorded once.**

```sql
SELECT id, file_path, COALESCE(fixed_commit,'(no commit)'), fixed_note
  FROM finding WHERE fixed_at IS NOT NULL AND file_path LIKE 'docs/%';
```

16 rows. Their own `fixed_note`s say what closed them, and in every case it is an edit to a
document: *"Option D added to the Options section and chosen"*, *"revision 2 F1 defines census_id as
the operator-allocated..."*, *"design 2 line 100 now reads 'no ranking, no cap...'"*. **Four of the
sixteen carry no `fixed_commit` at all** — the ADR 0004 group. So the migration population is not
hypothetical and its evidence is uneven; §7 costs it.

## 5. The mechanism

Three parts. Each is stated so it can fail; a part that cannot fail is not proposed.

**5.1 — closure records its stage, and the stage is declared, not sniffed.**

`kit-resolve.sh --finding ID --fixed` gains a qualifier for a closure that is a design fix:

```
kit-resolve.sh --finding ID --fixed --design <path> [--commit SHA] [--note TEXT]
```

It writes the existing `finding-fixed` event with two added fields, `stage:"design"` and
`design_blob`, where `design_blob` is `git hash-object <path>` **at the time of the mark**. The
finding closes exactly as today — `fixed_at` is set, the criticals gate clears. Sentence 1 is
honoured without exception or delay.

Blob SHA rather than a commit or a line range, for the reason ADR 0005's rejection banner named as
an option neither ADR considered: it is **content-addressed, rename-immune, and needs no
normalisation**. `kit-accel.sh:186` is the kit's existing precedent for `git hash-object` (there `--stdin`,
over a salted origin URL).

**5.2 — a design closure mints an obligation.**

The obligation is `(design path, design_blob, finding id)`. It is **not** a fifth disposition on the
finding; the finding is closed. It is a row about the *application*, which is what sentence 2 is
about. It is discharged by:

```
kit-resolve.sh --finding ID --conformant --commit SHA --note TEXT
```

asserting that the commit implements that design, contextually. Same rule as every other mark: **an
agent proposes it and stops.**

**5.3 — the gate, and the two ways it fails.**

`kit-preflight.sh --conformance` — exit 0 when every design closure has a live discharge; exit 1
otherwise, naming them. It fails on two distinct conditions, and the second is the one that makes
this a control rather than a checkbox:

1. **Undischarged** — a design closure with no `--conformant` mark. The implementation has not been
   asserted to match, so it is not correct. This is sentence 2 stated as a command.
2. **Stale** — `git hash-object <path>` today differs from the `design_blob` the discharge was made
   against. **The design moved after the implementation was certified against it**, so the
   certificate is about a document that no longer exists and the obligation re-opens.

Condition 2 is checkable, cheap, and would fire on real history:
**10 commits** have touched `docs/design-input/2026-08-27-census-store.md` since its first fix mark
(`63ae8668`, 2026-08-27) — `git log --oneline --since=2026-08-27 -- <path> | wc -l`. Every certificate
made against an earlier revision of it would be stale today.

## 6. Two things deliberately refused

**Not a fifth disposition verb.** `fixed_at`, `unassessable_at`, `superseded_at` and `vindicated`
each exist because no neighbour could carry the fact — the schema comments argue each case. A
`design_closed_at` column would be a *fifth* answer to *"was this finding addressed"*, and under the
ruling there is no fifth answer: it was addressed. The new fact is about the application, and the
application is a different subject, so it gets its own table rather than a column on `finding`.

**The stage is never inferred from the path.** `docs/TRIAL-PROTOCOL.md` and `docs/ENTRY-PROPOSAL.md`
are documents and not designs; a repository adopting this kit may put its designs anywhere. A rule
that reads `docs/%` would be right here and wrong in the first adopting repo, and wrong silently.
The marker declares the stage; the blob pin is what makes the declaration checkable afterwards.

## 7. What it costs, and what is not yet costed

- **One `git hash-object` per mark** at mark time, and one per design closure at gate time. On this
  machine's ~1000ms process spawns, a gate over the 16 existing design closures is ~16s — the same
  order as `kit-preflight.sh --isolated`, and run on demand rather than on every index rebuild.
  This is an estimate from the recorded spawn cost, **not a measurement**; measuring it is an
  acceptance criterion, not a claim made here.
- **A new table and a new event kind** — the indexer already ingests four disposition kinds; a
  fifth follows the same shape at `tooling/kit-index.sh:947-970`.
- **Not costed: the migration.** The 16 existing design closures predate the `--design` flag and
  have no blob pin; four have no commit either. Whether they are back-filled, grandfathered, or
  left to fail the gate loudly is an open question, not a detail — §4's evidence is uneven, and
  back-filling a pin from today's tree would certify a design revision nobody reviewed.

## 8. Proposed marks — for the operator, not to be run by an agent

Under §2, and only if the ruling is accepted as written:

```sh
bash tooling/kit-resolve.sh --finding '2026-08-28T02:07:03Z:5c1284da' --fixed \
  --note 'F1b states the refusal rule: census_id and unit match the allowed charset, and . and .. are refused outright. Closed at design stage per the 2026-09-09 ruling; implementation conformance is a separate assertion.'

bash tooling/kit-resolve.sh --finding '2026-09-08T03:46:46Z:4d5170af' --fixed \
  --note 'F1c defines unit as a manifest-declared slug. Closed at design stage per the 2026-09-09 ruling; implementation conformance is a separate assertion.'
```

Both would take the criticals gate from 12 to 10. **Neither carries a `--design` pin, because the
flag does not exist yet** — which is the first thing the migration question in §7 has to answer, and
the reason these two are proposed rather than run.

## 9. Open, and not folded in silently

1. **Migration of the 16.** §7. Needs the operator, because grandfathering is a decision about the
   honesty of the record rather than a technical choice.
2. **Who may discharge an obligation.** `--fixed` is human-gated by convention. `--conformant` is a
   stronger claim — that an application implements a design — and the convention may not be enough.
3. **What "contextually" admits as evidence.** The ruling's word. A conformance check that reads the
   design and the diff is an agent judgement; a check that runs the verify-ladder is deterministic
   and covers less. This document does not decide it, and ADR 0005 and 0006 are both worked examples
   of what deciding it too fast costs.

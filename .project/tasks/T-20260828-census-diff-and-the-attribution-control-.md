---
id: T-20260828-census-diff-and-the-attribution-control-
title: Census diff and the attribution control that refuses an unattributable comparison
epic: reporting
tier: T3
paths: tooling/kit-claim.sh, tooling/kit-status.sh, tooling/kit_claims.py, tests/conformance.sh
blocked_by: T-20260826-a-verified-claim-about-the-tree-has-no-a
state: created
---

## Intent

**Task C of a three-way split.** A: the store
(`T-20260826-a-verified-claim-about-the-tree-has-no-a`). B: dispositions
(`T-20260828-claim-dispositions-so-feedback-on-a-cens`). **C: this.**

This carries **AC6 of the parent task** — *"re-running a census on a later commit produces a
comparable result: which verdicts changed, which claims are new, which disappeared"* — which that
task's own text calls **the whole point**. It is split out precisely so it is not the part that
gets cut: the second review observed that it had no test plan at all while the rest of the design
grew, and that it **cannot be proved until a second census exists**.

## The operator's requirement this serves

> Findings recorded so we can use that for audit and to share feedback, that can be used for
> improving coding kit and **to later validate coding kit recursively, against same reference**.

That is a stronger requirement than diffing two documents. It makes a census a **benchmark**: run
it, improve the kit, re-run it, and attribute the difference to the improvement.

## Why attribution is the hard half, not the diff

Three variables move between two censuses, and **a diff in which more than one moved is
uninterpretable**:

| variable | recorded as | risk if unpinned |
|---|---|---|
| the subject tree | `subject_sha`, `subject_dirty` | code changed under the audit |
| the auditor | `auditor_model` | model nondeterminism, tier change |
| **the kit** | `kit_sha`, `kit_version` | **the thing being validated recursively** |

The parent design originally recorded only the first two, which would have made recursive
validation impossible — a changed verdict could not be attributed to the kit improvement it was
meant to measure.

**Two further variables the review found unpinned and this task must handle:**

- **Unit decomposition is unrecorded and moves the claim set most.** How a document was split
  across ~18 auditor invocations is not captured anywhere, and it changes what claims exist at all.
- **`subject_dirty = 1` makes `subject_sha` non-identifying by construction.** A dirty baseline is
  unattributable, and the three-variable rule says nothing about it. Decide whether a dirty census
  may serve as a diff baseline at all.

## The control, which must be a control

The parent design said the diff would *"refuse to be read as a kit result when more than one
variable moved"* and then described it as **reporting** which variables differ. **Reporting is not
refusing.** It had no named home and no test.

- [ ] The refusal is implemented, has a named home, and is on the test list.
- [ ] It **fails** when two or more pinned variables differ, rather than annotating the output.
- [ ] Mutation proof: a diff across two censuses differing in both `kit_sha` and `subject_sha` is
      refused; changing only `kit_sha` is permitted.

## Acceptance criteria

- [ ] Two censuses of the same subject diff to: verdicts changed, claims new, claims gone.
- [ ] **Per-subject verdict counts are the headline**, because they survive rewording; claim-level
      matching is best-effort and **the diff reports its own match rate** rather than presenting
      unmatched claims as confident changes.
- [ ] The attribution control above, as a control that can fail.
- [ ] The claim-identity question is settled **by A** before this starts. If the within-unit
      ordinal is in `claim_key`, inserting one claim into a re-audited unit shifts every later
      ordinal and this diff reports every downstream claim as simultaneously new and disappeared —
      the exact defect `kit-index.sh:865-870` records. **A must state the key in one sentence and
      say whether the ordinal is in it.**
- [ ] Extraction variance is measured before the diff's presentation is fixed: Jaccard over
      normalised claim text within a unit, plus verdict agreement on the intersection; **n = 3
      units × 2 runs**, not 1 × 2, so spread is visible; below 0.8 mean similarity, claim-level
      diffing is reported as best-effort only. Stated honestly as a **same-document noise floor**,
      not this task's operating condition.
- [ ] **A real second census is the fixture.** No synthetic diff proof is accepted as satisfying
      this task, because the parent's own CORRECTION section records that no fixture exists and
      that the next census must be one.

## Findings inherited from the parent

| id | severity | what |
|---|---|---|
| `…:e35` | major | AC6 gets no proof; no second census exists to be a fixture |
| `…:da4` | major | the refuse-control is only reporting, unhomed, untested |
| `…:523` | major | D3 under-pins: unit decomposition unrecorded, `subject_dirty` non-identifying |
| `…:e13` | major | the variance measurement has no metric, threshold or decision rule |

## Notes

**This task is the reason to run a census on Medha rather than a third narrative.** It cannot be
completed without two real censuses of one subject, and the first of those is what makes A's
schema real rather than synthetic. Sequencing follows from that, not from preference.

**Do not start this before A settles `claim_key`.** Every acceptance criterion here is downstream
of an identity decision that is currently undefined across three competing proposals.

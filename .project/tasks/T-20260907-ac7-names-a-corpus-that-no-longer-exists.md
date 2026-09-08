---
id: T-20260907-ac7-names-a-corpus-that-no-longer-exists
title: AC7 names a corpus that no longer exists so the criterion cannot be met
epic: agent-contracts
tier: T2
lang: bash
paths: .project/tasks/T-20260826-no-agent-owns-verifying-documented-claim.md, docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md, docs/MODELS.md
state: created
---

## Intent

`T-20260826-no-agent-owns-verifying-documented-claim` carries seven acceptance criteria. Five were
met by PR #27. AC7 reads:

> It is demonstrated on the 2026-08-26 corpus and its verdicts compared against that run.
> Divergence is a finding about one of the two, not automatically a regression.

**The corpus it names is gone.** The criterion cannot be met as written, by anyone, at any cost.

## Reproduced 2026-09-07, before proposing anything

The trial document says where the output went, at
`docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md:240`:

> Delivered as `docs/RECONCILIATION-2026-08-26.md` **in the copy**, never applied, copy has no
> remote.

Checked, in this order:

| where | result |
|---|---|
| `find /d/personal-github -maxdepth 4 -iname 'RECONCILIATION*'` | no match |
| `find /d/personal-github/highper-gateway -iname 'RECONCILIATION*'` | no match; the file was never applied to the real repo |
| `%TEMP%`, depth 4, for `RECONCILIATION*` / `*highper*` / `*aeon*` | no match |
| aeon's copy | `2026-08-27-aeon-reconciliation.md:22` — *"an isolated copy under the job tmp directory; no remote"*; aeon is not on disk at all |

**What survives of 792 claims is aggregate statistics and roughly ten narrated exemplars.** For
highper-gateway: 303 claims, 142 confirmed (47%), 129 do not hold — 48 stale-citation, 50
overstated, 31 understated. Per-claim verdicts, evidence and locations are not recoverable.

## The second reason, independent of the first

Even had the file survived, the comparison AC7 asks for is one D3 forbids. The 2026-08-26 run used
a **hand-written prompt**; any run today uses the shipped `claim-auditor` contract, which did not
exist until PR #27 the following day. So a comparison moves **two** variables — the auditor model
and the auditor instrument — and D3's attribution rule says a diff in which more than one moved is
uninterpretable.

AC7 is therefore unmeetable twice over, and fixing the data loss would not rescue it.

## What is NOT broken, and is worth recording before it is assumed

The subject is pinned for free, which is the variable usually hardest to control:

```
highper-gateway   HEAD 05c56eb206142e5e5920b9430f3e83d1dc8881ad   (2026-05-16)
commits since 2026-08-26: 0
working tree: clean  ->  subject_dirty = 0
```

The tree audited on 2026-08-26 is byte-identical to the tree on disk today. Any re-run is against
the same subject without pinning effort.

## Proposed amendment, for the operator to accept or replace

Split AC7's intent into the part that is measurable and the part that is not:

- [ ] **Replace AC7's per-claim comparison** with a two-arm run: the same unit, the same
      `claim-auditor` contract, the same `subject_sha`, audited at two model tiers, compared claim
      by claim **against each other**. One variable moves. This also satisfies AC6, which
      `docs/MODELS.md` already specifies in exactly these terms — the two criteria collapse into
      one experiment.
- [ ] **Keep the historical figures as a sanity check, explicitly not as proof.** If the opus arm
      lands near 47% confirmed with a comparable stale/overstated/understated split, that is
      evidence the shipped contract reproduces the hand-written prompt's behaviour. A large
      divergence is a finding about the contract and is worth more than the comparison AC7 wanted.
- [ ] **Record why the original criterion was withdrawn**, in the parent task, rather than editing
      it out. The reason — an audit output delivered into an isolated copy with no remote — is the
      same defect the census store exists to prevent, and it should be legible where the store's
      motivation is read.

## Acceptance criteria

- [ ] AC7 of the parent task is amended or withdrawn, with the reason recorded rather than the text
      silently replaced.
- [ ] The parent task states which surviving artefact any comparison may use, and that per-claim
      verdicts from 2026-08-26 and 2026-08-27 are **not** among them.
- [ ] `docs/MODELS.md` and the parent task describe **one** experiment, not two — AC6's tier
      question and AC7's demonstration are the same run and should not be written as separate work.
- [ ] The data-loss instance is referenced from the census store task as motivating evidence: an
      audit worth ~6.5M BTE was delivered somewhere with no remote and is unrecoverable.

## Notes

Filed 2026-09-07 on the operator's instruction, reproduced before filing per the standing
agreement. Found while checking whether the AC6/AC7 experiment could be run at all — the answer
for AC6 is yes and for AC7 is no, and the difference was invisible from the task text.

This is a defect in a **criterion**, not in code. It is filed as a task rather than a finding
because findings here are recorded by reviewer agents and attributing this to one would be false
attribution; the 2026-08-25 session-filed defects set the same precedent.

Tier declared T2, not classified. The fix is one criterion's wording, which reads T1, but choosing
what the criterion should measure instead is a judgement about the experiment's validity. Run
`tier-classify` rather than trusting this line.

## Outcome 2026-09-08 — amended on the operator's instruction

AC7 was **withdrawn and replaced** in `T-20260826-no-agent-owns-verifying-documented-claim`, and
AC6 was rewritten so the two read as one experiment. The withdrawn text is kept visible above the
replacement rather than overwritten, and the reason is recorded in that task's new
*"The AC6 / AC7 amendment"* section.

On this task's own four criteria: the first three were done by that amendment. The fourth — the
data-loss instance referenced from the census store task — was **already largely there**: the
`CORRECTION 2026-08-27` section of `T-20260826-a-verified-claim-about-the-tree-has-no-a` records
792 claims absent and 35 transcripts gone. What it did not name was the *mechanism*, so that was
added: the audit was delivered into an isolated copy with no remote, and nothing was ever deleted.

**Not marked done here** — per the working agreement that is the operator's, and this is a
close-recommendation.

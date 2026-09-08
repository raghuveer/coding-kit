---
id: T-20260908-kit-resolve-list-unfixed-counts-supersed
title: kit-resolve --list --unfixed counts superseded findings so it over-reports the gate it is named as listing
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-resolve.sh, tooling/kit-preflight.sh, tests/conformance.sh
state: created
---

## Intent

`kit-preflight.sh --criticals` refuses with a STOP and then tells the operator how to see what is
blocking them:

> `kit-status.sh` lists them per task; **`kit-resolve.sh --list --severity critical --unfixed`
> names them.**

**It does not name them.** `--unfixed` filters on `fixed_at` alone, so a finding that left the gate
via `--superseded` or `--unassessable` is still listed. The command the gate points at over-reports
the gate by exactly the number of dispositions that are not `--fixed`.

## Reproduced 2026-09-08, live, on this repository

```
kit-resolve.sh --list --severity critical --unfixed   ->  18
kit-preflight.sh --criticals                          ->   9 unfixed critical(s) outstanding
```

The gap is **9**, which is exactly the nine criticals superseded on that task earlier the same day
(five that died with the rejected `2026-09-08-claim-identity.md`, four transfer originals marked
after their re-filed copies existed). Before those marks the two agreed.

**This defect was hit rather than found.** In the same session the wrong number was read off
`--list --unfixed`, reported to the operator as the gate, and corrected only when
`kit-preflight.sh` was run directly and disagreed. That is the failure mode, exactly: the operator
follows the STOP message's own instruction and gets a number that is not the gate.

## Why it is not merely cosmetic

- **It inflates in the direction of despair.** Every disposition that is not `--fixed` widens the
  gap, so the more carefully an operator uses `--unassessable` and `--superseded` — the two verbs
  this repo added specifically so a gate could be cleared honestly — the more wrong this listing
  becomes.
- **The two excluded classes are the ones with the strongest evidence.** `--superseded` requires a
  marker in the tree; `--unassessable` requires a reason. `--fixed` requires neither. So the
  listing hides nothing and shows everything *except* the dispositions that had to prove
  themselves.
- **It is the recorded-vs-derived split reporting two different numbers for one fact** — the shape
  this repository files against itself elsewhere as *two artefacts carrying one fact with nothing
  comparing them*.

## What is NOT wrong, checked before proposing anything

`kit-preflight.sh --criticals` is correct: 9 matches a direct query with the full predicate
(`fixed_at IS NULL AND unassessable_at IS NULL AND superseded_at IS NULL`). The bug is in the
listing, not in the gate. Nothing that gates work is currently wrong — only the thing that explains
it.

## Acceptance criteria

- [ ] `--unfixed` means what the pre-flight means: it excludes `fixed_at`, `unassessable_at` and
      `superseded_at`, so the listing and the gate cannot disagree.
- [ ] The two numbers are computed from **one** predicate with one home, rather than from two
      queries that happen to agree — the finding-vocabulary drift is the precedent for why two
      copies is not a fix.
- [ ] A conformance step asserts the listing's count equals the pre-flight's count on a fixture
      that contains at least one finding of **each** disposition, so a regression in either half
      fails. A fixture with only `--fixed` rows cannot fail and does not count.
- [ ] The pre-flight's STOP message names a command that actually reproduces its own number, or
      names a different one.
- [ ] Whether `--unfixed` should have a companion that shows *all* undisposed-or-otherwise rows is
      decided explicitly rather than by leaving the current behaviour as an accidental feature.

## Notes

Filed 2026-09-08 on the operator's instruction, reproduced live before filing — both numbers read
in the same minute from the same tree.

**Tier declared T2, not classified.** The edit looks like one SQL predicate, which reads T1, but
`tier.rule` puts a `tooling/**` floor at T2 and the change touches the two places that must agree
about what the gate is. Run `tier-classify` rather than trusting this line.

**Not proposing the fix here beyond the criteria.** Whether the predicate belongs in a shared
function, a view, or a single query both callers use is an implementation judgement, and picking it
in the task is how a task starts constraining work it has not costed.

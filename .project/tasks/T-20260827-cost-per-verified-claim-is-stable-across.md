---
id: T-20260827-cost-per-verified-claim-is-stable-across
title: Cost per verified claim is stable across subjects so a census can be quoted before it runs
epic: measurement
tier: T2
paths: tooling, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

Two reconciliations have now run on unrelated brownfield Rust subjects. The per-claim cost differs
by **5%**.

| | highper-gateway (2026-08-26) | aeon (2026-08-27) |
|---|---|---|
| Subject size | 291 `.rs`, 2 crates, 169 commits | 277 `.rs`, **14 crates**, 249 commits |
| Units | 16 use cases | 18 phases |
| **Claims** | **303** | **489** |
| Subagent rows | 17 | 18 |
| Turns | 764 | 1,256 |
| **BTE** | **11,066,325** | **17,015,010** |
| **BTE per claim** | **36,522** | **34,796** |

1.61× the claims for 1.54× the cost, across repositories differing 7× in crate count. **The cost
driver is the number of claims to be re-derived, not the size of the tree.**

If that holds on a third subject, a reconciliation becomes **quotable in advance**: count the ✅
items in the roadmap, estimate claims per item, multiply by a per-claim rate the kit has measured.
An operator deciding whether to spend 17M BTE on a survey can see the number first.

Today the kit cannot express any of this. Both figures in the table above were re-derived by hand
from `events.ndjson` while writing the trial document, because neither trial's totals are queryable
— which is `T-20260826-the-trial-environment-is-recorded-as-pro` biting on its first real use.

## What this is not

**It is not a general estimator for kit work.** The stability observed is for one instrument doing
one job — verify N documented claims against a tree — where each claim costs roughly the same to
check because each is a bounded read-and-compare. Nothing here predicts the cost of implementation,
review, or debugging, and the estimate must refuse to be used for them.

**n = 2.** Two points fit any line. The claim in this task is "worth measuring a third time and
worth recording so a third measurement is possible", not "the rate is 35k". The acceptance criteria
below are deliberately about *recording and refusing*, not about publishing a constant.

## Acceptance criteria

- [ ] Trial totals — rows, turns, BTE by scope, and **claim count** — are recorded as structured
      data, not prose, so two trials can be compared by query. Shares the artefact with
      `T-20260826-the-trial-environment-is-recorded-as-pro` rather than adding a second store.
- [ ] The kit can report **BTE per unit of work** for any recorded run whose unit count is known,
      and reports it as `n=<runs>` alongside — never as a bare rate.
- [ ] An estimate is **refused below a stated minimum sample** rather than extrapolated from one
      run. A single trial produces "no estimate available, n=1", not a number.
- [ ] The estimate carries the **spread across observed runs**, not just a mean. Two runs 5% apart
      and two runs 400% apart must not print the same way.
- [ ] The estimator's scope is stated in its own output: **claim-verification work only**, with a
      named refusal for other work types.
- [ ] Mutation proof: recording a third run with a wildly different per-unit cost widens the
      reported spread rather than silently averaging it away.

## Notes

The reason to build this rather than note it: **the survey is the most expensive thing the kit
does and the only one whose value an operator must judge before paying.** 17M BTE bought 489
verdicts and two security findings on aeon. Whether that is a good trade is the operator's call,
and they can only make it with a number in front of them.

Evidence: `docs/TRIALS/2026-08-27-aeon-reconciliation.md`, methodology finding M6, and the cost
sections of both trial documents.

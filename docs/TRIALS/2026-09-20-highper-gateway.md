<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial 3: highper-gateway — 2026-09-20

| | |
|---|---|
| Question | **Does the verify ladder produce a verdict you can act on, when it runs on a real code change in an unfamiliar codebase whose baseline is red?** Written at pre-flight, before the first command. |
| Kit SHA | `0c61c69` (pre-flight); runtime `cck-trial sha256:e5ed7efcc9b5…` |
| Time-box / actual | **1 hour**, extended in 1-hour increments only while producing. Actual: *not started* |
| Subject | highper-gateway, Rust, workspace with a `highper-gateway` member. Subject `e588b53`; copy `9cc4e55` = subject + 2 recorded pre-flight commits |
| Greenfield / brownfield | **brownfield**, history not truncated, all 3 branches present |
| Rung dispositions | *one line per rung: `satisfied` \| `unavailable` (compensating control, tier raised) \| `unsatisfiable` (what did not run). **Any `unsatisfiable` makes the outcome VOID** — §3, §6* |
| Outcome | COMPLETE \| ABORTED (*cause*) \| VOID (*condition*) |
| Baseline before the kit | *one line per check, with its CAUSE — see the Baseline section below. `build pass, tests fail` is not a baseline* |
| Instruments verified live | spend rows > 0, findings row landed |
| Copy isolation verified | `kit-preflight.sh --isolated` exit 0 — no remote, no shared object store, no permission rule reaching outside |

## Stop rules, stated before the clock

Stop and record what you have when **any** of these fires:

- the time-box expires
- the same defect appears a **third** time — that is a pattern, not an instance
- **any VOID condition in §3 fires**, including the ninth added 2026-09-20: a rung declared
  `unsatisfiable` and the trial continued
- the kit needs a `commands.*` change to proceed. That change voids the trial under §2, so the
  trial stops and says so rather than making it
- you cannot state what the next step is testing

## Abort path, stated before the clock

If the kit crashes or corrupts state mid-trial: **stop, do not repair.** File as
`docs/TRIALS/2026-09-20-highper-gateway-VOID.md` naming the condition hit and what was established
before it. The copy is disposable and the subject is untouched by construction, so nothing is
recovered by pressing on.

## Baseline before the kit

Taken **before adoption**, because it cannot be reconstructed afterwards. **One row per check,
and every failing row carries its cause** — the error codes or advisory ids, and the command that
produced them.

| check | command | exit | seconds | cause, if it failed |
|---|---|---|---|---|
| build | | | | |
| tests | | | | |
| lint | | | | |
| typecheck | | | | |
| advisories | | | | |

**`build pass/fail, tests pass/fail` was the old shape of this section and it is the defect it
replaces.** On 2026-09-09 that shape reported one subject as red, and a later reading found the
release build **passed** while three CI jobs failed for three unrelated reasons — so one job's
cause stood in for four, and the aggregate word was what got quoted.

**Where the subject has its own CI, record each job separately.** An aggregate verdict hides
which half is broken, and a second trial cannot then tell a new failure from an old one.

| CI job | verdict | cause |
|---|---|---|
| | | |

**A cause you did NOT verify is written as unverified, by name, here and everywhere it is
repeated.** Not in a footnote, not only in the working notes. The 2026-09-09 notes flagged their
inference honestly and the record above them did not, and the record is what gets read — an
unverified cause carried into a later section as established is how a guess becomes a fact.
Use the literal word **unverified** so it survives being quoted.

**The commands are the ones the subject's own CI runs**, not ones invented for the trial. Where
they differ — a narrower feature set, a single package instead of the workspace — say which was
used and why, because three different commands give three different answers to "is this subject
green" and the report must name the one it means.

## Cost

**n on every figure, in the figure.**

- BTE by tier / scope / provenance / model — from `kit-status.sh`
- BTE by agent — from the §1 query
- Raw counters, so the weighting can be redone if pricing changes
- Wall-clock and API time, separately

## Findings

- By agent: class, severity, summary
- **Rejected by the recorder** — `finding-gap` rows with reasons. A `rejected` row is a review
  whose findings were lost; a `empty` row is a review that found nothing. They are not the same.
- Escape rate by tier, over **both** provenance populations. If `via:kit` has no denominator,
  say so rather than printing zeroes shaped like a rate.

## Which brownfield degradations bit

- Over-tiering from an empty edge table
- Co-change: usable graph, or withheld
- Planner ordering on a backlog it did not author

## Three kinds of finding

1. **Kit defects** — filed as tasks before any is fixed
2. **Subject defects** — delivered to the owner as a proposal, never applied
3. **Methodology** — folded back into `TRIAL-PROTOCOL.md` §3, with a detection

## Not exercised

*What ran and produced nothing, and what never ran. An untested component named as untested is
information; one omitted reads as fine.*

## Disputed

*Findings the subject's owner disagrees with — both positions, unresolved. The trial measures
whether the kit produced the finding, not whether it is correct.*

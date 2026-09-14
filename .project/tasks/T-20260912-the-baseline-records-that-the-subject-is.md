---
id: T-20260912-the-baseline-records-that-the-subject-is
title: The baseline records that the subject is red, not why, so an unverified cause survives the trial
epic: validation
tier: T2
paths: docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

Section 0's baseline item asks *"does the subject build, do its tests pass, how long do
they take"*, and the report template carries it as `build <pass/fail>, tests <pass/fail>,
<duration>`. **State and duration, never cause.**

A pass/fail with no cause is not a baseline you can reason from. It cannot tell a later reader
whether a failure is one defect or five, whether the trial's own work touched it, or whether it
has been fixed since -- and it leaves a vacuum that a plausible guess fills.

**Measured, and the guess was wrong.** The 2026-09-09 highper-gateway record captured three facts
with no reason attached to any of them: *"build green, tests do not compile"*, and the subject is
*"red on its own CI at this SHA"*. The trial notes then attributed that redness to a single cause,
the `signals.rs` `E0308`, and separately recorded an inference about a second -- flagged honestly
in the notes as *"(unsourced inference) ... not verified"*.

On 2026-09-12 the subject's CI logs were read for the first time. `master` is red for **three
distinct reasons**, and the recorded attribution covers one of them:

| job | cause | matches the recorded attribution? |
|---|---|---|
| `Test` | one `E0308` in the lib test target | **yes** |
| `Check`, `Clippy` | **90** errors under `--all-features` -- `E0405`, `E0422`, `E0425`, `E0433`, unresolved traits, names and paths | no |
| `Security Audit` | `RUSTSEC-2026-0255` (panic-safety unsoundness) plus a yanked `spin 0.9.8` | no |

`Build Release` passes. So "red on its own CI" was one job's cause generalised to all of them, and
the unverified `protoc` inference sat on top of it for three days and was repeated to the operator
as though it were established, until the logs refuted it.

**The cost is not the wrong guess.** It is that nothing in the protocol required the evidence that
would have prevented it, while §3's whole premise is that a condition without a detection is not a
control. The same standard has not been applied to the baseline.

## Acceptance criteria

- [ ] The baseline records the **cause** of every failing check, not only pass/fail: the error codes or advisory ids, and the command that produced them. `build <pass/fail>, tests <pass/fail>` is the current shape and it is what let one job's cause stand in for four
- [ ] Where a subject has its own CI, the baseline records **each job's verdict separately**. On this subject the aggregate 'red' hid that `Build Release` passes and three jobs fail for three unrelated reasons
- [ ] A cause the trialist did not verify is recorded as **unverified, by name**, and never carried into a later section as established. The 2026-09-09 notes did flag their inference honestly; the record above them did not, and the record is what gets read
- [ ] The report template carries the baseline in this fuller shape, so a second trial on the same subject can tell which failures are the same ones and which are new -- the comparison §2 exists to make legitimate
- [ ] A CHECK THAT CAN FAIL: a conformance step asserting the template names cause-per-check and not only pass/fail, in the same shape as the step asserting §0 calls the superseded count

### Evidence, 2026-09-14 — proposed, not certified

| AC | addressed by | where to verify |
|---|---|---|
| 1 — cause per failing check, with the command | a per-check table in `docs/TRIALS/TEMPLATE.md` — check, command, exit, seconds, cause — and §0's baseline box requiring the same | the old row, `build pass/fail, tests pass/fail`, is gone as an instruction and survives only where it is named as the defect |
| 2 — each CI job's verdict separately | a second table in the template, and §0 saying to use the commands the subject's CI runs rather than ones invented for the trial | |
| 3 — an unverified cause named as such, never carried forward as established | both documents require the literal token `unverified`, and the conformance step asserts the token rather than the idea | a synonym per trial is not a mark a reader can grep for |
| 4 — the template carries the fuller shape | `TEMPLATE.md` grew a `## Baseline before the kit` section | asserted on the template as well as the protocol: the protocol is read once, the template is copied into every report |
| 5 — a check that can fail | conformance step, mutation-proven | collapse the table back to `check \| result` and it goes red naming the missing column |

**AC3's failure mode was committed by me today, in this repository, while working on its
sibling.** The figure *"90 `--all-features` errors"* was quoted from this task into
`docs/DEPENDENCIES.md`, into a trial-2 blocker table, and then into a commit message asserting
that a fresh measurement of 91 *"reproduced the same baseline"*. It had no measurement behind it
anywhere: trial 1's run of that command failed at `protoc` and counted nothing. An unverified
cause repeated until it reads as established is exactly what this criterion forbids, and it took
three artefacts and one day.

**A worked example now exists for the shape**, measured 2026-09-14 on `highper-gateway` at
`05c56eb` in the trial runtime — the same subject whose aggregate `red` this task was filed
about:

| check | command | exit | seconds | cause |
|---|---|---|---|---|
| build | `cargo build --release -p highper-gateway` | 0 | 579 | — (from trial 1) |
| tests | `cargo test --workspace --lib -- --test-threads=4` | 101 | 167 | **one** `E0308` in `runtime/signals.rs`; target does not compile, so 0 tests ran |
| tests, after the one-line fix | same | 101 | 4.8 | 972 passed, 2 failed: `runtime_config` not installed by `test_health_check`; defaults failing their own `InvalidCombination` validation in `load_with_no_env_vars_returns_defaults` |
| typecheck | `cargo check --workspace --all-features` | 101 | 248 | 91 errors, all under `highper-gateway/` — 48 `E0433`, 36 `E0425`, 2 `E0422`, 2 `E0405`, 2 missing `async_trait` |

Four rows, four different answers to *"is this subject green"*, from one subject on one day. The
aggregate word this task was filed about cannot carry any of them.

## Notes

Filed on the operator's instruction of 2026-09-12, after the subject's CI logs were read
for the first time and refuted a cause carried since 2026-09-09.

**This is a methodology finding, and the second of the day.** The first is
`T-20260912-a-declared-rung-whose-tooling-fails-has-` -- a declared rung that fails has no
disposition. Both come from the same trial and both are about the protocol rather than the code,
which is the half that had not been landing: that day produced three kit defects fixed and seven
tasks filed, almost all of them defects.

**Not in scope: fixing the subject.** The 90 `--all-features` errors, the `E0308` and the
advisories belong to that project's owner and are routed by §7's three kinds of finding. A pull
request declaring the subject's build dependencies was opened separately and deliberately **left
open**, because merging it would destroy the only evidence that it is inert -- the failure set is
currently identical before and after it, which is what proves it changed nothing.

**Related:** `T-20260826-the-trial-environment-is-recorded-as-pro` made the same argument about
the environment being prose rather than data. This is that argument applied to the subject's
starting state.

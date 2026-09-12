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

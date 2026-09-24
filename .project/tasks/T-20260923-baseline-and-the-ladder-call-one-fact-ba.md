---
id: T-20260923-baseline-and-the-ladder-call-one-fact-ba
title: Baseline and the ladder call one fact baseline and unsatisfiable
tier: T3
lang: bash
state: created
---

## Intent

Two controls read the same fact and imply opposite outcomes.

**§0 of `docs/TRIAL-PROTOCOL.md`** blesses a red-baseline subject: *"A subject whose tests
already fail is a valid trial subject, but only if you knew that first, and only if you knew
WHY."* `kit-preflight.sh --commands` exists to separate that case from tooling that cannot run,
and its verdict is `=baseline`, which proceeds.

**`skills/verify-ladder/SKILL.md`** defines `unsatisfiable` as *"a satisfaction IS declared and
it does not run, **or cannot be made to pass for reasons outside the change**"*, and names as
its own example *"a target that does not compile before you touched it"*. Under `## Completion`:
*"a trial that discovers an unsatisfiable rung after starting has no non-voiding move left. The
outcome is VOID."*

A red-baseline subject satisfies both descriptions simultaneously. So either:

- the ladder governs, and **every red-baseline trial is VOID by construction** — §0's permission
  to run one can never be exercised, and the §0 gate that exists to grant it is decorative; or
- §0 governs, and the ladder's `unsatisfiable` has no force on precisely the subjects it was
  written for. It was added because the 2026-09-09 trial reported COMPLETE over a change that
  does not compile.

**Measured on trial 3, 2026-09-23.** Pre-flight dispositioned `test:101, lint:101,
typecheck:101` as `=baseline` and exited 0. After the change, rung 1's command still exited 101
for reasons in two files the change does not touch, while the change's own module went from 89
errors to 0. The trial's outcome label could not be written without deciding this.

## Acceptance criteria

- [ ] One document owns the distinction and the other cites it. Two homes for one rule has been
      wrong twice already in this repository (§0's criticals box says so itself).
- [ ] The rule is stated so that a reader with a red-baseline subject and a passing `--commands`
      pre-flight can reach the outcome label without judgement.
- [ ] Whatever the resolution, `kit-preflight.sh --commands` and the ladder agree by
      construction — the pre-flight's recorded disposition should be readable by whatever names
      the rung later, rather than re-derived from the same exit code.
- [ ] A check that fails on the contradiction as it stands today.

### Folded in from K4, 2026-09-24 — rung 1's "scope wider than the change"

**Operator decision 2026-09-24: option A, and K4's rung-1 half moves here.** The two could not be
separated. The obvious resolution of this task -- judge a `=baseline` rung against the recorded
baseline, passing when every failure after the change was already in it -- is refuted by trial 3's
own data: rung 1 went 90 -> 7 errors and **6 of the 7 were not in the before-log**
(`docs/TRIALS/2026-09-20-highper-gateway.md`, "The 7 that remain were UNMASKED"). rustc stopped at
name resolution while 89 import errors stood, so it never type-checked the other files. A strict
subset rule fails the rung the operator ruled COMPLETE; any rule that passes it has to say what a
failure outside the diff means, which was K4's rung-1 question.

**Option A, as decided:**

- the ladder owns the dispositions; `docs/TRIAL-PROTOCOL.md` and `kit-preflight.sh` cite it;
- `unsatisfiable` narrows to *the command produces no verdict on the changed code* -- it does not
  run, or a failure that predates the change stops it before it reaches the change. Both 2026-09-09
  rungs stay VOID (`protoc` missing; the `--lib` target never compiled, so no test ran);
- a rung that runs on a baseline dispositioned `=baseline` must show **zero failures in the files
  the diff touches** -- a failure there is the rung working, fix the change. Failures elsewhere are
  recorded with causes as baseline or unmasked and do not block;
- **the cost, stated:** this rung no longer catches a change that breaks an untouched file, e.g.
  through a signature. Compensating control: rungs 4 and 5 are handed the unmasked list;
- the "no verdict" guard must catch a build that stops BEFORE the changed unit, or "zero failures
  in touched files" is vacuous -- the 2026-09-09 shape again. Default: no evidence the command
  processed the touched files means `unsatisfiable`.

**Added acceptance criteria (from K4):**

- [ ] The trial-3 rung-1 case is the worked example, and reaches its disposition without judgement.
- [ ] The rule makes the 2026-09-09 case harder to reach, not easier -- both its rungs stay unsatisfiable, and its non-compiling change fails at rung 1.
- [ ] Scope-narrowing is ruled on with its cost stated: touched files are judged, cross-module breakage is handed to rungs 4 and 5.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K3, and the "Why two rungs are
CONTESTED" section.

This blocks the outcome label of trial 3 and of every future trial on a red-baseline subject,
which is the whole brownfield population.

### Operator decision 2026-09-24, after the second review chain: R1, reach is per UNIT

Two T3 chains, four `revise`. Chain 1's critical (reach evidence taken from the BEFORE run) was
fixed in `00f64eb` and both chain-2 readers confirmed it holds. Chain 2's critical, found by both
independently and reproduced here in a three-crate cargo workspace: reach evidence was counted per
FILE, so a warning in one touched crate stood in for a second touched crate that never built behind
a red dependency -- "satisfied against baseline" over a change that does not compile. Diagnostics
also cannot show reach for a clean change (it emits none) or for `cfg`-gated code.

Each text fix to step 1 moved the hole sideways, so the question went back to the operator.
**Decided: R1.** Every unit containing a touched file must get a complete verdict from the after
run, with every failure in a touched file; a touched unit that fails elsewhere, is blocked by a
dependency, or is skipped is `unsatisfiable`. A unit that passed before and fails after is a
regression, not unmasked.

**Stated consequence: under R1 trial 3's rung 1 is unsatisfiable and trial 3 would be VOID** --
`plugin/` shares the `highper-gateway` crate with `discovery/consul.rs`. The 2026-09-23 record
stands as the ruling made before the rule existed. Chain 2 also corrected a claim of mine: the
after-run logs DO exist at `D:/trials/trial3-target/` (I had searched only the subject copy).

---
id: T-20260923-baseline-and-the-ladder-call-one-fact-ba
title: Baseline and the ladder call one fact baseline and unsatisfiable
tier: T3
lang: bash
state: created
via: kit
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

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K3, and the "Why two rungs are
CONTESTED" section.

This blocks the outcome label of trial 3 and of every future trial on a red-baseline subject,
which is the whole brownfield population.

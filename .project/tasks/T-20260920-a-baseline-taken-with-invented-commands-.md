---
id: T-20260920-a-baseline-taken-with-invented-commands-
title: A baseline taken with invented commands measures a different codebase than the subject gates on
epic: validation
tier: T2
paths: docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

**§0's baseline box says to record causes. It does not say WHOSE COMMANDS to run, and the first
real use got that wrong in the direction that flatters the subject.**

Taking the trial-3 pre-flight on 2026-09-20, this session chose `cargo check --locked`,
`cargo clippy --locked`, `cargo test --locked --no-run` and `cargo fmt --check` — plausible
commands, none of them the subject's. The subject's `.github/workflows/ci.yml` gates on:

    cargo check   --workspace --all-features
    cargo clippy  --workspace --all-features -- -D warnings
    cargo test    --workspace --lib -- --test-threads=4
    cargo fmt     --all -- --check

**The difference is not cosmetic. It inverted the headline.**

| | invented command | subject's command |
|---|---|---|
| does it compile | `cargo check --locked` → **exit 0**, "the subject compiles" | `--workspace --all-features` → **exit 101**, *cannot find attribute `async_trait`* |

The recorded baseline said **THE SUBJECT COMPILES**. It does not, under the command the subject
itself gates on. Re-measured with their commands, the container reproduces their CI exactly: Check,
Clippy and Test fail, Format passes — **four for four** against a `master` that has been red since
2026-09-14.

**And it hid the cause.** With `--all-features` off, three unrelated-looking symptoms surfaced — a
one-line lockfile gap, a `Config` initializer missing two fields, a loop that never loops. With it
on, there is **one** root cause breaking all three jobs: `async_trait`. The cheaper commands
produced more findings and a worse diagnosis.

**Why this is a protocol defect rather than an operator error.** §0 already knows a baseline must be
causal — *"`build pass, tests fail` is not a baseline"*. It does not extend that to provenance: a
cause measured by the wrong command is a cause for something nobody runs. The operator has no
prompt to look for the subject's declared verification, and there is usually somewhere obvious to
look — a CI workflow, a Makefile, a CONTRIBUTING file.

## Acceptance criteria

- [ ] §0's baseline box requires the subject's own verification commands, and says where to find
      them — CI workflow, task runner, contributor docs — before falling back to anything invented
- [ ] When no declared command exists, that ABSENCE is recorded as a baseline fact, because a
      project with no stated way to verify itself is a finding about the project
- [ ] The commands used are written into the trial record beside their results, so a later reader
      can tell what was run from what was concluded. The 2026-09-20 record could not
- [ ] A check that can fail: a fixture subject declaring commands in CI is asserted to produce a
      baseline citing those commands, and a mutation substituting different ones takes it red
- [ ] Whether `commands.*` in the kit profile should be SEEDED from the subject's declared
      verification is decided rather than left open. The gate added on 2026-09-20 stops on
      `commands.*` that do not run; seeding them wrongly moves the error one step earlier

## Notes

Found 2026-09-20 during the trial-3 pre-flight, by checking the subject's CI status before choosing
a task and noticing its Check job fails where this session's baseline had it passing.

**The correction also changed the trial's task.** Roadmap item 3.4.A asks for five SAST tools to be
wired into CI; three already are, and four of seven CI jobs have been failing for six days, so the
first step is not wiring anything. That was invisible while the baseline said the subject compiled.

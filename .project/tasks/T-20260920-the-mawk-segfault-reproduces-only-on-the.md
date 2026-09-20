---
id: T-20260920-the-mawk-segfault-reproduces-only-on-the
title: The mawk segfault reproduces only on the GitHub runner, so nothing local can gate it
epic: validation
tier: T2
paths: tooling/kit-index.sh, tests/conformance.sh
state: created
---

## Intent

**Two different failures came out of one defect, and only one of them is now covered.**

The untyped array element in `kit-index.sh` — reading `v["paths"]` on a task file with no `paths:`
key — produced a **deterministic fatal under gawk** and a **heap-corruption crash under mawk**. The
gawk half is reproducible in two seconds and is now gated by the multi-awk conformance step filed
under `T-20260919-conformance-fixtures-are-too-small-to-ex`. **The mawk half is not**, and this task
exists so that gap is a named open item rather than something covered by a step that does not cover
it.

**What was tried on 2026-09-20, against the exact pre-fix tree `7f0db5b`:**

| environment | awk | 224 tasks | result |
|---|---|---|---|
| `ubuntu:22.04` container | mawk 1.3.4 20200120 | yes | clean, 224/224 indexed |
| `ubuntu:24.04` container | mawk 1.3.4 20240123 | yes | clean, 224/224 indexed |
| `debian:trixie` container | mawk 1.3.4 20250131 | yes | clean, 224/224 indexed |
| each of the above | — | — | repeated under `LANG=C`, `C.UTF-8`, `en_US.UTF-8` |
| GitHub `ubuntu-latest` | mawk (`/usr/bin/awk`) | yes | **`malloc_consolidate(): invalid chunk size`** twice, **segfault** twice, four for four |

Six-plus runs across three mawk builds and three locales, all clean, against the identical
backlog at the identical commit. The runner failed four times out of four on the same code.

**So it needs something the container does not have.** Heap corruption only crashes once the
allocator is churned into the wrong state, so the plausible remaining variables are the runner's
glibc build, its allocator tuning, memory pressure and ASLR — none of which a fixture controls. That
is a hypothesis and it is written down as one; it has not been instrumented.

**Why this matters beyond one crash.** A defect class that is only observable on the CI runner
cannot be gated by a local suite at all. Either a reproducer is found, or the honest position is
that `structure` — which indexes the real backlog and found this by accident — is the only thing
that sees it, and that job should say so deliberately instead of catching it as a side effect.

## Acceptance criteria

- [ ] Either the segfault is reproduced off the GitHub runner, with the variable that produces it
      named, or this task records that it could not be and says what was ruled out
- [ ] If it cannot be reproduced, the `structure` job's incidental coverage is made deliberate:
      it indexes the real backlog, and that is currently the only thing that has ever seen this
      failure. A control found by accident is not a control
- [ ] **The multi-awk step is not offered as covering this.** It gates the gawk manifestation and
      is measured doing so; this is the other half and must be closed on its own evidence
- [ ] Whatever is decided is reachable from `T-20260919-conformance-fixtures-are-too-small-to-ex`,
      whose AC5 is closed by this task existing rather than by anything being fixed here

## Notes

Split out of `T-20260919-conformance-fixtures-are-too-small-to-ex` on 2026-09-20, as that task's
AC5 requires: *"Either a scale fixture is shown to catch it, or this task records that it is only
reachable on the runner and files that separately."* This is the separate filing. The parent's
original scale premise was refuted in the same session — the defect fails at three task files under
a failing awk and passes at 224 under a tolerant one — so a scale fixture was not shown to catch it
and was not built.

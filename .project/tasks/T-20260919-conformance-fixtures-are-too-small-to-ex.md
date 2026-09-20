---
id: T-20260919-conformance-fixtures-are-too-small-to-ex
title: Conformance fixtures are too small to exercise the indexer at real scale
epic: validation
tier: T2
paths: tests/conformance.sh
state: created
---

## Intent

**AMENDED 2026-09-20 — THE ORIGINAL DIAGNOSIS IN THIS TASK IS REFUTED BY MEASUREMENT.** The gap is
real and the suite is blind, but **fixture SIZE is not the variable**; which `awk` runs is. The
title and id are left unchanged on purpose: the id is referenced by two dependency-map edges and by
the findings recorded against it, and renaming to fix a wording error would orphan them. Read the
title as the question that was asked, and section *"What was actually measured"* as the answer.

**The suite stayed green through four consecutive core dumps of the thing it exists to check.**

On 2026-09-19, `tooling/kit-index.sh` crashed under mawk — `/usr/bin/awk` on `ubuntu-latest` — on
every commit of `feat/pack-files-from-declared-paths`, four times, with two different signatures:

    malloc_consolidate(): invalid chunk size   (core dumped)
    Segmentation fault                        (core dumped)

**`conformance (ubuntu-latest)` passed on the same runner, in the same workflow, every time.**
The only job that ever saw it was `structure`, which runs `kit-index.sh` against this
repository's own backlog. Two blind reviewers named the reason independently: *"the conformance
suite passed on the same runner because its fixtures are small."*

**The gap is a property of the suite, not of that change.** Every fixture in `tests/conformance.sh`
builds a repository with a handful of task files — typically one to six. The indexer's behaviour at
224 task files is not exercised anywhere, on any platform, by anything except the `structure` job's
incidental use of the real backlog. So the suite cannot fail on:

- an awk that copes with six records and not with two hundred
- anything whose cost is per-task and only visible in aggregate
- a resource that leaks per file rather than per run
- any interaction between two tasks that a one-task fixture cannot express

**This is the `LESSONS.md` §1 shape applied to the suite itself.** A check that cannot go red is
worse than no check, because it is read as coverage. The suite's own summary line already refuses
to call a filtered run a pass; it does not yet refuse to call a small-fixture run a scale test.

**Why `structure` catching it is not the answer.** That job runs the indexer against the live
backlog as a side effect of checking prose references. It found this by accident, it reports the
failure as an unrelated step, and it cannot run on macOS or Windows. A property worth checking
deserves a step that says what it checks.

## What was actually measured, 2026-09-20

Against the exact pre-fix tree `7f0db5b` — the commit that produced the fourth segfault — in
containers, varying one thing at a time. The observable is the indexer's own line,
`kit: task ingest read 0 of N task file(s)`, which is what CI reported.

| awk | 224 tasks | 3 tasks |
|---|---|---|
| mawk 1.3.4, the 2020, 2024 and 2025 builds | pass | — |
| original-awk 20250116 (BSD) | pass | — |
| **gawk 5.2.1** | **fail**, `read 0 of 224` | **fail**, `read 0 of 3` |
| gawk 5.3.2 (this laptop, AND `debian:sid`) | pass | — |
| **gawk 5.4.1** (the Windows runner) | **pass** — see the correction below | — |
| mawk on the GitHub `ubuntu-latest` runner | **segfault** | — |

**It fails at three task files.** A three-task fixture catches it, so the suite was never too small
to see it.

**It passes at 224 under mawk and BSD awk.** So the two-hundred-task fixture this task originally
asked for would NOT have caught the worked example this task names, on three of the four
runner/awk combinations in use. That is the green-that-cannot-fail shape, rebuilt inside the fix
for it.

**The control that does work is proved able to fail, with the fixtures that already exist.** Running
`tests/conformance.sh` on the pre-fix tree:

| tree | under mawk | under gawk 5.2.1 |
|---|---|---|
| post-fix `df19be7` | 112 passed, 6 failed | 112 passed, 6 failed |
| pre-fix `7f0db5b` | 112 passed, 6 failed — **defect invisible** | **rc=1, no summary reached**, `no such table: plan_item` |

The 6 failures are a constant of the container baseline, identical in three of the four cells, so
they cancel; the fourth cell is the signal. **No new fixture was needed to produce it.**

**CORRECTED 2026-09-20, SAME DAY, BEFORE THIS WAS RELIED ON.** This section first said that
`conformance (windows-latest)` went green because Git Bash ships gawk 5.3.2, which tolerates the
construct. **That is true of this laptop and false of the runner.** The environment banner of the
failing run — job `conformance (windows-latest)` of run 35461506879 — reports **GNU Awk 5.4.1**. So
the Windows leg was green while running 5.4.1, and the claim that 5.4.1 does not tolerate the
construct, which this file took from `df19be7`'s commit message rather than from a measurement, is
not supported by that observation. `df19be7`'s gawk-5.4.1 fatal is most likely the *globre* octal
escape of #144, which is a different defect.

**THE CONFOUND IS RESOLVED, AND IT IS THE VERSION.** gawk 5.3.2 was re-run on Linux (`debian:sid`)
against the same pre-fix tree and **passed**, exactly as it does on Windows. Platform is not the
variable.

**SO ONE AWK IS VERIFIED TO CATCH THIS, AND IT IS gawk 5.2.1.** That is what `ubuntu-latest` ships,
which is where this step's coverage actually comes from. macOS runs gawk 5.4.1 beside BSD awk, and
whether *that* pair catches the defect under this step is **untested** — no container image carries
5.4.1, so it was not measured rather than assumed either way.

**THE CONFOUND THIS SECTION ORIGINALLY DECLARED IS NOW CLOSED.** It said version and platform were
not separated because 5.3.2 was measured on Windows and 5.2.1 on Linux. Both have since been run on
Linux: 5.2.1 fails, 5.3.2 passes. The version is the variable and the platform is not. The
conclusion it was hedging — that a multi-awk step must pin what it runs rather than trust a version
ordering — survives and is now better supported, because the ordering turned out to be wrong: it is
not "older and newer both fail", it is 5.2.1 alone among the gawks tested.

**THE SEGFAULT IS A SECOND, SEPARATE MANIFESTATION AND IT DID NOT REPRODUCE.** Six-plus runs at 224
tasks across three mawk builds and three locales, all clean. Heap corruption needing both volume and
that runner's allocator. The original AC2 said to say so rather than declare a step effective, and
this is saying so.

## Acceptance criteria

- [x] At least one conformance step runs the indexer under **more than one awk implementation**,
      pinned by name and version rather than taking whatever `/usr/bin/awk` happens to be
      **MET** — `tests/conformance.sh`, step *"the indexer runs under every awk present, not only
      the default"*. It discovers by NAME (`awk gawk mawk original-awk nawk`), dedupes on the
      VERSION BANNER rather than the path, and prints every version it ran. The path dedupe was
      written first and was wrong: on Git Bash `/usr/bin/awk` and `/usr/bin/gawk` are two files
      that are both gawk 5.3.2 and neither is a symlink, so the step ran gawk twice and reported
      PASS — a control that cannot fail, inside the step written to remove one.
- [x] That step is proved able to fail against the worked example, by running it on the pre-fix
      tree and showing it goes red where the single-awk suite goes green. The measurement above is
      the evidence to reproduce, not to cite
      **MET** — same step, same two awks (gawk 5.2.1, mawk 1.3.4 20250131), three task files:
      pre-fix `7f0db5b` **FAIL**, post-fix `df19be7` **PASS**. Run in `debian:trixie`.
- [x] Cost is stated and bounded. A second awk is one more process per step, not two hundred more
      files; if it turns out to cost more than that, say the number
      **MET, and here is the number: 2,110 ms** for the whole step across THREE implementations
      (gawk, mawk, original-awk) on a three-task fixture — roughly 700 ms per awk including its
      index build. Bounded by how many awks are installed, not by backlog size.
- [x] The step runs on every platform the matrix covers, and **pins the awk it tests** — otherwise
      the Windows leg keeps testing one gawk and keeps passing
      **MET on all three legs, run 35487558693 (PR #165).** The Windows probe was written as a
      probe and not a promise, and it succeeded:

      | leg | implementations the step ran | result |
      |---|---|---|
      | `ubuntu-latest` | **4** — gawk 5.2.1, mawk 1.3.4 20240123, original-awk 20231127, BusyBox 1.36.1 | PASS |
      | `macos-latest` | 2 — BSD awk 20200816, gawk 5.4.1 | PASS |
      | `windows-latest` | 2 — gawk 5.4.1, BusyBox 1.38.0 via choco | PASS |

      Every version is printed by the step at run time, which is the "pins what it tests" half:
      the log names the implementation rather than leaving `/usr/bin/awk` to mean whatever the
      image happens to ship. **`busybox` turned out to be pre-installed on `ubuntu-latest`**, so
      that leg gained a fourth implementation for free.

      **The coverage is still carried by ONE of them.** gawk 5.2.1 on `ubuntu-latest` is the only
      awk verified to catch the defect. macOS and Windows both run gawk 5.4.1, which passed the
      pre-fix tree under the old fixtures, and whether either catches it under THIS step is
      untested. So this criterion is met as written — the step runs everywhere — and that is not
      the same claim as "every leg would catch a regression".
- [x] **The scale question is answered rather than dropped.** The mawk segfault at 224 is a real
      second manifestation that no container reproduced. Either a scale fixture is shown to catch
      it, or this task records that it is only reachable on the runner and files that separately.
      Do not close this criterion by pointing at the awk-coverage step, which does not address it
      **MET BY THE SECOND BRANCH, NOT THE FIRST.** No scale fixture was built, because none was
      shown to catch it. Filed separately as
      `T-20260920-the-mawk-segfault-reproduces-only-on-the`, which carries the full negative
      result and explicitly refuses to let the multi-awk step stand in for it.
- [x] Whether OTHER steps should also gain a second awk is decided rather than left open: this task
      claims one such step, not a rewrite of every fixture
      **DECIDED: one step, not a sweep.** The defect class is the indexer's awk program, and one
      step exercising it under every installed awk covers that class. Running the whole suite once
      per awk would multiply ~100 steps by the awk count to re-test paths that embed no awk at
      all. If a second awk-bearing program appears, it gets a step, not a matrix.

### All six criteria are met as of 2026-09-20. The close is the operator's.

Recorded rather than closed, because ADR 0010 makes the transition the operator's and a session
certifying its own output is the signature that carries no information. Each criterion above
carries the evidence to check, so ticking is a read rather than a re-derivation.

**What a reader should be sceptical of, named here rather than left to be discovered.** Three
green-that-cannot-fail bugs were found INSIDE this work while building the control against that
exact class: the awk dedupe ran gawk twice and reported PASS; the busybox banner would have counted
an implementation that never ran; and the original scale premise would have built a two-hundred-task
fixture that could not catch its own worked example. All three were caught by running the thing
against a case that should fail. None was caught by reading it. A fourth of the same kind is the
most likely defect remaining here.


## Notes

Filed 2026-09-19 from `T-20260817-a-cluster-pack-file-list-ignores-declare`, whose branch produced
the evidence. Three wrong diagnoses were shipped before the real cause was found, each verified
clean under the development machine's gawk, each refuted only by a twenty-minute CI cycle. A local
check at real scale would have answered in one run what four CI cycles answered in an hour.

**AMENDED 2026-09-20.** The closing sentence above — *"a local check at real scale would have
answered in one run what four CI cycles answered in an hour"* — is half right and half wrong, and
the wrong half is the reason this task had to be amended. A local check WOULD have answered it in
one run. Scale is not what would have made it answer; a second awk is. The sentence is left standing
because it is the diagnosis that was believed at filing time, and overwriting it would hide the
error this task now records.

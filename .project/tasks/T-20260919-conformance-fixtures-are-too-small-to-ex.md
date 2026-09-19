---
id: T-20260919-conformance-fixtures-are-too-small-to-ex
title: Conformance fixtures are too small to exercise the indexer at real scale
epic: validation
tier: T2
paths: tests/conformance.sh
state: created
---

## Intent

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

## Acceptance criteria

- [ ] At least one conformance step builds a fixture at a scale comparable to a real backlog —
      the order of two hundred task files, generated rather than committed — and indexes it
- [ ] That step is proved able to fail, against a defect that a small fixture does not catch.
      The mawk crash is the worked example and the commits are on record; if it cannot be
      reproduced from a fixture, say so rather than declaring the step effective
- [ ] Generation cost is stated and bounded, so the suite does not become something people skip.
      `T-20260822-process-creation-costs-one-second-on-the` measured what per-item work costs here
- [ ] The step runs on every platform the matrix covers, since the crash it models was
      platform-specific and invisible on two of the three
- [ ] Whether OTHER steps should also scale up is decided rather than left open: this task claims
      one scale step, not a rewrite of every fixture

## Notes

Filed 2026-09-19 from `T-20260817-a-cluster-pack-file-list-ignores-declare`, whose branch produced
the evidence. Three wrong diagnoses were shipped before the real cause was found, each verified
clean under the development machine's gawk, each refuted only by a twenty-minute CI cycle. A local
check at real scale would have answered in one run what four CI cycles answered in an hour.

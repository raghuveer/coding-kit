---
id: T-20260926-three-steps-reset-the-suite-s-failure-ta
title: Three steps reset the suite's failure tally so CI passes over FAIL lines
epic: conformance
tier: T3
lang: bash
blocked_by: T-20260926-the-state-list-is-written-longhand-in-tw, T-20260926-the-python-only-arm-records-no-finding-o, T-20260926-kit-index-writes-no-index-under-posixly-, T-20260926-the-sign-off-adoption-boundary-check-fai
paths: tests/conformance.sh
state: created
---

## Intent

`tests/conformance.sh` ends with `exit $bad`, and `bad` is the suite's global failure tally,
incremented by `check()`. Three steps also use `bad` as their OWN accumulator and begin with a
top-level `bad=0` -- lines 6165, 6406 and 6538 on `main` at `a158d0a` (a fourth at 2627 is inside
an embedded Python program and is harmless). Each of those resets **erases every failure counted
before it.** A step that fails before them prints `FAIL` and the suite exits 0.

**Measured, 2026-09-26:**

- on a mutated tree the suite printed a `FAIL` line and exited **0** (`--only` two steps);
- **every green `main` run from `73dcaf7` (2026-09-17) onward carries hidden FAIL lines** -- six
  per run on the last six, against a tally of `0 failed`. Runs on 2026-09-14/15 carried none;
  the 2026-09-17 runs that did fail, failed visibly;
- the six green observations `.claude/CLAUDE.md` cites for promoting `conformance
  (windows-latest)` to a required check all fall in that window.

The resets entered with `5304db9` and `bdb871b` (both 2026-09-14) and `c43c8de` (2026-09-20).
Four checks were failing behind them; each is its own task and blocks this one.

## Acceptance criteria

- [ ] No step writes the global tally except through `check()`; the three step-local accumulators get their own names.
- [ ] A control that fails when a `FAIL` line is printed and the suite still exits 0 -- run in CI, and shown red by reintroducing one `bad=0`.
- [ ] `.claude/CLAUDE.md`'s Windows-promotion paragraph states that its six observations were taken with hidden failures, and what re-established them.
- [ ] Lands LAST, after the four blockers, so `main` goes from hidden-red to honestly green rather than to red.

## Notes

The blocking edges are a merge order forced by branch protection, not a design dependency: with the
tally fixed, every required leg reds on the four known failures and nothing can merge.

---
id: T-20260923-the-ladder-has-no-disposition-for-a-rung
title: The ladder has no disposition for a rung wider than the change
tier: T3
blocked_by: T-20260923-baseline-and-the-ladder-call-one-fact-ba
lang: bash
state: created
---

## Intent

`skills/verify-ladder/SKILL.md` states *"A rung has exactly **three** dispositions and no
fourth."* Trial 3 produced two situations that are none of the three, on two different rungs of
one change.

**Rung 1.** `commands.typecheck` is `cargo check --workspace --all-features`. The change fixed
its own module completely — 89 errors to 0 — and the command still exits 101 because of 7
errors in two files the diff does not touch. Not *satisfied* (the command failed). Not
*unavailable* (something is declared). *Unsatisfiable* is the literal reading, and it would void
a trial over a rung that did its job. The real state is: **the tooling runs, the obligation is
met for the change, and the declared command's scope is wider than the change.**

**Rung 2.** `commands.test` ran and produced a real signal — 972 passed, 2 failed, identical
with and without the change, measured by stashing. But the rung's obligation is *"criteria
proven by tests that fail without the change"*, and this change's effect is compile-time under a
feature the test job does not enable. A test that fails without it would be a compile failure,
which is rung 1's job. The state is: **the tooling runs and the obligation does not apply to
this change class.**

This is the 2026-09-09 failure one layer out. That trial's lesson was recorded as *"the
enumeration had two names and the situation was a third"*. The enumeration now has three names
and there are two more situations.

## Acceptance criteria

- [ ] The ladder names both states, or states positively why each collapses into an existing
      one — with the trial-3 case as the worked example either way.
- [ ] Whatever is added cannot be used to wave a rung through. The 2026-09-09 failure was a
      trial reporting COMPLETE over a change that does not compile, and any new name must make
      that case harder to reach, not easier.
- [ ] A rung dispositioned under a new name still blocks or permits completion explicitly.
      Silence is what let the first gap through.
- [ ] Scope-narrowing is considered and ruled on: whether a rung may be evaluated against the
      changed paths rather than the declared command's whole scope, and what that costs in
      missed cross-module breakage.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K4.

Related: the baseline/unsatisfiable contradiction, which is the same area and must be resolved
consistently with this.

**Blocked by `T-20260923-baseline-and-the-ladder-call-one-fact-ba`, declared 2026-09-24.** That task
decides which document owns the rung-disposition rule; the names this task adds go in that home.

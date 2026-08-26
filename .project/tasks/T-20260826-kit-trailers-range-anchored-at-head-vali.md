---
id: T-20260826-kit-trailers-range-anchored-at-head-vali
title: kit-trailers range anchored at HEAD validates the wrong commit after a rejection
epic: validation
tier: T2
lang: bash
paths: tooling/kit-trailers.sh, .claude/CLAUDE.md
state: created
---

## Intent

Observed live on 2026-08-26, in this repository, on the kit's own workflow.

A commit was refused by the `commit-msg` hook for a missing `Task-Id` and `Tier`. The very next
command was the check the working agreement mandates before pushing:

    bash tooling/kit-trailers.sh range 'HEAD~1..HEAD' --enforce

It printed **`kit: 1 commit(s) checked, all trailers valid`** and exited 0.

Nothing was wrong with the checker. The commit had not happened, so `HEAD` was still the *previous*
commit, and `HEAD~1..HEAD` named a commit that had been validated and merged days earlier. The
operator asked for reassurance about work that did not exist and received it.

**This is the exact failure the trailers gate exists to prevent, arriving through the gate's own
verification step.** It was caught only because `git log --oneline -1` was printed alongside and
showed a merge commit where a new one was expected.

## Why it is worse than it looks

`.claude/CLAUDE.md` instructs: *"Always run `bash tooling/kit-trailers.sh range 'HEAD~1..HEAD'
--enforce` and check its exit code before pushing."* That instruction is followed most reliably
right after a commit — which is precisely when a rejected commit makes `HEAD` mean something other
than what the operator believes. The more disciplined the user, the more likely they hit it.

A green here is not merely uninformative. It actively asserts that the work about to be pushed is
valid, when the work does not exist.

## Acceptance criteria

- [ ] `range` reports what it actually validated — the resolved shas and their subjects — so a
      range naming unexpected commits is visible in the output rather than inferable from a count.
      The current line says `1 commit(s) checked` and names nothing.
- [ ] A range that resolves to commits **already reachable from the upstream tracking branch** is
      called out. Validating merged history and reporting success is the specific misreading here.
- [ ] The working agreement in `.claude/CLAUDE.md` is corrected in the same change. It currently
      prescribes an `HEAD`-anchored range, and a rule that produces a false green under an ordinary
      failure is a rule that needs rewording, not just tooling around it.
- [ ] Consider recommending `origin/main..HEAD` as the default form: it names the work being
      pushed rather than a fixed offset, and is empty — rather than falsely green — when nothing
      new exists. **Empty must not read as success.**
- [ ] Mutation proof: a fixture where a commit is refused and the range check runs immediately
      after must FAIL or WARN, and must PASS once the commit lands.

## Notes

**Third instance in one session of the same shape**, which is why it is filed rather than noted:

1. `EXIT=${PIPESTATUS[0]}` after `nerdctl exec ... | tail` reported *tail's* status and printed
   `BUILD_EXIT=0` for a build that had just failed.
2. `diskpart` returned exit 0 with no output in twelve seconds against a 190 GB file, because it
   silently required elevation.
3. This.

The generalisation is recorded as M1 in the 2026-08-26 trial report: **a fast or trivially clean
success on an operation that should be substantial is a failure until proven otherwise.** All three
had the evidence visible in output already printed.

**Do not fix this by making the range check refuse to run.** The check is correct and valuable; it
is the ANCHOR that is unsafe. The fix is to make what was checked legible in the output.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 3 and methodology M1.

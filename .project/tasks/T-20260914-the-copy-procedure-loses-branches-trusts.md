---
id: T-20260914-the-copy-procedure-loses-branches-trusts
title: The copy procedure loses branches, trusts a stale subject, and the baseline dirties what it measures
epic: validation
tier: T2
lang: markdown
paths: docs/TRIAL-PROTOCOL.md, docs/trial-runtime/Dockerfile
state: created
---

## Intent

Three gaps in §0 and §4, all three found inside thirty minutes while executing the pre-flight for
trial 2, and none of them visible if the procedure happens to be run on a clean checkout with a
current lockfile. Each cost a wrong copy or a voided premise before the clock started.

**1. The two-line copy procedure loses every branch but one.** §4 gives:

    git clone --no-hardlinks <subject> <copy>
    git remote remove origin

`git clone` checks out whatever the subject's HEAD points at, and `git remote remove origin`
discards `refs/remotes/origin/*` with it. Run against a subject whose working tree sits on a
feature branch, the copy keeps **only that branch** and `master` is unreachable —
`git checkout master` returns *"pathspec 'master' did not match any file(s) known to git"*.
Measured 2026-09-14: the first copy landed on `proposals/fix-lib-test-compile`, not `master`.

**2. Nothing says to bring the subject up to date first.** The local `master` was two merges
behind `origin/master`; the second copy therefore came out at `05c56eb` — trial 1's exact SHA —
inside a directory named `highper-gateway-e588b53`. **The directory name was the only thing
asserting the version, and it was wrong.** Nothing in §0 or §4 requires the SHA to be printed and
compared, and a baseline taken there would have recorded "the subject moved" about a tree that had
not.

**3. The baseline run dirties the copy, and a dirty tree is a VOID condition.** §3 lists a dirty
subject tree among the conditions that void a trial. `cargo build` on a writable mount rewrote
`Cargo.lock` — one line, `async-graphql-value` — so the act of taking the baseline put the copy in
a state §3 voids on.

This is trial 1's subject finding **S3** confirmed (*"any cargo command without `--locked` rewrites
it"*) and extended: what is new is the consequence. `docs/trial-runtime/Dockerfile` says to mount
read-only *precisely because* a dirty tree voids the trial; the trial-2 pre-flight then mounted
writable to get past a stale lockfile, trading one condition for the other. The trade was made
knowingly and its cost was not stated anywhere a later reader would find it.

## Acceptance criteria

- [ ] §4's copy procedure names the branch explicitly and does it **before** the remote is
      removed, or clones with `--branch`. A copy silently carrying one branch is not a copy of the
      subject.
- [ ] §0 requires the subject's SHA to be **printed and compared** against the intended one, and
      says the directory name is not evidence. A copy at the wrong commit is indistinguishable
      from a correct one by inspection of the path.
- [ ] §0 states that the baseline run itself dirties the copy where the mount is writable, and
      requires the tree to be restored **after the baseline and before the kit touches anything** —
      or requires the baseline to run read-only and treats a stale lockfile as a recorded baseline
      fact rather than something to work around.
- [ ] A check that can fail for at least the SHA and the dirty tree: both are mechanical, and §3's
      own premise is that a condition without a detection is not a control.

## Notes

Filed 2026-09-14 from executing the trial-2 pre-flight, before the trial started. Every one of the
three was caught by printing a value rather than by a check: the branch by `git branch --show-current`,
the SHA by `git rev-parse --short HEAD`, and the dirty tree by `git status --short`. **The protocol
asks for none of the three.**

**Not a reason to delay trial 2 by itself** — each has a manual remedy and all three were applied
by hand. It is a reason not to run a second trial against the unfixed procedure, because the next
person executing §0 reproduces all three.

**One thing deliberately not proposed here:** whether the baseline should run read-only and accept
that `--locked` fails on a stale lockfile. That is a real choice with a cost on both sides — a
read-only baseline cannot measure a subject whose lockfile has drifted, and a writable one voids
the trial it is preparing. It belongs to whoever takes this task with the trial record in front of
them.

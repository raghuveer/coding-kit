---
id: T-20260817-a-cluster-pack-file-list-ignores-declare
title: A cluster pack file list ignores declared paths so it is empty before work starts
epic: planning
tier: T3
lang: bash
paths: tooling/kit-plan.sh, tooling/kit-index.sh, tooling/kit-status.sh, tests/conformance.sh
state: open
---

## Intent

A cluster pack's *"Files this cluster touches"* section is built from one source and one only:

    JOIN edge e ON e.src=p.task_id AND e.rel='touches'      -- kit-plan.sh:351

`touches` edges have exactly one origin — commit diffs carrying a `Task-Id`
(`kit-index.sh:645`, the only `touches` INSERT in the file; there are three edge INSERTs total
and the other two are `depends_on` and `regressed`). So **the pack can only describe work that
has already been committed**, and the pack is read when *starting* a task, which by definition
has no commits yet.

Measured 2026-08-17 at `1f83fe8`:

- **19 of 77** open tasks carry any `touches` edge.
- **42 of the 61** tasks in cluster 1 have none.
- **10 of 11** packs therefore print *"none recorded yet — no commits touch these tasks"*.
- **82 of 104** task files declare a non-empty `paths:` in frontmatter.

**The kit has already met and fixed this exact gap one file over.** `kit-index.sh:206-213`, on
tier floors:

> Files a task has already touched come from the edge table — but **7 of 8 open tasks in a real
> backlog had no touches edges**, because nothing is committed against a task until work begins.
> A floor that only sees touched files therefore passes silently on every task that has not
> started, which is exactly when the tier still matters. So a task may also declare `paths:` in
> its frontmatter.

The floor reads two sources. The pack reads one. The declared paths are sitting in 82 task files,
already parsed by the indexer, and the pack query never looks at them.

The consequence is that the pack's most load-bearing section — the one
`skills/task-context/SKILL.md` step 7 tells the agent not to re-derive (*"The pack already named
the cluster's files — do not re-derive them"*) — is empty for three quarters of the backlog, and
an agent told not to re-derive an empty list has been told to work blind.

## Acceptance criteria

- [x] The pack's file section draws on declared `paths:` as well as `touches` edges, and a task
      with no commits and a declared `paths:` contributes files to its cluster's pack.
- [x] **The two sources stay distinguishable in the pack.** A file a task has actually changed
      and a file it *says* it will change are different claims, and merging them silently turns a
      declaration into evidence. Mark them, or the pack's confidence is unearned.
- [x] **Glob expansion is handled, and this is why the change is not a one-liner.** `paths:`
      values are globs; `node.id` values are literal `f:<path>`. `kit-index.sh:253-265` already
      refuses `[`, `]` and `?` in a glob, with measured reasons (SQLite `GLOB` treats `[ab]` as a
      character class and `?` as a character while the awk side matches a byte). Whatever expands
      globs here must agree with the floor path or be the same code — **two expanders that
      disagree is the defect that section was written about.**
- [x] A conformance step proves it with a task that has a declared `paths:` and no commits, and
      it fails if the pack's file section comes back empty for that task.
- [x] Say what happens when a declared glob matches nothing — a pack naming a path that does not
      exist is the failure `T-20260817-a-touches-edge-is-never-checked-against-` is about, and
      this change can introduce it from a second direction.

### Evidence, 2026-09-19

**Measured against one index, before and after: clusters carrying a file list go from 9 of 19 to
17 of 19.** 108 tasks had declared paths and no `touches` edge, so the pack told them nothing.

**AC3 — the premise in the Intent needed correcting before it could be met.** The task says to
reuse "the floor path" expander. `floorof` does not expand globs to files at all: it matches a
task's declared path STRINGS against tier.rule globs. There was no declared-glob-to-file expander
to reuse, so the requirement became "pick a matcher that cannot disagree with the existing one".

**SQLite GLOB is that matcher, and it is the reference rather than a second opinion.** `globre`
exists to MIRROR SQLite GLOB -- its own comment records it as differentially fuzzed against it at
401,265 glob/subject pairs -- and `kit-index.sh` already matches the tier floor over touched files
with `dst GLOB 'f:<glob>'`. A shell matcher would have been wrong twice over: its `*` does not
cross `/` and SQLite's does. `[`, `]` and `?` are refused with a message, on the measured reason
the tier.rule reader already refuses them.

**Resolved against the tracked tree, not the commit history, and that is the crux.** File nodes
come only from commit diffs carrying a Task-Id -- 161 of 379 tracked files had one -- so expanding
a declared glob against `node` would have returned nothing for exactly the tasks this task is
about. `git ls-files -z` feeds a temp table and the matching happens in SQL.

**AC4 is a control, and the first attempt at proving it was not one.** `git stash push` was used to
put the pre-fix code back; those files were already COMMITTED, so nothing was stashed, the run used
the fixed code, and it passed. That pass measured nothing. Re-done with
`git checkout origin/main -- tooling/kit-index.sh tooling/kit-plan.sh`:

    FAIL  ... 2: the pack names no declared file      (pre-fix code)
    PASS  declared paths reach the pack, marked apart from committed ones, unmatched globs counted

**AC5 — an unmatched glob contributes no edge, so no pack can name a path that does not exist**,
which is the failure `T-20260817-a-touches-edge-is-never-checked-against-` covers from the other
direction. The count is recorded in `meta` AND reported by `kit-status.sh` (59 of 497 at the time of writing, and the command is `kit-status.sh`),
because a count nothing reads is the defect
`T-20260808-cluster-packs-are-generated-and-read-by-` names one file over. It is a notice, not a
warning: a glob may legitimately be declared before the file is written.

**Three defects of my own on the way, none caught by me.** A regex written with real control
characters instead of escapes; an apostrophe inside a comment in a single-quoted awk program, which
is `T-20260808-an-apostrophe-in-a-comment-inside-an-awk`; and an untyped array element reaching
`split`, which aborts gawk 5.4.1 on the SECOND task file after the first has emitted. The ingest
guard refused to rebuild every time -- without it the third would have left a half-built index
reported as a whole one.

### Rung 5, 2026-09-19 — two blind readers, BOTH REJECT

Not REVISE. Fourteen findings between them, four majors that neither shared, and a process failure
of mine that both detected independently.

**I edited the working tree while both were reading it.** One found `kit-index.sh` changing under
them mid-review; the other watched `index.db` revert repeatedly, restored it from a backup, and
moved the rest of its work into isolated worktrees. One explicitly discounted a timing measurement
as contaminated. That is *never let a run finish against a tree you are editing*, broken while
running the control that exists to catch me.

**What only reader A found:** the pack ordered touched-first and capped the combined list at 40, so
a cluster with 40+ touched files showed **no** declared-only files. Reproduced on this repository's
cluster 2 — five declared-only files, none named. **That is AC1 failing in the busy-cluster case
the feature exists for**, and the conformance fixture could not see it because the fixture has no
touched files at all. Fixed: each source now has its own slot budget, 30 and 10, so the pack's
context cost does not grow because a second source arrived. Cluster 2 now carries its five.

**What only reader B found:** backticks in the new SQL comment sat inside a double-quoted string,
so bash executed `touches`, `declares` and `skills/task-context` as commands on every pack build.
Reproduced, removed. And that `skills/task-context` steps 5-6 still read `touches` alone, keeping
the blindness for the query that feeds `tier-classify` — filed as
`T-20260919-blast-radius-for-tier-classify-still-rea` rather than folded in, because changing what
feeds the tier decision is a behaviour change to the control that governs every other control.

**What both found:** the per-path forking, the stderr-only refusal, and the `tr` handling of
`git ls-files -z`. All three fixed. The refusal now records to `meta` and `kit-status.sh` reports
it, mirroring `tier_rules_refused` — the sibling whose recording half had been left behind when its
refusing half was copied. `read -d ''` replaces `tr`, so a path containing a newline arrives whole.

**The over-match is now stated rather than inherited.** SQLite GLOB's `*` crosses `/`, so
`src/*.go` matches `src/deep/nested.go`. The tier floor accepts that because a floor only raises;
a declaration is not conservative in that direction. Accepted deliberately — narrowing it means a
second matcher — and pinned by a conformance arm so it is known rather than discovered.

**And the arm written to pin it failed the moment it existed, on a defect of mine nobody had
found.** `for _dg in $_dpaths` is unquoted to word-split, and an unquoted expansion also
PATHNAME-expands: the shell globbed every declared pattern against the working directory before
SQLite saw it, and shell `*` does not cross `/`. `src/*.go` arrived as `src/alpha.go`. I had
written a comment warning that shell globbing would be wrong for exactly this reason, then walked
into it. `set -f` fixes it. **Every count taken before that arm existed was measured against
shell-expanded paths.** Re-derived after: 438 edges, 59 of 497 unmatched, 109 declared-untouched
tasks, 9 of 19 to 17 of 19 clusters — unchanged, because this repository's declared paths are
almost all literal, so the broken path was never exercised here. Latent, real, and found only by
the arm.

**Figures corrected:** 494 to 496 (the same commit had widened this task's own `paths:`, so the
number went stale inside the commit that wrote it), and 109 to 108, which both readers measured
independently and I had not.

### Rung 5, round two — one REVISE, one REJECT, and the numbers stale a third time

Re-run against a clean tree, which both readers confirmed stayed clean. That was the process
failure from round one and it did not recur.

**The REJECT found a major neither earlier reader had: a temp-file leak I introduced.** The EXIT
trap names `$DECL_OUT` unconditionally, but `DECL_OUT` is assigned only inside
`if [ "$HAVE_TASKS" = 1 ]`. Under `set -u` an unset variable makes the WHOLE trap fail before it
runs, so on a repository with **no task files** -- which this script elsewhere calls a legitimate
state by definition -- every temp file leaked, not just that one. Reproduced on a fresh `kit-init`
repo. `KIT_SEEN=""` sits on the same initialisation line for exactly this reason; the analogy was
one token away and I did not copy it. Fixed, and the reason is now written beside it.

**The REVISE found that I violated my own principle three lines from where I wrote it.**
`while IFS="$(printf '	')" read ...` is a command substitution in a loop header, so it forks a
subshell per iteration -- about 190 -- under a comment that says *"NO SUBPROCESS PER PATH"*.
Measured by the reader at ~7.3s of a ~21s rebuild. Hoisted.

**My cost claim was wrong, and wrong in a way worth naming.** I reported ~20s against ~12.7s, about
60%. **The 12.7s was the previous round's reader's number, not mine** -- I compared my measurement
to someone else's, taken on a different machine state, which is the same defect as carrying a
figure forward from an earlier document. Measured properly, back to back in a worktree on this
machine: `main` 16.5s and 15.5s, this branch **15.2s and 15.2s**. The regression is gone. It is
still not a CI measurement, and this repository's own agreement says that is where cost claims
belong, because this machine's process-spawn cost is a documented local artefact.

**Also fixed:** `kit_declared` gained `PRIMARY KEY(task, glob)` and `INSERT OR IGNORE`, so a task
repeating a glob can no longer inflate the two counters AC5 asks a reader to trust; the window
`ORDER BY` now ranks each bucket on the count that defines it, instead of ranking both on a
combined total the display never shows; and the schema comment no longer offers its grep as an
authoritative list of all seven relations when it finds four -- the other three are written
elsewhere or not at all, and it now says which.

**Numbers stale a THIRD time, from a third cause.** 437/496/108 became 438/497/109 because the
commit that recorded them added a task file which itself declares a path. The first drift was this
task widening its own `paths:`; the second was the same shape; this one was a spin-off task filed
in the same commit. Corrected, and the lesson is the one already written into `kit-index.sh` and
`kit-lib.sh` this session: **do not write a live count into prose at all.** These figures survive
here only because a closing measurement has to say something; the command that answers each is
`kit-status.sh`.

**Deliberately not done, with reasons.** Over-match is pinned by an arm and a comment but not
counted in `meta` -- the reader is right that this applies the "a count nothing reads" principle
unevenly, and counting it means computing match depth per glob, which is a mechanism rather than a
report; deferred rather than smuggled in. The unchecked exit status of `git ls-files` matches the
file's existing convention for its other git readers, which the REJECT confirmed, so changing it
here alone would make one reader louder than its siblings for no stated reason. The clustering gap
the REVISE found is filed as
`T-20260919-cluster-assignment-is-touches-only-so-a`.

## Notes

Found 2026-08-17 pre-flighting the cluster-pack ROI experiment
(`docs/EXPERIMENTS/2026-08-17-cluster-pack-roi.md` §2(a)).

**Without this, that experiment has no population.** 58 of 77 open tasks can never receive a pack
carrying any file information, so an arm drawn from them measures nothing about the file list at
all. It is the reason route R1 in that document is restricted to cluster 1.

Verified before filing at the operator's request; this one survived checking unchanged, other
than the glob caveat above, which was missing from the first statement of it.

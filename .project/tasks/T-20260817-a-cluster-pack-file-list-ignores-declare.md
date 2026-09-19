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
17 of 19.** 109 tasks had declared paths and no `touches` edge, so the pack told them nothing.

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
direction. The count is recorded in `meta` AND reported by `kit-status.sh` (59 of 494 today),
because a count nothing reads is the defect
`T-20260808-cluster-packs-are-generated-and-read-by-` names one file over. It is a notice, not a
warning: a glob may legitimately be declared before the file is written.

**Three defects of my own on the way, none caught by me.** A regex written with real control
characters instead of escapes; an apostrophe inside a comment in a single-quoted awk program, which
is `T-20260808-an-apostrophe-in-a-comment-inside-an-awk`; and an untyped array element reaching
`split`, which aborts gawk 5.4.1 on the SECOND task file after the first has emitted. The ingest
guard refused to rebuild every time -- without it the third would have left a half-built index
reported as a whole one.

## Notes

Found 2026-08-17 pre-flighting the cluster-pack ROI experiment
(`docs/EXPERIMENTS/2026-08-17-cluster-pack-roi.md` §2(a)).

**Without this, that experiment has no population.** 58 of 77 open tasks can never receive a pack
carrying any file information, so an arm drawn from them measures nothing about the file list at
all. It is the reason route R1 in that document is restricted to cluster 1.

Verified before filing at the operator's request; this one survived checking unchanged, other
than the glob caveat above, which was missing from the first statement of it.

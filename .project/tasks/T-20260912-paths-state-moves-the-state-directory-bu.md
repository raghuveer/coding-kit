---
id: T-20260912-paths-state-moves-the-state-directory-bu
title: paths.state moves the state directory but adoption keeps its ignore and attribute rules on .project
epic: adoption
tier: T3
lang: bash
paths: tooling/kit-init.sh, tooling/kit-index.sh, tooling/kit-status.sh, tooling/kit-plan.sh, tooling/kit-lib.sh, tooling/kit-entry.sh, tooling/kit-task.sh, tooling/kit-trailers.sh, tooling/kit-charter.sh, tooling/kit-criteria.sh, tests/conformance.sh
state: created
---

## Intent

`paths.state` and `paths.tasks` are profile keys: the kit's state directory is meant to be movable,
and 17 scripts read `paths.state`. But adoption, two checks and several messages still assume
`.project`, and nothing tests any other value.

**Reproduced on 2026-09-11, twice and independently**, in fresh repositories. The steps: adopt with
`kit-init.sh`, set `paths.state: .kit` and `paths.tasks: .kit/tasks`, re-run `kit-init.sh`, file a
task, then run `kit-index.sh` and `kit-plan.sh`. The results:

- **`.kit/index.db` and `.kit/packs/` are untracked, not ignored**, so the next `git add -A` commits
  the derived database and the packs. `.gitignore` keeps `.project/index.db*` and `.project/packs/`
  (`kit-init.sh:84`, `:94`). Only the three `entry-*` lines followed the key.
- **The event log and the plan lose their attributes.** `git check-attr` reports
  `.kit/events.ndjson: merge: unspecified` and `.kit/plans/default.tsv: eol: unspecified`, because
  `.gitattributes` still carries only the `.project/…` rules (`kit-init.sh:123`, `:136-141`).
- **kit-init's checks pass silently in the broken configuration.**
  - `kit-init.sh:122` tests `grep -q 'events.ndjson'`. The old line satisfies that substring, so
    nothing new is written, and `:124` still prints *"updated .gitattributes (events.ndjson
    merge=union)"* unconditionally.
  - It also prints *".gitattributes already pins the plan to LF"*.
  - `kit-index.sh:1494` looks for the same stale literal that kit-init writes, so its LF-pin check
    passes in exactly this setup. With the plan committed under `.kit/plans`, no warning appeared
    while `eol` was unspecified.
- **`kit-init.sh` re-creates an empty `.project/tasks`** (`:12`). With `paths.tasks` set, no
  other script does; with it absent, `kit-task.sh:75` also creates the `.project/tasks` default
  (`:18`).
- **`paths.tasks` has two defaults:** `.project/tasks` in `kit-entry:167`, `kit-index:15`,
  `kit-status:73`, `kit-task:18` and `kit-trailers:23`, but `$STATE_DIR/tasks` in `kit-charter:37`
  and `kit-criteria:61`. With `paths.tasks` removed, `kit-index` indexed **0 tasks**, and warned
  only about a stale plan.

**Every hard-coded site found:**

- `kit-init.sh:12`, `:84`, `:94`, `:123` and `:136-141`
- `kit-init.sh:169` — a third `.project/tasks` default, inside the check that decides *"ADOPTION IS
  INCOMPLETE"*
- `kit-init.sh:188` — a message
- `kit-index.sh:1494-1497` — the check and its remedy text
- `kit-status.sh:893`
- `kit-plan.sh:423` — the header generated into every committed plan names `.project/index.db`
- the missing packs ignore rule

`validate.py:203` (`.project/census`) is **out of scope**: it applies only to the kit's own repository.

**Why it survived:** all 40 non-comment `paths.*` lines in `tests/conformance.sh` use the default
layout.

**Why it is not hypothetical:** the 2026-09-09 highper-gateway trial's subject already ignores
`.project` (`.gitignore:39`, an Eclipse line). Moving the state directory is the natural way around
that clash, and it is exactly the move that breaks here.

## Acceptance criteria

- [ ] `kit-init.sh` derives every rule and directory it writes from `paths.state` / `paths.tasks`,
      and adds exact-line rules for the current location. It never deletes an adopter's lines —
      consistent with its append-only writer (`kit-init.sh:109-112`) and with
      `T-20260812-kit-init-leaves-a-footprint-in-an-adopte`'s rule that pre-existing
      `.gitignore` / `.gitattributes` lines are not removed. Lines it wrote for an old location are
      reported by their exact text. kit-init records no previous location, so it finds those lines
      by matching its own rule shapes under a different prefix.
- [ ] Presence checks match exact lines, not substrings (`kit-init.sh:122`), and each confirmation
      is printed only when it is true (`:124`).
- [ ] `paths.tasks` has one default, `$STATE_DIR/tasks` — today's `kit-charter` and `kit-criteria`
      default — defined once in `kit-lib.sh`. `kit-index.sh` warns when task files exist under the
      other location instead of silently indexing zero, and a conformance check covers that
      warning.
- [ ] Every message, check and generated header that names a state path computes it from the key:
      `kit-index.sh:1494-1497`, `kit-status.sh:893`, `kit-plan.sh:423`, `kit-init.sh:169` and
      `:188`.
- [ ] Conformance adopts at the default layout, switches `paths.state` / `paths.tasks` to a
      non-default value, and re-runs `kit-init.sh` — the order in which old kit-written lines
      exist — then files a task, indexes, plans and runs status. It asserts, through
      `git check-ignore` and `git check-attr` rather than string matching, that `index.db` and the
      packs are ignored, that the event log has `merge=union`, that the plan has `eol=lf`, and
      that no `.project` directory is created. It also asserts that kit-init's output names each
      old kit-written line (`.project/index.db*` and the others) by its exact text, and that there
      is no LF-pin warning while the derived pin is present, and one after it is removed. Mutations, each of
      which must fail the step: restoring the literal `.project/index.db*`; restoring the substring
      match at `kit-init.sh:122`; and restoring the literal checked at `kit-index.sh:1494`.

## Notes

**T3 on two floors:** `kit-index.sh` (the check at `:1494`) and `kit-trailers.sh` (its `paths.tasks`
default at `:23`) are both floored at T3 in this repository's profile, and both need changing.

**Tasks that edit the same lines** — landing any of these together, or back to back, avoids
conflicts:

- `T-20260911-kit-init-prints-the-claude-remedy-when-t` (K5) comes from the same `.gitignore:39`
  collision and edits `kit-init.sh:168-222`, including the `:169` default.
- `T-20260908-kit-init-pins-less-for-an-adopter-than-t` edits the same line, `:123`.
- `T-20260812-kit-init-leaves-a-footprint-in-an-adopte` has to undo whatever this task writes.

The 20% "trailer discipline degraded" threshold (`kit-status.sh:961`) is left out on purpose. It is
unrelated to `paths.*`, and its counting was already fixed under
`T-20260801-trailer-discipline-warning-counts-commit`.

Reviewed before filing by an independent reviewer, who reproduced the results listed under
*Reproduced*; the list of hard-coded sites comes from grep. Found while
validating the operator's question, after the highper-gateway trial, about how much of the kit is
hard-coded. Filed before any fix.

---
id: T-20260912-a-fix-commit-can-weaken-an-existing-test
title: A fix commit can weaken an existing test after a review and nothing reports it
epic: validation
tier: T3
lang: bash
paths: tooling/kit-index.sh, tooling/schema.sql, tooling/kit-status.sh, templates/project-profile.md, tests/conformance.sh
state: created
---

## Intent

When a review finds a defect, the fix lands in later commits on the same task. A fix *should* add a
regression test — `verify-ladder` rung 2 asks for exactly that, and
`T-20260815-four-of-five-review-fixes-have-no-assert` records what happens when it doesn't. **What
nothing notices is the other case: a fix that removes or changes lines in an existing test.** That
is how a check that caught something stops being able to fail.

**What the index can and cannot answer today.**

- The `edge` table records task-to-file links only — `(src, dst, rel)`, with no commit and no time
  (`schema.sql:86-90`).
- Commits appear as `tiered` events carrying a hash and a time (`kit-index.sh:599-615`), but the
  files each commit touched are never stored.
- `kit-status.sh` makes no git calls.
- The profile has `commands.test`, but no key that names test paths
  (`templates/project-profile.md:62`).

**This task takes the indexer route.** `kit-index.sh` records the test files each commit changed,
and `kit-status.sh` reports from the index as it does for everything else. That puts the task at
the T3 floor of `kit-index.sh`.

**The playbook's version, and the kit's.** Anthropic's AI-native SDLC playbook
(claude.com/blog/the-ai-native-sdlc-playbook) uses *"a hook that blocks edits to test files during a
fix task"*. A hook is per agent, but the evidence lives in git, which every agent writes to. So the
kit's first step is to **report, not block**, following the operator's guidance of 2026-09-11 that
playbook practices are adopted on merit. Blocking is worth considering only if the report shows it
happens.

## Acceptance criteria

- [ ] The profile can declare which paths are tests, with a repeatable glob key. When the key is
      unset, the report says it is undeclared rather than reporting zero.
- [ ] `kit-index.sh` records, for each commit carrying a `Task-Id`:
      - its **committer date** (`%cd`), in the same explicit UTC format as the author date it
        already stores (`kit-index.sh:505-507` stores `%ad`);
      - for each declared test file the commit changed, the **deleted-line count** from `--numstat`.

      Both come from the single log walk the indexer already makes (`kit-index.sh:505`), never from
      one git call per commit. The cost of a call per commit is recorded in
      `T-20260822-process-creation-costs-one-second-on-the` and
      `T-20260821-the-fixed-commit-walk-spawns-one-git-per`.
- [ ] `kit-status.sh` lists, per task, each commit whose **committer date** is after the `at` of
      the task's first recorded finding, and whose **deleted-line count is greater than zero** in a
      declared test file. (`--numstat` has no "modified" count: a changed line shows as one deletion
      and one addition.) The listing shows the commit and the files. It reports; it does not judge
      whether the edit weakened anything.
- [ ] Conformance, using a fixture task with one finding:
      - a later commit that deletes a line from a declared test file is listed;
      - a later commit that only adds a new test is **not** listed;
      - a later commit touching only non-test files is not listed;
      - with the key unset, the report says "undeclared".
- [ ] Mutation proofs:
      - dropping the date comparison lists commits made before the finding, and the step fails;
      - counting additions as well as deletions lists the add-only fix, and the step fails.

## Notes

**Tier T3:** the floor of `kit-index.sh`, which has to store data it does not hold today.

**Portable core:** it reads only git history, the finding log and a profile key.

It complements `T-20260815-four-of-five-review-fixes-have-no-assert` (fixes that added no assertion)
and `T-20260809-a-claim-audit-before-a-task-closes-names` (naming the test that would fail) from the
other side.

Source: the operator's review of Anthropic's playbook, 2026-09-11. This is the measurement-first
form of the playbook's hook. Filed before any fix.

---
id: T-20260809-the-unverified-tier-floor-message-names-
title: The unverified tier floor message names a cause that is not the usual one
epic: measurement
tier: T2
lang: bash
paths: tooling/kit-status.sh
state: open
---

## Intent

Found by running the kit against a real repository it had never seen —
`highperapp/highper-gateway`, 169 commits, 967 files, adopted from scratch with a seven-task
backlog built from its own roadmap. The report said:

    > **Tier floors unverified for 7 of 7 open task(s).** No declared `paths:` and no
    > files touched yet, so no floor could be computed — not that none applies.

**All seven tasks declared `paths:`.** Verified: every task file carries a real, existing path,
and the index holds them. The floors were NULL for a different reason entirely — the profile
that `kit-init.sh` generates ships every `tier.rule` line COMMENTED OUT:

    tier.default: T1
    # tier.rule: src/auth/** T3
    # tier.rule: migrations/** T3

No rules, so nothing to match the declared paths against, so no floor. The message asserts a
cause the reader can check and find false, on the FIRST run after adoption — which is when a
new adopter is deciding whether to trust the tool.

## Why this shape matters here

`kit-status.sh` already knows this failure mode and guards against it twenty lines further down,
for the refused-rule case:

> the message above claims the benign one — "nothing to go on" — about a task that declared its
> paths and had them judged by a rule that was thrown away

That guard was added because a benign cause must not stand in for a real one. There are three
causes and the message covers one:

1. no `paths:` declared and no files touched — the stated cause, benign
2. rules were REFUSED by the indexer — already covered by its own line
3. **no `tier.rule` is declared at all** — not covered, and it is the DEFAULT state of every
   freshly adopted repository

## Acceptance criteria

- [ ] The message distinguishes "nothing to judge with" from "nothing to judge". A repository
      with no active `tier.rule` gets told that, and told that `tier.default` is doing all the
      work — not that its tasks failed to declare paths they did declare.
- [ ] The count is still honest in the mixed case: some tasks with paths, some without, and
      rules present. Do not trade one wrong single-cause message for another.
- [ ] A conformance case covers the fresh-adoption arrangement: `kit-init.sh` profile as
      generated, tasks WITH `paths:`, and an assertion that the report does not claim they have
      none. Nothing exercises this today, which is why it survived to a real repository.
- [ ] Check whether `kit-init.sh` should ship a starter `tier.rule` rather than only commented
      examples. An adopter who never uncomments them gets `tier.default` for everything and no
      floor check at all — which is a silent loss of the control, not just a confusing message.

## Notes

The dry run that found it was read-only on a throwaway clone; nothing was written to the real
repository. The same run also confirmed the parts that work: topological layering was correct
against the roadmap's real dependencies, clustering grouped tasks by shared file and epic, and
co-change on 169 commits produced a correct blast radius for the DSL subsystem with no
configuration at all.

**2026-09-11 — hit again, on the same subject, through a cause this task does not list.** The
highper-gateway plugin-mode trial declared **12** `tier.rule` lines, and its one task declared
`paths: highper-gateway/src/discovery/registry.rs`. No rule matches `discovery/**`, so no floor
applies. The report still said *"No declared `paths:` and no files touched yet"* — about a task that
had declared its path, and whose path a commit had touched.

The same mechanism is behind this and cause 3: `floorof()` (`kit-index.sh:377-378`) starts with
`best = ""`, returns it when nothing matches, and that is stored as the same NULL as "no paths
declared". **A fix for cause 3 alone (no rules at all) would miss this case** — here the rules exist;
they just do not cover the path. Evidence: `kit-status.txt`, and the task file beside it, in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode/`.

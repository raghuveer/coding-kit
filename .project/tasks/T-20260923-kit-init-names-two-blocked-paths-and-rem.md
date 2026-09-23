---
id: T-20260923-kit-init-names-two-blocked-paths-and-rem
title: kit-init names two blocked paths and remedies one
tier: T2
lang: bash
state: created
---

## Intent

Adopting the trial-3 copy, `kit-init.sh` exited 1 and printed:

    .claude/project-profile.md      excluded by  .gitignore:158:*.claude
    .project/tasks                  excluded by  .gitignore:39:.project

and then one remedy, for `.claude/` only:

    !.claude/
    .claude/*
    !.claude/project-profile.md

An adopter who pastes what is printed fixes half the problem and re-runs into the same exit 1,
now with one path listed. The message names both and remedies one.

**This is K5 of the 2026-09-09 trial**, recorded then as *"`kit-init.sh`'s ignore remedy prints
the `.claude/` idiom even when the blocked path is `.project/`"*, with the line numbers
`kit-init.sh:208-220` hard-coded to `.claude/`. It reproduced unchanged on 2026-09-23, on a
different subject, fourteen days later.

The subject ignores `.claude` four separate ways — `.claude/`, `**/.claude/`, `.claude-*`,
`*.claude` — which is worth keeping in mind for any fix that reasons about a single rule.

## Acceptance criteria

- [ ] Every path the message names gets its own remedy block, with the directory re-included
      first, using that path's own state directory name rather than a literal `.project`.
- [ ] Verified on a repository that blocks BOTH paths, which is the case that has now occurred
      twice and is not hypothetical.
- [ ] The remedy is derived from `paths.state` and `paths.tasks`, so an adopter who moved their
      state directory gets a remedy naming where it actually is.
- [ ] A test that fails against today's `kit-init.sh`.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K5.
2026-09-09 record: `docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`, K5.

A finding that survives a second trial unchanged is worth more than its tier suggests: the
re-occurrence is the evidence that the first filing did not reach anyone.

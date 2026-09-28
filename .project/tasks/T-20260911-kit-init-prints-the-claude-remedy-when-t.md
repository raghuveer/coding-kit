---
id: T-20260911-kit-init-prints-the-claude-remedy-when-t
title: kit-init prints the .claude remedy when the blocked path is .project
epic: adoption
tier: T2
lang: bash
paths: tooling/kit-init.sh, tests/conformance.sh
state: created
---

## Intent

When the adopter's `.gitignore` excludes a path the team is meant to share, `kit-init.sh` refuses to
finish and prints the re-include idiom. **That idiom is hard-coded to `.claude/`**
(`kit-init.sh:208-220`), whichever path was actually blocked.

On the 2026-09-09 highper-gateway trial both paths were blocked. `.gitignore:39` is `.project` — an
Eclipse IDE line that collides with the kit's state directory by accident — and `.gitignore:158` is
`*.claude`. `kit-init.sh` named both blocked paths correctly, then printed only the `.claude/`
remedy:

    !.claude/
    .claude/*
    !.claude/project-profile.md

An adopter who applies it still has every task file and the event log ignored, and re-running
`kit-init.sh` refuses again.

## Acceptance criteria

- [ ] A remedy is printed for each blocked path and built from that path, so a blocked
      `.project/tasks` gets the `.project/` re-include form.
- [ ] A conformance step with `.project` ignored asserts that the printed remedy re-includes
      `.project/tasks/`, and that applying the printed lines verbatim lets `kit-init.sh` complete.
- [ ] The remedy is derived from `paths.state` and `paths.tasks`, so an adopter who moved their
      state directory gets a remedy naming where it actually is.
- [ ] Verified on a repository that blocks BOTH paths, and by a test that fails against today's
      `kit-init.sh`.

## Notes

**2026-09-28 — merged in from `T-20260923-kit-init-names-two-blocked-paths-and-rem`, which is now
cancelled as a duplicate.** Trial 3 (`docs/TRIALS/2026-09-20-highper-gateway.md`, K5) reproduced
this unchanged on 2026-09-23: `kit-init.sh` exited 1 naming `.claude/project-profile.md`
(`.gitignore:158:*.claude`) and `.project/tasks` (`.gitignore:39:.project`), then printed the
`.claude/` remedy only. The two criteria above came from that task; its other two restate the
first two here. This file is kept because `docs/dependency-map.tsv`, `docs/DEPENDENCIES.md` and two
task files already point at it. The subject ignores `.claude` four ways -- `.claude/`,
`**/.claude/`, `.claude-*`, `*.claude` -- so a fix that reasons about one rule will miss some.

Proposed at T1 and filed at T2, the floor `tooling/**` sets in this repository's profile.

Found in the highper-gateway plugin-mode trial, kit defect K5 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md` (trial notes, 13:37Z). Filed before any fix.

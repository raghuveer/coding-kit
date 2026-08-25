---
id: T-20260825-kit-init-cannot-share-the-profile-when-t
title: kit-init cannot share the profile when the repo already ignores .claude
epic: portability
tier: T2
paths: tooling/kit-init.sh, INSTALL.md
state: created
---

## Intent

K-1 of the highper-gateway trial, 2026-08-24. Reproduced on a real 169-commit Rust workspace,
not argued.

The subject's `.gitignore` already carried `.claude/`, `**/.claude/`, `.claude-*` and `*.claude`
— a perfectly ordinary thing for a repository to do, since most people treat `.claude` as
personal scratch. `kit-init.sh` then:

1. exits **0**,
2. prints *"commit `.claude/project-profile.md` — the team shares them"*,
3. edits `.gitignore` in the same run — without noticing that existing patterns exclude the one
   file the kit depends on.

`git add .claude/project-profile.md` is **refused**. So the adopter follows the printed
instruction, it fails, and the kit has already told them adoption succeeded.

**Greenfield cannot surface this**, which is why it survived. An empty repository has no
`.gitignore` to conflict with. It appears the moment the kit meets a repository that has been
lived in — which is the entire brownfield case.

**The consequence is the thing another task exists to prevent.** A second developer cloning that
repository gets no profile, so the kit is inert for them and silently so — exactly what
`T-20260811-team-mode-bootstrap-so-a-second-develope` is about. This is that failure arriving
through a different door, and arriving on day one rather than on day two.

## Acceptance criteria

- [ ] `kit-init.sh` **detects** that the profile path is ignored before it claims success. The
      check is `git check-ignore -q <path>`, which is the authority — pattern-matching
      `.gitignore` by hand would reproduce git's precedence rules badly and is how this class of
      bug gets a second life.
- [ ] When it is ignored, the run says so **loudly and specifically**, naming the file and the
      fact that the printed "commit this" instruction will fail. A warning that says "check your
      gitignore" is not this criterion.
- [ ] The negation is offered rather than applied silently: `kit-init.sh` already edits
      `.gitignore`, so adding a `!.claude/project-profile.md` negation is within what it does —
      but **an un-negatable case must still be reported rather than half-fixed.** Git cannot
      re-include a file if a parent *directory* is excluded, so `.claude/` requires negating the
      directory too, and a naive negation line will look correct and do nothing.
- [ ] Whatever it does, the exit status reflects it. Exiting 0 while the stated next step cannot
      be performed is the defect, and it is not fixed by better wording alone.
- [ ] `INSTALL.md` covers the case, because an adopter reading the docs before running anything
      should not have to discover it from a failed `git add`.
- [ ] Mutation proof: a fixture repo whose `.gitignore` carries `.claude/` fails the check, and
      removing the check makes it pass.

## Notes

**Do not widen this into "the kit should own .gitignore".** It touches that file already and the
scope here is one file it needs tracked. A task that grows into managing an adopter's ignore
rules is a task about somebody else's repository.

The un-negatable case deserves stating plainly in the fix rather than being discovered later: if
a parent directory is excluded, git will not re-include a file beneath it, so `.claude/` and
`**/.claude/` cannot be undone by negating the file alone. That is a git rule, not a kit
limitation, and the honest output is to say the profile cannot be tracked here and name what the
adopter must change.

Reproduced 2026-08-24 during the highper-gateway trial; see
`docs/TRIALS/2026-08-24-highper-gateway.md` K-1.

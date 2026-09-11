---
id: T-20260911-kit-init-next-steps-omit-choosing-git-ad
title: kit-init next steps omit choosing git.adopted_at on a brownfield repo
epic: adoption
tier: T2
lang: bash
paths: tooling/kit-init.sh, INSTALL.md, tests/conformance.sh
state: created
---

## Intent

`INSTALL.md:155` makes choosing `git.adopted_at` the first step of a brownfield adoption, because the
choice decides what the kit believes about all earlier history. `kit-init.sh` never mentions it. Its
printed next steps (`kit-init.sh:185-194`) are: fill in `commands.*` and `tier.rule`, append
`CLAUDE.kit.md`, commit the profile and the tasks, delete any hand-maintained STATUS, and copy the
CI trailer gate.

On the 2026-09-09 highper-gateway trial the session followed that printed order and left the key
unset. The first status then said *"Trailer discipline degraded. 97 of 98 non-trivial commits carry
no Task-Id"*. That is the reading `INSTALL.md:158-160` predicts for the unset case: *"the
trailer-discipline warning reads as though the team is ignoring the rule"*. The documented step
exists; the command that starts adoption never leads to it.

Leaving it unset is a legitimate choice — it buys `touches` edges and co-change over the full
history. The defect is that the choice is made by default rather than by the adopter.

## Acceptance criteria

- [ ] On a repository with history, `kit-init.sh`'s next steps name `git.adopted_at`, both choices
      and what each costs — or point at `INSTALL.md`'s section by name.
- [ ] An empty repository is not told to choose one.
- [ ] A conformance step asserts that the line appears after `kit-init.sh` on a fixture with commits,
      and does not appear on a fixture without.

## Notes

Proposed at T1 and filed at T2, the floor `tooling/**` sets in this repository's profile.

Found in the highper-gateway plugin-mode trial, kit defect K6 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

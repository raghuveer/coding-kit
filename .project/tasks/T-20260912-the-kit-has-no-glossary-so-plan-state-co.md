---
id: T-20260912-the-kit-has-no-glossary-so-plan-state-co
title: The kit has no glossary so plan state context sandbox and hooks each carry two meanings
epic: components
tier: T1
lang: markdown
paths: docs/GLOSSARY.md, README.md, docs/DESIGN-NOTES.md, INSTALL.md, docs/TRIAL-PROTOCOL.md, docs/HANDOFF.md, docs/ADAPTERS.md, templates/CLAUDE.kit.md, validate.py
state: created
---

## Intent

The kit defines a term only when a clash gets noticed:

- "Overlay" was fixed inline in `DESIGN-NOTES.md:145` on 2026-08-14.
- "Plan" is stated by ADR 0004 and `HANDOFF.md:174`.

**There is no glossary.** On 2026-09-11, a single day's work found five words carrying more than
one meaning:

- **plan** — the kit's committed ordering of the backlog (`.project/plans/<goal>.tsv`, ADR 0004),
  versus a per-task implementation plan (the playbook's `plan.md`, or Claude Code's plan mode),
  which the kit does not produce.
- **state** — a task's lifecycle state (ADR 0008), versus the kit's state directory
  (`paths.state`), versus a session's state (checkpoints).
- **context** — an agent's context window, versus the `task-context` skill, versus a cluster pack.
- **sandbox** — Claude Code's sandboxed Bash tool, versus any OS-level boundary around an agent
  session (the agent-neutral sense).
- **hooks** — a coding agent's lifecycle hooks (`hooks/hooks.json`), versus the kit's git hooks
  (`commit-msg`, `pre-push`), which belong to the portable core.

"Parked" is also the operator's word for the state `on-hold`.

**Operator direction, 2026-09-11:** *"let us correct terminology where it is deemed fit"*.

## Acceptance criteria

- [ ] One glossary. The README links to it. It defines each term once, and names the file or ADR
      that owns the term.
- [ ] Each clash is resolved, within set limits:
      - One meaning keeps the bare word; the others get a qualified name.
      - Those names are used in the **prose of living documents**, starting with `README.md`,
        `INSTALL.md`, `docs/DESIGN-NOTES.md`, `docs/TRIAL-PROTOCOL.md`, `docs/HANDOFF.md`,
        `docs/ADAPTERS.md` and `templates/CLAUDE.kit.md`.
      - Identifiers stay unchanged — for example the profile key `paths.state` and the skill name
        `task-context` — because renaming them would break every adopter.
      - Historical records stay unchanged: ADRs, trial records, design inputs and task files.
- [ ] Only the **adapter sense** of a word is marked as adapter vocabulary. The agent-neutral sense
      of "sandbox" and the git sense of "hooks" are core.
- [ ] A check that can fail: `validate.py` fails when a glossary entry names an owning file that
      does not exist, or when the README does not link to the glossary.

## Notes

**Tier T1:** docs, plus one small check in `validate.py`.

The state-and-context design task, filed alongside this one, uses these terms.

Filed at the operator's direction of 2026-09-11, before any fix.

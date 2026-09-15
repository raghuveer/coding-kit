---
id: T-20260914-entry-proposal-step-2-names-a-researcher
title: Entry proposal step 2 names a researcher agent that adoption never installs
epic: validation
tier: T1
lang: markdown
paths: docs/ENTRY-PROPOSAL.md, tooling/kit-init.sh
state: created
---

## Intent

`docs/ENTRY-PROPOSAL.md` step 2 says a `researcher` subagent is given the report and the TSVs and
**returns** the proposal text. That is the judgement half of the entry mechanism; ADR 0001 split
facts from judgement precisely so that a reader can tell them apart.

**The agent is not reachable from an adopted project.** Measured 2026-09-14, executing the trial-2
entry unit on `highper-gateway`:

- the kit ships it at `agents/researcher.md`, a **kit-owned** directory
- since 0.2.0 the kit is distributed as a **plugin**, and `docs/agents-README.md` says plugin agent
  discovery is flat under `agents/`. So the agent exists only where that plugin is installed in the
  harness. The per-project `sync-agents.ps1` step that used to write `.claude/agents/` was retired
  and is explicitly **not wired up**.
- `grep -n agents tooling/kit-init.sh` returns **nothing**. Adoption installs no agent anywhere.
- on this subject `.gitignore` excludes `.claude` six ways, so a project-level copy is impossible
  even by hand.
- in the session that ran the trial, the available agent types were
  `claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup`. **No `researcher`,
  no `coder`, no reviewer.**

So the orchestrator produced the judgement itself. That is not a neutral substitution: the whole
value of the split is that the census and the reading of the census have different authors, and a
single author collapses it. It is recorded as a deviation at the top of the proposal, which is the
weakest possible control.

**Portability is the general form.** The operator's stated goal is that the kit support many coding
agents. A procedure step that resolves only inside one harness's plugin loader is the exact shape
that does not port.

## Acceptance criteria

- [ ] `docs/ENTRY-PROPOSAL.md` step 2 states what happens when no such agent is available, rather
      than naming one as though it were always there.
- [ ] Either adoption installs the agents somewhere the harness reads, or the document stops
      assuming it. A third answer -- the step is performed by whatever the operator has -- is fine,
      and is the portable one, but it has to be written down.
- [ ] A check that can fail: something reports whether the named agent resolves, before the
      procedure depends on it. Today the failure surfaces as an orchestrator quietly doing the work
      itself.

## Notes

Filed 2026-09-14 from trial 2's entry unit, `docs/TRIALS/2026-09-14-highper-gateway.md`. Found by
trying to run the documented step, not by reading the document -- the document reads correctly.

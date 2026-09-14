---
id: T-20260914-kit-agents-are-portable-prompts-behind-a
title: Kit agents are portable prompts behind a plugin-only distribution route
epic: portability
tier: T2
lang: markdown
paths: docs/agents-README.md, tooling/kit-init.sh, docs/ENTRY-PROPOSAL.md
state: created
---

## Intent


## Acceptance criteria

- [ ] 
- [ ] 

## Notes

## Intent

`T-20260914-entry-proposal-step-2-names-a-researcher` established that the kit's agents are
unreachable from an adopted project: `kit-init.sh` installs none, the per-project
`sync-agents.ps1` was retired in 0.2.0 and left unwired, and the plugin manifest is therefore the
only route. That task treats the consequence. **This one treats the cause, and it is narrower than
it looked.**

**Measured 2026-09-14, trial 2 unit 2.** A **generic** agent type — one the harness offers with no
kit plugin loaded — was pointed at `agents/claim-auditor.md` and told to follow it. It read the
prompt, obeyed the output contract, and returned a twelve-claim audit in the contract's JSON shape
with a per-claim verdict vocabulary it was never given inline. It found three real defects in the
document it audited, including a self-contradiction that had survived authoring, re-reading and a
`--check` run. 83k tokens, 23 tool calls, 5m14s.

**So the agent files are portable and their distribution is not.** Nothing in
`agents/claim-auditor.md` depends on the plugin loader; it is a prompt plus a tools line. What does
not port is the single mechanism that currently puts it in front of a model.

That reframes the operator's stated goal — *support many coding agents* — from a rewrite into a
packaging question. A harness that can run a subagent with a prompt can run all nine today.

## Acceptance criteria

- [ ] The kit has **at least one route** that puts an agent prompt in front of a model without a
      Claude Code plugin install. What the route is — `kit-init.sh` copying into a configured
      directory, a documented "paste this prompt" path, an export command — is the decision to make;
      having none is what this task closes.
- [ ] `docs/agents-README.md` states which parts of an agent file are portable and which are
      harness-specific. Today the `tools:` frontmatter line names Claude Code tool names and nothing
      says so; the auditor had to be told to ignore it.
- [ ] A check that can fail: something reports whether the agents are reachable in the current
      environment. The trial found this by trying, which is the expensive way.
- [ ] The `model:` frontmatter is covered by the adopter-configurable model work rather than
      duplicated here — a portable prompt that hardcodes `opus` is portable to one vendor.

## Notes

Filed 2026-09-14 from trial 2 unit 2, `docs/TRIALS/2026-09-14-highper-gateway.md`. **This is the
first evidence in either trial bearing on portability, and it is favourable** — worth recording
because the pre-flight and unit 1 produced only costs.

**Deliberately not proposed here:** whether the kit should ship a non-Claude-Code adapter. That is
a bigger decision than this task, and the evidence only supports the smaller claim — that the
prompts themselves are not the obstacle.

---
id: T-20260811-agent-behaviour-has-no-eval-only-mechani
title: Agent behaviour has no eval only mechanics
epic: validation
tier: T2
lang: bash
paths: tests, agents
state: open
---

## Intent

The kit's core claim is that it improves quality without context rot. Conformance proves the
**mechanics** — 34 steps covering the indexer, trailers, spend, findings, provenance, the
report. Nothing measures whether an agent *fired when it should have*, *stayed in scope*, or
*produced the evidence its own prompt requires*.

That gap is not theoretical. On 2026-08-11 a live reviewer, under a system prompt telling it in
capitals to return one JSON object and no fence, first called an unrelated reporting tool and
returned prose, then returned correct JSON wrapped in a fence. Both were behaviour failures
against an explicit contract, and both were invisible to every existing test. They were found by
running the agent, which nothing does automatically.

## The change

A behavioural eval: a handful of scenarios per agent, run separately from the conformance suite
because they need a model and conformance must stay deterministic and offline.

Per scenario, three questions: did it fire, did it stay in scope, did it produce the evidence
its prompt requires. The findings contract makes the third one checkable — a reviewer's output
either validates or does not.

**Extend what exists; do not build a parallel harness.** `--only` already makes single-scenario
runs cheap, and `kit_findings.py` already validates reviewer output. The new part is the
scenario set and a runner that tolerates non-determinism without becoming meaningless.

**Record which model served each run.** Otherwise a change behind the endpoint looks exactly
like a kit regression, and the eval starts producing false alarms nobody trusts.

## Acceptance criteria

- [ ] A prompt edit that degrades an agent is caught before it is committed. Prove it: degrade
      one deliberately and watch the eval go red.
- [ ] Scenarios assert behaviour, not phrasing. A reworded but equivalent reply passes.
- [ ] The run records which model answered, and a report from one model is never silently
      compared against another.
- [ ] Non-determinism is handled explicitly — a stated pass rule, not a single sample treated
      as truth.
- [ ] It does not run in the conformance job. CI's determinism is not traded away for this.

## Notes

Filed 2026-08-11 from R-09, **scoped to an extension** rather than the new harness the register
described, because the register was written without knowing conformance existed.

Distinct from `T-20260808-co-change-has-no-eval-harness-so-its-sco`, which evaluates co-change
*scoring*. Both are wanted; neither replaces the other.

**2026-09-11 — the same failure at 3 of 3, from the highper-gateway plugin-mode trial.** All three
`coding-kit:implementation-reviewer` replies came back wrapped in a ` ```json ` fence, which
`agents/implementation-reviewer.md:61` forbids. **0 of 3 complied**, and the third came back fenced
even after an in-prompt reminder in capitals (`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode/`,
under `reviews/` and in the trial notes at 14:06:06Z).

All three still landed, because `kit_findings.py:184-195` deliberately strips one fence. That
tolerance is right for the recorder, and it also hides the violation from every current report.
There are two ways to make it visible:

- the recorder could count the fences it strips, since `unfence()` already knows whether it matched
  — a small change in the portable core;
- an eval could check the raw replies, which is what this task proposes.

**Model:** the three subagent spend rows the hooks wrote for these reviewers (agent ids
`ac7e0037f040926ff`, `aef898e5643e9c10b` and `a2e86f9d43dfeaf7b` in `events.ndjson`) are all
`claude-sonnet-5`. That is n = 3 replies,
from one agent in one session.

A proposal, not a change to this task: the reply contract and the scenarios' pass rules are portable
core, while the agent files under test are adapter content
(`T-20260819-the-claude-adapter-is-16-files-but-nothi`).

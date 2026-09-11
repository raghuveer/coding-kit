---
id: T-20260911-a-finding-recorded-by-hand-carries-no-ag
title: A finding recorded by hand carries no agent id so it cannot be joined to its reviewer spend
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-finding.sh, skills/verify-ladder/SKILL.md, tests/conformance.sh
state: created
---

## Intent

A finding recorded through the reply-in-hand door cannot be joined to the spend row of the reviewer
that produced it. So "what did this reviewer cost?" and "what did it find?" cannot be answered for
the same run.

On the 2026-09-09 highper-gateway trial all **11 of 11** finding rows carry `agent_id: ""`, while
all **3 of 3** reviewer spend rows carry theirs (`agent-ac7e0037f040926ff` and two more). The
session recorded every reply with the command `skills/verify-ladder/SKILL.md:73-75` gives:

    bash ${CLAUDE_PLUGIN_ROOT}/tooling/kit-finding.sh --task <task-id> --agent <agent> --json < reviewer-reply.json

**`kit-finding.sh` accepts `--agent-id`** (`:69`) and carries it into the event. But neither its
usage header (`:4-6`) nor the skill's command mentions it, so an agent following either never passes
it. The trial session read the header and concluded the flag did not exist — the wrong conclusion,
and the one the header invites.

Only `kit-review-record.sh` passes the id, and in plugin mode that path has no caller shape for the
plugin's own Agent-tool reviewers (`T-20260801-nothing-invokes-kit-finding-so-the-findi`).

## Acceptance criteria

- [ ] `kit-finding.sh`'s usage header and `skills/verify-ladder/SKILL.md`'s reply-in-hand command
      both carry `--agent-id`, and the skill says where the agent gets the value in plugin mode.
- [ ] A finding recorded without an agent id is reported as unjoinable — by `kit-status.sh` or at
      record time — rather than stored as if the join were possible. An empty string that looks
      like a value is the failure.
- [ ] A conformance step records a finding through the documented door with an id and asserts that
      the finding and spend rows join on it. The same step without the id asserts that the
      unjoinable report fires.

## Notes

Adjacent: `T-20260808-record-which-mechanism-produced-a-findin` records *which mechanism* produced a
finding; this task is about *which run*. Judging the second reviewer needs both.

Found in the highper-gateway plugin-mode trial, kit defect K2 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

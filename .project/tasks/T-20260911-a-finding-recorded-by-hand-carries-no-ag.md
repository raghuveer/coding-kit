---
id: T-20260911-a-finding-recorded-by-hand-carries-no-ag
title: A finding recorded by hand carries no agent id so it cannot be joined to its reviewer spend
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-finding.sh, skills/verify-ladder/SKILL.md, tests/conformance.sh
state: completed
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

### Evidence, 2026-09-14 — proposed, not certified

**The boxes above are deliberately unticked.** A session certifying its own output is the
signature that carries no information, and ADR 0010 makes the transition the operator's. This
records what to check, per criterion, so ticking is a read rather than a re-derivation.

Delivered by PR #115, merged as `d710e08`.

| AC | state | where to verify |
|---|---|---|
| 1 — both doors carry `--agent-id`, and the skill says where the value comes from in plugin mode | **met** | `tooling/kit-finding.sh:4-8`; `skills/verify-ladder/SKILL.md` reply-in-hand block, which names the Agent-tool subagent id and the `<session>/subagents/agent-<id>.jsonl` file `kit-spend.sh` reads it from |
| 2 — a finding with no id is reported as unjoinable rather than stored as if the join were possible | **met** | `kit-status.sh` prints two counts. On this repository: `580 of 628 carry no agent id, and 48 carry one that matches no spend row` |
| 3 — a conformance step records through the documented door with an id and asserts the join; without it, asserts the report fires | **met, 2026-09-14** | now records through `kit-review-record.sh --reply-file`, the door `skills/verify-ladder/SKILL.md` names and the one all 11 of the trial's findings used. Mutation-proven: blank the door's `--agent-id` pass-through and arm 1 goes red |

**The finding this work produced, and it is not in the criteria above:** `finding` had no
`agent_id` column at all. `kit_findings.py` has written the key into the event since it was
added — 550 of 628 events here carry it — and the indexer had nowhere to store it, so supplying
the flag would not have helped. The task read this as a documentation gap, which was half of it.

**Still zero joinable after all of it**, for a reason that is a third layer and its own task:
`T-20260914-finding-run-ids-and-spend-run-ids-are-tw`.

**AC3 closed 2026-09-14.** It was recorded as PARTIAL when #115 landed, because the step
exercised `kit-finding.sh` directly while the documented door is `kit-review-record.sh`. That
distinction is the whole of this task: the defect was that *the documented door* omitted the
flag, so a test going through a different door proves the plumbing and cannot catch that class
at all. The step now goes through the documented one, and the mutation that blanks its
`--agent-id` pass-through takes arm 1 red.

### The join returned rows for the first time, 2026-09-20

**Every criterion above was recorded `met` on 2026-09-14, and the join had still never returned a
row.** 637 findings, 0 joinable. The mechanism was proved in a conformance fixture and nowhere
else, which is the shape this repository keeps filing against itself: a control demonstrated only
where it was built.

A reviewer was run as an Agent-tool subagent against a real change — the multi-awk conformance step
— and its six findings were recorded through the documented door with `--agent-id` carrying the
harness subagent id the spend hook had written. Re-derived from a rebuilt index:

| | before | after |
|---|---|---|
| findings total | 637 | 643 |
| no agent id | 582 | 582 |
| id matching no spend row | 55 | 55 |
| **joinable** | **0** | **6** |

**What the join now answers, for one run, which nothing in this repository could answer before:**

    agent            general-purpose      model   claude-opus-5
    turns    36      tok_in  72           tok_out 28,440
    cache_read  2,103,244                 cache_write 235,308
    found    1 major, 4 minor, 1 nit

646,731 billing-weighted input-token-equivalents (in x1 + cache-write x1.25 + cache-read x0.1 +
out x5), so **107,789 per finding**. That figure is a first measurement, not a benchmark: n=1, one
model, one reviewer, one subject.

**TWO THINGS THE EXERCISE ITSELF EXPOSED, both worth more than the number.**

**1. The naive join is a cartesian bomb, and it looks like success.** The first query run was
`finding f JOIN spend s ON f.agent_id = s.agent_id` with no guard. `''` matches `''`, so 582
id-less findings joined 35 id-less spend rows and produced 2.2MB of rows reading `critical` with
an empty summary. Any consumer that joins these tables without excluding the empty string gets
confident garbage rather than an empty result. This is AC2 of this task — *"an empty string that
looks like a value is the failure"* — demonstrated accidentally, and it argues the guard belongs in
a view or in the schema rather than in each caller's WHERE clause.

**2. Spend and findings are recorded at different moments, which is WHY the ids diverge.** The
reviewer's spend row was written by the Stop hook the instant the agent stopped, before its report
had reached the orchestrator at all. Spend is automatic and always carries the id; the finding is
recorded by whoever reads the reply and has to carry the id across by hand. That asymmetry is the
mechanical reason 55 of 55 subagent spend rows carry ids while 582 of 643 findings do not, and no
amount of documenting the flag changes it.


### CLOSED 2026-09-20 by the operator.

Closed on evidence that is now a real run rather than a fixture: six findings joined to the spend
row of the reviewer that produced them, against 0 joinable out of 637 that morning. The three
criteria were recorded `met` on 2026-09-14 and the join still returned nothing, so the close waited
on the demonstration rather than on the criteria.

**What the close does NOT claim.** 582 of 643 findings still carry no agent id and 55 carry an id
in the wrong space. Those are dispositioned, not fixed: the 582 predate the flag being documented,
and the 55 are legacy under `T-20260914-finding-run-ids-and-spend-run-ids-are-tw`. **The join works;
the backlog of rows that cannot use it is permanent.** Any future ratio computed over all findings
must say so, or it will read as a 1% success rate for a mechanism that works.

**Two defects this task's own closing exercise produced, both filed rather than folded in:**

- `T-20260920-joining-finding-to-spend-on-agent-id-wit` — the unguarded join matches empty on empty
  and returned 2.2MB of cross product that looked like a result. Written by the session minutes
  after it read AC2, which is the argument for the guard being structural rather than remembered.
- The asymmetry that causes the whole defect class: **spend is written by a hook at the agent's
  Stop, before its reply reaches anyone; a finding is written by whoever reads that reply and must
  carry the id across by hand.** One side cannot forget the id and the other cannot be made to
  remember it by documentation. Recorded here because it is the reason this task kept looking
  solved and kept returning zero.


## Notes

Adjacent: `T-20260808-record-which-mechanism-produced-a-findin` records *which mechanism* produced a
finding; this task is about *which run*. Judging the second reviewer needs both.

Found in the highper-gateway plugin-mode trial, kit defect K2 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

---
id: T-20260924-a-rung-that-cannot-run-writes-no-event-s
title: A rung that cannot run writes no event so the section 3 detection is blind to it
epic: agent-contracts
tier: T2
lang: bash
blocked_by: T-20260923-baseline-and-the-ladder-call-one-fact-ba
paths: tooling/kit-preflight.sh, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

`docs/TRIAL-PROTOCOL.md` §3's unsatisfiable-rung condition (`:453`) is detected by counting
`=unsatisfiable` in the subject's `preflight-commands` events. `kit-preflight.sh --commands` writes
that event **only on the red-disposition path** (`:575`). A command that CANNOT RUN — exit 126/127,
the tooling absent — stops at `:462` with exit 1 **before any event is written**.

So the case the condition was written for, tooling that does not run, is the one case the
detection cannot count. §3 compensates by requiring the operator to check `--commands; echo $?` is
0 or 3 before reading the count, which moves the control from the log to a step the reader must
remember. The same exit 1 also covers an unanswered red set (`:547`), so the exit code does not
separate them either — the half of `d3ae7333` that exit 3 did not fix.

Found 2026-09-24 by two independent verifiers reconciling the parent task's findings; the
chain-2 verifier reproduced a 127 exiting 1 with no event row.

## Acceptance criteria

- [ ] A cannot-run stop leaves a record a later reader can count without re-running pre-flight.
- [ ] §3's detection reaches the cannot-run case from that record, not from an exit code read at the time.
- [ ] A check that fails when the cannot-run path writes nothing.

## Notes

**Blocked by `T-20260923-baseline-and-the-ladder-call-one-fact-ba`.** That task's third criterion is
that the pre-flight's recorded disposition be readable by whatever names the rung later. What this
records, and in whose vocabulary, is that decision; building it first would fix one shape and
rebuild it. Parent: `T-20260912-a-declared-rung-whose-tooling-fails-has-`, findings `d3ae7333` (partial).

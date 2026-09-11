---
id: T-20260911-kit-guard-refuses-the-harness-scratchpad
title: kit-guard refuses the harness scratchpad so temp writes move to unguarded Bash
epic: validation
tier: T2
lang: bash
paths: tooling/kit-guard.sh, hooks/hooks.json, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

`kit-guard` refuses a Write or Edit outside the project root. The harness designates a session
scratchpad **outside** the project root and tells the agent to put temporary files there. The two
instructions cannot both be followed with the guarded tools, so an agent that follows the harness
moves to Bash — which the guard's matcher (`Write|Edit|NotebookEdit`, `hooks/hooks.json`) does not
cover.

On the 2026-09-09 highper-gateway trial (trial notes, 14:05:06Z) `kit-guard` refused a Write of a
commit-message draft to the scratchpad: *"kit: refusing write outside project root"*. By then the
session had already written six files there through Bash — logs and reviewer-reply extracts — and
the guard saw none of them. The trial's operator rule was to write only inside the copy; the guard
enforced it for one tool, and in doing so taught the agent to use the other.

**This is a design tension, not a bug in the guard.** Refusing out-of-root writes is right. But the
effect is to shift writes onto the one tool the control cannot see, and the trial recorded the
resulting writes as a rule deviation rather than as a property of the kit.

## Acceptance criteria

- [ ] The kit states where temporary files belong — for example a gitignored directory inside the
      root — in the guard's own header and in `docs/TRIAL-PROTOCOL.md`, so an agent is offered an
      in-root alternative rather than only a refusal.
- [ ] The refusal message names that alternative.
- [ ] Decided and recorded, with the reason: whether the harness scratchpad is allowed, allowed for
      reads only, or refused. Any of the three is acceptable; leaving it implicit is not.

## Notes

Bash's absence from the matcher is already recorded, as a protocol fact, in
`T-20260808-a-repeatable-trial-protocol-for-running-`. This task is about the guard pushing work
there. Methodology M2 in the trial record is the protocol side.

Found in the highper-gateway plugin-mode trial, kit defect K7 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

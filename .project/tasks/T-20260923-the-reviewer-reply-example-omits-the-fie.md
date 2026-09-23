---
id: T-20260923-the-reviewer-reply-example-omits-the-fie
title: The reviewer reply example omits the fields the recorder requires
tier: T2
lang: bash
state: created
---

## Intent

`skills/verify-ladder/SKILL.md`'s output-contract example shows `class`, `severity`, `summary`
and `lang`. `kit-finding.sh --contract` additionally defines `file`, `line`, `pattern`,
`domain` and `carries_over`, and caps `summary` at **8-200 characters**. None of that is in the
example.

A reviewer handed the example has nowhere to put a location except `summary`, so it puts it
there and goes over the cap. Rejection is all-or-nothing, so the whole review is lost.

**Measured on trial 3, 2026-09-23.** Two reviewers, prompted from the skill's own shape,
independently: **2 of 2 refused, 8 of 8 summaries over the cap** — 359, 362, 417, 360, 392,
450, 385, 419 characters. Both reviews contained a critical (a use-after-free across a C ABI).
Both criticals were lost at that moment and survive only because the caller re-asked by hand.

The `finding-gap` row makes the loss visible, which is the half that works. What does not work
is that the kit publishes the shape that causes it.

## Acceptance criteria

- [ ] The skill's example carries `file` and `line`, because a reviewer with nowhere to put a
      location is the mechanism, not the reviewer's carelessness.
- [ ] The skill states the `summary` cap next to the field, as a number.
- [ ] The two documents cannot drift again: the skill's field list is generated from, or
      checked against, `kit-finding.sh --contract` by something that fails when they differ.
- [ ] A check that would have failed before this change and passes after — not a re-read.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K1.

Do not fix this by making the recorder lenient. The cap exists because seven findings recorded
on 2026-08-10 all read `fail-open|major|bash` and could not be told apart. The defect is the
published example, not the contract.

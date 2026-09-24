---
id: T-20260924-a-dead-set-cmd-lint-line-was-added-twice
title: A dead set_cmd lint line was added twice in the red-disposition arms
epic: agent-contracts
tier: T1
lang: bash
paths: tests/conformance.sh
state: created
---

## Intent

`tests/conformance.sh:6360-6361` sets `set_cmd lint "true"` twice in a row, the reset after arm 3h.
The second line has no effect. It arrived in `bcacd64` — after `e3ea906` removed the identical
shape (`set_cmd test "true"` overwritten two lines later), which two reviewers had filed as
`b1068238` and `c09767e2`.

Found 2026-09-24 by a read-only verifier; re-checked on `main` at `a158d0a`.

Harmless as code. Filed because it is the fixed nit reintroduced by the next commit to touch the
block, and a reader of the arm cannot tell whether the duplicate was meant to reset a different rung.

## Acceptance criteria

- [ ] One reset per rung after arm 3h, or a second line that resets the rung it was meant to.
- [ ] If a different rung was meant, the arm that follows still passes with the intended reset and would fail without it.

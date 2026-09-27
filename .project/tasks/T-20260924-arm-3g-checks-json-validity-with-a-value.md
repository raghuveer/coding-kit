---
id: T-20260924-arm-3g-checks-json-validity-with-a-value
title: Arm 3g checks JSON validity with a value that cannot break it
epic: agent-contracts
tier: T1
lang: bash
paths: tests/conformance.sh
state: created
---

## Intent

`tests/conformance.sh` arm 3g (`~6342`) asserts the event log is valid JSON, with the comment
*"An entry carrying a quote used to append a line that no reader could parse"*. The only value the
arm ever writes is `lint:101=baseline` — no quote, backslash or newline. The assertion cannot fail on
the regression it cites.

The quote defect (`b94d8ecd`) IS fixed, but by the one-`=` count and exact-suffix match that arm 3f
guards. A change that kept those and broke escaping in `kit-event.sh`'s payload splice — which still
splices raw — would pass 3g.

Found 2026-09-24 by a read-only verifier who reproduced the original defect on `e3ea906` and ran ten
quote/backslash/newline probes against the current script.

## Acceptance criteria

- [ ] Arm 3g writes at least one value carrying a character that must be escaped, and asserts the log still parses.
- [ ] Mutation: make the payload splice skip escaping for that value, and 3g — not only 3f — goes red.
- [ ] If no such value can reach the log through `--commands`, say so in the arm and drop the claim instead.

---
id: T-20260926-the-sign-off-adoption-boundary-check-fai
title: The sign-off adoption-boundary check failed once on macOS
epic: conformance
tier: T2
lang: bash
paths: tooling/kit-trailers.sh, tests/conformance.sh
state: created
---

## Intent

Conformance *"pre-rule commits exempt, post-rule still refused, a bad boundary fails closed"*
(step: the sign-off requirement has an adoption boundary) failed **once on the macOS leg**, on
`main` run `35506232288` at `165afdd` (2026-09-20), with no diagnostic line before the FAIL.
Seen in one of 31 green runs scanned. Passes locally.

Hidden by the tally reset filed alongside this task. The paths above are a first guess.

## Acceptance criteria

- [ ] Reproduced, or its non-reproduction over repeated macOS runs recorded with n.
- [ ] If flaky: the step either becomes deterministic or states what it depends on.
- [ ] The step prints a diagnostic before failing, so the next occurrence is legible.

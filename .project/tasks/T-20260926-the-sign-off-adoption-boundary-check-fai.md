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

## Evidence, 2026-09-26

**Not reproduced, n=5.** Run `36239183305` (PR #182 at `2156682`), macOS leg run five times as
separate attempts -- jobs 108396372008, 108399364893, 108399809206, 108400280478, 108400884217 --
each read from its own log: 150 PASS, 0 FAIL, this step passing, bash 3.2.57 every time. Together
with the scan that found it: **1 failure in 36 macOS runs.**

The step now names each assertion and prints the output it read (`06f7813`), so criterion 3 is
met and the next occurrence will say which assertion fired. Criterion 1 is met as
non-reproduction with n. Criterion 2 -- deterministic or states its dependency -- stays open
until an occurrence shows what it depends on; there is nothing to act on without one.

---
id: T-20260926-kit-index-writes-no-index-under-posixly-
title: kit-index writes no index under POSIXLY_CORRECT on macOS, intermittently
epic: conformance
tier: T3
lang: bash
paths: tooling/kit-index.sh, tests/conformance.sh
state: created
---

## Intent

Conformance *"kit-index parses under POSIXLY_CORRECT and derives the same floor either way"* fails
**intermittently on the macOS leg** with `no index was written under POSIXLY_CORRECT=1` -- present
on some green `main` runs from 2026-09-19 and absent on others. Passes locally on Windows.

It guards the fix of an earlier task that is marked completed (an octal escape in `globre` made
`kit-index.sh` unparseable under `POSIXLY_CORRECT`), so an intermittent failure here is either a
flaky test or a regression of completed work; which one is the first thing to establish.

Hidden by the tally reset filed alongside this task.

## Acceptance criteria

- [ ] Flaky test or real regression, decided from evidence (repeated runs on the macOS runner).
- [ ] The step passes on macOS across repeated runs, counted by FAIL lines.

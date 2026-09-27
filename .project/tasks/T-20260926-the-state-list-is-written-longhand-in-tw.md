---
id: T-20260926-the-state-list-is-written-longhand-in-tw
title: The state list is written longhand in two files
epic: conformance
tier: T2
lang: bash
paths: tooling/kit-lib.sh, tests/conformance.sh
state: created
---

## Intent

The conformance check *"each state definition appears in exactly one file"* fails on every leg,
and reproduces locally: `'created planned in-progress on-hold completed cancelled abandoned'
appears in 2 file(s), expected 1` -- `tooling/kit-lib.sh` and `tests/conformance.sh`. The
vocabulary rule it guards is that the state list has one home.

Hidden since at least 2026-09-19 by the tally reset filed alongside this task.

## Acceptance criteria

- [ ] The list is written longhand in one file only; the other reads it.
- [ ] The step passes on all three legs, counted by FAIL lines, not the tally.

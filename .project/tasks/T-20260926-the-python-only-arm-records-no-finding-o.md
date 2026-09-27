---
id: T-20260926-the-python-only-arm-records-no-finding-o
title: The python-only arm records no finding on Linux and macOS runners
epic: conformance
tier: T2
lang: bash
paths: tooling/kit-finding.sh, tests/conformance.sh
state: created
---

## Intent

Conformance *"a finding records with only python present, and a missing interpreter is named as
one"* fails on the **ubuntu and macOS** legs with `arm 1: no finding recorded when only python
exists`, on every green `main` run since `73dcaf7` (2026-09-17). It passes on the Windows leg and
locally on Windows. Cause not yet established -- the arm constructs an environment where the
interpreter is named `python`, and something on the Unix runners differs.

Hidden by the tally reset filed alongside this task.

## Acceptance criteria

- [ ] The cause is named from a reproduction on a Unix runner or container, not inferred.
- [ ] The step passes on all three legs, counted by FAIL lines.

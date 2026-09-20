---
id: T-20260920-the-disposition-gate-asks-for-a-transcri
title: The disposition gate asks for a transcription rather than a judgement
epic: validation
tier: T3
paths: tooling/kit-preflight.sh, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

**The gate prints the bypass token, pre-formatted, in the message that stops you.**

`kit-preflight.sh --commands` stops when a declared command ran and reported failures, and asks the
operator to classify each red rung as `=baseline` (a known-red subject, proceed) or
`=unsatisfiable` (the tooling could not run, the trial is VOID). To help, the stop prints a
ready-to-paste value with **every rung already set to `=baseline`**.

**A reviewer pasted it verbatim into the founding scenario on 2026-09-20 and got `rc=0`, proceed.**
That scenario is one rung dead on a missing build dependency and one blocked because the target
does not compile — the 2026-09-09 incident — resolved to "carry on" in one keystroke, with no
thought and no evidence required.

**The two branches are asymmetric in the wrong direction.** `=baseline` costs one paste and
proceeds. `=unsatisfiable` costs editing the string, a second full pre-flight — measured at
**1,464 s** for the named evaluation subject — and ends in a blocked trial. Nothing checks the
classification against anything. Under time pressure this reduces to *type a string to proceed*.

**The friction is not incidental; it is what creates the pressure.** The named subject shows
`1 pass, 3 ran and reported failures` in-container, so the gate fires on **every** trial of it and
mandates a second full sweep each time. A design that makes the careless action cheap and the
careful action expensive will be defeated by the person operating it, and the tool currently hands
them the cheap one first.

**This is a design question about where judgement lives, not a bug**, which is why it was recorded
rather than patched when the mechanical defects around it were fixed.

## Acceptance criteria

- [ ] The correct action is at least as cheap as the careless one. Whatever shape that takes, it is
      argued against the measured cost above rather than asserted
- [ ] The stop does not hand over a value that classifies every rung as proceedable. If a template
      is printed at all, an unedited paste must not be a valid disposition
- [ ] Re-running to confirm a disposition does not require re-running every declared command, or
      the reason it must is stated with its cost
- [ ] Whether the classification is checkable at all is **decided**. It may not be — a human
      asserting "this failure is pre-existing" is not mechanically verifiable — and if so, that is
      recorded as the boundary of what this control can do, the way the prose check's ceiling was
- [ ] A check that can fail, whatever is built

## Notes

Found by both reviewers of the third T3 chain on 2026-09-20, one of whom demonstrated it end to end
on a live fixture. Split out of `T-20260912-a-declared-rung-whose-tooling-fails-has-`.

**T3 on consequence, not on a path floor** — the same argument the parent makes. This decides
whether the control that decides whether every other control ran can be waved through by a
keystroke, and its failure is silent: it reads as a dispositioned trial.

Related: `T-20260822-process-creation-costs-one-second-on-the` measured what per-item work costs
here, and is the reason a second full sweep is not a small ask.

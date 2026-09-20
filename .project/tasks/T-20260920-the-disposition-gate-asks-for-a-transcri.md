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

### END-TO-END REPLAY, 2026-09-20 — this task is now the ONLY thing between the founding scenario and COMPLETE

Built the 2026-09-09 shape as a real `kit-init.sh` subject: `commands.typecheck` exits 101 printing
*"protoc not found"*, `commands.test` exits 101 printing *"could not compile --lib"*, `commands.lint`
passes, `commands.build` is a comment. Then ran the chain, rather than reading it.

**Pre-flight reproduces the incident exactly:**

    commands.build      NOTHING DECLARED -- unavailable; raise the tier
    commands.test       ran, exit 101 -- a baseline fact, not a stop
    commands.lint       runs
    commands.typecheck  ran, exit 101 -- a baseline fact, not a stop
    STOP -- 2 declared command(s) RAN AND REPORTED FAILURES          rc=1

**Path A — the operator judges honestly.** Dispositions both rungs `=unsatisfiable`:

| step | result |
|---|---|
| pre-flight | **rc=3**, VOID-shaped, distinct from the cannot-run stop |
| §3's detection, run verbatim | returns **1** → **VOID** |

**The chain now works.** That is what items 1 and 2 bought: before them, §3 carried no such
condition and the detection did not exist, so an honest disposition reached nothing.

**Path B — the operator pastes what the tool printed.** The stop offers:

    KIT_COMMANDS_RED_DISPOSITIONED="test:101=baseline,typecheck:101=baseline"

| step | result |
|---|---|
| pre-flight with that value | **rc=0**, proceed |
| §3's detection | returns **0** → **NOT VOID, trial proceeds** |

**And nothing downstream catches it.** The template now forces a disposition row, but the operator
writes `baseline` there too, consistent with the ruling they just made. A wrong judgement is
internally consistent all the way to COMPLETE.

**SO THE ANSWER IS PRECISE.** Before today there were three holes between the founding scenario and
COMPLETE: the gate did not fire, §3 carried no condition, the template required no disposition.
**Two are closed. This task is the third, and it is the only one left.** It is also the one that
cannot be closed by a mechanism, because the thing being asked for is a human judgement about
whether a failure is pre-existing — and the tool currently makes the wrong answer one keystroke
cheaper than the right one.


## Notes

Found by both reviewers of the third T3 chain on 2026-09-20, one of whom demonstrated it end to end
on a live fixture. Split out of `T-20260912-a-declared-rung-whose-tooling-fails-has-`.

**T3 on consequence, not on a path floor** — the same argument the parent makes. This decides
whether the control that decides whether every other control ran can be waved through by a
keystroke, and its failure is silent: it reads as a dispositioned trial.

Related: `T-20260822-process-creation-costs-one-second-on-the` measured what per-item work costs
here, and is the reason a second full sweep is not a small ask.

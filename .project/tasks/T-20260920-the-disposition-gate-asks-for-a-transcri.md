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

- [x] The correct action is at least as cheap as the careless one. Whatever shape that takes, it is
      argued against the measured cost above rather than asserted
- [x] The stop does not hand over a value that classifies every rung as proceedable. If a template
      is printed at all, an unedited paste must not be a valid disposition
- [x] Re-running to confirm a disposition does not require re-running every declared command, or
      the reason it must is stated with its cost
- [x] Whether the classification is checkable at all is **decided**. It may not be — a human
      asserting "this failure is pre-existing" is not mechanically verifiable — and if so, that is
      recorded as the boundary of what this control can do, the way the prose check's ceiling was
- [x] A check that can fail, whatever is built

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


### The tool no longer prints its own bypass, 2026-09-20

**One criterion met, the rest deliberately not.** The stop now prints scaffolding with the
judgement withheld:

    KIT_COMMANDS_RED_DISPOSITIONED="test:101=?,typecheck:101=?"

**The rung names and exit codes are still printed, on purpose.** Transcribing those is tedious and
getting one wrong is a typo rather than a judgement — and an operator who cannot produce the string
at all will skip pre-flight entirely, which is a worse failure than a careless disposition. What is
withheld is only the part that IS a judgement. `?` is refused by the parser, so an unedited paste
stops exactly as an absent value does.

**Re-ran the end-to-end replay's careless path:** pasting what the tool prints now gives **rc=1**
where it gave **rc=0**, and no disposition event is written, so nothing is recorded as blessed that
was never judged.

**The arm is the reviewer's attack made permanent.** Rather than asserting the output does not
contain `=baseline` — which a rewording would defeat, the way three prose assertions were already
defeated — arm 3h **captures whatever the stop prints and feeds it straight back**, requiring
refusal. That is a property of the output rather than of one placeholder. Mutation-proven:
restoring the all-`=baseline` default fires *"the value the tool printed is itself a valid
disposition -- it prints its own bypass"*.

**WHAT THIS DOES NOT DO, and the task stays open for it.** It stops a thoughtless paste. It cannot
stop a **considered wrong answer**: an operator who types `=baseline` for a rung that genuinely
could not run still proceeds, and the report's disposition row will agree with them, because it is
the same person writing both. The judgement remains human. What changed is that the tool no longer
supplies the wrong one for free.

**Still open, and both are decisions rather than code:**

- whether re-confirming a disposition must re-run every declared command — it still must, and that
  was measured at 1,464 s on the named subject
- **whether the classification is checkable at all.** The criterion asks for this to be decided,
  and the honest answer looks like *no*: "this failure is pre-existing" is a claim about history
  that no mechanism here can verify. If that is the ruling, it belongs recorded as the boundary of
  this control — the way the prose check's ceiling now is — rather than chased through a fourth
  mechanism.


### The friction criterion, ruled 2026-09-20 — and the cost was overstated, by me

**Ruled: confirming a disposition MUST re-run every declared command.** A disposition is a
statement about what *this* run observed. Accepting a cached red set would bless an observation
taken at some other time, which is precisely the staleness that got the count-based version
rejected. There is no way to know the set is unchanged without looking.

**But the cost is not what was reported, including by me, repeatedly.** The reviewer wrote that the
gate *"mandates a second full run"*, and I restated that as a doubling of every trial in four
separate messages. Measured 2026-09-20:

| case | invocations |
|---|---|
| red set **known** — set the variable, then run | **1** |
| red set **unknown or changed** | 2 |

A matching disposition supplied up front exits 0 on the first run. **So the charge is one extra
sweep per (subject, red-set) — not per trial, not per invocation — and it disappears once a subject
is familiar.**

**And the extra sweep is the subject's cost, not the kit's.** The arm itself runs in ~2.3 s on the
fixture. The 1,464 s figure is one rung of the real evaluation subject compiling a dependency tree
in a container — a cost the trial was going to pay at rung 1 regardless. **The gate moves it
earlier, to where a remedy is still legal**, because §2 makes the same edit mid-trial void the
trial. That is the whole argument for pre-flight, and the friction objection was measuring the
subject's build and attributing it to the gate.

**What this does NOT overturn.** The reviewer's underlying point stands: a design that makes the
careless action cheap and the careful one expensive gets defeated by its operator. That is why the
printed default was removed. The correction is only to the magnitude, and it matters because a
doubling would be an argument against the gate while one extra sweep on first acquaintance is not.

### All criteria are now met. The close is the operator's.

Recorded rather than closed, per ADR 0010. **What a reader should stay sceptical of:** none of this
makes a *considered* wrong answer detectable. An operator who types `=baseline` for a rung that
could not run still proceeds, and the report's disposition row will agree with them because the
same person writes both. The classification was ruled unverifiable earlier today with its own
measurement; **attribution is the compensating control and it does not work yet** —
`T-20260920-a-disposition-that-cannot-be-verified-mu` is filed, and until it lands the event
carries no actor.

## Notes

Found by both reviewers of the third T3 chain on 2026-09-20, one of whom demonstrated it end to end
on a live fixture. Split out of `T-20260912-a-declared-rung-whose-tooling-fails-has-`.

**T3 on consequence, not on a path floor** — the same argument the parent makes. This decides
whether the control that decides whether every other control ran can be waved through by a
keystroke, and its failure is silent: it reads as a dispositioned trial.

Related: `T-20260822-process-creation-costs-one-second-on-the` measured what per-item work costs
here, and is the reason a second full sweep is not a small ask.

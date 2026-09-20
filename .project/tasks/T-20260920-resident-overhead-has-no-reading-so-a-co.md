---
id: T-20260920-resident-overhead-has-no-reading-so-a-co
title: Resident overhead has no reading, so a context reduction cannot be attributed
epic: validation
tier: T2
paths: tooling/kit-spend.sh, tooling/kit-status.sh
state: created
---

## Intent

**`context_peak` cannot answer the question it is read for, and no number of sessions fixes that.**
Measured on 2026-09-20 over 34 main-scope sessions carrying a context reading:

    context_peak   min 24,210   max 963,201        a 40x spread
    among the large ones: 441,430  543,806  639,338  716,062  750,414  963,201

`context_peak` is a **maximum over the whole session**, so it mixes the kit's FIXED cost with the
WORK's variable cost, and the variable part dominates. A change to the kit — a shorter working
agreement, a load that stops happening — moves the fixed part by a few percent and is invisible
inside a 2.2x spread among comparable sessions. This is structural. More samples cannot fix it,
because the property being asked for is absent rather than merely unevidenced.

**What is missing is a reading that isolates RESIDENT OVERHEAD** — the context in force before the
work begins, which is the part a kit change actually moves. The event log already carries per-reading
series, so it is derivable rather than new data collection: first readings of 136,520 at turn 62 and
100,695 at turn 36 were sampled while establishing the above.

**Filed as the disposition of `T-20260912-reduce-peak-context-per-session-and-meas`**, which is now
`on-hold` behind this task. That task deliberately made no reduction, because a reduction measured
against `context_peak` produces a number nobody can attribute. Building this instrument under that
task would have meant adding a criterion to make the task passable, which is the laundering this
repository refuses elsewhere. So it is its own task, with its own criteria, and the parent waits.

## Acceptance criteria

- [ ] A reading exists that isolates resident overhead from the work's variable cost, derived from
      `.project/events.ndjson` rather than from a new collection path
- [ ] It is proved able to fail, by a mutation that changes the resident part and is seen to move
      the number, and a mutation that changes only the work and is seen NOT to move it. The second
      half is the one that matters: a reading that tracks the work is `context_peak` again
- [ ] **Repeatability is measured and stated, not assumed.** The parent's AC4 asked for a reading
      repeatable across two sessions and `context_peak` failed it at 40x. This task reports its own
      spread over at least two sessions rather than inheriting the claim
- [ ] The known hole is carried forward explicitly: `kit-spend.sh` appends only when TOKEN totals
      move, and its dedupe key omits context, so any context column is a FLOOR on the true value.
      Whatever this reading is, it says so where it is reported
- [ ] `T-20260912-reduce-peak-context-per-session-and-meas` is taken off hold when this lands, or
      this task records why it still cannot be

## Notes

The parent's three options were put to the operator on 2026-09-20 and **option 2 was ruled**: file
the resident-overhead reading as its own task and let the parent wait for an instrument that can
attribute a reduction. Option 1 (declare unavailable, raise the tier) was rejected as ceremony —
raising a tier buys more review, and no work had been done for a reviewer to look at. Option 3
(amend the criteria) was rejected because the parent's AC2 exists precisely to stop a token metric
being improved by reviewing less, and amending the anti-gaming control to pass is the thing it
guards.

The parent is `on-hold` with this task as its blocker rather than left `created`. An open task
waiting with no stated reason is exactly the ambiguity the governing ordering document warns about
in its section 3.

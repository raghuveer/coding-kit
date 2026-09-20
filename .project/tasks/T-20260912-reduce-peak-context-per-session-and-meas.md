---
id: T-20260912-reduce-peak-context-per-session-and-meas
title: Reduce peak context per session and measure it against escape rate
epic: measurement
tier: T2
blocked_by: T-20260821-the-kit-does-not-measure-its-own-develop, T-20260920-resident-overhead-has-no-reading-so-a-co
state: on-hold
---

## Intent

**The caching lever is close to exhausted and the record says by how much.**
`DESIGN-NOTES.md` §0 measures a cache-read ratio of 97.5% and an effective input multiplier of
0.129x against a 0.100x floor -- at most 22% headroom left. The two levers that remain are
**peak context window** and **model mix**, and neither has an owner.

This task takes peak context: what enters a window, when, and what it costs. It must be measured
against escape rate in the same breath, because `HANDOFF.md` §9 is blunt that every token metric
improves if you simply review less -- so a reduction that degrades review has to be reported as
a loss, not a saving.

Proposed in `design-input/2026-09-09-one-core-many-adapters.md` §10 and never filed until now.

## Acceptance criteria

- [x] Peak context per session is recorded from the transcripts, not estimated
- [ ] At least one reduction is made, and its before and after are reported with escape rate beside them rather than alone
- [ ] A reduction that lowers escape-rate performance is reported as a loss, per `HANDOFF.md` §9
- [ ] The measurement is repeatable across two sessions, so a change is distinguishable from a difference in the work

### Evidence, 2026-09-18 — AC1 only; the peak was already in the log and nobody was reading it

**AC1 is met and the other three are not.** This is the measurement half of the task; the
reduction half has not been attempted.

**`spend.context` is the LAST reading, not the peak, and the gap is not small.** Measured on this
repository before the column existed:

    transcript ea536e58   76 readings   final = 270,398   PEAK = 963,201   (3.56x)

Context FALLS as well as rises -- compaction reclaims it -- so a session that peaked high and
ended low reports the low number. **"Reduce peak context" cannot be asked of a final reading at
all**, which is the whole reason AC1 is worded "peak ... not estimated".

**Nothing new is recorded. The series already existed.** `kit-spend.sh` appends an event whenever
a transcript's totals move, so the log holds the readings; `context_peak` is a running max taken
during ingest. The instrument closed as `T-20260821` on 2026-09-17 is what made this free -- one
day earlier this criterion would have needed a recorder change.

**`readings` is stored beside it, because `peak == final` has two meanings.** A series that never
fell, or **no series at all**. On this repository: **81 transcripts, 9 with more than one reading,
1 with a peak above its final.** Reported in that order in `STATUS.generated.md`, because a bare
"1 of 81" reads as a rarity rather than as a thin denominator.

**A KNOWN HOLE, stated rather than discovered later.** `kit-spend.sh` appends only when TOKEN
totals move, and its dedupe key is `tok_in|tok_out|cache_read|cache_write|pack_loads` -- **context
is not in it**. A context move with no token move appends nothing, so this column is a **floor on
the peak**, exact only where the two move together. Both the schema comment and the status note
say so.

**One claim in the tree was refuted by this and is corrected in the same change.**
`kit-status.sh` argued session-length bucketing from "Context grows **monotonically** within a
session". It does not; 963k -> 270k is the counter-example this column produced. The trend argument
survives, the word did not, and it was the word doing the work.

**The check can fail, proved by two mutations run separately:**

| mutation | result |
|---|---|
| `context_peak` collapses to the final reading | FAIL -- *"peak is 250, wanted 900 -- the peak is not being derived"* |
| `readings` is always 1 | FAIL -- *"readings is 1, wanted 3"* |

The fixture is a series whose token totals rise while context rises **then falls**. Its first
version used malformed timestamps (`2026-01-0100T...`) and failed for that rather than for the
defect -- the ingest sorts by timestamp THEN total, so a bad `at` silently reorders the series and
the highest-total row wins. Recorded because the step would have looked like a true negative.

**NOT claimed.** AC2 (a reduction made, before and after reported), AC3 (a reduction that costs
escape-rate performance reported as a loss) and AC4 (repeatable across two sessions) are untouched.
AC4 in particular needs two measured sessions and has one derivation; a single pass over historical
events is not repeatability. **And AC2 has a problem worth naming now rather than at the end:** it
asks for escape rate beside the before/after, and escape rate here is `0/0` by construction -- so
that half will be honest and uninformative until an escape is recorded.

### Finding, 2026-09-20 — two of the three open criteria cannot be met by work today

Recorded before starting, not discovered part-way through. Every figure re-derived from
`index.db` on the day of writing; none is carried forward from an earlier note.

**AC2 and AC3 rest on escape rate, and escape rate is zero by construction.** `Fixes-Escape-Of`
appears in **0 commits in all history**. AC2 asks for a before and after *"with escape rate beside
them rather than alone"*; AC3 asks that a reduction which lowers escape-rate performance be
reported as a loss. Both can be made to *pass* by reporting `0` before and `0` after, and that
reading would mean nothing. It is the green-that-cannot-fail this project refuses, and producing
it inside the criterion written to prevent exactly that would be worse than leaving the criterion
open.

**`T-20260914-the-escape-rate-numerator-has-no-writer-` does NOT unblock this, and was checked
rather than assumed.** It is complete, 3 of 3, verified 2026-09-15. Its job was to put the trailer
in front of the writer -- it was missing from `.claude/CLAUDE.md`, the one file a session reads --
and to make a zero print as *"zero by construction"* rather than as a clean result. **It builds
the door; it cannot produce escapes.** An escape is recorded when a real defect passes a real
review and someone writes the trailer on the fix. No mechanism creates that.

**AC4 is refuted by the data, and this is the finding that matters most.** It requires the
measurement to be *"repeatable across two sessions, so a change is distinguishable from a
difference in the work"*. Measured over **34 main-scope sessions** carrying a context reading:

    context_peak   min 24,210   max 963,201        a 40x spread
    among the large ones: 441,430  543,806  639,338  716,062  750,414  963,201

**Between-session variance is 2.2x among comparable sessions and 40x overall.** A reduction to the
kit -- a shorter working agreement, a load that stops happening -- moves a few percent. It is
invisible inside that noise. AC4 does not merely lack evidence; the data says the property it
requires is absent.

**The cause is structural, not a shortage of samples.** `context_peak` is a maximum over the whole
session, so it mixes the kit's FIXED cost with the WORK's variable cost, and the variable part
dominates. A change to the kit only moves the fixed part, so it cannot be attributed from this
number however many sessions are collected.

**What would make it measurable**, stated so the next reader does not re-derive it: a reading that
isolates resident overhead -- the context in force before the work begins. The event log already
carries per-reading series (first readings of 136,520 at turn 62 and 100,695 at turn 36 were
sampled while checking this), so it is derivable. **But that is a new instrument, and it is not
among this task's criteria.** Building it under this task would be adding a criterion to make the
task passable, which is the laundering this repository refuses elsewhere.

**Disposition is the operator's, not this note's.** The shape has precedent: `T-20260821`
carried a criterion its own task called *"a defect in the criterion as much as a gap in the
work"*, and it was left as a ruling. The options, none of them taken here:

1. **Declare the escape-rate and attribution halves unavailable**, name the compensating control
   and raise the tier -- the verify ladder's own move for a rung that cannot be satisfied.
2. **File the resident-overhead reading as its own task**, and let this one wait for an instrument
   that can attribute a reduction.
3. **Amend the criteria.** Possible, and the argument would have to be written down, because AC2
   exists precisely because `HANDOFF.md` section 9 says every token metric improves if you simply
   review less.

**Not done, deliberately:** no reduction was made. Making one now would produce a number nobody
can attribute and an escape-rate column of `0` to `0`, which is the outcome all three criteria
were written to prevent.

## Notes

**ON HOLD FROM 2026-09-20, behind `T-20260920-resident-overhead-has-no-reading-so-a-co`.** The
operator ruled option 2 of the three this task's own note listed: file the resident-overhead
reading as its own task, and let this one wait for an instrument that can attribute a reduction.

It is `on-hold` with a named blocker rather than left `created`, because an open task waiting for
an unstated reason is the ambiguity the governing ordering document warns about in its section 3.
Nothing here is withdrawn: AC1 stands and is met, and AC2 to AC4 stay unticked and unamended. The
refutation of AC4 recorded above is the reason for the hold, not a claim that the criterion was
satisfied.


Deliberately blocked. Per-agent spend works only in plugin mode and the kit registers no
hooks for its own development, so a compression programme run now would be optimising against a
number nobody can read -- the cluster-pack failure in a different costume, and the design input
says so in as many words.

The model-mix lever is real but narrow and should not be folded in here: `MEASUREMENTS.md` §C
found haiku missed a critical security finding entirely at 5 tool uses against 19, and sonnet
softened a REJECT into a REVISE. `MODELS.md` states the shape -- split the work by audience, do
not lower the tier across it.

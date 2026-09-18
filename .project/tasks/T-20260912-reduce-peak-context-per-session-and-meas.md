---
id: T-20260912-reduce-peak-context-per-session-and-meas
title: Reduce peak context per session and measure it against escape rate
epic: measurement
tier: T2
blocked_by: T-20260821-the-kit-does-not-measure-its-own-develop
state: created
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

## Notes

Deliberately blocked. Per-agent spend works only in plugin mode and the kit registers no
hooks for its own development, so a compression programme run now would be optimising against a
number nobody can read -- the cluster-pack failure in a different costume, and the design input
says so in as many words.

The model-mix lever is real but narrow and should not be folded in here: `MEASUREMENTS.md` §C
found haiku missed a critical security finding entirely at 5 tool uses against 19, and sonnet
softened a REJECT into a REVISE. `MODELS.md` states the shape -- split the work by audience, do
not lower the tier across it.

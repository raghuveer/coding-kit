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

- [ ] Peak context per session is recorded from the transcripts, not estimated
- [ ] At least one reduction is made, and its before and after are reported with escape rate beside them rather than alone
- [ ] A reduction that lowers escape-rate performance is reported as a loss, per `HANDOFF.md` §9
- [ ] The measurement is repeatable across two sessions, so a change is distinguishable from a difference in the work

## Notes

Deliberately blocked. Per-agent spend works only in plugin mode and the kit registers no
hooks for its own development, so a compression programme run now would be optimising against a
number nobody can read -- the cluster-pack failure in a different costume, and the design input
says so in as many words.

The model-mix lever is real but narrow and should not be folded in here: `MEASUREMENTS.md` §C
found haiku missed a critical security finding entirely at 5 tool uses against 19, and sonnet
softened a REJECT into a REVISE. `MODELS.md` states the shape -- split the work by audience, do
not lower the tier across it.

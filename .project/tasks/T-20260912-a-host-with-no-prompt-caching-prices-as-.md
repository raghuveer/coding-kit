---
id: T-20260912-a-host-with-no-prompt-caching-prices-as-
title: A host with no prompt caching prices as if cache reads were free because absent and zero are one value
epic: measurement
tier: T2
lang: bash
paths: tooling/kit-spend.sh, tooling/kit-status.sh
state: created
---

## Intent

The four counters assume prompt caching exists. A host that has none emits no cache fields
at all, and the reader would record **zero** -- which then prices as though every read happened
and cost the discounted rate, rather than as though caching was never available.

**Absent and zero are different readings.** The kit already had to make exactly this distinction
once: `via: unknown` is a real value rather than a synonym for any other, because a metric that
cannot tell "reviewed, nothing escaped" from "never reviewed" is an open circuit. The same
argument applies here and has not been applied.

## Acceptance criteria

- [ ] A cache field that is missing from a transcript is stored as absent, and is distinguishable in the database from a recorded zero
- [ ] `kit-status.sh` prints that the host reports no prompt cache, instead of a cache-read share of 0% which reads as a caching failure
- [ ] The effective multiplier is not computed for a host with no cache, rather than computed as 1.0 and presented beside hosts where it means something
- [ ] A conformance step feeds a transcript with no cache fields and asserts the notice appears and no zero-cache figure is printed

## Notes

Found while answering how the cost model travels to a second coding agent, 2026-09-12. It is
not hypothetical: prompt caching is a Claude feature, and the kit's stated scope since 2026-09-11
is any coding agent.

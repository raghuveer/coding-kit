---
id: T-20260923-nothing-prompts-for-task-provenance-so-v
title: Nothing prompts for task provenance so via kit stays empty
tier: T2
lang: bash
state: created
via: kit
---

## Intent

`task.via` partitions escape rate into `kit`, `agent`, `manual` and `unknown`. The schema
comment explains why at length: a metric that cannot tell *"reviewed, nothing escaped"* from
*"never reviewed"* is an open circuit, and the partition exists to close it.

Nothing asks for the value.

**Measured on trial 3, 2026-09-23.** A task created with `kit-task.sh`, tiered with the
tier-classify skill, reviewed by two agents through `kit-review-record.sh`, and committed with
`Task-Id:` and `Tier:` trailers recorded **`via: unknown`**. `kit-status.sh` then reported:

    T3   0 / 0 via:kit     0 / 1 all
    Other provenance — unknown  1 task(s)

The one task in the repository that was unambiguously kit work sat outside the `via:kit`
denominator, which read `0 / 0` — the exact open-circuit reading the column was added to
prevent, reached by the default rather than by dilution.

Both mechanisms exist: `kit-task.sh --via` and a `Via:` trailer the indexer reads. Neither is
mentioned by `kit-init.sh`'s six printed next steps, nor by the verify-ladder skill, nor by
anything else a first-time adopter reads.

**Same shape as K6 of the 2026-09-09 trial**, where the printed next steps omitted
`git.adopted_at` and the trial left it unset, producing *"97 of 98 non-trivial commits carry no
Task-Id"*. A field whose omission silently degrades a headline metric, and nothing prompts for
it.

## Acceptance criteria

- [ ] A task created and committed through the kit's own path records `via: kit` without the
      operator knowing the field exists, or the kit says at the point of creation that it does
      not know and what to pass.
- [ ] `kit-status.sh` distinguishes "no kit work" from "kit work not labelled" — a `0 / 0
      via:kit` line next to a populated `unknown` partition should read as a recording failure,
      not as an absence of work.
- [ ] Whatever prompts, prompts once and is not a per-task ritual.
- [ ] A check that fails on today's behaviour.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K6.

The trial corrected its own task by hand and committed the correction, so the copy's figures
are right; the default is what this task is about.

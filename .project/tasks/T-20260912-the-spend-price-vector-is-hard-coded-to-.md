---
id: T-20260912-the-spend-price-vector-is-hard-coded-to-
title: The spend price vector is hard-coded to one vendor so a second model family cannot be priced
epic: measurement
tier: T2
lang: bash
paths: tooling/kit-status.sh, templates/project-profile.md
state: created
---

## Intent

`kit-status.sh:384` defines the whole billing model as one SQL expression -- input x1,
cache-write x1.25, cache-read x0.1, output x5. Those are **one vendor's published multipliers**,
and they are the only thing standing between four raw counters and every cost figure the kit
reports.

A project running a second model family, or the same family through a different provider, is
priced with the wrong weights and **the report says nothing about it**. A wrong number that
announces itself is a defect; a wrong number that looks right is the failure this kit spends
most of its conformance suite avoiding.

The weights belong in the project profile, keyed by model family, with today's values as the
default so no existing project's figures move.

## Acceptance criteria

- [ ] The four weights are read from the profile, with today's values as defaults, and an existing project's reported totals are unchanged to the last digit
- [ ] A spend row whose model matches no configured family is reported as UNPRICED rather than silently priced at the default -- absent and wrong must not look alike
- [ ] `kit-status.sh` names the family it priced each line with, so a mixed-model project is readable rather than averaged
- [ ] A conformance step configures a second family with different weights and asserts the totals differ accordingly; it is run against the hard-coded expression first, to confirm it fails

## Notes

The weights decide the headline number rather than decorating it: `DESIGN-NOTES.md` §0
measures a cache-read ratio of 97.5% and an effective input multiplier of 0.129x against a 0.100x
floor. Almost all of the input cost is the cache-read weight, so that one constant carries the
result.

This is half of the portability answer; the other half is the reader, in
`T-20260912-the-transcript-reader-parses-one-vendor-`.

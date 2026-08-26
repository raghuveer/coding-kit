---
id: T-20260826-the-trial-environment-is-recorded-as-pro
title: The trial environment is recorded as prose so no two trials can be compared
epic: measurement
tier: T3
paths: docs/TRIAL-PROTOCOL.md, tooling/kit-preflight.sh, docs/TRIALS
state: created
---

## Intent

`TRIAL-PROTOCOL.md` §2 divides everything into *constant within a trial*, *constant across
trials*, and *recorded*. The third category is what makes two trials comparable — and it is
**markdown prose in a report file.** Nothing computes it, nothing checks it, nothing can diff it.

The 2026-08-26 trial recorded, by hand:

- host cargo 1.94.1 vs container cargo 1.98.0 / Debian 12 / gcc 12.2.0 / cmake 3.25.1
- `commands.build` / `commands.test` satisfied through `nerdctl exec` into a container rather than
  natively — a satisfaction shape no previous trial used
- ~1000 ms process spawns on this host making wall-clock non-comparable
- the subject un-buildable on the trial host, for reasons belonging partly to the subject and
  partly to the machine

Every one of those changes what a number from that trial MEANS. None is queryable. Comparing this
trial's ~11M BTE against a future one requires a human to read both reports and notice that one ran
its builds in a container and the other did not.

**The failure this invites is precise: comparing two figures whose recorded variables differ, and
not knowing.** That is worse than having no second trial, because the comparison looks valid.

## The evidence that prose is not enough

The same report contains a baseline entry that was **factually wrong** — "no C compiler on this
machine" — written from a probe in one shell, corrected the next day, and quoted rather than
deleted so the error stays visible. A prose field accepts a wrong value silently. A recorded fact
with a stated derivation at least says where it came from.

## Acceptance criteria

- [ ] The recorded-variable set is **captured, not typed**: toolchain versions, OS, how each
      `commands.*` rung was satisfied, and the kit SHA, gathered by a command rather than by the
      operator remembering.
- [ ] It lands next to the trial's other derived state, so a later trial can be compared against
      it without re-reading a report.
- [ ] **A variable that could not be captured is recorded as uncaptured, never omitted.** An absent
      field reads as "same as default"; the whole §2 discipline exists because that reading is
      wrong. Same rule the ladder already applies to an unavailable rung.
- [ ] Each captured fact names **how it was derived**, so a wrong value is traceable to a probe
      rather than to someone's memory. The "no C compiler" entry came from `command -v` in one
      shell and was reported as a property of the machine.
- [ ] A comparison between two trials **states which recorded variables differ** before it presents
      any figure. If they differ on a variable that affects the figure, the comparison says so
      rather than printing both numbers side by side.
- [ ] `TRIAL-PROTOCOL.md` §2 and the §7 report template are updated together, so the prose and the
      captured set cannot drift — which is instance seven of
      `T-20260826-two-artefacts-carrying-one-fact-with-not`, and should be treated as such.
- [ ] Mutation proof: a trial run with a changed toolchain produces a different recorded set, and a
      comparison against the earlier trial flags the difference.

## Notes

**T3 because it touches the protocol, not because the capture is hard.** The smallest useful
increment is a command that dumps the environment facts into the trial directory; the comparison
machinery can follow. Do that first and this task is most of the way done.

**Scope guard.** This records the environment of a TRIAL — a measurement the kit performs on
itself. It is not a general environment-preflight feature for adopting projects, and must not grow
into one; that would be the kit acquiring opinions about a host machine, which is the boundary
`T-20260808-make-the-security-assurance-cadence-a-po` draws in the same words.

**Prior art to check first**, per the standing rule about ritual-shaped work: `kit-preflight.sh`
already has `--criticals`, `--unassessable`, `--superseded`, `--spend`, `--isolated`. An
`--environment` verb may be the right home and would keep the pre-flight checks in one place
rather than adding a second tool.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 6.

---
id: T-20260920-a-disposition-that-cannot-be-verified-mu
title: A disposition that cannot be verified must at least be attributable
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-event.sh, tooling/kit-preflight.sh
state: created
---

## Intent

**Ruling it unverifiable is what makes this load-bearing.** On 2026-09-20 the disposition gate's
classification was ruled NOT mechanically checkable, with the measurement behind it: a subject's
own failing test and a missing build dependency both exit 101, both fail at baseline and after, so
a before/after comparison separates nothing, and only the error TEXT distinguishes them.

A control that cannot grade an answer has exactly one remaining defence: **the answer must be
attributable.** Otherwise "the operator decided this is a known-red baseline" is a claim with
nothing behind it, which is the shape this repository already refuses for `Via:` and for finding
marks — *a session certifying its own output is the signature that carries no information*.

**It is not attributable today.** `kit-preflight.sh --commands` writes:

    {"task":"","kind":"preflight-commands","at":"...",
     "payload":{"red":"test:101","dispositioned":"test:101=baseline"}}

WHAT was decided and WHEN. Not WHO. And `kit-index.sh` is ready for it — its ndjson reader already
does `jf($0,"actor")` and the `event` table has an `actor` column — but `kit-event.sh` nests its
third argument under `payload`, so a generic writer cannot set a top-level `actor` at all. The
indexer's own comment names this: *"events from this log had no way to say who acted, which is what
made 'the operator records the mark, the agent proposes it' an instruction with nothing behind it."*

**So the gap is in the writer, not the schema**, and it is wider than this one event: every event
appended through `kit-event.sh` is unattributable for the same reason.

## Acceptance criteria

- [ ] An event appended from a tool can carry an `actor`, and the indexer stores it. The column and
      the reader already exist; what is missing is a way for a writer to reach them
- [ ] What `actor` MEANS is decided and written down. A git identity, a harness session, an
      environment variable and "whoever ran the command" are four different claims, and one of them
      is unforgeable-ish while the others are decoration
- [ ] The disposition event carries it, so `preflight-commands` answers who ruled a rung a baseline
- [ ] **A check that can fail**: an event written without an actor is reported as unattributed
      rather than stored as though attributed. An empty string that reads as a value is the failure
      this repository has already recorded twice — `finding.agent_id` and the 582 rows that carry
      nothing
- [ ] Whether an unattributed disposition should BLOCK is decided rather than left implicit. It is
      the only defence left once the classification is unverifiable, which argues for blocking; a
      trial that cannot start because a name is missing argues against. Say which and why

## Notes

Filed 2026-09-20 as the direct consequence of ruling the classification unverifiable, recorded in
`T-20260920-the-disposition-gate-asks-for-a-transcri` and in `tooling/kit-preflight.sh`'s own
comment. **Neither the ruling nor this task claims the question is unanswerable by a human** — a
person reading `protoc not found` knows at once. The claim is about what the mechanism can see.

Related: `T-20260911-a-finding-recorded-by-hand-carries-no-ag` is the same defect one layer over —
a record that identifies no run — and its close on 2026-09-20 turned on producing a real joinable
row rather than on the plumbing existing. The same standard should apply here.

---
id: T-20260915-both-settings-and-plugin-dir-register-th
title: Both settings and --plugin-dir register the spend hook so every reading is logged twice
epic: measurement
tier: T2
lang: json
paths: .claude/settings.json, tooling/kit-spend.sh
state: created
---

## Intent

`T-20260821`'s fourth acceptance criterion says: *"It does not double-count under `--plugin-dir`.
A session run with both the local settings and `--plugin-dir` must not register the hook twice or
write two rows per transcript … check it, do not assume it."* It was checked on 2026-09-15 and
**half of it is false.**

**Measured.** A throwaway repo adopted with `kit-init.sh`, given a `.claude/settings.json`
registering `kit-spend.sh` on `Stop` and `SubagentStop`, then run once with
`claude --plugin-dir <kit> -p '…'` launching one subagent. Result: **8 spend events across 2
transcripts, and every reading written exactly twice** — same timestamp, same `turns`, same
`tok_out`, same `cache_read`, same `context`:

    main     2026-09-15T03:30:38Z turns=5 tok_out=2924 cache_read=105434
    subagent 2026-09-15T03:30:38Z turns=2 tok_out=255  cache_read=0
    main     2026-09-15T03:30:38Z turns=5 tok_out=2924 cache_read=105434     <- identical
    subagent 2026-09-15T03:30:38Z turns=2 tok_out=255  cache_read=0          <- identical
    …4 distinct readings, 8 events

**Which half holds and which does not.** *"Two rows per transcript"* **holds**: the index keys on
the transcript with last-write-wins, so the 8 events collapse to **2 rows carrying the correct
totals**. No token figure derived from `spend` is wrong. *"Register the hook twice"* **fails**: it
is registered twice and fires twice, and `kit-spend.sh`'s guard — *"does not append when the total
has not moved"* — does not stop it, because both firings read the log before either has written.

**So the damage is the append-only log, not the cost.** `.project/events.ndjson` is committed, and
any consumer counting EVENTS rather than derived rows double-counts. `kit-preflight.sh --spend`
is such a consumer: it reported `8 event(s), 2 row(s)` for this fixture.

**This repository's own log is CLEAN** — 0 identical-reading duplicates across 166 spend events and
80 transcripts, checked the same day. The kit's `.claude/settings.json` loads only when the session
root is the kit, the workspace file only when it is the workspace, and neither development session
passes `--plugin-dir`. So nothing recorded here is contaminated.

**Where it will bite is trials.** Every trial runs the kit through `--plugin-dir`. Trial 1 and
trial 2 were unaffected only because adoption installs no settings file
(`T-20260914-kit-agents-are-portable-prompts-behind-a`), so the subject had nothing to register a
second copy. That is luck, not design: the first adopter who registers the hook locally *and* loads
the plugin doubles their own log, and the figure that misleads them is the event count a preflight
prints, not a cost.

## Acceptance criteria

- [x] The two halves stay distinguishable in whatever fix lands. A duplicate that is invisible in
      the derived total and visible in the event log is a different defect from a wrong cost, and
      collapsing them would lose the only signal that showed this one.
- [x] Either the duplicate firing is prevented, or the log tolerates it and every event-counting
      consumer is corrected — `kit-preflight.sh --spend` names event counts today. Deciding which
      is the point of the task; both are defensible and they have different costs.
- [x] A check that can fail: a fixture that fires the recorder twice for one unchanged reading and
      asserts what the log holds afterwards. The existing conformance step at
      `tests/conformance.sh:688` fires four times and asserts ROWS, which is why this survived it.
- [ ] `T-20260821` AC4 is ticked only when this is settled, or is re-scoped to the half it proved.

### Evidence, 2026-09-17 — prevented, not tolerated; three of four criteria met

**The operator chose prevention over tolerating duplicates**, on the measurement below. AC4 stays
open because it belongs to `T-20260821` and is that task's to tick.

**It is a read-then-write race, and it is not rare.** The dedupe reads the WHOLE log into `seen[]`
in awk's `BEGIN` and only then appends, so concurrent firings for one transcript both read the
pre-append state. Reproduced against a throwaway adopted repo, one transcript, one unchanged
reading:

| firing pattern | duplicated |
|---|---|
| sequential, twice | **0 of 1** — the existing guard works |
| **concurrent pairs** | **17 of 20** |

The first three-run sample said 1 of 3 and was misleading; twenty runs said 17 of 20. **A rate, not
an anecdote**, is what made a non-flaky conformance step possible.

**Why this repository's log is clean, confirmed rather than assumed.** `Stop` and `SubagentStop`
key on DIFFERENT transcripts, so they never collide. The collision needs one hook registered TWICE
for ONE transcript, which is what a local `.claude/settings.json` plus `--plugin-dir` produces.

**The fix: `mkdir` as the lock**, because it is atomic everywhere the kit runs and needs no
`flock(1)`, which macOS does not ship. It wraps both read-modify-writes in `kit-spend.sh` -- the
main pipeline and the `spend-gap`/`spend-untracked` append, which greps the log then appends and is
the same race.

| behaviour | measured |
|---|---|
| concurrent pairs, with the lock | **0 of 20 duplicated** |
| a CHANGED reading still appends | 2 events, `tok_out` 20 then 119 |
| stale lock (>1 min) is broken | 0s, reading recorded, lock removed |
| fresh lock held, fall-through | reading **NOT dropped** |
| lock left behind after a run | none |

**Two deliberate choices, both arguable, both recorded.**

*It falls through rather than giving up.* Past the retry bound the behaviour is exactly what it was
before the lock existed -- a possible duplicate. That is better than dropping a reading: a
duplicate is visible in the log, a missing reading is visible nowhere, and understating spend is
the failure this instrument exists to detect.

*The bound is 20 x 0.1s, not 40 x 0.05s.* Every iteration spawns `sleep(1)`. On this machine 40
iterations cost **7s of wall clock against 2s of intended sleep** -- the spawns, not the waiting.
Halving the iterations brought it to 5s here and ~2.2s on a normal machine. It still covers ~2s of
contention against a critical section measured at 0.16s.

**The check can fail, proved by mutation.** With the lock calls removed and nothing else changed,
the new step reports `round1=2 round2=3 round3=3 (wanted 1 event each)` and FAILs. **The
pre-existing step at `tests/conformance.sh:688` still PASSES against the mutant** -- it fires four
times SEQUENTIALLY and asserts ROWS, which is precisely why this defect survived it.

Three rounds of three firings, not one round: at 17-in-20 a single round would pass against the
defect about one time in seven. Three rounds put a false pass below one in three hundred.

**AC1 is met by what the step asserts.** It asserts EVENTS, never rows. Rows were never wrong --
last-write-wins collapses duplicates and no cost figure moved -- and collapsing the two halves
would have destroyed the only signal that exposed this.

## Notes

Filed 2026-09-15 from executing `T-20260821` AC4 rather than from reading code. The criterion's own
words — *check it, do not assume it* — are what produced it; the design comment in
`kit-spend.sh:33-38` reads as though it covered this case and does not.

**Not filed as a blocker on `T-20260821`.** That task can close on a re-scope naming this one, or
wait; the decision is the operator's and is recorded in AC4 above rather than assumed here.

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

- [ ] The two halves stay distinguishable in whatever fix lands. A duplicate that is invisible in
      the derived total and visible in the event log is a different defect from a wrong cost, and
      collapsing them would lose the only signal that showed this one.
- [ ] Either the duplicate firing is prevented, or the log tolerates it and every event-counting
      consumer is corrected — `kit-preflight.sh --spend` names event counts today. Deciding which
      is the point of the task; both are defensible and they have different costs.
- [ ] A check that can fail: a fixture that fires the recorder twice for one unchanged reading and
      asserts what the log holds afterwards. The existing conformance step at
      `tests/conformance.sh:688` fires four times and asserts ROWS, which is why this survived it.
- [ ] `T-20260821` AC4 is ticked only when this is settled, or is re-scoped to the half it proved.

## Notes

Filed 2026-09-15 from executing `T-20260821` AC4 rather than from reading code. The criterion's own
words — *check it, do not assume it* — are what produced it; the design comment in
`kit-spend.sh:33-38` reads as though it covered this case and does not.

**Not filed as a blocker on `T-20260821`.** That task can close on a re-scope naming this one, or
wait; the decision is the operator's and is recorded in AC4 above rather than assumed here.

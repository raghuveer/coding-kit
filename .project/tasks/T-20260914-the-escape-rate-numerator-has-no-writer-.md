---
id: T-20260914-the-escape-rate-numerator-has-no-writer-
title: The escape rate numerator has no writer so every rate is zero by construction
epic: measurement
tier: T2
lang: markdown
paths: .claude/CLAUDE.md, templates/CLAUDE.kit.md, tooling/kit-status.sh
state: created
---
## Intent

Escape rate has two halves and only one was defended. `T-20260808-report-escape-rate-over-both-populations`
built the denominator side and closed: an absent `via:kit` population is called out in the report
as *"an absent denominator, not a clean result"*.

**The numerator had no such guard and no writer.** Measured 2026-09-14: **0 `escaped` events,
ever**, against 200 tasks, 628 findings, 79 criticals and a trial that shipped a change which
does not compile. Every tier therefore printed a plain `0`, which reads as "nothing escaped".

The cause is not subtle once looked for. `Fixes-Escape-Of` is read by `kit-trailers.sh` and
documented in README and HANDOFF — and appears in **0 of 324** agent-authored commits, because
it was absent from `.claude/CLAUDE.md`, the one file a session actually reads. The same shape as
two other instruments found the same day: a mechanism that exists, with its door somewhere the
writer never looks.

## Acceptance criteria

- [ ] The trailer is in both working agreements, in the half it belongs to — the agent half says
      propose and stop, the operator half says who writes it.
- [ ] The report distinguishes a zero with a writer from a zero without one. A numerator of zero
      and no recorder is not a measurement and must not print as one.
- [ ] A check that can fail, and the arm that matters is the second: the caveat must DISAPPEAR
      when a real escape is recorded, or it is decoration that survives its own cause.

## Notes

**Filed 2026-09-14, after the work, to correct a mis-attribution rather than to hide it.** The
change went out as PR #116 carrying `Task-Id: T-20260808-report-escape-rate-over-both-populations`,
which is `done`. Filing today's work against a finished task is how a backlog stops describing
what happened; caught in the closing pass and recorded here rather than amended away.

**Not claimed: that escape rate is now measurable.** It is not. This makes the next escape
recordable and the current zero honest. Denominators fill forward from here rather than being
reconstructed backwards, and back-filling 200 tasks of `Via:` provenance remains the operator's
judgement — `.claude/CLAUDE.md` forbids an agent writing that trailer at all.

Adjacent and still open: `T-20260731-validate-the-priority-weights-against-es` wants escape data
it cannot have until a first escape is recorded.

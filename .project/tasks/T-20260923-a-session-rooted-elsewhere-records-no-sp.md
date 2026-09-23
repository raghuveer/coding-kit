---
id: T-20260923-a-session-rooted-elsewhere-records-no-sp
title: A session rooted elsewhere records no spend in the adopted repo
tier: T2
lang: bash
state: created
via: kit
---

## Intent

The spend hooks fire for the session's own root. A session rooted at one repository that drives
work in another — which is what every trial is, and what a monorepo-adjacent workflow often is
— records **no spend rows at all** in the repository being worked on.

**Measured on trial 3, 2026-09-23.** The adopted copy's first `kit-status.sh` reported the
spend section as *"Not recorded — this is not a measurement of zero"*, and
`kit-review-record.sh` warned on every call: *"no spend rows are recorded at all, so no finding
in this repository can join one."* Both messages are correct and well worded; that half works.

What does not work is the recovery. `kit-status.sh` points at
`kit-spend.sh --transcript <path>`, which is the right tool, but:

- it takes the **main** session transcript and derives the subagent directory as
  `${TRANSCRIPT%.jsonl}/subagents`. Handed a subagent's own file — the nearest thing to hand
  when you want one agent's cost — it finds no sub-folder, records that agent's totals under
  `scope=main`, and exits 0. Populated, plausible and wrong, which is the failure the script's
  own header warns about, reached through bad input rather than bad code.
- with `--agent-id` supplied it writes a `spend-gap` *"no per-agent transcript found for this
  agent"* and exits 0 **silently** — no output at all, so a caller cannot tell success from a
  no-op without tracing it.

The trial produced a spend row that is a reviewer's cost labelled as main-loop cost, and the row
is permanent in an append-only log. It had to be named in the report so the cost table would not
be summed.

## Acceptance criteria

- [ ] `kit-spend.sh --transcript` says what it did. A run that records nothing must not exit 0
      in silence — instrumentation may be non-fatal without being mute.
- [ ] Handed a per-agent transcript it either uses it or refuses it by name. Recording it under
      `scope=main` is the one outcome that must not happen.
- [ ] The adoption path says how a session rooted elsewhere gets spend into the adopted repo,
      at adoption time, not in a status message read afterwards.
- [ ] A check that fails on today's silent no-op.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K7 and the Cost section.

The mis-labelled row was traced with `bash -x` before anything was written down, and it was
operator error rather than a kit defect. The kit defect is that the error was silent and the
wrong outcome was indistinguishable from the right one.

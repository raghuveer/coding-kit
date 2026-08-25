---
id: T-20260825-confirm-a-finding-before-surfacing-it-so
title: Confirm a finding before surfacing it so vindicated is ever written
epic: feedback-loop
tier: T2
paths: agents/security-reviewer.md, agents/implementation-reviewer.md, tooling/kit-finding.sh, tooling/schema.sql
state: created
---

## Intent

`finding.vindicated` records whether a finding was real (`1`), a false positive (`0`), or
unjudged (`NULL`). Measured 2026-08-25 by rebuilding the index on `main`:

    vindicated = NULL   482
    vindicated = 1        0
    vindicated = 0        0

**It has never been written. Not once, in 482 findings.** The column exists, its schema comment
states exactly what it is for, and nothing populates it. So the kit cannot answer *"what is our
reviewers' false-positive rate"* — the number every competitor quotes, and the only number that
says whether a review round was worth the tokens it cost.

The same rebuild:

    findings total        482
    dispositioned ever     90   (19%)
    outstanding           392

The closing side is not broken — it moves when it is worked (42 dispositions on 2026-08-20, 17 on
08-13, 14 on 08-19). It is simply outpaced, and every undispositioned finding is indistinguishable
in the record from one nobody looked at.

**The idea is taken from Sonar's Hunter agent**, whose published loop is Hunt → **Confirm** →
Explain → Integrate, where Confirm validates a suspected vulnerability *before* surfacing it. Their
claimed 3.2% false-positive rate is a vendor number with no published method and should not be
treated as a target — but the *stage* is sound, and it is the only idea in that comparison that
reduces closing load rather than adding to it.

## Acceptance criteria

- [ ] A finding is validated before it is recorded, and the outcome is written to `vindicated`.
      A confirm pass that leaves the column NULL has not done the job.
- [ ] `kit-status.sh` reports the confirmed / refuted / unjudged split, so a review round can be
      read as a measurement rather than a pile.
- [ ] **Refuted findings are still recorded**, with the reason. A reviewer that raises something
      the confirm pass kills has produced information — about the reviewer, and about the
      accelerators. Silently dropping it makes the false-positive rate unmeasurable, which is the
      thing this task exists to fix.
- [ ] The confirm pass is **independent of the finder**. A reviewer confirming its own finding is
      the self-certification the working agreement already refuses for `Via:` and for
      `--fixed`, and it carries the same amount of information: none.
- [ ] Cost is measured and reported before this is recommended as default-on. It adds a stage to
      every review in a kit whose central claim is deliberate spend; "it improves quality" is not
      an argument this repository accepts without a reading.
- [ ] `vindicated` stays orthogonal to `fixed_at`, `unassessable_at` and `superseded_at`. Real
      and unfixed, false and irrelevant, real and superseded are different states and the schema
      already says so — do not collapse the new signal into a disposition.
- [ ] Mutation proof: a deliberately false finding is refuted by the confirm pass, and removing
      the pass lets it through.

## Notes

**This attacks the recorded bottleneck, not a hypothesis.** `findings-outpace-dispositions`
records the pattern; the numbers above re-derive it and show it has not improved. 392 outstanding
against 90 ever closed is not a backlog to be worked down by asking for more review rounds.

**The risk to weigh, and it is real.** A confirm stage that is too aggressive suppresses true
findings, and a suppressed true finding is invisible — strictly worse than a false positive,
which is merely expensive. Every measured critical raised by a reviewer on 2026-08-21 that the
operator independently checked was CONFIRMED: not one false alarm across four review rounds. So
**the current false-positive rate may already be low**, and this stage may be solving less than
it appears to. That is an argument for measuring first: run the confirm pass in observe-only mode,
record `vindicated`, and change nothing about what surfaces until there is a number.

That ordering — instrument, read, then gate — is the same one `T-20260808` uses for the assurance
cadence, and the opposite of what a 3.2% marketing figure invites.

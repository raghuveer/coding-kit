---
id: T-20260912-conformance-runs-on-one-core-so-the-only
title: conformance runs on one core so the only Windows signal costs an hour
epic: validation
tier: T3
lang: bash
paths: tests/conformance.sh, .claude/CLAUDE.md
state: created
---

## Intent

The suite's 73 steps are **already independent**: each builds its own fixture under a
distinct `$WORK.<suffix>` and `rm -rf`s it first. It runs serially only because the tallies --
`ok`, `bad`, `ran`, `skipped` -- are shell variables in a single process.

On this machine that costs about an hour, and `.claude/CLAUDE.md` already records what the hour
buys: CI covers ubuntu in ~45s and macos in ~1m50s, and **Windows is in no CI matrix at all**, so
the local run is the only Windows signal that exists. That same block calls itself *temporary* --
"when that gap closes, this belongs in history rather than in the working agreement."

**An hour is why it gets skipped, and a control nobody runs is not a control.** The operator put it
plainly on 2026-09-12: running it for every change, on one core, after CI has already cleared two
platforms, is waste. The answer is to make the cost stop mattering, not to stop checking -- because
the Windows-only failures are real and recent, and none of them could ever surface in Linux CI:

- two GNU-only constructs took macOS red (`T-20260808-the-conformance-suite-shipped-two-gnu-o`);
- a carriage return broke config parsing (`T-20260808-kit-cfg-strips-space-and-tab-from-a-valu`);
- `grep -c $'\r'` degraded to an empty pattern under this shell and produced a **false CRLF
  finding in a trial record**, corrected only after re-measuring in Python.

Measured 2026-09-12: this machine has 16 cores. A prototype splitting the steps round-robin across
8 processes -- one `--only` alternation and one `WORK` prefix per bucket -- required no change to
the suite itself, which is the evidence that the steps really are independent.

## Acceptance criteria

- [ ] `--jobs N` runs the steps across N processes and prints ONE aggregated tally; `--jobs 1` is today's behaviour and its output is byte-identical to a run without the flag
- [ ] A step that lands in no bucket FAILS the run rather than vanishing from it: the run asserts that passed + failed + skipped equals the number of steps it enumerated. This is the whole risk of the change -- a parallel suite that silently drops a step reports green for work it never did, which is the green-that-cannot-fail this suite exists to refuse
- [ ] Exit status is non-zero if any bucket reports a failure or exits abnormally, and a run of zero steps exits non-zero -- the guard `--only` already makes, kept rather than re-argued
- [ ] No two buckets share a `WORK` prefix, and a step proves two concurrent buckets cannot collide -- fixture isolation is the assumption the whole change rests on, so it is asserted, not assumed
- [ ] The wall-clock and the job count are printed, so the gain is measured on each run rather than quoted once. A poor gain must be visible: if it proves I/O-bound on NTFS the honest conclusion is 'run it less', and that conclusion needs the number too
- [ ] Verified against the serial suite step for step -- same steps, same verdicts -- before the parallel path is trusted for anything
- [ ] `.claude/CLAUDE.md`'s working agreement is updated with the measured figure. It currently reads `Windows, local ~1 hour` and states it belongs in history once that gap closes

## Notes

**T3 on risk, not because of a floor.** The declared paths floor at T2. But this changes
the suite that gates every other control, and the way it goes wrong is silent: buckets that drop a
step, or an exit status that loses a failure, both report green. Everything else in this repo is
verified BY this suite, so a suite that over-reports is the one defect with no backstop.

Deliberately out of scope: making CI use it. Ubuntu already runs the whole suite in ~45s, so there
is nothing to win there -- the value is entirely the local Windows run.

Related: `T-20260810-the-suite-that-gates-every-control-has-` -- the suite has no tier floor of its
own, which is the same observation from the other direction.

Filed on the operator's instruction of 2026-09-12, after they challenged the cost of the serial
run. The prototype lives outside the repo and is not the deliverable; `--jobs` in the suite is.

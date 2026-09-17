---
id: T-20260817-an-octal-escape-in-globre-makes-kit-inde
title: An octal escape in globre makes kit-index unparseable under POSIXLY_CORRECT
epic: portability
tier: T3
lang: bash
paths: tooling/kit-index.sh, docs/LESSONS.md
state: completed
---

## Intent

> **AMENDED 2026-09-17. The severity bound in this task is REFUTED — see the amendment below
> the criteria. What follows is the original 2026-08-17 text, kept unedited because the record
> should show what was believed, not only what turned out to be true.**

`tooling/kit-index.sh:351`, inside `globre` — the glob-to-regex converter both tier-floor paths
depend on:

```awk
gsub(/\052+/, ".*", r)
```

Under `POSIXLY_CORRECT=1` the whole program fails to parse:

```
$ POSIXLY_CORRECT=1 bash tooling/kit-index.sh
awk: cmd. line:28: error: Invalid preceding regular expression: /\052+/
kit: task ingest read 0 of 109 task file(s); not read: …
kit: the task ingest did not complete; the index at .project/index.db was NOT rebuilt.
exit 1
```

**It fails safely**, which is why nobody noticed: the ingest refuses, the previous index is left
untouched, and the refusal is announced. This is not silent corruption.

**Reproduced against the parent commit `7c04bef`, so it predates the ADR 0004 work** — the same
error, the same exit code, from `git show 7c04bef:tooling/kit-index.sh`.

**It is this one construct, not a class.** Isolated 2026-08-17:

| regex | `POSIXLY_CORRECT=1` |
|---|---|
| `/\052+/` | **error** |
| `/\052/` | **error** — so the `+` is not the trigger |
| `/\052*/`, `/\052?/` | **error** |
| `/\001/`, `/\001+/`, `/\003.*$/` | fine |

The other octal escapes in this file (`\001`, `\003`, used as record and field separators) are
unaffected. A sweep of `tooling/`, `tests/` and `templates/` for octal escapes inside regex
literals found no other instance.

## What this does NOT establish, stated because it bounds the severity

**No supported platform is known to reject it at runtime.** CI is green on
`conformance (ubuntu-latest)` (mawk) and `conformance (macos-latest)` (BSD awk) on every recent
commit, so neither of the two awks the kit actually ships against has a problem with it. This is
a `gawk --posix` result, and `gawk --posix` is not any platform's awk.

**So the cost is not a broken build. The cost is that the kit's own pre-push check cannot be run
on its largest script.** `docs/LESSONS.md` §12 makes `POSIXLY_CORRECT=1` the partial-BSD
reproduction to run before pushing anything that shells out, on the evidence that it has already
caught two shipped defects that had turned `conformance (macos-latest)` red. That technique is
unusable against `kit-index.sh` — the file every session runs at `task-context` step 1 — because
it dies at parse time before reaching anything else. **A check that cannot be run on the code
most in need of it is the defect here**, and it is worth fixing for that reason rather than for a
portability failure nobody can demonstrate.

## Acceptance criteria

- [x] `POSIXLY_CORRECT=1 bash tooling/kit-index.sh` completes and rebuilds the index, so §12's
      technique covers this file.
- [x] The replacement is **proved equivalent, not assumed**. `/[*]+/` is a candidate and was
      checked on five realistic globs — `tooling/**`, `src/*.go`, `a/**/b`,
      `tooling/kit-index.sh`, `**` — producing byte-identical output under gawk and under
      `POSIXLY_CORRECT=1` gawk. Re-run that comparison as part of the fix rather than trusting
      this note, and include a glob containing no `*` at all, which is the case that must not
      change.
- [x] **Do not "fix" the other octal escapes while here.** `\001` and `\003` are separator
      sentinels, they pass under POSIX mode, and rewriting them would be an unrequested change to
      the git-log reader for no demonstrated gain. If a sweep finds a genuine second instance,
      that is a finding; a tidy-up is not.
- [x] A conformance step, or an addition to an existing one, that runs the affected converter
      under `POSIXLY_CORRECT=1`. Without it this regresses the next time someone reaches for an
      octal escape, and the whole point is that ordinary CI is green either way — **no existing
      check can fail on this**, which is why one has to be added rather than relied upon.
- [x] `docs/LESSONS.md` §12 records the construct alongside the two argument-permutation cases it
      already carries, with the detection. It is a third instance of the same lesson and the
      section is where the next person will look.

## Amendment 2026-09-17 — this is a broken build on a stock awk, not a POSIX-mode curiosity

**The section above headed "What this does NOT establish" is wrong, and it is wrong in the
direction that matters.** It reads:

> No supported platform is known to reject it at runtime. ... This is a `gawk --posix` result,
> and `gawk --posix` is not any platform's awk.

A `conformance (windows-latest)` leg was added to CI on 2026-09-17 (PR #137). On its first clean
run it failed, and this construct is the cause:

```
awk: cmd. line:28: error: ? * + or {interval} not preceded by valid subpattern: /\052+/
kit: task ingest read 0 of 2 task file(s)
kit: the task ingest did not complete; the index at .project/index.db was NOT rebuilt.
```

**`POSIXLY_CORRECT` is not set anywhere in that run.** `grep -c POSIXLY_CORRECT tests/conformance.sh`
is `0`, the workflow sets no such variable, and the error text differs from the one recorded above
(`Invalid preceding regular expression`), so it is not the same code path reporting the same thing.

| | gawk | `/\052+/` in DEFAULT mode |
|---|---|---|
| dev machine | **5.3.2** | accepts |
| `windows-latest` runner | **5.4.1** | **rejects** |

**Not bisected.** Two builds that differ in version behave differently; the change has not been
traced to a specific gawk commit, and this note does not claim a cause beyond the two readings.

### Why this raises the severity rather than merely adding a platform

**It is not a Windows defect.** `conformance (ubuntu-latest)` runs mawk and `conformance
(macos-latest)` runs BSD awk — neither is gawk, which is exactly why two green legs could coexist
with this for a month. Any machine that reaches gawk 5.4.1 loses the ability to build the index,
Linux included. The Windows leg did not find a Windows bug; it found the first machine in this
project's CI running a gawk new enough to care.

So the cost recorded above -- "not a broken build ... the cost is that the kit's own pre-push check
cannot be run on its largest script" -- understates it. On gawk 5.4.1 it **is** a broken build:
`kit-index.sh` cannot rebuild the index at all, and every consumer downstream reports
`no such table`.

### Blast radius measured, not estimated

From that one run: **31 steps FAILed and 37 `no such table` errors** followed the single ingest
refusal. The failures are a cascade from this line, not 31 independent defects. **One failure is
separate and is NOT attributable here** — the CRLF step reports `kit_cfg leg: masked by $(...) on
this shell` and needs its own look. The remainder were not individually attributed.

**It still fails safely.** The ingest refuses, the previous index is left untouched, and the
refusal is announced. Nothing in the original text about fail-safety is disturbed.

### What this changes about the criteria

**AC4's stated rationale is now false.** It says "the whole point is that ordinary CI is green
either way — **no existing check can fail on this**, which is why one has to be added rather than
relied upon." A check that fails on it now exists: `conformance (windows-latest)`, red at run
`35166601466`. The criterion is still worth meeting — that leg is deliberately NOT a required
check, and a `POSIXLY_CORRECT` step would fail on every platform rather than on whichever one
happens to ship a new gawk — but it should be met knowing a check already catches it, not on the
premise that none can.

**AC1 is unaffected and remains the right shape.** AC2's equivalence proof should now also be run
under **gawk 5.4.1**, since that is the awk that rejects the current construct and the one the
replacement has to satisfy.

**No criterion is ticked by this amendment.** Nothing here is a fix; the construct is unchanged at
`tooling/kit-index.sh:351`.

### Evidence, 2026-09-17 — fixed; four of five ticked, AC2 waits on the runner

**The change is one character class.** `gsub(/\052+/, ".*", r)` became `gsub(/[*]+/, ".*", r)` at
`tooling/kit-index.sh`. Nothing else in the function moved.

**AC2's equivalence was PROVED, and the method matters more than the result.** A first attempt
retyped `globre` into a scratch file and lost two backslashes in transcription -- it produced
`^src/.*&go$` where the real function produces `^src/.*\.go$`, so it was comparing something that
was not this code. **Both variants are now extracted from `kit-index.sh` itself**, the new one
derived from the old by a single asserted substitution, so a transcription error cannot survive.

Twelve globs, covering AC2's five plus the cases it asked for by name:

    tooling/**   src/*.go   a/**/b   tooling/kit-index.sh   **
    docs/*.md    a*b*c      *        x    a.b+c(d)    a?b    [abc]

| comparison | result |
|---|---|
| OLD default gawk vs NEW default gawk | **byte-identical** |
| NEW default gawk vs NEW `POSIXLY_CORRECT=1` | **byte-identical** |
| OLD under `POSIXLY_CORRECT=1` | *"Invalid preceding regular expression: /\052+/"* -- the defect, reproduced |

The globs with **no `*` at all** (`tooling/kit-index.sh`, `x`) are unchanged, which AC2 names as the
case that must not change, and the refused ones (`a?b`, `[abc]`) still return empty.

**AC2 IS NOT TICKED.** The amendment above requires the comparison to run under **gawk 5.4.1**, the
version that rejects the construct in default mode. This machine has 5.3.2 and cannot produce that
evidence; `conformance (windows-latest)` is the only place it exists. The proof is the leg moving
off its 31 FAIL / 71 PASS baseline -- not a claim to be made ahead of it.

**AC1 -- `POSIXLY_CORRECT=1 bash tooling/kit-index.sh` exits 0 and rebuilds**: 216 tasks, 635
findings, 81 spend rows, and **143 tasks with a computed `tier_floor`**, which is `globre`'s actual
job rather than merely proof the script ran.

**AC4 -- the step asserts the FLOOR, not the exit status**, because on the defect the ingest refuses
and LEAVES THE PREVIOUS INDEX IN PLACE: correct, announced, and indistinguishable from success to
anything that only checks whether the script ran. A fresh fixture plus a derived value is what makes
it visible. Mutation-proved: restoring the octal escape and changing nothing else gives *"no index
was written under POSIXLY_CORRECT=1"* and FAIL. It also asserts the floor is the same **with and
without** the variable, so the fix cannot silently change what a glob means. **It is not a Windows
step** -- it runs everywhere, because the defect is a gawk version and gawk runs everywhere.

**AC3 -- 13 `\001`/`\003` separator escapes remain untouched.** They are string context, not regex
literals, and the task says not to tidy them.

### AC2 proved on gawk 5.4.1, 2026-09-17 — closed

The one piece of evidence this machine could not produce. `conformance (windows-latest)` on PR #144
ran the suite under **gawk 5.4.1**, the version that rejects the old construct in default mode:

| | baseline (#138..#143) | with the fix |
|---|---|---|
| `/\052+/` parse errors | 1 | **0** |
| `no such table` | 37 | **0** |
| FAIL | 31 | **14** |
| PASS | 71 | **124** |

And the new step passed there by name -- *"kit-index parses under POSIXLY_CORRECT and derives the
same floor either way"* -- so the converter is exercised on the awk that rejected it, not only on
the two that never did.

**The index now builds on gawk 5.4.1, which is the whole of this task.** All five criteria met.

**What the numbers also reveal, and it is not this task's to fix.** PASS went 71 -> 124 because 53
steps that previously could not run now run. **The suite has never actually executed on Windows
before** -- every earlier "31 FAIL / 71 PASS" was one cascade from one unbuildable index, and the
124 is the first real Windows measurement this repository has.

The 14 remaining failures are therefore NEW information rather than a residue, and they cluster:
undeclared-domain handling, and then twelve steps across finding recording, dispositions
(`unassessable`, `superseded`, refutation by id), the finding vocabulary, run-id joins and defect
counting. That is `kit-finding.sh` / `kit-resolve.sh` / `kit-vindicate.sh` territory and it looks
like one or two roots rather than fourteen, the same shape this task turned out to be. **Filed
separately or not at all -- not folded in here**, and no cause is claimed for them from reading a
tally.

## Notes

Found 2026-08-17 while running §12's own check against the scripts changed by
`T-20260817-kit-index-deletes-the-plan-so-task-conte`. `kit-plan.sh` and `kit-status.sh` both
pass under `POSIXLY_CORRECT=1`; only `kit-index.sh` fails, and it failed identically before that
work touched it.

Filed at T3 because `tier.rule: tooling/kit-index.sh T3` — the floor, not a judgement about the
size of the change, which is one character class.

Related: `T-20260731-remove-hex-escapes-from-awk-programs-so-` is the same family one escape
notation over, and its reasoning (macOS awk does not interpret hex escapes) is why this file
prefers octal in the first place. Any fix must not reintroduce hex.

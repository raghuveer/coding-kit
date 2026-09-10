---
id: T-20260910-a-false-red-printf-into-grep-q-under-pip
title: A false red: printf into grep -q under pipefail reports a passing control as failed
epic: validation
tier: T2
paths: tests/conformance.sh
state: created
---

## Intent

`tests/conformance.sh` runs under `set -uo pipefail`. In a pipeline whose right-hand side is
`grep -q`, grep exits as soon as it matches; the producer on the left then takes `SIGPIPE`, and
**`pipefail` reports the pipeline as failed on the producer's status even though grep succeeded.**

So the assertion inverts: **a control that PASSED is reported as FAILED.** It is a race — whether
the producer has finished writing before grep exits — which is why it fires on macOS and not on
ubuntu, and why re-running the same job goes green.

**This is not a new discovery in this repository. The file already documents the trap and forbids
the idiom**, at `tests/conformance.sh:3860-3865`:

> `cap ... | grep -q` passed on Linux and Windows and FAILED on macOS: grep -q exits on its first
> match, printf then takes EPIPE, and under `set -o pipefail` the pipeline reports printf's failure
> rather than grep's success -- so a diagnostic that WAS present read as missing. [...] Capture
> into a variable and match with `case`, which involves no second process at all.

The rule was written for one step and never applied to the rest of the file.

## The occurrence that is proved

**PR #84, run `34490890563`, `conformance (macos-latest)`, 2026-09-10.** A commit that changes one
`.tsv` data file and no shell. `ubuntu-latest`, `structure` and `trailers` all passed on the same
sha; the re-run of the same job (`102918220128`) passed. The log names the mechanism itself:

    tests/conformance.sh: line 512: printf: write error: Broken pipe
      post-rule commit was exempted by the boundary
      FAIL  pre-rule commits exempt, post-rule still refused, a bad boundary fails closed

Line 512 is:

    printf '%s' "$(t "$OLD..HEAD")" | grep -q 'missing  Signed-off-by' ||
      { echo "  post-rule commit was exempted by the boundary"; exit 1; }

`kit-trailers.sh` DID report the missing sign-off. The suite said the boundary had exempted a
post-rule commit. **The diagnostic printed by that failure is a false statement about the code.**

## One more macOS-only red, same shape, mechanism NOT proved

**`34308592637`, sha `0a8f73f`, 2026-09-09** — `conformance (macos-latest)` only, `ubuntu-latest`
green on the same sha. The check that failed is *"agreement passes, and each way of disagreeing is
reported"* (`:4053`), and **every assertion in that step is this idiom**: the step defines
`v() { printf '%s' "$(python3 validate.py 2>&1)"; }` and then tests seven times with `v | grep -q`.

Marked NOT proved because the log carries no `Broken pipe` line. It is consistent with this defect;
it is not a demonstration of it.

## And one macOS-only red that is NOT this defect — checked, not assumed

**`34351636843`, sha `425a8ce`, 2026-09-09**, the red a handoff noted on 2026-09-09 as unreproduced
and worth watching for a recurrence. Its failing check is *"passes on a well-formed commit"* at
`:4258-4260`, which is:

    bash "$KIT/tooling/kit-trailers.sh" range "HEAD~1..HEAD" --enforce >/dev/null 2>&1
    check $? "passes on a well-formed commit"

**There is no pipeline there at all.** This was written into this task as a third occurrence of the
same idiom, on the strength of a `grep` that matched a different step inside the line range being
searched. It was wrong, it is corrected here rather than deleted, and `425a8ce` remains an
**unexplained macOS-only red with no mechanism and no task** — which is the state it was already in
before this task existed. Folding it in here would have retired it without anyone judging it.

## Blast radius, measured 2026-09-10

    59   code sites in tests/conformance.sh pipe into `grep -q`
     2   further mentions inside comments (which a naive lint would flag)
    14   of the 59 are the exact `printf '%s' "$(...)" | grep -q` form
     6   use `grep -qx`
    13   sites pipe into `head`, which also exits early

## Why this matters more than an occasional red

1. **It is a false red, and the cost of a false red is that reds stop being read.** The standing
   rule here is to fix red before merging; an assertion that lies at random trains the opposite.
2. **The same race can produce a false GREEN.** Every one of these sites is `producer | grep -q`
   used as a boolean. Where the sense is inverted — `… | grep -q X && { echo "..."; exit 1; }` —
   an EPIPE makes the pipeline non-zero and the failure branch does NOT run, so a control that
   should have failed reports success. That direction has not been observed and is not claimed as
   observed; it is the reason this is T2 rather than a nuisance.
3. **macOS is one of only two platforms CI covers**, and Windows is in no CI matrix at all.

## Acceptance criteria

- [ ] **The control is STRUCTURAL, not behavioural.** A test that tries to make the race fire is a
      test that passes when the race does not fire, which is the green-that-means-nothing shape.
      The check asserts the IDIOM IS ABSENT from `tests/conformance.sh` — no pipeline whose
      right-hand side is `grep -q`/`grep -qx`.
- [ ] The check distinguishes code from comments. `:3860-3865` documents the trap by quoting it,
      and a lint that flags its own documentation will be silenced rather than obeyed — which is
      how the rule got ignored for the rest of the file the first time.
- [ ] Mutation proof: re-introducing one `| grep -q` in a code line turns the check red, and the
      two comment mentions do not.
- [ ] The 59 sites are converted to capture-then-`case`, the form `:3865` already prescribes. A
      conversion that changes what an assertion MEANS is a separate finding, not a silent edit.
- [ ] Run `34490890563` is cited in the fix commit, so the next reader can see the defect was
      observed rather than reasoned about. `34308592637` is cited as consistent-not-proved, and
      `425a8ce` is NOT cited, because it is a different red and this task does not close it.

## Notes

**Scope is `tests/conformance.sh`.** Whether the same idiom is unsafe in `tooling/*.sh` is a real
question and deliberately not folded in: the observed failures are all in the suite, and the suite
is the thing that gates every control. The 13 `| head` sites are named above for the same reason —
they share the mechanism, and whether they are converted is part of doing this, not a separate
discovery to make later.

**Do not "fix" this by removing `pipefail`.** `pipefail` is what makes a failing producer visible
at all; without it a pipeline whose left side dies reports the right side's success, which is a
false green in every one of these sites rather than a false red in some.

Filed 2026-09-10 at the operator's instruction, after the third occurrence.

---
id: T-20260825-nothing-verifies-help-output-so-insertin
title: Nothing verifies --help output so inserting a header truncates it
tier: T2
lang: bash
state: created
---

## Intent

Seven scripts in `tooling/` print their own leading comment block as help, by line number:

    kit-accel.sh          sed -n '4,18p' "$0"
    kit-finding.sh        sed -n '4,8p'  "$0"
    kit-plan.sh           sed -n '4,16p' "$0"
    kit-review-record.sh  sed -n '4,6p'  "$0"
    kit-spend.sh          sed -n '4,46p' "$0"
    kit-task.sh           sed -n '4,14p' "$0"
    kit-trailers.sh       sed -n '4,18p' "$0"

The range is a hard-coded pair of integers with no relationship to the block it is meant to
print, so **any** line inserted or removed above the end of that block silently changes what
`--help` says. Nothing detects it.

Reproduced 2026-08-25 while adding SPDX headers for the relicence
(`T-20260818-relicense-from-mit-to-apache-2-0-while-s`). Two lines inserted after each shebang
made all seven print the SPDX header as the first two lines of help and drop the last two lines
of the real block. It was caught by hand — by capturing what each range printed beforehand and
diffing it afterwards — not by any check.

**The reason this is worth a task rather than a note is that the whole verification ladder
misses it.** `bash -n` passes, because a wrong line range is still valid shell. `validate.py`
does not read help. The conformance suite runs `kit-trailers.sh message --help` nowhere, and
its only `--help` occurrence is its own argument parsing. `commands.lint` in the profile is
`bash -n` over the same files. So a defect that changes user-visible output on seven scripts
has zero gates in front of it, on any platform.

It is also a live trap rather than a historical one: those ranges start at 4 today precisely
because they were bumped by two, and the next header edit hits it again.

## Acceptance criteria

- [ ] A conformance step asserts, for every script that prints its own help by line number,
      that the printed range **still ends at the last line of the leading comment block** and
      **starts at the first line after the shebang and any header**. Derived from the file, not
      a second hard-coded table — a table beside the ranges is the drift this repository has
      already paid for once with the finding vocabulary.
- [ ] The step **discovers** the scripts rather than listing them. A new script added with the
      same idiom must be covered without editing the test, and a script that stops using the
      idiom must not fail it.
- [ ] Mutation proof recorded: inserting one line after the shebang of one script turns the
      step red, and removing it turns it green again. A step that only passes proves nothing.
- [ ] The step fails for the RIGHT reason — a range that is short by one is caught, not only a
      range that is wildly wrong.

## Notes

**A cheaper fix was considered and rejected.** Replacing the line ranges with a sentinel — print
until the first non-comment line, or until a `# ---` marker — removes the coupling entirely and
needs no test. It is the better end state. It is not proposed here as the first move because it
changes seven scripts' output in one go with nothing yet able to tell you whether the output
changed, which is the same hole from the other side. Build the check first; the sentinel then
becomes a refactor the check can verify. If the check is written well, adopting the sentinel
afterwards should turn it green without edits.

**Related shape, deliberately not merged into this task:** `kit-spend.sh` prints a 43-line help
block, which is long enough that a truncation at the tail is invisible to a reader who is not
looking for it. That argues for the sentinel, not for a different check.

Found while doing something else, which is the usual way this class surfaces — see
`a-control-needs-a-check-that-can-fail`. The scripts were not broken before today and are not
broken now; what is missing is the thing that would have said so.

---
id: T-20260920-the-supersession-marker-cannot-be-writte
title: The supersession marker cannot be written in a file that is not markdown
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-resolve.sh
state: created
---

## Intent

**`--superseded` is unreachable for 364 of the open findings, and nothing says so.**

`kit-resolve.sh:308` refuses the verb unless the finding's own `file_path` carries a line matching:

    ^[[:space:]>*_]*Superseded-by:

That character class admits markdown decoration — leading space, `>`, `*`, `_`. It does not admit
`#`, and the regex is anchored at the start of the line. **Every line of a shell script, a Python
file or a YAML workflow is a comment**, so the marker cannot be written in any of them. Probed
2026-09-20:

| line | guard |
|---|---|
| `> **Superseded-by: X**` | accept |
| `   > **Superseded-by: X**` | accept |
| `# > **Superseded-by: X**` | **reject** |
| `#> **Superseded-by: X**` | **reject** |
| `# Superseded-by: X` | **reject** |

**Measured on this repository: 364 open findings are anchored to a file that is not `.md`.** For
every one of them the fourth disposition does not exist, and the refusal message tells the operator
to do something the file cannot contain — *"say so in the subject where its next reader will see
it"*, followed by a form that will be rejected there.

**Found by hitting it.** A critical finding against `tests/conformance.sh` was correctly identified
as superseded — the claim it reviewed had been withdrawn and replaced, which is precisely what the
verb records and precisely what `--fixed` and `--false` would both misstate. The marker could not
be written, so the finding stays open, and it is one of the seven criticals blocking the trial gate.

**The guard's intent is right and is not in question.** A withdrawal must land in a diff, in front
of the next reader of the subject, rather than in a flag. In a code file that means a comment, and
the regex simply does not know that.

## Acceptance criteria

- [x] The marker is writable in the languages this repository's findings actually anchor to —
      shell, Python, YAML, Markdown — without weakening the equality rule on the extracted value
- [x] **The equality rule is preserved exactly.** `kit-resolve.sh:318-330` records that the marker
      check was once containment and that `--by '-'` was ACCEPTED and written into the committed
      log, where `superseded_at` has no retraction. Two reviewers rated that critical. Widening
      what may precede the key must not widen what counts as naming it
- [x] A comment marker cannot be forged by a line that merely mentions the key in prose. The
      distinction between "this line IS the marker" and "this line talks about markers" is the
      whole risk of loosening the prefix
- [x] A check that can fail: the marker is written in a non-markdown subject, `--superseded`
      accepts it, and a mutation that reverts the prefix rule takes the step red
- [x] The refusal message names a form that will actually work **in the file it is refusing**,
      rather than a markdown form for every subject

### Fixed 2026-09-20

The leading class now admits comment markers: `#` for shell, python, yaml and make; `/` for `//`
and `/*`; `-` for `--`; `;` for ini and lisp. `-` is last in the bracket so it is a literal rather
than a range.

**What was NOT widened**, because the task asked for exactly this distinction: the key must still
begin the line after decoration only, so a sentence *mentioning* `Superseded-by:` is not a marker.
Probed both ways — `The rule is Superseded-by: something` and `  see the Superseded-by: convention`
are still rejected, while all five marker forms are accepted. **And the equality rule is untouched**
— the extracted value must still equal `--by` exactly, which is the check that once accepted
`--by '-'` against any marked file and was rated critical by two reviewers. The two rules are
independent and only the first moved.

**The refusal now names a form the subject can carry**, chosen by extension — a blockquote for
markdown, `--` for SQL, `//` for C-family, `#` otherwise. Printing a blockquote for a shell script
was the original defect restated as advice, and it is what made operators conclude a withdrawal was
unrecordable.

**The conformance step asserts the PROPERTY, not the character class**: one file per comment
convention plus the markdown form must all be recognised, and two prose mentions must not be.
Mutation-proven — narrowing the class back to markdown-only takes it red on `a.sh`.

**And the case that found it is now recordable.** `tests/conformance.sh` carries
`# > **Superseded-by: 52c83b2**` at the assertion whose claim was withdrawn, and the guard's own
grep finds it. The finding is still open until the operator runs the mark, which is theirs.

**This lesson has now arrived twice from different directions.** The FIRST version of this class
accepted only whitespace and `>` and so refused the exact text of its own error message; this one
refused every non-markdown subject. Both are the same defect — a guard whose remedy it rejects —
and the step above is written to catch the third instance rather than the third wording.

## Notes

Filed 2026-09-20 while triaging the seven criticals that block `kit-preflight.sh --criticals`, and
therefore every trial. The blocked finding is recorded in
`T-20260912-a-declared-rung-whose-tooling-fails-has-`, and `tests/conformance.sh` carries a comment
at the assertion in question stating that its withdrawal cannot be marked and why.

**This is not a request to make the gate easier to clear.** It is one to make an existing verb
reachable for the subjects it was written for. The gate should stay hard; it should not be
accidentally absolute for two thirds of the findings in the repository.

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

- [ ] The marker is writable in the languages this repository's findings actually anchor to —
      shell, Python, YAML, Markdown — without weakening the equality rule on the extracted value
- [ ] **The equality rule is preserved exactly.** `kit-resolve.sh:318-330` records that the marker
      check was once containment and that `--by '-'` was ACCEPTED and written into the committed
      log, where `superseded_at` has no retraction. Two reviewers rated that critical. Widening
      what may precede the key must not widen what counts as naming it
- [ ] A comment marker cannot be forged by a line that merely mentions the key in prose. The
      distinction between "this line IS the marker" and "this line talks about markers" is the
      whole risk of loosening the prefix
- [ ] A check that can fail: the marker is written in a non-markdown subject, `--superseded`
      accepts it, and a mutation that reverts the prefix rule takes the step red
- [ ] The refusal message names a form that will actually work **in the file it is refusing**,
      rather than a markdown form for every subject

## Notes

Filed 2026-09-20 while triaging the seven criticals that block `kit-preflight.sh --criticals`, and
therefore every trial. The blocked finding is recorded in
`T-20260912-a-declared-rung-whose-tooling-fails-has-`, and `tests/conformance.sh` carries a comment
at the assertion in question stating that its withdrawal cannot be marked and why.

**This is not a request to make the gate easier to clear.** It is one to make an existing verb
reachable for the subjects it was written for. The gate should stay hard; it should not be
accidentally absolute for two thirds of the findings in the repository.

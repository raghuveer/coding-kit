---
id: T-20260827-an-unknown-frontmatter-key-is-discarded-
title: An unknown frontmatter key is discarded silently so a dependency can be written and not exist
epic: measurement
tier: T2
paths: tooling/kit-index.sh, tooling/kit-task.sh, validate.py, tests/conformance.sh
state: created
---

## Intent

Reproduced on 2026-08-27 while recording dependencies that had been sitting in task prose.

I wrote `blocked-by:` — hyphen — into the frontmatter of six task files. The correct key is
`blocked_by:` with an **underscore**. What happened next is the defect:

- the files parsed
- `kit-index.sh` rebuilt with no warning
- `kit-plan.sh` computed an ordering and printed no complaint
- `validate.py` returned **7 ok, 0 warnings, 0 errors**
- and **not one of the six dependencies existed**

It was caught only because I queried the `edge` table by hand to confirm the work had landed. Had
I trusted any of the four green signals above, six false "this is ordered" claims would be sitting
in the backlog, and `kit-plan` would confidently order work by a graph missing seven edges.

## Why the hyphen was a reasonable thing to write

**`kit-task.sh`'s own flag is `--blocked-by`, and the key it writes is `blocked_by`.** The
interface and the storage disagree by one character, in a tool whose whole job is to write that
file:

    tooling/kit-task.sh:4    # kit-task.sh --title "..." [...] [--blocked-by "T-x,T-y"]
    tooling/kit-task.sh:27       --blocked-by) blocked=${2:-}; shift; shift ;;
    tooling/kit-task.sh:82       [ -n "$blocked" ] && printf 'blocked_by: %s\n' "$blocked"

So the failure is not only "unknown keys are dropped". It is that **the kit's own documented
vocabulary contains both spellings for the same concept**, and the one a reader is most likely to
type by hand is the one that silently does nothing.

## Why this is the kit's own defect class, twice over

**A control that cannot fail.** Four separate green signals — index, plan, validate, and the file
itself — all reported success on a file carrying a key none of them understood. This is exactly
`a-control-needs-a-check-that-can-fail`: a check that passes on input it does not comprehend is
not a check.

**Two artefacts carrying one fact with nothing comparing them.** The set of keys `kit-index.sh`
parses and the set `kit-task.sh` writes are maintained independently and nothing asserts they
agree. That is `T-20260826-two-artefacts-carrying-one-fact-with-not`, instance eight, and this
one is in the tooling rather than in the docs.

**And it is the specific failure this whole line of work is about.** The reason
`T-20260826-a-verified-claim-about-the-tree-has-no-a` exists is that a fact was written where a
person would read it and no machine would. Recording the dependency in frontmatter was the fix —
and the fix silently did nothing, which is a worse state than the prose it replaced, because the
prose at least did not claim to be data.

## Acceptance criteria

- [ ] **A frontmatter key the indexer does not recognise is reported**, naming the file, the key,
      and the nearest recognised key. Not fatal by default — a task file is prose plus metadata
      and forbidding annotation would be wrong — but never silent.
- [ ] **The recognised-key set has ONE home**, and `kit-task.sh` writes only keys from it.
      Currently the writer and the reader each carry their own list.
- [ ] **`blocked-by` specifically is either accepted as an alias or rejected loudly.** Choose one
      and state which; a spelling that is neither honoured nor refused is the present bug.
      If aliased, the alias set is part of the single home above.
- [ ] `validate.py` fails, or at minimum warns, on an unrecognised key — it is the check a human
      runs before pushing and it returned a clean bill of health on six broken files.
- [ ] **Mutation proof, and it must be the real one:** a fixture task carrying `blocked-by:`
      produces either an edge (if aliased) or a report (if rejected). A test that only asserts
      `blocked_by:` still works would have passed throughout this defect's entire lifetime.
- [ ] Existing task files are swept once for unrecognised keys and the result reported. Nobody
      knows today how many other silent keys are in the backlog.

## Notes

**Do not "fix" this by adding the alias and stopping.** The alias is the smaller half. The half
that matters is that four green signals reported success on input none of them parsed — if the
alias lands and the reporting does not, the next misspelled key fails exactly as silently.

**Scope check before building:** `validate.py` and `kit-index.sh` are separate readers, and
`kit-entry.sh` reads profile frontmatter with its own parser again. Whether all three share the
recognised-key home, or only the two that read task files, is a design decision this task should
make explicitly rather than by default.

Evidence: six files edited and corrected in the same session; `edge` table went from 9
`depends_on` rows to 16 once the key was spelled correctly, with no other change.

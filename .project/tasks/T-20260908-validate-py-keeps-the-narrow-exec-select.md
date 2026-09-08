---
id: T-20260908-validate-py-keeps-the-narrow-exec-select
title: validate.py keeps the narrow exec selector conformance was widened away from, and reports a partial count as complete
epic: portability
tier: T1
lang: python
paths: validate.py, tests/conformance.sh
state: created
---

## Intent

`tests/conformance.sh:156-164` records, in its own words, what a narrow exec-bit selector cost:

> **THE SELECTOR MUST MATCH CI'S, and it did not.** This loop filtered to `.sh$|commit-msg`, while
> the workflow's "Exec bits survive a fresh clone" step checks EVERYTHING under `tooling/` except
> `schema.sql`. So `kit_findings.py` landed at 100644 on 2026-08-10 and **CI went red for EIGHT
> consecutive commits while this step stayed green** — a local gate weaker than the remote one is
> a local gate that certifies nothing.

**That lesson was applied to `tests/conformance.sh` and not to `validate.py`, which still carries
the original narrow selector.** `validate.py:230-231`:

```python
names = [f for f in sorted(os.listdir(tdir))
         if f.endswith(".sh") or f == "commit-msg"]
```

Two artefacts carrying one fact; one was corrected loudly and the other was never revisited.

## Reproduced 2026-09-08, and it is smaller than it first looked

**The gap set is four files** — tracked, required by CI to be `100755`, never inspected by
`validate.py`:

| file | why `validate.py` misses it |
|---|---|
| `tooling/kit_findings.py` | not `.sh` |
| `tooling/kit_manifest.py` | not `.sh` |
| `tooling/pre-push` | not `.sh`, not named `commit-msg` |
| `templates/ingest-tasks-csv.sh` | **`validate.py:228` scopes to `tooling/` only and never looks at `templates/` at all** |

**Hit rather than found:** `kit_manifest.py` was added at `100644` on 2026-09-08. `validate.py`
reported `7 ok, 0 warnings, 0 errors` locally; CI failed three jobs. That is the eight-commit
incident recurring in the one place its fix was not applied.

## What this is NOT, checked before filing

- **NOT "nothing checks these."** `tests/conformance.sh:152-173` uses CI's exact selector and
  covers all four. The exposure is that **`validate.py` alone gives a false all-clear** — and
  `validate.py` is what `INSTALL.md` documents for a quick local check, and what runs in CI's
  `structure` job.
- **NOT a functional break.** An earlier reading of this claimed that `tooling/pre-push` losing its
  exec bit would silently disable the direct-push refusal. **That is false and is withdrawn.**
  `kit-init.sh:58-64,72` regenerates the hook body into `.git/hooks/pre-push` and `chmod +x`s it
  there, so the source file's mode is never the mode that runs. The `.py` files are likewise always
  invoked as `python3 <path>`. **The exec bit on all four is a consistency rule, not a functional
  one** — which is why this is T1 and not a critical.
- **NOT a deliberate, recorded exclusion.** `git log -L 227,262:validate.py` shows the block
  unchanged since `4368e4b` ("v0.2.0"). No comment in it justifies the selector — the comments
  there explain the Windows index-vs-stat choice only. No task or ADR mentions it.

## Two further inconsistencies in the same check, found while confirming the first

- **Severity differs by platform for one defect.** `validate.py:252` raises `E(...)` on Windows;
  `:259` raises `W(...)` on POSIX, and `:271` is `sys.exit(1 if errors else 0)`, so a warning never
  fails. **CI runs `validate.py` on `ubuntu-latest`, i.e. the POSIX branch** — so `validate.py`
  itself exits 0 on this defect even in CI, and what turns CI red is the separate exec-bit step.
- **The two branches read different sources.** Windows reads the git index (`:237`,
  `git ls-files -s`); POSIX reads the worktree (`:256-257`, `os.stat`). CI reads the index. So on
  POSIX the local check and the remote check are answering different questions about different
  bytes.
- **And the success line reports a partial count as if it were the whole set:** `:254` prints
  `tooling: {len(names)} scripts marked 100755` — 21, when CI requires 24.

## Acceptance criteria

- [ ] `validate.py` selects the way CI and `tests/conformance.sh` already select: tracked files
      under `tooling/` **and** `templates/*.sh`, minus a **named** exception list. Per the
      conformance comment, a file that genuinely should not be executable is added to that list
      **visibly**, not by narrowing the pattern until it stops complaining.
- [ ] The exception list has **one home** that all three consumers read or are asserted against.
      Three copies of one selector is the shape that produced this task.
- [ ] One severity for one defect, on every platform, and it is the severity CI enforces.
- [ ] The success line states the denominator it actually checked, so a partial count cannot read
      as a complete one.
- [ ] A conformance step asserts `validate.py`'s selector and CI's agree — computed, not restated.
      A test that lists the files by hand is a fourth copy.

## Notes

Filed 2026-09-08 on the operator's instruction, after an independent verifier checked every claim.
**Two of my six claims came back PARTLY TRUE and are corrected above rather than filed as stated**:
the gap set had a fourth member I missed (`templates/`), and the `pre-push` impact story was a
mechanism I never checked. Filing the unverified version would have made this a critical about
branch protection quietly failing, which is not true.

**Tier declared T1, not classified.** The change is one selector and a message in a root-level file
outside `tooling/`'s T2 floor, and the defect is a false all-clear rather than a broken control —
conformance already covers the files. Run `tier-classify` rather than trusting this line.

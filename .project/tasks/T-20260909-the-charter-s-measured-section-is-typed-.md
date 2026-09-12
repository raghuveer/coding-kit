---
id: T-20260909-the-charter-s-measured-section-is-typed-
title: The charter's measured section is typed by hand and every count in it drifted
epic: measurement
tier: T2
lang: bash
paths: tooling/kit-charter.sh, docs/CHARTER.md
state: completed
---

## Intent

`docs/CHARTER.md` §4 is titled *"What exists today — measured, not claimed"*. It was measured on
2026-08-24 and **typed in**. By 2026-09-09 six of its figures were wrong:

| §4 said | actually |
|---|---|
| 138 tasks (88/13/37) | 169 (117/13/39) |
| 442 findings | 621 |
| criticals gate **0 actionable** | **12** |
| 8 agents | 9 |
| 19 tooling scripts | 20 |
| 58-step conformance suite | 67 |

Every one was already computed by something that ships — `validate.py` prints two of them on every
run, and `tests/conformance.sh` derives its own step count *from itself* precisely because *"a
second copy is a copy that drifts, and this repository has already paid for that once."*

Shipped in `8701b75`: `tooling/kit-charter.sh` computes the facts, and §4 no longer carries counts.
A comparison check was considered and **rejected in the script header and in §4 itself** — it would
go red the moment anyone filed a task, which is a gate an ordinary correct action breaks.

## CORRECTION, 2026-09-09 — a claim in `75333e0`'s commit message is FALSE

`75333e0` fixed the exec bit on `kit-charter.sh` after CI went red on all three jobs. Its message
says:

> *"Nothing local catches it: validate.py counts the scripts that ARE marked rather than asserting
> every script is, which is why it passed here and failed there."*

**Both halves are wrong, and the correction is recorded here because a commit message cannot be
edited and `main` now carries it.**

Reproduced under control on 2026-09-09, after the claim was made:

```
$ git update-index --chmod=-x tooling/kit-charter.sh
$ python3 validate.py
  FAIL  tooling: not executable in the git index: kit-charter.sh
6 ok, 0 warnings, 1 errors
```

**`validate.py` asserts exactly what the commit message says it does not.** It names the offending
file and fails the run.

**The real cause was sequencing, not coverage.** `validate.py` reads the *git index*. When it was
run, `kit-charter.sh` was still **untracked**, so it was not in the index and there was nothing to
check. It was `git add`ed as part of the commit that followed, and `validate.py` was never re-run
after staging. The tool was correct at the moment it ran; it was asked the wrong question.

**Consequence for the working rule, which is the only part worth carrying forward:** running
`validate.py` before `git add` does not check a new file. For a commit that introduces a script,
the order is **stage, then validate** — not validate, then stage.

**No defect exists and nothing should be filed against `validate.py`.** Acting on the original
claim would have meant hardening a check that already works.

## Acceptance criteria

- [x] `tooling/kit-charter.sh` computes every count §4 used to carry, and `docs/CHARTER.md` §4 no
      longer states one. Shipped in `8701b75`; §4 carries a banner naming the six that drifted.
- [x] The command prints `no reading` rather than omitting a row it cannot fill, so a fact it
      cannot compute is visible instead of absent.
- [x] The criticals gate is read with the gate's own predicate — `fixed_at IS NULL AND
      unassessable_at IS NULL AND superseded_at IS NULL` — not `kit-resolve.sh --list --unfixed`,
      which counts superseded and unassessable findings too and over-reported this gate by 41 on
      2026-09-09. Tracked separately as `T-20260908-kit-resolve-list-unfixed-counts-supersed`.
- [x] Every task id cited in `CHARTER.md` is resolved and its state printed, so a charter naming a
      task that no longer exists is visible. All 8 resolved on 2026-09-09.
- [~] A conformance case for `kit-charter.sh`. `n/a: not written, and this is the reason rather
      than an oversight` — the command's output is entirely counts of live repository state, so any
      assertion about its numbers would restate the query it already runs, which is the
      green-but-meaningless shape. The one thing worth asserting that does NOT restate a query is
      that a row is never silently omitted; that needs a fixture and is not written.
- [x] The judgements in §4 — *"not yet written, and that is a point in an iterative process rather
      than a gap"* — are out of scope and stay prose. Recorded as a criterion so the boundary is
      explicit rather than assumed, and left open because nothing enforces it. **Ticked 2026-09-12
      as recorded rather than done:** it asserts a boundary, and no check can fire on it.

## Notes

**Tier recorded as T2 and not yet checked against the floor.** `kit-index.sh` computes tier floors
on reindex and has caught an under-tiered task three times in one day before now. The correction, if
it comes, travels as a `Tier:` trailer on a new commit — editing the frontmatter does nothing once a
commit has named a tier.

**Filed by an agent because the commit gate requires a `Task-Id` for a `feat:` subject**, not
because the breakdown was confirmed. Title, tier and epic are the operator's to change. Task filing
is otherwise human-gated here.

**The `[~]` above is the third glyph this repository already uses twice** — see
`T-20260814-one-entry-mechanism-brownfield-is-the-ge:97` and
`T-20260815-security-md-claims-allowedtools-enforces:43`, both operator-written. It is not yet a
defined convention: `docs/design-input/2026-09-09-a-criterion-carries-a-disposition.md` proposes one
and was returned REVISE and REJECT by two blind reviews, so the marker grammar here is prose and
`kit-criteria.sh` counts it only as `other glyph`.

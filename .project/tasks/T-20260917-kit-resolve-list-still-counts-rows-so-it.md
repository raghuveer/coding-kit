---
id: T-20260917-kit-resolve-list-still-counts-rows-so-it
title: kit-resolve --list still counts rows, so it disagrees with the gate about a carried-over defect
epic: feedback-loop
tier: T2
lang: sql
paths: tooling/kit-resolve.sh
state: created
---

## Intent

`T-20260914-every-finding-consumer-still-counts-rows` named **three** row-counting consumers and
closed having fixed two. This is the third, left open by contract: no criterion covered it.

`tooling/kit-resolve.sh` has **zero** references to `defect_id` or `carries_over`. Two places
still decide per row:

- **`--unfixed` filters on `fixed_at IS NULL`.** A defect carried into a second round is two rows.
  Mark one fixed and the gate is satisfied — `kit-preflight.sh --criticals` reads the shared
  `UNFIXED` predicate and reports zero — while `--list --unfixed` still returns the other row.
- **The `state` column** prints `OPEN ` / `fixed` from `fixed_at IS NOT NULL` on the row, so the
  same defect renders `fixed` and `OPEN ` on adjacent lines of one listing.

**This is the third instance of the same defect class in this one file, and the file says so.**
Its own comment at `tooling/kit-resolve.sh:101-105` records the second:

> The state column carries the REFUTATION too. [...] it disagreed with the gate whenever a
> critical was refuted: the gate excluded it, the listing still showed it as OPEN, and the two
> numbers could not be reconciled by reading either.

That was fixed for refutation and not for carry-over, because carry-over did not exist yet. The
pattern is now established: **when a gate learns to collapse rows, this listing does not follow,
and an operator reading it concludes work is outstanding that the gate considers done.**

## Why this is not urgent, stated so it is not over-ranked

**0 of 635 findings on this repository carry a `carries_over` link** — verified as
`COALESCE(carries_over,'') <> ''`, because the column stores the empty string rather than NULL and
an `IS NOT NULL` count returns all 635 and is wrong. So today the listing and the gate cannot
disagree here: there is nothing to collapse. This is latent until a review round records a
carry-over, which is equally true of the two consumers already fixed.

**It fails in the safe direction.** The listing shows MORE than the gate, so an operator sees work
that is already addressed rather than missing work that is not. Nobody is blocked and no gate opens
early. That is why the parent task closed rather than staying open.

## Acceptance criteria

- [ ] `--list --unfixed` and `kit-preflight.sh --criticals` cannot disagree about whether a given
      defect is outstanding. A fixture with one defect across two rounds and one `--fixed` mark
      must produce the same answer from both.
- [ ] The `state` column reports the DEFECT's state, so one defect cannot render `fixed` and
      `OPEN ` on two lines of the same listing. Decide and record what a carried-over row shows —
      collapsing the rows and showing the root, or showing each round with the defect's state —
      because those are different operator experiences and the choice is not obvious.
- [ ] `COALESCE(defect_id, id)` is used, not a bare `defect_id`. The parent task established that
      a NULL makes the comparison never true and silently disables the fix; an index built before
      the column must behave exactly as it did.
- [ ] A check that can fail: the assertion must FAIL against the current `kit-resolve.sh` and PASS
      after. A targeted run over code just written proves nothing on its own.
- [ ] The refutation logic at `:101-105` is NOT rewritten while here. It is correct, it was paid
      for once, and touching it would be an unrequested change to the `vindicated` path.

## Notes

Found 2026-09-17 while closing the parent task, by checking the Intent's three named consumers
against the tree rather than the four acceptance criteria against their checkboxes.

Filed at T2 because `tooling/**` floors there. **The operator may want T3**: this is the
consistency between a gate and the view an operator dispositions decisions from, which is the
argument the parent task used to sit at T3 on `tooling/kit-index.sh`.

Severity is still read per row throughout the finding tooling. The parent task's Notes leave open
whether a carry-over chain should collapse to its root for severity as well as for counting; that
question governs AC2 here and is still unanswered.

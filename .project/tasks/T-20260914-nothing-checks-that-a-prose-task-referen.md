---
id: T-20260914-nothing-checks-that-a-prose-task-referen
title: Nothing checks that a prose task reference is declared so the audit decays
epic: planning
tier: T2
lang: python
paths: tooling/kit_refs.py, tooling/kit-plan.sh, tests/conformance.sh
state: created
---
## Intent

`docs/DEPENDENCIES.md` audited 273 prose references against 23 declared `blocked_by:` edges on
2026-09-13 and said plainly what it had not done: *"nothing stops the next twenty tasks writing
dependencies in prose exactly as the last two hundred did."* An audit that decays from the first
task filed after it is a snapshot, not an invariant.

The mechanical form was specified a month earlier, in
`docs/design-input/2026-08-18-the-plan-is-the-unreviewed-artefact.md`, and never built.

## Acceptance criteria

- [x] Every `T-20\d{6}-` reference in a live task body must appear in that task's `blocked_by:` or
      in the dependency map, and the check fails otherwise.
- [x] The state partition is read from the index's `state_class`, not re-spelled in the check.
      `on-hold` counts as live, per ADR 0008 -- this is where it is wider than the hand audit,
      which missed eight references at the parked cluster's ends.
- [x] An unresolvable id is counted and reported, not failed: a different fault with a different
      remedy, owned by `T-20260808-a-task-id-matching-no-task-file-is-count`.
- [x] The map path is a profile key (`paths.depmap`), not a constant. An adopter keeps the map
      where they like.
- [x] A check that can fail, mutation-proven: with the comparison disabled the fixture's undeclared
      reference passes and the conformance step goes red.
- [x] It runs in CI against this repository's own backlog, not only against a fixture.

### Evidence, 2026-09-14

Six criteria, all ticked **at filing time, by the change that implemented them** — this task was
filed alongside its own implementation rather than ahead of it, so the boxes record what shipped
rather than a self-assessment made afterwards. Delivered by PR #108, merged as `bf60490`.

**The state is still `created` and that is the operator's call**, not an oversight: ADR 0010
makes the transition to `completed` a validation rather than an author's claim.

Two things worth carrying that the criteria do not:

- **It fired twice on the changes that wrote it.** 15 undeclared references on its first run
  against a backlog audited by hand hours earlier, then a 16th inside its own commit, then three
  more in the filing PR two changes later.
- **It cannot stop a lazy declaration**, only an undeclared one — `related` is always available.
  Reviewing the map's contents is `T-20260818-nothing-reviews-the-plan-so-a-wrong-orde`.

## Notes

Filed 2026-09-14 at the operator's direction, with the implementation in the same change. The 15
references it found on first run are recorded in `docs/DEPENDENCIES.md`; all were judged from the
paragraph carrying them rather than classified in bulk.

**What it does not do.** It asks that a relation was declared, never that the relation is right.
`related` is always an available answer, so the check cannot stop a lazy declaration -- only an
undeclared one. Reviewing the map's contents is
`T-20260818-nothing-reviews-the-plan-so-a-wrong-orde`, and remains open.

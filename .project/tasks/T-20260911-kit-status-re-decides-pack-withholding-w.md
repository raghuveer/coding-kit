---
id: T-20260911-kit-status-re-decides-pack-withholding-w
title: kit-status re-decides pack withholding with a hard-coded 60 and reports written packs as withheld
epic: planning
tier: T2
lang: bash
paths: tooling/kit-status.sh, tooling/kit-plan.sh, tests/conformance.sh
state: created
---

## Intent

`kit-plan.sh` decides whether a goal's cluster packs are withheld, and `kit-status.sh` decides it
again, by a different rule. **The two disagree on every backlog smaller than `cluster.min_tasks`.**

- `kit-plan.sh:527` withholds only when the largest cluster's share exceeds `cluster.max_share`
  (default 60) **and** the goal has at least `cluster.min_tasks` tasks (default 10). On a small
  backlog, one cluster holding everything is normal rather than degenerate, and the floor exists
  for that.
- `kit-status.sh:875` prints *"Packs are **withheld**"* whenever `cluster_largest_pct > 60`. The 60
  is hard-coded: it reads neither `cluster.max_share` nor `cluster.min_tasks`, nor the
  `cluster_packs_withheld:<goal>` flag that `kit-plan.sh:538` records for exactly this decision.

Reproduced on the 2026-09-09 highper-gateway trial (trial notes, 13:56:24Z). On a 1-task backlog,
`kit-plan.sh` printed *"wrote 1 cluster pack(s) to .project/packs/default"*. The pack existed,
`task-context` step 4 loaded it (`pack_loads: 1` on the spend row), and `STATUS.generated.md` still
said *"Largest cluster in `default` holds 100% of its planned tasks. Packs are withheld"*.

**Who hits it:** every adoption whose first backlog is under ten tasks — which describes every
brownfield first run the kit has had. The report contradicts the planner on the first day an adopter
reads both.

## Acceptance criteria

- [ ] The withhold decision is made in one place. `kit-status.sh` reports what the planner decided
      instead of re-deriving it. If the rule must be evaluated twice, it lives in `kit-lib.sh`, both
      callers use it, and both read `cluster.max_share` and `cluster.min_tasks` the same way.
- [ ] One conformance step covers both directions: a 1-task backlog whose pack was written is
      reported as written, and a backlog over `min_tasks` whose pack was withheld is reported as
      withheld. A fix that flips the message for everyone then fails.
- [ ] Mutation proof: restoring the hard-coded `-gt 60` makes the step fail.

## Notes

Related, not blocking: `T-20260821-kit-plan-writes-two-meta-keys-the-indexe`, where the same meta
keys are erased by a plain reindex. A fix that makes `kit-status.sh` read `cluster_packs_withheld`
inherits that defect until it lands; a fix that evaluates the shared rule does not. Either shape
satisfies this task.

The final `kit-status.txt` in the trial's evidence directory does not show the line — a reindex had
erased the key by then. The evidence for this defect is therefore the trial notes at 13:56:24Z.

Found in the highper-gateway plugin-mode trial, kit defect K1 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

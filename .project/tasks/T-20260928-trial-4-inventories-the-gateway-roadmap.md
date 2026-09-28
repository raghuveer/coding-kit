---
id: T-20260928-trial-4-inventories-the-gateway-roadmap
title: Trial 4 inventories the gateway roadmap
epic: validation
tier: T2
state: created
---

## Intent

Run the kit's brownfield entry path end to end on highper-gateway: turn its roadmap and the
documents the roadmap names into candidate tasks, have the maintainer confirm them, file the
confirmed ones with `kit-task.sh`, and let `kit-plan.sh` order them. **No code change is made to
the subject.** The unit is an inventory, under `docs/TRIAL-INVENTORY-UNIT.md` once the operator
adopts it for this trial.

**Why this unit.** Three code-change trials have run on this subject, and all three record the
planner ordering a backlog the kit did not write as not exercised. Four of the trial root's open
criteria depend on it (`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie`: the roadmap becomes
a task inventory; the degradations with numbers, planner half; clustering on a real backlog;
defects filed before fixing). The 2026-08-24 pass produced 103 candidates and filed none, so
filing and planning have never run on a real backlog.

**Why not a code-change trial.** Upstream `e588b53` is red: its CI jobs Check, Clippy, Test and
Security Audit fail. Under PR #181's every-unit rule, a unit that fails only because a unit it
depends on failed has no verdict, so rungs 1 and 2 are `unsatisfiable` for any change on this
tree — including a change that repairs the baseline, because the before run still lacks those
verdicts. The baseline has to be repaired outside a trial before a code-change trial here can
reach one. An inventory unit runs no rung.

**What gates it.** The ladder chain (`T-20260923-baseline-and-the-ladder-call-one-fact-ba`,
`T-20260912-a-declared-rung-whose-tooling-fails-has-`,
`T-20260923-the-ladder-has-no-disposition-for-a-rung`) decides rung dispositions for a change and
is not read by this unit. **But §0's criticals gate is read, and must be zero.** On `main` it reads
5, all on K3. PR #181's branch carries **15** critical rows on K3, the other ten from its later
review chains, none marked; so after #181 merges the gate reads up to 15 until the operator
dispositions each one. That is a pre-flight box, not a `blocked_by` edge: the edge would wait for
K3 to complete, which this trial does not need. The annex also depends on #181's §3 detection, so
this trial's preparation lands after #181.

**The departure.** Running this ahead of item 4 of
`docs/design-input/2026-09-20-what-next-after-state-and-context.md` departs from the governing
order. ADR 0012 clause 3 requires the argument in the commit that departs; it is in the commit
that files this task. That document names nothing after its item 5, so once this trial runs,
clause 5 applies and a successor ordering is due.

## Rulings

The operator's words, 2026-09-28, answering proposals put to them in this session:
*"trial 4 option a"*, then *"subject option i"*, then *"go ahead with steps 2 and 3"* — where
step 2 was the operator making the rulings the proposal listed. So rulings 2 and 3 below were
drafted by the agent and approved in that phrase, not written by the operator.

1. **Subject of record: upstream `highperapp/highper-gateway` at `e588b53`.** The maintainer's
   checkout `D:/my-opensource/highper-gateway` at `4da4c07` carries 48 commits upstream lacks
   (merge-base `05c56eb`; 4 the other way), and their messages name 28 roadmap items as closed that
   `docs/planning/ROADMAP.md` at `e588b53` shows `[ ]` (sampled: UC3.A, UC12.A, UC14.A, UC15.C).
   Those closures are withheld from the researcher. That checkout is never a clone source and is
   never written.
2. **Writes into the COPY's tracked tree are allowed, as recorded trial commits made before any
   reindex.** The subject itself is never written.
3. **The researcher is a separate agent run, not the orchestrator**, and `kit-entry.sh --check`
   runs on its reply as returned, before anyone edits it.

**Rulings 4-8, given 2026-09-28** as *"Accept all as proposed"*, answering the proposals below,
which the agent drafted after reading `docs/planning/ROADMAP.md` at `e588b53` (blob `794c04e`)
through the GitHub API, not from the maintainer's checkout:

4. **`docs/TRIAL-INVENTORY-UNIT.md` is adopted for this trial.**
5. **Roadmap markers map as** `[d]` → `on-hold`, `[k]` → `cancelled`, `[x]` → `completed --via
   unknown` (unknown until `T-20260825-the-provenance-vocabulary-cannot-express` lands), and every
   candidate title begins with its roadmap id (`UC3.A ...`; `.` is allowed, `/` is refused). **The
   mapping is dormant: all 85 items at `e588b53` are `[ ]`** (41 with UC ids, 44 with §3 ids such
   as `3.1.A`); the legend at lines 37-40 defines the other markers and no item uses them. A
   candidate is `completed` only on evidence in the tree at `e588b53`.
6. **The trial root's clustering criterion is not exercisable on an imported backlog**: with no
   `Task-Id` in the subject's history there are no `touches` edges, so `cluster.min_shared` and
   `cluster.ignore_glob` add no links and clusters follow `--epic` only.
7. **The walk, the time-box and the order comparison:**
   - the maintainer judges every candidate whose disposition is not `created`, plus every 4th
     `created` candidate in roadmap order; the rest are counted as unjudged;
   - one hour with a recorded STOP / CONTINUE at the boundary, capped at two, plus the protocol's
     §0 stop rules;
   - the plan is compared with the roadmap's own order by two counts, and no rank correlation:
     (a) of the item pairs implied by its four *Dependencies inherited* lines (a §2 item after the
     §3 items it inherits), how many the plan respects; (b) among the 44 §3 items, which the
     roadmap orders by risk class (line 520: security & correctness → completeness → hygiene →
     validation → documentation), how many pairs the plan inverts, with tied pairs counted apart.
8. **The question:** *"Given `docs/planning/ROADMAP.md` (85 open items) and the documents it names
   at `e588b53`, does the kit's entry path yield candidates the maintainer confirms as real and
   correctly scoped, and does `kit-plan.sh` order them consistently with the roadmap's stated
   dependencies and risk-class order?"*

With every item open, this trial mainly tests whether candidates are real and correctly scoped,
and how the planner orders them. It says little about done-or-not claims.

## Acceptance criteria

- [ ] Pre-flight recorded before the clock per the annex §1: criticals gate zero, rulings 1-3 and
      the rulings 4-8 as given, the backlog baseline, the before-state of the maintainer's other
      checkout, the adoption shape, the researcher resolving, and spend checked in the real layout.
- [ ] The input set is named and bounded: the roadmap and each child document it names, by path
      and blob SHA at `e588b53`, recorded apart from `kit-entry.sh`'s code census.
- [ ] Every candidate cites its roadmap item, and the roadmap id survives filing in the title.
- [ ] The confirmed inventory is one committed artefact in the copy: each candidate's disposition,
      who gave it, when, and against which subject SHA.
- [ ] The gate can fail: nothing is filed without a recorded disposition, and confirmed titles
      match filed titles except for refusals recorded with their exit codes, checked by a command
      whose output is in the record.
- [ ] `kit-entry.sh` still writes no task.
- [ ] Every measure in the annex §3 is recorded with n, including the withheld-items comparison and
      the planner's layer and tie distribution.
- [ ] The outcome is labelled COMPLETE, ABORTED or VOID under the annex §2, and the record is
      committed as `docs/TRIALS/<date>-highper-gateway-inventory.md`.
- [ ] Every kit defect found is filed as a task before any of them is fixed.

## Notes

**The withheld items are a probe for false completions, not a sealed comparison.** An inventory
correct at `e588b53` marks all 28 `created`, because the only evidence they are done is in commits
that tree does not contain. So the prediction is known in advance: any of the 28 marked
`completed` without evidence at `e588b53` is a false claim. **The confirmer is not sealed**: the
maintainer who confirms is the operator who made those commits, so the annex has the confirmation
cite subject-of-record evidence, and flags those rows so the split can be read with and without
them.

**Predicted, not measured**, so the trial can confirm or refute them:
- few or no `depends_on` edges, so a layer-0 plan sorted by tier. A candidate can name another's
  future id (ids are the filing date plus the title slug, and `--blocked-by` accepts any id-shaped
  string), but the edge dangles if filing crosses a UTC midnight. Record edges proposed, filed, and
  resolving;
- a stale first `kit-plan.sh` run (`T-20260820-kit-plan-computes-the-ordering-before-re`);
- filed tasks with an empty Intent and blank criteria
  (`T-20260912-task-intent-is-free-form-and-the-two-tas`);
- titles refused for `/` (`T-20260825-the-entry-proposal-format-does-not-state`);
- `kit-init.sh` exiting 1 on this subject's `.gitignore` unless trial 3's re-include is repeated
  (`T-20260911-kit-init-prints-the-claude-remedy-when-t`);
- slug collisions among about 85 filings on one day (`T-20260822-a-truncated-slug-makes-two-different-tit`),
  counted as filing refusals.

**An incident in the maintainer's checkout, 2026-09-28**, recorded so its before-state is read
correctly: a read-only analysis ran `git fetch --dry-run` there. No ref, index or file changed, but
upstream's objects now sit unreferenced in its object store. Nothing was undone, since undoing it
is a second write; the operator decides. The annex's before-state is taken after this, so the
trial does not misread it.

Filing this task reproduced the trailing-hyphen case of
`T-20260822-a-truncated-slug-makes-two-different-tit`: the first title tried produced
`T-20260928-trial-4-inventories-the-highper-gateway-`. It was deleted before any commit and
re-filed under a shorter title.

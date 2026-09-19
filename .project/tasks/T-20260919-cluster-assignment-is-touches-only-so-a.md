---
id: T-20260919-cluster-assignment-is-touches-only-so-a
title: Cluster assignment is touches-only so a task with no commits cannot group by a shared file
epic: planning
tier: T2
paths: tooling/kit-plan.sh
state: created
---

## Intent

**Found by a blind reviewer on `T-20260817-a-cluster-pack-file-list-ignores-declare`, and filed
because that task does not cover it and neither does the other spin-off.**

That task taught a cluster pack to LIST declared paths as well as touched ones. It did not touch
how tasks are assigned to a cluster in the first place. `kit-plan.sh`'s union-find builds its
shared-file edges from `rel='touches'` alone, so a task with declared paths and no commits can
only be grouped by a shared epic or by an eventual shared `touches` edge -- never by the file it
says it will change.

**The consequence is narrower than it sounds and worth stating precisely.** The pack fix means a
declared-only task's cluster now SHOWS its declared files once the task is in that cluster. This
task is about whether it lands in the right cluster at all. Both matter and they are different
mechanisms.

**Do not read this as covered by
`T-20260919-blast-radius-for-tier-classify-still-rea`.** That one is about the blast radius
`task-context` computes for `tier-classify`. This one is about cluster membership in the planner.
Same shape -- a `touches`-only consumer left behind -- different consumer, different consequence.
The reviewer explicitly flagged that it should not be allowed to read as covered, which is why the
distinction is written here rather than assumed.

## Acceptance criteria

- [ ] Whether a shared DECLARED file groups two tasks into one cluster is decided and stated,
      rather than being answered by whichever query happens to run
- [ ] If it does group them, the asymmetry with co-change is stated: co-change is derived from
      commit history, so a declared path has no co-change neighbours and cannot widen that way
- [ ] Clustering remains stable for tasks that already have `touches` edges -- a task must not
      change cluster because a sibling declared a path
- [ ] A conformance step covers whichever answer is taken, and is proved able to fail

## Notes

Filed 2026-09-19 from the second rung-5 review of the pack change. Checked before filing: no other
task file references cluster assignment and declared paths together.

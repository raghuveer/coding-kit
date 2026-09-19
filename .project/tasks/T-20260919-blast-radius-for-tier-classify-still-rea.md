---
id: T-20260919-blast-radius-for-tier-classify-still-rea
title: Blast radius for tier-classify still reads touches only, so a task with no commits gets none
epic: planning
tier: T2
paths: skills/task-context/SKILL.md
state: created
---

## Intent

**Found by a blind reviewer on `T-20260817-a-cluster-pack-file-list-ignores-declare`, and filed
rather than folded in.** That task taught the cluster pack to read declared `paths:` as well as
`touches` edges. It did not teach `skills/task-context`, and the reviewer's point is that the
consumer it left behind is the more safety-relevant of the two.

`skills/task-context/SKILL.md` step 5 builds the **blast radius** -- the skill's own words call it
*"the reason the index carries an edge table at all"* -- and step 6 widens it through co-change.
Both query `rel='touches'` only. That output feeds `tier-classify`, which decides the review tier.

**The skill already states the symptom in its own prose:** *"`touches` edges need a `Task-Id`, so a
repository adopted brownfield has none and step 5 returns nothing at all."* So the gap is
documented and was simply left standing when the sibling gap was closed one file over.

**Why this is a task and not a line in that one.** Changing what feeds `tier-classify` changes
which tier a change is reviewed at, which is a behaviour change to the control that governs every
other control. It deserves its own tier, its own criteria and its own review, rather than riding
in on a pack-formatting change. That is this repository's own rule about filing a defect
separately from the fix that found it.

**The distinction that must survive.** A file a task HAS changed and a file it SAYS it will change
are different claims. The pack keeps them apart by printing both counts. A blast radius has no
such column today, so whatever this does must decide whether a declared path widens the radius,
raises the floor, or only annotates -- and say which.

## Acceptance criteria

- [ ] Step 5 states what a declared path contributes to blast radius, and whether it differs from
      a touched file
- [ ] If declared paths widen the radius, the effect on `tier-classify` is stated: which way the
      tier moves, and whether a declaration alone can raise a floor
- [ ] A task with a declared `paths:` and no commits gets a non-empty blast radius, or the skill
      says explicitly that it does not and why
- [ ] A conformance step covers it and is proved able to fail
- [ ] The co-change widening in step 6 is decided too -- co-change is derived from commit history,
      so a declared path has no co-change neighbours and that asymmetry needs stating rather than
      discovering

## Notes

Filed 2026-09-19 from the rung-5 review of `T-20260817-a-cluster-pack-file-list-ignores-declare`.
The reviewer noted no other filed task covered it, which was checked and held.

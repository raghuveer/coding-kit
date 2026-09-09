---
id: T-20260909-handoff-section-11-asserts-invariants-by
title: HANDOFF section 11 asserts invariants by hand and three of them are false
epic: reporting
tier: T2
lang: markdown
state: created
---

## Intent

`docs/HANDOFF.md` section 11 is headed **"Constraints that must not be broken"** and lists nine
invariants as settled fact. They are typed by hand and nothing compares them to the tree. Audited
2026-09-09 against `be2a27d` -- `.project/census/handoff-invariants-2026-09-09/` carries the
artefact, one command per claim -- **five hold and four do not**. Three of the four belong here;
the fourth has its own task already.

| line | claim | what the tree says |
|---|---|---|
| :414 | the kit never writes outside the project root | the guard matcher is `Write\|Edit\|NotebookEdit`, so Bash writes are unguarded. `SECURITY.md` section 4 **concedes this**, so two documents in this repository disagree in print |
| :418 | accelerator export is aggregate-only **by construction** | `T-20260816-the-accelerator-export-leaks-project-tex` is state `open` and says it leaks project text and its counts can be forged |
| :419 | skill **and agent** counts stay fixed | HANDOFF itself says eight agents at :199 and :288; the tree holds nine. The count moved and the constraint did not bind |

The fourth refutation -- findings carry language and defect class -- is
`T-20260909-209-of-621-findings-carry-no-language-so`, because its remedy is data recording rather
than a document.

**Why one task rather than three.** One cause, one remedy: a hand-maintained list of facts about
the tree, drifting from it silently. `docs/CHARTER.md` section 4 had the identical defect -- six
figures wrong by 2026-09-09 -- and the fix was not to correct them but to stop typing them:
*"A figure that is never typed cannot drift."* `tooling/kit-charter.sh` is the precedent and may
be the mechanism here too.

**What this is NOT.** It is not a proposal to fix the write boundary. `SECURITY.md` section 4
argues that gap cannot be closed from inside the repository, and this task takes no position on
that -- it is about a document asserting as an invariant something the security document concedes
is not one.

## Acceptance criteria

- [ ] Each of the three claims above is either made TRUE in the tree, or the sentence is corrected
      to say what actually holds. Both are acceptable outcomes and the task does not prejudge which.
- [ ] Where a claim is a count, it is **derived rather than typed**, per the CHARTER precedent -- or
      the decision not to derive it is recorded with its reason.
- [ ] A check that can fail: the invariant section disagreeing with the tree turns something red.
      Deriving the counts satisfies this for the counts; the write-boundary and export claims need
      their own answer, and a task that corrected the prose and left nothing watching it would have
      reproduced the defect.
- [ ] `SECURITY.md` section 4 and `HANDOFF.md` :414 agree, in whichever direction is true. Two
      committed documents contradicting each other on the same fact is the class
      `T-20260826-two-artefacts-carrying-one-fact-with-not` already names.

## Notes

Filed 2026-09-09 from the first census the kit has captured. Evidence is
`.project/census/handoff-invariants-2026-09-09/section-11-constraints.json`, validated against the
shipped contract: 9 claims, 0 violations, 5 `CONFIRMED` / 4 `OVERSTATED`.

The audit is repeatable and that is the point -- re-running it after this task closes should return
`CONFIRMED` on all three, and if it does not, the correction was prose.

**Task ids named above are NOT blockers**, stated explicitly because a proposed lint
(`design-input/2026-08-18-the-plan-is-the-unreviewed-artifact.md` candidate A) would otherwise
read a prose mention as an undeclared dependency. `T-20260909-the-charter-s-measured-section-is-typed-`
is the sibling of this task in a different document -- same class, same remedy, and whichever runs
first should decide whether one mechanism serves both rather than each deriving its own.

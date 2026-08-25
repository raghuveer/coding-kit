---
id: T-20260825-two-migration-md-mapping-rows-record-cap
title: Two MIGRATION.md mapping rows record capability loss as a rename
tier: T2
state: created
---

## Intent

`docs/MIGRATION.md`'s mapping table tells a reader what each 0.1 command became. Two of its
three rows describe a **reduction in capability as though it were a rename or a tidy-up**, and
nothing tests the table, so it records what was intended rather than what happened.

Re-verified against the tree on 2026-08-25, independently of the earlier check.

**Row 15 — `/resume-context` → skill `task-context`.** The stated reason is *"Claude should
reach for it at the start of work, not only when you type it"*, which is about **invocation**.
The actual change is one of **scope**, and the row does not mention it:

| | `legacy-commands/resume-context.md` | `skills/task-context/SKILL.md` |
|---|---|---|
| subject | a **session** ("Start-of-session ritual — rebuild context from files, not old conversation") | **one task** — `task-id` appears 6 times |
| git | runs `git log --oneline -15` and `git status --short` | **0 occurrences of `git`** |

So session-level orientation — where am I, what moved recently, what is uncommitted — was
dropped, and the table presents that as the same capability delivered more conveniently.

**Row 17 — `/drift-check` → "mostly retired".** The row's own escape clause is *"What survives
is narrative claims, which `status-report` covers."* It does not. `skills/status-report/SKILL.md`
has sections for escape rate, trailer discipline and deeper SQL queries, and **zero** mentions of
README, roadmap, narrative, claim, prose or HANDOFF — it reads no prose document, so it cannot
compare one against git. Grepping `skills/` and `agents/` for `STALE` or `unverifiable` returns
only `--if-stale` (a rebuild optimisation), one line of prose about the plan looking stale, and
`documenter.md` warning that copies go stale. Nothing anywhere issues a drift verdict.

The row's first half is sound and should stay: with derived state, **item-level** drift really is
structurally impossible, because `STATUS.generated.md` is regenerated from task files and
trailers. It is the second half — the claim that the remainder is covered — that is false.

**Why this matters more than two wrong sentences.** `MIGRATION.md` is the document a reader
consults to find out whether something they relied on still exists. A mapping table is a set of
claims about the present tree, and this one has never been checked against it. It is also
actively load-bearing: on 2026-08-12 a filed task
(`T-20260811-restore-session-state-from-checkpoint-co`) was about to reinvent `resume-context`,
and the operator caught it — the table had not made the gap findable.

## Acceptance criteria

- [ ] Row 15 states the scope change plainly: session orientation was **not** carried over, and
      `task-context` is task-scoped and runs no git. Whether to restore it is a separate
      decision — this criterion is only that the record stops implying it was carried over.
- [ ] Row 17 keeps the item-level-drift argument and **withdraws the claim that `status-report`
      covers narrative claims**, naming what is actually unchecked.
- [ ] Every remaining row in the table is checked against the tree in the same pass and either
      confirmed or corrected. Fixing the two already known while leaving the rest unverified
      would leave the table exactly as trustworthy as it is now.
- [ ] A check exists that the mapping table's right-hand column names things that **exist** —
      each named skill, agent, hook or script resolves to a file. That is mechanical and cheap,
      and it is the half that can be automated.
- [ ] Mutation proof for that check: point a row at a skill that does not exist and it goes red.

## Notes

**What the check can and cannot do, stated so nobody claims more later.** Existence of the
right-hand target is mechanical. *Equivalence* — whether the replacement does what the original
did — is not, and no test written here will establish it. So the check closes the "names
something that was deleted" failure and leaves the "names something narrower" failure to
review. Do not let a green existence check be read as the table being verified; if the check is
added, say so in the table's own preamble.

**Do not fold the missing capabilities into this task.** Restoring session-level orientation, and
deciding whether anything should check narrative claims against git, are separate decisions with
their own cost. This task is about the **record** being wrong. Filing the fix and the record
together is how a documentation correction quietly turns into a feature and then stalls.

The general lesson is `verify-own-claims-before-asserting` applied to a migration: a table
nothing tests will record intent, not outcome.

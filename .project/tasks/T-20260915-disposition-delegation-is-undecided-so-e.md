---
id: T-20260915-disposition-delegation-is-undecided-so-e
title: Disposition delegation is undecided so every mark resolves to the operator forever
epic: components
tier: T3
lang: markdown
paths: docs/design-input
state: created
---

## Intent

`docs/design-input/2026-08-22-auto-mode-is-a-graduation.md` §6 item 5:

> **Disposition delegation is decided** — which marks the machine may set, on what evidence, and
> which remain the human's permanently. This covers **both** kinds of mark: findings, and the
> deviation dispositions of §3.1. For deviations it also has to answer *which layer* a given person
> may accept against, since accepting one mutates a definition.

§6 calls it *"the one that is pure design"*; §7 lists it as absent from the previous roadmap.
**No task covers it**, measured 2026-09-15 across 211 task files.

**Why it is the item that actually blocks graduation.** §2 states that at graduation the controls
do not change — **their addressee does.** Every gate in the kit today resolves to the operator, and
that is correct for trust-building and is exactly what has to stop. Until it is decided which marks
a machine may set, "auto-mode" means a run that halts at the first disposition, which is not
unattended at all.

**The record already shows the shape of the problem.** `.claude/CLAUDE.md` and `kit-resolve.sh`'s
header both say the agent proposes and stops, and **nothing mechanically enforces it** — on
2026-09-10 a `--fixed` mark was set by the session that wrote the code, on the operator's direct
instruction, and the only thing carrying that fact forward is a note in three places. A rule with no
mechanism is exactly what delegation has to replace, in either direction.

**And the closing side is where the loop already breaks.** 635 findings against 79 fixed, 0 refuted
and 0 confirmed; 55 findings carry an agent id matching no spend row; a `(task, class)` pair holds
more than one finding in 604 of 635 rows. Delegating dispositions to a machine on top of a record
that cannot aim a mark at a row would automate the wrong thing — which is why this is filed and not
designed.

## Acceptance criteria

- [ ] Both kinds of mark are covered, not just findings: the finding dispositions and the
      deviation dispositions of §3.1. A decision about one that is silent about the other is
      recorded as covering half.
- [ ] For each mark it is stated whether a machine may set it, on what evidence, or whether it is
      the human's permanently — and the reason, since the reason is what a later reader needs.
- [ ] For deviations, **which layer** a given person may accept against is answered. Accepting one
      mutates a definition, and §8.2 already fixes developer authority at a task's acceptance
      criteria only, with floors and the overlay escalating.
- [ ] Nothing is built in this task. The prerequisite is a record a mark can aim at — see Notes.
- [ ] A check that can fail, when a mechanism lands: a mark set by a machine outside its delegated
      set is refused, and the refusal names which rule it breached. A delegation that cannot refuse
      is a preference, not a control.

## Notes

Filed 2026-09-15 on the operator's instruction, alongside
`T-20260915-divergence-is-computable-for-no-class-of` and
`T-20260915-no-budget-cap-binds-so-an-unattended-run`.

**Explicitly ordered behind the findings-record work.** `T-20260914-a-finding-that-was-never-a-defect-has-no`
(a disposition cannot be aimed at a row) and
`T-20260914-finding-run-ids-and-spend-run-ids-are-tw` (0 of 54 attributed findings join) are the
instruments this decision would be made against. Deciding delegation first would be deciding what a
machine may certify on a record whose marks are 95% coarser than the thing being marked.

**Pure design is the hazard, not the label.** The 2026-09-09 precedent — four mechanisms, nine blind
reviews, REJECT x7, 947 lines of prose and 0 lines of shell — is the reason this is a filing with a
stated prerequisite rather than a proposal.

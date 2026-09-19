---
id: T-20260919-task-context-routes-what-next-to-the-pla
title: task-context routes what-next to the planner, which ADR 0012 forbids
epic: planning
tier: T2
paths: skills/task-context/SKILL.md
state: created
---

## Intent

**ADR 0012 decided which ordering governs "what next" on 2026-09-18, and the skill that answers
that question was never told.**

`skills/task-context/SKILL.md`'s own `description` says it is for *"starting or resuming work on a
task ID, **or when asked what to work on next**"*. So it is the surface an agent reaches for at
exactly the moment ADR 0012 legislates about.

**Measured 2026-09-19** — `grep -n 'ordering\|ADR 0012\|governing\|what next\|kit-plan'` over that
file returns **two hits, both `kit-plan.sh`** (`:41`, `:59`), and **no mention of an ordering
document, of ADR 0012, or of any source of sequencing other than the planner.** An agent that
correctly reaches for the correct skill is therefore routed to the tool ADR 0012 excludes:

> *"A named ordering document governs sequencing; the planner does not… It is not consulted for
> 'what should I do next' on its own."*

**The ADR measured why this matters, so this is not a tidiness argument.** Over the planned tasks
the scores run one at 11.0, five at 6.0, six at 5.0, one at 4.0, then **28 tied at 3.0 and 84 tied
at 2.0**. Past about rank 13 the planner's rank is a tiebreak, not a judgement — so a skill that
hands back rank 1 returns a true statement about a sort and a false one about priority.

**This is the mechanism behind a repeated failure, not a hypothetical.** Next-task recommendations
from this repository have been refuted on re-check more than once, and each time the cause was an
ordering read from a score rather than from the governing document.

**Two further clauses have no home either.** Clause 5 — when the governing document runs out, say
so rather than falling through to the planner — matters **now**: five of the eight items in §6 of
`docs/design-input/2026-09-14-state-and-context.md` are complete as of 2026-09-19, so the document
this ADR points at is visibly running out. Clause 3 — a departure from the governing order is
argued in the commit that departs, not in a summary written afterwards — is a rule about how work
is committed and appears in no skill an agent reads.

## Acceptance criteria

- [ ] The skill names the governing ordering document as the source for "what next", and names
      `kit-plan.sh` as answering eligibility and within-selection ranking only, in ADR 0012's own terms
- [ ] A reader can find WHICH document governs today without asking the operator — the skill gives a
      path or a derivation, not an instruction to ask
- [ ] The skill states clause 5: when the governing document is exhausted, report that and stop,
      rather than falling through to the planner's rank 1
- [ ] The skill states clause 3: a departure from the governing order is argued in the commit that
      departs
- [ ] A conformance step covers it and is **proved able to fail** — break the skill's reference to
      the ordering source and watch the step go red before it is trusted. A check over prose that has
      never been shown to fail is the shape `LESSONS.md` §1 refuses

## Notes

Filed 2026-09-19 after an operator-requested re-check of the next-step set. The gap was found by
grepping the skill rather than by reading it, which is worth recording: the skill reads perfectly
well and is wrong only in what it omits.

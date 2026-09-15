---
id: T-20260915-no-budget-cap-binds-so-an-unattended-run
title: No budget cap binds so an unattended run cannot be bounded
epic: measurement
tier: T2
lang: markdown
paths: docs/design-input, tooling/kit-status.sh
state: created
---

## Intent

`docs/design-input/2026-08-22-auto-mode-is-a-graduation.md` §6 item 4:

> **A budget cap binds**, because unattended plus unbounded is the one failure that cannot be
> noticed late.

§7 moves it onto the critical path under **Rises**. **No task covers it.** Measured 2026-09-15:
eight task files contain the word "budget" and every one is something else — accelerator line
budget and eviction, cluster-pack context economics, high-stakes routing, the claim-audit budget.
None is a cap that binds a run.

**The measuring half exists and the binding half does not.** `kit-spend.sh` records per transcript,
`kit-status.sh` prices with the weight vector at `:384`, and this repository now has 166 spend
events over 80 transcripts with capture proven live. So the kit can say what a session *cost*. It
has nothing that can say *stop* — no cap is declared anywhere in the profile, and nothing reads one.

**Why it is cheap here and is not a design problem.** Unlike divergence detection and disposition
delegation, this one has a reading under it already. A cap is a number in the profile and a
comparison against a figure `kit-status.sh` computes today. The open questions are scope and
addressee — per goal or per session, and what "binds" means when the kit cannot halt a coding agent
it does not own — not whether the quantity can be measured.

**The scope boundary that constrains any answer.** The kit does not own the pipeline and cannot
stop the host: `THE KIT CONSUMES OUTCOMES; IT DOES NOT OWN THE PIPELINE` (§8.7). So "binds" most
likely means *reports a breach against a declared limit*, in the same shape as an absent limit
versus a breached limit being two finding classes (§8.6) — not a kill switch. That should be
settled before anything is built, because the two readings have very different costs.

## Acceptance criteria

- [ ] It is written down what a cap is declared against — a goal, a session, or a task — and where
      it lives. The profile is the obvious home; naming it is the decision.
- [ ] It is written down what "binds" means for an add-on that cannot halt its host, and the answer
      is reconciled with §8.7 rather than asserted past it.
- [ ] The report distinguishes **no cap declared** from **a cap declared and not breached**. A
      project with no cap must not read as a project within budget — absent-is-not-zero, applied to
      a limit rather than a count.
- [ ] A check that can fail: a fixture with a declared cap and spend past it reports a breach, and
      the same fixture with no cap declared reports the absence rather than a pass.

## Notes

Filed 2026-09-15 on the operator's instruction, alongside
`T-20260915-divergence-is-computable-for-no-class-of` and
`T-20260915-disposition-delegation-is-undecided-so-e`, after a check found three of the seven
graduation-checklist items had no task at all.

**T2 rather than T3, unlike its two siblings.** Those two decide what a machine may do unattended
and fail silently in the dangerous direction. This one is a comparison against a number the kit
already computes; its failure mode is a wrong or missing report, which a fixture catches. The tier
is a claim about review depth and is stated here so it can be argued with rather than inherited.

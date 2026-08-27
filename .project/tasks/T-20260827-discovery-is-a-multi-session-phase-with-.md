---
id: T-20260827-discovery-is-a-multi-session-phase-with-
title: Discovery is a multi-session phase with three input classes and the kit has only the single-run code half
epic: components
tier: T2
paths: skills, tooling, docs/DESIGN-NOTES.md, docs/ENTRY-PROPOSAL.md
state: created
blocked-by: T-20260814-one-entry-mechanism-brownfield-is-the-ge
---

## Provenance

**This is the operator's proposal, recorded as theirs**, made on 2026-08-27 after reviewing the
cost of the highper-gateway and aeon reconciliations. The framing below — the name *discovery
session*, the input classes, and the convergence gate — is his. What this task adds is the
comparison against what the kit already has, and the identification of which parts are genuinely
absent.

## The proposal

> Whatever code analysis is combined with the initial discussion — which may extend across
> multiple sessions and be compiled together as discovery and analysis progress — call that a
> **discovery session**. It is apt when starting a brownfield project and much more relevant for
> legacy application modernization while adopting the kit.
>
> For greenfield, even though code will not be there, documentation will: a single-page
> description, or a multi-page Scope of Work, combined with an optional detailed SRS, Figma or
> Photoshop UI/UX designs, documented test cases, and a solution document with architecture
> diagrams and high-level approach. Those are analysed and discussed on a coding agent such as
> Claude Code, with the kit's support.
>
> All three then reach a common point: **confirming the approach and strategy, considering all
> dependencies including the deployment environment across dev / UAT / pre-prod / prod scopes.**
> Tasks are derived and mapped, and the approach is reviewed — **before coding and other agents
> start their job.**

## What the kit already has, so this is not built twice

Substantial prior art. It must be read before any of this is designed:

- **`T-20260814-one-entry-mechanism-brownfield-is-the-ge`** — establishes that greenfield,
  brownfield and modernization are *three starting conditions of one mechanism*, not three
  mechanisms; that the output is a **candidate** list a human confirms before coding; and the rule
  that an **undocumented design choice is a QUESTION, not a defect**, never auto-filed as work.
  This task is a refinement of that one and is blocked by it.
- **`tooling/kit-entry.sh`** — turns a tracked tree into facts anchored to files. Writes exactly
  three artefacts and, by ADR 0001, **no task, no SQL, no index row**. That refusal is the
  structural control of the entry design and this task must not weaken it.
- **`docs/ENTRY-PROPOSAL.md` + `kit-entry.sh --check`** — the proposal format, enforced. A question
  carries no checkbox, deliberately.
- **`.project/entry-candidates.md`** — a worked example on this repository: open questions with
  evidence and blank `answer:` fields, then candidate tasks.

So the *shape* of the output, the *human gate*, and the *question-not-defect* rule all exist. What
follows is what does not.

## Gap 1 — discovery is a single run, and it is actually a multi-session phase

`kit-entry.sh` produces a snapshot. The proposal describes discovery **accumulating** across
sessions as understanding develops: a fact established on Monday, a question answered on Wednesday,
a design decision explained by the architect on Friday.

Today there is nowhere for that to live. The blank `answer:` fields in `entry-candidates.md` are
the closest thing, and they are a flat file with no notion of when an answer arrived, who gave it,
or whether the fact it rests on has since changed. A second `kit-entry.sh` run overwrites the facts
and the answers have no anchor.

**This is also the point where the two trials' most expensive lesson applies.** The
highper-gateway and aeon reconciliations together produced **792 verified claims and the kit holds
a row for none of them** — see `T-20260826-a-verified-claim-about-the-tree-has-no-a`. A discovery
phase that accumulates over sessions and cannot persist what it established will reproduce that
failure every session instead of once per trial.

## Gap 2 — greenfield's inventory is not empty, and the existing task says it is

`T-20260814` states:

> **Greenfield** | brownfield with an **empty inventory**; the overlay and the feature discussion
> carry the whole input

**That is wrong, and the correction is the operator's.** A greenfield project arrives with
substantial input — it is simply not code:

| input | what it constrains |
|---|---|
| single-page description, or multi-page Scope of Work | scope boundary, what is out |
| detailed SRS (optional) | functional surface, acceptance |
| Figma / Photoshop UI/UX designs | screens, states, flows — and by implication component count |
| documented test cases | acceptance criteria that already exist and must not be re-derived |
| solution document, architecture diagrams, high-level approach | the target design, and the decisions already made |

An entry mechanism that treats greenfield as *empty* discards all of it and asks the architect to
re-say in conversation what a document already states. The correct statement is: **greenfield has
an inventory of documents rather than an inventory of code, and it is analysed the same way — as
claims to be reconciled against each other.**

Two consequences worth naming:

1. **The reconciliation instrument the two trials built applies directly.** Its job is comparing
   documented claims against a reference. On brownfield the reference is the tree. On greenfield
   the reference is *the other documents* — an SRS against a SoW, test cases against an SRS,
   screens against a functional surface. `T-20260826-two-artefacts-carrying-one-fact-with-not` is
   the same defect class, arriving before any code exists.
2. **Binary and image inputs need a stated policy.** Figma and Photoshop are not text. Whether the
   kit reads exported artefacts, requires a text summary, or declares the input unanalysable and
   raises the tier is an open decision — and *declaring unavailable raises the tier* is the
   existing convention it should follow.

## Gap 3 — the convergence gate is named but has no content

`T-20260814` has a human gate on the candidate task list. The proposal asks for something more
specific: **approach and strategy confirmed, all dependencies considered including the deployment
environment across dev / UAT / pre-prod / prod, tasks derived and mapped, approach reviewed —
before coding starts.**

Deployment-environment scope appears nowhere in the kit today. It matters because it changes the
task list rather than decorating it: a capability that must work in four environments with
different data, credentials, scale and network egress is not one task, and the differences are
usually discovered late.

Note what this gate is **not**: it is not a new reviewer and not a new ritual. The kit already has
tiering, dependency grouping, and review at the declared tier. This is a **precondition on
entering** that machinery, and the check it needs is one that can fail — per
`a-control-needs-a-check-that-can-fail`, a gate everything passes is not a gate.

## Acceptance criteria

- [ ] **A discovery session is a first-class, resumable unit.** Facts, questions, answers and
      decisions accumulate across sessions with provenance — when, from whom, and against which
      version of the underlying fact. A re-run of `kit-entry.sh` refreshes facts **without
      orphaning or silently invalidating answers**; where a fact an answer rested on has changed,
      that is reported, not overwritten.
- [ ] **`kit-entry.sh`'s refusal to write tasks survives unchanged.** Discovery state is not a task
      list. If this task's implementation ends with the entry tooling writing a task file, it has
      failed regardless of its other criteria.
- [ ] **Document inventory is a first-class input class alongside code**, with SoW / SRS / UX
      design / test cases / solution architecture named as recognised kinds. Greenfield runs the
      same mechanism against documents that brownfield runs against a tree.
- [ ] **`T-20260814` is corrected**, not silently superseded: the "empty inventory" row is replaced
      and the change is visible in the task's own history.
- [ ] **Cross-document reconciliation is available before code exists** — the same claim-comparison
      job, with other documents as the reference instead of the tree.
- [ ] **A stated policy for non-text inputs** (Figma, Photoshop, diagrams): read an export, require
      a text summary, or declare unanalysable and raise the tier. Silence is not a pass.
- [ ] **Deployment environments are a recorded dimension** of the confirmed approach, with
      dev / UAT / pre-prod / prod expressible, and the differences between them able to generate or
      split tasks rather than being noted in prose.
- [ ] **The convergence gate can fail.** Explicit conditions — unanswered blocking questions,
      unmapped dependencies, an unreviewed approach — that hold the phase open. A gate that always
      passes is not built.
- [ ] **The gate is the human's**, consistent with every other closing decision in this kit. The
      kit reports readiness; it does not declare it.

## Notes

**Why this is worth building before more analysis is bought.** The operator's reason, recorded
plainly: the two reconciliations cost **28,081,335 BTE combined** and covered limited parts of two
projects. The intent is to get the kit into better shape from these learnings first, then deploy it
on those projects to complete the analysis and carry each implementation forward on its own
roadmap. That sequencing decision is his.

**The naming is worth keeping.** "Discovery session" is the term practitioners already use for this
phase in brownfield and modernization engagements, and adopting it costs nothing and buys
recognition. The kit's existing internal name for the code half is *entry*; these should be
reconciled rather than left as two words for overlapping things.

Evidence: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`,
`docs/TRIALS/2026-08-27-aeon-reconciliation.md`, `.project/entry-candidates.md`,
`tooling/kit-entry.sh` header (ADR 0001).

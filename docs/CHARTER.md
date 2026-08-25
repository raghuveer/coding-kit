<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Charter — the goal, what serves it, and the basis for judging it

> **Status: synthesis, 2026-08-24.** This document states the goal and the model in one place. It
> **adds no new decision**: everything here is drawn from `design-input/2026-08-22-auto-mode-is-a-graduation.md`
> §§1–21, `design-input/2026-08-16-artifact-model-and-distribution.md`, `DESIGN-NOTES.md`,
> `HANDOFF.md` and the task record, and each section says where its claims come from. Counts in §4
> were measured on 2026-08-24 against a full index rebuild.
>
> Its purpose is to make two things possible that a scattered record does not: **judging a
> competitor against this kit's goals rather than against its feature list**, and **judging the
> backlog against the same goals**.
>
> The other documents keep their jobs. `HANDOFF.md` says why the kit is built the way it is;
> `DESIGN-NOTES.md` says what is proposed on top of it; `COMPETITIVE-LANDSCAPE.md` says what else
> exists. This says what it is all *for*.

---

## 1. The goal

**Terminal goal: expedite the development of multiple software projects in auto-mode.** The kit is
the means, not the product.

Everything below is instrumental to that, and the chain is short:

1. **Auto-mode is switched on per project**, against that project's own roadmap — and **per goal**
   within it, not per repository. There is no single date on which the kit is ready.
2. **It is switched on by a person** who has judged the outcomes appropriate. So the kit's job is to
   produce **evidence that supports that judgement**, cheaply enough that judging stays affordable.
3. **A judgement needs definitions to judge against.** Where those definitions come from, and how
   they reach the work, is the whole of §3.

**What the kit is.** A coding **support kit that rides on Claude Code** — derived project state, a
task and dependency planner, risk-tiered review, and token economics. **Not an agent framework**: it
does not own an agent runtime, an orchestration engine, or a multi-agent runtime, and systems that
do are a different category rather than a competitor.

**What it is for its users.** A **tool that nurtures AI-assisted coding agents through application
development in the projects it is used in** — and, in the operator's phrase, **hidden support** to a
human-plus-AI collaboration that is as live as it was before.

## 2. Who it serves

- **The solution, application or enterprise architect**, with the **lead developer** — who together
  author the solution overlay. The second author is not ceremony: the lead developer is the one who
  knows what the team can actually maintain.
- **The delivery team**, who receive tasks with acceptance criteria and implement against them, and
  to whom the model's technology recommendations are addressed as proposals rather than decisions.
- **Whoever maintains the result afterwards**, including a team with no assistant at all. That is
  the constraint that outranks the others: **the delivered application must be maintainable without
  GenAI, by developers, as-is.** Code and docs — ADRs included — are the entire inheritance.

## 3. The model — four artefacts and one route

**The shortest statement:** *personalized solutions, with standardized tech options, for well-defined
business problems* — and the kit **made better with real experience**.

| Carries | Artefact | Standing |
|---|---|---|
| **well-defined business problems** | **Industry accelerator** — pain point → business solution → NFR requirements, in business terms, naming no implementation | shared; **candidates** an architect draws on |
| **personalized solutions** | **Solution overlay** — prose, given, project-scoped, architect with lead developer | **authoritative from the first commit**; amended by ADR and nothing else |
| **standardized tech options** | **Technology accelerator** — design-pattern usage, and which libraries satisfy it in this stack at this posture. Patterns are a **subset** of this kind, not a fourth one | shared; **guidance**, not authority |
| **real experience** | **The completion session** — lessons extracted from the kit, GenAI-assisted update, all involved roles contributing, producing a new accelerator **version** | how the standard improves |

**The kinds are directed, not parallel:** industry defines the problem → the pattern states the
obligations any implementation must satisfy → technology says how to build it in this stack. Each
layer is a translation of the one above, and the wider the reuse, the slower the decay.

**The route a requirement travels**, using a non-functional one because it is the case that used to
have no answer:

1. the **industry accelerator** says this kind of project typically expects *X*;
2. the **solution overlay** states what **this** project commits to;
3. **ADRs** carry every subsequent change — functional and non-functional alike, by the same route;
4. the **technology accelerator** says which library shape satisfies it, in this stack, at this
   posture, for the pattern the feature implements;
5. the **task** receives it as an acceptance criterion;
6. **review and auto-mode** check conformance: a breach is a finding, and a choice with no recorded
   answer is an interrupt.

**The kit owns no non-functional mechanism at any step, and the requirement still travels the whole
distance.** Non-functional criteria are project content, not kit capability.

### 3.1 Three things that constrain what may be built on this

- **Posture is a vector, not a label.** At least three axes vary independently — **scale** (a proof
  of concept versus ten thousand transactions per second), **deployment** (cloud, on-premises, or
  vendor-agnostic, which *requires* interface-first with adapters), and **lifespan** (disposable
  versus maintained for years). The business outcome can be identical across all of them and the
  stack entirely different.
- **The dimensions are illustrative, not a schema.** An architect writes them personalized per
  project and there are more than any list holds. So a template or self-check may verify **shape**
  — a pain point has a solution, a claim has its evidence, an industry entry names no
  implementation — and must **not** enumerate a closed vocabulary. *Absent from the list is not
  disallowed*, the same rule the kit already applies to counts.
- **The known set is a preference order, not a whitelist.** The model chooses among the known where
  possible, and a choice outside it is **recorded, not silent** — an ADR for a project-level choice,
  the completion session for anything that outlives the project. A model's recommendation is a
  hypothesis carrying its basis, including **the date it was made under**, because *contemporary*
  without a date silently means *as of training*.

## 4. What exists today — measured, not claimed

Facts, so that any comparison starts from what is built rather than what is designed. Measured
2026-08-24 after a full index rebuild; `STATUS.generated.md` regenerates all of it.

**Shipped and exercised**

- Plugin at **v0.11.0** — the authoritative value is `.claude-plugin/plugin.json`, and this line
  ages with it. 8 agents, 5 skills, 4 hooks, 19 tooling scripts, distributed as a plugin with
  a marketplace entry.
- **Derived state**: task files and git trailers are the truth, SQLite is a rebuildable index,
  `STATUS.generated.md` is output. Nothing that matters lives only in the database.
- **Risk-tiered review** (T0–T3) with tier floors by path, a trailer gate enforced in CI, and a
  findings record with dispositions that cannot be set by assertion alone.
- **CI**: three jobs producing **four required checks** — `trailers`, `structure`, and `conformance`
  across a `[ubuntu-latest, macos-latest]` matrix — over a **58-step conformance suite**.
- **The record itself**: 138 tasks (88 created, 13 in progress, 37 completed), 442 findings
  (42 critical, 262 major, 142 minor, 36 nit), 8 ADRs — **two of which are rejected and deliberately
  kept unedited**, so the record shows what was wrong.
- **Criticals gate: 0 actionable.** Of 42 criticals, 20 addressed and 22 excluded — 9 unassessable
  and 13 superseded. Those 22 are **not fixes** and are carried as standing blind spots.
- **One complete brownfield trial** (`TRIALS/2026-08-12-fd-throwaway.md`, sharkdp/fd, Rust, 2005
  commits) and one cost experiment (`EXPERIMENTS/2026-08-17-cluster-pack-roi.md`).

**Instrumented but without readings**

- **Escape rate is `0 / 0 via:kit` in every tier** — an absent denominator, not a clean result.
  Nothing writes `Via:` automatically; a model proposes it and a human confirms it.
- **Spend**: 10,488k billable-equivalent recorded across **2 tasks**, and **5 subagent runs recorded
  nothing at all**. Per-agent spend works only when the kit is loaded as a plugin, which is not how
  the kit itself is developed.
- **Measured on one project**, greenfield and single-stack (`MEASUREMENTS.md`, n=1 per cell).

**Designed, with a task, not built**

Named with their tasks so the backlog can be read against this charter rather than as a flat list:

| Aspect | Task |
|---|---|
| Accelerator authoring template and self-check | `T-20260811-an-accelerator-authoring-template-and-se` |
| Which mechanism produced a finding — the instrument that judges an accelerator | `T-20260808-record-which-mechanism-produced-a-findin` |
| Line budget and eviction (`refuted → stale → lowest occurrence`) | `T-20260731-accelerator-line-budget-and-eviction` |
| Library catalogue: selection and enforcement, `deploy.target` and `adapter.path` first | `T-20260801-declare-and-enforce-a-library-catalogue` |
| Cluster packs wired and measured | `T-20260808-cluster-packs-are-generated-and-read-by-` |
| Removing the kit's footprint from an adopted repository | `T-20260812-kit-init-leaves-a-footprint-in-an-adopte` |
| The retro artefact that closes the improvement loop | `T-20260811-a-retro-artefact-that-closes-the-kaizen-` |
| The brownfield trial itself, all five blockers closed | `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` |

**Not yet written, and that is a point in an iterative process rather than a gap**

The accelerator seeds — one per kind — are **drafts, not earned content**, and say so. The
constituents described in §3 are to be created, and accelerator development is iterative even when
experienced architects do it. **An accelerator's measurement is its use**: referenced from an
overlay, supported by ADRs, within a specific project's requirements.

**Named and unbuilt, with no task, and it is the load-bearing one**

**Task segregation — turning confirmed inputs into tasks.** Everything up to *confirmed
project-level inputs* is authoring; everything from auto-mode onward is machinery the kit largely
has. This is the step between, and everything built today is downstream of *a task already exists*.

## 5. The basis for evaluation

The point of §§1–4 is that a comparison can now be made against goals rather than against feature
inventories. Six dimensions follow from the goal, and they are the ones on which a competitor's
advantage is a real finding.

1. **Does the record survive the tool?** Task files, git trailers and `events.ndjson` are artefacts
   *about* the work; the product must be maintainable with no assistant at all. A system whose value
   evaporates when you stop using it fails a requirement this kit treats as ranked above the others.
2. **Is the cost measured, or asserted?** Token economics is a claim only where there are readings.
   By this test the kit currently scores on *mechanism present, denominator absent* — and says so.
3. **Is the outcome bounded without the text being fixed?** *Determinism of conformance, not of
   text*: two runs may write different code and both be correct. A system promising reproducible
   output is answering a different question.
4. **Does reuse actually cross projects?** This is the accelerator claim, and it is **not** visible
   in a single project. It is the one measurement a single trial structurally cannot produce.
5. **Does it stay hidden?** Every interrupt is the kit becoming visible; a footprint that cannot be
   removed is not hidden; resident token cost is obtrusiveness in the currency the model feels.
6. **Is it one mechanism across the three starting conditions**, or three implementations wearing
   one name?

**The baseline for all six is not an unaided team.** A competent architect writes this content in
some form already, and anyone can write prompts in different scopes and run them against different
models. So the kit's value is a **delta**, measurable in two places: whether reuse occurred across
projects, and whether the same work lands more consistently and at lower token cost than the same
people prompting directly. Neither is measured today.

**How to use this against a competitor.** An advantage on one of the six is a finding to act on. An
advantage outside them — more agents, more integrations, a bigger catalogue — is **not automatically
a gap**, and recording it as one is how a roadmap gets cut by someone else's feature list. That
error has already been made once here and corrected: `COMPETITIVE-LANDSCAPE.md` carries a banner
where a headline claim was refuted, and the memo is kept rather than rewritten.

## 6. The three starting conditions are one mechanism

**Greenfield, brownfield and legacy modernization are states of one project's life, not three kinds
of project.** A greenfield build becomes brownfield the moment anyone maintains it. So there is
**one entry mechanism parameterised by what exists at the start**: brownfield is the general case,
greenfield is brownfield with an empty inventory, and modernization is brownfield plus a source-to-
target delta carried by the overlay along with its migration strategy.

Do not build three paths. An earlier plan did, and it would have built the same thing three times.

What each still needs is a difference of input, not of machinery: greenfield has no derived context,
so the overlay is the *entire* input and is the cleanest place to prove it binds; brownfield has a
complete trial already run, whose *"not exercised"* list is the real remaining scope; modernization
adds the stack delta and stays parked by operator decision.

## 7. Open decisions

Live at the time of writing, each with where it is argued:

- **Trial or overlay first** — run the brownfield trial now, or build the solution overlay first.
- **Whether a declared short lifespan may relax maintainable-without-GenAI**, or whether that
  constraint holds regardless and lifespan only moves the stack and the abstraction budget.
- **Whether `accelerators/solution/` is withdrawn** and the overlay given its own path key —
  proposed, not made.
- **A retirement rule for an `[earned]` entry the industry moved past.** Eviction names `stale`, but
  the only written deletion rule covers seeded content that never recurred.
- **Where a project's posture is declared.** Deployment has a specified key; scale and lifespan have
  none, and one label will not carry a vector.

## 8. What this document is not

It is **not** a specification, and nothing in it is filed as work. Where it names an aspect as
designed-not-built it points at the task that owns it, and where it names something as not yet
written it says so plainly rather than as a defect. The seeded-versus-earned marking applies to this
document as much as to an accelerator: **§§1–3 are settled with the operator, §4 is measured, and
§§5–6 are `[judgement]`** — the argument for how to judge, offered to be argued with.

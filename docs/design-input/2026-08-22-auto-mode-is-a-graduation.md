# Auto-mode is a graduation, and the interrupt budget is the constraint

Design input, 2026-08-22, second of the day. Produced from a working session between the operator
and the coding agent, immediately after
`2026-08-22-competitive-comparison-and-roadmap-input.md` and correcting its framing.

That earlier document organised the roadmap around competitive gaps. The operator's response made
clear that the organising axis is different and simpler: **the kit exists to get multiple
open-source projects developed in auto-mode.** Everything else is instrumental. This document
records that goal chain, the operating model it implies, and the design questions it opens — most
of which had no home before.

Marked as before: unmarked statements are the operator's stated goals or facts about the kit;
`[judgement]` marks an opinion a future session may overturn.

**§3.1 was added later in the same session**, after the operator corrected §3's assumption that the
definitions are fixed before a run. It is marked as a correction in place rather than folded into
§3, so that the assumption and its refutation are both visible.

**§10 and §11 were added on 2026-08-24.** §10 records the operator's correction of §8.4's central
inference; §8.4 carries a banner and is otherwise left as written, so the claim and its correction
are both readable. Read §10 before acting on §7, §8.4 or §8.6. §11 records what accelerators are
for, and raises the one collision that follows from it — recency is not recurrence. §12 closes most of
that collision: versions carry currency, so no third provenance state is needed. §13 settles what an
accelerator names — a closed set of patterns over an open set of implementations.

**Nothing here is filed as a defect and nothing is marked done.** Where the reasoning implies work,
it is named as an open question with what would settle it.

---

## 1. The goal chain, recorded because it lived only in a transcript

1. **Terminal goal:** expedite development of multiple open-source projects **in auto-mode**. The
   kit is the means, not the product.
2. **Maturity is plural.** Auto-mode is switched on per project, against that project's own
   roadmap. There is no single ready date for the kit.
3. **Positioning:** an add-on used *with* Claude Code and other coding agents, by architects,
   developers and teams, from startups to enterprises.
4. **No gateway, no agent framework — because of (3), not as a preference.** An add-on that
   requires you to adopt its runtime is not an add-on. It has to sit on top of whatever the
   organisation already runs.
5. **Host sequencing:** stable as a Claude Code plugin first, then other coding agents. The
   foundation for the second was designed in deliberately over time; the deferral is intent, not
   debt.
6. **Model support, later and constrained:** the kit never selects a model. It works with whatever
   models the organisation's own AI/LLM gateway exposes to the coding agent the kit is connected
   to in that deployment. The kit must be model-*aware* — able to price and attribute what was
   used — and model-*agnostic* — unable to name what should be used.

### 1.1 Two corrections to the previous document

**LangGraph was an example use case, not a scope.** The previous document promoted it to a design
pillar (§3.1 there) on the grounds that agent applications are non-deterministic subjects. That
over-read one example into a category. The surviving residue is one finding class, not a pillar:
some acceptance criteria are distributions rather than booleans, and that will matter when finding
classes for non-functional coverage are defined. Nothing more.

**"Not a gateway" is a positioning statement, not a build-vs-buy conclusion.** The previous
document read it as "consume what exists". Goal (4) above is the actual reason and it is
stronger: it constrains what the kit may ever require of a host organisation.

---

## 2. Auto-mode is a graduation, not a mode

The operator's formulation, which is the load-bearing sentence of this whole design:

> It is only when the person sitting there sees the appropriate outcome that they can define a set
> of tasks as a goal and leave it in auto-mode.

Three things follow, and none of them is a feature flag.

**The unit of delegation is a goal, not a task.** A goal is a set of tasks with acceptance
criteria, handed over as one thing. That is a larger unit than anything the kit currently
delegates, and `goals` already exist in the schema as the milestone mechanism — with only
`default` ever used. The mechanism is present and unexercised, which is the right kind of gap.

**Trust is earned by observation, not by argument.** Nobody delegates because the design is sound;
they delegate because they watched it produce appropriate outcomes repeatedly. So the kit's first
obligation is not to be trustworthy — it is to be **legible enough that trustworthiness can be
observed**. That reframes the measurement work entirely: escape rate at `0/0`, tier floors that
have never bound, reviewers whose recall has never been tested. These are not competitive gaps.
**They are the evidence the watching human does not have**, and without that evidence graduation
cannot happen no matter how good the kit gets.

**The controls do not change at graduation; their addressee does.** Today every gate resolves to
the operator: never mark a task done, propose the disposition and stop, `Via:` is yours, findings
are marked by you. That is correct for the trust-building phase and it is precisely what stops in
auto-mode. So the transition is not "add an unattended mode" — it is deciding, control by control,
which addressee each has at which phase, and what evidence justifies the change. `[judgement]`
This is the single largest piece of unbuilt design in the kit, and it is design, not code.

---

## 3. The interrupt budget is the real constraint

The operator's second formulation:

> Too many runtime reminders are not needed, unless the system is really deviating beyond the
> discussed approach, plan, acceptance criteria and all kinds of definitions.

Read as a requirement rather than a preference, this is demanding, and it is demanding in a
productive direction.

**It says escalation must name which definition was breached.** Not "I am uncertain", not "this
seemed risky", not "confirming before I proceed" — those are the interrupts that make auto-mode
not auto-mode. A legitimate interrupt points at a recorded definition and says: *this diverged
from that.*

**Therefore the definitions must exist as checkable artifacts, not as prose in a document a model
is asked to honour.** This is the same distinction the competitive comparison found between our
computed tier floors and BMAD's prose floor — except here it is not a differentiator to boast
about, it is a precondition. Every class of definition the operator named needs a form that
divergence can be computed against:

| Definition | Where it lives today | Is divergence computable? |
|---|---|---|
| Approach | Solution overlay | No mechanism found |
| Plan | `.project/plans/`, `kit-plan.sh` | Ordering is computed; adherence is not |
| Acceptance criteria | Task files | Ticked by judgement, not checked |
| "All kinds of definitions" | Profile, tier floors, catalogue, ADRs | Floors are computed; the rest are not |

**The asymmetry to design for `[judgement]`:** silence must be cheap and interruption must be
expensive. Anything the kit notices that is *not* a divergence from a definition goes into the
record for later review rather than to the human now. This inverts the current default, where the
agent surfaces everything and the operator filters. Under auto-mode the kit must filter, and the
filter must be a named definition rather than a confidence threshold — because a confidence
threshold is exactly the thing that drifts.

**The failure mode this creates, stated so it is not discovered later:** a definition that does not
exist cannot be diverged from, so an under-specified project will run quietly and wrongly. The
interrupt rule therefore puts weight on the *completeness* of the overlay and acceptance criteria
that nothing currently checks. A silent dimension is a finding — BMAD's phrasing for its
architecture spine — and it applies here for a different and sharper reason than theirs.

---

### 3.1 Definitions accrete, and a deviation is an event with a disposition

§3 above treats the definitions as a set fixed before the run, with divergence measured against
it. **That is wrong about how inputs arrive**, and the operator corrected it in the same session.

- The **solution overlay is one input channel** from the architect and/or the lead developer. It is
  not the definition set.
- **`project-profile.md` carries an introduction and further inputs.**
- **At any point while the activity progresses, a developer may input something about a
  deviation** — and it is adjudicated: **planned, rejected, accepted as proposed, or accepted with
  changes**. Execution then continues under whatever that adjudication left standing, through the
  kit on whichever coding agent is in use.

So the governing state at any moment is an **accumulation with provenance**, not a document. Three
consequences, and the first is the useful one.

**A deviation has the same shape as a finding, so it should reuse the same machinery.** The kit
already has a disposition vocabulary where each value is a distinct claim rather than a synonym,
and where one of them is refused unless the tree carries corroborating evidence. A deviation needs
exactly that treatment one layer up — `planned | rejected | accepted | accepted-with-changes`,
each recorded with **who decided, against which definition, and on what date**. `[judgement]`
Building a second, parallel mechanism for this would be the mistake; the finding-disposition design
already solved the hard part, which is making a mark that clears a gate say why.

**"Planned" is an entry into the backlog — and that gap is already recorded elsewhere.** Turning an
accepted deviation into task rows is the same missing mechanism as brownfield entry, where
`ENTRY-PROPOSAL.md` can express exactly one disposition — a new task — and nothing turns a roadmap
into rows. **One mechanism, two callers.** That is worth knowing before either is built
separately.

**Acceptance mutates a definition, so authority is per layer.** The overlay is co-authored by the
solution architect with the lead developer and is explicitly not the coding agent's to re-open. A
developer's in-flight input therefore cannot silently amend it. **Which disposition a person may
apply depends on which layer the deviation touches** — a task's acceptance criteria, a
project-scoped floor, or the overlay itself. This is undecided, and the goal chain puts it on the
critical path: without it, an accepted deviation is indistinguishable from drift the next time
anyone reads the record.

**What this changes about §3.** An escalation is not only "name the definition breached". It is
**name the definition, propose a disposition, then either apply a pre-authorised one or queue it**.
In auto-mode nobody is sitting there to adjudicate, so the pre-authorisation rules are the whole
difference between a run that halts at the first deviation and one that finishes. That is the
addressee question from §2 arriving from the other side, and it is the same question.

**What it does not change: the invariant layer.** A deviation may amend approach, plan or
acceptance criteria. It may **not** amend what counts as a finding, a tier, or an escape — because
the accumulated record has to stay comparable across time and across projects, and graduation is
built entirely on that comparison (§4).

---

## 4. Personalisation and determinism are both required, so they must live in different layers

The operator's third point: each architect or developer using the kit works in their own style,
while some aspects of the SDLC are expected to be common — and personalisation extends to how a
person or team plans a solution.

Held next to "the kit's duty is to facilitate deterministic outcomes", that is a tension, and it
resolves only by being explicit about which layer is allowed to vary.

**Proposed layering `[judgement]` — three layers, of which the third does not exist yet:**

- **Invariant, kit-owned.** The *shape of the record*: what counts as a finding, a disposition, a
  tier, a spend row, an escape, a goal. **This may not vary by person or project.** If one
  practitioner's style can change what counts as a finding, then outcomes observed under one style
  stop predicting outcomes under another — and graduation, which is entirely built on observed
  outcomes, becomes impossible. Determinism lives here or nowhere.
- **Project-scoped.** Approach, stack, baseline patterns, tier floors, thresholds, debt strategy,
  acceptance criteria, which accelerators apply. Carried by the solution overlay and
  `project-profile.md`; authoritative from the first commit; amended by ADR.
- **Practitioner-scoped — absent today.** Working style: how much research before a decision, how
  much narration, review appetite, when to ask versus proceed, preferred decomposition
  granularity, how a person likes solution planning to run.

Today the profile absorbs some of the third layer's job and the rest lives in each session's
habits. `[judgement]` The open question is not whether to add the layer but **where its boundary
sits**: a style that changes *how work is approached* is legitimate; a style that changes *what
counts as done, found, or escaped* is the invariant layer in disguise and must be refused.

That refusal is testable, which makes it a real boundary rather than a slogan: a practitioner
setting that alters any number `kit-status.sh` reports is in the wrong layer.

---

## 5. What "deterministic outcomes" can honestly mean

Worth settling because the goal is stated in those words and the literal reading is impossible: a
language model does not produce identical text from identical input, and no overlay changes that.

**The defensible meaning is determinism of conformance, not of text.** The same inputs produce
outcomes that conform to the same definitions — the same tier floors bind, the same acceptance
criteria are met, the same finding classes are checked, the same budget holds. Two runs may write
different code and both be correct outcomes; two runs may write similar code and one be a
divergence.

The kit's stated mechanism maps onto three stages, and this is the clearest statement of what the
overlay and accelerators are *for*:

1. **Constrain before generation.** The solution overlay narrows the solution space — stack,
   baseline patterns, the architect's recorded answers, the debt strategy — so fewer decisions are
   improvised in the moment. Fewer improvised decisions is the whole of the variance reduction.
2. **Supply instead of improvise.** Technology and industry accelerators provide pre-decided
   answers that were earned on previous projects. Every answer supplied is a decision not re-made,
   and re-made decisions are where two runs diverge.
3. **Verify after.** The record shows conformance: tiers, findings, dispositions, spend, escapes.
   This is the stage that produces the observable outcomes graduation depends on.

Constrain → supply → verify. `[judgement]` Stage 1 exists as a concept with its authorship settled
and its content per project. Stage 2 exists as a concept with an earning ladder and no
distribution mechanism. Stage 3 is the most built and the least exercised. The order of maturity is
the reverse of the order of use, which is worth knowing when sequencing.

---

## 6. What graduation requires, per project

Since maturity is plural, this is a checklist a project passes, not a milestone the kit reaches.
`[judgement]` — offered as a first draft to argue with, not as a standard:

1. **The definitions exist.** Overlay present; acceptance criteria on every task in the goal; tier
   floors populated. A project cannot be run unattended against definitions it does not have.
2. **Divergence is computable** for each class of definition, and has been **proven to trigger** at
   least once. An escalation path that has never fired is not known to work.
3. **The controls have readings.** Escape rate has a denominator; floors have bound; reviewer
   recall has been measured against something planted rather than found.
4. **A budget cap binds**, because unattended plus unbounded is the one failure that cannot be
   noticed late.
5. **Disposition delegation is decided** — which marks the machine may set, on what evidence, and
   which remain the human's permanently. This covers **both** kinds of mark: findings, and the
   deviation dispositions of §3.1. For deviations it also has to answer *which layer* a given
   person may accept against, since accepting one mutates a definition.
6. **The goal is expressed as a goal**: a named set of tasks with acceptance criteria, not a
   backlog to be interpreted.
7. **A stop condition and a resume path exist**, so that halting is a defined outcome rather than
   an abandoned run.

Item 2 is the one with no mechanism at all today, and item 5 is the one that is pure design. Those
two are the graduation blockers `[judgement]`; the rest are work whose shape is already known.

---

## 7. How this re-sequences the previous document's roadmap

The earlier roadmap was cut by competitive gap. Re-cut by the goal chain, the same items land
differently and some change priority sharply:

- **Rises:** getting readings into existing instruments (§2 — it is the evidence for graduation,
  not a marketing claim); the budget cap (§6.4, now on the critical path); model-capability instead
  of model identity (goal 6 makes it structural — an agent naming a model is unrunnable in a
  deployment whose gateway exposes different ones); accelerator distribution (the reuse mechanism
  across *multiple projects*, which is the terminal goal, rather than a feature Spec Kit happens to
  have).
- **New, and absent from the previous roadmap entirely:** divergence detection (§3); disposition
  delegation (§2, §6.5); the practitioner layer (§4); goal-as-unit-of-delegation (§2).
- **Falls:** host portability, which is a deliberate later phase (goal 5) and was wrongly framed as
  a gap; the agentic-subject pillar, demoted to one finding class (§1.1).
- **Unchanged:** finish the brownfield trial first. It was the right next step under the
  competitive framing and it is the right next step under this one, for a better reason — it is the
  first end-to-end observation of outcomes on a project nobody on this side wrote, which is exactly
  the evidence §2 says graduation is built from.

---

## 8. Decisions taken in this session

Five answers from the operator, recorded with what each closes and what it leaves open. Where a
decision needed a boundary the operator did not draw, the boundary below is **proposed, not
decided**, and is marked as such.

### 8.1 The audience spans seniority, and that is why supply matters

> Wanted to make this coding kit available to developers, seniors to juniors, who may find
> optimistic outcomes based on provided project inputs, solution overlay etc.

This sharpens §5's middle stage from a claim about efficiency into the actual value proposition.
**Accelerators and the overlay are the seniority-levelling mechanism**: every decision they supply
is a decision a junior does not have to improvise and a senior does not have to re-make. "Reuse
across projects" undersells it — the same mechanism that reduces variance between two runs reduces
variance between two people.

`[judgement]` Two consequences follow that were not obvious before. **Legibility (§2) has to be
stronger than for an expert audience** — a junior cannot be relied on to know what to look at, so
the kit must surface the checks rather than assume the reader will think of them; this is the
argument for §8.4 below. And **the overlay's completeness matters more**, because §3's failure mode
— an under-specified project running quietly and wrongly — lands hardest on whoever has least
context to notice.

### 8.2 Deviation authority: task acceptance criteria only

A developer adjudicates deviations **against a task's acceptance criteria and nothing else**.
Project-scoped floors and thresholds, and the solution overlay, escalate to whoever owns them.

Closes the first open question of §3.1. It is also the answer that composes with §8.1: it is the
same rule for a junior and a senior, so authority does not have to be reasoned about per person,
and §8.5's deferral of the practitioner layer costs nothing.

### 8.3 Uncertainty default: tier decides, and the rest batches

The operator placed this between "decide by tier" and "batch and ask once". Both, composed:

- **Tier decides whether an uncertain call can wait.** T0 and T1 surface immediately; T2 and T3 are
  recorded and carried.
- **What can wait is batched to one question per goal**, rather than one interruption per event.

`[judgement]` — **proposed boundary, not decided.** Two additions that seem to follow and need
confirming: anything touching a layer the current adjudicator has no authority over (§8.2) surfaces
immediately regardless of tier, because batching a question nobody present can answer only delays
it; and a budget threshold breach surfaces immediately for the same reason it is on the graduation
checklist — unattended plus unbounded is the failure that cannot be noticed late.

The important property is that this adds **no new dial**. The interrupt budget binds to the tier
machinery that already exists, which means it is calibrated by the same decision an operator
already makes per task.

### 8.4 What "appropriate outcome" means — and it includes non-functional conformance

> **CORRECTED 2026-08-24 — see §10.** The conclusion below, that non-functional coverage is a
> **graduation prerequisite for the kit**, is withdrawn. Non-functional criteria are project
> content: the architects state them in the solution overlay and the ADRs refine them. The
> observation about what a developer inspects still stands; the inference from it does not.

Asked what a developer inspects beyond unit and integration tests, the operator named **all four
offered signals** — runs it and exercises the behaviour; reads the diff and the reasoning; checks
against the plan and acceptance criteria; looks at what it chose *not* to do — **and added a
fifth**:

> latency within prescribed limits, functional and security guidelines compliance in code etc.

**This is the most consequential answer in the session `[judgement]`, and it re-prioritises the
roadmap.** The chain is short and hard to escape: graduation depends on a person judging outcomes
appropriate (§2); that judgement includes non-functional conformance; the kit has **no mechanism**
that makes an absent or breached non-functional requirement visible — it was the dimension where
the competitive comparison found us furthest behind a stated goal. So **non-functional coverage is
not a mid-term improvement. It is a graduation prerequisite**, and it moves ahead of most of what
the earlier roadmap put in front of it.

Three of the five signals also happen to be things the kit could surface rather than leave to
inspection: conformance to plan and acceptance criteria, what was deferred or silently decided, and
non-functional limits. The other two — running the thing, reading the reasoning — stay human, and
should. `[judgement]` The design target is not to replace the inspection but to make the three
mechanisable ones cheap enough that attention is left for the two that are not.

### 8.5 The practitioner layer is deferred

Not needed yet. §4's three-layer model stands as analysis; its third layer is **parked by operator
decision**, not left open. Ship the invariant and project layers first and let the trial say
whether style ever needs to be represented.

Recorded here so a later session does not re-open it as an oversight — and note that §8.2 is what
makes the deferral cheap, since authority does not vary by person.

### 8.6 An absent limit and a breached limit are two finding classes, not one

Operator decision. They differ on four axes, which is why severity would not have carried it:

| | Absent limit | Breached limit |
|---|---|---|
| Subject | a **definition** that does not exist | an **artifact** that violates one |
| Authority | escalates — a limit is project-scoped or overlay-scoped, so it is above the developer's §8.2 authority | the developer's, against the task's criteria |
| Timing | detectable **before any code is written**, at entry and planning | detectable only after the artifact exists |
| Resolution | a human **supplies an input**, or records that it does not apply | the code changes |

**The absent one is the dangerous one in auto-mode, and this is the point of separating them.** A
breach is loud: a check fails. An absence is silent, because nothing failed — nothing was checked.
That is §3's named failure mode exactly — *a definition that does not exist cannot be diverged
from* — and it now has an instrument attached to it instead of only a warning.

**It generalises past latency `[judgement]`.** Absent-versus-breached is a pattern, not a
non-functional special case: absent acceptance criterion versus failed one, absent security
guideline versus violated one, absent tier floor versus below-floor. The kit already applies this
principle to *counts* — an absent denominator is reported as absent rather than as zero, and the
below-floor section says when no floors exist. **This is absent-is-not-zero applied to definitions
rather than to numbers**, and treating it as one idea rather than two is what keeps it consistent.

**And it gives accelerators a second job.** For the kit to say a limit is *missing*, it needs a
basis for expecting one — and what a given kind of project ought to specify is precisely what a
technology or industry accelerator carries. So an accelerator does not only **supply pre-decided
answers (§5, stage 2); it defines what must be specified at all.** `[judgement]` That is a
stronger reason to build accelerator distribution than reuse was, and it puts accelerators on the
path to the §8.4 prerequisite rather than beside it.

**Resolution reuses the guard design, and must.** An absent limit can be legitimately absent — a
CLI tool has no latency SLO. So it resolves two ways: the limit is supplied, or it is recorded as
not applicable **with a reason**. The second is the same shape as the existing marks that clear a
gate while saying why, and it should not grow a fourth spelling of that idea. It also means an
absent-limit finding resolves through §3.1's deviation adjudication rather than through a code
change, which is the first place the two mechanisms touch.

### 8.7 Work happens outside the kit, and it is still the evidence graduation is judged on

Operator context, given as examples of the kind of collaborative work already happening — and
therefore of where coordination, not capability, is the thing to remove.

- **Tests including load tests have been run with Claude's support**, before the kit existed.
- **Some testing is performed outside the kit's scope**, by developers and testers.
- **Most applications here were built with Claude Code before the kit's sub-agent scenario existed,
  including deployment to Rancher Desktop and to cloud.**
- **Accelerator distribution and the absent-limit check may land together** (§8.6's open question,
  now closed), and **accelerators evolve over time** rather than arriving complete.

Five things follow, and the first is a scope boundary worth stating before it gets crossed.

**The kit consumes outcomes; it does not own the pipeline.** §8.4 makes latency-within-limits part
of judging an outcome appropriate, and that cannot be judged without running something somewhere.
The temptation is to have the kit orchestrate test and deployment. It should not: an add-on that
requires you to adopt its pipeline is the same mistake as one that requires its runtime (goal 4).
`[judgement]` **The kit's job is to record that a load test ran, against which limit, with what
result — not to run it.**

**Therefore outside-the-kit results are a first-class ingest problem, not an edge case.** A
tester's result and a load test run in a session the kit never saw are exactly the evidence the
watching human weighs. If they cannot land in the record, graduation is judged on partial
evidence — and partial in the worst way, because the missing parts are the ones the operator named
first. This is the same principle `Via:` already encodes for work provenance (`kit`, `agent`,
`manual`, absent meaning unknown), applied to results rather than to authorship;
`docs/ADAPTERS.md` and the `ingest.*` contract are where it belongs, and
`T-20260814-a-reviewer-s-verdict-and-narrative-are-d` already covers recording bounded facts
agents return.

**Less coordination, not fewer activities `[judgement]`.** The examples are not a list of jobs for
the kit to absorb. What they have in common is **relay**: a load test result reaching whoever
decides, a tester's finding reaching the developer, a deployment outcome reaching the plan. The
kit removes coordination by **making the record the shared surface**, which is a much smaller claim
than automating the activities and is the one consistent with being an add-on.

**An evolving accelerator forces the absent-limit check to declare its own coverage.** If an
accelerator knows three of the ten limits a kind of project should carry, the check can only find
three absences — and reporting "no absent limits" would be exactly the green-that-cannot-fail this
project has recorded before. So the check must state its basis: which accelerator, at which
version, covering how many dimensions. **That is absent-is-not-zero applied a third time — to the
checker's own coverage** — and it is what keeps the check honest while accelerators are still
young.

**And the loop closes: a limit a human supplies that the accelerator did not ask for is a candidate
accelerator entry.** That is how an accelerator earns content from use rather than from
authorship, which is the ladder that already exists. It also means the absent-limit check gets
better precisely by being run on projects, which is the right incentive.

### 8.8 A result is evidence when it carries its input; deployment stays outside

Two operator answers that resolve §8.7's open questions, and the first is lighter and better than
what was proposed.

**Evidence is the input and the outcome together.**

> While quoting a number is easy, I always tend to provide input and outcome result accordingly.

The proposal in §8.7 was that a result should name its producer and point at a surviving artifact.
That is heavier than necessary and aims at the wrong property. **A number alone is an assertion
because nothing says what it measured** — a latency figure without the load profile cannot be
compared to a limit, re-run, or contradicted. With the input beside it, it can be all three, and a
tester who ran a script can supply it without a harness.

`[judgement]` This also **subsumes the environment question**: where a result was produced is part
of the input that produced it, so it needs no separate representation. And it is the same rule this
project already applies elsewhere in a different costume — a mark that clears a gate must say why;
a count must say what it counted; **a result must say what it measured.**

**Deployment is not an event the kit should carry.**

> CI is being triggered, right. Similarly deployment on local system after changes and testing on
> local servers on laptop, or remotely. How explicitly it comes into the coding kit, I say not too
> much — that activity happens through Claude Code, and it may be something else in future, and it
> can be different for someone else. It all depends on how much the developer trusts coding agents
> and entrusts responsibility accordingly while they take care of the rest.

So: **no deployment event class.** An outcome measured against a deployed thing is a result like
any other, and §8.8's first half already carries where it ran.

**And this generalises graduation in a way §2 did not `[judgement]`.** Trust is **per activity and
per agent**, not a global setting. A developer entrusts deployment to the coding agent to whatever
degree they have decided, independently of whether they have graduated the kit on task execution,
and two developers will draw that line differently. The design consequence is concrete: **the
kit's checks must never assume who or what performed an activity.** They consume the outcome
whoever produced it — an agent, a person, or CI — which is the same shape as reporting escape rate
over every population rather than only over `via:kit`.

---

## 9. Open questions this document does not answer

- ~~Where the practitioner layer's boundary sits~~ — **closed by §8.5**: parked, not open.
- ~~Which authority may accept a deviation against which layer~~ — **closed by §8.2**: task
  acceptance criteria only, the same rule for every seniority.
- What evidence justifies moving a control's addressee from human to machine, control by control.
- Whether the two additions proposed in §8.3 hold — immediate surfacing when the adjudicator lacks
  authority over the layer, and on a budget threshold breach.
- ~~Whether a breached limit and an absent limit are the same finding class or two~~ — **closed by
  §8.6**: two.
- ~~Which non-functional dimensions get a mechanism first (§8.4)~~ — **withdrawn by §10.2**:
  the kit does not own the dimensions. What remains is §10.4's goal-readiness gate.
- ~~Whether an absent-limit check can run before an accelerator exists to say what should be
  present~~ — **closed by §8.7**: they may land together.
- ~~What minimum makes an outside result evidence rather than a claim~~ — **closed by §8.8**: the
  input that produced it, travelling with the outcome.
- ~~Whether a deployment is an event the record should carry~~ — **closed by §8.8**: no. Only
  outcomes, and their environment rides in the input.
- What *carries* an input-and-outcome pair in practice — a trailer, an ingest adapter, or a file a
  tester writes — which is now a shape question rather than a sufficiency one.
- ~~Whether the two-state provenance rule survives content whose subject expires~~ (§11.3) —
  **largely closed by §12.2**: the version carries currency and the state carries observation,
  so the two are orthogonal and no third state is needed. What remains is narrower and is the
  next entry.
- **There is no rule for retiring an `[earned]` entry the industry moved past** (§12.3). The
  eviction order already names `stale`, but it was argued from context cost, and the deletion
  rule that exists covers only seeded content that never recurred.
- ~~Whether phase-out applies to a design pattern or only to the open-source solution named
  under it~~ (§12.5) — **closed by §13.1**: the pattern is the stable unit, the
  library-and-version binding is the perishable pointer.
- Whether a library chosen outside the known set is surfaced as an interrupt in auto-mode, and
  at what threshold (§13.5). The machinery exists; the population is new.
- Whether an accelerator points at a library's release channel or copies its versions
  (§13.4) — which decides whether an accelerator version bump means an editorial act or a
  dependency patch.
- Whether the accelerator update produced at project completion (§11.2, §12.4) lives in the retro
  artefact or somewhere of its own.
- Whether divergence detection is one mechanism across all definition classes or one per class.
- Which authority may accept a deviation against which layer (§3.1), and whether that is expressed
  as a role, a person, or a rule in the profile.
- Whether the deviation vocabulary is literally the finding-disposition mechanism reused, or a
  sibling sharing its guard design — and what the corroborating marker is for
  `accepted-with-changes`, which is the value that most easily launders a silent amendment.
- Whether "planned" and brownfield entry can share one roadmap-to-task-rows mechanism, given both
  need it and neither exists.
- What a stop condition looks like that is not simply "an error occurred".
- Whether goals-as-delegation-unit needs anything beyond the `goal` rows that already exist.
- How a team shares an overlay — the style half of this is parked by §8.5, but the team story
  itself is not designed.
- What a junior developer sees that a senior does not need (§8.1), and whether that is extra
  surfacing or the same surfacing with more explanation.

---

## 10. Amendment, 2026-08-24 — the kit is a tool, and non-functional criteria are project content

Operator statement, given after reading §8.4 and correcting it. Recorded here as an amendment
rather than folded into §8.4, so that the claim and its correction are both visible — the same
treatment §3.1 gave §3, and the banner on `docs/COMPETITIVE-LANDSCAPE.md` §3.

### 10.1 The scope statement, in the operator's terms

> The coding kit is a **tool**, that works as a **nurturing mechanism**, to have AI-assisted coding
> agents fast-track application development — brownfield, greenfield, legacy application
> modernization — **in the projects it is used in**.

And the authoring chain that surrounds it:

> **Solution architect / application architect / enterprise architect, with the lead developer,
> provide the inputs that constitute the solution overlay. All subsequent discussions and derived
> changes are documented in ADRs.**

Neither sentence is new policy. Both restate what
`2026-08-16-artifact-model-and-distribution.md` already records — the overlay is *given before the
project starts, amended by ADR, authoritative from the first commit, not the coding agent's to
re-open* — and what the scope boundary has said since 2026-08-14: this is a support kit riding on
Claude Code, not an agent framework. What they do is settle which side of the boundary a
non-functional requirement falls on.

**It falls on the project's side.** Latency limits, security guidelines, compliance obligations and
the rest are **content the overlay carries and the ADRs refine** — stated by the architects for the
project at hand, or absent because the project has no such obligation. They are not capability the
kit must possess before any project can be run.

### 10.2 §8.4 is withdrawn as a prerequisite claim

§8.4 took the operator's fifth inspection signal — *latency within prescribed limits, functional
and security guidelines compliance in code* — and concluded that **the kit** needs a non-functional
mechanism before graduation, moving it "ahead of most of what the earlier roadmap put in front of
it". That inference is the error, and it is a category error rather than a wrong priority: it
converted **project content into kit capability**.

Withdrawn with it:

- the §7 re-sequencing that placed non-functional coverage ahead of the existing roadmap;
- the §9 open question *"which non-functional dimensions get a mechanism first"*, which only exists
  if the kit owns the dimensions. It does not. What survives of that question is narrower and is
  stated in §10.4.

The **observation** in §8.4 stands and is not withdrawn: a developer judging an outcome appropriate
does weigh non-functional conformance, and three of the five signals are mechanisable while two are
not. What changes is who supplies the standard being conformed to.

### 10.3 What survives untouched

- **§6 item 1 — the definitions exist.** Overlay present, acceptance criteria on every task in the
  goal, tier floors populated. This was always a *per-project* checklist rather than a kit
  milestone, so it carries the corrected model rather than contradicting it. If a project's
  architects put a latency limit in the overlay, item 1 already requires it to be present before
  that project runs unattended — with no kit-level non-functional feature involved.
- **§3.1** — a deviation is an event with a disposition.
- **§2, §5** — graduation is per project, judged on outcomes.
- The thirteen prerequisites for unattended operation in `2026-08-16` §5, in four groups. Note that
  non-functional coverage was never among them; §8.4 added it from outside that list.

### 10.4 What §8.6 narrows to, and the residual mechanism

§8.6 split *absent limit* from *breached limit* and gave accelerators a second job: **defining what
must be specified at all**, which it called "a stronger reason to build accelerator distribution
than reuse was".

That second job is downgraded. Under the corrected model the **overlay and the ADRs** decide what
applies to a project; an accelerator may **offer candidates into overlay authoring** — a checklist
an architect draws on — but it does not create an obligation the kit then enforces. The two finding
classes remain worth distinguishing, because they still differ on subject, authority, timing and
resolution. Their *source of expectation* moves from the accelerator to the overlay.

**The consequence, stated rather than discovered later `[judgement]`:** if a non-functional
requirement exists only where the overlay or an ADR puts it, then the kit can detect a **breach**
of a stated limit but never an **absence**. Absence moves upstream, to overlay authoring and ADR
discussion — both human, both already the architects' responsibility. That is a deliberate transfer
of risk out of the kit and into the authoring chain, and it is consistent with §10.1: a tool that
nurtures does not invent the project's obligations.

What remains for the kit is smaller and better shaped than "non-functional coverage". In the
operator's words, the kit takes implementation forward for set-defined goals in its own scope,

> ensuring all dependency-related queries are cleared, for chosen tasks with respect to that goal

— a **goal-readiness gate before auto-mode is enabled**: every task in the goal has its acceptance
criteria resolved, including whatever the overlay and the ADRs imposed on it, with open questions
cleared rather than carried into an unattended run. Where a limit applies and is stated, it reaches
the task as an acceptance criterion like any other, and §8.2's authority rule already covers who
may accept a deviation from it. No new vocabulary is required for the non-functional case.

This is the part of §8.4 worth keeping, and it is **not** filed as work here.

### 10.5 The collaboration model this states, end to end

Recorded because §8.4's error came from having the chain only partly written down:

1. The architects — solution, application or enterprise — **with the lead developer** supply the
   inputs that constitute the **solution overlay**. This is where a tech-stack override to a
   specific software mandate is expressed, whether it originates as the architect's recommendation
   or as the client's preference for that project.
2. **Discussion absorbs details and changes, and produces ADRs.** The overlay is amended by ADR and
   by nothing else.
3. The **kit takes implementation forward** for goals defined within its scope, having cleared the
   dependency questions for the tasks chosen against that goal.
4. **Auto-mode is enabled** to complete the work.
5. **Intervention needs that are prominent enough trigger the human anyway**, through notifications
   and prompts — which is §3's interrupt budget and §8.3's uncertainty default, not a new mechanism.

Step 1 **amends** the authorship row in `2026-08-16-artifact-model-and-distribution.md` §1, which
names only the *solution* architect with the lead developer. The role is wider: application and
enterprise architects author the overlay on the same footing. Nothing else in that row changes.

### 10.6 What this amendment does not settle

**The trial-versus-overlay fork stays open.** The chain in §10.5 places the overlay upstream of
everything the kit does, which reads like an argument for building it first — but
`2026-08-16` §5 explicitly lists the solution overlay as **not** a prerequisite for unattended
operation, while its §4 says to prove the overlay against greenfield first. Those are different
goals, not a contradiction, and conceptual upstream is not build order. This amendment corrects a
category error; it does not choose a next task.

---

## 11. Amendment, 2026-08-24 — accelerators carry technology evolution, and some are written by hand

Operator statement, given after §10:

> Accelerators can be **human-written** in some scenarios. Improvements are derived **after
> completion of each project**, to update the accelerator. Accelerators are the **result of
> technology evolution**, and that **guides the implementation** through the coding kit. The
> solution overlay **references tech stacks and different accelerators**.

Three of those four are already recorded and are confirmed rather than changed. The third breaks
an assumption the record depends on, and that is the substance of this section.

### 11.1 Already recorded — confirmed, not new

- **Human-written accelerators are already legitimate.** `docs/DESIGN-NOTES.md`, *"Sources are
  many; states are two"*, lists three sources and two of them are human: an accelerator supplied
  from work delivered outside this kit, and best practice gathered from public material, analysed
  by an agent, **then discussed with the architects who maintain accelerators**. The 2026-08-16
  table says the same in one line — *earned across projects, **or seeded from architect input***.
  What is missing is not permission but **a repeatable shape**:
  `T-20260811-an-accelerator-authoring-template-and-se` (T1, open) is the template plus self-check
  that would make two accelerators written months apart by different people interchangeable.
- **The overlay references stacks and accelerators.** Unchanged: the overlay names which
  accelerators apply, `project-profile.md` binds them to paths and agents, and subsequent changes
  are recorded as ADRs.
- **Accelerators guide implementation** — consistent with §10.4 provided one distinction holds:
  **an accelerator guides, the overlay decides.** §10.4 removed the accelerator's power to create
  an obligation the kit enforces; it did not remove its role in shaping how the work is done.
  Guidance is not authority, and keeping those apart is what makes §10.4 and this statement
  compatible rather than contradictory.

### 11.2 New: the promotion ladder has rungs but no clock

The ladder is expressed in counts — one occurrence, then a project overlay at ≥N within one
project, then a shared accelerator at ≥1 in ≥2 projects. Nothing in the record says **when** it is
walked. The operator's answer supplies that: **at the completion of each project**, improvements
are derived and the accelerator is updated.

That makes the update a **defined event with a place to live**, and the place already has a task —
`T-20260811-a-retro-artefact-that-closes-the-kaizen-`. If the retro is where the accelerator
delta is produced, the retro stops being a summary and becomes the mechanism's write step.
`[judgement]` Otherwise the update has no home and happens when someone remembers.

### 11.3 Where this collides with the record: recency is not recurrence

`docs/DESIGN-NOTES.md`, *"Two provenance states, not three"*, is explicit:

> Resist a third tier for "expert-provided". The operational question is only *has this system
> observed it*, and an experienced architect's judgement is still a hypothesis until the findings
> table agrees.

That rule assumes **the claim does not expire**. Accelerators as *the result of technology
evolution* are exactly the class where it does, and the assumption fails in both directions:

- A **true current** claim — a framework's API changed at this version, an idiom is now deprecated,
  a default became unsafe — **cannot be earned by findings** unless projects happen to trip over
  it. It is correct and it sits at `[seeded]` indefinitely.
- A **stale** claim can be `[earned]` from projects that ran before the technology moved, and be
  **wrong now**. The accumulated evidence is precisely what makes it look trustworthy.

So for this class the truth condition is **recency against the technology**, not **recurrence
across projects**. The two-state rule is not wrong — it is scoped to claims that do not expire, and
that scope was never stated because nothing had raised a class that does.

**This is not settled here.** Three shapes are visible and the operator has not chosen between
them:

1. **A third state.** Cheapest to describe, and the thing DESIGN-NOTES explicitly resists. Listed
   for completeness, not recommended `[judgement]`.
2. **An `as-of` on entries whose subject moves**, so `[earned]` can *lapse* rather than needing a
   new state. This reuses the kit's own absent-is-not-zero rule at the level of dates: an entry
   with no `as-of` is not current, it is **undated**, and should read that way. `[judgement]`
   Probably the cheapest that keeps two states.
3. **Split accelerator content by whether its subject expires** — failure shapes recur, version
   facts expire — and apply the two-state rule only to the first. Most honest, most work.

**What would settle it:** one real accelerator whose subject moved between two projects that used
it. The brownfield trial cannot produce that — it needs the *same stack twice, months apart*, which
is the first thing the terminal goal's multiple-projects premise actually supplies. Until then this
is reasoned, not observed.

**One knock-on to note, not to act on.**
`T-20260814-the-promotion-ladder-has-no-gate-so-an-a` was filed because an accelerator can be
promoted on opinion. If human authorship is first-class for the evolution class, that gate needs a
**second rule rather than a stricter one** — a hand-written entry is opinion by construction, and
the check that catches an ungrounded promotion is not the check that keeps a version fact current.

### 11.4 Status

Nothing here is filed as work, and nothing is marked done — same as the rest of this document. §11.3
is recorded as an open question with what would settle it, which is the only honest state for it
while the kit has run one stack once.

---

## 12. Amendment, 2026-08-24 — versions carry currency, and the update happens at project completion

Operator statement, given after §11 and answering most of §11.3:

> Accelerators **do have versions**. Be it best practices or other, **some get phased out when
> industry evolves**, with new design patterns addressing the evolving problem space. After every
> project completion, **lessons learnt will be extracted from the coding kit**, then **with use of
> GenAI the accelerators are updated**, by providing the extracted lessons from that specific
> project and **inputs from the solution architect, the lead developer and all involved roles**.
> Re-usable assets development is **out of scope** — required ones will be created, while
> **existing open-source solutions are represented in the accelerators with respect to the specific
> design patterns in use**.

### 12.1 Versioning already exists, and now carries a second job

`docs/DESIGN-NOTES.md` §3 already specifies it: frontmatter carrying `id`, `version` and `source`
**alongside** the per-line `[seeded]`/`[earned]` marking; `kit-accel.sh import <id>@<version>`
pinning into a project; an imported copy keeping its version header so that a year later *the file
itself answers which version this project was reviewed against*. Accelerators version independently
of the plugin, because content that improves after every project would otherwise churn the engine's
version.

All of that was justified as **drift protection** — a project pins and stays put. The operator's
statement gives the same field a second job: **the version is what carries currency**. Phase-out is
a change between versions, not a new kind of claim.

### 12.2 §11.3 resolves, and without a third provenance state

The collision in §11.3 was that recurrence cannot confirm a technology-currency claim, and past
recurrence can make a stale one look confirmed. With versions carrying currency the two concerns
separate cleanly, and it is the same shape as *"sources are many; states are two"*:

| Question | Answered by |
|---|---|
| **Has this system observed it?** | the provenance state — `[seeded]` / `[earned]` |
| **Is it still true of the technology?** | the accelerator **version**, and what that version still contains |

They are **orthogonal**, so `DESIGN-NOTES`' resistance to a third tier holds and none of §11.3's
three shapes is needed as stated. What was actually missing was never a state. It was a
**retirement step** — and that step turns out to exist already.

### 12.3 The retirement step exists, filed under the wrong motivation

`HANDOFF.md` §8, quoted in `DESIGN-NOTES` under *"Line budget is a prerequisite, not a follow-up"*,
already names the eviction order:

> refuted → **stale** → lowest occurrence

with an open task, `T-20260731-accelerator-line-budget-and-eviction` (T2). But the argument made
for it is **context cost**: a library that only ever adds eventually costs more per invocation than
the defects it prevents, multiplied across every project that pins it.

The operator's framing supplies a second and stronger reason. **An entry phased out by industry
evolution is wrong, not merely expensive.** Two consequences follow `[judgement]`:

- Eviction cannot be tuned purely by budget pressure. `stale` has to be able to fire **when the
  budget is comfortable**, because its trigger is the technology moving, not the file growing.
- The order stops being a priority list of things to drop and becomes two mechanisms sharing a
  verb: `refuted` and `stale` are **correctness** removals; `lowest occurrence` is a **cost**
  removal.

**The residual gap is narrow and worth stating precisely.** `accelerators/README.md` already has a
deletion rule for *seeded* content — *"a seeded entry that never appears in findings across several
projects is scar tissue for a wound nobody has — delete it"*. There is **no rule for retiring an
`[earned]` entry that the industry moved past**, which is exactly the case where the accumulated
evidence makes the entry look most trustworthy. That is the whole of what §11.3 leaves open.

### 12.4 The update pipeline, as stated

At the completion of every project:

1. **Lessons are extracted from the coding kit** — findings and their dispositions, events, spend,
   and whatever the retro artefact carries.
2. **GenAI performs the update**, taking those extracted lessons as input.
3. **The involved roles supply the rest** — solution architect, lead developer, **and all other
   roles that worked the project**. Wider than the overlay's authorship (§10.5), deliberately: the
   overlay is a target shape decided by architects, while lessons come from everyone who met the
   problem.
4. **The output is a new accelerator version** (§12.1), which is where a phase-out lands.

**What this settles about the promotion ladder:** the ladder **counts**, this session **decides**.
Occurrence thresholds become an *input* to a facilitated update at a defined moment rather than an
automatic trigger — consistent with `T-20260811-an-accelerator-authoring-template-and-se`, whose
criteria already require that an authoring agent *produce a draft, never a promoted entry*.

**One dependency worth naming and not filing.** Step 1 assumes the kit *has* something to extract.
Today this project's own record shows `0 / 0 via:kit` escape rate in every tier and five subagent
runs that recorded nothing — an absent denominator. A completion session run against an empty
extraction has only human memory as input, which is the ordinary way lessons are lost and precisely
what the kit exists to prevent. **The value of the update pipeline is bounded by what the kit
recorded during the project**, so instrumentation is upstream of accelerator improvement rather
than parallel to it.

### 12.5 Reusable assets: out of scope, referenced rather than contained, keyed by design pattern

This confirms the boundary already drawn. `docs/CATALOGUE.md` opens with it — the catalogue is *an
N-languages × M-solutions engineering programme with its own release cadence*, and **the kit's role
is selection and enforcement; it must not host the code**. `DESIGN-NOTES` says the same: the code
belongs outside this kit even when the knowledge belongs inside it.

What the operator adds is **how the knowledge is expressed**: an accelerator **represents existing
open-source solutions against the specific design patterns in use**, and where no suitable one
exists the required asset is created — still outside the kit. So an accelerator entry for a pattern
**points at an implementation choice rather than carrying one**.

Two consequences `[judgement]`:

- It stays compatible with the vendoring and no-network posture. A reference to an open-source
  solution is reference material; nothing fetches it, and `SECURITY.md`'s no-network claim is
  untouched.
- **The open-source reference is the most perishable content in an accelerator**, which is §12.3
  again at finer grain: **the design pattern outlives the library that implements it.** That
  suggests phase-out granularity is the *implementation reference*, not the pattern — a pattern
  entry survives while the solution named under it is replaced. Not decided here.

### 12.6 Status

Nothing filed as work, nothing marked done. §12.2 and §12.3 close most of §11.3; what remains open
is the single missing rule named at the end of §12.3, and the granularity question at the end of
§12.5.

---

## 13. Amendment, 2026-08-24 — the pattern is closed, the implementation list is open

Operator statement, refining §12.5 and answering the granularity question it left open:

> Accelerators reference **design patterns**. For specific design-pattern usage, **libraries and
> corresponding versions can be referenced externally**. GenAI can handle this, based on **industry
> maturity** and references that are good for specific tech stacks. **I am trying to keep this
> open.** At the same time, provide **guidance and references, so the model chooses among the known
> where possible**, to ensure **deterministic and quality code outcomes**. No human architect or
> developer can list all; only **known software may be provided as a reference**, while GenAI
> suggests recommendations **additionally, to the actual implementation team who uses the coding
> kit**.

### 13.1 §12.5's open question closes

§12.5 asked whether phase-out applies to a design pattern or only to the open-source solution named
under it. **Answered: the pattern is the stable unit; the library-and-version binding is the
perishable pointer.** A pattern entry persists across versions of an accelerator while the
implementation named under it is replaced, which is why the two belong at different granularities in
the file rather than as one entry.

### 13.2 The tension the statement contains, and why it is not a contradiction

*Keep it open* and *deterministic outcomes* pull against each other on the surface: if the model may
propose a library outside the listed set, two runs of the same task can select differently.

§5 already disposes of this, and it is worth reading again with libraries in mind: **the defensible
meaning is determinism of conformance, not of text.** Two runs may write different code and both be
correct outcomes. An open implementation set is therefore not a determinism failure by itself — it
becomes one only if the choice is **improvised twice**, which is §5 stage 2's actual concern:
*every answer supplied is a decision not re-made, and re-made decisions are where two runs diverge*.

So the operative rule is not *the model may only pick from a list*. It is:

**The known set is a preference order, not a whitelist — and a choice outside it must be recorded
rather than silent.** Once recorded, the next run inherits it as known and stops re-deciding. That
is the `[seeded]` → `[earned]` ladder applied to implementation selection, with the recording sites
already defined by §10.5: an **ADR** for a project-level choice, and the **completion session**
(§12.4) for anything that should outlive the project.

**The disposition machinery already exists too.** A selection outside the known set is a **deviation
with a disposition** in §3.1's sense — a decision made against a definition that did not cover it —
and §8.2's authority rule already says who may accept one. No new vocabulary is required.

### 13.3 What the model cannot supply, and what follows

*Industry maturity* is the one input in the statement that a model **cannot verify**. Its evidence is
what it was trained on, not the state of the industry at the moment of asking, and it will present
both with the same fluency. This is §11.3's recency problem reappearing one level down — at the
library rather than at the accelerator entry.

The existing rule already covers it and should be applied rather than extended: `DESIGN-NOTES`'s
third source is *best practice gathered from public material, analysed by an agent, then discussed
with the architects who maintain accelerators*, and it enters as `[seeded]`. **A model's library
recommendation is `[seeded]` by construction.**

The consequence is about presentation, and it matches the operator's own phrasing — the
recommendation goes **to the implementation team**. So it must arrive as a **proposal carrying its
basis**, never as a settled fact: what pattern it implements, what it is being preferred over, and
that its maturity claim is unverified. `[judgement]` A recommendation that arrives without its basis
cannot be judged by the team it was addressed to, which is the only place in this chain that can
judge it.

### 13.4 Referencing externally without inheriting staleness

"Referenced externally" has a strong reading and a weak one, and the difference decides whether
§12.3's phase-out has anything to bite on.

- **Copying a version table into the accelerator** makes the file a snapshot that expires, and every
  pinned project inherits the snapshot. This is the shape §12.3 is about.
- **Pointing at the authority** — the library's own release channel or registry — puts the moving
  fact where it already moves. The accelerator then carries the *binding* (this pattern, this
  library, in this stack) and not the digits.

`[judgement]` The second is the reading that keeps the accelerator's own version meaningful:
a version bump then records *the binding changed*, which is a real editorial act, rather than
*a dependency released a patch*, which is noise.

### 13.5 The auto-mode consequence, which is the first concrete one in these amendments

The operator's chain terminates at a human: GenAI suggests **to the implementation team**. In
auto-mode there is no human at that moment.

So a library selection **outside the known set** is an interrupt candidate — it is a decision with
no recorded answer, whose central claim (maturity) is made by the party least able to verify it, and
whose consequences outlive the task. §3's interrupt budget and §8.3's uncertainty default already
own the machinery; what has been missing is a concrete population to point them at, and this is one.
`[judgement]`

The symmetric case is quieter and matters as much: a selection **inside** the known set should
**not** interrupt. That is what makes the guidance worth supplying at all — it converts a decision
into a lookup, and §3's whole argument is that the interrupt budget is the scarce resource.

### 13.6 This lands on an existing task, and the fit is close

`T-20260801-declare-and-enforce-a-library-catalogue` (open; the file records `tier: T2` while
`STATUS` renders `[T0]` from its commit trailers) already carries acceptance criteria that assume
exactly this model:

- *a pattern accelerator entry can name its catalogue implementations per language* — the
  pattern-to-implementation binding of §13.1;
- *the solution overlay can pin an implementation, and the pin is recorded not assumed* — the
  recording site of §13.2, with `not assumed` doing the same work as *record rather than improvise*;
- *an empty or undeclared catalogue costs nothing and warns nothing* — **openness is already the
  default posture**, and a project that names nothing is not in violation of anything.

Its scope note also holds the line §12.5 confirmed: the kit's share is **selection and enforcement**;
the implementations are code in their own repositories with their own release cadence.

**What the statement adds to that task, and it is not currently in its criteria:** the catalogue is
**not exhaustive by design**, so nothing may treat *absent from the catalogue* as *disallowed*. The
finding class the task proposes — *re-implementing a catalogued capability* — is safe, because it
fires only on entries that exist. A finding class of the opposite shape, firing on a library that is
merely unlisted, would contradict the operator's statement outright. Recorded so it is not built by
accident; **not filed**.

### 13.7 Status

Nothing filed as work, nothing marked done. §12.5's granularity question closes at §13.1. The one
open item from §12.3 — no retirement rule for an `[earned]` entry the industry moved past — is
unaffected and still open.

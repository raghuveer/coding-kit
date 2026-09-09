<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — one core, many adapters: where a second host's work lives, and what it may reuse

**Tier:** T3 — it proposes a second distributable, changes what a version pin identifies, and
touches the licence surface of material that would be vendored from third parties.
**Status:** design input. **A proposal, not a decision.** Nothing here is implemented, no task is
filed by this document, and no finding is marked.

**Serves:** `T-20260819-the-claude-adapter-is-16-files-but-nothi`, which records the two-layer
boundary and says the distance to a port *"is closer than it appears; this task exists so the
distance is recorded rather than re-derived by whoever picks it up."* This document is that
pick-up. It amends none of the task's acceptance criteria and argues with one of them in §7.

**Related and deliberately not reopened:** `docs/CHARTER.md` §6 (three starting conditions, one
mechanism), `docs/VERSIONING.md` (what a bump means here), `docs/ADAPTERS.md` (the producer-swap
contract this generalises), `design-input/2026-08-16-artifact-model-and-distribution.md` §2.5
(agent-neutrality of the distribution format, decided then, unimplemented).

Every number below was produced by a command on this machine on 2026-09-09 and the command is
named. ADR 0005, ADR 0006 and ADR 0010 were each rejected for a load-bearing claim that was
confident, checkable and false; the discipline is a response to that.

---

## 0. The questions this comes from

The operator, 2026-09-09:

> *"a design input is required. To isolate, do we create a minor version on the same github
> repository or how? I want this plugin to be developed that is usable, that is usable as plugin
> for codex and other coding agents starting with claude-code. You may consider opensource license
> and see what can be re-used across coding agents. Give me the plan. we use this for brownfield,
> then, greenfield then legacy application modernization."*

Four questions, and they are not equally open. **Isolation** (§3) has a defensible answer from the
existing versioning rule. **The adapter contract** (§4) is a design proposal. **Licence and reuse**
(§5) is mostly fact-finding, already done. **The order of the three starting conditions** (§6) is
already decided in the charter and needs reconciling rather than deciding — it *looks* like it
contradicts the record and does not.

---

## 1. What is already true — measured, not assumed

### 1.1 The two layers exist and the boundary holds by accident

Re-measured 2026-09-09 against the working tree at `9ce8b70`:

```sh
grep -rlE 'CLAUDE_PLUGIN_ROOT|CLAUDE_[A-Z_]+|anthropic|claude-(opus|sonnet|haiku)' tooling/
# -> no match
```

| | |
|---|---|
| Harness variables, vendor names or model ids under `tooling/` | **0** |
| What the `.claude/` strings under `tooling/` are | a directory name, in 13 files |
| Portable core | **24 files, 7,923 lines** — 21 shell, 2 Python, 1 SQL schema |
| Host adapter | **16 files** — 5 skills, 9 agents, 1 hook manifest, 2 plugin manifests |

This confirms `T-20260819`'s 2026-08-18 measurement at a different SHA and with a ninth agent
added since. **The boundary is real and nothing defends it.** Its one genuine hardcode is
unchanged: `kit_profile()` in `kit-lib.sh` fixes `.claude/project-profile.md`, while `paths.*`
already exists as the pattern for making it a value (`paths.tasks`, `paths.state`, `paths.status`,
`paths.adr`, `paths.design_input` are all live in `.claude/project-profile.md`).

### 1.2 The host constrains the layout, and this is the fact that decides §3

Read from `plugin-dev/skills/plugin-structure/references/manifest-reference.md`, which enumerates
every manifest field:

| field | custom path? |
|---|---|
| `commands` | **yes** — string or array, must start with `./` |
| `agents` | **yes** — string or array |
| `hooks` | **yes** — a file path |
| `mcpServers` | **yes** — a file path |
| **`skills`** | **NO SUCH FIELD.** Skills are discovered at `./skills/` and nowhere else |

And: *"Custom paths supplement defaults — they don't replace them. Components in both default
directories and custom paths will load."*

Two consequences, and both are load-bearing:

- **A symmetric `adapters/<host>/` tree is not achievable for the Claude adapter.** Five of its
  sixteen files cannot move. Any design that assumes a clean per-host directory is wrong before it
  is written, and would be discovered only after the move.
- **Moving a component directory requires deleting the original**, not just repointing the
  manifest. A leftover `agents/` would keep loading alongside the new path, silently, with no
  error — the same shape as HANDOFF §7's first shipped bug, where nested agents never loaded and
  `agents/README.md` would have been parsed *as an agent*.

### 1.3 What the marketplace ships

`.claude-plugin/marketplace.json` declares one plugin with `"source": "."`, so **the whole
repository is the plugin**. An `adapters/codex/` directory would therefore be present in every
Claude Code install of the kit. Cost: disk. Resident context: **zero** — the same argument
`accelerators/README.md` already makes, *"distribution is free (unread files cost zero); context
is not."*

`.claude-plugin/plugin.json` is `0.11.0`, `"license": "Apache-2.0"`.

---

## 2. What this document does not propose

Stated first, because the expensive failure here is scope drift into a rewrite.

- **No change to the portable core.** It is the asset. Nothing in §§3–7 edits `tooling/`.
- **No agent runtime, no gateway, no orchestrator.** `CHARTER.md` §1 and the scope boundary of
  2026-08-14 hold unchanged: *an add-on that requires you to adopt its runtime is not an add-on.*
- **No claim about what any specific non-Claude host supports.** §4 states a contract and a
  pre-flight that answers it per host. `codex` is not installed on this machine
  (`command -v codex` -> nothing), so **every statement about it in this document would be
  unverified**, and there are none.
- **No port before the kit has produced a reading.** §7.

---

## 3. Isolation — the answer is the existing rule, applied

### 3.1 Options

**A — a separate repository for the second adapter.** *Rejected.* The core is the shared and
expensive half; a second repository either duplicates it or imports it, and a duplicated core is
two copies of one truth. That is the failure this entire design exists to avoid, and the kit has
paid for it twice at smaller scale — the finding vocabulary across four locations, the state
partition across nineteen sites.

**B — a long-lived `v0.3` development branch.** *Rejected, and the reason is already written down.*
`VERSIONING.md`: *"The default branch is what unpinned installs get… A release that stops at a side
branch has not shipped."* A long-lived branch also inverts the working agreement — CI fires on
`pull_request` and on pushes to `main`, so work that lives off `main` for weeks is work CI is not
keeping green.

**C — restructure into `adapters/<host>/` for every host.** *Rejected on §1.2.* Skills cannot move.
The symmetry is not available, and buying it would mean abandoning skills for commands — which
`MIGRATION.md` already records as a capability loss, not a rename: a command is user-invoked only,
so Claude cannot reach for `task-context` at the start of work.

**D — same repository, same marketplace, MINOR bumps on `0.x`; the Claude adapter stays at the
root because the host requires it to, and a second adapter goes in `adapters/<host>/`.**
**Proposed.**

### 3.2 The recommendation, and why it is MINOR rather than MAJOR

**One repository. One core. Per-host packaging. Isolation is the branch-and-PR workflow that
already exists, not a version number.**

`VERSIONING.md` gives the test directly: *does someone pulling this have to take an action?* —
where MAJOR prices **repair of committed state**. Adding an adapter directory migrates no
`.project/` file, moves no schema, rewrites no trailer, and changes nothing a consumer's repository
believes. **MINOR.** This is the same reading that classified the repository rename and the
MIT → Apache-2.0 relicence as MINOR, both of which felt louder than this one.

The asymmetry in the layout is **forced by the host, not chosen**, and must be documented where a
contributor hits it or it will read as an oversight:

```
tooling/  templates/  tests/  docs/  accelerators/   <- portable core, host-agnostic
skills/   agents/     hooks/  .claude-plugin/        <- Claude Code adapter (root-bound: §1.2)
adapters/<host>/                                     <- every subsequent adapter
```

**The boundary is enforced by a check, not by the directory layout** — which is what `T-20260819`
AC2 already asks for, and it is worth doing even if no port ever happens:

> no harness name, model name or `CLAUDE_*` variable appears under `tooling/`

It is true today by accident, and *true-by-accident becomes false the first time someone reaches
for convenience.* `[judgement]`

### 3.3 When a second marketplace entry becomes right

Not yet, and the trigger is stateable. `VERSIONING.md` records that `claude plugin tag` produces
`coding-kit--v0.2.0` *"so a marketplace carrying several plugins can version them independently"*,
and that today's marketplace carries one. **When a second manifest exists and is installable, the
marketplace gains a second entry and the prefixed tag convention starts earning its typing
friction.** Until then it costs friction for no disambiguation. Decide it in the commit that adds
the second manifest, not before.

---

## 4. The adapter contract — four surfaces, and a declared degradation for each

The kit already has the right idiom for this and it is not a new mechanism. `verify-ladder` states
obligations with **declared substitutes**: an unavailable rung is declared in `project-profile.md`
as an empty value and **raises the tier**, because less mechanical verification means more
adversarial reading rather than a lower bar. *Silent absence is the failure.*

Apply the same shape to the host. An adapter declares which of four surfaces its host provides, and
the kit **reports the degradation rather than pretending**:

| # | Surface | Claude Code | If the host lacks it |
|---|---|---|---|
| 1 | **Model-invocable procedure** — the model reaches for it by name | 5 skills | Degrades to user-invoked. `task-context` stops being reached for at the start of work, which is the whole reason commands became skills. Declare it; the context economy is weaker, not absent |
| 2 | **Delegated worker with its own context window** | 9 agents | **This is the one that breaks the premise.** `MODELS.md` and `HANDOFF.md` §4.10 rest on *context independence beats weight independence* — never pass the coder's rationale to the reviewer. A host that collapses review into one context loses the primary uncorrelated-reviewer argument, and the tier floors must rise to compensate. Declare it and raise the floor, exactly as an absent ladder rung does |
| 3 | **Lifecycle hook** — write guard, stop checkpoint, subagent-stop spend | `hooks/hooks.json` | No telemetry, so **no graduation evidence**: per-agent spend and the escape-rate denominator both come from here. The guard is convention-bounded already (`SECURITY.md` §4), so its loss is smaller than the telemetry's |
| 4 | **Manifest and a distribution channel** | `.claude-plugin/` | No version pin, so *"you cannot tell which version someone's feedback is about, and the comparison you are running becomes uninterpretable"* (`INSTALL.md`) |

**The port's pre-flight is those four questions, answered against the target host before any file
is written.** A host answering *no* to #2 is a materially different product and that should be
known on day one rather than discovered at integration. `[judgement]`

### 4.1 The binding indirection, which serves two requirements at once

`2026-08-16-artifact-model-and-distribution.md` §2.5 already decided this and it is unimplemented:

> **Recommendation: do not put agent names in a published accelerator file.** Put role or
> capability intent in the file, and let the consuming project's profile map role → its own agent
> names. One indirection, and it is the difference between a format others can publish into and one
> only this kit can read.

Today the binding is `accelerator.technology: <path> -> implementation-reviewer,coder` — Claude
Code agent names, in a file intended to be shared. The proposal is that the kit names **roles**
and the profile maps role → provider, where a provider is a kit agent, a host-native reviewer, or
a third-party plugin agent.

**The same indirection answers a requirement that arrived from the other direction**: substituting
a reviewer the ecosystem already ships (`pr-review-toolkit`, `code-simplifier`) is the same
mechanism as binding a role on a second host. That convergence is the strongest argument for
building it, and it is invisible from either requirement alone. `[judgement]`

It is also the existing `ADAPTERS.md` producer-swap contract applied one layer up — *"replacing a
source means replacing one producer, not rewriting the indexer"* — so it is a generalisation of
something already shipped rather than a new idea.

---

## 5. Licence — what may be reused, and in which direction

### 5.1 The kit's own licence is already the right one

`plugin.json` says `Apache-2.0`, and `T-20260818` recorded the reason: *"Apache 2.0 is the right
licence for a multi-adapter end product."* The patent grant is the part MIT lacks and the part that
matters once other organisations ship the format. `VERSIONING.md` records the limit precisely: the
relicence was clean **only because every commit to that point is single-author**, and *"with
third-party contributions under the old licence it becomes a permissions exercise, not a version
decision."* Copies obtained under MIT stay MIT permanently.

**Consequence for this plan:** the moment third-party material is vendored, the same door closes on
any future relicence. That is acceptable and should be a decision rather than a side effect.

### 5.2 What can be reused, verified per file

The registered marketplace lists **292 plugins**, of which **52 are Anthropic-authored** and
bundled in the repository (`marketplace.json`, counted 2026-09-09). Licences read from each
plugin's own `LICENSE`, not inferred from the marketplace root:

| Source | Licence | Usable how |
|---|---|---|
| `pr-review-toolkit` (6 reviewer agents) | Apache-2.0 | **Vendor.** Closest counterparts to `implementation-reviewer`, `tester` |
| `feature-dev` (`code-architect`, `code-explorer`) | Apache-2.0 | **Vendor.** Against `researcher`, `approach-reviewer` |
| `code-modernization` (8 agents, 10 commands) | Apache-2.0 | **Vendor.** Aimed at the third starting condition |
| `code-simplifier` | Apache-2.0 | Vendor or depend. No kit counterpart |
| `plugin-dev` (7 skills), `skill-creator`, `hookify` | Apache-2.0 | Use as-is for authoring the kit |
| **`claude-security`** | **"Copyright (c) 2026 Anthropic, PBC. All rights reserved."** | **Depend, never copy.** No vendoring, no derivative, in either host direction |
| `/code-review`, `/security-review`, `/simplify` | built into the harness | No install, no resident cost |
| the other 240 | varies | Read each repository's own `LICENSE`. The marketplace README says so explicitly |

### 5.3 The direction question, which is what "across coding agents" actually asks

**Apache-2.0 carries no field-of-use restriction.** Material forked from an Apache-2.0 plugin may
therefore be re-emitted for a different host, provided the three obligations travel: keep the
licence text, carry the attribution in `NOTICE`, and state the changes. That is the mechanism by
which reviewer *prompts* — the substantial, portable content — reach a second host without being
rewritten from nothing.

`claude-security` is excluded from this entirely and in both directions. The exclusion must be
mechanical rather than remembered, for the reason every other exclusion in this kit is: **a
conformance step asserting that no vendored path lacks a `NOTICE` entry**, in the same spirit as
the single-home vocabulary check. `[judgement]`

> **Not legal advice, and this document should not be read as giving any.** The obligations above
> are the ones Apache-2.0 states on its face. If the kit is ever distributed commercially or
> bundled into a client deliverable, that is the point to have the vendored set reviewed properly.

### 5.4 The reuse trap, and it is measured rather than theoretical

A vendored reviewer will not emit `class|severity|lang|domain`, and vocabulary compliance is a
**measured** defect here, not a hypothesis: `MEASUREMENTS.md` §B3 records sonnet at **0/9** and
haiku at **0/8** valid classes until the vocabulary was inlined into the agent's own instructions,
with haiku additionally breaking the batch format by appending prose after the fourth field.

So there are two ways to consume a foreign reviewer, and only one survives this repository's own
lessons:

- **Scrape its prose.** `LESSONS.md` §5 is the record of what that costs — one harvester, five
  defects in about 120 lines, and the conclusion *"ask for the data; do not scrape it. The cheapest
  component to secure is the one you deleted."*
- **Fork it and edit the prompt** so it returns the kit's structured finding directly. Apache-2.0
  permits exactly this.

**For reviewers, vendoring is the correct mode and depending is the trap** — which inverts the usual
instinct, and is why `claude-security`'s licence matters more than its position in the table
suggests. `[judgement]`

---

## 6. The three starting conditions — the operator's order, reconciled

The operator's order is **brownfield → greenfield → modernization**. That reads as a contradiction
of `2026-08-16` §4 (*"Build and prove the overlay against greenfield first"*) and is not one,
because the two statements have different subjects. Recording the reconciliation here so it is not
re-derived:

| | Subject being validated | Why it is in this position |
|---|---|---|
| **1. Brownfield** | the **entry mechanism and the review pipeline** | It is the general case (`CHARTER.md` §6), the trial is already staged and isolation verified, and it is *"the first end-to-end observation of outcomes on a project nobody on this side wrote"* |
| **2. Greenfield** | the **solution overlay** | Greenfield has no derived context, so the overlay is the *entire* input — no census noise, no legacy confound, no argument about whether a finding came from the code or the constraints. §4 of 2026-08-16 calls it the proving ground for the load-bearing component, not the cheap third variation |
| **3. Modernization** | the **source→target delta and per-component disposition** | Hardest case, worst place to debug a new mechanism, and it has a named unmet prerequisite: `T-20260819-legacy-candidate-selection-is-unresearch` |

**This is one mechanism parameterised three ways, not three builds.** `CHARTER.md` §6 is explicit:
*"Do not build three paths. An earlier plan did, and it would have built the same thing three
times."*

---

## 7. Sequencing — and the one criterion this document argues with

`T-20260819` AC4 states a sequencing constraint and invites the argument:

> **Do not port before the kit has been validated once.** … Generalising an unvalidated design is
> `T-20260808-cluster-packs-are-generated-and-read-by-` at architecture scale — built at both ends,
> documented, never measured. This criterion is a sequencing constraint and exists to be argued
> with, not silently dropped.

**It is upheld, and it is narrower than it reads.** The work splits cleanly into a half that is
independent of any port and a half that is not:

**Port-independent, and worth doing now even if no second host is ever built** — this is the half
AC4 does not block:

1. The boundary check (§3.2), mutation-proven.
2. `kit_profile()`'s hardcoded `.claude/project-profile.md` becomes a `paths.*` value.
3. Role-based binding replacing `-> agent-name` in accelerator declarations (§4.1) — already
   decided on 2026-08-16 and unimplemented.
4. The two-layer boundary documented where a contributor hits it (AC1).
5. What a second adapter must supply, enumerated from the sixteen files rather than guessed (AC3).
6. `NOTICE` discipline as a check, before anything is vendored (§5.3).

**Port-dependent, and gated on a reading** — the second manifest, the second skill and agent set,
the hook shim, and the marketplace's second entry. The gate is not ceremonial: **the kit has never
been loaded as a plugin against a repository it did not author.** `TRIALS/2026-09-09-highper-gateway-plugin-mode.md`
is `PREPARED, NOT RUN`, and its own pre-flight fails at *no unfixed critical* with **12
outstanding**, all anchored in one design document for a feature that was never built.

**So the shortest path to a second host runs through the brownfield trial**, and the six items above
can be built in parallel with it because none of them depends on its outcome. `[judgement]`

### 7.1 What this buys in tokens, and the honest size of it

Raised by the operator while this document was being written: *"people are saving tokens through
bash compression and many other approaches. we need to do save too."* The part that belongs in
**this** document is the resident-cost consequence of §3 and §4.1; the general question is a
different subject and §10 proposes it as its own task rather than folding it in here.

**The caching lever is close to exhausted and the record says by how much.** `DESIGN-NOTES.md` §0,
measured: cache-read ratio **97.5%**, effective input multiplier **0.129×** against a **0.100×**
floor — **≤22% headroom** — and the conclusion drawn there binds anything proposed now:

> The remaining levers are **peak context window** and **model mix**. A design that adds structure
> without touching either is not a token improvement, whatever else it is worth.

Against that rule, three things in this document are token improvements and one is not:

- **§4.1's role binding is.** Agent descriptions are resident because that is how routing works —
  measured at **~840 tok for eight agents**, and **nine ship today**. That charge is paid in every
  project on the machine, including ones not using the kit. Substituting a host-native or
  third-party reviewer for a kit agent removes a standing charge rather than a per-call one, which
  is the more valuable kind.
- **§1.3's packaging answer is**, trivially and by construction: an unread adapter directory costs
  disk and **zero** resident context.
- **§3's layout is not**, and should not be argued as one. It buys a checkable boundary. Claiming a
  token benefit for it would be the category error §10.2 of the auto-mode document already
  corrected once.

**And the caution that outranks all of it**, from `HANDOFF.md` §9: *"every metric here improves if
you simply review less. Token efficiency is necessary and not sufficient; pair it with escape rate
before concluding anything."* Lowering the tier is a **measured** loss here, not a saving —
`MEASUREMENTS.md` §C found haiku missed the critical security finding entirely at 5 tool uses
against 19, and sonnet softened a REJECT into a REVISE. So the model-mix lever is real but narrow,
and `MODELS.md` already states its shape: **split the work by audience, do not lower the tier
across it.**

**None of this is measurable today**, which is the sequencing point. Per-agent spend works only in
plugin mode, and `T-20260821-the-kit-does-not-measure-its-own-develop` records that the kit's own
development registers no hooks at all. A compression programme run before that lands would be
optimising against a number nobody can read — which is the cluster-pack failure again, in a
different costume. `[judgement]`

### 7.2 The rename is downstream of the same reading

`T-20260819` AC5: *"The rename to a generic identity is decided **with** this, not before it. The
name should follow from what the kit proves to be; renaming twice is the avoidable cost."*
Unchanged by this document, and §3.3's second marketplace entry is the natural moment for it.

---

## 8. Open — the operator's, and each one changes something above

1. **Does the Codex adapter ship inside the Claude Code plugin distributable?** §1.3 says the cost
   is disk only and resident context is zero, so the proposal is yes, for simplicity. The
   alternative — per-host packaging from one repository — is more machinery than the cost justifies
   today, and becomes right if adapter count grows past two.
2. **Is `NOTICE` discipline a check or a convention?** §5.3 proposes a check. It is the difference
   between an obligation that holds and one that holds until someone is busy.
3. **Does vendoring close the relicence door deliberately?** §5.1. It is a one-way decision and
   should be taken as one rather than arrived at.
4. **Which host is second?** This document names none, deliberately, and §4's pre-flight is the
   instrument for choosing rather than an argument for a particular answer.
5. **Does surface #2 being absent disqualify a host, or merely raise its floors?** §4 proposes the
   second. If a host collapses review into one context, the tier economy's central argument weakens
   and someone has to decide whether the kit still means anything there.

---

## 9. Acceptance criteria, if this is built

Written as things that can fail, per `LESSONS.md` §1 and `docs/adr/0008` §Consequences.

1. **A conformance step that fails on a mutated tree**: introducing `CLAUDE_PLUGIN_ROOT`, a vendor
   name or a model id anywhere under `tooling/` turns the suite red. Proven by making the mutation,
   not by asserting the step exists.
2. **`kit_profile()` reads a `paths.*` value**, and a project declaring a different profile location
   indexes correctly — asserted with a case that fails on the pre-change tree, where the path is a
   literal.
3. **An accelerator declaration binds a role, not an agent name**, and the existing `-> agent`
   form still resolves — the additive rule `kit-index.sh` already follows for unknown frontmatter
   keys.
4. **A vendored path with no `NOTICE` entry is refused**, and a case proves the refusal fires. A
   check that passes on an empty vendored set is decoration.
5. **The layout asymmetry of §1.2 is documented at the boundary**, and a reader can answer *why can
   skills not move* without reading this file.
6. **The four-surface pre-flight is answered and recorded for the chosen second host before any
   adapter file is written** — the answers are part of the result, the same rule
   `TRIAL-PROTOCOL.md` §0 applies to a trial.
7. **The same `tooling/` tree, unchanged, produces identical derived status under both adapters on
   one repository.** If the core needs a patch to work under the second host, the boundary was in
   the wrong place and the adapter is not finished.

---

## 10. Proposed task lines — for the operator, not to be run by an agent

Per `.claude/CLAUDE.md` and `kit-task.sh`'s own gate: *a researcher proposes a breakdown, a human
confirms and edits, then this writes the confirmed tasks.* Nothing below has been run.

```sh
kit-task.sh --title 'The tooling boundary is checked so a harness name cannot enter the core' --tier T2 --paths 'tests/conformance.sh, tooling/'
kit-task.sh --title 'kit-profile reads a paths value instead of a hardcoded profile location' --tier T2 --paths 'tooling/kit-lib.sh'
kit-task.sh --title 'An accelerator binds a role and the project profile maps role to provider' --tier T3 --paths 'tooling/kit-accel.sh, templates/project-profile.md, accelerators/README.md'
kit-task.sh --title 'A vendored third-party path with no NOTICE entry is refused' --tier T2 --paths 'tests/conformance.sh, NOTICE'
kit-task.sh --title 'Task segregation turns confirmed inputs into tasks' --tier T3
kit-task.sh --title 'Register the kit hooks for the kit so development produces spend rows' --tier T2 --paths 'hooks/hooks.json, tooling/kit-spend.sh'
kit-task.sh --title 'Reduce peak context per session and measure it against escape rate' --tier T2
```

The last line is filed against a gap the record names as load-bearing and has never given a task:
`design-input/2026-08-22-auto-mode-is-a-graduation.md` §20.5 — *"Task segregation is the step
between them, and it is the least built thing in the kit"* — and `CHARTER.md` §4 lists it under
**"Named and unbuilt, with no task, and it is the load-bearing one."** It is outside this
document's subject and is proposed here only because filing it costs one line and re-deriving it
has already cost several sessions.

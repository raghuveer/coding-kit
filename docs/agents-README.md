<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Subagents — routing, risk-tiering, and model selection

Eight agents. The harness auto-routes to them by matching your request against each agent's
`description`, so the `description` line is a routing decision, not documentation.

## The pipeline

```
  ┌─ BROWNFIELD / unfamiliar codebase: runs BEFORE any of the below ─┐
  claim-auditor(opus)  →  [human reads the census]  →  tiering + planning
  └──────────────────────────────────────────────────────────────────┘
                                                                                           ↓
                         ┌─ NON-TRIVIAL design only ─┐
  researcher(opus) → approach-reviewer(opus) → [operator walkthrough] → adr-scribe(sonnet) ┐
                                                                                           ↓
  ROUTINE change ──────────────────────────────────────────────────────────→  coder(sonnet)
                                                                                           ↓
                                      implementation-reviewer(sonnet)  +  security-reviewer(opus, HIGH-STAKES only)
                                                                                           ↓
                                                                                  tester(sonnet)
                                                                                           ↓
                                                                                documenter(haiku)
```

### `claim-auditor` runs before tiering and planning, not alongside them

Every other agent in this pipeline acts on work that is already scoped. `claim-auditor` is the one
that decides **whether the scoping inputs are true.** Its subject is a claim someone already wrote
down — a roadmap, a status page, a gate record — and its output is a census: a verdict per claim,
with evidence, against the tree.

**On an unfamiliar or long-running codebase this is the first job.** You cannot tier work you
cannot scope, and you cannot scope from documentation nobody has checked. On the run that motivated
the agent, **three of four candidate tasks taken straight from the roadmap were already done**, and
the two genuinely valuable ones were invisible until the audit had run.

The measured base rate across two unrelated Rust subjects six months apart: **35% and 43% of
documented claims did not hold as written.** Planning against an unaudited document on a codebase
like that is planning against a third of a fiction.

It does **not** run on greenfield work you are authoring turn by turn, and it does not run before a
routine fix. It runs when you are inheriting a body of claims — which includes inheriting your own,
a year later.

## Model tiering — keeps expensive fan-out proportional to risk

| Agent | Model | Runs when |
|-------|-------|-----------|
| claim-auditor | opus † | brownfield entry, before tiering and planning |
| researcher | opus | non-trivial design only |
| approach-reviewer | opus | non-trivial design only |
| security-reviewer | opus | **high-stakes changes only** |
| adr-scribe | sonnet | after APPROVED + the operator walkthrough |
| coder | sonnet | every implementation |
| implementation-reviewer | sonnet | every change (escalate to opus for high-stakes) |
| tester | sonnet | after review approves |
| documenter | haiku | after tests / a feature-state change |

**† `claim-auditor`'s tier is what the two measured runs used, not what they proved necessary.**
6,547,551 BTE across 17 subagents for 303 claims; 13,853,224 across 18 for 489. That is evidence
the tier works and none that it is required. Whether a cheaper model reaches the same verdicts is
answerable — re-audit one unit at a lower tier and compare claim by claim against the recorded
census — and unanswered. Per-claim cost was stable at ~35k BTE across both subjects, so the saving
is quantifiable in advance if anyone wants to argue for it. Read the row as an assumption wearing a
number until someone runs that experiment.

**Risk tiering is defined in your `project-profile.md`** — see `templates/project-profile.md`.
Name the tier and cite the trigger *before* spawning agents, or routine work quietly defaults to the full
pipeline and the expensive tier becomes your largest cost line.

**Do not skip phases** on non-trivial or high-stakes work — the review→code→review→test chain is the
correctness story. **Do** go straight to `coder` for a one-line routine fix; running the full gauntlet on
a CRUD tweak is wasted quota.

## Model selection — what it can and cannot do

There is **no** dynamic router that classifies each request and picks the cheapest capable model per call.
Selection happens at two fixed points: the **session model**, and the **`model:` line in each agent's
frontmatter** (static per agent).

What this kit gives you is *effective* task-based routing without a router: the harness routes your prompt
to whichever agent's `description` matches, and that agent carries a fixed tier. The chain is
**task → agent (by description) → model (by frontmatter)**. Routine work matches the cheaper agents; hard
design and security work matches the expensive ones.

**Practical default:** set the session to the mid tier, let the agents pull the expensive tier only where
their frontmatter says so, and reach for a manual override only for a hard stretch in the main loop.

## Structure — flat, and read at spawn

```
agents/<agent>.md          the portable method; owns the frontmatter
.claude/project-profile.md the project layer, read by each agent when it spawns
```

Plugin agent discovery is **flat and not recursive**: every `.md` directly under `agents/`
loads as an agent, and nothing in a subdirectory loads at all. That is why these files sit
at the top level and why this README lives in `docs/` — left in `agents/`, it would have
been parsed as an agent definition.

Nothing is composed or generated. Agents read `.claude/project-profile.md` at spawn, so
the project layer is edited in one place and never built. Plugin agents and a project's own
`.claude/agents/` coexist, so a project can add its own without touching these.

### `tools:` is a declaration, not a boundary

The frontmatter `tools:` line — `Read, Grep, Glob` on the three reviewers, `Bash` on `coder` and
`tester` — states what an agent is **asked** to hold. **Nothing in this kit verifies it binds, and
on 2026-08-16 it was demonstrated not to.** A reviewer launched with exactly
`--allowedTools "Read,Grep,Glob"` ran `Bash` successfully; its transcript carries the `tool_use`
with `is_error: false`. Whether a grant is honoured is a property of the harness and its version,
not of these files.

Read `tools:` as routing and intent — it documents the role, keeps an agent from being handed
capabilities its method never needs, and is the line to change when that method changes. Do not
read it as a capability boundary, do not cite it as one in a design, and do not let a review
conclude "the reviewer could not have edited this" from it. `SECURITY.md` §3 carries the full
account.

> **Superseded in 0.2.0.** Through 0.1 the agents were composed per project by a
> `sync-agents.ps1` build step that wrote `.claude/agents/`. That step is retired — the script
> is kept as `legacy-sync-agents.ps1` for reference and is not wired up. The per-session
> profile read replaces it, lands in the cached prefix at 0.1×, and drops the last PowerShell
> dependency. See `docs/MIGRATION.md`.
>
> Its one durable lesson, since the document describing it has been deleted: the composer chose
> the SOURCE by flag and the DESTINATION by where the script lived, so running it with another
> project's flag silently rewrote the live agent set with a different project's vocabulary and
> decision ids — no diff, no error. A marker file recording which project a destination belonged
> to made the mismatch refuse and change nothing. **Any future generator that writes into a
> repository needs the destination pinned, not inferred.**
>
> **The word "overlay" no longer refers to this.** In this kit an *overlay* is the **solution
> overlay** — client architecture supplied as an input — defined in `docs/DESIGN-NOTES.md` §2,
> which is its one home. The agent-composition sense is retired and its document removed so the
> term is unambiguous.

## What transfers, and what has to be earned

**Transfers unchanged:** the three-pass reviews, the HALT verdict and its asymmetry, the fail-closed bias,
the output contracts, the universal defect classes (a/b/c/f/h) and test traps (d/e/g), the mutation
discipline, and the diminishing-returns cap on design review.

**Does not transfer — and this is the point:** the *citations*. An agent ships the class ("a guard written
in the positive direction passes on every absent value"); your project supplies "shipped four times, here,
as &lt;your decision id&gt;". A new project starts with the classes and accumulates its own evidence
underneath them. **That ledger is the part no kit can ship** — it is the compound interest of running the
process.

Where that evidence now lives is the 0.2.0 change: the prose overlay became the `finding`
table. Reviews record `--class` and `--lang` through `kit-finding.sh`, `kit-vindicate.sh`
separates real defects from reviewer noise, and `kit-accel.sh propose` promotes only what
recurred and was never refuted. Queried per project rather than loaded wholesale, so the
ledger can grow without growing the window.

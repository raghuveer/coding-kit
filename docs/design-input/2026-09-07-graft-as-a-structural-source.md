<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Graft read at source: what it complements in `task-context`, and integrate vs replicate

Design input, 2026-09-07. Produced from a working session in which the operator asked whether
`trailhq/Graft` maintains context token-efficiently, and then whether it could complement
`task-context` — a skill that assembles *task* context with dependencies — by integration or by
replication.

Facts carry the file they came from. Unmarked statements were read out of a repository on
2026-09-07; `[judgement]` marks an opinion a future session is free to overturn.

**Nothing here is implemented, nothing is marked done, and no defect is filed from it.** The one
correction in §2 is to a claim this agent made in conversation, never to a repository artefact.

---

## 1. What Graft is, verified rather than quoted

`trailhq/Graft` (published by NanoNets), MIT, TypeScript, created 2026-07-03, 5,796 stars at time
of reading. Installed as `npm install -g @nanonets/graft`; `package.json` declares
`"engines": { "node": ">=20" }`.

It splits cleanly in two, and the split is the whole reason it is worth reading here:

| Half | What it does | Cost |
|---|---|---|
| **Structural** | tree-sitter parse to a code graph of symbols and typed edges. Serves `graft build`, `check`, `callers`, `skeleton`, `grep`, `map`. | deterministic, `$0`, **no model, no API key** |
| **Semantic** | plain-English node summaries and a "crux" — the handful of lines carrying the logic — written by a provider under the adopter's own key. | one LLM call per node, cached by content hash |

The artefact is a folder of linked markdown files under `graft/`, one node per system or concept,
with `[[wikilinks]]` between them. `graft build` **adds `graft/` to `.gitignore` itself**: it is a
regenerable local cache, like `node_modules`, and what a team commits is only the wiring. Each
node records the content hash of its sources, so staleness is exact rather than guessed.

Freshness is structural: every query stats the tree against the last build's fingerprint (~3ms)
and rebuilds only what moved, so answers describe uncommitted edits. That path never calls a model.

Two properties matter to us and neither is in the marketing copy:

- **The crux is stored as text, not as a line range.** Their stated reason: line numbers drift when
  unrelated code above them shifts, the lines that matter do not. This is the same failure mode as
  `T-20260817-a-touches-edge-is-never-checked-against-` — an edge that names a location the tree
  has since moved.
- **The tool directive forbids nothing and names the tools positively** (`format.ts:211`), and
  separately instructs the agent to pick *one* tool and act on its answer rather than re-asking a
  reworded question.

### 1.1 What is not in the repository

The README's headline numbers — `4x cheaper`, `+42% tokens`, `+46% tool calls`, and SWE-bench
Verified at 33/50 against a cold baseline's 27/50 — are asserted in prose. **I listed the whole
tree: there is no benchmark, eval, or harness directory.** The methodology is described; it is not
reproducible from the repo.

`[judgement]` This is the same asymmetry `docs/MEASUREMENTS.md` exists to avoid on our side, and it
is worth naming precisely because the rest of the project is unusually honest. Their *inline*
saving figure is real, verifiable code — it is only the comparative claims that cannot be re-run.

---

## 2. A correction, made before the argument that depends on it

In conversation I said the kit "currently has no notion of cached-vs-uncached channel cost", and
offered Graft's handling of it as the transferable idea. **That is false, and `task-context`
step 4 has said so for as long as the file has existed:**

> Place it **early and verbatim**, before the task spec. It is frozen for the life of the plan and
> byte-identical across every session in the cluster, so an unmodified copy sits in the cached
> prefix and costs a fraction of a fresh read. Reformatting or summarising it breaks that and you
> pay full price in every sibling session.

The cluster pack *is* the kit's cached-prefix channel, and the reasoning is not merely present, it
is stricter than Graft's — it explains why *reformatting* the artefact is the thing that destroys
the saving. I asserted the gap without reading the skill. The real difference is narrower and is
§4.

---

## 3. Where Graft genuinely complements `task-context`

`task-context` computes blast radius (step 5) from `edge` rows with `rel='touches'`. Those rows come
from `Task-Id` git trailers. The skill states the consequence itself, in step 6:

> `touches` edges need a `Task-Id`, so a repository adopted brownfield has none and step 5 returns
> nothing at all.

The fallback is co-change, derived from raw history, and the skill is equally candid about it:

> Measured recall@10 is 0.24 — roughly three quarters of genuinely related files are *not* in this
> list. It turns "unknown" into "unknown, and at least these".

So on day one of a brownfield adoption the kit's dependency picture is: **one signal that is empty
by construction, and one that misses three files in four.** Both are *history*-derived. Neither
reads the code.

Graft's structural half is derived from the **current tree**, needs no trailers and no history, and
is `$0`. It answers a question our two signals cannot: *what does this symbol actually call, and who
actually calls it, right now.*

That is the complement, and it is specific: **not "Graft gives better context", but "`graft callers
<sym> --depth all` populates a blast radius on a repository where step 5 returns zero rows."**

`[judgement]` This also lands where the operator has already committed effort. The brownfield trial
(`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie`, in-progress) and the two candidate
reconciliations against highper-gateway and aeon are exactly the setting where the empty-edge
problem bites, and where a structural source would be measurable rather than argued.

### 3.1 What it does not complement

Graft has no notion of a task, a dependency between tasks, a tier, a finding, or an acceptance
criterion. It ranks *code* for a *prompt*. `task-context` assembles a *task* with its spec, state,
plan cluster and blast radius. **They are not competing designs and Graft cannot replace any part of
the task half.** The overlap is exactly one row of the picture: which files this work touches.

---

## 4. What Graft has that the kit does not: a per-turn injection gate

This is the narrower true version of the claim §2 withdraws. The kit reasons about the *cached*
channel. Graft additionally polices the *uncached* one, and the mechanism is small enough to
describe completely:

Per-prompt injected tokens are fresh full-price input on every turn — their comment at
`format.ts:110` states it — so anything injected per-turn passes two gates (`relevantRetrieval`,
`format.ts:193`):

1. **Strength.** Inject only if the top hit landed on a real symbol *name*
   (`coverageStrong >= STRONG_FLOOR`, 0.1) or matched broadly enough to trust regardless
   (`coverage >= HIGH_FLOOR`, 0.5) — `fuse.ts:100,108`. Below both, it injects a single nudge line
   instead of a pack, capped at **two per session** (`NUDGE_CAP`, `format.ts:160`), on the stated
   grounds that "a line that shows up every turn stops being read".
2. **Novelty.** Drop hits whose pointer was already injected this session; if none survive, skip the
   pack entirely. Session memory is a rolling 40 pointers (`INJECTED_POINTERS_CAP`,
   `format.ts:155`).

`format.ts:152` keeps a dead constant, `INJECT_MIN_COVERAGE = 0.15`, exported purely as a tombstone.
A prompt measuring 0.165 cleared that single-clause floor by 0.015 and injected three test files for
a question answered elsewhere. The comment records that the original justification — *a wrongly
skipped pack is recoverable, the agent will pull with `graft ask`* — was falsified by a traced
session in which **the agent did not pull; it grepped 38 times.**

`[judgement]` That comment is the single most useful thing in the repository for us, and it is not
about retrieval. It is a worked example of the rule in `[[a-control-needs-a-check-that-can-fail]]`:
a threshold with a plausible rationale, shipped, then refuted by tracing what the agent actually did
rather than what the rationale assumed it would do. Any injection gate we build needs that trace
before its numbers mean anything.

They also print the saving inline on every tool's output — `tokensOf(chars) = chars/4`
(`format.ts:94`), baseline minus pack — and convert to dollars **only once a turn has actually been
billed**, so the count "stands alone rather than carrying a rate nobody measured."

---

## 5. Integrate or replicate

### 5.1 What settles it

`INSTALL.md:9-11`:

> Prerequisites: `git` 2.32 or newer, `sqlite3`, `bash`, and the POSIX text utilities.
> **No language runtime — no Node, no Python, no PowerShell. That is deliberate, so a Go or Rust
> team can adopt this without installing something they do not otherwise want.**

Graft needs Node >= 20 and a global npm install. **Bundling it, or requiring it, breaks a documented
and deliberate adoption constraint** — and breaks it hardest for exactly the audiences the
constraint was written for.

That rules out one option and only one. It does not rule out an adapter, because `ADAPTERS.md`
already exists for the case of a source the kit does not own.

### 5.2 The three options, as they actually stand

| | Integrate as a dependency | **Adapter (opt-in)** | Replicate in the kit |
|---|---|---|---|
| Node >= 20 on every adopter | **required — violates `INSTALL.md`** | only for adopters who opt in | never |
| Effort | small | small; the seam exists | large — a tree-sitter parser per language, in `bash`, with no runtime |
| Licence | MIT into Apache-2.0: fine either way, we shell out rather than vendor | same | n/a |
| Telemetry | inherited by every adopter | inherited only by opters-in | none |
| Maintained by | them | them | us, forever |
| Survives Graft being abandoned | no | yes — the profile line goes back to `none` | yes |

Replication is the option that looks principled and is not: `[judgement]` re-implementing
multi-language structural parsing with no language runtime is not a feature the kit can carry, and
attempting it would put the kit squarely on the wrong side of
`[[cck-scope-support-kit-not-agent-framework]]`. A structural code graph is a *tool*; this kit's
position on tools is already settled — **the kit ships adapters, never a scanner** — which is the
same reasoning `T-20260825-a-security-rung-on-the-ladder-satisfied-` applies to security scanners.

### 5.3 The seam already exists and needs nothing new

`ADAPTERS.md` defines `ingest.extra: <path>` in `.claude/project-profile.md` — repeatable, always
additive, never replacing a built-in. It is enforced, not advised: the path must be
**repository-relative and tracked by git**, both refused by `run_adapter` before execution, with a
conformance step proving all three directions.

A Graft adapter fits that contract without amendment:

```
ingest.extra: tools/graft-edges.sh     # tracked; emits SQL for structural edges
```

It would shell out to `graft callers --json` (or read `graft/` directly), and emit `edge` rows of a
new relation — `calls`, say, distinct from `touches` — for `task-context` step 5 to traverse.

**Two constraints from that document bind hard, and both happen to hold:**

- *"An adapter that puts something in the index that exists nowhere else breaks it."* Graft's graph
  is itself a regenerable gitignored cache, so `graft/` and `index.db` can both be deleted and
  rebuilt. The invariant survives.
- Adapters run as privileged code with the operator's permissions. `SECURITY.md` §4's sandbox gap
  and ADR 0003 apply unchanged; **Graft's opt-out telemetry becomes an adopter-facing disclosure**,
  not an internal detail. Its `TELEMETRY.md` is an allowlist enforced in
  `src/telemetry/contract.ts`, flushed by a detached process at most daily, plus one `install` event
  from the npm postinstall hook.

### 5.4 The recommendation

`[judgement]` **Adapter, opt-in, never a dependency — and not yet.**

The blocker is not design, it is proof. `T-20260808-co-change-has-no-eval-harness-so-its-sco` records
that co-change scoring cannot be improved because nothing measures it. The 0.24 figure in
`task-context` is the only number we have about blast-radius quality. **Adding a second source
without that harness would mean swapping one unmeasured signal for another and calling it an
improvement** — which is the failure `[[verify-own-claims-before-asserting]]` and
`[[a-control-needs-a-check-that-can-fail]]` both describe, and which §1.1 criticises Graft for.

So the sequence is: **eval harness first, adapter second, injection gate third if at all.** That
ordering is a claim, and per `[[sequencing-is-a-claim-that-needs-checking]]` it should be checked
against the planner rather than accepted from this document.

---

## 6. What would falsify the complement argument

Stated now, so a later session can kill this cheaply instead of re-arguing it:

1. **Recall.** If structural `calls` edges do not beat co-change's 0.24 recall@10 on the same eval
   set, there is no complement — only a second incomplete signal and a Node dependency.
2. **Overlap.** If structural edges land mostly on files co-change already returns, the marginal
   value is near zero even at higher recall.
3. **Polyglot.** Both candidate subjects are polyglot. If Graft's language coverage misses a
   subject's primary language, the adapter returns little on precisely the repositories that
   motivated it.
4. **Cost.** `ADAPTERS.md` records that built-ins run inline because a bare process spawn costs
   ~0.2s on Windows, and `kit-index.sh --if-stale` runs at the start of **every session**. A
   `graft` spawn is a process spawn plus a graph read. If that lands anywhere near the ~1000ms
   spawn cost this machine has already been measured at, `--if-stale` stops being cheap and the
   adapter has to be gated behind explicit invocation rather than the session-start path.

---

## 7. Questions only the operator can answer

1. **Is an optional Node dependency acceptable at all**, even opt-in and even documented as such?
   `INSTALL.md` currently reads as an absolute. An opt-in adapter makes it conditional, and that is
   a change to a promise, not just to a file.
2. **Does Graft's opt-out telemetry disqualify it** for adopters running the kit on client
   codebases? The events are anonymous and allowlisted, but "a detached process posts daily" is a
   sentence some clients will not accept, and the kit would be the thing that recommended it.
3. **Should a structural edge be a new relation or reuse `touches`?** A new relation keeps the
   history-derived and tree-derived signals separately measurable — which §6's recall test needs — at the cost
   of every consumer learning it exists.
4. **Is the injection gate (§4) in scope for this kit at all**, or is per-turn injection the host's
   job? The kit's skills are invoked, not hooked; adopting a gate means adopting hooks as a delivery
   channel, which is a larger commitment than an adapter.

---

## 8. What this document does not propose

It proposes no implementation, no dependency, no task closure and no finding disposition. It
recommends filing **one** task — an opt-in structural-source adapter, blocked by the existing
co-change eval-harness task — and leaves that filing to the operator, per the standing agreement
that a defect is filed only when personally reproduced and a task is not created on the agent's own
authority.

Related: `[[cck-scope-support-kit-not-agent-framework]]`,
`[[a-control-needs-a-check-that-can-fail]]`, `[[verify-own-claims-before-asserting]]`,
`[[sequencing-is-a-claim-that-needs-checking]]`, `docs/ADAPTERS.md`, `docs/CHARTER.md` §5.

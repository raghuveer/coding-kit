<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — state and context: what persists, what is rebuilt, and what enters a window

**Tier:** T2 — it files nothing and changes no code, but it sets the order of about twenty open
tasks and proposes where one load-bearing vocabulary lives.
**Status:** design input. **A proposal, not a decision.** Nothing here is implemented, no task is
filed by this document, and no finding is marked. An independent reviewer reads it before any ADR
is drafted from it.

**Serves:** `T-20260912-state-and-context-management-has-no-unif`, filed at the operator's
direction of 2026-09-11: *"while using markdown files are ok where necessary, we need to plan state
management and context management with a clear focus."*

**Every number below is produced by a command named beside it, or cites the artefact it came from.
A number that cannot be measured today is marked so.** Figures are as of 2026-09-14 on `main` at
`5d56dbc`.

---

## 1. The state inventory

`git ls-files` and `wc -c` for the source column; `du`/`wc -c` for the derived column; row counts
from `sqlite3 .project/index.db`.

### 1.1 Source — authored, committed, text

| what | where | size | written by | read by |
|---|---|---|---|---|
| task files | `.project/tasks/*.md` | **201 files, 996,609 B** | `kit-task.sh`, humans, agents | `kit-index.sh`, every reader |
| the plan | `.project/plans/default.tsv` | **11,236 B** | `kit-plan.sh` | `kit-index.sh`, `task-context` |
| relations that are not orderings | `docs/dependency-map.tsv` | **22,678 B**, 187 rows | humans, agents | `kit_refs.py` |
| the event log | `.project/events.ndjson` | **350,755 B** | `kit-event.sh`, `kit-spend.sh`, `kit-finding.sh` | `kit-index.sh` |
| entry proposal | `.project/entry-candidates.md` | **11,890 B** | a model, per `ENTRY-PROPOSAL.md` | humans |
| census artefacts | `.project/census/**` | **2 files, 3,817 B** | `kit-claim.sh` | `kit-index.sh` |
| the profile | `.claude/project-profile.md` | part of **3 files, 14,223 B** | humans | everything, via `kit_cfg` |

### 1.2 Derived — rebuilt from the above, gitignored, disposable

| what | size | rebuilt by |
|---|---|---|
| `.project/index.db` | **1,912,832 B** | `kit-index.sh` |
| `STATUS.generated.md` | **30,606 B** | `kit-status.sh` |
| `.project/packs/` | **29,587 B in 18 files** | `kit-plan.sh --packs` |
| `entry-facts.tsv`, `entry-comment-runs.tsv`, `entry-report.md` | **8,319 B** | `kit-entry.sh` |

Fifteen tables, all derived: `task` 201, `cochange` 1,694, `event` 1,474, `finding` 628, `edge`
467, `node` 356, `plan_item` 149, `spend` 73, `meta` 16, `state_alias` 13, `state_class` 7,
`goal` 1, and `accelerator`/`accel_candidate` at 0 — reserved schema for an unbuilt feature, with
a conditional exemption in the conformance suite that expires the moment anything writes to them.

### 1.3 Neither — machine-local, never shared

`.claude/settings.local.json` (a permission allowlist) and `.claude/settings.json` (hook
registration). The second is state the kit's *measurement* depends on and §4.3 returns to it.

### 1.4 The one thing that is code rather than data

The seven states and their four partitions are **shell functions** in `tooling/kit-lib.sh` —
`kit_state_vocab()`, `kit_state_closed()`, `kit_state_activity()`, and the two beside them.
`kit-index.sh:1231` projects them into `state_class`. §3 is about this.

---

## 2. The rule, and where it is already enforced

> **Anything a person or an agent decides is text in git. Anything a machine can recompute is
> derived and disposable. Nothing is both.**

This is not new — it is ADR 0004 for the plan and `kit-lib.sh`'s own words for the vocabulary:
*"Text is truth, the table is derived and disposable."* What this document adds is that it is
stated once, for everything, with the exceptions named.

**It is enforced by two conformance steps that must not be merged**, and the suite says so:

- *every table the schema declares is populated from text* — the expectation is **derived** from
  `CREATE TABLE` in `schema.sql` against the `INSERT` targets in `kit-index.sh`, so a table added
  next year is covered without an edit. It exists because `goal` and `plan_item` were silently
  lost across rebuilds until something enumerated the tables.
- *delete and rebuild is lossless* — catches a source that stopped working, which the first cannot
  see. Proved by mutation: disabling the plan ingest left the first step fully green.

`kit-index.sh:1466-1473` refuses to build at all when `state_class` comes out empty, because every
partition is a join against it and an empty table would classify all seven states as open.

### 2.1 The one violation, and it is a column

`goal.state` in `schema.sql` is reserved, unwritten, and reset to `'open'` by every rebuild. The
table-level check cannot see it because it is a column. Its own comment states the remedy:

> The condition for using it is a TEXT SOURCE first — a header in the plan file, derived like
> every other column — for the reason ADR 0004 records: a table nothing can rebuild from text is
> the second source of truth this design exists to avoid.

**Proposal:** `#goal_state` as a plan-file header, preserved across replans exactly as `#created`
already is (`kit-plan.sh:152` reads it back off the existing file before writing), validated on
read like every other header, because `kit-index.sh` classes a plan file as untrusted input and
parses it into SQL at the start of every session.

That puts the only exception back under the rule rather than adding a second mechanism for it.

---

## 3. The vocabulary: the operator's question, answered in two halves

> *"Cannot we maintain list of states in a JSON file, so that the kit's code is not changed to add
> a state?"* — operator, 2026-09-14.

**The direction is right, and it is consistent with everything above: a data file is text, so
moving the vocabulary out of shell into data does not weaken the rule, it completes it.** Today
the vocabulary is the only load-bearing thing in the kit that lives as code. Two constraints shape
the answer.

**Constraint one — the table must stay derived.** `T-20260819-vocabularies-live-in-shell-constants-so-`
is blunt: *"A master-data table that becomes authoritative recreates the exact defect."* A data
file as the source and `state_class` as its projection satisfies this. A data file that is loaded
into a table which then becomes the thing people edit does not.

**Constraint two — a state is not a name.** ADR 0008 gives each state four independent booleans,
and the schema comments insist none is derivable from another: `on-hold` is open but not
plannable; `cancelled` is closed but not measured; `abandoned` is both closed and measured,
*"because it was real work, and hiding it would flatter the record."* So the file is a five-column
table, not a list — and a wrong partition is silent, changing what escape rate counts and what the
planner may order.

There is a third thing to carry: **13 legacy spellings** in `state_alias`, because 127 commits
already say `Task-Status: started|progress|done` and are immutable.

### 3.1 Proposal — the vocabulary is kit-owned data; a project may add spellings, not states

Splitting the question is what makes both halves answerable:

| | proposal | why |
|---|---|---|
| **the seven states and their partitions** | move from `kit-lib.sh` into a data file that **ships with the kit**; `kit-index.sh` projects it into `state_class` as it does today | adding a state stops being a code change. It does **not** become a per-project decision, because the partitions are the semantics of the kit's own numbers — a project that redefines `is_measured` silently changes what every escape rate in every report means |
| **spellings** | a project may map its own vocabulary onto a canonical state, through the profile, as repeatable keys | this is the extension adopters actually need — a brownfield repo arrives with `Status: WIP` already in its history — and `state_alias` is the mechanism that already exists for exactly this |

This answers `T-20260819`'s fifth acceptance criterion, which asks that per-project extension be
*"designed or explicitly refused, not left ambiguous"*: **refused for states, granted for aliases.**

### 3.2 Where the file should live, and a recommendation

Three homes were considered. `[judgement]`

- **`tooling/states.json`, shipped in the kit.** Fixes the code-change problem. Needs a JSON
  parser on a path that `kit-lib.sh` is sourced into by every script — and the kit already depends
  on `python3` (four tools shell out to it), so this is not a new dependency, only a new call.
- **A file in the adopted repo.** Grants per-project extension, which §3.1 argues against.
- **Rows in `project-profile.md`.** No new file and no new parser: `kit_cfg_all` already reads
  repeatable structured keys, and `tier.rule: tooling/** T2` is the exact precedent for a key
  carrying a pattern and a value. But it puts a kit-owned vocabulary in a project-owned file,
  which invites the editing §3.1 refuses.

**Recommended: `tooling/states.json`, kit-owned, read once by `kit-index.sh` at derivation time —
not by `kit-lib.sh` on every source.** The shell functions become thin readers or disappear. The
aliases a project adds go in the profile, where project-owned things belong.

**The check that makes it safe, and it must exist before the move:** `state_class` rebuilt from
the file equals the seven states and four partitions the current shell functions produce. That is
a check that can fail, and it is the whole safety argument for touching a vocabulary that every
partition in the kit joins against.

### 3.2.1 The scattered-literals figure is stale, and the job is smaller than the repo thinks

`kit-lib.sh` still carries this, as a standing instruction to whoever does the move:

> `grep -rc "'done','abandoned'" tooling/` — 19, in kit-status(7) kit-index(6) kit-plan(5) kit-lib(1)

**Re-run today that grep returns 4, not 19**, and the survivors are not what the note implies:

| | |
|---|---|
| `kit-index.sh:1224`, `kit-status.sh:251`, `schema.sql:12` | **comments**, each describing the refactor as already done |
| `kit-index.sh:1305`, `schema.sql:60` | `DEFAULT 'created'` — a default value, not a partition test |
| **`kit-status.sh:67-69`** | **the only genuine hardcoded partition left**: three `WHERE state='completed'` / `'cancelled'` / `'abandoned'` counts |

So the consumers were migrated to join against `state_class` at some point and **the note was never
updated**. This matters twice. It makes the move to a data file a much smaller job than the
backlog believes — three lines in one file, not nineteen across four. And it is itself an instance
of the defect this document is about: a figure that was true, is now false, and is quoted as
current by anyone who reads it. It was taken at face value in this document's first draft and
caught only by re-running the command beside it.

`kit-status.sh:67-69` is also the exact symptom `T-20260819` names — a distribution that shows
only the values that *occurred*, so a state with zero rows is indistinguishable from a state that
does not exist.

### 3.3 Two vocabularies, not one

`state` and the `Task-Status` trailer are **different sets** today. `open` is a valid state and an
invalid trailer value, and that difference has already turned the `trailers` CI job red once. Any
file that claims to hold "the states" must either carry both and say they differ, or carry one and
name the other. Silently merging them is the failure this section exists to prevent.

---

## 4. The context model

State is what persists. Context is what enters a window, and it is where the token question lives.

### 4.1 Resident — paid in every session, whether or not the kit is used

| | measured | source |
|---|---|---|
| 9 agent descriptions | **2,944 B** of description text | `awk` over `agents/*.md` frontmatter |
| 5 skill descriptions | **1,209 B** | `awk` over `skills/*/SKILL.md` |
| `CLAUDE.kit.md` | **2,005 B, 33 lines** | `wc` |
| this repo's own `CLAUDE.md` | **6,953 B, 102 lines** | `wc` |

`MODELS.md` puts the agent half at **~840 tok of a ~1,259 tok always-on cost**, measured with
`claude --plugin-dir . plugin details coding-kit`. **Note the drift: it says eight agents and nine
ship**, so the figure understates by about a ninth. Adding a tenth agent adds to this; changing
what a model alias resolves to does not.

### 4.2 Per session and per task

| | measured |
|---|---|
| `kit-plan.sh --show` | **24,528 B** — the largest single kit output an agent can pull into a window |
| `STATUS.generated.md` | **30,606 B** |
| one cluster pack | **mean 1,643 B**, largest 7,601 B, across 18 packs |

**The pack is the design working.** `HANDOFF.md:174` — *"the plan is state, not context"* — and
`kit-plan.sh` rule 2 says a task session reads **one row**, not the plan and not the graph. A pack
at 1.6 kB against a 24.5 kB plan dump is that rule paying off, and `spend.pack_loads` exists
precisely so the two arms can be compared rather than assumed.

### 4.3 Where the cost actually is — and why no reduction is measurable today

From the 2026-09-09 highper-gateway trial: the main loop read **145,641 tokens at turn 51** and
**324,496 at turn 267**, and accounted for **10,259.6 of 11,014.2 kBTE — 93.1%**. `DESIGN-NOTES.md`
§0: cache-read ratio **97.5%**, effective input multiplier **0.129×** against a **0.100×** floor,
so **≤22% headroom** on caching. The conclusion drawn there binds anything proposed here: *the
remaining levers are peak context window and model mix; a design that adds structure without
touching either is not a token improvement.*

**And the instrument is dark.** `sqlite3 .project/index.db "SELECT MAX(at) FROM spend"` and
`grep '"kind":"spend"' .project/events.ndjson | tail -1` both give **2026-09-10T03:22:11Z**.
Nothing since — four days and at least four sessions. The cause: `.claude/settings.json` registers
the hook through `$CLAUDE_PROJECT_DIR`, and sessions run from the parent workspace directory,
which has no such file. Meanwhile `kit-preflight.sh --spend` reports **`spend capture is live --
78 event(s), 73 row(s)`, exit 0**, because it asks whether anything was *ever* recorded, not
whether it is recording now.

**That is a green check over a dead instrument, and it is the first thing to fix.** Every token
figure this document or any successor produces rests on that series.

**Cannot be measured today, and marked as such:** escape rate by tier — the `via:kit`
denominators are **0 for T0 and T1**, and 197 tasks carry unknown provenance. So the pairing
`HANDOFF.md` §9 demands — *"every metric here improves if you simply review less; pair it with
escape rate before concluding anything"* — cannot currently be honoured for a compression change.
**A reduction proposed before that is repaired is unfalsifiable.**

### 4.4 On third-party output compression

Raised by the operator, with `rtk` as the example: a hook that filters Bash output before it
reaches the model. The mechanism is sound in principle — the main loop is 93.1% of spend and tool
output is most of what fills it — and three things bound what the kit should do with it.
`[judgement]`

1. **It is adapter surface, not core.** A `PreToolUse`/`PostToolUse` hook is Claude Code's shape.
   A second host re-solves it. Nothing about it belongs under `tooling/`.
2. **It is lossy, and the kit's own controls read tool output.** A summariser that drops a line
   `kit-preflight.sh` printed turns a gate into a guess.
3. **The portable half is free and is not a hook at all** — make the command emit less rather than
   filter after. That half lives in the kit: `kit-plan.sh --show` at 24.5 kB and
   `STATUS.generated.md` at 30.6 kB are the kit's own output, and a `--brief` on each is a
   reduction no adapter has to re-implement.

**Recommendation: take the portable half; do not vendor a tool the kit cannot measure.** Revisit
the hook after §4.3's instrument is alive, and judge it on a before/after with escape rate beside
it, per the standing rule.

---

## 5. Core and adapter

`T-20260819-the-claude-adapter-is-16-files-but-nothi` measured the split: a **portable core** of 18
shell scripts, a sqlite schema and text files; a **Claude adapter** of 16 files.

Against that boundary, this document's proposals sort cleanly:

| | core | adapter |
|---|---|---|
| the state rule (§2) | yes | |
| `#goal_state` (§2.1) | yes | |
| the state vocabulary as data (§3) | yes | |
| `--brief` outputs (§4.4) | yes | |
| spend capture | **currently core, and wrongly so** | belongs here |
| output-filtering hooks (§4.4) | | yes |

**The one that is misplaced today is spend.** `tooling/kit-spend.sh` lives in the core and depends
entirely on Claude Code's formats: the hook payload fields `transcript_path` and `agent_type`, the
`<session>/subagents/agent-<id>.jsonl` layout, and Anthropic's `input_tokens` /
`cache_read_input_tokens` usage fields. The boundary check that task proposes — no harness name,
model name or `CLAUDE_*` variable under `tooling/` — **passes today and would miss this entirely**,
which the task's own 2026-09-11 note already records. A second form is needed, one that looks for
foreign data *formats* rather than names.

So the context model has an adapter-shaped hole in it: **what a second host must supply is a reader
that emits the kit's own `spend` event.** That is the portable contract, and it is not written down
anywhere today.

---

## 6. The tasks, mapped, with an order

The open tasks the umbrella names, sorted by what they unblock rather than by tier.

**First — the instrument, because everything after it is measured against a series.**

1. `T-20260821-the-kit-does-not-measure-its-own-develop` — substantially landed
   (`.claude/settings.json` exists and is tracked; 30 main + 43 subagent rows), but §4.3 shows it
   dark since 2026-09-10. The gap is the workspace-rooted session, and a `--spend` arm that cannot
   detect silence.
2. `T-20260911-kit-status-reports-spend-with-no-as-of-t` — a reading with no as-of time; 33% low
   in trial 1.

**Second — the rule made total.**

3. `#goal_state` (§2.1), under `T-20260819-goals-are-the-milestone-mechanism-and-on`.
4. `T-20260912-paths-state-moves-the-state-directory-bu` — `paths.state` exists and does not move
   everything.
5. `T-20260819-vocabularies-live-in-shell-constants-so-` (§3) — smaller than it reads: §3.2.1
   measures **three** genuine hardcoded literals, not the nineteen its own note still claims.

**Third — context, once it can be measured.**

6. `T-20260912-reduce-peak-context-per-session-and-meas` — deliberately blocked on 1; the block is
   correct and the blocker is nearly clear.
7. `T-20260808-cluster-packs-are-generated-and-read-by-` — the ROI question §4.2 has the
   instrumentation for and no reading of.
8. `T-20260911-kit-status-re-decides-pack-withholding-w`, `T-20260817-a-cluster-pack-file-list-ignores-declare`.

**Fourth — the seams, none of which blocks the above.** The plan and index group
(`T-20260820-kit-plan-computes-the-ordering-before-re`, `T-20260821-kit-plan-writes-two-meta-keys-the-indexe`,
`T-20260818-nothing-reviews-the-plan-so-a-wrong-orde`, `T-20260808-decompose-kit-index-along-the-seam-it-al`),
the task-state group (`T-20260822-legacy-state-spellings-in-task-files-sho`,
`T-20260808-task-state-cannot-express-no-longer-rele`, `T-20260822-derived-owner-flips-to-whoever-committed`),
and session state (`T-20260811-restore-session-state-from-checkpoint-co`,
`T-20260827-discovery-is-a-multi-session-phase-with-`).

### 6.1 The open decision this document does not take

Whether the umbrella task **blocks** the 18 tasks it names. They are recorded as `umbrella-member`
in `dependency-map.tsv` precisely so the question stays visible, and 18 edges hang on the answer.
This document proposes an order; it does not convert that order into blockers, because an ordering
argued in a document and an ordering the planner obeys are different claims, and this repository
has paid for confusing them.

---

## 7. What would falsify this

- **§3.1** if a real adopter needs a state the seven do not cover. The refusal is a judgement about
  semantics, and one counter-example is enough to reopen it.
- **§4.4** if, once the instrument is alive, output filtering measures a large saving with escape
  rate flat. The recommendation is *"not yet, and not vendored"*, not *"never"*.
- **§2.1** if `#goal_state` proves insufficient for a second goal — the case that would show it is
  two goals sharing a task, which `T-20260819` already names as the interesting one and nobody has
  run.

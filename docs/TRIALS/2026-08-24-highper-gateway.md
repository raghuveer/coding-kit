<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-08-24

| | |
|---|---|
| Question | Does the kit's entry path turn a 763k-word brownfield documentation corpus into a task inventory its maintainer recognises, and do the brownfield degradations bite on a genuinely polyglot repo? |
| Kit SHA | `e4a594f` (v0.10.0) |
| Time-box / actual | 3h / ~1h20m |
| Unassessable crits | **9** (previous trial: **not recorded** — see §Methodology) |
| Superseded crits | **13** (previous trial: **not recorded**) |
| Subject | `highper-gateway` — 965 tracked files, 169 commits, 2025-11-24→2026-05-16, `rs` 291 / `md` 370 / `yaml`+`yml` 117 / `sh` 68 / `hcl`+`tf` 21 / `toml` 12 / `j2` 5 / `html` 4 / `php` 3 |
| Greenfield / brownfield | **brownfield**, full history, not truncated |
| Outcome | **COMPLETE** for the agreed scope — inventory and report only, no writes to the subject |
| Baseline before the kit | `cargo check --workspace --all-targets` **FAILS**, 63s. Tests **not runnable**. |
| Copy isolation verified | **YES** — `kit-preflight.sh --isolated` printed *no remote, no shared object store* |
| Instruments verified live | **NO** — findings recorder not exercised; spend recorder confirmed dead (see Cost) |

**Scope was agreed before starting** — inventory and report only. No code changes, and nothing
written into the operator's working repository at any point. The subject was cloned
`--no-hardlinks` to scratch and its remote removed before the kit touched it.

**The baseline failure is the environment, not the repo.** `aws-lc-sys v0.34.0`'s build script
fails under MSVC (`cl.exe` cannot compile `c11.c`). The subject's CI is `ubuntu-latest` across 15
jobs — Windows was never a target platform. **Consequence: no finding in this trial can be
confirmed by building, and none claims to be.**

## Cost (n on every figure)

**Not measured, n=0 — and this time an agent did run.**

`.project/events.ndjson` is **absent**; `kit-preflight.sh --spend` returns
*"STOP — no spend EVENT has ever been recorded here"*.

This is the same empty cost half as the `fd` trial, for a reason worth stating precisely because
it is not the obvious one: **running an agent is not sufficient.** The `researcher` was run through
the harness `Agent` tool, whose runs fire no kit hooks. Hooks run from `SubagentStop` and `Stop`
and only exist when the kit is loaded as a plugin **in the subject's own session**. A trial that
wants cost figures must invoke `claude --plugin-dir <kit>` from inside the subject, not call an
agent from the kit's development session.

The preflight's diagnostic said exactly this, unprompted, and was correct. That is the instrument
working.

Raw counters, all n=1 subject:

| | |
|---|---|
| `kit-entry.sh` | 72s, 965 files, 15,494 comment runs across 470 files |
| `kit-index.sh` | 3s |
| `researcher` run | 470s wall, 121,556 subagent tokens, 25 tool uses — **from the harness, not the kit; not attributable by the kit** |

## Findings

**By agent:** one agent ran (`researcher`). It returned 18 open questions, 103 candidates and 11
`Could not determine` entries. **None of it entered the findings recorder** — the entry path
produces a proposal, not findings, so `kit-review-record.sh` was never exercised and the
findings-capture instrument remains unverified on this subject.

**Escape rate:** `_no task recorded yet_`. Zero tasks, so both provenance populations are empty.
Not a clean result — an absent denominator, as on every trial so far.

## Which brownfield degradations bit

| Degradation | Result | Numbers |
|---|---|---|
| **Over-tiering from an empty edge table** | **BIT, as predicted** | `edge` = **0**. No `Task-Id` in 169 commits, so blast radius is unknown for every file. 97 of 97 non-trivial commits untagged; 72 exempt under `git.trivial_pattern`. |
| **Co-change** | **DID NOT DEGRADE — the headline result again** | 4,904 pairs over 483 files, avg degree **20.3**, 158 commits used, 9,808 rows. Under `cochange.max_degree: 50`, so **not withheld**. Richer than `fd`'s 722/97/14.9. |
| **Planner ordering on a backlog it did not author** | **NOT EXERCISED** | `plan_item` = 0. The planner needs tasks; tasks require the operator to accept candidates. Out of reach in an inventory-only pass, and it remains the criterion nothing has tested. |

**A degeneracy notice misled on first read.** `kit-entry.sh` reported `cochange empty:
indistinguishable from withheld / disabled / no history / no index` — because entry runs *before*
the index exists, and the true cause was *no index yet*. After `kit-index.sh` the graph is rich.
The notice is honest and correctly refuses to say "no dependencies", but on the documented adoption
order it will always fire, and its first-listed cause (*withheld*) is the alarming one.
`T-20260815-co-change-withheld-disabled-and-empty-ar` is this, seen live.

## Three kinds of finding

### Kit defects — proposed as tasks, not filed

Per the working agreement these are proposals; the operator runs the lines.

**K-1 (new, T2) — a fresh adoption cannot share its profile when the subject already ignores
`.claude`.** The subject's `.gitignore` carries `.claude/`, `**/.claude/`, `.claude-*` and
`*.claude`. `kit-init.sh` exits 0 and prints *"commit `.claude/project-profile.md` — the team
shares them"*; `git add .claude/project-profile.md` is **refused**. `kit-init.sh` edits
`.gitignore` in the same run without detecting that existing patterns exclude the file the kit
depends on. Greenfield cannot surface this. Consequence: a second developer gets nothing, which is
what `T-20260811-team-mode-bootstrap-so-a-second-develope` exists to prevent.

    kit-task.sh --title 'kit-init cannot share the profile when the repo already ignores .claude' --tier T2 --paths 'tooling/kit-init.sh,INSTALL.md'

**K-2 (new, T2) — the entry proposal format produces candidate lines its own validator refuses.**
Given the `docs/ENTRY-PROPOSAL.md` format verbatim, `researcher` wrote titles naming paths —
`3.1.F delete the orphaned src/admin/api.rs`, `3.7.A write docs/MONITORING.md …`. The title
whitelist is `A-Za-z0-9 space . _ -`, so `/` is refused: `kit: candidate line is not safe to
paste`. At least 10 of 103 candidates. The charset appears only in the grammar block under *"What
`--check` does and does not enforce"*, after the format section, expressed as a grammar rather than
as an instruction to the author. Either the format section states the charset, or the whitelist
admits `/`.

    kit-task.sh --title 'The entry proposal format does not state the title charset its own check enforces' --tier T2 --paths 'docs/ENTRY-PROPOSAL.md,tooling/kit-entry.sh'

**K-3 (reproduced, existing task) —
`T-20260814-a-fresh-adoption-reports-none-outstandin`.** Verbatim on this subject: *"none
outstanding (0 critical finding(s) recorded, **all marked addressed**)"*, having recorded nothing.
Reproduced on a real brownfield repo rather than argued.

**K-4 (reproduced, existing task) —
`T-20260814-the-absent-counter-notice-fires-on-every`.** The index was built minutes earlier on
`e4a594f`; the notice claims *"It was built before they existed"* and prescribes deleting and
rebuilding, which cannot help — the counters are absent because there is no event log.

**K-5 (confirmed from `fd`) — a freshly adopted brownfield repo has no tier floors.** Zero
`tier.rule` lines in the shipped profile template, and `commands.build/test/lint/typecheck` all
empty. `fd` found this on 2026-08-12; it reproduces. Not a one-off.

**K-6 (new, T3) — accelerator repeatability is invisible to the adopter.** `accelerator.technology`
/ `.industry` / `.pattern` **are** repeatable — `tooling/kit-accel.sh:41` says so and `kit_cfg_all`
reads them that way at `:45` and `kit-finding.sh:167`. The profile template an adopter fills in
never says so; only `ingest.extra` is marked repeatable there. This matters precisely on the
polyglot case, where one value per axis is not enough.

    kit-task.sh --title 'The profile template does not say the accelerator keys are repeatable' --tier T3 --paths 'templates/project-profile.md'

**K-7 (new, T2, found in the walkthrough) — the provenance vocabulary cannot express AI-assisted
work done without the kit.** `kit_via_vocab` is exactly `kit agent manual unknown`
(`tooling/kit-lib.sh:126`). The maintainer's account of how this subject was built is *"before I
started creating sub-agents, mostly up to Sonnet 4.5 on Claude subscription"* — a human driving an
assistant interactively, no kit, no subagents. **None of the four values says that:** `kit` is
false, `agent` implies an agent ran it, `manual` erases the assistant, and `unknown` is honest but
discards information the maintainer actually has. The proposal wrote `--via manual` on all ten
completed candidates; under that account it is **false on all ten**, and `unknown` is the only
defensible value today.

This is not an edge case on this subject. Escape rate is reported over `via:kit` and over `all`,
and the population between them — **AI-assisted but not kit-run** — has no name. The maintainer
reports a second project in the same state. A kit whose thesis is human-plus-AI collaboration
cannot currently label the ordinary case of it.

    kit-task.sh --title 'The provenance vocabulary cannot express AI-assisted work done without the kit' --tier T2 --paths 'tooling/kit-lib.sh'

**K-8 (field evidence for an existing task) —
`T-20260808-task-state-cannot-express-no-longer-rele`.** No longer a hypothesis. The subject's
roadmap uses five states (`[ ] [~] [x] [d] [k]`); the kit has no `deferred`, so four of the five
proposed cancellations were `[d]` mapped to `cancelled`. **The maintainer then contradicted one of
them in the same conversation** — see the walkthrough below. A vocabulary gap that silently
converts *"do this later"* into *"never do this"* is now demonstrated end to end, on a real
backlog, with the owner present.

### Subject defects — a proposal for the subject's owner, filed nowhere

`.project/entry-candidates.md` on the copy: **18 open questions, 103 candidates, 11 Could-not-determine**,
`kit-entry.sh --check` → *"proposal conforms — 18 question(s), 103 candidate(s), none filed by this
check"*. Nothing has been filed from it. The 103 split **88 new work · 10 already-finished · 5
should-never-be-done**, tiered T0 ×6, T1 ×45, T2 ×37, T3 ×15.

**After the walkthrough below: 1 of the 10 confirmed, 1 of the 5 refuted, the rest open.**

The strongest items are the ones that read the v1→v2 roadmap transition against the tree: roughly
60 v1 per-UC backlog items and the whole competitor net-add table appear in neither v2 nor any
disposition; several v2 line citations no longer resolve after a workspace-wide `cargo fmt`; a
runtime-config lint hard-fails on four paths of which two do not exist; and a CI job validates every
scenario config but appends an echo so it cannot fail.

### Methodology — for TRIAL-PROTOCOL §3, with their detection

**M-1 — a transcribed agent output is not the agent's output.** The `researcher` returned its
proposal as text; the orchestrator must save it. While transcribing, this session **normalised
titles containing `/`**, so the first `--check` run validated a cleaned document and passed. The
defect K-2 was recovered only by re-probing `--check` with one of the agent's verbatim titles.
**Detection: run `--check` on the agent's output byte-for-byte before any editing.** A proposal
that passes after the orchestrator tidied it has measured the orchestrator.

**M-2 — §0's stop rule 2 is unevaluable on first use.** It requires comparing the unassessable
count against the previous trial's report; `docs/TRIALS/2026-08-12-fd-throwaway.md` carries neither
the unassessable nor the superseded count, because it predates both verbs. This trial sets the
baseline at 9 and 13. §6 requires both reports to carry it and the first pair cannot.

**M-3 — an accepted stop condition, recorded rather than discovered.** Four of the nine
unassessable criticals sit on tasks this trial exercised — two on
`T-20260801-nothing-invokes-kit-finding-so-the-findi` (the findings pipeline) and two on
`T-20260808-record-how-a-task-was-executed-so-kit-wo` (how work was executed). §0 calls that a
stop. The operator accepted it explicitly before the trial started, so the blind spot is inside the
measured path and this report says so.

## Not exercised

- **Every reviewer agent.** No `coder`, no `implementation-reviewer`, no `security-reviewer`, no
  `tier-classify`. One agent ran, and it was `researcher`. The quality claim remains untested on
  unfamiliar code — the same gap `fd` reported.
- **Cost.** n=0. See Cost; the fix is to run the subject under `--plugin-dir`, not to run more agents.
- **The findings recorder.** `kit-review-record.sh` was never invoked; the entry path produces a
  proposal, not findings.
- **`ingest.tasks` as an adapter.** INSTALL §C.3 says a roadmap should be ingested by an executable
  emitting SQL; only a CSV reference adapter ships, so the §C.4 model-proposal route was used
  instead. Whether §C.3 is executable on a markdown roadmap is untested.
- **The planner and the clustering rules.** Both need tasks to exist.
- **The questions file.** Procedure step 3 saves `<paths.design_input>/YYYY-MM-DD-entry-questions.md`
  as a second artefact; the questions were left in `entry-candidates.md` and the split was not
  performed, under the time-box.
- **Build and test verification of anything**, per the baseline.

## Walkthrough with the maintainer — 2026-08-24, same day

The inventory was walked in order of cost-of-being-wrong rather than document order: the ten
`completed` claims first (they assert work is finished), then the five `cancelled` ones (they
assert work should never happen), then the six T0 tiers, then the four questions that move many
candidates at once.

**Ten claims that work is already finished — 1 confirmed, 9 open.**

- **Confirmed:** the SBOM and CVE scan workflow.
- **Left deliberately unconfirmed:** `3.3.A`, the CI gate on the `rsa` crate. The agent claimed it
  done **against the roadmap, which still lists it pending**, on the strength of reading a workflow
  file. That is exactly the claim a maintainer should settle, and it was not settled here.
- The remaining eight stay open. Five of them (`B4.1`, `B4.2`, `B6`, `B11`, Workstream 0.J) come
  from the roadmap's own status snapshot and are low-risk, but low-risk is not confirmed.

**Five claims that work should never be done — "mostly true", with one refuted.**

`3.10.C UC16 vertical implementation` is **wrong**. The maintainer confirmed the set broadly and
then, in the same message, described the plan for UC16: a comparative study of LiteLLM alternatives
first, **then implementation using the kit**. That is *deferred pending research*, the exact
opposite of `cancelled`. Filing that line would have removed a planned programme from the backlog
permanently.

**This is the trial's most valuable single result.** It is not that the model mis-classified —
given a vocabulary of `created | completed | cancelled`, `cancelled` was the least-wrong available
value for a `[d]`. The defect is the vocabulary, the loss was silent, and it took the owner reading
one line to catch it. Nothing in the kit would have.

**Provenance.** The maintainer's account of how the subject was built invalidated `--via manual` on
all ten completed candidates and produced K-7 above.

## Disputed

- **`3.10.C UC16` — disputed and resolved against the inventory.** Proposed `cancelled`; the
  maintainer's stated plan makes it deferred. Recorded rather than corrected in place, because the
  kit has no state to correct it *to*.
- **`3.3.A` rsa CI gate — unresolved.** The agent says complete, the roadmap says pending, the
  maintainer did not adjudicate. It stays unconfirmed, which is the honest state.

---

**The copy is retained and is contaminated** — it carries an adopted kit, a built index and the
proposal. Path: the session scratchpad, `trial-highper/subject`. It is not the operator's working
repository, which was never written to.

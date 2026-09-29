<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway (inventory unit) — 2026-09-29

> **Status: PRE-FLIGHT, written before the clock.** Everything above "Results" is fixed before
> the first prompt; the prompts are pasted verbatim. Procedure: `docs/TRIAL-PROTOCOL.md` with
> `docs/TRIAL-INVENTORY-UNIT.md` (adopted for this trial, ruling 4). Task:
> `T-20260928-trial-4-inventories-the-gateway-roadmap`, which holds rulings 1-8. The prompts were
> reviewed blind before being pinned (REVISE: 2 critical, 6 major; all applied).

| | |
|---|---|
| Question | *"Given `docs/planning/ROADMAP.md` (85 open items) and the documents it names at `e588b53`, does the kit's entry path yield candidates the maintainer confirms as real and correctly scoped, and does `kit-plan.sh` order them consistently with the roadmap's stated dependencies and risk-class order?"* (ruling 8) |
| Kit SHA | `6aa066f` at pre-flight — `main`, CI 152 PASS / 0 FAIL on ubuntu, macOS and Windows (run 36464754051). The SHA the trial runs on is the merge of this record, noted at step 1 |
| Time-box / actual | 1 h, STOP / CONTINUE recorded at the boundary, cap 2 h (ruling 7) / *filled after* |
| Runtime | `MINGW64_NT-10.0-26200 3.6.6 x86_64`, Windows 11 host, no container; Claude Code 2.1.284 |
| Unassessable crits | 9 (previous trial: 9) |
| Superseded crits | 40 (previous trial: 40) |
| Subject | highperapp/highper-gateway at `e588b53`: Rust (291 `.rs`), 968 tracked files, 173 commits since 2025-11-24 |
| Greenfield / brownfield | brownfield; full history cloned; `git.adopted_at` = adoption commit `9d0cae9` |
| Rung dispositions | 5 × `ladder not invoked — inventory unit` (annex §2) |
| Outcome | *filled after:* COMPLETE \| ABORTED (*cause*) \| VOID (*condition*) |
| Baseline before the kit | recorded, decides nothing (annex §1): upstream CI at `e588b53` — see below |
| Instruments verified live | *in the trial session, before the clock: run sheet step 3* |
| Copy isolation verified | `kit-preflight.sh --isolated`: exit 0, "no remote, no shared object store, no permission rule reaching outside it" |

## Rung dispositions

| Rung | Obligation | Command | Disposition |
|---|---|---|---|
| 1 | compiles + static analysis | none | ladder not invoked — inventory unit (annex §2, adopted by ruling 4) |
| 2 | criteria proven by tests that fail without the change | none | ladder not invoked — inventory unit (annex §2, adopted by ruling 4) |
| 3 | wiring proof | none | ladder not invoked — inventory unit (annex §2, adopted by ruling 4) |
| 4 | adversarial reader | none | ladder not invoked — inventory unit (annex §2, adopted by ruling 4) |
| 5 | blind second reader | none | ladder not invoked — inventory unit (annex §2, adopted by ruling 4) |

## Baseline before the kit

No build runs in this unit; the baseline is recorded so a later code-change trial on the same SHA
can compare. **Upstream CI at `e588b53`, by job** (GitHub Actions, `highperapp/highper-gateway`):

| CI job | verdict | cause |
|---|---|---|
| Build Release | success | |
| Format | success | |
| Validate Configs | success | |
| Check | failure | 90 errors, two causes, measured by trial 3 (`docs/TRIALS/2026-09-20-highper-gateway.md`); not re-measured here |
| Clippy | failure | **unverified** for this SHA beyond trial 3's reading |
| Test | failure | two `runtime_config` tests, per trial 3; **unverified** here |
| Security Audit | failure | **unverified** |

`commands.*` in the copy's profile are empty: `kit-preflight.sh --commands` exits 0 and prints
"NOTHING DECLARED" per command. Recorded at step 3; not outcome-bearing (annex §1).

## Pre-flight (protocol §0 and annex §1)

**The kit**
- [x] Tree at `6aa066f`, CI green on every platform, counted by `FAIL` lines.
- [x] `kit-preflight.sh --criticals`: "no unfixed critical outstanding". (15 on K3 were marked in #186.)
- [x] Unassessable: 9. Superseded: 40.
- [x] **The kit checkout is not edited, switched or pulled from step 1 until copy-back**: the
      plugin loads its working tree.

**The instruments** — in the trial session, run sheet step 3.

**The subject**
- [x] Copy `D:/trials/trial4-highper-gateway-e588b53`, cloned from **upstream** (never from the
      maintainer's checkout) with `core.autocrlf=false`: 0 files with CRLF. `origin` removed.
- [x] The subject tracked `.claude/settings.local.json` pre-approving `Bash(git *)` and `git -C`
      commands naming `D:/my-opensource/highper-gateway` — the oracle's tree. Moved out to
      `D:/trials/trial4-highper-gateway-e588b53.settings.local.json.orig`, recorded as copy commit
      `1aab221`. Then `--isolated`: exit 0.
- [x] Adoption (`9d0cae9`, `0872aae`): `kit-init.sh` exited 1 naming both blocked paths and
      remedying one (**K5, a third time**). Re-included with trial 3's block plus
      `.project/events.ndjson`, `.project/entry-candidates.md` and `.project/plans/`.
      `git.adopted_at` = `9d0cae9`. `kit-index.sh` and `kit-status.sh` exit 0 on the copy:
      0 tasks, 0 `touches` edges.
- [x] Owner: the operator.

**The trial**
- [x] Question, time-box and stop rules: rulings 7 and 8. Stop also on: a kit crash, a
      permission denial, or any VOID condition noticed live.
- [x] Abort path: the copy is disposable. Record what ran, the stage reached, and stop.

**Annex additions**
- [x] Annex adopted (ruling 4).
- [x] Subject of record `e588b53`. The maintainer's checkout: `4da4c07`, 48 local-only / 4
      upstream-only, merge base `05c56eb`. **The maintainer confirms against `e588b53`, not their
      own tree.**
- [x] **Reachability, chosen and stated:** the session runs on the host, so the maintainer's
      checkout is reachable, and the subject's own roadmap names it (`ROADMAP.md:76`, and 36
      tracked files mention `my-opensource`). Mitigated by the brief (no web tools, no absolute
      path but one) and detected by the leak check over tool inputs (annex §2).
- [x] Other tree's before-state: `D:/trials/trial4-evidence/other-tree-before.txt` (HEAD, status,
      `count-objects -v`) and `marker-before`, taken 2026-09-29T01:37Z.
- [x] Backlog baseline: `D:/trials/trial4-evidence/backlog-baseline.txt` — `ROADMAP.md` blob
      `794c04e`, 85 items all `[ ]` (41 UC ids, 44 §3 ids), the counting command, and the cited
      documents present at `e588b53` with their blobs. `GA_CHECKLIST.md` and
      `RELEASE_NOTES_v1.0.md`, which the roadmap names, do not exist at this SHA.
- [x] Mappings, walk scope, order-comparison method: rulings 5 and 7. Epics map to the roadmap
      section: `uc1`…`uc15` for §2.1…§2.15, `ws3-1`…`ws3-11` for §3.1…§3.11 (`--check` accepts
      only `[A-Za-z0-9_-]`).
- [x] Adoption shape: as above, frozen for the trial.
- [ ] Researcher resolves as `coding-kit:researcher` — run sheet step 3. **If not, stop.**
- [x] Oracle sealed: the 28 closures are derived only AFTER the trial, by
      `git -C D:/my-opensource/highper-gateway log --format=%s 05c56eb..4da4c07 | grep -oE 'UC[0-9]+\.[A-Z]' | sort -u`.
      Prediction: all 28 are `created` in a correct inventory at `e588b53`. **One path outside
      the copy is allowed by name**: the format file
      `D:/personal-github/cck/coding-kit/docs/ENTRY-PROPOSAL.md`.

**Predicted**, so the run can confirm or refute it: plan run 1 plans **nothing**, because the index
was last rebuilt at step 3 with 0 tasks and `kit-plan.sh` orders from the index it finds
(`T-20260820-kit-plan-computes-the-ordering-before-re`); run 2, after `kit-index.sh`, is the plan.

## Run sheet

1. **Freeze the kit.** In the analysis session, confirm the kit checkout is on `main` at the merge
   of this record and clean except `.project/events.ndjson`; note the SHA. Do not touch it again
   until copy-back.

2. **Open a new terminal** (Git Bash) and start the trial session in the copy:

       cd /d/trials/trial4-highper-gateway-e588b53
       claude --plugin-dir D:/personal-github/cck/coding-kit

3. **Pre-flight, before the clock.** Paste **P0** verbatim. Stop if the researcher does not
   resolve, `--spend` fails, or the probe row does not land. Note the probe's `agent_id`: the
   leak and authorship detections exclude it.

4. **Start the clock.** Note the UTC time. Paste **P1** verbatim.

5. **When P1 stops**, paste **P2** verbatim.

6. **The walk (you).** Open `docs/design-input/2026-09-29-entry-confirmations.md` in the copy (in
   an editor, not in the trial session). Fill the header lines. For each row with `walk: yes`,
   write `confirmed`, `refuted` or `unjudged`, a reason, and for a confirmed non-`created` state
   the evidence **at `e588b53`**. Rows with `walk: no` stay empty and are not filed. At the
   1-hour mark, write `STOP` or `CONTINUE` and the UTC time in the file.

7. **Paste P3** verbatim.

8. **End the session** (`/exit`). Note the UTC time. Tell the analysis session "trial 4 ran": it
   copies back, runs every VOID detection, fills this record, and files defects before any fix.

### P0 — pre-flight, before the clock

> Trial 4 of coding-kit, an inventory unit, is about to start in this repository. Before the
> clock, do exactly these checks and report each result verbatim; do not start any trial work,
> and do not fix anything that fails — report it and stop.
> (1) Confirm the agent `coding-kit:researcher` is available to you; if it is not, say so and
> stop. (2) Spawn one throwaway `coding-kit:researcher` subagent with the prompt "Reply with the
> single word ready." Report its agent id. Then run
> `bash D:/personal-github/cck/coding-kit/tooling/kit-preflight.sh --spend` and report the output
> and exit code, including the `agent` value the spend row carries. (3) Run
> `bash D:/personal-github/cck/coding-kit/tooling/kit-preflight.sh --commands` and report the
> output and exit code. (4) Write `{"findings":[]}` to `.project/probe-reply.json`, run
> `bash D:/personal-github/cck/coding-kit/tooling/kit-review-record.sh --unattributed --agent probe --reply-file .project/probe-reply.json`,
> and report its output, exit code, and the last line of `.project/events.ndjson`.
> (5) Commit `.project/events.ndjson` alone, message `trial: pre-flight probes`, then run
> `git status --short` and report it (expected: empty).

### P1 — the clock starts

> Trial 4, an inventory unit, runs now under `docs/TRIAL-INVENTORY-UNIT.md` in the kit at
> `D:/personal-github/cck/coding-kit`. Do exactly these steps, keep every temporary file under
> `.project/` in this repository, and stop where told. You orchestrate; you do not judge.
>
> 1. Run `bash D:/personal-github/cck/coding-kit/tooling/kit-entry.sh` and report its summary.
>    Run `date -u +%Y%m%d` and use its output as DATE below.
> 2. Spawn the `coding-kit:researcher` subagent **once**. Do not do its judgement yourself. Give
>    it this brief, verbatim except for DATE, then the file list:
>
>    "Produce an entry proposal in the exact format of
>    `D:/personal-github/cck/coding-kit/docs/ENTRY-PROPOSAL.md`: `## Open questions`, then
>    `## Candidate tasks`, then `## Could not determine`. The backlog is `docs/planning/ROADMAP.md`:
>    85 items, every one marked `[ ]`. Propose one candidate per roadmap item you judge real, and
>    list in `## Could not determine` each item you did not propose, with why. Every candidate
>    cites evidence as path or path:line and carries its `kit-task.sh` line on a line of its own:
>    beginning with `kit-task.sh`, not in backticks, not wrapped. Nothing outside
>    `## Candidate tasks` may contain the text `kit-task.sh --title`.
>    The title is single-quoted, begins with the roadmap id (`UC3.A ...` or `3.1.A ...`), and
>    contains only letters, digits, spaces, `.`, `_` and `-`. `--epic` is the roadmap section:
>    `uc1` to `uc15` for sections 2.1 to 2.15, `ws3-1` to `ws3-11` for sections 3.1 to 3.11.
>    `--state created` unless this tree shows the item already done; then
>    `--state completed --via unknown`, citing the evidence in this tree. Where the roadmap says an
>    item depends on another candidate, add `--blocked-by` with that candidate's id, computed as:
>    `T-DATE-` followed by its title lowercased, every run of characters other than a-z and 0-9
>    replaced by one hyphen, a leading or trailing hyphen removed, then cut to the first 40
>    characters. Do not use WebFetch or WebSearch. Open no absolute path except the format file
>    named above; read only files inside this repository."
>
>    Files: `.project/entry-report.md`, `.project/entry-facts.tsv`,
>    `.project/entry-comment-runs.tsv`, `docs/planning/ROADMAP.md`, `README.md`, `CLAUDE.md`,
>    `CHANGELOG.md`, `KNOWN_LIMITATIONS.md`, `docs/ARCHITECTURE.md`, `docs/CONFIG_ENV.md`,
>    everything under `docs/planning/archive/2026-05-16-v1/`, and the source tree for evidence.
> 3. When it returns, write its reply text to `.project/entry-candidates.md` exactly as returned:
>    the reply text only, no tool-result footer or usage lines, nothing added, removed or
>    reformatted, and no trailing newline added. If the reply is malformed, write it anyway: do not
>    edit it, re-ask, or spawn again. Do nothing else in this turn — no commit, no check. Report
>    the byte count and stop.

### P2 — after the reply (a later turn)

> Continue trial 4. Do not edit `.project/entry-candidates.md`, re-ask, or re-spawn, whatever the
> results below.
> 1. Commit `.project/entry-candidates.md` and `.project/events.ndjson`, message
>    `trial: researcher reply, verbatim`.
> 2. Run `bash D:/personal-github/cck/coding-kit/tooling/kit-entry.sh --check .project/entry-candidates.md`,
>    save its full output to `.project/check-output.txt`, and report the output and exit code.
>    A non-zero exit is a result; record it and continue.
> 3. Copy the `## Open questions` section of `.project/entry-candidates.md`, unchanged, to
>    `docs/design-input/2026-09-29-entry-questions.md`.
> 4. Create `docs/design-input/2026-09-29-entry-confirmations.md`. Start it with three lines to be
>    filled by the maintainer: `confirmed by:`, `at (UTC):`, `against: e588b53`. Then a table with
>    one row per candidate line, in the order they appear, columns
>    `title | proposed state | check | walk | disposition | reason | evidence at e588b53`.
>    `title` is the `--title` value, verbatim, without its quotes. `proposed state` is the
>    `--state` value, or `created` if the line has none. `check` is `refused` for a line
>    `--check` refused, else `ok`. `walk` is `no` for a refused line; otherwise `yes` for every line
>    whose state is not `created` and for every 4th `created` line counting down the file (the 4th,
>    8th, 12th, ...), `no` for the rest. Leave the last three columns empty.
> 5. Commit both files and `.project/events.ndjson`, message `trial: questions and walk list`.
> 6. Report counts: candidates by state, questions, `--check` refusals, walk rows. Stop.

### P3 — after the walk

> Continue trial 4. The maintainer has filled
> `docs/design-input/2026-09-29-entry-confirmations.md`.
> 1. Commit it and `.project/events.ndjson`, message `trial: maintainer dispositions`.
> 2. For each row whose disposition is `confirmed` and whose `check` is `ok`, run its line from
>    `.project/entry-candidates.md` exactly as written, via
>    `bash D:/personal-github/cck/coding-kit/tooling/kit-task.sh ...`. Record every line run and its
>    exit code and message in `.project/filing-log.txt`. Run nothing for any other row.
> 3. Commit the filed task files and `.project/events.ndjson`, message
>    `trial: file confirmed candidates`.
> 4. Run `bash D:/personal-github/cck/coding-kit/tooling/kit-plan.sh --show > .project/plan-run-1.txt 2>&1`.
>    Commit `.project/plans/` and `.project/events.ndjson`, message `trial: plan run 1`. Run
>    `bash D:/personal-github/cck/coding-kit/tooling/kit-index.sh`, then
>    `bash D:/personal-github/cck/coding-kit/tooling/kit-plan.sh --show > .project/plan-run-2.txt 2>&1`,
>    then commit `.project/plans/` and `.project/events.ndjson`, message `trial: plan run 2`.
> 5. Run `bash D:/personal-github/cck/coding-kit/tooling/kit-status.sh`. Report the filing exit
>    codes by value, and from `.project/plan-run-2.txt` the number of layers and the first 15 rows.
>    Stop.

## Results

*Filled after the trial, by the analysis session: funnel, oracle, provenance, plan, clusters,
cost, the VOID detections with their outputs, defects filed, not exercised, disputed.*

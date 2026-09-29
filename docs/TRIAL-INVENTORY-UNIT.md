<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial protocol annex: an inventory unit

`docs/TRIAL-PROTOCOL.md` assumes the unit of work is a **code change**: its baseline is a build,
its outcome is read through the verify ladder, and its rung table has five rows. An **inventory
unit** changes no code. It takes a subject's roadmap and the documents it names, turns them into
candidate tasks through the entry procedure (`docs/ENTRY-PROPOSAL.md`), has the maintainer
confirm them, files the confirmed ones, and lets `kit-plan.sh` order them.

This annex says which parts of the protocol apply to such a unit unchanged, which change, and what
is added. **Everything not named here applies as written.** It exists because three code-change
trials each recorded the planner on a backlog the kit did not write as *not exercised*, and the
2026-08-24 pass that tried an inventory filed nothing.

**Status: proposed 2026-09-28.** A trial runs under it only when the operator adopts it for that
trial at pre-flight, before the clock, and the record says so. Until then it is a document, not a
ruling, and a record cannot cite it as one. Its first use is also its first test: revise it from
that record, as revision 2 of the protocol was revised from the first code trial.

It depends on PR #181's rung-table detection in protocol §3 and must not land before it.

---

## 1. Pre-flight (protocol §0)

**Unchanged:** every box under *The kit*; *the subject copy has no remote*; *the owner has
agreed*; and every box under *The trial* (question, time-box, stop rules, abort path). Note that
`kit-preflight.sh --criticals` is not read-only: it runs `kit-index.sh --if-stale` first
(`kit-preflight.sh:229`), so run it on a committed tree.

**Instruments, changed:**

- [ ] **Spend capture is checked in the session layout the trial will use** — under
      `claude --plugin-dir <kit>`, rooted in the copy. A check run from another root passes while
      the trial records nothing (`T-20260923-a-session-rooted-elsewhere-records-no-sp`). Several
      detections in §2 read spend rows, so this box is not optional here.
- [ ] **Findings capture is still probed**, as protocol §0 describes, although an inventory unit
      runs no reviewer. It proves the finding join works on this copy, which the trial's own
      defects will be filed through.

**Subject, changed:**

- [ ] **The build baseline is recorded and decides nothing.** Record the subject's CI state at the
      subject SHA by job, with causes where known. No rung runs, so it cannot void or complete this
      unit; it is there so a later code-change trial on the same SHA can compare.
- [ ] **`kit-preflight.sh --commands` is run and recorded, and is not outcome-bearing**, for the
      same reason.

**Added:**

- [ ] **The operator adopts this annex for the trial**, and the record says so.
- [ ] **The subject of record is named by SHA**, and any other tree the maintainer knows is
      recorded with its SHA and divergence (`git rev-list --count A..B` both ways, and the merge
      base). **The maintainer confirms candidates against the subject of record, not their own
      tree**: an item done only in a tree the trial cannot see is `created` here, and a
      confirmation that it is done must cite evidence in the subject of record.
- [ ] **A before-state of every other tree**, for §2's last condition: `git status --porcelain`,
      `HEAD`, `git count-objects -v`, and a marker file's timestamp for `find -newer`.
- [ ] **The backlog baseline:** the roadmap's path and blob SHA, each child document it names by
      path and blob SHA, and the count of items by state marker. Derive the counts with a command
      and record the command; a legend or example line is not an item.
- [ ] **State mappings written down** — which roadmap marker becomes which kit state and `--via`
      value — and the rule that each candidate title begins with the roadmap id.
- [ ] **The walk is scoped before the clock.** Which candidates the maintainer will judge (all of
      them, or a sample drawn by a stated rule), the time allowed, and what happens to the rest:
      an unwalked candidate is not filed and is counted as unjudged.
- [ ] **The method for comparing the plan with the roadmap's own order**, fixed before the clock.
- [ ] **The adoption shape is fixed**: whether the tasks directory is tracked or ignored in the
      copy, and where the questions file goes.
- [ ] **The researcher resolves as a separate agent** in that session layout, and its bounded file
      list is written down. **If it does not resolve, stop:** trial 2 fell back to the orchestrator
      doing the judgement, and that trial then measured the orchestrator.
- [ ] **Any oracle is sealed.** If the trial holds facts back from the researcher to compare
      afterwards, record where they are and how to derive them, and state what result the oracle
      predicts. Prefer running the session where the other tree is not reachable at all (a
      container without that mount); record which was done.

## 2. Outcome

The protocol's three labels apply (`docs/TRIALS/TEMPLATE.md`):

- **COMPLETE**: the scoped walk finished; every confirmed candidate was filed or its refusal
  recorded; the plan was computed twice (below); every measure in §3 is recorded with n; and no
  VOID condition fired.
- **ABORTED (cause)**: stopped before that, for example at the time-box mid-walk. The funnel is
  recorded as far as it got, with the stage; that is a result.
- **VOID (condition)**: a condition below, or an applicable protocol §3 condition, fired.

**The rung table** gets one row per rung with the disposition cell reading
**`ladder not invoked — inventory unit`**. PR #181's detection counts these in its second number,
as dispositions outside the ladder's words, and requires the record to cite the ruling that allows
them: that ruling is the operator's adoption of this annex at pre-flight.

**Protocol §3 conditions that apply:** a permission denial, a reindex on a dirty tree, reading
inside the session what the trial was to measure, a mid-trial profile edit (`ingest.*` and
`tier.rule` matter most here), and `rejected` finding-gap rows. **That do not apply:** an
unsatisfiable rung, per-file structural blindness, and the worktree blind comparison unless a
second researcher is run blind.

**Added conditions, each with a detection that can fail.** The subagent's own transcript,
`<session>/subagents/agent-<agent_id>.jsonl` (`kit-spend.sh` reads it), is the one copy of the
researcher's reply the orchestrator did not write, so the first two detections read it.

| condition | detection |
|---|---|
| **The judgement was the orchestrator's.** | A `scope=subagent` spend row whose `agent` is the researcher (confirm the spelling at pre-flight, so zero means absent, not misspelled), **other than any pre-flight probe's, whose `agent_id` is recorded before the clock**. Its `agent_id` names a transcript whose final assistant text is the reply. Commit the candidates file in a **later turn** than the researcher returned, so the row exists before the commit even if it was recorded by the end-of-turn sweep. No row, or no transcript: VOID. |
| **The reply was edited before `--check`.** | `<paths.state>/entry-candidates.md` is the reply **verbatim, whole**; `--check` needs both its sections in that one file. The questions file is a derived copy of the questions section. The researcher's final assistant text, extracted from its transcript, is compared with `git show <first commit>:<paths.state>/entry-candidates.md` using `cmp`, both sides with trailing newlines stripped (`printf '%s' "$(cat F)"`) and nothing else normalised, and `--check`'s output on that commit is recorded. Any other difference: VOID. |
| **A confirmed candidate went unfiled without a recorded reason, or something unconfirmed was filed.** | Compare **titles**, not ids: an id is computed at filing from the date and a slug, so a filing across UTC midnight or a slug collision changes or refuses it. Confirmed titles against the `title:` lines of the filed task files, each sorted, with `comm -3`. Every line of output must be explained by a recorded refusal (the `kit-task.sh` exit code and message). An unexplained line: VOID. |
| **The oracle leaked.** | Every `Read`, `Grep`, `Glob`, `WebFetch` and `WebSearch` call in the researcher's transcript is listed with its **input** (path, pattern, URL or query), and none reaches outside the copy, other than paths the trial record allows by name. The check reads tool **inputs** and the final reply, not tool results: the subject's own files may name the other tree (highper-gateway's roadmap does), and reading them is not a leak; opening that tree is. A path in the prompt does not isolate a subagent (protocol §3, first row), which is why the tool calls are read and not only the prompt. Any hit: VOID. |
| **Anything outside the copy was written.** | The subject of record is untouched (the copy has no remote). Each other tree shows the same `git status --porcelain`, `HEAD` and `git count-objects -v` as its before-state, and `find <tree>/.git -newer <marker>` prints nothing. Objects count: `git fetch --dry-run` writes objects and changes no ref. Any difference: VOID. |

**Writes into the copy's tracked tree** — the candidates file, the questions file, the
confirmations file, filed tasks — are part of this unit, not a collision with §3's dirty-tree
rule, **provided each is committed as a recorded trial commit before the next reindex.** Trial 3
set that precedent. Two tracked paths change without the unit writing them, and are expected:
`.project/events.ndjson`, which the Stop and SubagentStop hooks append to every turn, and
`.project/plans/`, which `kit-plan.sh` writes and then reindexes before anyone can commit it.
**Detection, before every reindex the trial triggers:**
`git status --short -- . ':!.project/events.ndjson' ':!.project/plans/'` prints nothing. Both
excluded paths are committed at the next trial commit.

*Revised 2026-09-29, before first use, from a blind review of trial 4's prompts: as first
written, a clean run fired the dirty-tree condition, the leak check fired on the subject's own
roadmap (which names the maintainer's checkout), and the reply comparison was byte-exact.*

## 3. What is measured (n on every figure)

**The funnel:** roadmap items by marker → candidates by disposition (`created`, `completed`,
`cancelled`, `on-hold`) → questions → `--check` refusals by cause → maintainer walked, confirmed,
refuted and unjudged, **split by disposition class** (2026-08-24 confirmed 1 of 10 `completed`
claims and refuted 1 of 5 `cancelled`) → filed → filing refusals by cause.

**The oracle**, if one was sealed: for each withheld item, what the inventory said, on what
evidence, and what the maintainer confirmed. Rows for withheld items are flagged, so the
confirmation split can be computed with and without them: the confirmer is not sealed from the
oracle even when the researcher is.

**Provenance:** the `--via` distribution of filed tasks.

**The plan:** `plan_item` count; `depends_on` edges proposed, filed, and resolving to a filed task;
the layer histogram; the number of distinct scores and the size of the largest tie; the withheld
count; **one `kit-plan.sh` run straight after filing and one after `kit-index.sh`**, both recorded
(`T-20260820-kit-plan-computes-the-ordering-before-re`); and agreement with the roadmap's own
order by the method fixed at pre-flight. When most items tie, say so rather than quote a rank
correlation over ties.

**Clusters:** `touches` edges (expect none on a subject with no `Task-Id` history), cluster count,
largest share, whether packs were withheld, and how much of the clustering came from `--epic`
alone.

**Cost:** BTE per candidate and per filed task (protocol §1), and spawn latency in the runtime.

**Not exercised, and said so:** over-tiering (no `tier-classify` runs on candidates unless the
trial runs it), accelerator binding (none declared), and any ingest adapter other than the entry
procedure.

## 4. Isolation (protocol §4)

Unchanged for the subject. Added: any other tree the maintainer holds is **never a clone source
and never written**, not even by a command that looks read-only (`git fetch --dry-run` writes
objects). The researcher has no `Write` (`docs/ENTRY-PROPOSAL.md`, step 2).

---
id: T-20260821-the-kit-does-not-measure-its-own-develop
title: The kit does not measure its own development because hooks are never registered
epic: measurement
tier: T2
lang: json
paths: .claude/settings.json, tooling/kit-spend.sh, tooling/kit-preflight.sh
state: open
---

## Intent

`hooks/hooks.json` invokes `bash ${CLAUDE_PLUGIN_ROOT}/tooling/kit-spend.sh`, and
`CLAUDE_PLUGIN_ROOT` is set **only under `--plugin-dir`**. Kit development does not run that way, and
there is no `.claude/settings.json` here. So during development the hooks are not quiet — they are
**not registered at all**.

Measured 2026-08-21 on this repository:

| | |
|---|---|
| `spend` rows in `.project/index.db` | **11, every one `scope=main`** |
| `scope=subagent` rows | **0** |
| date range of all 11 | `2026-08-14` → `2026-08-15`, nothing in the six days since |
| `.claude/settings.json` | **absent** |

**The cost is not hypothetical and it is large.** On 2026-08-21 a T3 review chain plus an ADR review
ran four subagents against this repository, together roughly **440k subagent tokens** — the most
expensive measurement opportunity the project has had — and produced **zero** spend rows. The
period-one retro had already recorded that *"the kit can measure this and does not, on itself"*; this
is that, with a number.

## Scoped to spend only. The guard is deliberately excluded.

`hooks.json` registers three things. This task registers **one**.

`kit-guard.sh` must NOT be self-hosted here, and the reason is a rule this project already learned:
**never read — or in this case, be governed by — a control you are still changing.** Registering it
would make `kit-guard.sh` guard the very edits that change `kit-guard.sh`. The session on
2026-08-21 edited `kit-index.sh`, `kit-resolve.sh` and `kit_findings.py` in sequence; under
self-hosting a bad intermediate save could refuse every subsequent write, or pass silently, and
the failure would look like the harness misbehaving.

`kit-spend.sh` does not have that shape. It **appends** on `SubagentStop`/`Stop`, it cannot refuse a
write, and a broken version loses telemetry rather than blocking work. That asymmetry is the whole
justification for the narrower scope, and widening it later needs its own argument.

## What this is NOT

- **Not a port, and not a step toward one.** This adds a 17th file to the **Claude adapter**
  (`T-20260819-the-claude-adapter-is-16-files-but-nothi` counts the current 16). It measures
  Claude-Code-developed sessions and nothing else. Codex is not a near-term target; the current
  goal is a working head start on Claude Code.
- **Not a substitute for plugin-mode testing.** Those are different configurations, and conflating
  them is what made this gap invisible. Loading the kit into a development session is
  *(agent=Claude Code, kit loaded, subject=the kit)*. The trial task's smoke tests are
  *(agent=Claude Code, kit loaded, subject=a throwaway repo)*. This task changes only the first.
- **Not retroactive.** Six days of development, a T3 chain and four agent runs are gone as far as
  the instrument is concerned. This starts the clock; it does not recover the period, and the next
  retro must say so rather than report a healthy period from a partial series.

## Acceptance criteria

- [x] `.claude/settings.json` registers `kit-spend.sh` on `SubagentStop` and `Stop`, by a path that
      resolves without `CLAUDE_PLUGIN_ROOT`. **`kit-guard.sh` is not registered**, and the file says
      why, so the omission reads as a decision rather than an oversight.
- [x] **Proven against a recorded zero**, the way the plugin smoke test was: capture the
      `scope=subagent` count before, run one subagent, capture it after. "The hook fired" is only a
      measurement against a baseline.
- [x] `kit-preflight.sh --spend` reports live capture in this repository. It asks
      `events.ndjson` before the index, so "the hook never fired" and "the hook fired and nothing
      derived it" stay distinguishable.
- [ ] **It does not double-count under `--plugin-dir`.** A session run with both the local settings
      and `--plugin-dir` must not register the hook twice or write two rows per transcript.
      `spend` totals are cumulative per transcript with last-write-wins, so a duplicate may be
      invisible in the total and wrong per agent — check it, do not assume it.
- [x] The churn is accepted deliberately: every development session now appends `spend` events to
      the **tracked** `.project/events.ndjson`. `merge=union` handles the merge; the commit noise is
      the cost of the measurement and is stated here so it is not rediscovered as a surprise.
- [ ] A check that can fail. Asserting the file exists is a source-text assertion and is vacuous —
      assert the **behaviour**: a fixture session with the settings registered produces a
      `scope=subagent` row, and one without produces none.

### Evidence, 2026-09-14 — proposed, not certified, and three of six are NOT met

**The boxes above are deliberately unticked**, and this one should not be closed: half its
criteria are open. Recorded because "the instrument is fixed" is the shorter and wronger
summary of today, and it is the one that would have been carried forward.

| AC | state | where to verify |
|---|---|---|
| 1 — `.claude/settings.json` registers the two hooks, no `CLAUDE_PLUGIN_ROOT`, guard excluded with the reason | **met, and it predates today** | the file has existed since before this session; `$CLAUDE_PROJECT_DIR`, `$comment` states why `kit-guard.sh` stays out |
| 2 — proven against a recorded zero, by running one subagent and comparing `scope=subagent` before and after | **NOT met** | main-loop scope was proven this way — nothing from `2026-09-10T03:22:11Z` to `2026-09-14T03:30`, then readings at `03:37:40Z` and `03:40:44Z`. **No subagent was run**, so the half this criterion actually names is unproven |
| 3 — `--spend` reports live capture, asking `events.ndjson` before the index | **met**, and strengthened | pre-existing; PR #110 added a recency arm and #112 stopped that arm failing open |
| 4 — does not double-count under `--plugin-dir` | **NOT met** | never exercised. The criterion says *check it, do not assume it*, and it has not been checked |
| 5 — the churn is accepted deliberately | **met, and now real** | `.project/events.ndjson` was committed twice today carrying this session's rows |
| 6 — a check that can fail: a fixture session WITH the settings produces a `scope=subagent` row, one WITHOUT produces none | **NOT met** | today's conformance work asserts the recency arm, not settings registration. The existing spend step proves `kit-spend.sh` records subagent rows; nothing proves the registration is what causes it |

**What today actually added is not in these six.** The recorder had been dark since 2026-09-10
because `kit-spend.sh` resolves its root from the SESSION's directory and exits 0 in a repo that
has not adopted the kit — sessions rooted at the parent workspace recorded nothing, correctly and
silently. Fixed by a workspace-level registration; capture resumed mid-session. And `--spend`
reported `spend capture is live` throughout, because it asked whether anything was EVER recorded.
Both are worth their own criteria if this task is re-scoped rather than closed.

### Evidence, 2026-09-15 — AC2 proven, AC4 DISPROVEN, AC6 partly landed; four boxes now ticked

The 2026-09-14 table above stands; this is what changed. Four criteria are ticked because each is
now evidenced, and the task **stays open** because two are not.

| AC | state | evidence |
|---|---|---|
| 1 | **met**, unchanged from 2026-09-14 | the file registers both hooks via `$CLAUDE_PROJECT_DIR`, `kit-guard.sh` excluded with the reason in `$comment` |
| 2 | **MET — proven 2026-09-15** | see below |
| 3 | **met**, unchanged | `kit: spend capture is live -- 164 event(s), 79 row(s), last reading 2026-09-15T02:45:33Z` |
| 4 | **NOT met, and now DISPROVEN rather than unexercised** | see below; filed as `T-20260915-both-settings-and-plugin-dir-register-th` |
| 5 | **met**, and this branch is another instance | `.project/events.ndjson` carries this session's rows |
| 6 | **NOT met — half of it is not reachable from conformance**, see below | `tests/conformance.sh`, step *"the registered hook records, and silence in an unadopted repo stays correct"* |

**AC2 — proven against a recorded zero, and the zero was captured first.** Counted from
`.project/events.ndjson`, which is the source `--spend` reads before the index:

    before   50 subagent-scope spend events, newest 2026-09-14T17:15:34Z
    one general-purpose subagent run
    after    51 subagent-scope spend events, newest 2026-09-15T03:28:36Z

The new row: `agent=general-purpose`, `agent_id=a106078dedc892495`, `model=claude-haiku-4-5`,
`turns=4`, `tok_out=412`, `cache_read=61500`. **It was recorded from a session rooted at the parent
workspace, not at the kit** — which is the exact path that was dark from 2026-09-10 to 2026-09-14,
so this proves the workspace-level registration on `SubagentStop` and not only on `Stop`. The
2026-09-14 commit that made the fix said in its own message that it was *"NOT YET PROVEN END TO
END"* and named this measurement as the proof. This is that measurement.

**AC4 — checked as the criterion demanded, and it fails.** A throwaway repo adopted with
`kit-init.sh`, given a `.claude/settings.json` registering the hook, then run once with
`claude --plugin-dir <kit>` launching one subagent. Result: **8 spend events over 2 transcripts —
every reading written exactly twice**, identical `at`, `turns`, `tok_out`, `cache_read`, `context`.

The criterion has two halves and they split:

- *"two rows per transcript"* — **holds.** The index keys on transcript with last-write-wins; the 8
  events collapse to 2 rows carrying correct totals. **No cost figure is wrong.**
- *"register the hook twice"* — **fails.** It is registered twice and fires twice, and
  `kit-spend.sh`'s *"does not append when the total has not moved"* guard does not stop it, because
  both firings read the log before either writes.

So the damage is the committed append-only log and every consumer that counts EVENTS — which
`kit-preflight.sh --spend` does. **This repository's own log is clean**: 0 identical-reading
duplicates across 166 spend events and 80 transcripts, because neither development session passes
`--plugin-dir`. Filed as `T-20260915-both-settings-and-plugin-dir-register-th`; AC4 is left
unticked rather than re-worded, per *file, don't fix*.

**AC6 — a check that can fail now exists, and it does not cover the whole criterion.** The new step
makes three assertions: the committed `.claude/settings.json` still registers `kit-spend.sh` on
`SubagentStop`; invoked as the hook invokes it, in an adopted repo, it writes one `scope=subagent`
row; invoked identically where no repo has adopted the kit it writes nothing and exits 0 — the
inertness that was correct behaviour and that hid the four-day outage.

Both arms were mutation-proved **separately**, because a combined revert can pass while one
mutation slips through:

| mutation | result |
|---|---|
| `SubagentStop` registration deleted from `.claude/settings.json` | FAIL — *"does not register kit-spend.sh on SubagentStop (read: absent)"* |
| `kit_active "$ROOT" \|\| exit 0` weakened to `\|\| true` in `kit-spend.sh` | FAIL — *"an unadopted repo had events written to it"* |

**Why it is still unticked.** The criterion says *"a fixture session WITH the settings registered
produces a `scope=subagent` row, and one WITHOUT produces none."* The second half needs a real
harness session started without the settings, and conformance cannot start a harness session — in a
shell fixture "nothing invoked the recorder, so nothing was written" is a tautology, not a test.
What landed guards the registration and the silence; what the criterion literally asks for is not
reachable from this suite. **That is a defect in the criterion as much as a gap in the work**, and
it is recorded here rather than resolved by ticking the box.

## Notes

Filed 2026-08-21 after the operator asked whether hooks were in place during kit development. They
are not, and the answer had been assumed rather than checked twice before in this project.

The naming trap that hid it: `docs/ADAPTERS.md` is about **ingest** adapters — data sources — not
coding-agent adapters. Nothing in it concerns hook registration, so reading it does not reveal
this gap.

Related and still untested: `kit-review-record.sh --cmd 'claude --plugin-dir …'` has **never
executed**. The four reviewers on 2026-08-21 were spawned through the harness Agent tool instead,
which is a second reason they produced no spend rows and is tracked on
`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie`.

---
id: T-20260808-trial-the-kit-on-one-unfamiliar-brownfie
title: Trial the kit on one unfamiliar brownfield polyglot project
epic: validation
tier: T2
blocked_by: T-20260808-record-how-a-task-was-executed-so-kit-wo, T-20260808-a-repeatable-trial-protocol-for-running-, T-20260808-adoption-paths-for-an-empty-folder-and-f, T-20260813-nine-criticals-predate-summary-and-canno, T-20260819-a-finding-whose-subject-no-longer-exists, T-20260912-a-declared-rung-whose-tooling-fails-has-, T-20260912-a-trial-runs-in-a-container-on-the-subje, T-20260912-the-baseline-records-that-the-subject-is, T-20260911-the-isolation-check-passes-while-the-cop, T-20260911-kit-status-reports-spend-with-no-as-of-t, T-20260911-a-finding-recorded-by-hand-carries-no-ag, T-20260911-a-carried-over-finding-is-recorded-as-a-, T-20260911-kit-init-next-steps-omit-choosing-git-ad, T-20260923-the-ladder-has-no-disposition-for-a-rung
state: open
---

> **Blockers six to thirteen added 2026-09-13, and every one of them comes from trial 1's own
> record.** The first five are all `completed`, so this task read as ready work while the run it
> gates had already happened once and produced a result the record calls into question. Seven of
> the eleven acceptance criteria below are still open.
>
> **The test applied was not "did trial 1 find this".** It found more. It was: *would trial 2
> measure the wrong thing without it.*
>
> | | blocker | what it invalidates |
> |---|---|---|
> | 6 | `T-20260912-a-declared-rung-whose-tooling-fails-has-` | **the verdict.** Rungs 1 and 2 had tooling declared and failing — a state the ladder does not name — so three reviews passed a change that does not compile and the trial recorded COMPLETE |
> | 7 | `T-20260912-a-trial-runs-in-a-container-on-the-subje` | **rungs 1–3, which never ran.** The subject is Linux-first and trial 1 ran on a Windows host where the crate does not build. This is the cause of blocker 6, not a separate wish |
> | 8 | `T-20260912-the-baseline-records-that-the-subject-is` | **comparability with trial 1**, which is the reason to run a second trial on the same subject. One job's cause stood in for four for three days |
> | 9 | `T-20260911-the-isolation-check-passes-while-the-cop` | **the isolation claim.** The copy pre-approved `Bash(git *)` against another checkout and `kit-preflight.sh --isolated` still returned 0 |
> | 10 | `T-20260911-kit-status-reports-spend-with-no-as-of-t` | **every cost figure.** 6,902.9 kBTE reported against 10,259.6 spent — 33% low |
> | 11 | `T-20260911-a-finding-recorded-by-hand-carries-no-ag` | **per-reviewer attribution.** 11 of 11 findings carry `agent_id: ""`; 3 of 3 spend rows carry one |
> | 12 | `T-20260911-a-carried-over-finding-is-recorded-as-a-` | **every finding count.** 11 rows for 5 defects |
> | 13 | `T-20260911-kit-init-next-steps-omit-choosing-git-ad` | **the central brownfield degradation.** The printed next steps omit `git.adopted_at`, so 97 of 98 commits carried no Task-Id, blast radius read UNKNOWN, and a half-day change was tiered T3 |
>
> **Four trial-1 defects were considered and deliberately left out**, with reasons, in
> `docs/DEPENDENCIES.md`. The closest call is
> `T-20260801-nothing-invokes-kit-finding-so-the-findi`: in plugin mode 11 of 11 findings landed
> only by hand. Recording by hand is a documented procedure that worked, so it is not declared —
> but if trial 2 must exercise the feedback loop rather than work around it, that is blocker
> fourteen and it is the operator's call.

> **Fifth blocker added 2026-08-21, and it is mechanical rather than argued.** §0's criticals
> gate must read **zero** before this trial can honestly start. **The number is deliberately not
> written here — run it:**
>
>     bash tooling/kit-preflight.sh --criticals
>
> **The figure was hard-coded three times and was wrong all three.** It said `4` when this note
> was filed, was `13` when a review measured it hours later, and `5` the next time anyone looked.
> A note carrying a live count goes stale between the session that writes it and the session that
> reads it, and it was re-filed as a finding each time. The command is the single home for the
> answer, exactly as §0 says: *run it, do not judge it.*
>
> **The original form of this blocker is discharged.** It said the four criticals then outstanding
> all reviewed `docs/design-input/2026-08-15-entry-mechanism.md` — design 1, which design 2
> rejected outright — and that **no existing verb could clear them**: `--fixed` was false because
> nothing was fixed, `--unassessable` is refused for any finding carrying a summary, and
> `kit-vindicate.sh --false` keys on `(task, class)` and would have refuted unrelated findings,
> besides being the wrong claim — they were real, and being real is why the design died.
>
> That gap is closed. `T-20260819-a-finding-whose-subject-no-longer-exists` built `--superseded`,
> and those four left the gate under it. **It stays in `blocked_by` until it is closed**, which is
> an operator decision and not this note's to make.
>
> This edge existed in prose for two days before anything recorded it, which is the same failure
> the fourth blocker's note describes. A dependency nothing can read is not a dependency.

> **Fourth blocker added 2026-08-14.** §0's criticals gate stopped filtering by task state, and
> nine criticals that predate the `summary` column cannot be assessed — so the gate cannot reach
> zero until `T-20260813-nine-criticals-predate-summary-and-canno` lands, and this trial cannot
> honestly start. That was true the moment the gate widened and nothing recorded it: `kit-plan`
> went on offering this task as ready work. An approach reviewer noticed the edge was missing,
> not the tooling.

## Intent

Every measurement the kit has is from ONE greenfield TypeScript project, and its own record
says so: n=1 per cell, the whole sample is the kit's worst case, and the cost figures must not
be generalised to a brownfield repository without rerunning there. Brownfield is where the
co-change graph is not inert, where the tier floors meet paths that already exist, and where
the backlog arrives from somewhere other than this kit — none of which has ever been exercised.

The subject projects available are comprehensive and complex, several polyglot, several in
Rust, and each carries a roadmap document with child-level analysis and task-description
documents. That is the input the adoption path has to consume, and it is the first real test
of whether `ingest.tasks` and the task inventory hold up against a backlog the kit did not
author.

## The constraint that shapes this task

**The subject projects are real work and must not be destabilised.** The operator's condition,
stated 2026-08-08: do not try this while the kit is in an unstable state, and do not mess up
those projects. That is not a footnote; it decides the method.

- The kit is not stable enough today. Four T3 reviews on 2026-08-08 found two critical
  fail-opens, both in code written the same day, and both in the indexer.
- The first pass must be non-destructive: read the project, produce a task inventory and a
  report, and write nothing into the project's own history until a human has read it.
- `kit-guard.sh` blocks Write outside the project root but NOT Bash writes
  (`docs/MEASUREMENTS.md` §B, "Smaller"). Until that is closed, "non-destructive" is a
  procedure the operator enforces, not a property the kit guarantees. Say which it is.

## Acceptance criteria

- [ ] Run against a COPY or a read-only clone first, never the working repository, until the
      inventory has been reviewed by a human.
- [ ] The existing roadmap and its child documents become a task inventory: new tasks, tasks
      already finished before adoption, tasks no longer relevant, tasks not yet started. Each
      carries how it was executed, or `unknown` where nobody can say.
- [ ] Report which of the brownfield degradations actually bit, with numbers: over-tiering from
      an empty edge table, whether co-change produced a usable graph or withheld itself, and
      whether the planner's ordering was usable on a backlog it did not author.
- [ ] Report what the polyglot case did to accelerator binding. This is the evidence
      T-20260731-component-model-for-polyglot-and-moderni says it needs — its field names are
      "seeded, not earned" and are to be bound to a real polyglot project rather than to the
      design note.
- [ ] Every figure carries n and the unit, per the trial protocol. No figure from this project
      is generalised to another.
- [ ] The kit's own backlog gains the defects this finds, filed as tasks, before any of them is
      fixed. Filing before fixing is what makes the escape record real.

### Added 2026-08-19 — the plugin path itself is untested since ADR 0004

**Everything below has only ever been exercised by `tests/conformance.sh`, which invokes the
scripts directly and never runs `skills/task-context` as a session would.**
`T-20260731-run-one-real-task-with-the-model-in-the-` is **done** and dates from 2026-07-31, so it
predates all of it. Folded in here rather than filed separately, because this task already owns
"exercise it for real" and two tasks racing at one target is the duplication an audit exists to
prevent.

- [x] Run through `claude --plugin-dir <kit>` and confirm skills and agents resolve as
      `coding-kit:*`. Nothing else proves the manifest is right.
- [x] **`task-context` end to end, which is where ADR 0004's whole argument lands:** step 1's
      `kit-index.sh --if-stale` must leave `plan_item` intact, and step 4 must find the pack it
      resolves. Before 2026-08-17 step 1 deleted what step 4 read; the fix is proven by conformance
      and unproven in a session.

      **DONE 2026-08-20 on a synthetic subject. This is a smoke test, not the trial** — the
      subject is three Python files and three tasks that this session authored, so it exercises
      the PATH and proves nothing about brownfield behaviour. The criteria below and above still
      require a real, unfamiliar repository.

      Method: a throwaway repo adopted with `kit-init.sh`, confirmed by
      `kit-preflight.sh --isolated` to have no remote and no shared object store, invoked as
      `claude --plugin-dir <kit> --allowedTools "Read,Grep,Glob,Bash,Task,Skill"`. Baseline
      captured first — **3 plan rows, 2 packs, 0 spend rows, 0 spend events** — because "the hooks
      fired" is only a measurement against a recorded zero.

      | check | result |
      |---|---|
      | skill resolves and its procedure is followed | yes |
      | **`plan_item` across step 1** | **3 before, 3 after** |
      | step 4 resolves and dereferences its pack | `default`/cluster 1 → `c1.md`, existed and loaded |
      | spend events written by the hooks | **0 → 2** |
      | per-agent attribution | `scope=subagent`, `agent=general-purpose` |
      | `kit-preflight.sh --spend` | *"spend capture is live — 2 event(s), 2 row(s)"* |

      **The plan_item row is the whole point.** Before 2026-08-17 step 1 deleted exactly what step
      4 reads, so a session would have found no row and silently skipped the pack. Proven by
      conformance for days; this is the first time it has been true in an actual session.

      **Two things the run surfaced that a passing test would have hidden.** The pack loaded and
      was nearly EMPTY — it named the sibling task and recorded no files and no defect classes,
      because no commit in the subject carries a `Task-Id` yet. That is
      `T-20260817-a-cluster-pack-file-list-ignores-declare` visible in a live session rather than
      in a query. And the session correctly reported blast radius as **"unknown, not small"**
      rather than reading the empty result as "no dependencies", which is the distinction
      `skills/task-context` §Reporting exists to preserve.

      **Not exercised:** `--packs` recovery, the `cluster.max_share` withhold (the subject has 3
      tasks, below `cluster.min_tasks: 10`, so the floor correctly suppressed it), a stale plan, a
      refused plan, and any reviewer agent.
- [x] `kit-plan.sh --packs` recovers a clone's packs, and the withhold notice surfaces where a
      human reads it — `STATUS.generated.md`, not stderr.

      **Done 2026-08-20 on the same synthetic subject, all five paths, still a smoke test.**

      | path | result |
      |---|---|
      | stale plan (task added, not replanned) | warned, and `STATUS.generated.md` carried it |
      | replan clears it | `plan_stale` 0, `plan_item` 4 |
      | refused plan (non-numeric `layer`) | *"layer/rank are not plain numbers"*, **0 rows loaded**, STATUS named the file and the reason |
      | orphan notice while refused | **suppressed** — a refused plan is not reported as an orphaned pack |
      | `--packs` recovery in a clone | 0 → **2 packs**, plan file **byte-identical**, missing-pack notice cleared |

      The suppression row is the one worth keeping: reporting a refused plan as an orphaned pack
      would be the wrong cause and the wrong remedy, which is what a T3 security review flagged.

      **The `cluster.max_share` withhold was NOT exercised** — the subject has 4 tasks, below
      `cluster.min_tasks: 10`, so the floor correctly suppressed it. That floor exists because a
      percentage has no meaning at small n, and it is doing its job here rather than being
      skipped. The withhold path remains conformance-proven only.

      **A defect this surfaced is filed as
      `T-20260820-task-context-has-no-branch-for-a-missing`:** `--packs` fixes the recovery and
      `kit-status.sh` makes the state discoverable, but `skills/task-context` step 4 — the
      consumer — still has no branch for a row whose pack is absent, and the repair it *does*
      name (bare `kit-plan.sh`) discards the committed plan. A live session recovered correctly
      only by reading `kit-plan.sh`'s source.
- [x] Per-agent spend rows land with `scope=subagent`. Hooks fire only under the plugin, so this is
      the precondition for every cost figure the trial reports, and `kit-preflight.sh --spend` is
      the check.

      **Confirmed 2026-08-20** in the run above: one `scope=main` row and one
      `scope=subagent`/`agent=general-purpose` row, from a recorded baseline of zero. This is also
      the precondition for `T-20260808-cluster-packs-are-generated-and-read-by-` — measured from a
      development session the kit yields only `scope=main` rows that conflate every agent, and the
      experiment would report a confidently wrong number.
- [ ] The new clustering rules behave on the subject's real backlog: record the cluster
      distribution and whether packs were withheld. `cluster.min_shared` and `cluster.ignore_glob`
      were tuned against **one** backlog on 2026-08-19 and are seeded values by the kit's own
      doctrine — this is the first chance to earn or refute them.

### Decision, 2026-09-14 — operator: `commands.*` matches the subject's OWN CI

Three commands give three different answers to *"is this subject green"*, measured the same day
on `highper-gateway` in the trial runtime:

| command | exit | what it is |
|---|---|---|
| `cargo build --release -p highper-gateway` | 0 | one package, default features. What trial 1 used |
| `cargo test --workspace --lib -- --test-threads=4` | 101 | 972 pass, 2 fail, both causes named |
| `cargo check --workspace --all-features` | 101 | 91 errors, all under `highper-gateway/` |

**The trial declares what the subject's own `ci.yml` runs** — `--workspace --all-features` for
check, `--workspace --lib` for test — not the narrower commands trial 1 happened to use.

Two reasons, and the second is the one that matters:

1. `docs/TRIAL-PROTOCOL.md` §0 now requires the baseline to use *"the commands the subject's own
   CI runs, rather than ones invented for the trial"*, and says that where they differ the report
   must name which was used.
2. **Choosing the narrower command would make rung 1 green by selection.** That is the shape this
   repository keeps filing findings about — a measurement improved by measuring less. A red rung
   with a named cause is a first-class outcome since
   `T-20260912-a-declared-rung-whose-tooling-fails-has-`, and it is the honest one here.

**Consequence, stated so it is not discovered mid-trial:** rung 1 and rung 2 will both be RED at
the start of trial 2, with causes recorded. Neither is `unsatisfiable` — both commands run and
report — so neither trips the stop condition. The trial measures what the kit does against a
subject that is genuinely broken in named ways, which is what a brownfield trial is for.

**The subject moved twice on 2026-09-14** and the baseline must be retaken at pre-flight against
`e588b53`, not reused from trial 1's `05c56eb`: PR #28 made the `--lib` target compile for the
first time, and PR #27 declared the system build dependencies. Both are recorded in the subject's
history; neither touches its Rust sources except #28's one-line test fix.

### Pre-flight baseline for trial 3, 2026-09-20 — taken before the clock, recorded with causes

**Copy.** `git clone -c core.autocrlf=false -c core.eol=lf --no-hardlinks`, all 3 branches
materialised BEFORE the remote was removed, no remote, clean tree.

    subject   e588b533edb6ccf7a5b63c3f34bf7c9859ca4744
    copy      0399d5c6fbb05c9a3c0eb0c59037614665e60339   = subject + one pre-flight commit
    runtime   cck-trial  sha256:372fc7a9d8648f21110bc50efd1def80661f2e513ede3328369a95a7722b9d29

**The pre-flight commit removes `.claude/settings.local.json`**, which `--isolated` STOPs on: it
pre-approves `Bash(git *)`, `Bash(cargo *)` and `Bash(nerdctl:*)` unscoped plus seven rules naming
a second checkout outside the copy. **The copy is therefore NOT byte-identical to the subject**,
and that is stated here rather than left to be discovered by diffing.

**BASELINE — one row per rung, with the command and the cause.** Read-only mount,
`CARGO_TARGET_DIR=/tmp/target`, as `docs/trial-runtime/Dockerfile` prescribes.

| rung | command | exit | cause |
|---|---|---|---|
| 1 compiles | `cargo check --locked` | **101** | committed `Cargo.lock` lacks one entry — `"async-graphql-value"` at line 2685 — so cargo must rewrite it, and the read-only mount forbids that |
| 2 tests | `cargo test --locked --no-run` | **101** | same single cause |
| 3 lint | `cargo clippy --locked` | **1** | *"'cargo-clippy' is not installed for the toolchain 1.98.1"* — `rust:1-bookworm` ships no clippy component |
| 4 format | `cargo fmt --check` | **1** | *"'cargo-fmt' is not installed"* — same |

**THE SUBJECT COMPILES.** With a writable copy of the tree, `cargo check` exits **0** with 92
warnings. Rungs 1 and 2 are not blocked by the subject's code; they are blocked by a one-line
lockfile gap meeting a read-only mount.

**That exact line is a repeat.** `T-20260914-the-copy-procedure-loses-branches-trusts` gap 3
recorded *"`cargo build` on a writable mount rewrote `Cargo.lock` — one line,
`async-graphql-value`"* on 2026-09-14. Same dependency, six days later, still committed short.
It is a SUBJECT finding and routes to its owner under §7.

**FOUR RUNGS, FOUR UNSATISFIABLE — and the gate would have caught every one.** This is the
2026-09-09 shape reproduced before the clock rather than after it: declared tooling that does not
run. Under the vocabulary landed today each is `unsatisfiable`, `--commands` stops, and §3's new
condition voids a trial that proceeds anyway.

**TWO WRONG DIAGNOSES ON THE WAY HERE, both caught by measuring.** First *"the lockfile is stale,
missing `ahash`"* — refuted by `grep -c` showing `ahash` present. Then *"CRLF is why `--locked`
refuses"* — refuted by re-cloning with LF and getting the identical refusal. The CRLF finding is
real and separate, below. **Neither survived contact with a command**, which is the only reason
they are not in this table.


### Baseline RE-TAKEN after the two pre-flight fixes, 2026-09-20 — 4 unsatisfiable became 0

Both fixes were made **before the clock**, where a `commands.*`-adjacent change is legal; §2 makes
the same edit mid-trial void the trial.

**1. The runtime gained the rung tooling.** `RUN rustup component add clippy rustfmt`. The apt list
above it was read from the subject's declared BUILD dependencies, which is why it served rung 1 and
was blind to rungs 3 and 4 — lint and format tools are not build dependencies.
**Digest changed and is re-recorded: `sha256:372fc7a9d864…` → `sha256:e5ed7efcc9b5…`**

**2. The copy gained the one lockfile line the subject committed short**, as a recorded pre-flight
commit. **Fixed in the COPY, not in the subject** — fixing the thing being measured to make the
measurement work is contamination; the subject's owner gets it under §7.

    subject   e588b53
    copy      9cc4e55   = subject + 2 pre-flight commits (permissions removed, lockfile completed)

**THE BASELINE, RE-MEASURED.** Read-only mount, `CARGO_TARGET_DIR=/tmp/target`, tree still clean
after every run.

| rung | command | exit | disposition | cause |
|---|---|---|---|---|
| 1 compiles | `cargo check --locked` | **0** | **satisfied** | 92 warnings |
| 2 tests | `cargo test --locked --no-run` | 101 | **known-red baseline** | test target out of sync with the lib: `E0063` missing fields `graphql` and `webserver` in `Config` initializer; `E0061` function takes 1 argument, 2 supplied |
| 3 lint | `cargo clippy --locked` | 101 | **known-red baseline** | one error — *"this loop never actually loops"* — then could not compile; 196 warnings |
| 4 format | `cargo fmt --check` | **0** | **satisfied** | clean |

**FOUR UNSATISFIABLE BECAME ZERO.** Before the fixes every rung returned non-zero and all four
looked alike. They were not alike: two had tooling that could not run, and two had tooling that ran
and found real defects. **That is the distinction the whole of 2026-09-20 was spent building, and
it is doing the work here on a real subject.**

**Rung 2 confirms trial 1's finding, still true.** That trial recorded *"the `--lib` target does not
compile"*; the cause is now named — the test target initialises `Config` without `graphql` and
`webserver`. It is a subject defect and routes under §7.

**§0 item 12 is now satisfiable rather than satisfied.** Two rungs are known-red, and §0 blesses
that *"only if you knew that first"*. This record is knowing it first. When the kit is adopted into
the copy, `--commands` will stop and ask for a disposition, and the honest answer for rungs 2 and 3
is `=baseline` — which is a judgement this record now supports rather than a box to tick.


### CORRECTION 2026-09-20 — the baseline above used commands the subject does not run

**Both baseline tables above are wrong, and the error is methodological rather than a slip.** They
were measured with commands this session invented — `cargo check --locked`, `cargo clippy --locked`
— not with the commands the subject's own CI runs. §0 says record the baseline with causes. It does
not say *use the subject's declared verification commands*, and that omission produced a rosier
answer on the first real use.

**Re-measured with `.github/workflows/ci.yml`'s own commands:**

| their CI job | command | our exit | their CI on `master` |
|---|---|---|---|
| Check | `cargo check --workspace --all-features` | **101** — *cannot find attribute `async_trait`* | ❌ |
| Clippy | `cargo clippy --workspace --all-features -- -D warnings` | **101** — same root cause | ❌ |
| Test | `cargo test --workspace --lib -- --test-threads=4` | **101** — *test failed* | ❌ |
| Format | `cargo fmt --all -- --check` | **0** | ✅ |

**Four for four against their runner.** The container is faithful; the earlier commands were not.

**What the wrong baseline claimed:** *"THE SUBJECT COMPILES — `cargo check` exits 0 with 92
warnings."* With `--all-features`, which is what the subject actually gates on, **it does not
compile.** The one-line lockfile gap, the `Config` initializer and the non-looping loop were
downstream symptoms visible only because `--all-features` was off. **The root cause is one thing:**
`cannot find attribute async_trait`, which breaks Check, Clippy and Test alike.

**The subject's CI has been red on `master` since 2026-09-14** — six days, four of seven jobs:
Check, Clippy, Test and Security Audit. Build Release, Format and Validate Configs pass.

**CONSEQUENCE FOR THE TRIAL'S TASK.** Roadmap item 3.4.A — *"wire 5 SAST tools into CI"* — is not
the first step and its own status line is stale: clippy, cargo-audit and cargo-deny are already
wired; only cargo-geiger and Semgrep are missing. **You cannot add SAST to a CI where four jobs
have been failing for six days.** The blocking work is `async_trait`, a single-cause defect with a
verifiable outcome, and it unblocks 3.4.A rather than performing it.

**A kit gap filed from this**: `T-20260920-a-baseline-taken-with-invented-commands`.


## Notes

Blocked by three things, and the order matters. Without
T-20260808-record-how-a-task-was-executed-so-kit-wo the trial produces data that cannot be
interpreted afterwards; without T-20260808-a-repeatable-trial-protocol-for-running- it is not
comparable to the next one; without
T-20260808-adoption-paths-for-an-empty-folder-and-f there is no written path to follow and the
trial would be measuring an improvised procedure.

T-20260731-run-one-real-task-with-the-model-in-the- should also land first. The kit has never
been driven through the harness end to end — only its scripts from bash — and every defect
found on 2026-07-31 lived in a path that had never been executed.

**Blocked by `T-20260923-the-ladder-has-no-disposition-for-a-rung`, declared 2026-09-24.** The
operator's ruling on trial 3's rungs 1 and 2 (`6a9873d`) is *"precedent for one trial, not a general
licence"* until that task lands. The baseline/unsatisfiable task is reached through the rung task.

<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway (UC reconciliation) — 2026-08-26

> **COMPLETE, 2026-08-26.** Pre-flight recorded before the first agent command, per TRIAL-PROTOCOL §0:
> *"Stop unless every box is ticked. Record the answers; they are part of the result."*
> Everything below the pre-flight table is filled in as the trial runs.

| | |
|---|---|
| Question | **Does the kit's per-use-case verification produce a status for a 16-use-case brownfield project that its own author can trust — on a tree frozen since the roadmap was written?** |
| Kit SHA | `3e2af50` (`main`, all four CI jobs green, Windows suite 105 passed / 0 failed) |
| Time-box / actual | **2 hours** / **within box** — reconciliation ~1h, Tier-1 verification ~15m. Host-build investigation ran outside the box and is recorded as environment work, not trial work |
| Subject | Rust workspace, 2 members, 291 `.rs` files, 296 markdown docs, 169 commits, history 2025-11-24 → 2026-05-16 |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | **COMPLETE** — the question was answered. Not a pass for the kit as a whole: see *Not exercised*, where `coder` is absent for the third consecutive trial |
| Baseline before the kit | **host: BUILD FAILS** — *not* for a missing compiler; see the corrected section below. **container: BUILD PASSES** (exit 0, 3m43s, 460 crates, 92 warnings). **TESTS DO NOT COMPILE** — `cargo test --workspace --no-fail-fast` exits 101 with ZERO tests run, 2 errors blocking 1331 test functions |
| Instruments verified live | **spend** — `spend capture is live -- 2 event(s), 2 row(s)`, incl. a real `scope=subagent` row. **findings** — 8 recorded from structured output, first attempt, no correction loop |
| Copy isolation verified | `kit-preflight.sh --isolated` exit 0; no remote, no shared object store |

## Pre-flight answers, recorded

- **Criticals:** 0 actionable. **Unassessable:** 9. **Superseded:** 13. Both equal the previous
  trial's baseline, so §0 stop rule 2 (the count went UP) does not fire. None lacks a reason.
- **Stop rules:** the time-box expires · the same kit defect blocks progress three times · any
  §3 VOID condition.
- **Abort path:** if the kit crashes or corrupts state mid-trial, this is filed as ABORTED at
  that point with the cause. Never silently restarted — a restarted trial has a contaminated
  index and is no longer comparable.
- **Attribution:** §5 requires one task at a time for spend to bind correctly, so the 16
  use-case verifications run as subagents under **ONE** task, not sixteen.

## The test suite does not compile — established before the run

`cargo test --workspace --no-fail-fast` in the container: **exit 101, zero `test result:` lines**,
one error.

    error[E0308]: mismatched types
      --> highper-gateway/src/runtime/signals.rs:238:47
    238 |     _ = setup_signals_with_reload(tx) => {
        |         ------------------------- ^^ expected `Sender<ReloadTrigger>`,
        |                                      found `UnboundedSender<_>`

The library builds; the tests do not. The last commit is 2026-05-16, so **no test has run on this
project for ~101 days**, and every completeness claim in the roadmap is unbacked by test evidence.
That is a fact about the subject, recorded before the reconciliation so the reconciliation is not
credited with finding it — and so no claim in it is read as test-verified.

**Consequence for the ladder, and it is the rule working rather than failing:** `commands.test`
cannot be satisfied on this subject. `verify-ladder` declares rung 2 unavailable, names the
compensating control, and RAISES the tier — less mechanical verification means more adversarial
reading, not a lower bar. First observation of that rule firing on a real subject.

**It is also one error.** `due to 1 previous error` — a single fix unblocks the entire suite.

## Recorded variables (TRIAL-PROTOCOL §2 — varied, so recorded rather than normalised)

- **CORRECTED 2026-08-26 — the original entry here said "No C compiler" and that was FALSE.**
  Visual Studio Build Tools 2022 with the VC++ toolset was installed the whole time; `cl.exe`
  19.44 and `link.exe` 14.44 both work the moment `vcvars64.bat` is loaded. What was actually
  observed is that `cc`/`gcc`/`clang`/`cl` are not on PATH *in the msys bash shell the baseline
  ran in*. Absence from one shell was reported as absence from the machine. The wrong version is
  kept visible rather than deleted, because it is the more impressive claim and the one that
  would have been repeated.

- **The subject genuinely cannot be built on the trial host, for reasons that are properties of
  the SUBJECT rather than the machine.** Established by four builds, each moving the wall:

  | # | Blocker | Cause | Whose |
  |---|---|---|---|
  | 1 | `cl`/`link` not found | MSVC env not loaded in msys bash | the machine — fixed by `vcvars64.bat` |
  | 2 | `tikv-jemalloc-sys` | autotools `configure` needs a POSIX `sh`, absent under cmd+vcvars | environment interaction |
  | 3 | `io-uring`, **44 errors** | `tokio-uring` (unconditional, **zero call sites**) pulls Linux-only `io-uring 0.6.4` | **the subject** |
  | 4 | `quiche`/BoringSSL | NASM assembler genuinely missing | the machine — NASM 3.02 installed |
  | 5 | `signal-hook-tokio` | Unix-only, needs `UnixStream`, ungated | **the subject** |

  Blocker 3 was proved by removing the line: before, 44 errors in `io-uring`; after, **zero
  mentions of it in the log** and the build advancing to an entirely different crate. The probe
  was reverted; the copy is unmodified.

- **The manifest contradicts the source, and that is the finding.** `highper-gateway/Cargo.toml`
  has **0 `[target.*]` sections** while `src/` carries **59 `cfg(unix)` / `cfg(target_os)`
  guards**. Platform was thought about carefully in the code and never applied to dependencies.

- **Linux-only is the operator's deliberate choice** (tokio + io_uring, for throughput), stated
  2026-08-26 — so this is NOT filed as a design defect. Two things remain true anyway: the
  per-OS backend selector `runtime/io_backend.rs::select_best_backend()` is correct AND wired
  (`GLOBAL_IO` has 21 consumers including the accept path at `proxy/server.rs:311`, making it one
  of the few reachable subsystems in this codebase), its macOS/BSD arm would work but is blocked
  by the ungated manifest, and its **Windows arm calls `crate::runtime::iocp_backend::IocpBackend`
  — a module that does not exist.** No document states a platform requirement.

- `commands.build` / `commands.test` are therefore satisfied through `nerdctl exec` into a Linux
  container with the copy bind-mounted, so `verify-ladder` rungs 1–2 stay mechanical rather than
  being declared unavailable and raising every task's tier. **The container was necessary** — for
  a reason not known when it was chosen: the blocker is a Linux kernel interface, not a toolchain,
  and no Windows compiler could have satisfied it.
- **Toolchain differs from the host and possibly from the subject's own CI**: container is
  cargo 1.98.0 / Debian 12 / gcc 12.2.0 / cmake 3.25.1; host is cargo 1.94.1.
- **~1000 ms process spawns on this host** (§2) make wall-clock non-comparable for anything run
  on Windows. Build and test timings come from the container and do not carry that distortion.

## Why this subject, and why now — established before the run

The roadmap is **not stale by drift**. Measured:

| | |
|---|---|
| ROADMAP v2 written | 2026-05-16 **16:20** |
| `cargo fmt --all` — 234 files, ±11,800 lines | 2026-05-16 **22:54** |
| Last commit in the repository | 2026-05-16 |
| Dormant since | ~101 days |

The roadmap was invalidated by a reformat **6½ hours after it was written**, and nothing has
been committed since. So its *semantic* claims are contemporaneous with the tree while its
*coordinates* are broken. That splits the reconciliation into a mechanical half (line citations)
and a judgement half (claims that were wrong when written), and only the second is a review.

Three probes before the run, as evidence the split is real rather than assumed:

- `UC5.A` cites `http3_quiche.rs:403` as an unguarded `unwrap()`; that line is a `match` with an
  error branch. **stale citation**
- `UC4.F` names an empty `src/gateway/rate_limit/`; the directory does not exist. **stale**
- `admin/api.rs` is claimed dead code awaiting deletion; still present at 354 lines. **confirmed**
- `§1` cites head commit `b018071`; **not in this history at all**
- `§1` names `src/ha` and `src/health` as empty directories; neither exists in a clone, because
  git cannot track an empty directory — **unverifiable as written**, not false

## Cost

**n on every figure.** Billable-token-equivalent = `in×1 + cache_write×1.25 + cache_read×0.1 + out×5`.

| scope | rows | turns | BTE |
|---|---|---|---|
| main | 4 | 141 | 4,518,774 |
| **subagent** | **17** | **623** | **6,547,551** |
| **total** | **21** | **764** | **11,066,325** |

All 17 subagent rows are `general-purpose`. **This is the first trial in this repository's history
to produce a non-empty cost half.** Both previous trials recorded `scope=subagent` zero times,
which made every cost figure structurally absent rather than low.

Wall-clock is NOT reported as a kit measurement. §2 records this host's ~1000 ms process spawns as
making it non-comparable, and this trial ran agents on Windows while building in a container — two
different distortions in one run. Container build timings (3m43s) are comparable to each other and
to nothing else here.

**Escape rate: still `0 / 0 via:kit`.** No task in this trial was closed, so the denominator is
unchanged. Reporting a rate would be printing zeroes in the shape of a result.

## Findings

**Recorded through `kit-finding.sh`, 18 rows, zero rejected:**

| agent | severity | n |
|---|---|---|
| implementation-reviewer | major | 4 |
| implementation-reviewer | minor | 4 |
| security-reviewer | **critical** | **2** |
| security-reviewer | major | 8 |

`finding-gap` rows: **0**. Both reviewer invocations returned contract-valid JSON on the FIRST
attempt with no correction loop — `kit-review-record.sh`'s retry machinery was never needed. That
is a measurement of the contract, not a lucky run: across four live runs recorded in that script's
own header the contract was ignored three times, so first-try compliance twice is a change worth
noting rather than assuming.

**The 303 reconciliation claims are NOT in the finding table.** See *Not exercised* — this is the
single largest structural gap the trial surfaced in the kit.

## Which brownfield degradations bit

- **Over-tiering from an empty edge table:** not reached. No task was tiered by the kit; the trial
  task was tiered by hand at T2.
- **Co-change graph:** not exercised. `kit-index.sh` ran on the copy and built its tables, but no
  step in this trial consumed the co-change edges.
- **Planner ordering on a backlog it did not author:** not exercised. `kit-plan.sh` was not run on
  the copy.
- **What DID bite, and is not on this list:** a freshly adopted brownfield repo whose `.gitignore`
  already excludes `.claude/`. `kit-init.sh` exited 0, printed *"commit
  .claude/project-profile.md — the team shares them"*, and `git add` was then refused. Reproduced
  live during this trial's own setup — see K-1, filed 2026-08-25 from the previous trial and **now
  confirmed on a second subject before the trial proper began.**

## Three kinds of finding

### 1. Kit defects

**Already filed, and this trial supplies field evidence for four of them:**

| task | what this trial added |
|---|---|
| `T-20260825-kit-init-cannot-share-the-profile-when-t` | reproduced live on this subject's own `.gitignore` (`*.claude` at line 158) |
| `T-20260825-confirm-a-finding-before-surfacing-it-so` | **evidence it works**: `security-reviewer` confirmed 10/10 Tier-1 claims and SHARPENED two — claim 10 overstated the variant count, claim 7 was misworded. Both would have shipped quotable-but-wrong |
| `T-20260825-reviewing-generated-code-is-not-the-same` | the ambiguity axis fired again: `tier-classify` raised T1→T2 on an empty-AC task during the 0.11.0 release check |
| `T-20260808-make-the-security-assurance-cadence-a-po` | the subject ships an SBOM/CVE CI workflow (Syft/Grype/Trivy/cargo-audit) and the kit has no way to know it exists or when it last ran |

**NEW, not yet filed — proposed by this trial:**

1. **The kit cannot record a census.** 303 verified claims came back as prose in a subagent reply.
   Only the 18 reviewer findings reached `finding`. There is no artefact type for *"a claim about
   the tree, verified, with a verdict and evidence"* — so the most valuable output this kit has
   produced on a real subject lives in a markdown file that nothing can query, count, diff or
   re-check. **T2.**

2. **There is no reconciler agent.** The kit ships `researcher`, `coder`, `documenter`,
   `adr-scribe`, `tester` and three reviewers. The job that unblocked this entire session —
   *verify documented claims against the tree* — matched none of them, so it ran on
   `general-purpose` subagents with a hand-written prompt. On brownfield this is the FIRST job,
   not an auxiliary one. **T2.**

3. **`kit-trailers.sh range 'HEAD~1..HEAD'` validates the wrong commit after a rejected commit.**
   Observed live: the `commit-msg` hook refused a commit for a missing `Task-Id`, and the range
   check immediately after reported *"1 commit(s) checked, all trailers valid"* — because `HEAD`
   was still the previous commit. A green that means the opposite of what the operator reads.
   **T2.**

4. **"Two artefacts carry one fact and nothing compares them" is a defect CLASS, not four
   defects.** Instances observed or confirmed in one session: `plugin.json` vs `LICENSE` (fixed in
   0.11.0); `MIGRATION.md` rows vs the skills they name; `ENTRY-PROPOSAL.md` format vs its own
   validator's charset; the profile template vs `kit-accel.sh`'s repeatable keys; the subject's
   `SECURITY.md` advertising a slowloris timeout no code reads; and the whole 303-claim
   reconciliation. The kit should name this class and offer one mechanism, not six one-off checks.
   **T3, and it is the strongest generalisation this trial produced.**

5. **Reachability is mechanically checkable and would have found the dominant failure mode.**
   Twelve of sixteen use cases contain subsystems that compile, are unit-tested, and have zero
   production call sites. *"Does this symbol have a caller outside its own module and tests"* is a
   grep-and-graph question, not a judgement one. It cost 17 subagents and ~6.5M BTE to discover by
   reading; a mechanical pass would have flagged the candidates for a fraction of that. **T2.**

6. **Nothing records the trial environment as data.** §2's "recorded variables" are prose in this
   file. The toolchain split (host cargo 1.94.1 / container 1.98.0), the container-satisfied rung,
   the spawn-latency distortion — none is queryable, so no future trial can be compared against
   this one on those axes without a human re-reading the report. **T3.**

### 2. Subject defects — a proposal for the owner, filed nowhere in this backlog

Delivered as `docs/RECONCILIATION-2026-08-26.md` **in the copy**, never applied, copy has no remote.

- **303 claims checked across 16 use cases. 142 confirmed (47%). 129 (43%) do not hold as
  written** — 48 stale citations, 50 overstated, 31 understated. **Every use case is PARTIAL**,
  including the three marked ✅.
- **The dominant failure mode is unreachable code, not drift.** Twelve of sixteen use cases contain
  a subsystem that compiles, is tested, and is never called. The roadmap consistently reads *"the
  module exists"* as *"the feature works."*
- **Ten Tier-1 overstatements independently confirmed**, two of them security controls present in
  source and absent in behaviour: `extract_client_ip` has zero callers so rate limits are
  XFF-spoofable under a ✅, and the WAF's `extract_context` hardcodes `body: None` so every
  body-target rule is inert.
- **The test suite does not compile.** Two errors block **1331 test functions** across 230 files;
  no test has run in ~101 days.
- **`tokio-uring` is declared, unused, and makes the crate un-buildable off Linux** — proved by
  deletion.
- **`runtime::iocp_backend` does not exist** though `select_best_backend()` calls it on Windows.
- **The roadmap was invalidated 6½ hours after it was written** by `cargo fmt --all` across 234
  files, which is why line citations rot while semantic claims survive.

### 3. Methodology — for TRIAL-PROTOCOL §3, with detections

**M1 — A fast success on a slow operation is a failure until proven otherwise.** Three instances
in one session: `EXIT=${PIPESTATUS[0]}` after `nerdctl exec … | tail` reported *tail's* status and
printed `BUILD_EXIT=0` for a build that had just failed; `diskpart` returned exit 0 with no output
in 12 seconds against a 190 GB file because it silently needed elevation; and the trailer range
check above. **Detection:** compare elapsed time against the operation's plausible cost before
reading the status, and echo the exit code from inside the process that did the work.

**M2 — Absence from one shell is not absence from the machine.** The baseline recorded "no C
compiler" from a `command -v` probe in msys bash. MSVC 19.44 was installed the whole time.
**Detection:** a negative environment finding must name the environment it was observed in, and be
re-checked in at least one other before it is written down as a property.

**M3 — Verify the premise of a task before selecting it.** Three of four roadmap items probed as
trial-task candidates were stale: UC5.A cited an `unwrap()` that is a `match`, UC4.F named a
directory that does not exist, UC3.F chased a log leak that isn't there. Selecting any of them
would have spent the time-box discovering the task was already done. **Detection:** re-derive the
premise from the tree, never from the document proposing the work.

**M4 — Reconnaissance beats task selection on an unfamiliar subject.** The task proposed before
the reconciliation (a route-validation fix) was arbitrary. After it, two far better candidates were
obvious and evidenced: the two-error test-compile fix that restores 1331 tests, and the manifest
gating that restores the platforms the code already supports. **Fold into §1 (the unit): on
brownfield, the first unit is a census, not a change.**

**M5 — Record the baseline before the tool touches anything, including what is BROKEN.** The test
suite's non-compilation was established before the reconciliation ran. Had it not been, the
reconciliation would have been credited with finding it — and worse, its verdicts might have been
read as test-verified. §0 already requires this; this trial is the case where it paid.

## Not exercised

*What ran and produced nothing, and what never ran.*

- **`coder` never ran.** Third consecutive trial. The gap two trials left open is still open.
- **`approach-reviewer`, `adr-scribe`, `researcher`, `documenter`, `tester` never ran.**
- **`implementation-reviewer` ran once**, as an instrument check, not against a change.
- **The kit's reviewer agents were invoked by hand-written prompt through
  `kit-review-record.sh --cmd`**, not by the kit selecting them. Agent ROUTING was not exercised.
- **`kit-plan.sh` was not run on the copy.** Planner ordering on a foreign backlog: untested.
- **Co-change edges were built and never consumed.**
- **The verification ladder was never actually driven.** `commands.build` / `commands.test` were
  established as satisfiable via `nerdctl exec` and run by hand; no kit component invoked them.
- **The 303 reconciliation claims were never recorded as kit data** — see kit defect 1.
- **Nothing was ever run.** The gateway was built, never started. Every reconciliation verdict is
  about REACHABILITY IN SOURCE, a static fact, not runtime behaviour. *"This code has no call
  sites"* is reliable; *"this feature does not work"* is an inference from it and is not tested
  here.

## Disputed

Nothing disputed at the time of writing. The subject's owner is the operator and reviewed findings
as they were produced. The Linux-only platform question was raised as a possible defect by the
agent, corrected by the operator as a deliberate design choice (tokio + io_uring, for throughput),
and the record was amended rather than defended — see *Recorded variables*.


## Provenance of this document

Written by the agent during the run, from commands whose output is quoted. The subject's owner
is the operator. Nothing here has been applied to the subject; the copy has no remote.

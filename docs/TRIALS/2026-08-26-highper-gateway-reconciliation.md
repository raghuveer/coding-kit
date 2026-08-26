<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway (UC reconciliation) — 2026-08-26

> **IN PROGRESS.** Pre-flight recorded before the first agent command, per TRIAL-PROTOCOL §0:
> *"Stop unless every box is ticked. Record the answers; they are part of the result."*
> Everything below the pre-flight table is filled in as the trial runs.

| | |
|---|---|
| Question | **Does the kit's per-use-case verification produce a status for a 16-use-case brownfield project that its own author can trust — on a tree frozen since the roadmap was written?** |
| Kit SHA | `3e2af50` (`main`, all four CI jobs green, Windows suite 105 passed / 0 failed) |
| Time-box / actual | **2 hours** / *pending* |
| Subject | Rust workspace, 2 members, 291 `.rs` files, 296 markdown docs, 169 commits, history 2025-11-24 → 2026-05-16 |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | *pending* |
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

*pending*

## Findings

*pending*

## Which brownfield degradations bit

*pending*

## Three kinds of finding

*pending*

## Not exercised

*pending*

## Disputed

*pending*

## Provenance of this document

Written by the agent during the run, from commands whose output is quoted. The subject's owner
is the operator. Nothing here has been applied to the subject; the copy has no remote.

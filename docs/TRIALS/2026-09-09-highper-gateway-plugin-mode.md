<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-09, plugin mode

> **PREPARED, NOT RUN.** Section 0 below is filled in; everything after it is empty on purpose and
> says why. The protocol requires the pre-flight answers to be recorded *before* the first command
> — *"Record the answers; they are part of the result"* — so this file exists at pre-flight rather
> than after, and a reader can see what was true before anyone touched the subject.

| | |
|---|---|
| Question | **Does the kit, loaded as a plugin, produce readings on a subject it did not author?** Specifically: does any `scope=subagent` spend row appear, and does any finding land, on a 967-file **Rust** subject with 169 commits. Written before the first command. **Corrected 2026-09-09: this read `PHP`.** The subject is Rust -- 291 `.rs` files, one `Cargo.toml`, 160 files referencing io_uring. File and commit counts were right; the language was not. ADR 0002's rule is that a pre-registered condition is only as good as its targets, so it is corrected before the run rather than after. |
| Kit SHA | `9ce8b70` (`main`, all four CI checks green) |
| Time-box / actual | not set / not run |
| Subject | highper-gateway — 967 tracked files, 169 commits, branch `master`, clean tree, **not adopted** (no `.project/`). **Unmaintained since 2026-05-16 by operator decision** — attention moved to other projects — and **red on its own CI** at this SHA. Both are recorded below and neither disqualifies it |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | **not run** — see §0 |
| Baseline before the kit | **TAKEN 2026-09-09, on Linux** -- build green, tests do not compile. See the Baseline section |
| Instruments verified live | **not yet** — this is the trial's own question |
| Copy isolation verified | **YES** — `kit-preflight.sh --isolated` exit 0, `git remote -v` prints nothing |

## 0. Pre-flight — recorded, and one box FAILS

Run 2026-09-09 against kit `9ce8b70`.

| box | command | result |
|---|---|---|
| Working tree clean | `git status` | **PASS** — clean |
| CI green every platform | `gh run list --branch main` | **PASS** — `9ce8b70` success, four checks |
| Full local Windows conformance | `tests/conformance.sh` | **NOT RUN** — ~1 h on this machine; CI covers ubuntu and macOS, Windows is unverified for this SHA |
| **No unfixed critical** | `kit-preflight.sh --criticals` | **FAIL — STOP. 12 outstanding.** |
| Unassessable criticals | `kit-preflight.sh --unassessable` | **9** — excluded from the gate and still true |
| Superseded criticals | `kit-preflight.sh --superseded` | **32** — excluded, and each was real |
| Copy isolated | `kit-preflight.sh --isolated <copy>` | **PASS** — no remote, no shared object store |

> **The table above is the pre-flight AS RUN on 2026-09-09 and is not edited.** Later the same day
> the gate moved **12 -> 7** and the kit SHA moved from `9ce8b70` to `bedc22e`. Recorded here rather
> than rewritten, because a pre-flight that silently reports today's numbers cannot be compared with
> the next trial's:
>
> | | then | now |
> |---|---|---|
> | criticals gate | 12 | **7** |
> | unassessable | 9 | 9 |
> | superseded | 32 | **35** |
>
> Two closed on evidence (`627b9764` fixed in `validate.py`; `5c1284da` enforced at
> `kit-claim.sh:158`) and three were superseded by **ADR 0011**, which decided claims are recorded
> in committed artefacts and not derived into the index -- retiring the three findings that objected
> to index-time derivation specifically. The remaining seven are three claim-identity findings, due
> at the second census, and four rationale defects in the design document.
>
> **The box still FAILS.** Seven is not zero, and the trial task's fifth blocker requires zero.

**All 12 outstanding criticals are anchored in one file**, `docs/design-input/2026-08-27-census-store.md`
— a design for a feature that was never built. Verified:

```sql
SELECT DISTINCT file_path FROM finding
 WHERE severity='critical' AND fixed_at IS NULL
   AND unassessable_at IS NULL AND superseded_at IS NULL;
-- docs/design-input/2026-08-27-census-store.md
```

### The operator parked the census store, and that does NOT clear this box

`T-20260826-a-verified-claim-about-the-tree-has-no-a` is moved to **`on-hold`** by operator
decision on 2026-09-09. **The gate is unchanged at 12, deliberately.** `kit-preflight.sh:209-217`
queries the `finding` table with no join to `task` and no state predicate at all, and §0 of the
protocol says why in its own words:

> *"**Not filtered by task state.** An earlier revision read `AND t.state='progress'`, so a critical
> on a *done* task did not count — closing the task cleared the pre-flight exactly as well as fixing
> the defect… **A gate you can satisfy by editing a status field is not a gate.**"*

So parking is a true statement about the work — nobody is working the census store — and it is
**not** a route through the pre-flight. It was offered as one in the session that produced this
file, and that was wrong; the correction is recorded here rather than in a message that scrolls
away.

### What would actually unblock this trial — the operator's decision, not taken here

1. **Disposition the 12** under the 2026-09-09 ruling: they are design-stage findings, and the
   ruling says such a finding closes when the design is fixed. Most need the design fixed first, so
   this is not free.
2. **Amend §0's box** to read *no unfixed critical in shipped code*. Defensible on the grounds that
   a gate protecting a trial from defective shipped code is being held by criticals against an
   unbuilt design — but it is a protocol change, argued and recorded, never a bypass.

**Neither has been done. This trial has not started.**

## Baseline — taken 2026-09-09, BEFORE the kit touched the subject

`kit_footprint=none` was asserted in the same run that produced these numbers, not assumed. The
protocol requires the baseline before adoption because it cannot be reconstructed afterwards.

### Why Linux, and why this is the whole point

**Both this subject and aeon use io_uring, which is a Linux kernel API.**
`docs/ARCHITECTURE.md` names `io_backend.rs` as the *"io_uring backend (Linux)"* -- an
interface-first adapter whose OS-specific options are not fully integrated yet. The project's own
CI is `runs-on: ubuntu-latest`. **A Windows run therefore measures the compatibility shim, not the
subject**, and any earlier aeon-versus-highper-gateway comparison taken on Windows was comparing
two projects' Windows fallbacks.

So the environment is recorded as DATA, per
`T-20260826-the-trial-environment-is-recorded-as-pro`, and the field that makes a bad run
detectable is `io_uring_symbols`. On Windows it is zero.

```
image_distro      Debian GNU/Linux 12 (bookworm)   via nerdctl, rust:1-bookworm
kernel            6.6.87.2-microsoft-standard-WSL2
cores             8
io_uring_symbols  507                              <- the control; zero on Windows
rustc / cargo     1.98.0
cmake             3.25.1                           <- SUPPLIED, see finding 1
go                1.19.8
subject files     967      commits 169      head 05c56eb
kit_footprint     none
```

### Result

| | command | exit | seconds |
|---|---|---|---|
| **Build** | `cargo build --release -p highper-gateway` | **0** | 579 |
| **Test** | `cargo test --workspace --lib -- --test-threads=4` | **101** | 167 |

**The build passes on Linux.** The tests do not fail at runtime and do not fail on io_uring --
**they fail to compile**, so `cargo test` ran zero tests:

```
highper-gateway/src/runtime/signals.rs:238:47
error[E0308]: mismatched types: expected `Sender<ReloadTrigger>`, found `UnboundedSender<_>`
error: could not compile `highper-gateway` (lib test) due to 1 previous error; 60 warnings emitted
```

### Two SUBJECT findings, not applied

Per the three-kinds split below: delivered to the owner as a proposal, never applied here.

1. **Undeclared system dependency on `cmake`**, via `quiche 0.24 -> boringssl`. `.github/workflows/ci.yml`
   installs no system packages, so the build succeeds only because the `ubuntu-latest` runner image
   happens to ship cmake. On clean Debian with a Rust toolchain it fails at 151-156s with
   *"is `cmake` not installed?"*. Reproduced twice.
2. **The `--lib` test target does not compile at `05c56eb`.** Production `setup_signals_with_reload`
   takes a **bounded** `mpsc::Sender<ReloadTrigger>` (`signals.rs:50`, using `try_send` at `:92`),
   while two test sites still build `mpsc::unbounded_channel()` (`:200`, `:238`). The nearest
   `#[cfg(test)]` above the error is `:161`, so this is test-only -- the library itself builds.
   **The larger question was not the line, and it is now answered.** CI runs the same command, so
   the job had to be red or not running. **It is red** -- see the CI table below. That was checked
   before the run rather than discovered in the write-up, which is the difference between a
   recorded condition and an excuse.

### The subject's own CI, on the same SHA — red, and red before the kit arrived

Queried 2026-09-09 against `highperapp/highper-gateway`, run `25968962590`, head `05c56eb` — the
trial subject's exact commit:

| | job |
|---|---|
| **failure** | Test |
| **failure** | Check |
| **failure** | Clippy |
| **failure** | Security Audit |
| success | Build Release |
| success | Format |
| success | Validate Configs |

**Four of seven failing, and the last four CI runs are all failures, all dated 2026-05-16.**

**This is a parked project, not a neglected one.** The operator stopped work on it in May 2026 and
moved to other projects; nothing has been pushed since. The record says so here because a reader
arriving at this file in a year would otherwise infer decay, and because the trial protocol asks
what state the subject was in before the kit touched it.

**And it is the right kind of subject for a trial.** `design-input/2026-08-16-artifact-model-and-distribution.md`
section 3.3 argues explicitly for archived or unmaintained subjects: real accreted debt, and a
**frozen target, so two trials months apart remain comparable**. A moving subject would make the
second trial incomparable with this one.

**The baseline reproduces their CI independently.** `Build Release` green against
`cargo build --release` exit 0; `Test` red against `cargo test --workspace --lib` exit 101. Two
machines, two toolchains, same split — which is evidence the baseline measures the subject rather
than this environment, and it is a stronger check than either result alone.

`Check` and `Clippy` failing is consistent with the same single `E0308`: both compile the test
target, and `Clippy` runs `-D warnings` against the 60 warnings the build emitted. `Security Audit`
is `cargo-audit` and is a different thing — an advisory in the dependency tree, unexamined here.

### Two consequences for how this trial must be read

1. **Attribution.** The subject was already failing four jobs before the kit existed on it, so a
   finding the kit produces is **not** evidence the kit found something new unless it is checked
   against this table. Recorded before the run precisely so it cannot be decided afterwards.
2. **A free oracle, and it is the most valuable thing on this page.** The kit *should* independently
   surface the class of defect CI is already failing on. If a full run does not notice a test target
   that will not compile, **that is a finding about the kit** — and a sharper one than a green
   subject could ever have produced. This is the ground-truth injection that section 3.3 asks for,
   except that the subject supplied it rather than us.

### What this settles about the platform confusion

The difference between aeon passing and this subject not was **never io_uring and never Windows**.
At `05c56eb` this test target compiles nowhere. On Windows that is indistinguishable from the
missing backend; on a kernel with 507 io_uring symbols there is nothing else left to attribute it
to.

### Method — three false starts, recorded because the protocol asks for methodology findings

None was a subject defect and all three were mine:

1. Git Bash rewrote `/out/script.sh` into a Windows path; the container never ran the script.
2. `cmake` missing in the image -- a real subject finding, but not a baseline.
3. A `python` edit adding cmake died on a cygwin fork error, so the container silently re-ran the
   OLD script and failed identically.

**All three reported exit 0**, because the wrapper read the status of the last command in a
pipeline rather than of the thing under test -- `docs/LESSONS.md` section 12, *"a status read from
the wrong process"*. Each was caught by reading the log, never by the exit code. The final script
carries a hard abort if `cmake` is absent, so it can no longer produce a number that describes the
image instead of the subject.

### Reproduction

```sh
nerdctl run --rm -v <subject>:/src:ro -v <scratch>:/out   -v hg-target:/work/target -v hg-registry:/usr/local/cargo/registry   rust:1-bookworm bash /out/baseline3.sh
```

On Git Bash, prefix with `MSYS_NO_PATHCONV=1` or `/out/...` is rewritten before nerdctl sees it.

## Cost

*Not measured — the trial has not run.* When it does, plugin mode is the reason: kit-development
mode structurally emits **zero** `scope=subagent` rows, so every per-agent figure taken from a
development session is empty by construction rather than by result.

- BTE by tier / scope / provenance / model — pending
- BTE by agent — pending
- Raw counters — pending
- Wall-clock and API time, separately — pending

## Findings

*None. Not run.*

- By agent — pending
- Rejected by the recorder (`finding-gap` rows) — pending
- Escape rate by tier over both provenance populations — pending, and expected to have **no
  `via:kit` denominator** on a first run, which must be reported as an absent denominator rather
  than as zeroes shaped like a rate

## Which brownfield degradations bit

*Not measured.* The three to watch, from the protocol:

- Over-tiering from an empty edge table
- Co-change: usable graph, or withheld
- Planner ordering on a backlog it did not author

## Three kinds of finding

*None yet.* The split is stated in advance so it cannot be decided after the fact:

1. **Kit defects** — filed as tasks before any is fixed
2. **Subject defects** — delivered to highper-gateway's owner as a proposal, never applied
3. **Methodology** — folded back into `TRIAL-PROTOCOL.md` §3, with a detection

## Not exercised

Everything. Named rather than omitted, because an untested component named as untested is
information and one left out reads as fine:

- **Plugin mode itself** — the session that prepared this file is kit-development mode and cannot
  produce a `scope=subagent` row at all.
- **`kit-spend.sh` against a foreign subject.** Note before running: it writes into the
  **subject's** tracked `events.ndjson`. That is why the trial runs against an isolated copy at
  `…/scratchpad/trial-highper` and not against `D:\personal-github\highper-gateway`.
- **Cluster packs.** `.project/packs/` is empty in the kit and would be empty here too;
  `skills/task-context` step 4 loads a pack and there has never been one to load.
- **The Windows conformance suite** for kit SHA `9ce8b70`.

## Disputed

*Nothing. No finding has been produced to dispute.*

## Setup already done, so a run can start immediately

```
copy:      <scratchpad>/trial-highper
verified:  169 commits, 967 files, remotes: []   kit-preflight.sh --isolated -> exit 0
```

The run itself must happen in a **plugin-mode session**, which is the one thing the preparing
session cannot supply:

```
cd <scratchpad>/trial-highper
claude --plugin-dir D:\personal-github\cck\coding-kit
```

<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-09, plugin mode

> **RE-PREPARED 2026-09-10, STILL NOT RUN.** §0 below is the pre-flight as run on 2026-09-09,
> kept unedited with its gate box failing at 12. **§0b is the pre-flight for the run that can now
> start**: the gate reads zero, and the subject copy this file named had to be rebuilt because the
> original was destroyed by scratchpad reaping. Two boxes are the operator's — the time-box, and
> one stop-condition judgement §0b sets out.
>
> **PREPARED, NOT RUN.** Section 0 below is filled in; everything after it is empty on purpose and
> says why. The protocol requires the pre-flight answers to be recorded *before* the first command
> — *"Record the answers; they are part of the result"* — so this file exists at pre-flight rather
> than after, and a reader can see what was true before anyone touched the subject.

| | |
|---|---|
| Question | **Does the kit, loaded as a plugin, produce readings on a subject it did not author?** Specifically: does any `scope=subagent` spend row appear, and does any finding land, on a 967-file **Rust** subject with 169 commits. Written before the first command. **Corrected 2026-09-09: this read `PHP`.** The subject is Rust -- 291 `.rs` files, one `Cargo.toml`, 160 files referencing io_uring. File and commit counts were right; the language was not. ADR 0002's rule is that a pre-registered condition is only as good as its targets, so it is corrected before the run rather than after. |
| Kit SHA | `9ce8b70` at pre-flight on 2026-09-09. **Re-frozen 2026-09-10 at `50226b8`** for the run — §0b, which states the check that catches a tree drifting off it |
| Time-box / actual | not set / not run |
| Subject | highper-gateway — 967 tracked files, 169 commits, branch `master`, clean tree, **not adopted** (no `.project/`). **Unmaintained since 2026-05-16 by operator decision** — attention moved to other projects — and **red on its own CI** at this SHA. Both are recorded below and neither disqualifies it |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | **not run** — see §0 |
| Baseline before the kit | **TAKEN 2026-09-09, on Linux** -- build green, tests do not compile. See the Baseline section |
| Instruments verified live | **not yet** — this is the trial's own question |
| Copy isolation verified | **YES on 2026-09-09, and again 2026-09-10 on a REBUILT copy** — the first was destroyed by scratchpad reaping and reported itself intact via `git ls-files`. §0b carries the evidence and the new path |

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

## 0b. Pre-flight — RE-RUN 2026-09-10 against kit `50226b8`, and two boxes are the operator's

**§0 above is the pre-flight as run on 2026-09-09 and stays unedited**, gate box failing at 12. It
is not amended into a pass: the record of a trial that could not start is worth more than a tidy
table. This section is a **second, dated pre-flight** for the run that can now start.

**What changed between them:** the twelve criticals were dispositioned on evidence over PRs #78-#86
— none by amending §0's box, which is the bypass the 2026-09-09 record named and refused.

| box | command | result |
|---|---|---|
| Working tree clean | `git status` | **PASS** — clean at `50226b8` |
| CI green every platform | `gh run list --branch main` | **PASS** — `50226b8`, four checks, read unfiltered |
| Full local Windows conformance | `tests/conformance.sh` | see **Windows conformance** below |
| **No unfixed critical** | `kit-preflight.sh --criticals` | **PASS — "no unfixed critical outstanding"** |
| Unassessable criticals | `kit-preflight.sh --unassessable` | **9** — unchanged from 2026-09-09 |
| Superseded criticals | `kit-preflight.sh --superseded` | **39** — was 32 |
| `git rev-parse HEAD` recorded | | `50226b8f8fb92cc78c7adb45c8174017bdcf58ef` |
| Spend capture live | `kit-preflight.sh --spend` | **this trial's own question** — see §0 of 2026-09-09 |
| Findings capture live | `kit-review-record.sh` | **PASS** — 7 findings through the real loop, PR #79 |
| Copy isolated | `kit-preflight.sh --isolated <copy>` | **PASS** — see **The subject copy** below |
| Baseline before the kit | | **PASS** — taken 2026-09-09, unchanged; the subject is untouched |
| The question written down | | **PASS** — header table, corrected 2026-09-09 |
| **Time-box stated** | | **NOT SET — the operator's number** |
| Stop rules stated | | **PASS** — recorded below |
| Abort path stated | | **PASS** — recorded below |

### The kit SHA is frozen at `50226b8`, and the check for it can fail

Every command above ran against that tree. **This record itself lands on top of it**, so a tree
carrying this file is one docs-only commit ahead. Before the first trial command, run:

```sh
git -C <the kit checkout> diff --stat 50226b8..HEAD
```

**Only `docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md` may appear.** Anything else and the
pre-flight above describes a different kit than the one about to run, and it must be re-run.

### The subject copy — REBUILT, and the reason is a finding

**The copy this file previously named was destroyed**, and the way it failed is worth recording
because nothing announced it:

```
.git/objects   0 files, no packs, 177K total
git log        fatal: bad object HEAD
git ls-files   967          <- the stale index, answering as if intact
```

It lived in a **session scratchpad**, which is reaped. A later reader running `git ls-files` — the
same command that produced the "967 files" figure in this document — would have been told the copy
was fine. **The lesson is the location, not the loss:** a subject copy prepared by one session for
another session to use must not live anywhere a session owns.

Rebuilt 2026-09-10 by §4's procedure, at a path outside every repository and every scratchpad:

```
copy:      D:\trials\highper-gateway-05c56eb
made by:   git clone --no-hardlinks <subject> <copy>   then   git remote remove origin
verified:  HEAD 05c56eb   169 commits   967 files   branch master   clean
           remotes 0   alternates none   .project absent (not adopted)
control:   kit-preflight.sh --isolated <copy>  ->  "isolated -- no remote, no shared object store"
```

**Two checkouts of this subject exist on the machine and only one is this trial's subject:**

| path | HEAD | commits | files | tree |
|---|---|---|---|---|
| `D:\personal-github\highper-gateway` | `05c56eb` | 169 | 967 | clean — **this one**, and it matches the baseline |
| `D:\my-opensource\highper-gateway` | `4da4c07` | 217 | 971 | dirty — **not this trial's subject** |

Cloning the second would change the subject silently and invalidate every figure in this document.
The copy above carries `05c56eb` in its own directory name so the mistake is visible in a path.

### Windows conformance

`116 passed, 0 failed` on `5116200` (2026-09-10). A second full run was started on `50226b8`, the
frozen SHA, and its result is recorded here rather than assumed:

**RESULT: 116 passed, 0 failed, 0 skipped.** Same figure as the `5116200` run, one step wider than
the 2026-09-09 suite because F1d added a step.

**One caveat, stated because the alternative is a measurement nobody can check.** The run was
started against the `50226b8` tree and **this file was edited while it was in flight** — so the
tree was not constant for its whole duration. Why that does not invalidate it, checked rather than
asserted:

- `grep -n 'docs/TRIALS' tests/conformance.sh` returns **one** line, and it only asserts
  `docs/TRIALS/TEMPLATE.md` exists. **No step reads this file.**
- `validate.py` walks `.md` under `agents/` and the plugin directories, not `docs/TRIALS/`, and it
  was run by hand on the final tree: 7 ok, 0 warnings, 0 errors.
- CI ran the full suite on the exact branch tree on ubuntu and macOS, both green.

A Windows run over a tree that never moved has **not** been done. If that is wanted before the
trial, it is one command and about an hour:

```sh
KIT=$(pwd) WORK=<empty scratch dir> bash tests/conformance.sh
```

The three commits between `5116200` and `50226b8` are data-only — `.project/plans/default.tsv`, one
task file, one `events.ndjson` line — but "data-only" is an argument and the box asks for a run, so
it was run.

### Stop rules — stated before the run, per §0

Stop and record what you have when **any** of these holds. None is a judgement call at the moment it
fires; the judgement was making the list.

1. **The time-box expires.** Whatever has been produced is the result.
2. **The same kit defect blocks progress three times.** Not three defects — the same one, three
   times. A kit that cannot get past its own defect is the finding.
3. **Any VOID condition in §3 is hit.**

### Abort path — stated before the run, per §0

If the kit **crashes or corrupts state mid-trial**, the trial is recorded as **ABORTED at that
point, with the cause**. It is never silently restarted: a restarted trial has a contaminated index
and is no longer comparable with any other trial, which is the whole reason this protocol exists.

### The one box the operator must judge, and it is not the time-box

§0's unassessable box defines **three things that are stops**, and the first one needs a human:

> *An unassessable critical on a task this trial will exercise. The blind spot is then inside the
> path being measured, and any finding the trial produces there cannot be told from the one nobody
> could judge. Check the `task_id` column the command prints against the trial's scope.*

The nine unassessable criticals sit on **five** tasks, and every one of them is plausibly inside
this trial's path:

| task | findings | why it is arguably in scope |
|---|---|---|
| `T-20260808-a-task-id-matching-no-task-file-is-count` | 3 | the trial ingests a foreign backlog into tasks — a task id matching no file is that failure mode |
| `T-20260808-record-how-a-task-was-executed-so-kit-wo` | 2 | "each carries how it was executed" is an acceptance criterion of the trial task itself |
| `T-20260801-nothing-invokes-kit-finding-so-the-findi` | 2 | whether a finding lands is one of this trial's two questions |
| `T-20260808-kit-cfg-strips-space-and-tab-from-a-valu` | 1 | the profile is read on every path the trial exercises |
| `T-20260808-an-apostrophe-in-a-tier-rule-breaks-the-` | 1 | tier floors meeting brownfield paths is a named degradation this trial measures |

**This is recorded as a question and not ticked.** The other two stop conditions do NOT fire, and
both were checked rather than assumed: the count is **9, unchanged** since 2026-09-09 (condition 2
is about it going UP), and **0 of the 9 print `(no reason recorded)`** (condition 3).

A defensible answer is to run anyway and carry the five task ids in the report, so a finding landing
on one of those paths is read next to the blind spot rather than instead of it. That is a decision,
not a formality, and it is the operator's.

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

> **CORRECTED 2026-09-10.** This section named `<scratchpad>/trial-highper`, and that copy no longer
> exists — a session scratchpad is reaped, and the remains answered `git ls-files` with 967 as if
> intact. The path below is outside every repository and every scratchpad for exactly that reason.
> §0b carries the evidence; the old path is recorded here rather than quietly swapped.

```
copy:      D:\trials\highper-gateway-05c56eb
verified:  HEAD 05c56eb, 169 commits, 967 files, master, clean, remotes: [], alternates: none
           kit-preflight.sh --isolated -> exit 0     (re-verified 2026-09-10)
```

The run itself must happen in a **plugin-mode session**, which is the one thing the preparing
session cannot supply:

```
cd D:\trials\highper-gateway-05c56eb
claude --plugin-dir D:\personal-github\cck\coding-kit
```

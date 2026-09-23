<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial 3: highper-gateway — written 2026-09-20, RUN 2026-09-23

| | |
|---|---|
| Question | **Does the verify ladder produce a verdict you can act on, when it runs on a real code change in an unfamiliar codebase whose baseline is red?** Written at pre-flight, before the first command. |
| **Answer** | **Yes — and the verdict is one no gate could have produced.** Rungs 4 and 5 both returned REJECT, blind to each other, converging on a critical: the change is correct as an import fix *and* it takes undefined behaviour from unbuildable to shippable. |
| Kit SHA | `a2f9177` at the clock (pre-flight was written at `0c61c69`, 7 commits earlier); runtime `cck-trial` image `e5ed7efcc9b5`, kernel `Linux 6.6.87.2-microsoft-standard-WSL2 x86_64`, cargo 1.98.1, rustc 1.98.1 |
| Time-box / actual | **1 hour.** Actual **53 min** (01:25:31Z → 02:18Z). Not extended. |
| Subject | highper-gateway, Rust workspace. Subject `e588b53` (untouched, verified after). Copy `9cc4e55` + 2 pre-flight + 3 trial commits |
| Greenfield / brownfield | **brownfield**, history not truncated, all 3 branches present, 175 pre-kit commits |
| Unassessable / superseded criticals | **9 / 40.** Previous trial to record them, 2026-09-09: **9 / 39.** Unassessable unchanged since 2026-08-24; the one new superseded row is `tests/conformance.sh` superseded by `52c83b2`. |
| Rung dispositions | **See the table below — and two of the five land in a state the ladder cannot name.** |
| Outcome | **COMPLETE, subject to the operator's disposition of rungs 1 and 2.** The trial ran end to end, every instrument recorded, no VOID condition fired. What is unresolved is a naming conflict between two kit documents, not a gap in the run. |
| Baseline before the kit | **Red on 3 of 4 rungs — and the recorded cause was wrong.** See Baseline. |
| Instruments verified live | spend rows > 0, findings rows landed, **2 `finding-gap reason=rejected` rows recorded and recovered** |
| Copy isolation verified | `kit-preflight.sh --isolated` exit 0 |

## Rung dispositions

**A reader must not be able to reach the outcome without passing these** (§6).

| Rung | Obligation | Command | Disposition |
|---|---|---|---|
| 1 | compiles + static analysis | `cargo check --workspace --all-features` → **101**; `cargo clippy … -D warnings` → **101**; `cargo build --release -p highper-gateway` → **0**; `cargo fmt --all -- --check` → **0** | **CONTESTED.** The change's own module went 89 errors → **0**. The 7 that remain are in two files the diff does not touch. The command ran; it cannot be made to pass for reasons outside the change. |
| 2 | criteria proven by tests that fail without the change | `cargo test --workspace --lib -- --test-threads=4` → **101** | **CONTESTED.** The command RAN and gave a real signal: **972 passed / 2 failed, identical with and without the change** (measured by stashing). But no test proves *this* change — its effect is compile-time, under a feature the test job does not enable. |
| 3 | wiring proof | nothing declared (`ladder.rung3:` empty) | **UNAVAILABLE.** Tier raised T2 → T3. Compensating control: two adversarial readers instead of one. |
| 4 | adversarial reader | Agent-tool subagent | **SATISFIED.** REJECT, 4 findings. |
| 5 | blind second reader | Agent-tool subagent, spawned in parallel so neither could see the other | **SATISFIED.** REJECT, 4 findings. |

### Why two rungs are CONTESTED rather than dispositioned

`skills/verify-ladder/SKILL.md` defines **unsatisfiable** as *"a satisfaction IS declared and it
does not run, **or cannot be made to pass for reasons outside the change**"*, and gives as its own
example *"a target that does not compile before you touched it"*. That is this subject exactly. On
that text rung 1 is unsatisfiable, and §3 plus §6 make the trial **VOID**.

But §0 asked the same question before the clock. `kit-preflight.sh --commands` observed
`test:101, lint:101, typecheck:101`, and the disposition recorded was **`=baseline`** — the state
§0 explicitly blesses: *"A subject whose tests already fail is a valid trial subject, but only if
you knew that first, and only if you knew WHY."* Pre-flight exited **0**.

**Two controls, one fact, opposite outcomes.** If the ladder's text governs, then every subject
with a red baseline is VOID by construction and §0's permission to trial one can never be
exercised. If §0 governs, the ladder's `unsatisfiable` has no force on precisely the subjects it
was written for — it was added because the 2026-09-09 trial reported COMPLETE over a change that
does not compile.

Neither reading is available without a name the ladder does not have: **the tooling runs, the
obligation is met for the change, and the declared command's scope is wider than the change.**
Rung 2 needs a second missing name: **the tooling runs and the obligation does not apply to this
change class.** That is the 2026-09-09 failure one layer out — *"the enumeration had two names and
the situation was a third"* — and it is now two situations and two missing names.

Filed as kit findings. **The outcome label is the operator's call.**

## Stop rules, stated before the clock

Stop and record what you have when **any** of these fires:

- the time-box expires
- the same defect appears a **third** time — that is a pattern, not an instance
- **any VOID condition in §3 fires**
- the kit needs a `commands.*` change to proceed
- you cannot state what the next step is testing

**None fired.** The box was not reached (53 min of 60). No defect recurred three times. The §3
detections were run at the end and all pass — profile unchanged since the clock, `0`
`=unsatisfiable` dispositions with pre-flight exit 0, clean tree before the final reindex.

## Abort path, stated before the clock

If the kit crashes or corrupts state mid-trial: **stop, do not repair.** Not invoked.

## Baseline before the kit

Taken before adoption, in `cck-trial`, read-only mount, tree clean after. **Commands are the
subject's own, from `.github/workflows/ci.yml`.**

| their CI job | command | exit | cause |
|---|---|---|---|
| Check | `cargo check --workspace --all-features` | 101 | **90 errors, two causes** — see below |
| Clippy | `cargo clippy --workspace --all-features -- -D warnings` | 101 | same two causes |
| Test | `cargo test --workspace --lib -- --test-threads=4` | 101 | **2 failing tests**, unrelated to either |
| Format | `cargo fmt --all -- --check` | **0** | clean |
| Build Release | `cargo build --release -p highper-gateway` | **0** | one package, no `--all-features` |

**CORRECTED TWICE, AND THE SECOND CORRECTION IS THIS TRIAL'S FIRST FINDING.**

Revision 1 used invented commands (`cargo check --locked`) and reported *"the subject compiles"*.
Revision 2 fixed the commands and recorded *"One root cause — `async_trait` — not the three
symptoms the wrong commands surfaced."* **Revision 2's cause is also wrong**, and it was wrong in
the more dangerous direction: it was measured with the right commands and reported a cause nobody
had counted.

Measured 2026-09-23, first command of the trial:

| cause | errors | files |
|---|---|---|
| feature-gated code whose `use` statements were never added | **89** | `plugin/ffi.rs` 35, `plugin/wasm.rs` 29, `plugin/host_functions.rs` 25 |
| `consul::types` — the crate has no such module | **1** | `discovery/consul.rs:151` |

Missing names by count: `PluginError` 23, `FilterResult` 18, `Arc` 12, `PluginExecutionContext`
11, `PluginStats` 6, `PluginMetadata` 6, `PluginLimits` 3, **`async_trait` 2**, `PluginTypeInfo` 2,
`Plugin` 2, `Bytes` 2.

So `async_trait` is **2 of 90 symptoms**, there are **two** causes and not one, and the Test job's
101 is a **third**, unrelated cause: `cache::manager::tests::test_health_check` and
`runtime_config::loader::tests::load_with_no_env_vars_returns_defaults` both fail on an
uninitialised `runtime_config` global. The baseline recorded Test's cause as *"test failed"* —
which is the aggregate verdict §0 forbids, one level down from the job name.

**The lesson is not "check harder".** Revision 2 fixed the commands, which was the right method,
and then carried an unverified cause through the correction. §0 requires the word `unverified` on
exactly this, and revision 2 did not use it.

## The change

`T-20260923-feature-gated-plugin-code-references-typ`, **T3**, `via: kit`.

Tier by the axes: blast radius **unknown** — the repository was adopted the same morning, so the
edge table is empty and unknown floors at T2. Rung 3 undeclared → raise one → **T3**.
Reversibility and ambiguity are both low on their own.

**12 added lines, 0 deleted, 0 modified — every one a `use` statement**, in three files.

| reading | errors | in `plugin/` |
|---|---|---|
| before | 90 | 89 |
| after the 11 obvious imports | 12 | 5 |
| after `super::Result` in `host_functions.rs` | **7** | **0** |

The middle reading is the one worth keeping. Importing `PluginError` alone left four `E0308`s and
one `E0277`: bare `Result<T>` in that file was resolving to `anyhow::Result` through the
`wasmtime::*` glob while every body built a `PluginError`. Both sibling files already import the
pair. **An explicit import beats a glob import in Rust, so one line cleared five errors.**

Acceptance criteria: 1, 2 and 3 met — criterion 2 is proven by the diff itself, a pure-addition
diff of import lines. Criterion 4 met, `cargo build --release` exits 0.

### The 7 that remain were UNMASKED, not introduced

6 of the 7 do not appear in the before-log. They sit in `discovery/consul.rs` (6) and
`middleware/waf/aws_engine.rs` (1) — two files the diff does not touch — and concern third-party
crate APIs. rustc aborts after name resolution, so while 89 resolution errors stood it never
type-checked those files.

**That phase-progression explanation is an INFERENCE and is written with the word**, per §0. What
is *measured* is that the diff touches neither file, and that the same unmasking happened inside a
file the change does touch, where the cause is not in doubt.

## Cost

**n on every figure.** Billable input-token-equivalents: input ×1, cache-write ×1.25, cache-read
×0.1, output ×5.

| scope | n | turns | BTE | context |
|---|---|---|---|---|
| main loop | 1 | 305 | **6,078k** | 236,498 |
| rung 4 reviewer | 1 | 48 | **560k** | 100,622 |
| rung 5 reviewer | 1 | 29 | **399k** | 92,596 |
| **both reviewers** | **2** | 77 | **959k** | — |

**The main-loop figure is a floor, not the total.** §3's ninth condition: main-loop spend is
written at each `Stop`, so a reading taken inside the session omits the turn that produced it.

**A fourth row exists in the table and must not be summed.** `main / 48 turns / 560k` is
byte-identical to the rung-4 reviewer's row, because the first `kit-spend.sh --transcript` call of
the trial was given a *subagent's* file. `kit-spend.sh` derives the subagent directory as
`${TRANSCRIPT%.jsonl}/subagents`, so it expects the **main** transcript and walks the folder
itself. Given a subagent file it found no sub-folder, recorded the subagent's totals under
`scope=main`, and exited 0. **Operator error, not a kit defect** — traced with `bash -x` before
being written down, and the row is left in place and named here rather than deleted, because
editing a measurement you are reading is its own failure.

Wall-clock is not comparable across machines and is not offered as a measurement of the kit.

## Findings

**8 rows over 8 distinct defects**, 2 critical / 3 major / 3 minor. By class: correctness 4,
fail-open 2, compliance 1, style 1. **Attribution: 8 of 8 joined to the reviewer run that produced
them** — 4 per agent, using the Agent-tool subagent id rather than the session id. On 2026-09-14
this repository recorded 54 of 54 attributed findings that joined nothing.

| finding | rung 4 | rung 5 | severity |
|---|---|---|---|
| `to_ffi_context` returns pointers into two local `String`s dropped at return — use-after-free across the C ABI | ✓ | ✓ | **critical** |
| WASM sandbox enforces only `fuel`: epoch deadline set, `increment_epoch` never called; `timeout_ms`/`memory_mb`/`max_concurrent_requests` read nowhere | ✓ | ✓ | major |
| `call_ffi_function` never copies plugin changes back — FFI plugins are write-blind | — | ✓ | major |
| added imports unused under default features; should be cfg-gated like the `libloading`/`wasmtime` lines below them | ✓ | ✓ | minor |
| newly type-checked code trips `dead_code` and `manual_range_contains`, which the clippy `-D warnings` job denies | ✓ | — | minor |

**Overlap 3 of 5 — close to the ~70% the skill predicts — and each reader brought one the other
missed.** That is rung 5 behaving as documented: a different half of the problem, not a second
opinion on the verdict. Both returned REJECT.

**Both also refused the prompt's planted suspicion.** The request asked whether `super::Result`
silently re-typed `host_functions.rs`. Rung 4 cleared it through the `func_wrap` closures
returning `i32`; rung 5 cleared it through the absence of `From<anyhow::Error> for PluginError`.
Neither took the steer.

**The critical was verified by hand before being repeated here**, not accepted on two agents'
word: `to_ffi_context` builds `request_json`/`response_json` as locals, stores `.as_ptr()` into the
returned struct, and returns; `call_ffi_function` then passes it to plugin code.

### Rejected by the recorder — 2 rows, both recovered

`kit-review-record.sh` refused **both** reviews on first submission. **8 of 8 summaries over the
200-character cap** (359, 362, 417, 360, 392, 450, 385, 419). Rejection is all-or-nothing, so both
criticals were lost at that moment, and survive only because the caller re-asked.

**The cause is the kit's own published example.** The output contract in
`skills/verify-ladder/SKILL.md` shows `class`, `severity`, `summary`, `lang` and nothing else — no
`file`, no `line`, and no length limits, all of which `kit-finding.sh --contract` enforces. A
reviewer given that shape has nowhere to put a location except `summary`. Both did. Both were
refused.

The gap rows mean the loss is **visible**, and §3's detection returned `rejected|2` on the copy —
that half of the control works, and this is the first live confirmation of it.

## Which brownfield degradations bit

- **Over-tiering from an empty edge table: YES, and it decided the tier.** Blast radius unknown →
  T2, then rung 3 unavailable → T3. `tier_floor` came back `NULL` — "no basis to judge" — which is
  the documented fresh-adoption state and read correctly rather than as "meets its floor".
- **Co-change: not exercised.** `git.adopted_at` was deliberately left unset so the graph could
  see all 175 pre-kit commits, but nothing in this trial consumed a co-change ordering.
- **Planner ordering on a backlog it did not author: not exercised.** The backlog has one task.
- **Trailer discipline on a fresh adoption: as predicted.** 175 commits carry no `Task-Id`, which
  is the cost of leaving `adopted_at` unset and was chosen with that cost stated.
- **Provenance defaulted to `unknown` on work that was entirely kit-driven.** Escape rate read
  `T3 0 / 0 via:kit` with the one real task in the `unknown` partition — the open-circuit reading
  the partition exists to prevent. `kit-task.sh --via` and a `Via:` trailer both exist; nothing
  prompts for either. Corrected by hand, and the correction committed.

## Three kinds of finding

### 1. Kit defects — filed as tasks before any is fixed

| # | finding | tier |
|---|---|---|
| K1 | `verify-ladder/SKILL.md`'s reply example omits `file`, `line` and every length limit `kit-finding.sh --contract` enforces, so a reviewer following it is refused and an all-or-nothing rejection loses the review. **2 of 2 reviewers, 8 of 8 summaries.** | T2 |
| K2 | §3's structural-blindness detection greps the file's **basename**, which returns nothing on any language whose module system drops the extension. On all three changed files it returned empty — a pass that asked nothing. The stem form returns 6 files. | T2 |
| K3 | The ladder's `unsatisfiable` (*"cannot be made to pass for reasons outside the change"*) and §0's `=baseline` describe one fact and imply opposite outcomes, so every red-baseline trial is VOID by construction and §0's blessing of one is unreachable. | T3 |
| K4 | The ladder has no disposition for *"the tooling runs and the obligation does not apply to this change class"* (rung 2 here), nor for *"the declared command's scope is wider than the change"* (rung 1). | T3 |
| K5 | `kit-init.sh` named **two** blocked paths — `.claude/project-profile.md` and `.project/tasks` — and printed the remedy for `.claude/` only. **This is K5 of the 2026-09-09 trial, unchanged.** | T2 |
| K6 | Nothing prompts for task provenance. `kit-init.sh`'s six printed next steps and the verify-ladder skill both omit it, and the default silently empties the `via:kit` escape denominator. Same shape as K6 of 2026-09-09 (`git.adopted_at`). | T2 |
| K7 | Adoption from a session rooted elsewhere records **no spend at all** in the adopted repo — the hooks fire for their own session's root. `kit-status.sh` says so, which is the good half; the recovery is manual. | T2 |

### 2. Subject defects — the owner's, delivered as a proposal, never applied

The two criticals and the three other findings above, plus:

- `highper-gateway/src/tls/` is an **empty directory**.
- `highper-gateway/src/middleware/compression_old.rs.backup` is a dead file in the tree.
- The `Cargo.lock` was one entry short of its manifest (fixed in the copy at pre-flight, recorded).

### 3. Methodology — folded back into `TRIAL-PROTOCOL.md` §3, with a detection

- **M-1 = K2.** Detection: run the basename form and the stem form and compare; a basename form
  returning empty on a non-shell codebase is the signal.
- **M-2.** §3's own text asserts the finding-gap query *"returns `empty|2` here — two gaps, both
  `empty`, no `rejected` rows"*. Run against the kit today: **`empty|2`, `rejected|4`**. The four
  are historical (2 on 2026-09-09, 2 on 2026-09-14), so the recorder works — but the document
  states a claim about this repository that stopped being true and is written as a fact.
- **M-3.** A cause that survives a correction is not thereby verified. Revision 2 of this
  baseline fixed the *commands* and carried an unmeasured *cause* through, and the corrected
  document reads as more trustworthy than the one it replaced.

## Not exercised

*An untested component named as untested is information; one omitted reads as fine.*

- **Co-change and the planner.** One task in the backlog, so no ordering was produced or judged.
- **Cluster packs.** `pack_loads` is 0 on every spend row.
- **Accelerators.** None declared; `tier.rule` floors came from the profile alone.
- **`kit-checkpoint.sh`, `kit-claim.sh`, `kit-criteria.sh`, `kit-entry.sh`, `kit-charter.sh`,
  `kit-accel.sh`, `kit-vindicate.sh`, `kit-resolve.sh`** — none ran.
- **The escape mechanism.** No `Fixes-Escape-Of:` trailer exists here, so every escape numerator
  is zero by construction. That is the denominator only, and the status output says so itself.
- **Rung 3.** Undeclared, so the wiring of the FFI and WASM paths was never proven — which is
  exactly where both reviewers found the criticals. The tier was raised in compensation and the
  raise is what bought the second reader.
- **The subject's own CI.** Nothing was pushed; the subject is untouched at `e588b53`.

## Disputed

*Findings the subject's owner disagrees with — both positions, unresolved.*

None yet. The subject's owner has not seen these findings. The two criticals and the sandbox
finding are the ones to deliver first.

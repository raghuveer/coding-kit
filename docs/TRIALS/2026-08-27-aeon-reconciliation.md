<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: aeon (roadmap reconciliation) — 2026-08-27

> **COMPLETE, 2026-08-27.** Second subject for the reconciliation instrument, run one day after
> `2026-08-26-highper-gateway-reconciliation.md`. Its purpose is different from that trial's:
> highper-gateway asked *does the instrument work*. This one asks **does what it found generalise,
> or was it a property of one repository**. That question cannot be answered by a single subject,
> which is why this trial exists at all.

| | |
|---|---|
| Question | **Is "compiles, tested, zero production callers" a property of one codebase or a general failure mode of roadmap-driven development — and does the cost of finding it scale with the codebase or with the claim count?** |
| Kit SHA | `main` at the 2026-08-26 state (K-1 merged); no kit change landed between the two trials, so the instrument is identical |
| Subject | `aeon` — Rust workspace, **14 crates**, 277 `.rs` files, 50 markdown docs, **249 commits**, HEAD `8cd9dae` (2026-05-06) |
| Subject relation to trial 1 | **Unrelated codebase, same language, different domain** (streaming data pipeline vs HTTP gateway), different author-period, no shared dependencies of consequence |
| Greenfield / brownfield | **brownfield**, history intact |
| Scope | the **18 phases marked ✅** in the roadmap, re-derived against the tree |
| Outcome | **COMPLETE** — the question was answered, and the answer is *general* |
| Instruments verified live | **spend** — 19 rows, 18 of them `scope=subagent`, all `claude-opus-5`. **findings** — see *Kit defects*, the census again came back as prose |
| Copy isolation | ran in an isolated copy under the job tmp directory; no remote |

## Cost

Billable-token-equivalent = `in×1 + cache_write×1.25 + cache_read×0.1 + out×5`.

| scope | rows | turns | BTE |
|---|---|---|---|
| main | 1 | 47 | 3,161,786 |
| **subagent** | **18** | **1,209** | **13,853,224** |
| **total** | **19** | **1,256** | **17,015,010** |

**Escape rate: still `0 / 0 via:kit`.** No task closed in this trial. Unchanged denominator,
so no rate is reported — printing zeroes in the shape of a result is the thing the convention exists
to prevent.

## Results

**489 claims re-derived across 18 phases marked ✅.**

| | count | share |
|---|---|---|
| Confirmed | 252 | 52% |
| **Diverge from tree** | **173** | **35%** |
| — overstated | 139 | 28% |
| — stale citation | 20 | 4% |
| — understated | 14 | 3% |
| Unverifiable | 64 | 13% |

**Phase verdicts: 2 DONE, 16 PARTIAL.** Only Phase 0 (foundations) and Phase 2 (Kafka/Redpanda)
survive. Phase 2 is *ahead* of its description — three delivery strategies, transactions, mTLS
translation, pause/resume drain, runtime partition reassignment on ownership flips.

Worst: **Phase 10 (Security & Crypto)** — 46 claims, 19 overstated, assessed "PARTIAL, closer to
NOT-STARTED on security posture". **Phase 7 (Wasm)** — 15 of 23 overstated.

## The answer to the question this trial existed to ask

**It generalises.** Two unrelated Rust codebases, six months apart in authorship, same dominant
failure mode, and in aeon it is *worse* and reaches security controls.

**Two entire orphan crates.** `aeon-io` — nothing in the workspace depends on it, so the project's
own `CLAUDE.md` rule #4 is unfollowed everywhere. `aeon-secrets` — Vault KV-v2 and Transit,
`KekRegistry`; the string `aeon_secrets::` returns **zero hits repo-wide**.

**Zero-caller subsystems**, abbreviated: `DagGraph` (31 unit tests), `StringInterner`, the SIMD
scanner, `BatchTuner`, `DeadLetterQueue`, `CircuitBreaker`, `retry_async`, `ShutdownCoordinator`,
`serve_health` / `serve_metrics`, `PipelineObservability`, `TieredStore` with windowing and
watermarks, `EncryptedL3Store`, `KeyProvider`, the FIPS guard, `TlsMode` / `CertificateStore`,
`AuthConfig`, `HsmProvider`, `PohCheckpoint`, `MerkleTree::proof`, `DeliveryLedger`. The
`Seekable` trait has **zero implementors**.

**A prediction I made and got wrong, recorded because the correction is the finding.** Before
reading the results I predicted the unreachable subsystems would cluster in the *later* phases —
cluster, QUIC, PoH — on the reasoning that Gate 1's core is demonstrably live and therefore its
declared surface probably was too. They start at **Phase 0** and run through everything. `DagGraph`,
`StringInterner`, the SIMD scanner and `BatchTuner` are all Gate 1. **A working core is not
evidence that the core's declared surface is wired**, and I had no basis for treating it as such.

## Two classes this subject surfaced that trial 1 did not

The first trial produced one mechanical class — *no production caller* — now filed as
`T-20260826-reachability-of-a-declared-feature-is-me`. This subject shows that class has **two
blind spots**, and both hide security findings.

### Class A — declared, but compiled by no build configuration

A call-graph analysis run from a production entry point reports these as unreachable, which is
true but misleading: the remedy is not "wire it up", it is "the code is not in the binary at all".

- `crates/aeon-state/src/l2.rs` — 646 lines, 17 tests. Its `mmap` feature is enabled by **zero**
  `Cargo.toml` in the workspace.
- **All of `crates/aeon-cluster`** — Raft, QUIC, a three-stage transfer protocol, ~13.4 kLOC, and
  **23 integration tests** — because CI passes only `--features aeon-engine/rest-api`, which does
  not imply `cluster`, and neither does `cargo build --release -p aeon-cli`. Only the Docker image
  contains Phase 8. So the 23 tests that would substantiate the Gate 2 acceptance criteria have
  **no automated execution path at all** — they are neither run nor clippy'd by anything.
- `crates/aeon-crypto/src/fips.rs` — `fips` declared in exactly one `Cargo.toml`, its own.
- Encryption-at-rest (`aeon-cluster/src/store.rs`) — `encryption-at-rest` enabled by nobody.
- Tier D E2E tests — gated `#[cfg(feature = "webtransport-host")]`, enabled nowhere; the
  non-feature twins are `#[ignore]` + `todo!()`.

This is **more mechanical than the call-graph question**, not less: it is a set difference between
features declared and features enabled, computable from manifests and CI configuration without
parsing a line of source.

### Class B — constructed and called, but hardwired off

**This is the sharp one, because it is invisible to both of the above.** The symbol has a
production call site. The call graph reaches it. Dead-code analysis sees it used. And the argument
passed is a constant that disables it.

- `crates/aeon-cli/src/main.rs:1264` — `authenticator: None`. **The shipped REST API is always
  unauthenticated**; the binary logs `auth DISABLED` and passes every request. The roadmap claims
  "REST API auth wiring ✅, Bearer middleware."
- `set_audit_sink` is never called outside the test module, so the process-global audit sink stays
  `NullAuditSink` and **13 emit sites across 5 crates are discarded — five of them authentication
  rejections.** Independently re-verified by enumeration and filed with the subject as AEON-002.
- Every production spawn passes `ledger = None`, so persisted checkpoints carry empty
  `source_offsets` and `pending_event_ids`, and `load_recovery_plan` is never called from the
  production runner. Crash recovery is fully written and cannot restore a position.
- `ws_host: None` — `/processors/connect` returns 503 in every build.
- Nothing writes `PipelineConfig.delivery.strategy`, so the engine always takes the blocking
  `OrderedBatch` path regardless of the sink-level `strategy:` key a manifest sets.

Note where the two security findings live: **both are Class B.** A reachability pass built to the
acceptance criteria currently filed would have cleared both.

## Which brownfield degradations bit

- **Adoption boundary.** The subject was never kit-adopted; all 249 commits predate the run. Same
  as trial 1 — the instrument reads a tree, it does not need history it authored.
- **The tree contained its own refutation, and nothing compared the two.** `docs/GATE1-VALIDATION.md:14`
  records 245ns where the roadmap claims `<100ns` "proven". `docs/perf-results/2026-05-03-bench.md:162-165`
  marks the 8-partition result FAIL where Phase 15c claims 5.29x. `docs/CONNECTORS.md:8-9` is closer
  to the code than the ✅ beside it. `pipeline.rs:606` says *"DLQ routing pending Phase 15b"* while
  roadmap line 2686 says it was "already built in Phase 5". This is the sixth and seventh instance
  of `T-20260826-two-artefacts-carrying-one-fact-with-not`, and the first where the *honest*
  artefact was the one nobody read.

## Three kinds of finding

### 1. Kit defects

**Already filed, and this trial is confirming evidence rather than new information:**

- `T-20260826-a-verified-claim-about-the-tree-has-no-a` — **489 claims came back as prose in a
  subagent reply, for the second consecutive trial.** 792 verified claims now exist across two
  trials and the kit holds a row for none of them. The cost of that is no longer hypothetical: this
  document is the only place either census survives, and it survives as narrative.
- `T-20260826-reachability-of-a-declared-feature-is-me` — **confirmed as general, not over-fitted.**
  This was filed on one subject's evidence and could reasonably have been a property of that
  subject. It is not.
- `T-20260826-the-trial-environment-is-recorded-as-pro` — writing the cost comparison in this
  document required re-deriving both trials' figures by hand from `events.ndjson`, because neither
  trial's environment or totals are queryable.
- `T-20260826-two-artefacts-carrying-one-fact-with-not` — two further instances, above.

**New, filed from this trial:** see `Class A` and `Class B` above, plus the estimation finding
below. Task ids are recorded in the *Provenance* section once filed.

### 2. Subject defects — a proposal for the owner, filed in the subject's own repository

Nothing in this backlog. **AEON-002** was written into `docs/FINDINGS-2026-08-26.md` in both aeon
working copies and committed there (`59a9d66` on `aeon-rust/aeon` `main`, `86bab68` on
`v0.2-canonical`). It also amends AEON-001's closing claim, which was wrong about its premise: that
commit said "a running process installs its sink once at startup", and no running process does.

The other items above are **not** filed as subject defects, because they were produced by a survey
rather than reproduced by hand. That distinction is deliberate and is stated inside the findings
file so a later reader can tell which statements carry which weight.

### 3. Methodology

**M6 — cost tracks claim count, not codebase size.** This is the finding that makes the instrument
schedulable, and it is the reason to run a second subject at all.

| | highper-gateway | aeon |
|---|---|---|
| Subject size | 291 `.rs`, 2 crates, 169 commits | 277 `.rs`, 14 crates, 249 commits |
| Units | 16 use cases | 18 phases |
| **Claims** | **303** | **489** |
| Confirmed | 47% | 52% |
| Diverge | 43% | 35% |
| Fully DONE | 0 of 16 | 2 of 18 |
| Subagent rows | 17 | 18 |
| Turns | 764 | 1,256 |
| **BTE** | **11,066,325** | **17,015,010** |
| **BTE per claim** | **36,522** | **34,796** |

1.61× the claims for 1.54× the cost, across two repositories that differ in crate count by 7×.
**Per-claim cost varies by 5%.** That means a reconciliation can be quoted from the roadmap before
it runs — count the ✅ items, estimate claims per item, multiply. The kit has no way to express
that estimate today, which is the third new task.

**M7 — a survey and a defect report are different artefacts and must not merge.** AEON-002 was
promoted out of the survey into the hand-verified findings file only after I re-ran the enumeration
myself. Everything else stayed in the survey. Without that rule the findings file would silently
acquire 489 claims of unstated provenance, and its existing hand-reproduced findings would lose the
thing that makes them worth reading.

**M8 — record the prediction before reading the result.** Mine was wrong in a specific, useful way
(see above), and it was only visible as wrong because it had been stated. An unstated prior is
unfalsifiable and teaches nothing.

## Not exercised

- **`coder` is absent for the fourth consecutive trial.** This instrument reads; it does not build.
- **No fix was implemented or proposed to the subject beyond AEON-002.** The 173 divergent claims
  are a report, not a backlog.
- **The 64 unverifiable claims were not chased.** They are counted, not resolved, and the count is
  reported rather than folded into either column — absent is not zero.
- **No second run.** Every figure here is n=1 per subject; the *comparison* is n=2.

## Disputed

- **Whether Class A belongs to the reachability task or is its own.** Filed separately on the
  argument that the remedies differ and a merged report would misroute the fix. A reasonable reader
  could take it as one acceptance criterion on the existing task instead.
- **Whether 64 "unverifiable" is an instrument limit or a subject property.** Trial 1 did not report
  this category at all, so there is no baseline. Unresolved.

## Provenance of this document

Written from the subagent census at `aeonm/copy`, the spend rows in that copy's
`.project/events.ndjson` (re-derived here, not carried forward from the earlier reply), and
independent re-verification of the audit-sink enumeration against both aeon working copies. The
highper-gateway comparison figures are read from `2026-08-26-highper-gateway-reconciliation.md`
and its own recorded totals, not from memory of them.

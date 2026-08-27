---
id: T-20260827-a-feature-declared-but-enabled-by-no-bui
title: A feature declared but enabled by no build configuration is invisible to a call graph
epic: measurement
tier: T2
paths: tooling, docs/DESIGN-NOTES.md
state: created
---

## Intent

`T-20260826-reachability-of-a-declared-feature-is-me` asks whether a symbol has a production
caller. The 2026-08-27 aeon reconciliation found a class that question answers **correctly but
misleadingly**: code that has no caller because **it is not compiled into anything**.

Measured on that subject:

| what | evidence |
|---|---|
| `crates/aeon-state/src/l2.rs` — 646 lines, 17 tests | its `mmap` feature is enabled by **zero** `Cargo.toml` in the workspace |
| **all of `crates/aeon-cluster`** — Raft, QUIC, three-stage transfer, ~13.4 kLOC, **23 integration tests** | CI passes only `--features aeon-engine/rest-api`, which does not imply `cluster`; nor does `cargo build --release -p aeon-cli`. Only the Docker image contains it |
| `crates/aeon-crypto/src/fips.rs` | `fips` declared in exactly one manifest — its own |
| encryption-at-rest (`aeon-cluster/src/store.rs`) | `encryption-at-rest` enabled by nobody |
| Tier D E2E tests | `#[cfg(feature = "webtransport-host")]`, enabled nowhere; the non-feature twins are `#[ignore]` + `todo!()` |

The `aeon-cluster` row is the one that shows why this needs its own report line. **Twenty-three
integration tests that would substantiate a gate's acceptance criteria have no automated execution
path at all** — nothing runs them, nothing clippies them, and the roadmap marks the gate ✅. A
report saying "no production caller" points the reader at wiring. The actual remedy is a build
configuration, and the actual severity is that a test estate is silently inert.

## Why this is not a criterion on the reachability task

Two reasons, and the second is the load-bearing one.

1. **It is more mechanical, not less.** This is a set difference between features *declared* in
   manifests and features *enabled* by any build path — computable without parsing a line of
   source, and therefore cheaper and more reliable than a call graph. Making it a criterion on a
   call-graph task couples a cheap deterministic check to an expensive one.
2. **A call-graph tool cannot see it.** The analyser is run against a build. Code excluded from
   that build is not in its input at all, so it is not reported as unreachable — it is reported as
   nothing. The absence is invisible unless something reads the manifests directly.

This is disputed and recorded as such in `docs/TRIALS/2026-08-27-aeon-reconciliation.md`: a
reasonable reader could fold it into the other task. The argument for separating is above.

## Acceptance criteria

- [ ] The kit can report **features/flags/profiles declared in build manifests that no build path
      enables** — where "build path" includes CI configuration, release build commands, and
      container image builds, each named as a distinct enabler so the report can say *"enabled only
      by the Docker image"* rather than a bare yes/no.
- [ ] **Test estates gated behind an unenabled flag are reported separately and prominently**, with
      a count. "23 tests are compiled by nothing" is a different sentence from "a module is compiled
      by nothing" and the first is the one a gate reviewer needs.
- [ ] **Language-agnostic by delegation**, per the kit's boundary — the kit declares the check and
      consumes a documented output shape; it does not implement a manifest parser per ecosystem.
      The class generalises well beyond Cargo: Maven profiles, Gradle source sets, Go build tags,
      npm `optionalDependencies`, C preprocessor defines, `#if` in .NET, Bazel `select()`.
- [ ] A stack with no satisfying tool **declares it unavailable and raises the tier**, as
      `verify-ladder` already does. Silence is not a pass.
- [ ] Output feeds the census store from `T-20260826-a-verified-claim-about-the-tree-has-no-a`,
      not a second reporting path.
- [ ] **Unenabled is a candidate, not a verdict.** A feature deliberately off by default, a
      platform-specific arm, an opt-in extra for downstream consumers — all legitimate. The report
      says "enabled by no build path found", never "this is dead".
- [ ] Mutation proof: a fixture crate with a feature-gated module and no enabler is flagged;
      adding the feature to one build path clears it.

## Notes

The subject's own gate document was honest about part of this — roadmap line 1209 already admits
the `mmap` situation — while the ✅ beside the phase does not. That is another instance of
`T-20260826-two-artefacts-carrying-one-fact-with-not`, and it suggests the two checks should
report into the same place so a reader sees both halves at once.

Evidence: `docs/TRIALS/2026-08-27-aeon-reconciliation.md`, section *Class A*.

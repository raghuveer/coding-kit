---
id: T-20260826-reachability-of-a-declared-feature-is-me
title: Reachability of a declared feature is mechanically checkable and is not checked
epic: measurement
tier: T2
paths: tooling, docs/DESIGN-NOTES.md
state: created
---

## Intent

The dominant finding of the 2026-08-26 reconciliation was not documentation drift. It was this:

> **Twelve of sixteen use cases contain at least one subsystem that compiles, is unit-tested, and
> has zero production call sites. The roadmap consistently reads "the module exists" as "the
> feature works."**

Concretely, on that subject: four rate-limiting algorithms with no consumer; four authenticators
the gateway never calls; a complete disk cache backend while traffic gets an unbounded `DashMap`;
a CRL fetcher of 808 lines referenced by nothing; a discovery registry whose own source comments
admit it; `extract_client_ip` — an entire security fix — with zero callers.

**"Does this symbol have a caller outside its own module and its tests" is a grep-and-graph
question.** It is not a judgement call. It cost **17 subagents and ~6,547,551 BTE** to discover by
reading, and a mechanical pass would have flagged every candidate for a fraction of that, leaving
the agents to judge only the flagged ones.

The kit already computes something adjacent — `kit-index.sh` builds a co-change graph from history.
It has no notion of a **call** graph, or of an entry point.

## Why this belongs in the kit rather than in a linter

Rust has `dead_code`, and it did not catch any of this. Every one of those subsystems is `pub`,
re-exported, and covered by its own unit tests — so the compiler sees it used. **Reachability from
a production entry point is a different question from reachability from anywhere**, and it is the
one that matters when deciding whether a declared feature is real.

That question is also the one a brownfield census keeps asking. It is the mechanical half of
`T-20260826-no-agent-owns-verifying-documented-claim`.

## Acceptance criteria

- [ ] Given a declared entry point, the kit can report symbols that are **defined and exported but
      never reached** from it, excluding paths that only reach them through `#[cfg(test)]` or an
      `#[ignore]`d test. The test-only exclusion is the whole point — without it every one of the
      twelve findings is invisible.
- [ ] **Language-agnostic by delegation, per the kit's own boundary.** The kit declares and checks;
      it does not implement a call-graph analyser per language. The satisfying tool is declared in
      the profile the way `commands.*` already are, and the kit consumes a documented output shape.
      Candidate satisfiers, licences to be verified at adoption: `cargo-udeps` / `cargo-machete`
      for dependency reach, `rust-analyzer`'s call hierarchy, `callgraph`/`pycg` for Python, or a
      per-stack accelerator recipe.
- [ ] A stack with no such tool **declares it unavailable and raises the tier**, exactly as
      `verify-ladder` already does for rungs 3 and 5. Silence is not a pass.
- [ ] Output feeds the census store from
      `T-20260826-a-verified-claim-about-the-tree-has-no-a` rather than a second reporting path.
- [ ] **Unreachable is a candidate, not a verdict.** Deliberate dead code exists — a re-export for
      downstream consumers, a platform-gated arm, a public API of a library crate. The report must
      say "no production caller found", never "this is dead", and the judgement stays with a human
      or an agent that reads it.
- [ ] Mutation proof: a fixture with a symbol reachable only from a test is flagged; wiring one
      production call site clears it.

## Notes

**The economics are the argument, and they are measured rather than asserted.** 6.5M BTE bought
303 verdicts across 16 use cases. The reachability subset of that work — roughly the twelve
findings above — is the part a tool could have produced for near-zero tokens, leaving the agents
the part that needs reading. That is the same argument
`T-20260825-a-security-rung-on-the-ladder-satisfied-` makes for SAST: every mechanical finding an
LLM produces is spend on something a scanner does free.

**Do not build a call-graph analyser.** The moment this task starts implementing per-language
analysis it has left the kit's scope, which is the boundary `T-20260808-make-the-security-assurance-cadence-a-po`
draws for SCA/SAST/DAST in the same words: *declare and check, never perform.*

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 5.

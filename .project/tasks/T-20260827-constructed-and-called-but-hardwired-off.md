---
id: T-20260827-constructed-and-called-but-hardwired-off
title: Constructed and called but hardwired off is the blind spot reachability analysis cannot see
epic: measurement
tier: T2
paths: tooling, agents, docs/DESIGN-NOTES.md
blocked_by: T-20260826-no-agent-owns-verifying-documented-claim,T-20260826-a-verified-claim-about-the-tree-has-no-a
 created
---

## Intent

The kit now has two filed mechanical checks for declared-but-not-real features: no production
caller (`T-20260826-reachability-of-a-declared-feature-is-me`) and compiled by no build path
(`T-20260827-a-feature-declared-but-enabled-by-no-bui`). The 2026-08-27 aeon reconciliation found a
third state that **both of them clear**.

The symbol has a production call site. The call graph reaches it. `dead_code` sees it used. Every
functional test passes. **And the argument passed at that call site is a constant that disables the
feature.**

Measured on that subject:

| site | constant | consequence |
|---|---|---|
| `crates/aeon-cli/src/main.rs:1264` | `authenticator: None` | **the shipped REST API is always unauthenticated**; the binary logs `auth DISABLED` and passes every request. Roadmap: "REST API auth wiring ✅, Bearer middleware" |
| `set_audit_sink` never called outside `mod tests` | global stays `NullAuditSink` | **13 emit sites across 5 crates discarded, five of them authentication rejections.** Independently re-verified and filed with the subject as AEON-002 |
| every production spawn | `ledger = None` | checkpoints persist with empty `source_offsets` and `pending_event_ids`; `load_recovery_plan` is never called from the production runner. Crash recovery is fully written and cannot restore a position |
| REST processor host | `ws_host: None` | `/processors/connect` returns 503 in every build |
| pipeline config | nothing writes `PipelineConfig.delivery.strategy` | the engine always takes the blocking `OrderedBatch` path whatever the manifest says |

**Both of that subject's security findings are in this class.** A reachability pass built exactly to
the acceptance criteria currently filed would have reported neither. That is the argument for this
task: the two existing checks are worth building and would have missed the findings that mattered
most.

## Why this is hard, stated honestly

The other two checks are set differences. This one is not — it is dataflow. "Is this argument
always a disabling constant on every production path" is a real static-analysis question, and the
kit is not going to implement it.

So the honest framing is that this is **partly mechanical and partly a prompt**:

- The **mechanical half** is cheap and worth having on its own: find call sites where a parameter
  typed `Option<T>`, a trait object, a sink, a provider, or a handler is passed a literal `None` /
  `null` / `NullXxx` / no-op implementation, and where **no other production call site passes
  anything else**. That is a grep plus a uniqueness test, not a solver. It over-reports, which is
  fine — every candidate goes to a reader.
- The **judgement half** belongs to whichever agent owns claim verification
  (`T-20260826-no-agent-owns-verifying-documented-claim`). Its brief must include the question
  *"is this capability switched on anywhere a shipped artefact reaches"*, because reading a module
  and finding it correct is what produced the ✅ in the first place.

## Acceptance criteria

- [ ] The claim-verification brief explicitly asks, for every capability claimed working:
      **is it enabled on a path a shipped artefact takes**, not merely present and called. Wording
      to name the three states — no caller, not compiled, called-but-disabled — so a verifier
      cannot satisfy the question by finding a call site.
- [ ] A mechanical candidate pass exists for the narrow case: an injection point that is passed a
      null/no-op/`None` value at **every** production call site while a non-null alternative exists
      in the codebase. Over-reporting is acceptable and must be stated in the output.
- [ ] **Security-relevant injection points are ranked first** in that output — authenticators,
      authorizers, audit sinks, TLS verifiers, key providers, rate limiters. This is where the class
      concentrates, on the one subject measured.
- [ ] Output feeds the census store from `T-20260826-a-verified-claim-about-the-tree-has-no-a`.
- [ ] **Candidate, not verdict** — a deliberately optional dependency, a feature genuinely
      off-by-default with a documented enabler, and a test seam are all legitimate. The report says
      "no production call site supplies a non-null value", never "this is disabled by mistake".
- [ ] Mutation proof: a fixture wiring an authenticator as `None` at its only construction site is
      flagged; supplying a real one clears it.

## Notes

The generalisation worth writing into DESIGN-NOTES: **a control that is present, called, and
disabled passes every test a control that works would pass.** This is the same shape as
`a-control-needs-a-check-that-can-fail` — a green signal that cannot go red — arriving from the
opposite direction. There the check could not fail; here the control cannot act, and the check
was never asked to notice.

Evidence: `docs/TRIALS/2026-08-27-aeon-reconciliation.md`, section *Class B*; subject finding
AEON-002 (`59a9d66` on `aeon-rust/aeon`, `86bab68` on `v0.2-canonical`).

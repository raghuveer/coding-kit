---
id: T-20260825-a-security-rung-on-the-ladder-satisfied-
title: A security rung on the ladder satisfied by configurable tools
epic: validation
tier: T3
paths: skills/verify-ladder/SKILL.md, templates/project-profile.md, docs/ADAPTERS.md, tooling/kit-status.sh
blocked_by: T-20260808-make-the-security-assurance-cadence-a-po
state: created
---

## Intent

The verification ladder's deterministic rungs stop at correctness. `commands.build`,
`commands.test`, `commands.lint` and `commands.typecheck` are declared per project and run
against the adopting repository — so the claim "the kit performs no deterministic analysis on
your product" is **false**, and was withdrawn on 2026-08-25 after being made in this session.

What is true is narrower and more actionable: **security has vocabulary but no rung.** There is
no `security.sast`, no `security.sca`, no `security.dast`. `agents/security-reviewer.md` names
those layers in prose and delegates to them, and nothing invokes them, declares them, or notices
their absence.

The consequence is an economic one, which is the argument for fixing it in a kit whose whole
position is spending tokens deliberately. Every mechanical finding an LLM reviewer produces — an
injection sink, a hardcoded secret — is opus tokens spent on work a scanner does for free. The
reviewer already knows this and says so in its Boundary section. It just has nothing to delegate
*to*.

## Why this is a rung and not a new mechanism

Two existing contracts already have the right shape, and this task should invent neither:

1. **`verify-ladder` already has the rule.** A rung with no satisfaction declared for this stack
   is **declared unavailable, its compensating control named, and the tier RAISED by one**. That
   is exactly the correct behaviour for "this team has no DAST" — the bar goes up rather than the
   obligation quietly disappearing. Applying it to security needs no new concept.
2. **`docs/ADAPTERS.md` already establishes pluggable executables.** `ingest.tasks` takes
   `files | none | <path to executable>`. A security-tool adapter is that same contract aimed at
   a different category.

**The kit ships adapters and a contract. It never ships a scanner.** That keeps
`T-20260808`'s line intact — *the kit declares and checks the scope; it does not perform SCA,
SAST, DAST or VAPT, and must not grow toward doing so.* This task is the **invoke** half;
`T-20260808` is the **declare, record and report** half, which is why it blocks this one.

## Acceptance criteria

- [ ] Security rungs are declarable per project in the same flat `key: value` shape as
      `commands.*`, covering at least SAST, SCA/SBOM and DAST. A layer the project does not run
      is **declared absent**, never left blank.
- [ ] An undeclared security rung **raises the tier**, by the same rule and the same words
      `verify-ladder` already uses for rungs 3 and 5. Not a warning, not a lower bar.
- [ ] **At least two supported tools per category are documented**, so an organisation installs
      what it already has rather than what the kit prefers. The kit is open source and cannot
      bundle scanners; it also must not pick one. Candidates verified for licence at adoption
      time, not taken from this file:
      SAST — Semgrep, or per-stack Bandit / gosec / Brakeman;
      SCA+SBOM — Trivy, or Syft+Grype, or OSV-Scanner;
      DAST — OWASP ZAP, or Nuclei;
      secrets — Gitleaks.
- [ ] Adding support for a tool the kit has never heard of requires **no change to the kit** —
      it is a declared executable honouring the adapter contract. If a new tool needs a code
      change, the contract is wrong.
- [ ] **CLI is the default integration and MCP is the exception, with the reason recorded.** A
      scanner is run-once-parse-output: it has no resident cost, and its findings cost zero model
      tokens to PRODUCE, only to interpret. MCP is justified only where a tool needs iterative
      querying. This is consistent with the zero-MCP position, which was always about resident
      cost rather than hostility to MCP — see the README's corrected note on deferred schemas.
- [ ] Scanner output reaches the record through `kit-finding.sh`'s existing contract, so a
      scanner finding and a reviewer finding are the same kind of row and can be counted
      together. No second findings path.
- [ ] A scanner that is declared but **fails to run** is distinguishable from one that ran and
      found nothing. Silence is not a pass — this is the same distinction `T-20260808` requires
      between "never ran" and "ran, found nothing".
- [ ] Mutation proof: a project declaring a security rung it does not satisfy has its tier
      raised, demonstrated by a conformance step that goes red when the rule is removed.

## Notes

**Token efficiency is the point, not a side benefit.** Measured 2026-08-17 on one T3 change, the
security review cost **134,882 tokens**. A scanner sweep for the mechanical subset of that costs
none. The reviewer's job then narrows to what a checklist cannot anticipate, which is what
`T-20260819` argues for from the design-input side.

**Do not let this grow into a security programme.** The tell would be the kit gaining opinions
about scanner configuration, rule sets, or severity thresholds. Those are project decisions and
belong in the overlay and in accelerators — a technology accelerator is where "this stack's SAST
is X, invoked thus" lives, and an industry accelerator is where "this vertical mandates SBOM at
release" lives. See `docs/DESIGN-NOTES.md` §2 and the withdrawal of §8.4: non-functional criteria
are overlay and ADR content, not kit capability.

**T3 because it changes the profile schema**, which the versioning table treats as the hardest
surface to move. Worth challenging: if the keys are additive with safe defaults — as
`git.require_signoff` was in 0.11.0 — the migration cost may be nil and T2 may be right.

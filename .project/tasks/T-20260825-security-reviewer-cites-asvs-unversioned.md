---
id: T-20260825-security-reviewer-cites-asvs-unversioned
title: security-reviewer cites ASVS unversioned and has no business-logic dimension
epic: agent-contracts
tier: T2
lang: markdown
paths: agents/security-reviewer.md
state: created
---

## Intent

Four defects in one file, found by reading `agents/security-reviewer.md` end to end on
2026-08-25 while comparing the kit against Sonar's Hunter agent. They are grouped because they
are one review pass over one 131-line file, not because they share a cause.

**1. ASVS is cited without a version, while the LLM list is versioned.** Line 20 reads
`**OWASP ASVS** V2 / V3 / V4 / V6 / V7`; line 21 reads `**OWASP LLM Top 10 (2025)**`. Chapter
numbers only mean something against an edition, and ASVS has been restructured across major
versions. A reviewer working from a different edition cites wrong chapters while looking
perfectly correct — and the stated purpose of citing at all is that a finding "speaks the
language a VAPT vendor or enterprise security team expects", which a wrong chapter actively
defeats. The file already knows to pin an edition; it does it once and not twice.

**2. There is no business-logic dimension.** The five dimensions are auth/authz, service
boundary, crypto/secrets, content/sensitive-data, and data integrity. Dimension 5 covers
quota/limit/velocity **races** very well — the check-then-act-across-an-await shape is named
precisely and is the best thing in the file. What no dimension covers is **workflow-step
ordering** and **replay / idempotency**: a payment submitted twice, or a workflow whose step 3
is reachable without step 2. Both pass all five dimensions today.

This is the one place the Sonar comparison produced a finding rather than a theme. Hunter's
three published categories are broken access control, business-logic flaws, and
authentication/sessions. Two of the three this agent covers well. The third it does not cover
at all, and reading our own dimensions would never have surfaced that — it took an external
taxonomy to see the hole.

**3. The producer is never told where the declared industry lives.** The Output section says
`domain` "is dropped unless this project declared it, so leave that blank too unless you know
it". Nothing tells the agent that the answer is derivable from `accelerator.industry` in the
profile it has already been instructed to read — `kit-finding.sh:168 declared_industries()`
strips the path and the `.md` to get `bfsi`. So the safe default is blank, and blank starves
the industry-accelerator axis. **The recorder's mechanism is sound and must not be changed**:
accepting a domain only where an accelerator was imported is what stopped reviewers inventing
verticals. Only the instruction at the producing end is missing.

**4. `tools: Read, Grep, Glob` reads as enforcement.** It is a declaration, not a boundary —
verified false on 2026-08-15, and `SECURITY.md` §3 and `docs/agents-README.md` both now say so.
This file does not, and it is the file an operator reads when deciding whether to trust an
**adversarial** reviewer with repository access.

## Acceptance criteria

- [ ] The ASVS citation names an edition, in the same shape the LLM Top 10 already does. If the
      chapter numbers move between editions, the mapping in the file is corrected to the edition
      named — do not pin the edition to whatever makes the current numbers right.
- [ ] A business-logic dimension exists covering at least **workflow-step ordering** and
      **replay / idempotency**, with the same concreteness as dimension 5's check-then-act
      shape. A dimension that says "check the business logic" is not this criterion.
- [ ] The dimension cites its ASVS chapter, per criterion 1.
- [ ] The Output section tells the agent to read the declared industry from
      `accelerator.industry` and use it, and to leave `domain` blank only when the project
      declared none. `kit-finding.sh` is NOT changed.
- [ ] The file carries the `tools:`-is-a-declaration caveat, pointing at `SECURITY.md` §3
      rather than restating it.
- [ ] `tests/conformance.sh` still passes, in particular the step asserting the agent's inlined
      vocabulary matches `kit-finding.sh --vocab`.

## Notes

**Checked in the same pass and found CORRECT — recorded so nobody re-raises them:**

- `model: opus` is right. `docs/MODELS.md` mandates the alias and forbids only a full model ID
  (`model: claude-opus-4-8`). This was nearly filed as a defect.
- The `domain` gating mechanism is elegant, not broken — see defect 3.
- JSON-not-prose output, the HALT verdict and its asymmetry argument, "do not accept a safety
  argument written in a comment as evidence", and emitting `findings: []` as a measurement are
  all strong and should not be touched by this task.

**Out of scope, deliberately.** Supply-chain integrity (signing, provenance, attestation —
Sigstore/SLSA/in-toto) is absent from the Boundary table, which stops at SCA/SBOM. SBOM answers
*what is in it*; it does not answer *is this the artefact we built*. That belongs as a row on
`T-20260808-make-the-security-assurance-cadence-a-po`'s delegation table, not here — this task
does not touch the cadence.

Found 2026-08-25 by reading the file, not by a check. Nothing tests the content of an agent
contract, which is a larger problem this task does not solve.

---
id: T-20260826-a-verified-claim-about-the-tree-has-no-a
title: A verified claim about the tree has no artefact so a census cannot be recorded
epic: reporting
tier: T2
paths: tooling/schema.sql, tooling/kit-finding.sh, tooling/kit-status.sh
state: created
---

## Intent

Measured on 2026-08-26 during the highper-gateway reconciliation: **303 claims were verified
against the tree and none of them are in the kit.**

The run produced, per use case, a set of assertions extracted from a roadmap, each checked against
the source and classified `CONFIRMED / STALE-CITATION / OVERSTATED / UNDERSTATED / UNVERIFIABLE`
with evidence. That is 303 durable, re-checkable facts about a real codebase. **They came back as
prose in a subagent's reply**, were pasted into a markdown file, and are now unqueryable. Only the
18 rows the two reviewers emitted reached the `finding` table, because `kit-finding.sh` is the
only structured intake the kit has.

So the most valuable artefact this kit has produced on a real subject cannot be counted, diffed,
re-checked on a later commit, or reported by `kit-status.sh`. A second reconciliation six months
from now could not tell you which verdicts changed.

**A finding is not the right shape for this and must not be stretched into one.** A finding says
*"this code is defective."* A census claim says *"this document asserts X; the tree says Y."* The
subject of a finding is code; the subject of a claim is a **claim**. Recording 303 roadmap
assertions as findings would flood the criticals gate with rows that are not defects and would
make `findings-outpace-dispositions` structurally unfixable.

## Acceptance criteria

- [ ] A claim is recordable with at least: the source document and where in it, the assertion in
      one line, the verdict from a closed vocabulary, the evidence path, and whether the location
      was RE-DERIVED or copied from the source document.
- [ ] The vocabulary has ONE home and is asserted against by `tests/conformance.sh`, exactly as
      the finding vocabulary is against `kit-finding.sh --vocab`. It drifted across four locations
      once already.
- [ ] **`UNVERIFIABLE` is a first-class verdict, not an absence.** The 2026-08-26 run needed it
      immediately: `src/ha` and `src/health` are described as "empty directories" and git cannot
      track an empty directory, so the claim cannot be checked from a clone. A schema that forces
      a true/false answer there manufactures a wrong one.
- [ ] Claims are **orthogonal to findings** and land in a separate table. A claim that leads to a
      defect may reference a finding; it must not become one.
- [ ] `kit-status.sh` reports the census: counts by verdict, and the **drift rate as a fraction
      with its denominator**. "37 of 112 stale" — never an adjective.
- [ ] Re-running a census on a later commit produces a **comparable** result: which verdicts
      changed, which claims are new, which disappeared. If two censuses cannot be diffed, this
      task has not been done — that is the whole point of recording them.
- [ ] Mutation proof: a claim recorded with an invalid verdict is rejected, and the batch records
      nothing, matching `kit-finding.sh`'s all-or-nothing rule.

## Notes

**Do not design this before `T-20260826-no-agent-owns-verifying-documented-claim`.** That task
decides who produces claims and in what shape; this one decides where they land. Building the
store first risks a schema fitted to one hand-written prompt rather than to a contract.

**The 2026-08-26 output is the test fixture.** 303 real claims across 16 use cases, with verdicts
and evidence, in `docs/RECONCILIATION-2026-08-26.md` in the trial copy. Any schema proposed here
should be able to hold that document losslessly. If it cannot, it is the wrong schema — and this
is a rare case where the requirement exists before the implementation and is already measured.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 1.

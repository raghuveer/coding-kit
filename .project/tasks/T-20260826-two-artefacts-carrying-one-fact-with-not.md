---
id: T-20260826-two-artefacts-carrying-one-fact-with-not
title: Two artefacts carrying one fact with nothing comparing them is a defect class
epic: validation
tier: T3
paths: validate.py, tests/conformance.sh, docs
state: created
---

## Intent

Six instances of the same defect were observed or confirmed in a single session, 2026-08-25 to
2026-08-26. They were filed, or fixed, as six separate things. **They are one class**, and naming
it is worth more than the six fixes.

The shape: **two artefacts each carry half of one fact, neither is wrong on its own, and nothing
compares them.** Every check in the repository stays green, because there is no artefact to point
at and say *this one is incorrect.*

| # | artefact A | artefact B | outcome |
|---|---|---|---|
| 1 | `plugin.json` `"license"` | the `LICENSE` text | **fixed** in 0.11.0 by `validate.py` |
| 2 | `MIGRATION.md` mapping rows | the skills they name | `T-20260825-two-migration-md-mapping-rows-record-cap` |
| 3 | `ENTRY-PROPOSAL.md` format section | its own validator's title charset | `T-20260825-the-entry-proposal-format-does-not-state` |
| 4 | profile template | `kit-accel.sh:41`'s repeatable keys | `T-20260825-the-profile-template-does-not-say-the-ac` |
| 5 | subject's `SECURITY.md` slowloris timeout | the code, which never reads it | subject defect, Tier 1 claim 3 |
| 6 | a 920-line roadmap | 291 source files | **129 of 303 claims fail** |

Instance 1 is the proof that a mechanism works: two files carried one fact, a check was written,
and four distinct failure modes became detectable. Instance 6 is the proof of scale: the same shape
across a whole project cost 17 subagents and ~6.5M BTE to surface by reading.

**The kit is itself an instance-generator.** It is a system whose product is *documents that
describe a repository*: profile, task files, ADRs, design inputs, INSTALL, MIGRATION, agent
contracts with inlined vocabularies. Every one of those is artefact A looking for its artefact B.
Six one-off checks will become twelve.

## Acceptance criteria

- [ ] The class is **named and written down** where a reader building the next check will meet it —
      most likely `docs/LESSONS.md` — with these six instances as evidence and instance 1 as the
      worked example.
- [ ] **A rule for deciding whether a given pair is mechanically checkable at all.** Instance 1 was
      (marker phrase in a file). Instance 6 was not — it needed judgement per claim. A class that
      does not distinguish these will produce a check that claims to verify a roadmap and cannot.
- [ ] At least one mechanism generalising over more than one instance, rather than a seventh
      bespoke check. Candidate shape: a declared pair — *this document asserts something about that
      artefact* — plus a per-pair comparator, so adding a pair is data rather than code.
- [ ] **What the mechanism CANNOT do is stated in the same place.** Existence of a named target is
      mechanical; equivalence of behaviour is not. `T-20260825-two-migration-md-mapping-rows-record-cap`
      already carries this limit for its own case and it generalises: a green existence check must
      never be read as the document being verified.
- [ ] Existing instances 2, 3 and 4 are re-examined against the mechanism. If it cannot express
      them, it is the wrong mechanism — those are its acceptance corpus and they exist already.
- [ ] Mutation proof: break one side of a declared pair and the check goes red.

## Notes

**T3 because it changes how the kit decides what to verify, not because the code is large.** The
smallest honest version — write the class down with its six instances and the checkability rule,
and adopt no mechanism at all — would be worth doing on its own and should be considered as the
first increment. A named class that stops the seventh bespoke check being written is most of the
value.

**Resist making this a documentation linter.** The kit's scope boundary is that it does not grow
opinions about a host project's content. This class is about **internal consistency between two
artefacts that already exist**, which is the same thing `validate.py`'s licence check does and the
same thing the security cadence task draws a line around. A generic "check the docs match the code"
feature would cross that line and must not be built here.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 4 — recorded there
as the strongest generalisation the trial produced.

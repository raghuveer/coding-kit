---
id: T-20260818-relicense-from-mit-to-apache-2-0-while-s
title: Relicense from MIT to Apache 2.0 while sole authorship still makes it clean
epic: components
tier: T1
state: open
---

## Intent

The kit is positioned as an end product used in client engagements. Apache 2.0 adds two things MIT
lacks that matter for that: an **express patent grant** from contributors, and a **NOTICE**
mechanism for attribution. It stays permissive, so downstream users may build open-source *or*
proprietary software on it in any domain — which is the operator's stated requirement.

**Do it now, because the cost only rises.** Verified 2026-08-18: every commit is authored by one
person (`Raghu Veer Dendukuri` / `Raghuveer Dendukuri`, same address), the repository has **0 forks
and 1 star**, and it is not itself a fork. Sole copyright means relicensing is a decision rather
than a permissions exercise. Once outside contributions land, each contributor's agreement is
needed for their part or it stays MIT.

The surface is small. Verified: the only machine-readable declaration is
`.claude-plugin/plugin.json:7` (`"license": "MIT"`), plus the `LICENSE` file. There is **no
`NOTICE`**, and neither `validate.py` nor `tests/conformance.sh` asserts anything about the licence
— so nothing breaks and, equally, nothing would catch a half-done change.

## Acceptance criteria

- [ ] `LICENSE` replaced with the full, unmodified Apache License 2.0 text, and the copyright line
      carried over.
- [ ] A `NOTICE` file exists. Apache 2.0's attribution mechanism only works if it does, and adding
      it later means downstream copies exist without it.
- [ ] `.claude-plugin/plugin.json` `"license"` reads `Apache-2.0` — the SPDX identifier, not prose.
- [ ] The README states the licence and the change, so a reader who saw the MIT version is not left
      guessing which applies to the copy they hold.
- [ ] **Inbound contribution terms are decided and written down.** Recommendation: a **DCO**
      (`Signed-off-by`) rather than a CLA — provenance without the administrative weight of
      collecting agreements from individuals. Apache 2.0 §5 already licenses inbound contributions
      under the same terms by default; the DCO records that the contributor had the right to send
      them.
- [ ] A check exists that the declared licence and the `LICENSE` file agree. Nothing asserts this
      today, which is exactly how a half-finished relicense survives — `plugin.json` saying one
      thing and the file saying another is the two-sources-of-truth shape this repository keeps
      paying for.

## Notes — the operator's, and the part no code change settles

**A licence governs what downstream users may do. It does not establish who owns the copyright,
and you cannot licence what you do not own.** If an employment agreement assigns IP created during
employment — some are drafted broadly enough to reach personal time, personal equipment, or merely
the employer's field of business — then rights may sit elsewhere regardless of what `LICENSE`
contains. Apache 2.0 does not settle that question; it assumes the answer.

Jurisdiction- and contract-specific, and outside what this task can resolve. The operator's own
sequence, recorded here so it is not lost:

1. read the IP / inventions clause of any current or prospective employment agreement
2. where an OSS-contribution policy exists, use it and obtain the waiver **in writing**, naming
   this project
3. do it **before** it matters — a written acknowledgement while nobody cares is routine; the same
   request after the project has visibility is a negotiation

The commit history is clean single-author evidence, which is the one part already in good shape.

### Operator determination, 2026-08-25 — this point is CLOSED

The operator's position, recorded verbatim as theirs: *work done at work belongs to the
employer; open source work done otherwise should not be an issue for the employing
organisation.* On that basis the operator considers the question settled and the item closed.

Recorded as the operator's determination. **The kit verifies nothing here and has no mechanism
that could** — nothing in it reads employment terms, records who owns a piece of work, or checks
the licence of an adopting project. An earlier draft of this note said "not a finding this kit
verified", which wrongly implied such a category exists and was withdrawn.

The usage this settles, stated by the operator: the kit is their personal open source work; they
may use it to build open source solutions and equally to build work implementations at work;
others may use it too. **Apache 2.0 already permits exactly that** — that is what a permissive
licence is for, and no verification is involved. The kit is a tool, and using an Apache-2.0 tool
at work raises no question about the tool: whatever is built with it belongs to whoever the
employment terms say, and the kit's own licence is untouched either way.

**And the kit has no reach-through to what anyone builds with it, by licence or by feature.**
Apache 2.0 §2 grants rights in the Work and in Derivative Works; a project built *using* the kit
is neither — it is output produced with a tool, as a compiled binary is not a derivative of the
compiler. There is no copyleft here and none is wanted. The operator's framing, 2026-08-25: the
user deploys their own tooling, supplies the thinking, validates the outcome, and owns the
result; neither the LLMs nor the coding agents in that loop define a licence on generated code,
and the kit — which does not even generate, only manages state and routes reviews — has less
standing than either.

**Consequence for scope, recorded because it will be proposed again:** a check on an adopting
project's own licence declaration is NOT kit capability. It is a lint, lint is `commands.lint`,
and that is the adopter's tooling declared by the adopter — the same boundary
`T-20260808-make-the-security-assurance-cadence-a-po` draws for SAST and SBOM. Such a check was
floated on 2026-08-25 and withdrawn on these grounds. The only licence opinion the kit is
entitled to is whether its OWN two files agree with each other, which `validate.py` now holds.

The three-step sequence above stays in the record as what was recommended. The agent raised the
caveat on 2026-08-18 and again on 2026-08-25; it was considered and decided. Nothing further is
outstanding on this task's behalf.

**Known trade, accepted:** Apache 2.0 does not stop anyone else offering deployment or training
services around this kit either. Preventing that needs a source-available licence, which
contradicts both "usable in proprietary software" and "lets others contribute". The permissive
choice is deliberate.

Filed 2026-08-18. Related: a rename to a generic, agent-neutral identity is a **separate** decision
and deliberately not bundled here — the name should follow from what the kit proves to be in its
first trial, and renaming twice is the avoidable cost.

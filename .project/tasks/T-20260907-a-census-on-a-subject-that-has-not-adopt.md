---
id: T-20260907-a-census-on-a-subject-that-has-not-adopt
title: A census on a subject that has not adopted the kit must refuse and name adoption as the step
epic: reporting
tier: T2
lang: bash
blocked_by: T-20260826-a-verified-claim-about-the-tree-has-no-a
paths: tooling/kit-claim.sh, tooling/kit-lib.sh, tests/conformance.sh
state: created
---

## Intent

D4 scopes a census by **purpose**: project-scoped by default, kit repo when the subject is being
used to evaluate the kit. Working the rule through against adoption produced four cases, and the
fourth had no home:

| subject | adopted the kit? | used to evaluate the kit? | census lives in |
|---|---|---|---|
| highper-gateway, aeon | no | yes | kit repo, marked foreign |
| an adopter auditing its own project | yes | no | subject's `.project/census/` |
| an adopted repo later used as an evaluation subject | yes | yes | kit repo, marked foreign |
| **a non-adopted repo audited for its own sake** | **no** | **no** | **this task** |

It has no `.project/` to write to and no evaluation purpose to justify the kit repo. Left
unhandled it becomes a silent misfile: the plausible-looking fallback is the kit repo, which would
put a third party's claims in this repository under no rule that authorises it.

## The operator's decision, recorded as his

> In "a non-adopted repo audited for its own sake" scenario, the subject must adopt the kit first
> and census to be write in subject repo as kit state.

Stated 2026-09-07. So the fourth row is **not** a new storage location. It resolves into the second
row by requiring adoption first, and the census then lands in the subject's own
`.project/census/` like any other kit state.

This is consistent with the rule the kit already enforces everywhere else — `kit_active()` is
`[ -f "$(kit_profile "$1")" ]` and every script refuses when it is false, because the kit does not
create state in a repository that did not opt in. A census is kit state and gets no exemption.

## What this task is, and is not

**It is not a storage decision** — that is settled above. It is the **control that makes the
decision hold**, and the reason it is a task rather than a paragraph is that a rule with no
mechanism is a convention. `SECURITY.md` and this backlog both already carry the lesson that a
control which cannot fail is not a control.

Concretely: census intake must **refuse** a subject with no profile, and the refusal must name
adoption as the step rather than leaving the operator to infer it. The failure to avoid is not a
crash — it is intake choosing a plausible directory and succeeding.

## Acceptance criteria

- [ ] Census intake against a subject where `kit_active` is false is **refused**, non-zero, with no
      artefact written anywhere — not in the subject, not in the kit repo, not partially.
- [ ] The refusal names the remedy: run `kit-init.sh` in the subject, then re-run the census. A
      refusal that says only "not adopted" reproduces the gap in a different place.
- [ ] **The refusal does not fire on the evaluation path.** A subject declared as being used to
      evaluate the kit is the first row and is legitimately non-adopted; it must still record, to
      the kit repo, marked foreign. This is the case the check will break if it is written as a
      bare `kit_active` guard, and it is the whole reason D4 keys on purpose rather than adoption.
- [ ] After adoption, the same census records to the subject's `.project/census/` — proving the
      fourth row resolves into the second rather than into a special case.
- [ ] Mutation proof: with the refusal removed, a census on a non-adopted, non-evaluation subject
      writes an artefact, and conformance goes red. A check that passes with the control deleted
      is measuring nothing.
- [ ] Conformance covers all four rows of the table, not only the refusal. Three of them must
      still succeed, and a test suite that only proves the refusal will not notice when the
      refusal starts firing on the evaluation path.

## Why it is blocked

Intake does not exist yet. `tooling/kit-claim.sh` is the vocabulary home only and says so in its
own header: *"THIS SCRIPT DOES NOT YET RECORD ANYTHING, AND THAT IS DELIBERATE."* The store —
table, intake, reporting, diffing — is `T-20260826-a-verified-claim-about-the-tree-has-no-a`.
There is nothing to add a refusal to until that lands, and when it does, this extends
`kit-claim.sh` rather than adding a second door, exactly as `kit-finding.sh` holds both its
vocabulary and its intake.

## Notes

Filed 2026-09-07 on the operator's instruction, from the D4 correction in
`docs/design-input/2026-08-27-census-store.md`. The gap was surfaced by his rewording of D4: the
agent's draft keyed the fallback on adoption and covered this row **by accident**, sending it to
the kit repo. His purpose-based rule is correct and declines to cover it, which is what made the
gap visible at all.

Purpose is declared, not derived — nothing in the tree can compute whether a subject is being used
to evaluate the kit — so the third acceptance criterion depends on that declaration existing in the
manifest. If task A ships without it, this task cannot distinguish row one from row four and must
say so rather than guessing.

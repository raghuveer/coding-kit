---
id: T-20260825-the-profile-template-does-not-say-the-ac
title: The profile template does not say the accelerator keys are repeatable
epic: accelerators
tier: T3
paths: templates/project-profile.md
state: created
---

## Intent

K-6 of the highper-gateway trial, 2026-08-24.

`accelerator.technology`, `accelerator.industry` and `accelerator.pattern` **are repeatable**.
The code says so in three places — `tooling/kit-accel.sh:41` states it, `kit_cfg_all` reads them
that way at `:45`, and `kit-finding.sh:167` derives the permitted `domain` list by reading every
`accelerator.industry` value.

`templates/project-profile.md` — the file an adopter actually fills in — **never says so.** The
only key marked repeatable there is `ingest.extra`. So the adopter's reasonable reading is one
value per axis, and one value per axis is what they write.

**This bites precisely on the polyglot case**, which is the case the kit is least tested on. A
Rust workspace with a Python tooling directory and a TypeScript dashboard needs three technology
accelerators. An adopter following the template writes one, and the other two stacks silently
get no accelerator at all — no failure, no warning, just less context than the mechanism was
built to supply.

It also silently narrows `domain`: `kit-finding.sh` permits an industry only where an
accelerator for it was imported, so an adopter who could have declared two verticals declares
one, and findings in the other are dropped by a rule they never knew applied.

## Acceptance criteria

- [ ] The template marks all three accelerator keys repeatable, in the same way `ingest.extra`
      is marked, so the notation is one convention rather than two.
- [ ] The template shows a **multi-value example** rather than only saying "repeatable" — the
      polyglot case is the one that needs it, and a single commented line does not demonstrate
      what two look like.
- [ ] The consequence of declaring one is stated where the key is: stacks without an accelerator
      get none, silently. An adopter should not have to infer that from absence.
- [ ] A check that every key the code reads with `kit_cfg_all` is marked repeatable in the
      template. That is mechanical, it generalises beyond these three, and it is what stops the
      next repeatable key shipping undocumented.
- [ ] Mutation proof: unmark one and the check goes red.

## Notes

**T3 rather than T2, and the reason is the blast radius of the check, not of the text.** Editing
the template is trivial. The fifth criterion reaches into how the profile schema is documented
and touches every key the kit reads repeatably — and this repository's own versioning table
treats profile frontmatter keys as its hardest surface. Worth challenging at planning time: if
the check is scoped to reading `kit_cfg_all` call sites and comparing against the template, the
change may be additive enough for T2.

**Do not fix this by making the keys non-repeatable.** They are repeatable on purpose and three
call sites depend on it; the defect is entirely that the adopter-facing file does not say so.

Reproduced 2026-08-24 during the highper-gateway trial; see
`docs/TRIALS/2026-08-24-highper-gateway.md` K-6.

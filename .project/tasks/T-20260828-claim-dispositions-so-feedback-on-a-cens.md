---
id: T-20260828-claim-dispositions-so-feedback-on-a-cens
title: Claim dispositions so feedback on a census is data and a discard is a recorded act
epic: reporting
tier: T3
paths: tooling/kit-claim.sh, tooling/kit_claims.py, tooling/kit-index.sh, tooling/schema.sql, tooling/kit-status.sh, docs/adr
blocked_by: T-20260826-a-verified-claim-about-the-tree-has-no-a
state: created
---

## Intent

**Task B of a three-way split**, made on 2026-08-28 after a second approach review returned REVISE
and recommended it. A: the store. **B: this.** C:
`T-20260828-census-diff-and-the-attribution-control-`.

The reviewer's argument for splitting, which the operator accepted: landing all three together
risks AC6 — *the criterion the parent task itself calls the whole point* — being the part that gets
cut when the rest runs long.

## The operator's requirement, recorded as his

> Once we have findings as data, data can be shown and opinions & inputs and feedback can be shared
> and logged on specific points of importance and false positives or less important ones, may be
> discarded if chosen, **that can be recorded as so**. Overall, the design can happen with clear
> consideration and in future, when more developers intend to contribute, **they will have history
> clearly**.

A disposition is therefore not metadata. It is **content** — of the census summary, and of the
discovery-session document in `T-20260827-discovery-is-a-multi-session-phase-with-`, which combines
code evaluation with *user inputs and decisions made*. A claim, its verdict, its evidence, its
disposition and that disposition's **reason** must be retrievable together.

## Proposed vocabulary — a proposal, not a decision

| disposition | meaning |
|---|---|
| `accepted` | the claim stands; real and worth acting on |
| `false-positive` | the audit was wrong about the tree — a finding about the auditor, not the subject |
| `low-value` | true but not worth acting on, with the reason |
| `actioned` | a task or finding was raised from it |
| `deferred` | real, not now, with the reason |

**Operator-only**, for the same reason `--fixed` is: a session certifying its own output is the one
signature that carries no information. Every disposition carries a required reason. An
undispositioned claim is **neither accepted nor discarded** and is reported as a standing count,
never folded into zero.

## The blocking problem this task must solve first

**A second approach review found that dispositions falsify the parent design's central argument.**
That architecture rests on *"the committed artefact freezes nothing, so re-keying stays free
forever."* A `claim-disposition` event must name the claim it disposes of — so the first
disposition written freezes `claim_key` in the append-only committed log, exactly as the rejected
revision-1 design would have.

**Do not begin this task by writing the event format.** Begin by resolving that contradiction:
either accept the freeze and re-cost the parent's argument honestly, or key dispositions to
something artefact-derived and content-stable.

**ADR 0006 governs this and was never opened.** It decides a disposition needs assent *and*
evidence re-established at every rebuild, and it **rejects** option A1 — store the citation, check
it once — because *"storing a claim that nothing re-establishes means the record can assert a
present fact that stopped being true."* The proposed `actioned` (carrying a task/finding id) and
the parent's `claim.finding_id` are A1 verbatim. **Read ADR 0006 before designing; this task is a
conversation with it, not around it.**

## Acceptance criteria

- [ ] The freeze contradiction above is resolved **in writing** before any format is chosen, and
      the parent design's argument is corrected to match whichever way it resolves.
- [ ] ADR 0006 is engaged explicitly: either this follows its A2-style re-establishment, or an ADR
      records why A1 is acceptable here when it was rejected there.
- [ ] Dispositions are **operator-only** and an agent proposing one in its summary is the intended
      path. Stated as the convention it is, not claimed as a boundary the kit enforces.
- [ ] Every disposition carries a **required reason**. A mark that clears anything without saying
      why is the laundering the mark exists to prevent.
- [ ] A disposition naming an **unknown claim is refused**, as `kit-resolve.sh:175-179` refuses an
      unknown finding id — and orphaned dispositions are counted and reported, as
      `finding_orphan_marks` is. A unit re-run overwrites its artefact, so orphaning is not
      hypothetical.
- [ ] The disposition vocabulary has ONE home in `kit-claim.sh --vocab` **and a drift check that
      can fail.** `conformance.sh:224-261` only compares `--vocab` against agent files, and
      dispositions appear in no agent — so that guard would match nothing and pass. Its own comment
      forbids exactly this: *"A LOOP THAT MATCHES NOTHING MUST NOT PASS."*
- [ ] Claim, verdict, evidence, disposition and reason are retrievable **together**, per the
      operator's requirement above.
- [ ] `kit-status.sh` reports the undispositioned count as a standing figure.
- [ ] The event-volume cost is stated: one disposition per claim over a 489-claim census is ~490
      lines, ~190KB against a 245KB log.
- [ ] Mutation proof: an invalid disposition is refused and records nothing; a disposition with no
      reason is refused; a disposition naming an unknown claim is refused and counted.

## Findings inherited from the parent

Recorded against `T-20260826-a-verified-claim-about-the-tree-has-no-a`, applying here:

| id | severity | what |
|---|---|---|
| `…:b03` | critical | re-keying-free is falsified by dispositions — **shared with A, and blocking for both** |
| `…:79b` | major | this is ADR 0006's rejected option A1 |
| `…:1ab` | major | two ingestion sources; a re-run orphans dispositions silently |
| `…:df1` | major | `events.ndjson` does grow per claim, via dispositions |
| `…:1bf` | major | the disposition vocabulary gets no drift check |
| `…:92d` | major | `claim.finding_id` has no source |
| `…:af2` | minor | AC4's second half — a claim may reference a finding — unaddressed |

## Notes

**Why this is T3.** It touches `tooling/kit-index.sh`, floored at T3 by the profile. Note that the
parent design's claim of *"`security-reviewer` per the profile"* is **false** — the profile names
no reviewer and `ladder.rung5` is empty; the T3 second-reader rule lives in
`skills/tier-classify/SKILL.md:30`. Cite that, not the profile.

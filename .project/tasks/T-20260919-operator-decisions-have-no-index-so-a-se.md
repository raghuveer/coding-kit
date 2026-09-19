---
id: T-20260919-operator-decisions-have-no-index-so-a-se
title: Operator decisions have no index so a settled question is re-asked
epic: reporting
tier: T2
paths: tooling/kit-decisions.sh, tooling/kit-status.sh, tests/conformance.sh
state: created
---

## Intent

**A decision this operator has already taken cannot be listed, so it gets re-asked.** Recorded
decisions live in at least four shapes and nothing indexes any of them:

| shape | count, 2026-09-19 | findable how |
|---|---|---|
| `docs/adr/*.md` | 12 | by browsing the directory |
| `### Decision, <date> — operator:` inside a task file, **below the acceptance criteria** | 3 task files | only by reading to the end of the right file |
| a STOP / CONTINUE / PROCEED ruling inside `docs/TRIALS/*.md` | per trial | by reading the trial |
| `<paths.design_input>/YYYY-MM-DD-entry-questions.md`, answered | per adoption | not written at all on the one subject that reached this step -- see `T-20260914-the-entry-procedure-writes-into-the-trac` |

**The cost is measured, not anticipated: ADR 0013.** It was written, accepted and **superseded
within hours** on 2026-09-18. Its own retraction names the cause:

> *"The operator decided this on 2026-09-14 and I did not read it. That task file carries a section
> headed 'Decision, 2026-09-14 — operator: a goal is a ROOT TASK plus its `blocked_by` closure',
> below the criteria. I read AC1, saw its note say 'blocked on a decision', and designed an answer
> without reading to the end of the file where the answer already was. The note was a stale
> forward-reference; the decision was four days old."*

A full propose-review-accept-supersede cycle was spent re-deciding a four-day-old decision, and the
ADR it produced argued **the opposite** of what had been decided.

**The operator states it as a standing pattern, 2026-09-19:** *"many times, I see insufficient
context problem as you asked me repeated questions despite me answering them in the past, may be in
slightly different perspective. While asking is not bad, you referring to existing info helps asking
for more details as and when needed."* The phrasing matters — a question re-asked from a different
angle does not match on a literal grep, which is why a per-session search habit has not fixed this
and an index is the remedy.

**This is a graduation prerequisite, not housekeeping.** The interrupt budget is the stated
constraint on auto-mode: silence is cheap, interruption expensive, and an escalation must name which
recorded definition was breached. A run that cannot enumerate what was already decided cannot tell a
genuine escalation from a re-ask, so it must either interrupt too often or proceed against a
decision it never saw.

## Proposed shape, and the alternative that was weighed

**Proposed: a standalone `tooling/kit-decisions.sh --list` (T2 under `tier.rule: tooling/** T2`),
reading the tree at run time.** It is the smallest thing that can fail, and the vocabulary of "what
counts as a recorded decision" is exactly the kind of thing that should be named by use rather than
designed up front.

**Weighed and not chosen yet: ingest decisions in `kit-index.sh` and render a Decisions section in
`kit-status.sh`.** This is the architecturally consistent answer -- decisions would become derived
state like everything else and would land in `STATUS.generated.md`, the file a session already
reads. Two costs push it to a second step rather than the first: `tier.rule` puts
`tooling/kit-index.sh` at **T3**, and teaching its parser a new prose shape runs directly against
`T-20260808-shrink-the-embedded-awk-surface-by-movin` and
`T-20260808-decompose-kit-index-along-the-seam-it-al`, both of which want that surface smaller.

**The choice is recorded as an acceptance criterion rather than settled here**, because promotion
into the index is the right follow-up if the standalone listing proves the vocabulary.

## Acceptance criteria

- [ ] One command lists every recorded operator decision with its date, its subject, and the file it
      is recorded in -- across ADRs and task-file decision sections at minimum
- [ ] The listing is derived from the tree at read time; no hand-maintained list exists, and deleting
      any generated artefact and rebuilding reproduces it
- [ ] A decision recorded in a shape the collector does not know is reported as an **uncounted shape
      with its count**, never omitted silently -- absent is not zero, applied to decisions
- [ ] A conformance step fails when a known decision is dropped from the listing, **proved by
      removing one and watching the step go red** before the step is trusted
- [ ] Whether this folds into `kit-status.sh` / `kit-index.sh` or stays standalone is recorded with
      its reason, so the next reader inherits the argument rather than the outcome

## Notes

Filed 2026-09-19 at the operator's direction, alongside
`T-20260919-task-context-routes-what-next-to-the-pla`. Both come from the same session and the same
root: a decision that exists and cannot be found is, for every practical purpose, a decision that
was never taken.

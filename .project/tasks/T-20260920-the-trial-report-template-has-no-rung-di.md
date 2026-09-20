---
id: T-20260920-the-trial-report-template-has-no-rung-di
title: The trial report template has no rung-disposition row so COMPLETE can be written without one
epic: validation
tier: T2
paths: docs/TRIALS/TEMPLATE.md, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

**`docs/TRIALS/TEMPLATE.md` contains the string `rung` zero times.** Measured 2026-09-20. It
carries `| Outcome | COMPLETE \| ABORTED (*cause*) \| VOID (*condition*) |` and no disposition row
anywhere, while instructing *"Do not restructure it… Delete nothing."*

So a report that follows the mandated shape exactly **reaches COMPLETE without passing a single
rung disposition** — which is the 2026-09-09 headline failure, reproducible today.

`docs/TRIAL-PROTOCOL.md` §6 requires the opposite:

> **State every rung's disposition, in the report, next to the outcome.** One line per rung…
> Not a footnote and not prose elsewhere — a reader must not be able to reach the outcome without
> passing the dispositions.

**That rule is enforced nowhere.** A reviewer mutated §6 by deleting the rule entirely and the
conformance suite stayed green.

**The repository already knows this shape of fix.** The baseline-cause step asserts against the
TEMPLATE rather than the protocol, and says why in its own comment: *"the protocol is read once and
the template is copied into every trial report, so the template is where the shape survives."* The
disposition rule did not get that treatment; `--isolated`, `--unassessable` and `--superseded`
counts all did, and each has a header row in the template.

## Acceptance criteria

- [ ] The template carries a rung-disposition row or section, positioned so a reader reaches it
      before the outcome
- [ ] Each rung's disposition is one of the ladder's three, and an `unsatisfiable` entry is
      visually inseparable from the outcome line rather than a footnote
- [ ] A check that can fail: a conformance step asserting the template carries it, mutation-proven
      by deleting the row. Assert on the TEMPLATE, not only the protocol, for the reason the
      baseline-cause step already gives
- [ ] Whether the pre-flight's recorded disposition feeds this row is decided rather than left
      open. `T-20260912`'s gate writes a `preflight-commands` event that nothing reads

## Notes

Found independently by two reviewers on 2026-09-20, in the second and third T3 chains of
`T-20260912-a-declared-rung-whose-tooling-fails-has-`. Split out because that task's fixes address
detection at pre-flight and this is the reporting half: detection moved earlier and still connects
to nothing a reader sees.

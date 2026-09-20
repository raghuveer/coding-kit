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

- [x] The template carries a rung-disposition row or section, positioned so a reader reaches it
      before the outcome
- [x] Each rung's disposition is one of the ladder's three, and an `unsatisfiable` entry is
      visually inseparable from the outcome line rather than a footnote
- [x] A check that can fail: a conformance step asserting the template carries it, mutation-proven
      by deleting the row. Assert on the TEMPLATE, not only the protocol, for the reason the
      baseline-cause step already gives
- [x] Whether the pre-flight's recorded disposition feeds this row is decided rather than left
      open. `T-20260912`'s gate writes a `preflight-commands` event that nothing reads

### Done 2026-09-20 — asserted by POSITION, which a footnote cannot satisfy

`TEMPLATE.md` carries a `Rung dispositions` row naming all three dispositions and stating that any
`unsatisfiable` makes the outcome VOID. **It sits ABOVE the `Outcome` row**, because §6's rule is
literally positional — *"a reader must not be able to reach the outcome without passing the
dispositions"* — and position is the one property a footnote reusing the same words cannot fake.

The conformance arm asserts the ORDER, not the presence: it compares the two line numbers.
**Mutation-proven** by moving the row below `Outcome`, which reddens it with *"puts the
dispositions at line 22, at or after the outcome at 21"*. A keyword grep would have passed that
mutation, which is exactly how the three prose assertions recorded in the parent were defeated.

**The last criterion, decided rather than left open:** the pre-flight event does NOT auto-fill this
row. §3's detection READS the event to void a trial; the template row is authored by the operator
alongside every other row. Wiring one to the other would make the report a copy of the tool's
output rather than a statement by the person who ran it, and the thing being asked for here is a
statement.

## Notes

Found independently by two reviewers on 2026-09-20, in the second and third T3 chains of
`T-20260912-a-declared-rung-whose-tooling-fails-has-`. Split out because that task's fixes address
detection at pre-flight and this is the reporting half: detection moved earlier and still connects
to nothing a reader sees.

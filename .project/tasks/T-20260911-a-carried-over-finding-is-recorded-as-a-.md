---
id: T-20260911-a-carried-over-finding-is-recorded-as-a-
title: A carried-over finding is recorded as a new row every review round
epic: feedback-loop
tier: T3
lang: python
paths: tooling/kit_findings.py, tooling/schema.sql, tooling/kit-index.sh, tooling/kit-status.sh, tests/conformance.sh
state: created
---

## Intent

A defect that a reviewer carries over from an earlier round is recorded as a **new finding row**
every round, and nothing links it to the row it repeats. So per-task and per-agent finding counts
grow with the number of review rounds, not the number of defects.

On the 2026-09-09 highper-gateway trial, three reviews of one change produced **11 rows for 5
defects**. Two defects appear three times each: the missing single-flight guard (rung 4, rung 5 and
the re-review) and the missing `elapsed() == ttl` test (the same three). The re-review's own
summaries say *"Carried over from round 1"*. Because the finding id is `at` plus a hash, rows from
different rounds never collide, and nothing in the contract lets a reviewer say which earlier row it
is repeating.

**Why it matters beyond tidiness:** the accelerators are seeded from these rows, and the escape rate
and the second-reviewer comparison count them. A defect that survives two rounds weighs three times
as much as one fixed in the first.

The same trial shows a second axis of the problem: the carried-over single-flight defect was classed
`race`, `perf`, `race` across its three rows, so even counting by class does not collapse the
duplicates.

## Acceptance criteria

- [ ] A finding can name the earlier finding it carries over, and `kit-finding.sh --contract`
      documents the field. A reviewer that omits it still validates.
- [ ] Reports count distinct defects and rounds separately, and say which one they are counting.
- [ ] A conformance step records two rounds, where round 2 carries one finding over and adds one
      new, and asserts: 3 rows, 2 distinct defects, 1 carry-over link.

### Evidence, 2026-09-14 — PR #126, and the only blocker that got its tier's review chain

| AC | where to verify |
|---|---|
| 1 — a finding can name the earlier one it carries over, `--contract` documents it, omission still validates | `carries_over`, optional, on the contract; round 1 of the conformance fixture omits it on purpose |
| 2 — reports count distinct defects and rounds separately, and say which | `kit-status.sh` prints both with the labels, and counts a dangling link apart |
| 3 — a conformance step: two rounds, one carried over, one new → 3 rows, 2 defects, 1 link | exactly that, plus a dangling-link arm and a pre-column arm both reviewers asked for |

**Two reviewers, the second blind, both REVISE.** They converged on four findings and rung 5 found
three more. Without them the column would have shipped **permanently empty**: no reviewer prompt
mentioned the field, the by-hand door had no flag — and that is the door all 11 findings of the
motivating trial came through — and a pre-column index printed a confident claim with a blank
count.

**Rung 5 also caught a `false-rationale` in this change's own schema comment**, which justified
the column by accelerator seeding and escape rate while both still count rows. The comment now
says what the column does not fix; the behaviour is
`T-20260914-every-finding-consumer-still-counts-rows`.

## Notes

Where the link lives decides the tier. A new event field has to be ingested into the `finding` table
by `kit-index.sh`, which is why that file is in `paths` and why the task sits at its T3 floor.

Found in the highper-gateway plugin-mode trial, kit defect K3 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

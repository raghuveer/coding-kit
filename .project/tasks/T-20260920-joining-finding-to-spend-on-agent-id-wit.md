---
id: T-20260920-joining-finding-to-spend-on-agent-id-wit
title: Joining finding to spend on agent_id without a guard matches empty on empty
epic: measurement
tier: T2
lang: sql
paths: tooling/schema.sql, tooling/kit-status.sh
state: created
---

## Intent

**The obvious join over these two tables returns confident garbage rather than nothing.** Run on
2026-09-20 against the live index:

    SELECT ... FROM finding f JOIN spend s ON f.agent_id = s.agent_id

`''` equals `''` in SQL, so **582 findings carrying no id joined 35 spend rows carrying no id** and
produced 2.2MB of output — rows reporting `critical` with an empty summary against a real model and
a real token count. Nothing errored. Nothing was empty. The result looked like a successful
measurement and was a cross product of two absences.

**This is the failure mode `T-20260911`'s AC2 names** — *"An empty string that looks like a value is
the failure"* — surviving in the one place the criterion did not reach. That AC was satisfied by
making `kit-status.sh` REPORT the two faults apart, and it does. But the guard lives in the
reporter, so every other consumer has to re-derive it, and the first consumer written after the
criterion passed (a hand-written query, by the session that had just read the criterion) got it
wrong immediately.

**Why this is worth a task rather than a note.** The join's whole purpose is answering "what did
this reviewer cost and what did it find". Six rows joinable against 643 findings means almost every
future query here is mostly-empty on one side, which is exactly the condition that makes an
unguarded join look plausible: a small correct result and a large wrong one are both "some rows".

## Acceptance criteria

- [ ] The guard lives where the join does, not in each caller — a view, a generated column, or a
      NULL-not-empty-string representation, decided and written down with the reason
- [ ] `NULL` versus `''` is settled for `finding.agent_id` and `spend.agent_id` together. A column
      where absence is sometimes NULL and sometimes empty cannot be guarded once
- [ ] A check that can fail: a query over the joined shape with id-less rows present returns only
      genuinely joined rows, and a mutation that removes the guard is seen to return the cross
      product rather than an error
- [ ] Any existing consumer of the join is checked against the guard rather than assumed correct.
      `kit-status.sh` reports the counts apart today and must keep doing so

## Notes

Found on 2026-09-20 while producing the first joinable findings in this repository, recorded under
`T-20260911-a-finding-recorded-by-hand-carries-no-ag`. The session wrote the unguarded query itself,
minutes after reading the criterion that warns about exactly this, which is the argument for the
guard being structural rather than remembered.

Related: `T-20260914-finding-run-ids-and-spend-run-ids-are-tw` settled WHICH id space the column
holds. This task is about what happens when it holds nothing.

---
id: T-20260909-209-of-621-findings-carry-no-language-so
title: 209 of 621 findings carry no language so accelerator derivation is partly blind
epic: reporting
tier: T2
lang: sql
state: created
---

## Intent

`docs/HANDOFF.md`:416 lists as an invariant that must not be broken:

> Findings carry language and defect class from day one -- the only genuinely lossy thing if
> skipped, since findings cannot be retroactively tagged.

Audited 2026-09-09 against `be2a27d`:

    sqlite3 .project/index.db "SELECT COUNT(*) FROM finding WHERE class IS NULL OR class='';"   -- 0
    sqlite3 .project/index.db "SELECT COUNT(*) FROM finding WHERE lang  IS NULL OR lang='';"    -- 209
    sqlite3 .project/index.db "SELECT COUNT(*) FROM finding;"                                   -- 621

**Class holds. Language does not, on a third of the record.** The sentence claims both, so it is
one invariant that is half true, which reads as fully true to anyone who does not run the query.

**Why this matters more than a stale sentence.** The document says why itself: findings cannot be
retroactively tagged. `docs/HANDOFF.md` section 4.5 makes `lang` load-bearing for the accelerator
promotion ladder -- a technology accelerator is derived from findings keyed by language, and a
finding with no language cannot contribute to one. So 209 rows are permanently outside the
mechanism the kit's reuse claim depends on, and `docs/MEASUREMENTS.md` section B.6 already records
the neighbouring failure: domain-tagged compliance findings surfacing as technology candidates.

## Acceptance criteria

- [ ] The 209 are characterised before anything is changed: which recorder wrote them, over what
      date range, and whether `lang` was optional at the time or simply not passed. A remedy chosen
      before that is a guess.
- [ ] Whether `lang` becomes REQUIRED at the writer is decided and recorded. It is a contract
      change on `kit-finding.sh` and on every agent that emits a finding, so it is not free.
- [ ] If it becomes required, a check that can fail: a finding emitted with no language is refused,
      proven by a case that is red before the change.
- [ ] `HANDOFF.md`:416 says what actually holds, whichever way this lands -- and if language stays
      optional, the sentence stops claiming it.
- [ ] The 209 existing rows get a stated disposition: backfilled, left and counted, or declared
      permanently untagged. **Leaving them uncounted is refused** -- `docs/LESSONS.md` section 11,
      an exclusion must be counted, or the smaller number is indistinguishable from a wrong one.

## Notes

Filed 2026-09-09 from the first census the kit has captured; evidence is
`.project/census/handoff-invariants-2026-09-09/section-11-constraints.json`.

Split from `T-20260909-handoff-section-11-asserts-invariants-by` deliberately. That task is a
document drifting from the tree and its remedy is to derive rather than type. This one is a data
and contract defect whose remedy is in `kit-finding.sh` and the agent set, and bundling them would
have put a prose fix and a contract change under one tier.

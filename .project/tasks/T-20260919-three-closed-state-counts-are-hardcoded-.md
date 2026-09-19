---
id: T-20260919-three-closed-state-counts-are-hardcoded-
title: Three closed-state counts are hardcoded literals so the set of states is not derived
epic: reporting
tier: T2
lang: bash
paths: tooling/kit-status.sh, tooling/kit-lib.sh, tests/conformance.sh
state: created
---

## Intent

**This is the T2 half of `T-20260819-vocabularies-live-in-shell-constants-so-`, split off on the
operator's instruction 2026-09-19 so the cheap fix is not held behind a T3 design job.** That task
proposes a derived vocabulary projection -- `lang: sql`, `paths` spanning four files, recorded T3.
This one is the three lines §6 item 5 of `docs/design-input/2026-09-14-state-and-context.md` points
at, and nothing more.

**Measured 2026-09-19, by re-running the greps rather than quoting them.**
`tooling/kit-status.sh:161-163` holds the only genuine hardcoded state partition left in the file:

    printf -- '- %s completed, %s cancelled, %s abandoned\n' \
      "$(q "SELECT COUNT(*) FROM task WHERE state='completed';")" \
      "$(q "SELECT COUNT(*) FROM task WHERE state='cancelled';")" \
      "$(q "SELECT COUNT(*) FROM task WHERE state='abandoned';")"

Against **12** places in the same file that correctly join `state_class`. So the consumers were
migrated and these three were missed.

**The symptom is the one `T-20260819` names:** the line reports only the states someone thought to
hardcode. Today it prints `55 completed, 2 cancelled, 0 abandoned`. A state added to the vocabulary
tomorrow is absent from that line with nothing saying so, and **a state that does not exist reads
identically to a state with zero rows** -- the same absent-is-not-zero failure the empty-review rule
and the `via:kit` denominator rule already exist to prevent elsewhere.

**What must NOT be lost.** The comment above those lines earns its place and the fix has to keep its
guarantee: three counts, not two, because `abandoned` judges the ATTEMPT -- we stopped -- while
`cancelled` judges the WORK -- it should not be done at all. ADR 0008 exists partly to remove that
misread. A derived list must still render all three distinctly rather than collapsing closed states
into one total.

**The figures in §3.2.1 have themselves drifted twice**, which is why the measurement above was
re-taken rather than cited. The note in `kit-lib.sh` prescribes `grep -rc "'done','abandoned'"
tooling/` and says the answer is 19; §3.2.1 re-ran it and got 4, in three named files at named
lines; re-run today it is 4 again but in a **different** three files, and the lines §3.2.1 cites are
now comments. Anything this task records as a count should be a command instead, per
`T-20260919-the-goal-state-comment-says-unwritten-an`.

## Acceptance criteria

- [x] The closed-state line is derived from `state_class` rather than from three literals, so a
      state added to the vocabulary appears without editing this file
- [x] A state in the vocabulary with **zero** rows is rendered as zero, not omitted -- absent and
      zero must not print identically
- [x] `completed`, `cancelled` and `abandoned` remain three distinct numbers with their current
      meanings; the ADR 0008 distinction the existing comment protects survives the change
- [x] A conformance step fails when a vocabulary state is dropped from the line, **proved by adding
      a state to the fixture's vocabulary and watching the step go red** before it is trusted
- [x] `STATUS.generated.md` is byte-identical for the current backlog apart from states that were
      previously invisible, so the change is shown to add coverage rather than to move numbers
- [x] The stale note in `kit-lib.sh` that prescribes the 19-count grep is corrected or removed --
      it is the standing instruction to whoever does this work, and it is wrong

### Evidence, 2026-09-19

**The line is now counted outward from `state_class`**, `WHERE is_closed = 1`, `ORDER BY sc.rowid`.
Rowid is the vocabulary DECLARATION order -- `kit-index.sh` inserts that table by iterating
`kit_state_vocab` -- so the line keeps reading completed, cancelled, abandoned. Ordering by name
would have put abandoned first and silently reordered a published report. Each count is its own
correlated subquery rather than a `GROUP BY` over `task`, because a state with no rows has nothing
to group and would vanish, which is the defect being fixed.

**AC5 was proved with a clean A/B, after the first attempt was not one.** The initial baseline had
been taken before an unrelated plan regeneration, so its diff showed changes this task did not
cause. Re-run properly -- old `kit-status.sh` and new, against the SAME `index.db`, with no
reindex between them -- the output is **byte-identical**.

**AC4 is proved in both directions, which is the only way it means anything.** With the vocabulary
frozen at seven states, no assertion over the CURRENT states can tell a derived list from a
hardcoded one: both print the same line. So the step copies `tooling/` out of the kit and
**mutates the vocabulary itself**, declaring an eighth closed state with no rows.

    PASS  controlled, mutation-proved by an eighth closed state, and ordered by the vocabulary
    FAIL  ... same step, with the fix reverted   (0 passed, 1 failed)

The first arm alone would have been a green that cannot fail, which `LESSONS.md` section 1
refuses; it is kept only as the control that proves the fixture is sane before the mutation lands.

**A defect in the first draft of the test, found before it shipped:** the kit copy sat inside the
fixture repository, so `git add -A` committed the whole kit into the subject's own history and the
indexer then walked it. Moved outside. It is the same rule a trial has about not writing into its
subject.

**AC6 keeps the history and drops the instruction.** The `kit-lib.sh` note's "NINETEEN places on
2026-08-22" is a dated measurement and stays, on the same grounds as the immutable commit counts.
What went was the live count presented as current. The replacement names a grep for the three
literal partitions; it returns **nothing** across `tooling/` now.

### Review, 2026-09-19 — rung 4, one adversarial reader, REVISE

`skills/verify-ladder` makes rung 4 a **T2** obligation, not a T3 one, so this ran before the task
could honestly close. Five findings, all reproduced against the tree before being acted on.

| # | severity | finding | disposition |
|---|---|---|---|
| 1 | **major** | the grep this task told the next reader to run matches its OWN comment line, so "returns nothing" was false | fixed — the note now states the expected single self-hit and why |
| 2 | minor | "twelve other partitions join `state_class`" counted matching LINES, not partitions | fixed — the count is gone, replaced by the command |
| 3 | minor | the fixture mutation self-check could not tell a half-applied mutation from a full one | fixed — each function asserted separately |
| 4 | minor | arm 3's ordering check could not fail; arm 2 already pinned order by string equality | removed, with the reasoning kept in place of the arm |
| 5 | minor | the empty-vocabulary branch was untested and named a cause `q()` cannot distinguish | fixed and now exercised |

**Finding 1 is the one to keep.** AC6 existed because the old note froze a live count; the
replacement asserted the new command "returns nothing across `tooling/`" — and the check behind
that claim piped its output through `grep -v kit-lib.sh`, filtering out the only hit. **A
verification rigged, unintentionally, to agree with the sentence it was verifying.** The note now
states the invariant instead: exactly one hit, and it is the comment itself.

**Finding 5 turned an untested branch into a tested one, and the message with it.** It had asserted
*"it was not built by `kit-index.sh`"* — a cause `q()` cannot see, because it swallows stderr and a
missing table, an unreadable file and a syntax error all arrive identically. That is
`T-20260812-the-empty-spend-notice-asserts-a-cause-i` repeated, in a notice written by the person
who had read that task. It now reports only what it observed, and arm 3 asserts **both** that the
notice appears and that it does not diagnose.

**Every arm was proved able to fail, individually.** Arm 2 red with the fix reverted; arm 3's first
assertion red when the notice is absent, and its second red when a notice is present but diagnoses
a cause — proved with a deliberately contrived message, because an assertion never shown to fail is
the decorative thing finding 4 was about.

## Notes

Filed 2026-09-19. The parent task `T-20260819-vocabularies-live-in-shell-constants-so-` keeps the
design question it was filed for -- whether a vocabulary becomes a derived projection table -- and
is unaffected by this landing first.

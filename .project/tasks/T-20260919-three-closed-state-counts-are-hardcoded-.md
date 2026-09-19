---
id: T-20260919-three-closed-state-counts-are-hardcoded-
title: Three closed-state counts are hardcoded literals so the set of states is not derived
epic: reporting
tier: T2
lang: bash
paths: tooling/kit-status.sh
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

- [ ] The closed-state line is derived from `state_class` rather than from three literals, so a
      state added to the vocabulary appears without editing this file
- [ ] A state in the vocabulary with **zero** rows is rendered as zero, not omitted -- absent and
      zero must not print identically
- [ ] `completed`, `cancelled` and `abandoned` remain three distinct numbers with their current
      meanings; the ADR 0008 distinction the existing comment protects survives the change
- [ ] A conformance step fails when a vocabulary state is dropped from the line, **proved by adding
      a state to the fixture's vocabulary and watching the step go red** before it is trusted
- [ ] `STATUS.generated.md` is byte-identical for the current backlog apart from states that were
      previously invisible, so the change is shown to add coverage rather than to move numbers
- [ ] The stale note in `kit-lib.sh` that prescribes the 19-count grep is corrected or removed --
      it is the standing instruction to whoever does this work, and it is wrong

## Notes

Filed 2026-09-19. The parent task `T-20260819-vocabularies-live-in-shell-constants-so-` keeps the
design question it was filed for -- whether a vocabulary becomes a derived projection table -- and
is unaffected by this landing first.

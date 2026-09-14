---
id: T-20260914-the-entry-procedure-writes-into-the-trac
title: The entry procedure writes into the tracked tree which voids the trial it serves
epic: validation
tier: T1
lang: markdown
paths: docs/ENTRY-PROPOSAL.md, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent


## Acceptance criteria

- [ ] 
- [ ] 

## Notes

## Intent

`docs/ENTRY-PROPOSAL.md` step 3 has the orchestrator write two files. One,
`<paths.state>/entry-candidates.md`, is fine on a trial subject: `paths.state` is `.project`, which
this subject ignores. The other is not:

    <paths.design_input>/YYYY-MM-DD-entry-questions.md   -- **committed**

`docs/TRIAL-PROTOCOL.md` S3 makes a dirty subject tree a **VOID condition**. On `highper-gateway`
`docs/design-input/` does not exist and is not ignored, so creating it puts `?? docs/design-input/`
in `git status --short`. **Following the documented entry procedure voids the trial that the entry
procedure is being run inside.** Measured 2026-09-14: the copy was clean before the step and the
step was therefore not taken; the questions were left in the ignored candidates file instead, which
is not what the procedure says.

**This is the third instance of one gap, and that is the point.** The trial-2 pre-flight already
found it twice -- the baseline run rewrites `Cargo.lock`, and `kit-preflight.sh --commands` does the
same -- and both were treated as properties of those two steps. They are not. **Any kit step that
writes into the tracked tree collides with S3**, and the kit has no rule saying which steps may.
`T-20260914-the-copy-procedure-loses-branches-trusts` AC3 asks for a clean-tree assertion before the
clock; that helps the baseline and does nothing for a step taken mid-trial.

## Acceptance criteria

- [ ] The kit states, in one place, which of its steps write into the tracked tree, and S3 says what
      a trial does when one of them must run. Today the two rules contradict each other silently and
      whoever notices first decides.
- [ ] The entry questions have a home that does not depend on the subject's ignore rules, **or**
      S3 excludes paths the kit itself is expected to create. Either is a decision; neither is made.
- [ ] A check that can fail: a trial that took a tree-writing step and did not record it should be
      distinguishable afterwards from one that did not take it. It is not, today.

## Notes

Filed 2026-09-14 from trial 2's entry unit. The deviation is recorded in the copy's
`.project/entry-candidates.md` and in `docs/TRIALS/2026-09-14-highper-gateway.md`.

**Not a reason to change S3 by default.** A dirty tree voiding a trial is a real control and it has
already caught real contamination in this trial's own pre-flight. The defect is the absence of a
rule, not the strictness of the one that exists.

---
id: T-20260825-reviewing-generated-code-is-not-the-same
title: Reviewing generated code is not the same job as reviewing a human diff
epic: agent-contracts
tier: T2
lang: markdown
paths: agents/security-reviewer.md, agents/implementation-reviewer.md, skills/tier-classify/SKILL.md
state: created
---

## Intent

Every reviewer contract in this kit assumes a change with a human intention behind it. It reads
the diff and asks whether the intention was carried out safely. That is the right shape for a
human diff and the wrong shape for the code this kit exists to review, because **the kit's whole
purpose is that an agent wrote it.**

Generated code fails differently. It is plausible where human code is wrong; it is confidently
commented where human code is uncertain; and it is frequently correct against a specification so
thin that "correct" was never defined. A reviewer that only asks "does this do what was intended"
cannot see the third case at all, because it takes the intention from the same underspecified
source the coder did.

**Demonstrated on this repository on 2026-08-25, unprompted.** During the 0.11.0 release check, a
task was created with `kit-task.sh`, its Intent and acceptance criteria left empty, and a change
made against it. `tier-classify`, run through `claude --plugin-dir`, returned **T2 against the
`Tier: T1` already on the commit and in the task file** — raised on the ambiguity axis, because
the acceptance criteria were empty and the behaviour therefore inferred rather than stated. It
named what was unstated: raise versus coerce, and whether `bool` counts as numeric (it passes
`isinstance(x, int)`).

That is the exact failure class this task is about, and the important detail is **where it was
caught**: `tier-classify` has an ambiguity axis and **the reviewers do not**. A tier was raised;
no reviewer would have said anything, because the code does what the empty specification implies.

## Acceptance criteria

- [ ] The reviewer contracts carry a **specification-adequacy** check: is the acceptance
      criteria set sufficient to make "correct" decidable for this change? An inadequate
      specification is a finding against the TASK, not against the code, and must be recordable
      as such.
- [ ] A **scope check**: does the change implement behaviour no acceptance criterion asked for?
      Unrequested behaviour in generated code is the common shape and is currently invisible —
      it is not a bug, it does not fail a test, and nothing asks about it.
- [ ] A **load-bearing-comment** check. `security-reviewer` already says "do not accept a safety
      argument written in a comment as evidence"; generalise it, because generated code produces
      confident explanatory comments at a far higher rate than human code and the reviewer is
      reading them as context.
- [ ] The ambiguity signal is **shared, not duplicated**. `tier-classify` already computes it;
      the reviewers should consume it rather than re-deriving it in three more files. The finding
      vocabulary drifted across four locations once and produced agents whose output the recorder
      rejected — this is the same shape.
- [ ] These checks are **cheap**. They are questions about the specification and the diff, not a
      second full review pass. If this measurably raises per-review token cost, it is wrong: the
      argument for it is that it catches a class nothing else catches, not that more review is
      better.
- [ ] Recorded with a finding class that lets the class be counted. Whether that needs a new
      value in `kit-finding.sh --vocab` is part of the work; `unclassified` is not an answer.

## Notes

**This is not blocked by the security scope, and the distinction matters.**
`T-20260819-researcher-carries-no-security-baseline-` IS blocked by
`T-20260808-make-the-security-assurance-cadence-a-po`, for a real reason: the scope selects which
checklist to load, and "include OWASP" without one is a firehose. Nothing here depends on a
security scope. Specification adequacy, unrequested scope, and load-bearing comments are the same
questions in every stack and every vertical. Declaring a dependency that does not exist would
push this behind two tasks for no reason — and `kit-plan.sh` reads `blocked_by`, so a false
dependency is not a note, it is an ordering.

**The evidence base is thin and should be stated rather than dressed up.** Two brownfield trials
have run and NEITHER exercised `coder` or the reviewers; the 2026-08-25 adoption run exercised
skill loading and `tier-classify` only. So the failure classes above are argued from one observed
instance plus the shape of the contracts, not from a measured defect population. **The right
first move may be to measure rather than to write checks**: run one real task end to end through
`coder` and the reviewers under `--plugin-dir`, and see what the reviewers miss. A check written
against an imagined failure distribution is how a control ends up green and meaningless.

Related: `T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` is the task where that measurement
would happen.

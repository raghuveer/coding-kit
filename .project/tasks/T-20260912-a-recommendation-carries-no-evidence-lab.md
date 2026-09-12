---
id: T-20260912-a-recommendation-carries-no-evidence-lab
title: A recommendation carries no evidence label so partial guidance reads as settled
epic: agent-contracts
tier: T2
paths: .claude/CLAUDE.md
state: created
---

## Intent

The operator, 2026-09-12: *"so many of your recommendations might be turning as partial
guidance. I am asking for review occasionally."*

**The failure is narrower than "bad recommendations".** A recommendation is stated at the moment
it is FORMED, with the confidence of a conclusion, and the checking happens afterwards. The later
correction is honest but late: the operator has already read the first version, and may have
acted on it. The cost lands on them -- "asking for review occasionally" means spending attention
auditing advice that cannot be taken at face value.

**Six instances in the single session that filed this, all the same shape:**

| stated | refuted by |
|---|---|
| "`--event SubagentStop` is the principled fix" | the 19 gaps WERE SubagentStop firings, so the flag would have suppressed none |
| "the 73 conformance steps are already independent" | the suite has chains, declared in `--list`; two spend steps share one fixture |
| "14.1 min, 103 passed, 0 failed" | the run had silently skipped every chained step; the real figure is 22.1 min and 177 result lines |
| "a `Stop` carrying an agent_id skips the sweep" | the 13:57:34Z triple shows the sweep ran |
| "floorof is a message fix" | a schema column, an adopter-facing behaviour change, and a re-pin of two cross-platform reproducibility constants |
| "about 4.3x from parallelising the suite" | 2.7x -- and `docs/TRIAL-PROTOCOL.md` section 2 had ALREADY measured that spawns do not parallelise here, 1.16x on eight workers |

**Why a skill is the weaker instrument, by this repository's own evidence.** `.claude/CLAUDE.md`
already contains a rule that was written down and then broken twice in the same session, and it
says so: *"This is written down because knowing it was not enough. The order was inverted twice in
one session after the lesson had already been recorded."* Its conclusion is that such a rule must
be **"a precondition on the ACT ... not a strategy to remember."** A skill carrying good advice is
the shape that has already failed here. What survives is something that produces an ARTEFACT.

## Acceptance criteria

- [ ] Every recommendation in session output carries one of three labels -- **measured**, **read**, **guess** -- naming what was actually done rather than what could have been. `measured` requires a command run in that session; `read` requires a file read in that session; anything else is `guess`, including a confident inference from code already seen
- [ ] A **sequencing** recommendation quotes `kit-plan` output, or states that the planner disagrees and why. Asserting an order without consulting the planner is the failure `[[sequencing-is-a-claim-that-needs-checking]]` already records three times, and it recurred twice more in the session that filed this
- [ ] A **size or scope** claim -- "small", "a message fix", "one line" -- names the consumers that were checked. One grep for what reads the thing being changed, BEFORE the adjective. "floorof is a message fix" would have died immediately against this
- [ ] The rule lands as a precondition on an ACT, not as advice to remember, per `.claude/CLAUDE.md`'s own record that writing the lesson down failed twice in one session
- [ ] A CHECK THAT CAN FAIL: the operator can point at any recommendation in a transcript and find its label, and a `measured` label with no command behind it in the same session is a defect. Without this the whole thing is decoration
- [ ] Decide, and record the reason, whether this belongs in `.claude/CLAUDE.md`, in a skill, or in both. The evidence above argues against a skill alone; that argument should be written down rather than assumed by whoever implements it

## Notes

Filed on the operator's instruction of 2026-09-12, after they asked: *"Do we create a
skill to address this or how? I am asking about recommendations in text window on claude-code."*

**Scope, stated because it is easy to widen wrongly.** This is about the assistant's output in the
session window. It is NOT about claims in repository artefacts -- thirteen existing tasks already
cover those: claims in documents, findings, census records, `--help` output, acceptance criteria.
The nearest, `T-20260826-no-agent-owns-verifying-documented-claim`, is documented claims checked
against the tree. None of them covers what is said in conversation, which is why this is filed
separately rather than folded into one of them.

**Open, and deliberately not decided here:** whether the label belongs on EVERY recommendation or
only on ones that change what gets built. Mandatory everywhere risks the noise that makes a
warning skippable -- the same argument this repository already makes about a gap that is always
present. Whoever implements this should measure that rather than guess it, which is the point.

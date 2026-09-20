---
id: T-20260920-section-6-cites-section-3-for-an-unsatis
title: Section 6 cites section 3 for an unsatisfiable-rung VOID condition section 3 does not carry
epic: validation
tier: T2
paths: docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

**The cross-reference points at nothing, and it is the reference an operator follows to void a
trial.**

`docs/TRIAL-PROTOCOL.md` §6 says, in as many words:

> **A trial with any unsatisfiable rung is VOID, never COMPLETE** — see §3 and the ladder's
> `## Completion`.

**§3 contains the word `unsatisfiable` zero times.** Verified 2026-09-20 by extracting §3 and
counting. Its VOID table has eight conditions and none of them is this one. §0's stop rules route
the operator to *"any VOID condition (§3)"*, so an operator following the protocol literally checks
§3, finds nothing, and does not void.

**Why this is the live half of the 2026-09-09 failure.** The eighth condition that WAS added to §3
detects a mid-trial profile change — the **remedy** an operator might reach for — not the **fault**,
a rung that could not run. So the document now detects the escape route and not the thing being
escaped.

§3's own premise is *"a condition without a detection is not a control"*. This is the inverse and
is worse: a condition that is cited as existing, by another section of the same document, and does
not exist at all.

## Acceptance criteria

- [x] §3 carries an unsatisfiable-rung VOID condition **with a detection**, like its other eight
- [x] The detection is runnable and is shown run, including what it prints when the condition has
      NOT fired. "Empty is a pass" needs a status check, because a command that could not run also
      prints nothing
- [x] §6's cross-reference resolves, and §0's routing to §3 reaches the condition
- [x] A check that can fail: a conformance step asserting §3 carries it, mutation-proven by
      removing the row and seeing the step go red. **Not a grep that a footer can satisfy** — see
      the three defeated attempts recorded in
      `T-20260912-a-declared-rung-whose-tooling-fails-has-` before choosing the shape of this one

### Done 2026-09-20 — and the detection is the gate's own event

§3 now carries a **ninth** condition: *"A rung was declared UNSATISFIABLE and the trial continued."*
Its detection is the `preflight-commands` event `kit-preflight.sh --commands` already writes:

    grep -h '"kind":"preflight-commands"' <subject>/.project/events.ndjson | grep -c '=unsatisfiable'

**That closes the loop the reviewers said was missing.** The previous criticism was that the gate
moved detection earlier and connected to nothing; the event it writes is now what §3 reads, so
pre-flight's answer reaches the document that voids the trial.

**"Empty is a pass" carries its status check**, because an absent file and an unrun pre-flight both
print zero — the "a question that could not be asked is not a pass" rule this document applies
elsewhere and did not apply to its own eighth condition.

**The check is deliberately NOT shaped like the prose assertions next door.** Three attempts at
asserting a normative document by keyword were each defeated. This one runs §3's detection against
a fixture where a rung IS unsatisfiable, one where none is, and one with no log at all, and
requires it to separate them. Mutation-proven: deleting the condition row reddens arm 1; breaking
the detection reddens arm 2.

## Notes

Found by the second reviewer of the T3 chain on 2026-09-20 and confirmed by the third chain's
independent reviewer. Split out of `T-20260912-a-declared-rung-whose-tooling-fails-has-`, whose
own fixes do not touch it: that task made the pre-flight gate fire, and this is the reason firing
earlier still does not stop a COMPLETE claim.

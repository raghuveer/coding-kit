---
id: T-20260912-a-declared-rung-whose-tooling-fails-has-
title: A declared rung whose tooling fails has no disposition, so work completes unverified
epic: agent-contracts
tier: T3
paths: skills/verify-ladder/SKILL.md, docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

`skills/verify-ladder/SKILL.md` gives a rung two dispositions: **satisfied**, or
**declared unavailable with the tier raised**. A third state happens in practice and has no name:
*a satisfaction IS declared for this stack, and it does not run or does not pass.*

The gap is narrow, and the mechanism around it works. SKILL.md:41-42 -- *"If a rung has **no
satisfaction declared** for this stack, do not skip it silently. Declare it unavailable, name the
compensating control, and raise the tier by one"* -- is conditioned on nothing being declared. It
does not reach a declared `commands.typecheck` that fails.

**Measured on the 2026-09-09 highper-gateway trial**, which distinguished the two situations
itself and handled one of them correctly:

| rung | declared | outcome |
|---|---|---|
| 1 | `commands.typecheck` | **failed everywhere.** Windows host died on jemalloc's autoconf; `--no-default-features` died because io-uring does not type-check on Windows at all; the container probe ran 1,464 s and died on a missing `protoc` |
| 2 | `commands.test` | **blocked before the kit touched anything** -- the `--lib` target does not compile at `05c56eb` |
| 3 | `ladder.rung3` EMPTY | **declared unavailable, tier raised T2 to T3**, rung 5 then satisfied by a second blind reviewer. This is the existing procedure, and it worked |

Rungs 1 and 2 were neither satisfied nor declarable unavailable, because both had tooling
declared. `SKILL.md` under its own `## Completion` heading says work is complete when every
obligation is *"either satisfied or explicitly declared unavailable with its tier raised"*, and
closes with *"'I inspected it' satisfies no rung"* -- a section whose whole purpose is refusing
informal satisfaction, admitting a failing declared rung through a gap in its own enumeration.

The trial recorded **COMPLETE**. Two reviewers passed the change at rungs 4 and 5. It does not
compile: `registry.rs:77`, `error[E0597]`, `git blame` attributing the line to that trial's own
commit `ab74d4c`.

**And the protocol closed the only exit.** `docs/TRIAL-PROTOCOL.md` section 2, *Constant WITHIN a
trial*: *"Changing any of these mid-trial voids it: the kit SHA, the agent set and each agent's
capability, the profile (`tier.rule`, `commands.*`, `ingest.*`, `accelerator.*`)"*. Adding
`protoc` to the wrapper is a `commands.*` change, so the only route to a green rung 1 voided the
trial. The trial reasoned this out and stopped, correctly.

**That condition is in section 2 and NOT in section 3.** Section 3 lists six VOID conditions with
a detection for each, on the stated premise that *"a condition without a detection is not a
control"*. The profile-change condition is the one that actually fired on a real trial, and it is
the one section 3 does not carry.

## Acceptance criteria

- [ ] The ladder names a **third disposition** -- a declared satisfaction that did not run or did not pass -- kept distinct from `unavailable`, which stays conditioned on nothing being declared for the stack
- [ ] A rung in that state **blocks a completion claim**. Today `## Completion` permits complete with such a rung, because it is neither of the two states that section enumerates
- [ ] `docs/TRIAL-PROTOCOL.md` section 3 carries the profile-change condition **with a detection**, like its other six. It is the VOID condition that actually fired on a real trial and the only one section 3 omits, in the section whose premise is that an undetectable condition is not a control
- [ ] Pre-flight proves every `commands.*` actually RUNS before the clock starts. Trial 1 discovered `commands.typecheck` was unsatisfiable after starting, when the only remedy was a change that voids the trial -- so the trial had no non-voiding move left. This is the structural fix; the criteria above are reporting
- [ ] A trial reporting **COMPLETE** states each rung's disposition in the report template, so the outcome cannot be read without seeing which rungs failed
- [ ] A CHECK THAT CAN FAIL: a conformance step asserting the skill names all three dispositions and that section 3 carries the profile condition -- the same shape as the existing step asserting section 0 calls the superseded count
- [ ] Rung 3's existing behaviour is preserved. Declaring an undeclared rung unavailable and raising the tier worked correctly on trial 1 and must keep working

## Notes

**On the tier, stated plainly because it is an argument rather than a floor.** No
`tier.rule` in this repository covers `skills/` or `docs/` -- the floors are `tooling/**` T2,
`tooling/kit-index.sh` T3, `.claude-plugin/**` T2 and `hooks/**` T2 -- so `tier.default: T1`
applies and nothing forces T3. T3 is claimed on consequence: this is the control that decides
whether every other control ran, and its failure is silent, reading as a completed trial. The
operator was told this before filing and chose T3.

**Filed after the operator asked whether kit lessons are landing in the kit's scope.** The honest
answer was *partially*: that day produced three kit defects fixed and merged and six tasks filed,
all of them defects, while the methodology lesson from trial 1 had no task at all. This is that
lesson.

**Two claims in the first draft were wrong and were corrected before filing**, which is worth
recording because it is the same failure mode the ladder gap describes. The draft said the ladder
had no procedure for an unavailable rung -- it does, and trial 1 followed it. And it cited the
profile-change rule to section 3, where it is not; it is in section 2, which is exactly the
finding.

**Not in scope:** whether the subject should be fixed. `registry.rs:77` and the undeclared
`cmake`/`protoc` build dependencies are subject findings for that project's owner, routed by
section 7's three kinds of finding, and they do not belong to the kit.

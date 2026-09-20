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
- [ ] Pre-flight proves every `commands.*` actually RUNS before the clock starts. **This is methodology finding M5 of the 2026-09-09 trial**, deliberately left here rather than written into §3 on 2026-09-12 when its five siblings were, because duplicating it would fork one fix across two homes. Trial 1 discovered `commands.typecheck` was unsatisfiable after starting, when the only remedy was a change that voids the trial -- so the trial had no non-voiding move left. This is the structural fix; the criteria above are reporting
- [ ] A trial reporting **COMPLETE** states each rung's disposition in the report template, so the outcome cannot be read without seeing which rungs failed
- [ ] A CHECK THAT CAN FAIL: a conformance step asserting the skill names all three dispositions and that section 3 carries the profile condition -- the same shape as the existing step asserting section 0 calls the superseded count
- [ ] Rung 3's existing behaviour is preserved. Declaring an undeclared rung unavailable and raising the tier worked correctly on trial 1 and must keep working

### Evidence, 2026-09-14 — PR #117, open and UNREVIEWED

**The boxes above are deliberately unticked, and there is a second reason here.** Beyond the
usual one — a session must not certify its own output — this is T3, and **the review chain the
tier asks for has not run.** The session was directed not to spawn agents. The tier is claimed
on consequence rather than a floor (this is the control that decides whether every other
control ran), so the missing chain matters more here than it would elsewhere.

| AC | addressed by | where to verify |
|---|---|---|
| 1 — a third disposition, distinct from `unavailable` | named **`unsatisfiable`** | `skills/verify-ladder/SKILL.md` `## Satisfaction`, now three numbered dispositions, with the distinction from an ordinary failing check stated |
| 2 — it blocks a completion claim | `## Completion` rewritten | it enumerated two states and permitted the third by omission; now says an unsatisfiable rung blocks, and inside a trial the outcome is VOID rather than COMPLETE |
| 3 — §3 carries the profile-change condition with a detection | added | `docs/TRIAL-PROTOCOL.md` §3, seven conditions become eight. Detection `git -C <subject> log --oneline <preflight-sha>..HEAD -- .claude/project-profile.md`, run here and empty on an unchanged profile |
| 4 — pre-flight proves every `commands.*` RUNS before the clock starts (M5) | `kit-preflight.sh --commands` | three outcomes matching the ladder's three dispositions; wired into §0 as a subject box |
| 5 — a COMPLETE report states each rung's disposition | added | §6 Reporting: one line per rung, and a reader must not reach the outcome without passing them |
| 6 — a check that can fail | conformance step, mutation-proven | asserts the ladder names it and blocks, §3 carries the condition, and `--commands` separates three outcomes on a fixture. Collapsing them to two takes it red |
| 7 — rung 3's existing behaviour preserved | unchanged and stated | the `unavailable` clause is untouched; the ladder says in as many words that trial 1's rung-3 path was correct and still is |

**A finding from building it, not in the criteria:** `commands.build: # none -- nothing is
compiled` handed to a shell **runs and exits 0**. A pre-flight that executed the declared value
blindly would report the rung satisfiable while nothing is declared — the same conflation the
ladder gap is about, one layer down in the control meant to catch it. The arm separates them and
the mutation that collapses them is the one that takes conformance red.

### The T3 chain finally ran, 2026-09-20 — and the verdict is REVISE, twice

**Correction to the section above: PR #117 is MERGED** (`5304db9`, merged `aed2bf6`), not "open and
UNREVIEWED". That line has been stale since 2026-09-14. All seven criteria were re-verified present
on `main` before this review, so the work landed. **What had never run was the review the tier
declares** — and this is the one task where skipping it is the defect it exists to name.

Two reviewers, launched in parallel so neither could see the other's findings, which is what
`skills/tier-classify/SKILL.md:30` requires of T3.

| run | findings | critical | major | turns | weighted ITE |
|---|---|---|---|---|---|
| A | 11 | 2 | 5 | 48 | 649,361 |
| B | 8 | 1 | 4 | 55 | 784,855 |
| **chain** | **19** | **3** | **9** | — | **1,434,216** (75,485 per finding) |

**BOTH VERDICTS ARE `revise`. THIS TASK MUST NOT BE CLOSED.**

#### The critical both found independently, blind to each other

**`kit-preflight.sh --commands` does not fire on the trial it was built from.** It calls a rung
`unsatisfiable` only on shell exit **126 or 127**; every other non-zero prints *"ran, exit N — a
baseline fact, not a stop"* and the arm exits 0. The 2026-09-09 trial's own notes record the
actual exits: **101** for the jemalloc host probe, **101** for io-uring, **101** for the 1,464-second
container probe on missing `protoc`. All three land in the pass branch.

**Verified by this session at the source**, not taken on report: `tooling/kit-preflight.sh:447-453`
for the case statement, `docs/TRIALS/2026-09-09-highper-gateway-plugin-mode/trial-notes.md:25,30,76`
for the exit codes. §0 line 217 still promises the opposite — *"a command that is declared and does
not run is **unsatisfiable**, and that is a stop."*

Reviewer B traced the cause: follow-up commit `4d0785f`, *"a command that ran and failed is a
baseline fact, not a stop"*, turned three outcomes into four. The distinction it drew is correct —
ran-and-failed is genuinely not cannot-run — but the signal chosen to carry it does not.

#### The second critical: the conformance step cannot fail on the defect it names

The step's first `check` is four **file-wide** greps against `SKILL.md`. Two of them —
`unsatisfiable` and `blocks a completion claim` — are satisfied by the `## Satisfaction` section
alone. **Both reviewers independently restored `## Completion` to its pre-change two-state text —
the exact regression this task exists to prevent — and the step stayed green, 2 passed 0 failed.**
Verified here: the strings sit at `## Satisfaction` lines 15 and 20, and nothing anchors any
assertion to `## Completion`.

#### What only the SECOND reviewer found, which is the argument for T3

- **§6:591 says *"A trial with any unsatisfiable rung is VOID, never COMPLETE — see §3"*, and §3
  contains the word `unsatisfiable` zero times.** Verified. The eighth condition that was added
  detects the *remedy* (a mid-trial profile change) rather than the *fault*. The cross-reference
  points at nothing.
- **`docs/TRIALS/TEMPLATE.md` has an `Outcome` row and no disposition row at all** — zero mentions.
  The template says "Do not restructure it. Delete nothing", so a report following the mandated
  shape reaches COMPLETE without passing a single rung disposition. That is the 2026-09-09 headline
  failure, still reachable. Mutation-proven: deleting §6's rule entirely keeps the step green.
- **The two documents contradict each other on the founding case.** `SKILL.md:62` calls a target
  that does not compile before you touched it `unsatisfiable`, which blocks completion.
  §0's baseline box and `kit-preflight.sh:452` call the same thing a blessed known-red baseline.
  That is rung 2 of the incident.

**So the second reviewer was not redundant, measured rather than asserted.** It converged on the
critical independently — which is the strongest evidence either finding is real — and contributed
three majors the first did not reach, all structural rather than local. `docs/MEASUREMENTS.md`
asks *"Is T3's second reviewer redundant?"* and answers no; this is a fresh data point for it, and
the first where both runs are joinable to their own cost.

#### What holds

The `unavailable` clause for a rung with nothing declared is byte-for-byte unchanged and still
correct; trial 1's rung-3 path was right and still is. The `## Completion` sentence blocking
COMPLETE is real prose that does hold on paper. **It is the only thing holding** — every mechanical
support around it either does not fire, does not contain the rule, or is not enforced.

#### One limit on this chain, stated rather than left to be assumed

Both reviewers ran as `general-purpose` agents. **The kit's own named reviewer agents were not
used, because they are plugin agents and were not loaded in this session** — adoption installs no
agent anywhere, which is already on trial 3's agenda. So this chain exercised the ladder and the
protocol; it did not exercise the kit's reviewer routing, and the tier should not be read as fully
exercised in that second sense.


### The two criticals are fixed, 2026-09-20. Nine majors remain open.

**Critical 2 — the conformance assertion could not fail on the defect it names.** The four greps
were file-wide over `SKILL.md`, and both ladder strings live in `## Satisfaction`, so `## Completion`
could be reverted to its two-state text with the step still green. The assertions are now
**section-anchored**: a small `awk` extracts one `## ` section by name and the match must occur
inside it. `## Completion` must mention `unsatisfiable` AND say it blocks.

**Mutation-proven.** Restoring `## Completion` to its pre-fix text — the exact mutation both
reviewers used — now takes the step RED, naming which section lost the rule.

**Critical 1 — the gate did not fire on its founding case.** Fixed, and NOT the way it first looks.

The obvious repair, treating exit 101 as "cannot run", was rejected because it is a regression:
commit `4d0785f` correctly established that `cargo check` exiting 101 over 91 real type errors
**ran**, and §0's baseline box blesses exactly that subject. A gate that stops there stops on the
case the protocol permits.

**The real defect is that an exit code cannot carry the distinction.** A missing `protoc` exits 101.
Ninety-one type errors exit 101. Every exit-code rule trades one false reading for the other. So
the arm no longer decides: **a red command STOPS and requires a recorded disposition, carrying the
count, before the clock starts.** The blessed baseline stays legal — the operator blesses it
explicitly, which is what §0's "only if you knew that first" already demands, instead of this
script guessing on their behalf.

**Proved in four directions, not one:**

| case | expected | got |
|---|---|---|
| two commands exiting 101, no disposition | STOP | `exit 1`, both named |
| same, `KIT_COMMANDS_RED_DISPOSITIONED=2` | pass | `exit 0` |
| same, stale count `=1` | STOP | `exit 1` — **but see the correction below: this proves far less than I claimed** |
| all commands green, no variable | pass | `exit 0` — no new friction where nothing is red |

**And the gate itself has a check that can fail.** Mutating `if [ "$_red" -gt 0 ] && …` to
`if false` takes arm 3 red with *"a ran-and-failed command passed without a disposition (rc=0)"*.
Run against a full clone, because a partial file copy fails `kit_active` at arm 1 and never
reaches arm 3 — a first attempt at this proof failed for that reason and is recorded so the next
reader does not repeat it.

**STILL OPEN: the nine majors from the T3 chain**, recorded as findings against this task. The two
most consequential, both from the second reviewer:

- **§6:591 cites §3 for a VOID condition §3 does not contain** — verified, zero occurrences of
  `unsatisfiable` in §3. The eighth condition that was added detects the remedy, not the fault.
- **`docs/TRIALS/TEMPLATE.md` has an `Outcome` row and no disposition row**, while instructing
  "Delete nothing". A report in the mandated shape still reaches COMPLETE without passing a rung
  disposition — the 2026-09-09 headline failure, still reachable.

Neither critical fix touches either. **This task does not close on this change.**


### CORRECTION 2026-09-20 — the second T3 chain rejected the fix, and both criticals are real

The fix above was reviewed by two more reviewers, in parallel and blind to each other. **Verdicts
`reject` and `revise`. Both criticals below were reproduced by this session before being written
down.** Seventeen further findings; the fix does not merge.

**CRITICAL — `sec()` has no end anchor, so the anchoring is defeated by one line of boilerplate.**
`awk -v h="## $2" '$0==h{f=1;next} /^## /{f=0} f'` closes a section only at the next `## `.
**`## Completion` is the LAST `## ` heading in `SKILL.md`** — line 162 of 176 — so the "anchored"
extraction runs to end of file. Restoring `## Completion` to its true pre-fix two-state text and
appending one innocuous footer mentioning *"an unsatisfiable rung blocks a completion claim"* leaves
the step **green**. Verified here. A `## Completion` line inside a fenced code block also re-opens
the section, so quoted example prose satisfies a normative assertion.

So the earlier "mutation-proven" claim held for exactly the one literal mutation the first chain
used, and for nothing else. That is the same shape as the file-wide greps it replaced: an assertion
tuned to the example rather than to the property.

**CRITICAL — the disposition is a COUNT, and a count is not a fingerprint. My claim that the flag
"cannot be set-and-forgotten" is FALSE.** Reproduced here: with the red pair `{test, typecheck}`
dispositioned at `=2`, changing the subject so the red pair becomes `{build, test}` — a **different
set** — still exits 0 under the stale `=2`. A single `export` in a shell profile, CI block or
wrapper permanently blesses every same-sized case. Arm 3c only varied the count 1→2, which is
precisely the half the mechanism happens to catch, so the arm's own comment asserting the stronger
property is a false rationale I wrote and then cited as evidence.

**Both reviewers found the count defect independently.** That is the second independent convergence
of the day and the strongest signal available that it is real.

**What the second reviewer added, and it is the more important half.** The gate moves detection
earlier and **connects to nothing**: the count is compared and discarded, `--commands` writes no
event, the variable dies with the shell, and both branches of the stop message — "known-red
baseline" and "tooling that could not run" — share one exit, so nothing records which the operator
chose. §3 still has no unsatisfiable-rung condition and the report template still has no disposition
row. **So the 2026-09-09 outcome remains reachable even after the operator dispositions correctly.**

It also measured the friction: the named evaluation subject runs `1 pass, 3 ran and reported
failures` in-container, so this gate fires on every trial of it and mandates a second full run of a
pre-flight whose typecheck probe was measured at **1,464 s**. A guaranteed doubling is what pushes
an operator to export the variable permanently — the design creates the pressure that defeats it,
and the stop message hands over the bypass token pre-formatted.

**The recommended direction, which I did not invent and am recording as theirs:** key the
disposition to the IDENTITY of the red commands — a sorted rung list or a digest of `rung:exit`
pairs — rather than their cardinality; give the two branches two different outcomes; and persist the
answer as an event row and a template row, the way `--unassessable` and `--superseded` counts are
already carried into the report.

**Also confirmed by both, and worth keeping:** the gate does fire on the founding case, the three
mutations the second reviewer ran each take the step red, `--commands` still exits 0 on this
repository, and nothing in the repo calls `--commands` in a way this breaks. The direction is right.
The mechanism is not.


### Rebuilt on identity, 2026-09-20 — third attempt at this control

Both criticals from the second chain are addressed. **This has not been reviewed by a third chain**
and is not claimed to be correct; what follows is what was changed and what was proved.

**The disposition now carries IDENTITY and CLASSIFICATION, not cardinality.**

    KIT_COMMANDS_RED_DISPOSITIONED="build:101=baseline,test:101=unsatisfiable"

Each red rung is named with the exit code this run observed, in the loop's fixed order, so a stale
value cannot survive a change in which rung is red, in what it exited with, or in how many there
are. When it does not match, the stop prints both sides — *"the value supplied names X; this run
observed Y"* — so the operator sees what moved.

**The two branches are now two outcomes.** `=baseline` proceeds (exit 0). `=unsatisfiable` exits
**2**, distinct from the cannot-run stop's 1, so a caller can tell a VOID-shaped rung from an
answerable baseline. An entry carrying neither is refused: naming a rung is not deciding anything.

**The answer is persisted.** One `preflight-commands` event per run records both the observed red
set and the disposition given, so a later reader can audit what was blessed. Previously the
variable was compared, discarded, and died with the shell.

**Measured behaviour, re-run after the rebuild:**

| case | expected | got |
|---|---|---|
| two red, no disposition | STOP | `exit 1` |
| identity right, no `=class` | STOP | `exit 1` |
| `build:101=baseline,test:101=baseline` | pass | `exit 0` |
| **stale value naming a DIFFERENT red set** | **STOP** | `exit 1`, both sides printed |
| one entry `=unsatisfiable` | VOID-shaped | `exit 2` |

**THE `sec()` END ANCHOR IS FIXED AND ITS CEILING IS NOW STATED.** It closes on a heading of any
level and on `---`, not only on `## `. But a grep cannot tell normative prose from a footnote using
the same words, so the positive assertions are a tripwire rather than a proof. **The weight moved
to a negative assertion**: the pre-fix rule *"either satisfied or explicitly declared unavailable"*
must not reappear in `## Completion`. A footer cannot satisfy that, because adding words elsewhere
does not remove the sentence.

**Three mutation proofs, each isolating one mechanism:**

| mutation | caught by |
|---|---|
| `## Completion` reverted to two states **plus the See-also footer** — the exact bypass that defeated the previous fix | the negative assertion: *"has the two-state completion rule back verbatim"* |
| identity match downgraded to **cardinality only**, leaving arm 3 green | **arm 3d**: *"a stale disposition blessed a DIFFERENT red rung at the same count"* |
| the red gate disabled entirely | arm 3 |

The second one needed care: a coarser mutation broke arm 3 first, so arm 3d never ran and proved
nothing about itself. The surgical version leaves arm 3 passing and isolates arm 3d — recorded
because "the suite went red" is not the same claim as "this assertion can fail".

**What is NOT fixed, and is not claimed to be.** The gate still only moves detection earlier: §3
carries no unsatisfiable-rung condition and `docs/TRIALS/TEMPLATE.md` still has no disposition row,
both filed as majors. The stop still prints a pre-formatted value the operator can paste without
thinking, though it now forces a per-rung choice rather than a single number. And the friction the
second reviewer measured is unchanged — a subject with red commands still costs a second full
pre-flight run.


### Third chain's findings addressed, 2026-09-20 — and the prose check is demoted, not fixed

Third chain: **reject** and **revise**, 17 findings. It split cleanly, and the split decided what
to do.

**WHAT HELD, and it is the half that was rebuilt.** One reviewer ran a 15-value probe table against
the identity match on a live subject: wrong order, duplicates, an extra non-red rung, a green rung,
empty classification, wrong case, leading space, trailing text, and a rung red at a *different exit
code* — **all stop**. The count-to-identity rebuild genuinely closed the stale-value bypass. Arm
independence verified for all four arms, each reddening alone under a mutation isolating its own
mechanism, including the correction made after a coarse mutation had reddened arm 3 first.

**WHAT WAS DEFEATED, for the third time: the documentation assertion.** Two separate bypasses, both
verified here before being accepted:

- `sec()` set its flag on EVERY line equal to the heading, so a **duplicate `## Completion`** at EOF
  spliced a footer into the section and the attempt-2 bypass worked again with a heading in front
  of it.
- The negative grep was keyed to `"either satisfied or"` — **a literal the fix itself had deleted**.
  The current sentence reads *"is satisfied, or explicitly declared unavailable"*, so the grep
  returns zero against the live file and only ever fires on a verbatim historical revert. Dropping
  the single word *either* from a revert defeats it.

**THE JUDGEMENT: stop trying to prove this with greps.** The check asserts a SEMANTIC property with
a LEXICAL tool, and each fix moved the bypass one step sideways — file-wide, then section-anchored,
then any-heading-anchored plus a negative grep. Three attempts, three defeats, four reviewers. That
is the ceiling of the technique, not a run of bad luck.

So the step now **says so in its own comment**, the claim that the negative assertion carries the
weight is withdrawn, and the weight sits on the mechanical arms. Two cheap tightenings were kept
because they were genuinely broken: the heading must occur **exactly once** (a duplicate is now
itself the failure, which is easier to assert than the absence of its consequences), and `sec()`
never re-opens once closed. **A mutation that edits the normative text in place still passes, and
no grep will catch that** — recorded rather than left to be rediscovered a fourth time.

**The four mechanical fixes, each proved:**

| fix | proof |
|---|---|
| `sec()` duplicate-heading bypass | the exact attempt-3 bypass — reworded revert **plus** duplicate-heading footer — now fails on three counts, the duplicate assertion firing first |
| the event write had no check | deleting the write outright now reddens **arm 3g**: *"the disposition was not written to the event log"*. Arms also assert the payload names which rungs were red and what was decided, and that the log is still valid JSON |
| `exit 2` collided with not-a-repo, not-adopted and bad usage | **exit 3**, caught by arm 3e |
| suffix-glob accepted `rung:exit=unsatisfiable=baseline` as baseline | exactly one `=` per entry, counted; caught by arm 3f |

Also fixed: operator input is split on comma with globbing off, instead of being word-split and
glob-expanded against the working directory; and two assertions that both printed "arm 3b" now
print distinct labels.

**STILL OPEN AND NOT PATCHED, deliberately.** The stop prints a paste-ready all-`=baseline` value —
the exact classification the founding incident needed — so the gate forces a per-rung
*transcription* rather than a per-rung *judgement*. That is a design question about where judgement
lives, not a bug, and it stays filed. §3 still carries no unsatisfiable-rung condition though §6
cites it for one, and `docs/TRIALS/TEMPLATE.md` still contains the string "rung" zero times. **So a
trial can still reach COMPLETE**: the only thing between the founding scenario and that outcome is
one paragraph of prose an agent must choose to apply, which is what failed on 2026-09-09.


### Triage of the 7 criticals blocking trial 3, 2026-09-20 — six addressed, one is the ceiling

`kit-preflight.sh --criticals` refuses a trial while any critical is unfixed, and it counts
**distinct defects**, not rows. The seven it names are **all from this task's three T3 chains
today** — not, as first reported here, old findings from August. That first reading came from
`kit-resolve.sh --list`, which prints ROWS; the gate's own query excludes vindicated, superseded
and unassessable rows and collapses carried-over duplicates. **The two outputs answer different
questions and only one of them is the gate.**

**Six are addressed in merged code, verified against `main` rather than from memory:**

| defect | addressed by |
|---|---|
| `--commands` keyed cannot-run on 126/127 only (×3 rows, 2 defects) | the red-disposition gate — `RAN AND REPORTED FAILURES` |
| the disposition was a count, not a fingerprint | identity matching — `"$_gotids" != "$_want"` |
| conformance greps file-wide, satisfied by `## Satisfaction` | section anchoring |
| `sec()` had no end anchor | closes on any heading level and `---` |
| `sec()` re-opened on a duplicate heading | the heading must occur exactly once |

**The seventh is not fixed, and cannot be by this technique.** The negative assertion greps
`"either satisfied or"` — the PRE-FIX wording, which the fix itself deleted, so it matches nothing
in today's file and fires only on a byte-for-byte revert. Its comment claimed it was *"the one a
footer cannot satisfy"*, which the third chain refuted. **The comment is corrected here** rather
than left contradicting the demotion comment forty lines above it; the grep is kept as a cheap
tripwire for a literal restoration, labelled as exactly that.

**AND THAT EXPOSES A GAP IN THE RESOLUTION VOCABULARY.** `kit-resolve.sh` offers `--fixed`,
`--unassessable`, `--superseded` and `--false`. **None of them means "real, correctly reported, and
permanently beyond what this control can do."** The finding is not fixed — the grep still cannot
catch a reworded revert. It is not unassessable — it is perfectly legible. It is not superseded —
its subject is live. It is not false — it was true and remains true.

This is the same gap recorded for the 55 label-carrying findings under
`T-20260914-finding-run-ids-and-spend-run-ids-are-tw`, reached from the opposite direction. Marking
it `--fixed` to clear the gate would be the laundering this repository refuses; leaving it open
blocks every trial indefinitely over an accepted limit. **The disposition is the operator's and the
vocabulary does not currently have a word for it.**


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

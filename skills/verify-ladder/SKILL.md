---
name: verify-ladder
description: Determine which verification obligations apply at the declared tier, how each is satisfied in this project's stack, and what to do when a rung has no tooling. Use before claiming any work is complete.
---

# verify-ladder

The ladder states **obligations**, not commands. An obligation is portable across
stacks; a command is not. This is the seam that lets a technology accelerator be added
later without editing this skill.

## Obligations

| Rung | Obligation | From (T) |
|---|---|---|
| 1 | The change compiles and satisfies static analysis | T0 |
| 2 | Stated acceptance criteria are proven by tests that fail without the change | T1 |
| 3 | The **wiring** fails as designed, not just the parsers — integration points, error paths, timeouts | T2 |
| 4 | An adversarial reader has looked for what the tests cannot express: fail-open guards, races behind a green suite, comments whose rationale is false | T2 |
| 5 | A second reader, given no sight of the first's findings, has done the same | T3 |

Rung 5 is a **completeness control, not a correctness control**, and the difference decides
whether it is worth its cost. Measured on one T3 design: two reviewers, the second blind at
a commit predating the first's findings, both returned REJECT and shared roughly 70% of
findings. Same verdict either way — so as insurance against a wrong call it bought nothing.

The 30% that differed is what it bought. Only the security reader found an unpinned hash
whose ambiguous pre-image lets a same-tenant attacker poison a victim's cached answer. Only
the design reader found that the proposed port set had no invalidation method at all.
Neither list contained the other's.

So do not run rung 5 expecting a second opinion on the verdict. Run it expecting a
different half of the problem, and treat convergence on the verdict as normal rather than
as evidence the rung is redundant.

## Satisfaction

Read `.claude/project-profile.md` for `commands.*` and `ladder.*` keys. Never invoke a
tool this skill names itself — it names none deliberately.

A rung has exactly **three** dispositions and no fourth. Two of them let work complete. **This
section is their one home**: `docs/TRIAL-PROTOCOL.md` and `kit-preflight.sh --commands` cite it,
and restate nothing.

**1. Satisfied.** The declared command ran and passed -- or, where the command was already red
before the change, it ran and passed **against that baseline** (below). A comment is not a
declaration: `commands.build: # none` handed to a shell runs and exits 0, and it is disposition 2,
nothing declared, not a pass.

**2. Unavailable** — *nothing is declared for this stack.* Do not skip it silently. Declare it
unavailable, name the compensating control, and **raise the tier by one**. Less mechanical
verification means more adversarial reading, not a lower bar. A T3 change in a stack with no
mutation tooling gets more human and reviewer attention, not less.

**3. Unsatisfiable** — *a satisfaction IS declared and the command produces no verdict on the
changed code.* Either it does not run -- a missing build dependency, a platform the toolchain
does not support -- or it gives no complete verdict on a unit the change touches (step 1 below):
the unit was blocked, skipped, or still fails in a file the change did not touch. This is **not** unavailable: something was declared, so the clause above does
not reach it, and raising the tier is not the remedy because the rung was supposed to be
mechanical here and is not.

A trial's pre-flight can decide this before the clock: `kit-preflight.sh --commands` records a
rung the operator dispositions `rung:exit=unsatisfiable` as exactly this, and exits 3.

**`unsatisfiable` blocks a completion claim.** It is not a weaker satisfaction and there is no
tier that compensates for it: an unsatisfiable rung means the verification the tier assumed
did not happen, and nothing else in the ladder knows that.

Distinguish it from an ordinary failing check. `commands.typecheck` reporting errors in a file
YOUR change touches is the rung working -- fix the change. And distinguish it from a red
baseline: a command that was failing before you started, and still reaches your change, has a
verdict to give. That is the next paragraph, not this one.

**Against a recorded baseline** -- a mode of disposition 1, not a fourth disposition. When the
declared command was red before the change -- in a trial, pre-flight recorded the rung as
`rung:exit=baseline`; outside one, you ran the command on the unchanged tree first and kept its
output -- judge the rung in three steps, in order, and stop at the first that decides.

Every step reasons about **units**: the smallest thing the declared command itself reports a
whole result for -- a crate or build target, a package, a test binary. The tool names them; you
do not choose them. A unit has a **complete verdict** in a run when the command reports that it
built or passed, or reports its failures. A unit the command never got to -- skipped, or blocked
by a failure elsewhere -- has none.

1. **Did the AFTER run reach the change?** Every unit that contains a touched file must have a
   complete verdict in the run made after the change, from the declared command, and every one
   of its failures must be located in a touched file. **Any touched unit that fails in a file the
   diff does not touch, that did not build because something it depends on failed, or that the
   command skipped, has no verdict on the change: `unsatisfiable`.** One touched unit's result
   says nothing about another's, and the before run says nothing about the after run -- the
   change can stop the after run earlier than the baseline stopped. A test binary whose target
   did not build ran nothing. And a changed line that the command's configuration compiles out
   -- a feature, `cfg` or build tag the command does not enable -- was not reached even when its
   unit was; that is the one check here the tool does not report for you, so say which
   configuration the changed lines need and whether the command enables it.
2. **Is any failure in a touched file after the change?** Then the rung is working. Fix the
   change; the work is not complete. The failure's **primary** location decides; a note or
   secondary span pointing into a touched file does not move an error out of the file it is in.
3. **Otherwise the rung is satisfied against the baseline.** Every touched unit passed, so every
   remaining failure is in a unit the change does not touch. Sort each, with its cause, into one
   of three kinds:
   - **regression** -- the unit had a complete verdict BEFORE the change and passed, and now
     fails; or a test that ran and passed before and now fails or no longer runs. This is not a
     count to record and move past: **it blocks exactly as step 2 does -- fix the change**,
     wherever it lives;
   - **baseline** -- the same unit, file and error code or test name as the before run, and no
     more occurrences of it than before;
   - **unmasked** -- anything else, in a unit the before run never gave a complete verdict. It
     does not block. Hand the list to the rung 4 and rung 5 readers.

**The cost, stated rather than discovered:** a unit that was already failing before the change
and does not contain it can be broken further by the change, and that reads as unmasked. That is
why the unmasked list goes to rungs 4 and 5 and is recorded rather than waved through. And the
price of step 1 is deliberate: **a change inside a unit that does not build cannot be verified by
that unit's command.** Fix the unit's baseline first, or accept `unsatisfiable`. The stricter rule
-- no failure anywhere that the baseline did not have -- was refused on one observation: trial 3's
change left 7 errors of which 6 were not in the before run.

This decides whether the command's red result blocks. **It does not replace the rung's
obligation**: rung 2 still needs tests that fail without the change. A rung whose command runs but
whose configuration compiles the change out produces no step-1 evidence, so it is `unsatisfiable`
by default. Whether that state deserves its own name is
`T-20260923-the-ladder-has-no-disposition-for-a-rung`. Until that lands, only an operator's ruling,
recorded in the report next to the disposition, may record such a rung as anything else.

**Worked example, trial 3 (2026-09-23), rung 1.** `cargo check --workspace --all-features`,
pre-flight `=baseline`. The change touches three files in `highper-gateway/src/plugin/`, all in
the `highper-gateway` library crate. After the change that crate still fails: 7 errors, none in
touched files, all in `discovery/consul.rs` and `middleware/waf/aws_engine.rs` -- the same crate.
Step 1: the touched unit fails in files the diff does not touch, so it has no complete verdict:
**unsatisfiable**. Step 1 decides, so the lints the after run reports in touched files -- among
them `unused_mut` at `plugin/host_functions.rs:544`, an error under `clippy -D warnings`
(`D:/trials/trial3-target/check3.log`, `clippy.log`) -- are never reached. Under this rule trial 3
is VOID. It was recorded COMPLETE on 2026-09-23 by an operator ruling made before the rule existed,
and the record stands as that ruling.

**And the case this ladder exists for, 2026-09-09.** Rung 1 needed `protoc` and did not run:
**unsatisfiable**. Rung 2's `--lib` test target contains the touched `registry.rs` and failed to
build over `runtime/signals.rs`, a file the change did not touch: step 1, **unsatisfiable**,
whatever it reported about `registry.rs:77`. No route reaches complete.

> **Why this exists.** The 2026-09-09 highper-gateway trial hit it on two rungs at once.
> `commands.typecheck` failed everywhere — a Windows host died on jemalloc's autoconf, a
> container probe ran 1,464 s and died on a missing `protoc` — and `commands.test` was blocked
> because the `--lib` target did not compile before the trial began. Both had tooling declared,
> so neither was satisfied and neither was declarable unavailable. The enumeration had two
> names and the situation was a third. **The trial recorded COMPLETE, two reviewers passed the
> change at rungs 4 and 5, and it does not compile** — `registry.rs:77`, `error[E0597]`, on
> that trial's own commit. Rung 3, which genuinely had nothing declared, was declared
> unavailable and the tier raised correctly; that path is unchanged and still right.
>
> **And why the baseline paragraph exists.** The first version of disposition 3 read *"or cannot
> be made to pass for reasons outside the change"* and named *"a target that does not compile
> before you touched it"* as its example. That is every red-baseline subject, and
> `docs/TRIAL-PROTOCOL.md` §0 blesses trialling one -- so the two documents read one fact with
> opposite outcomes, and trial 3 could not write its outcome label without an operator ruling.
> What separates the cases is not whether the failure predates you. It is whether the command
> still reaches your change.

## Recording findings

Every finding gets recorded, including from reviewers you disagree with. A reviewer returns
**one JSON object** — `verdict`, `narrative`, `findings` — and you pipe that whole reply in
**unchanged**. Do not read it and retype the fields: that is parsing, it is where every defect
in the old path came from, and on 2026-08-10 it dropped `pattern` from every row of a review.

**Prefer the loop.** Reviewers ignore the output rule — across four live runs it was ignored
three times — and repairing a reply by hand is the step that stops happening on the day it
matters. `kit-review-record.sh` runs the reviewer, hands the validator's own diagnostics back
if the reply is refused, retries a bounded number of times, and records a `finding-gap` if the
reviewer never complies:

```sh
bash ${CLAUDE_PLUGIN_ROOT}/tooling/kit-review-record.sh \
  --task <task-id> --agent <agent> --max-attempts 3 \
  --prompt-file review-request.txt \
  --cmd '<command that reads a prompt on stdin and writes the reply to stdout>'
```

`--cmd` is the only place that knows how a reviewer is invoked here, so nothing about the
harness or the model leaks into the kit.

If you already have a reply in hand — **which is every review in plugin mode**, where a
reviewer is an Agent-tool subagent and there is no command that reads stdin and writes stdout —
record it through the same door the loop uses:

```sh
bash ${CLAUDE_PLUGIN_ROOT}/tooling/kit-review-record.sh \
  --task <task-id> --agent <agent> --agent-id <agent-id> --reply-file reviewer-reply.json
```

**`--agent-id` is the reviewer RUN and it is not optional in practice.** `--agent` is the role,
and a T3 chain runs three reviewers sharing one role and one task, so the role cannot answer
"what did *this* reviewer cost and what did it find" -- one question about one run, and one of
the two readings a trial exists to take. In plugin mode the value is the Agent-tool subagent's
id, the same one `kit-spend.sh` records from `<session>/subagents/agent-<id>.jsonl`; that is
what makes the two rows join.

**It is NOT the session id, and that is the mistake to expect.** The harness hands you the
session id, so it is the value nearest to hand; it covers every agent in the session and
therefore identifies no single run. Measured 2026-09-14 on the kit's own repository: **54 of 54
attributed findings joined nothing**, and five of those had been given the session id by a
session that had read this page. `kit-finding.sh` now says so at record time and names
which kind of wrong value it got -- but the advice is a warning, not a refusal, so a caller that
does not read it still records an unjoinable finding.

Omit it and the finding is still recorded -- losing a finding to a missing label would be the
worse trade -- but `kit-status.sh` reports it as unattributed rather than letting it read as
attributed. On the 2026-09-09 trial **all 11 findings** were recorded through this door while
all 3 reviewer spend rows carried an id, so not one finding could be traced to the reviewer
that produced it.


That validates the reply, records it, and **leaves a `finding-gap` if it is refused** — so a
review whose findings were rejected is still visible in the measurement. `kit-finding.sh --json`
still works and is what this calls, but it records nothing when it refuses, and a refused review
that leaves no row is the open circuit this whole path exists to close.

**What `--reply-file` cannot do is retry.** A correction restates the original request, and a
caller holding one finished reply has nothing to re-ask with. So in plugin mode the compliance
half is yours: read the diagnostics, ask the reviewer again, record its next reply. Across five
live rounds one model complied 3/3 and another 0/4, so expect to do this.

A reviewer that found nothing returns `{"findings": []}`, which records a `finding-gap` — an
empty review is a measurement, and it must not look like a review that never ran.

Rejection is **all-or-nothing**: one bad value and nothing is recorded, because a half-stored
review is a finding table that disagrees with the review it came from. The diagnostics name
every problem at once.

One finding at a time takes named flags: `--task --agent --class --severity --summary
[--lang] [--pattern] [--domain]`. `--summary` is required — without it the row is a bare
counter that cannot be told from any other. `kit-finding.sh --contract` prints the field list.
Both forms reject an unknown value rather than storing it, and a batch with any rejected row
exits non-zero — a partly recorded review is a measurement gap, and you are the only one
still holding the findings needed to fix it.

Do not memorise the vocabularies; print them:

```sh
bash ${CLAUDE_PLUGIN_ROOT}/tooling/kit-finding.sh --vocab
```

`class` and `lang` are the entire mechanism by which technology and industry accelerators
are later improved from real work rather than invented. A finding recorded without them is
a finding that teaches nothing.

## Completion

Work is complete when every obligation at the declared tier is **satisfied** -- against the
recorded baseline, where the command was red before the change -- or explicitly declared
**unavailable** with its tier raised. "I inspected it" satisfies no rung.

**An `unsatisfiable` rung blocks completion.** This section used to enumerate two states and
permit anything outside them by omission, which is how a trial reported COMPLETE over a change
that does not compile. There is no third way to complete: either the rung is made to run, or
the work is not complete and says so.

Inside a trial the remedy is narrower still, and it is why §0 of `docs/TRIAL-PROTOCOL.md`
proves every `commands.*` runs BEFORE the clock starts. Mid-trial, editing the profile to make
a rung run is a `commands.*` change, and §2 makes that void the trial — so a trial that
discovers an unsatisfiable rung after starting has no non-voiding move left. The outcome is
VOID, recorded as such. It is never COMPLETE.

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

A rung has exactly **three** dispositions and no fourth. Two of them let work complete.

**1. Satisfied.** The declared command ran and passed.

**2. Unavailable** — *nothing is declared for this stack.* Do not skip it silently. Declare it
unavailable, name the compensating control, and **raise the tier by one**. Less mechanical
verification means more adversarial reading, not a lower bar. A T3 change in a stack with no
mutation tooling gets more human and reviewer attention, not less.

**3. Unsatisfiable** — *a satisfaction IS declared and it does not run, or cannot be made to
pass for reasons outside the change.* This is **not** unavailable: something was declared, so
the clause above does not reach it, and raising the tier is not the remedy because the rung
was supposed to be mechanical here and is not.

**`unsatisfiable` blocks a completion claim.** It is not a weaker satisfaction and there is no
tier that compensates for it: an unsatisfiable rung means the verification the tier assumed
did not happen, and nothing else in the ladder knows that.

Distinguish it from an ordinary failing check. `commands.typecheck` reporting type errors in
YOUR change is the rung working — fix the change. `unsatisfiable` is the rung not working: a
missing build dependency, a platform the toolchain does not support, a target that does not
compile before you touched it.

> **Why this exists.** The 2026-09-09 highper-gateway trial hit it on two rungs at once.
> `commands.typecheck` failed everywhere — a Windows host died on jemalloc's autoconf, a
> container probe ran 1,464 s and died on a missing `protoc` — and `commands.test` was blocked
> because the `--lib` target did not compile before the trial began. Both had tooling declared,
> so neither was satisfied and neither was declarable unavailable. The enumeration had two
> names and the situation was a third. **The trial recorded COMPLETE, two reviewers passed the
> change at rungs 4 and 5, and it does not compile** — `registry.rs:77`, `error[E0597]`, on
> that trial's own commit. Rung 3, which genuinely had nothing declared, was declared
> unavailable and the tier raised correctly; that path is unchanged and still right.

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

Work is complete when every obligation at the declared tier is **satisfied**, or explicitly
declared **unavailable** with its tier raised. "I inspected it" satisfies no rung.

**An `unsatisfiable` rung blocks completion.** This section used to enumerate two states and
permit anything outside them by omission, which is how a trial reported COMPLETE over a change
that does not compile. There is no third way to complete: either the rung is made to run, or
the work is not complete and says so.

Inside a trial the remedy is narrower still, and it is why §0 of `docs/TRIAL-PROTOCOL.md`
proves every `commands.*` runs BEFORE the clock starts. Mid-trial, editing the profile to make
a rung run is a `commands.*` change, and §2 makes that void the trial — so a trial that
discovers an unsatisfiable rung after starting has no non-voiding move left. The outcome is
VOID, recorded as such. It is never COMPLETE.

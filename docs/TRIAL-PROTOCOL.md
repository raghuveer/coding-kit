<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial protocol

How to run the kit against a project it has never seen, so that two trials can be compared.

**This is a procedure, not a report.** You should be able to execute it without having read
`docs/MEASUREMENTS.md`. That document is the first trial's *results*, and it is cited here only
where a rule exists because something went wrong there.

The procedure is fixed **before** a trial, not reconstructed after it. A comparison assembled
afterwards from whatever each run happened to record is not a comparison.

**Revision 2, 2026-08-12.** Revision 1 was reviewed before first use and rejected with two
criticals — its isolation rule left `git push` pointed at the subject, and it mandated a figure
the kit does not emit while forbidding the only way to get it. Both are fixed below. The review
is the reason this document is usable, and the reason to run one again after the first trial.

---

## 0. Pre-flight

Stop unless every box is ticked. Record the answers; they are part of the result.

**The kit**

- [ ] Working tree clean, full conformance green, CI green on every platform.
- [ ] No unfixed critical anywhere in the backlog. **Computable — run it, do not judge it:**

          bash tooling/kit-preflight.sh --criticals

      **The rule is not written here.** It lived in this document AND in `kit-status.sh`, and a
      rule with two homes has been wrong twice: once filtering by task state, once excluding
      refutations too eagerly. The command is the single home; this box calls it.

      **Not filtered by task state.** An earlier revision read `AND t.state='progress'`, so a
      critical on a *done* task did not count — closing the task cleared the pre-flight exactly
      as well as fixing the defect, and two of this repository's own outstanding criticals were
      invisible to it. A gate you can satisfy by editing a status field is not a gate.

      **Refuted findings are excluded only when the refutation is unambiguous.**
      `kit-vindicate.sh` keys on `(task, class)` and marks every finding matching both, so on a
      task with two `fail-open` findings one `--false` about the harmless one also refutes the
      critical. It is retired only when it is the sole finding of its class on its task;
      otherwise it stays in the gate, unjudged rather than assumed innocent.

      Zero, or stop. `kit-status.sh` prints the same thing per task under **Outstanding
      criticals**, and `kit-resolve.sh --list --severity critical --unfixed` names them.
      An unmarked finding counts as OUTSTANDING: silence is not a fix.
- [ ] **The third state: unassessable criticals. Run it, and record the number.**

          bash tooling/kit-preflight.sh --unassessable

      **A zero from the box above does not mean there is nothing wrong.** `--criticals`
      deliberately excludes any finding the operator marked `--unassessable`, because those
      cannot be judged from what survives and leaving them in would make the gate permanently
      unsatisfiable — no trial could ever run. The cost is that a repository whose every
      remaining critical is unassessable reports **zero and passes**, with the blind spot
      intact. That is the state this box exists to make visible, and it is the exact shape the
      whole criticals chain was built to remove: **a pre-flight box that a third state silently
      satisfies.**
- [ ] **The fourth state: superseded criticals. Run it, and record the number.**

          bash tooling/kit-preflight.sh --superseded

      Same hole, one category over, and it opened the day the fourth disposition landed —
      `--criticals` excludes `superseded_at` too, so a repository whose every remaining critical
      criticised a withdrawn design reports **zero** and passes with nothing said. This
      repository was in precisely that state within minutes of the verb existing: the gate went
      to zero with **thirteen** excluded criticals behind it, nine unassessable and four
      superseded.

      **It is not the same blind spot and the two counts are not summed.** An unassessable
      critical is unreadable — nobody can say what it was, and that is a gap in the record. A
      superseded one is perfectly readable, **was real, and its subject was withdrawn, often
      because of it.** One is missing evidence; the other is evidence that did its job. Reporting
      them as one number would erase the most valuable thing a review produces.

      Non-zero is not a stop. It is a **figure the trial report carries**, next to the
      unassessable count, so "no unfixed critical outstanding" is read as what it is.

      **This is NOT a stop by itself.** An unassessable critical is a standing blind spot, not
      an unaddressed defect, and treating it as a stop would restore the unsatisfiable gate.
      Proceed — with the count recorded in §7's report, next to the kit SHA, where a reader
      comparing two trials can see it. A trial run over a known blind spot is a valid trial that
      says so; a trial run over one it never mentioned is not.

      **Three things that ARE stops**, and they are judgement rather than exit codes:

      1. **An unassessable critical on a task this trial will exercise.** The blind spot is then
         inside the path being measured, and any finding the trial produces there cannot be told
         from the one nobody could judge. Check the `task_id` column the command prints against
         the trial's scope.
      2. **The count went UP since the last trial.** These are meant to be a bounded historical
         set — findings that predate the summary column. A new one means something is producing
         unjudgeable findings *now*, which is a recording-discipline failure and a worse problem
         than the nine. Compare against the previous report; §6 requires both to carry it.
      3. **Any of them carries no reason.** `--reason` is required by `kit-resolve.sh` precisely
         because a mark that clears a gate without saying why is the laundering the gate exists
         to prevent. If the command prints `(no reason recorded)`, the record was written around
         the tool and the mark cannot be trusted.

      > Why a whole box for a number that is usually small: the criticals box above was written
      > with no way to evaluate it, and its first execution hit that on the very first line. This
      > one is the same failure caught one layer up — the box became evaluable, and the answer it
      > returns stopped covering the whole question the moment `--unassessable` existed. Serves
      > AC5 of `T-20260813-nine-criticals-predate-summary-and-canno`.

      > Revision 2 wrote this box with no way to evaluate it. The `finding` table had no column
      > for whether a finding was addressed — `vindicated` says whether it was *real*, a
      > different question — so the first execution of this protocol hit the very first box,
      > got 16 including findings fixed hours earlier, and overrode it. That is the honest
      > outcome and it is also proof a gate nobody can evaluate is worse than none: it launders
      > "we ignored it" into "we checked". Three review rounds on this document did not find
      > that. Running the first checkbox did.
- [ ] `git rev-parse HEAD` recorded. The SHA is the kit version, not the tag.

**The instruments** — an unmeasured trial is worse than none, because it looks like a result.

- [ ] **Spend capture is live.** Run one throwaway agent, then:

          bash tooling/kit-preflight.sh --spend

      A failure here means **the entire cost half of the trial will be empty**. Not
      hypothetical: this repository recorded **0 spend rows across 12 days** of heavy use, and
      `kit-status.sh` skips the cost section silently when the table is empty, so nothing
      announced it.

      > This box used to read `sqlite3 .project/index.db "SELECT COUNT(*) FROM spend;"` with no
      > rebuild, which made it **say STOP to a working kit**. Hooks append to
      > `.project/events.ndjson`; `spend` rows exist only once `kit-index.sh` has derived them,
      > so querying the index straight after the agent finishes reads whatever the last rebuild
      > happened to contain — normally zero. A live recorder failing a check written to detect a
      > dead one is the same class of defect as the gate that could not be evaluated, and it was
      > found the same way: by running it. The command above asks the event log first, so "the
      > hook never fired" and "the hook fired and nothing derived it" report as the different
      > faults they are.
- [ ] **Findings capture is live.** Run one reviewer through `kit-review-record.sh` and confirm
      a row lands. A review that records nothing is indistinguishable from a review that found
      nothing (§3).
- [ ] `kit-index.sh` and `kit-status.sh` both run clean on the copy.

**The subject**

- [ ] **The subject copy has NO REMOTE.** Not "a copy or a clone with its remote removed" —
      that phrasing was the hole. A `cp -r` copy carries `.git/config` verbatim, so it keeps
      `origin` pointed at the subject, and §4's removal procedure began with `git clone` and so
      covered only the other path. The rule is a property of the copy, not of how you made it,
      and it is checked the same way either way:

          bash tooling/kit-preflight.sh --isolated <copy>

      Zero, or stop. §4 has the reasoning and the same check.

      **It now checks a third path, and the third one is not git.** A clone brings the subject's
      `.claude/settings.*` with it when the subject tracks them. On 2026-09-11 the copy prepared
      for the highper-gateway trial carried `Bash(git *)` and seven entries naming a second
      checkout of the same subject outside the copy — and `--isolated` printed *"isolated"* and
      exited 0. A pre-approved `git *` routes around the removed remote entirely, because it
      never needs the copy's remote.

      **What it still cannot see, stated so nobody reads the pass as more than it is:** a
      permission rule is not a sandbox. A command that is *prompted* can still be approved by a
      human mid-trial, and no check can prevent that — §4's guard discussion is the other half.
- [ ] **Baseline recorded before the kit touches anything**, and recorded with **causes**: one
      row per check — command, exit, seconds, and for every failure the error codes or advisory
      ids that produced it. A subject whose tests already fail is a valid trial subject, but only
      if you knew that first, and only if you knew WHY — otherwise the kit gets blamed for it,
      or a later run cannot tell an old failure from a new one. A red rung recorded here is
      judged later **against this baseline** — see the ladder's `## Satisfaction` — so the
      causes are what that judgement reads, not decoration. **Keep each red command's full
      output and the tool's unit list**, not only the error codes: the ladder sorts failures
      after the change by which units passed before, which tests ran, and how many times each
      error occurred, and none of that can be recovered afterwards.

      **`build pass/fail, tests pass/fail` is not a baseline, and this is measured rather than
      asserted.** On 2026-09-09 that shape recorded one subject as red; a later reading found
      the release build **passed** and three CI jobs failing for three unrelated reasons. One
      job's cause stood in for four, and the aggregate word is what got quoted afterwards.

      **Where the subject has its own CI, record each job's verdict separately**, and use the
      commands that CI runs rather than ones invented for the trial. Where they differ, say
      which was used: a narrower feature set or a single package gives a different answer to
      "is this subject green", and the report must name the one it means.

      **A cause you did not verify is written `unverified`, by name, wherever it appears.** The
      2026-09-09 notes flagged their inference honestly and the record above them did not — and
      the record is what gets read. An unverified cause repeated in a later section as
      established is how a guess becomes a fact.
- [ ] **The runtime is built and its digest recorded**, for any subject whose toolchain is not
      already on the host — which is every subject the host does not develop in natively.

          nerdctl build -t cck-trial docs/trial-runtime
          nerdctl image inspect cck-trial --format '{{index .RepoDigests 0}}'

      `docs/trial-runtime/Dockerfile` is the definition, and every package in it was read from
      the subject's own manifest rather than guessed. **The tag is not the identity** — record
      the digest, with `uname -srm` from inside the container, as §2's *Record every time* table
      requires. Two trials naming one tag over different digests are not comparable.

      **What runs where, stated once so it is not re-derived per trial:**

      - the **subject's toolchain** runs in the container — that is the whole point, and it is
        what keeps a Linux-first subject off a Windows host's build path;
      - the **subject is mounted read-only** and the build target sent to `/tmp`. §3 lists a
        dirty subject tree as a VOID condition, so a run that left `target/` behind would void
        the next trial before it started;
      - the **kit** needs only `bash`, `git` and `sqlite3`, which adoption already implies. It
        is not the subject's toolchain and does not need the container to exist.
- [ ] **Every declared `commands.*` actually RUNS, before the clock starts.**

          bash tooling/kit-preflight.sh --commands

      **Run it wherever the commands are meant to run.** If the box above built a runtime, that
      is inside the container, not on the host — a Linux-first subject's `commands.typecheck`
      failing on a Windows host is the runtime being wrong, not the rung being unsatisfiable,
      and running this check in the wrong place would report exactly the state it exists to
      catch. Run it **in the subject copy**, never in the subject itself.

      **What each result MEANS is the ladder's to say, not this box's.** The dispositions have
      one home, `skills/verify-ladder/SKILL.md` `## Satisfaction`. This box only asks the
      question before the clock, and it has three results:

      - a declared command that **cannot run** (the shell's 126/127) stops, exit 1. Fix it here;
      - a declared command that **ran and reported failures** stops, exit 1, until each red rung
        is dispositioned by name and exit code:

            KIT_COMMANDS_RED_DISPOSITIONED="test:101=baseline,lint:101=unsatisfiable" \
              bash tooling/kit-preflight.sh --commands

        `=baseline` says *this was red before the kit, and I know why* -- the baseline box above --
        and the ladder judges that rung after the change against it. `=unsatisfiable` is the
        ladder's disposition 3 decided now; it exits **3**, and a trial that proceeds is VOID (§3);
      - nothing declared is *unavailable*, reported, and not a stop -- the ladder raises the tier.

      Each run writes one `preflight-commands` event naming the red rungs and the dispositions
      given, so the answer outlives the shell that gave it.

      **This box exists because a trial had no move left without it.** On 2026-09-09 rung 1's
      `commands.typecheck` turned out to need `protoc`, discovered after the clock started. The
      only remedy is a `commands.*` edit, which §2 makes void the trial — so the trial could
      neither satisfy the rung, nor declare it unavailable (something *was* declared), nor fix
      it without voiding itself. It reported COMPLETE over a change that does not compile.
      Asked here, the answer costs a pre-flight; asked later, it costs the trial.

      **A comment is not a declaration** -- the ladder's disposition 1 says why. The check
      separates the two rather than executing the value blindly.
- [ ] The subject's owner has agreed, if that is not you.

**The trial**

- [ ] **The question is written down.** "Try the kit on X" is not a question. "Does the
      co-change graph produce a usable ordering on a repo with four years of history" is.
- [ ] **Time-box stated**, in hours, before starting.
- [ ] **Stop rules stated.** Stop and record what you have when: the time-box expires; the same
      kit defect blocks progress three times; or any VOID condition (§3) is hit.
- [ ] **Abort path stated.** If the kit crashes or corrupts state mid-trial, the trial is
      recorded as aborted at that point with the cause — it is never silently restarted, because
      a restarted trial has a contaminated index and is no longer comparable.

---

## 1. The unit

**Billing-weighted input-token-equivalents (BTE).** One number, four counters:

    input×1 + cache-write×1.25 + cache-read×0.1 + output×5

**Never retype those weights.** They have one home — `BTE=` in `tooling/kit-status.sh` — and a
conformance step asserts this document still agrees with it. Read them from that home:

```sh
W=$(sed -n 's/^BTE="(\(.*\))"/\1/p' tooling/kit-status.sh)
```

**What the kit emits, and what it does not.** `kit-status.sh` reports BTE grouped by **tier,
scope, provenance and model**. It does **not** emit a per-agent figure. Revision 1 mandated
per-agent BTE anyway, which made two of its own rules jointly unsatisfiable. The `spend` table
does carry an `agent` column, so the number is one query away — and this form takes the weights
from their one home rather than duplicating them:

```sh
sqlite3 -column .project/index.db "
  SELECT COALESCE(NULLIF(s.agent,''),'(main loop)') AS agent,
         COUNT(*) AS transcripts, SUM($W)/100000 AS kBTE
    FROM spend s GROUP BY 1 ORDER BY 3 DESC;"
```

**Where the counters come from.** `kit-spend.sh` writes them from the `SubagentStop` and `Stop`
hooks — nobody types it, which is why §0 checks the hooks are live rather than trusting them.
Its `--transcript` flag is the manual door if you are reconstructing a run after the fact.

**Do NOT use the harness's per-agent completion summary.**
That figure is each agent's **final context size**, not its cost.
Reconciled across a 105-subagent run it matched summed last-context to 0.012% while differing
from actual output work by **5–215×**. It is a fair measure of context carried and a worthless
measure of money. The first trial's headline table is in that wrong unit and says so; do not
reproduce the mistake by copying its shape.

**Record raw counters alongside the weighted total.** Weights are a pricing assumption and
pricing changes; raw counters can be re-weighted later, a weighted total cannot be undone.

---

## 2. Constant, varied, recorded

### Constant WITHIN a trial

Changing any of these mid-trial voids it: the kit SHA, the agent set and each agent's
capability, the profile (`tier.rule`, `commands.*`, `ingest.*`, `accelerator.*`), and whether
accelerators are loaded.

`commands.*` and `tier.rule` must be **authored per subject** — a Rust monorepo has different
test commands from a TypeScript one. Author them during pre-flight, record them verbatim in the
report, and do not touch them again once the trial starts.

### Constant ACROSS trials — the part that makes comparison legitimate

This is the section revision 1 was missing entirely, and without it the document fixed a
procedure that produced incomparable results.

| Must match across compared trials | Why |
|---|---|
| the BTE definition | a different unit is a different measurement |
| the runtime | a trial on the subject's own OS and one on the host measure different things; trial 1's findings included carriage returns and host paths, which are facts about Windows |
| the agent set and capabilities | the cost question is about these agents |
| the tier vocabulary and floors' *shape* | floors differ per subject; the ladder must not |
| what counts as an escape | the escape rate is otherwise not one number |
| the report template (§7) | a figure not in both reports cannot be compared |

**The kit SHA will differ between trials, and that is unavoidable** — §7 requires filing and
fixing the defects each trial finds. So "vary one thing per trial" is false as stated, and
revision 1 stated it. The honest rule: **the subject is the variable; the kit moves anyway.**
Record both SHAs and diff them, and when a figure moves, say plainly that either the subject or
the kit could account for it. A two-trial difference is a hypothesis, not a finding.

#### WALL-CLOCK IS NOT COMPARABLE ACROSS MACHINES, and on this one it is not a measurement of the kit

Record the **machine's process-creation latency** beside any wall-clock figure, because on the
development machine it dominates everything else. Measured 2026-08-22:

    $sw=[Diagnostics.Stopwatch]::StartNew()
    for($i=0;$i -lt 50;$i++){ Start-Process cmd.exe -ArgumentList '/c','exit' -NoNewWindow -Wait }
    $sw.Stop(); "{0:N0} ms per spawn" -f ($sw.Elapsed.TotalMilliseconds/50)

**1,015 ms per process creation.** A healthy machine is 10–30 ms. The consequence is arithmetic
rather than opinion: a minimal three-task fixture costs ~61 spawns and takes **25 seconds** to
index, the suite performs **90 index builds**, and that is essentially its entire runtime — about
an hour locally against **43 seconds** for the same suite on ubuntu in CI.

**It does not parallelise.** 160 spawns took 65 s sequentially and 56 s across eight concurrent
workers — 1.16×, not 8×, on sixteen idle cores, with `sys` time *rising*. Process creation is
serialised at roughly 2.5/sec however many ask, so neither `xargs -P` nor more cores helps.

**Four causes were tested and refuted**, each by measurement rather than argument:

| hypothesis | result |
|---|---|
| Defender path exclusions | 80 s vs 79 s |
| Overwolf process hooks | 76 s vs 79 s |
| msys `fork` emulation | PowerShell → `cmd.exe` is *slower* still |
| Defender real-time protection **off** | **1,016 ms vs 1,015 ms** |

`fltmc filters` lists only Microsoft drivers — no third-party endpoint, backup or sync filter.
The cause is unidentified and is tracked as its own task.

**What this means for a trial report.** Any duration measured on that machine describes the
machine, not the kit. State the spawn latency beside it, or report API time and token counts and
mark wall-clock UNAVAILABLE — the same honesty §7 requires of a missing cost figure. Two trials
run on different machines cannot have their wall-clock compared at all, and the fd trial's
"six seconds" for co-change was measured before any of this was known.

#### A CONTAINER MOVES THIS NUMBER, so it is part of the runtime rather than of the machine

The 1,015 ms figure is a property of process creation on the Windows host. Running the kit
inside a Linux container on the same machine is a different runtime with a different spawn cost,
so the latency above is **not transferable** between them -- which is exactly why the runtime is
recorded rather than assumed, and why a containerised trial may not be wall-clock-compared
against a host-run one.

Measure it where the kit actually ran, and record it beside the wall-clock figure:

    # inside the runtime under test
    s=$(date +%s%N); i=0; while [ $i -lt 50 ]; do /bin/true; i=$((i+1)); done
    e=$(date +%s%N); echo "$(( (e-s)/50000000 )) ms per spawn"

**This does not make a containerised figure comparable to a host one.** It makes the difference
visible instead of silently attributing a machine's cost to the kit -- the same failure §2
already records for the fd trial.

### Record every time

| | |
|---|---|
| kit commit SHA | the exact tree that ran, both trials when comparing |
| runtime | `uname -srm` from where the kit actually ran, plus the container image digest if any, plus the host OS. Prose does not compare; `6.6.87.2-microsoft-standard-WSL2` and an image digest do |
| subject | language mix, size, commit count, age of history |
| greenfield or brownfield | and whether history was truncated |
| BTE by tier / scope / provenance / model | what `kit-status.sh` emits |
| BTE by agent | the query in §1 |
| raw counters | so the weighting can be redone |
| verdict per reviewer | and whether a second was genuinely blind (§3) |
| findings per agent | class, severity, summary, via `kit-review-record.sh` |
| findings **rejected** by the recorder | the `finding-gap` rows, with reasons |
| escape rate by tier | over both provenance populations |
| wall-clock and API time | separately |
| **n** | on every figure, in the figure |

#### Three disciplines the 2026-09-09 trial had to correct mid-run

Not VOID conditions — §3's bar is *no result*, and each of these was caught and corrected while
the trial was still running, by the trialist rather than by a reader afterwards. They are here
because the next trialist will not remember them unprompted.

**Probe side effects inside the copy.** `cargo` rewrote `Cargo.lock`, and `nerdctl -v name:/path`
bind-mounted cwd-relative host directories — 2.2 GB of them — instead of named volumes. Run
`git status --short` before every `kit-index.sh`: a non-empty tree means the index you are about
to read is not the one you think. The 2026-09-09 session did exactly this and it caught both.

**Every timestamp comes from `date -u` in the same command that makes the observation.** Estimated
stamps on that trial ran ahead of the clock and had to be corrected at 13:44:22Z. A recorded time
that was guessed is not evidence, and it is indistinguishable from one that was measured.

**Do not spend the free oracle before the run.** The subject's baseline holds defects the kit has
not been told about, and each one is a chance to observe whether the kit finds it independently —
which is the only unpaid signal a trial gets. On 2026-09-09 the reviewer prompts carried the
`signals.rs` compile failure straight out of the baseline section, so the kit was never given the
chance and the record cannot say whether it would have taken it.

**This one has no mechanical detection, and that is stated rather than papered over.** §3 refuses
conditions nobody can check, and a real check here needs the reviewer prompts kept as evidence and
compared against the baseline facts — nothing currently captures them. Until something does, the
discipline is: reviewer prompts carry no baseline defect, or the report lists every baseline fact
that was supplied to an agent, by name.


**Tool-use counts are not currently obtainable.** Revision 1 asked for them and asserted a
five-use threshold, and no tool in the kit counts tool uses. If your harness reports them,
record them and say which harness; otherwise record that they were unavailable rather than
leaving a column that looks unmeasured.

---

## 3. What makes a trial VOID — and how to detect each

Each of these produced a wrong answer on a real run. A trial that hits one is not a weak
result — it is **no result**. Revision 1 stated the conditions without saying how to notice
them, which made three of five undetectable in practice.

**Nine conditions as of 2026-09-20.** Six were found by 2026-09-09; the seventh — a reading
taken inside the session — was written up on 2026-09-12 from that same trial. The eighth was
already written in §2 and never carried here, which is the gap described below. **The ninth was
cited by §6 and by the ladder as living here, and did not exist at all** — a condition asserted to
be a control by two other documents, with nothing behind it.

**One of them differs from all the others in a way worth naming.** The rest leave a trace a
suspicious reader can find: a path outside the worktree, a dirty tree, a denial in a tool log,
a `rejected` gap row, a spend row older than the session, a commit touching the profile.
**A structurally blind review leaves none.** It is well-formed, confidently worded, and complete on its face; the only thing wrong
with it is what it was never shown. So it is the one condition that must be checked *before*
the review rather than doubted afterwards.

| Condition | Detection you can actually run |
|---|---|
| **A worktree path in a prompt does not isolate a subagent.** Both agents in one comparison found and read the live repository; one said so and reviewed that instead. | Grep the agent's own reply and tool log for paths outside the worktree root. If the harness does not expose a tool log, a blind comparison cannot be validated — say so and do not claim one. |
| **Registering a finding contaminates every later blind run.** | `sqlite3 … "SELECT COUNT(*) FROM finding WHERE at < '<worktree commit date>'"` — the worktree must predate every row you are hiding. |
| **Reindexing before committing** showed `T2 0/8` and nearly produced a report that the escape mechanism was broken. | Run `git status --short` before `kit-index.sh`; a non-empty tree means the index you are about to read is early. |
| **A permission denial inside a subagent degrades into a partial read.** | Check the tool log for denials. An agent that discloses one is salvageable; assume an undisclosed denial happened if its tool count is far below its peers on the same task. |
| **A per-file review is STRUCTURALLY BLIND to a defect whose halves live in different files.** Proved 2026-09-09: a reviewer was given `tooling/kit-guard.sh` and a ground-truth check asked whether it found the documented gap that the guard matcher omits `Bash`. It returned **zero** -- and could not have returned anything else, because the matcher is in `hooks/hooks.json` and the reviewer was handed only the script. Unlike every row above, this one produces a **confident, well-formed, complete-looking review**: 7 findings, 7/7 valid vocabulary, no correction loop. Nothing about the output says it was blind. | Before believing a review of `F` found nothing of a class, list what could hold the other half:<br><br>`git grep -lF "$(basename F)" -- . ':!docs' ':!.project' ':!*.md' \| grep -v "^F$"`<br><br>Every file that NAMES `F` is a place a defect about `F` can be half-written. On `kit-guard.sh` this returns 6 files and `hooks/hooks.json` is one of them. Either include them in the prompt, or record them in **Not exercised** by name. The unfiltered form returns 24 here and is unusable, which is why the pathspecs are part of the check rather than an optimisation. |
| **A reviewer that returns nothing may not have reviewed nothing.** An empty `{"findings":[]}` records as `reason=empty` — *"looked and found nothing"*. | `sqlite3 .project/index.db "SELECT json_extract(payload,'$.reason') AS reason, COUNT(*) FROM event WHERE kind='finding-gap' GROUP BY 1"`. Any `rejected` row is a review whose findings were lost. Confirm the reviewer received a prompt before believing any zero. |
| **The profile changed mid-trial.** §2 has said since revision 1 that changing `tier.rule`, `commands.*`, `ingest.*` or `accelerator.*` mid-trial voids it. **It was never carried into this section, and it is the only condition on this list that has actually fired.** On 2026-09-09 rung 1 needed `protoc` added to the wrapper to run at all; that is a `commands.*` change, so the only route to a green rung voided the trial. The trial reasoned it out and stopped, correctly — and then reported COMPLETE anyway, because the ladder had no name for the rung it left behind. | Record the profile's commit at §0 and compare at the end:<br><br>`git -C <subject> log --oneline <preflight-sha>..HEAD -- .claude/project-profile.md`<br><br>Any output is a mid-trial profile change and the trial is void. Empty is a pass. Verified runnable: it returns nothing on an unchanged profile and the file's own path comes from `paths.*`, so it follows an adopter who moved it. |
| **A rung was declared UNSATISFIABLE and the trial continued.** §6 and the ladder's `## Completion` both say a trial with any unsatisfiable rung is VOID, never COMPLETE, and both cited THIS SECTION for it — which carried no such condition until now. That dangling reference was found by two reviewers independently on 2026-09-20, and it is the live half of the 2026-09-09 failure: rungs 1 and 2 had tooling declared that could not run, the ladder had no name for that state, and the trial reported COMPLETE over a change that does not compile. **The eighth condition above detects the REMEDY — a mid-trial profile edit — not the FAULT.** | `kit-preflight.sh --commands` exits **3** when the operator dispositions any red rung `=unsatisfiable`, and writes what was decided:<br><br>`grep -h '"kind":"preflight-commands"' <subject>/.project/events.ndjson | grep -c '=unsatisfiable'`<br><br>Non-zero is a rung the operator ruled unsatisfiable, and the trial is void. **Zero is a pass ONLY if the file exists and pre-flight ran** — an absent file and an unrun pre-flight both print zero, which is the "a question that could not be asked is not a pass" rule this document applies elsewhere. Check `kit-preflight.sh --commands; echo $?` is 0 or 3 before reading the count.<br><br>**That detects the rung ruled unsatisfiable BEFORE the clock only.** The ladder also reaches unsatisfiable AFTER it -- step 1 of judging against a baseline, when a touched unit has no complete verdict -- and that writes no event. It is carried by the report's per-rung table, whose Disposition cell starts with the disposition word (`docs/TRIALS/TEMPLATE.md`):<br><br>`awk -F'\174' '/^## Rung dispositions/{f=1;next} f&&/^## /{f=0} f{r=$2;gsub(/[*\140 ]/,"",r);if(r!~/^[1-5]$/)next;d=tolower($(NF-1));gsub(/[*\140_ ]/,"",d);if(d=="")next;if(d~/^unsatisfiable/)u++;else if(d!~/^(satisfied|unavailable)/)o++} END{print u+0, o+0}' <record>`<br><br>It prints two numbers. **A non-zero first number is a VOID trial whatever the outcome row says.** A non-zero second number is a rung whose disposition is not one of the ladder's words -- the record must cite the ruling that allowed it (trial 3's `baseline-blocked` is one), or it is read as VOID too. It reads the first word of the LAST cell, after stripping bold, italics and backticks, so instruction text and a phrase like "no rung unsatisfiable" cannot trip it and a pipe in the Command cell cannot shift it. A pipe inside the disposition cell itself still would. |
| **A reading taken inside the session omits the turn that produced it.** Main-loop spend is written at each `Stop`, so a status read mid-session reports the PREVIOUS turn's row. Measured 2026-09-09: 6,902.9 kBTE read against 10,259.6 actually spent — a third of the cost missing from the headline figure. | After the session closes, the index's `spend.at` for the main transcript must equal the last `spend` event for it in `events.ndjson`:<br><br>`sqlite3 .project/index.db "SELECT MAX(at) FROM spend WHERE scope='main';"` against `grep -o '"kind":"spend","at":"[^"]*"' .project/events.ndjson | tail -1`<br><br>If they differ, reindex before reading anything. Verified runnable against this repository. |

**The last detection was itself undetectable, and that is a fourth instance of this section's
own failure.** It read `SELECT reason, COUNT(*) FROM … kind='finding-gap'`, with a literal
ellipsis where the table and `WHERE` belong — the row above it elides only the database path, so
the shape read as complete. Nobody could run it. Completing it the obvious way then fails:
`reason` is **not a column**, it lives inside `payload`, and `FROM event` returns
`Parse error: no such column: reason`. So the one check that catches a **lost review** has never
been runnable, in a section whose whole premise is that a condition without a detection is not a
control. Corrected above and verified against this repository: it returns `empty|2` here — two
gaps, both `empty`, **no `rejected` rows**, so no review has in fact been lost to date.

**A VOID trial is still recorded** — as `docs/TRIALS/<date>-<subject>-VOID.md`, naming the
condition hit and what had been established before it. Discarding it silently is the same
failure as an unrecorded empty review: the next person repeats it.

---

## 4. Isolation — what a trial must not do to the subject

The subject projects are real work. The operator's condition, and it decides the method rather
than qualifying it: **do not destabilise them.**

**The copy must have no path back.** Revision 1 said "a copy or a read-only clone" and was
rejected on it: `git clone` leaves `origin` pointing at the subject, and `git push` is a **Bash**
invocation, which the guard hook does not match (below). Do this instead:

```sh
git clone --no-hardlinks <subject> <copy>
cd <copy>
git remote remove origin
```

`--no-hardlinks` because a hardlinked object store shares files with the subject.

**Then verify the PROPERTY, not the procedure.** Revision 2 fixed the clone path and left the
copy path open: the removal block above starts with `git clone`, while §0 still permitted "a
COPY", and `cp -r` duplicates `.git/config` with `origin` intact. A rule about how you made the
copy cannot be checked afterwards; a rule about what is true of it can. One command, whichever
route you took:

```sh
bash tooling/kit-preflight.sh --isolated <copy>
```

It exits non-zero if the copy has any remote, is not a git repository at all, or still shares an
object store with the subject via `alternates` — the hardlink case wearing a different hat. Run
it after making the copy and before any agent runs. **That command is the control; the intention
is not.**

**What is enforced and what is not.** `hooks/hooks.json` matches `Write|Edit|NotebookEdit`, so
the guard blocks those outside the project root. **It does not see Bash at all** — no `git push`,
no `rm`, no redirect. So non-destructiveness is a procedure *you* enforce; the removed remote is
what makes the procedure hold when the guard cannot.

**This is not hypothetical, and the rule above predicted it.** On 2026-09-09 a session wrote logs
and reply extracts to the harness scratchpad *after* `kit-guard` refused a `Write` there — the
guard did its job, and `Bash` walked around it, exactly as the paragraph above says it can. The
breach was self-reported at 14:05:06Z; nothing would otherwise have found it. So: the opening
prompt names a temp location INSIDE the copy — the gitignored `.project/` — and at copy-back you
list every file the transcript wrote outside the copy root. A guard that cannot see the most
common tool is a guard whose coverage has to be checked by hand.

**Hooks go in the copy, never the subject.** Revision 1 banned hooks in the subject while
requiring every metric that `kit-init.sh` produces, and `kit-init.sh` installs `commit-msg` and
`pre-push` and edits `.gitignore` — so the document forbade what it required. The resolution is
that **the copy is not the subject**: run `kit-init.sh` there and let it install whatever it
installs. Nothing is ever installed into the subject.

**Everything the trial produces for the subject is a proposal** — files for review, never
applied, never pushed.

---

## 5. Attribution

A trial that cannot separate kit work from other work produces numbers nobody can interpret
later.

- Every task the trial touches carries `kit`, `agent`, `manual`, or `unknown`.
- **`unknown` is the honest default** for pre-existing work and is load-bearing on brownfield,
  where most of the backlog predates adoption. Recording it is not a failure; guessing is.
- **Back-fill uses the lowercase `via:` frontmatter key.** `Via:` is the git trailer and a
  commit already written cannot gain one.
- **Precedence: a `Via:` trailer beats the frontmatter `via:`.** The derivation takes the last
  `via` event by sequence and falls back to frontmatter only when there is none — so a
  back-filled value is silently overridden by any later trailer on that task. If you back-fill
  and then commit against the same task, state which value you intended.
- Provenance is set by the operator, never by the agent that did the work.
- **Run one task at a time.** Spend attribution binds a transcript to the task whose transition
  follows it; with two tasks in flight it can bind to the wrong one, and the resulting cost
  figures are wrong in a way nothing detects afterwards.
- Report escape rate over **both** populations. If `via:kit` has no denominator, the report says
  so — zeroes shaped like a rate are not a result.

---

## 6. Reporting

**State n on every figure**, next to the number, not in a preamble. A figure whose n is
elsewhere gets quoted without it.

**Never generalise across subjects without saying so.** One greenfield TypeScript run is not a
rate card for a polyglot Rust monorepo.

**Every number in the report needs a source.** Revision 1 asserted a five-tool-use threshold and
a "4× divergence" between wall-clock and API time, neither with a derivation or an n — breaking
this document's own rule three sections later. If a number came from one session, say so and
give the n; if it came from nowhere, delete it.

**Report what was NOT exercised.** The first trial's most useful section lists what it never
touched. An untested component named as untested is information; one omitted reads as fine.

**Carry the unassessable count, and the previous trial's, in the header.** Both, side by side —
the number alone says how large the blind spot is, and only the pair says whether it is growing.
§0's third stop condition is unevaluable without the previous figure, so a report that omits it
disarms a control in the *next* trial rather than its own.

**Separate three kinds of finding**, because they have different lifetimes:

1. defects **in the kit** → tasks here
2. defects **in the subject** → the subject owner's, delivered as a proposal
3. **methodology** failures → §3 of this document

**Disputed findings.** Where the subject's owner disagrees that a finding is real, record it as
disputed with both positions and do not resolve it in the trial report. The trial measures
whether the kit *produced* the finding; whether it is correct is the owner's call.

**The baseline carries a cause per failing check, not a verdict.** §0 takes it in that shape and
the template holds it; a report that compresses it back to `build pass, tests fail` cannot be
compared against the next trial on the same subject, which is the comparison §2 exists to make
legitimate.

**State every rung's disposition, in the report, next to the outcome.** One line per rung:
`satisfied` -- written `satisfied (against baseline)` where the command was red before the change,
with the touched units and their verdicts and the **baseline** and **unmasked** counts;
`unavailable` (with the compensating control and the raised
tier); or `unsatisfiable` (with what did not run, or what stopped it before the change). What each
means is the ladder's `## Satisfaction`. Not a footnote and not prose elsewhere — a reader must
not be able to reach the outcome without passing the dispositions.

This exists because the alternative was measured. The 2026-09-09 report said **COMPLETE** while
rungs 1 and 2 were unsatisfiable and rung 3 unavailable; the rung detail was real and recorded,
and the headline did not carry it, so the headline is what got quoted. **A trial with any
unsatisfiable rung is VOID, never COMPLETE** — see §3 and the ladder's `## Completion`.

**A trial that found nothing is a result**, and is recorded as one, including which parts of the
kit ran and produced no output.

---

## 7. After the trial

- [ ] Every kit defect filed as a task **before** any of them is fixed.
- [ ] Methodology failures added to §3 **with their detection**, not just their story.
- [ ] Results committed as `docs/TRIALS/<date>-<subject>.md` using the template below —
      `docs/TRIALS/TEMPLATE.md`. A shape each trialist invents is a shape nothing can compare.
- [ ] What the trial could not test, listed explicitly.
- [ ] The copy deleted, or kept and named as contaminated.

### Report template

**`docs/TRIALS/TEMPLATE.md`, and only there.** This section carried its own copy until
2026-09-24, and the copy had drifted: no rung-dispositions line, and a `build pass/fail, tests
pass/fail` baseline that §0 forbids. A second home for the shape is the defect, whichever copy is
right.

---

## Provenance of this document

Written 2026-08-12 before the first brownfield trial, from the greenfield run of 2026-08-01
(`docs/MEASUREMENTS.md`). §3 is that run's "Methodology warnings" promoted from narrative into
procedure, plus detections. The empty-review rule in §3 and the empty-denominator rule in §5
come from defects found in the kit's own review loop, not from a trial.

Revision 2 incorporates a T2 review that found 20 defects **before first use**, including the
two criticals named at the top. That review cost one agent run and would otherwise have been
paid for by a trial on a client codebase.

**This protocol is n=0.** It has never been executed. Its first execution is
`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie`, which is also its first real test, and
the expected outcome is that this document changes again.

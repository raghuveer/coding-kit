<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-09, plugin mode

> **RE-PREPARED 2026-09-10, STILL NOT RUN.** §0 below is the pre-flight as run on 2026-09-09,
> kept unedited with its gate box failing at 12. **§0b is the pre-flight for the run that can now
> start**: the gate reads zero, and the subject copy this file named had to be rebuilt because the
> original was destroyed by scratchpad reaping. Two boxes are the operator's — the time-box, and
> one stop-condition judgement §0b sets out.
>
> **PREPARED, NOT RUN.** Section 0 below is filled in; everything after it is empty on purpose and
> says why. The protocol requires the pre-flight answers to be recorded *before* the first command
> — *"Record the answers; they are part of the result"* — so this file exists at pre-flight rather
> than after, and a reader can see what was true before anyone touched the subject.

| | |
|---|---|
| Question | **Does the kit, loaded as a plugin, produce readings on a subject it did not author?** Specifically: does any `scope=subagent` spend row appear, and does any finding land, on a 967-file **Rust** subject with 169 commits. Written before the first command. **Corrected 2026-09-09: this read `PHP`.** The subject is Rust -- 291 `.rs` files, one `Cargo.toml`, 160 files referencing io_uring. File and commit counts were right; the language was not. ADR 0002's rule is that a pre-registered condition is only as good as its targets, so it is corrected before the run rather than after. |
| Kit SHA | `9ce8b70` at pre-flight on 2026-09-09. **Re-frozen 2026-09-10 at `50226b8`** for the run — §0b, which states the check that catches a tree drifting off it |
| Time-box / actual | **1 h**, then a recorded STOP / CONTINUE / RETRY under §0b's pre-registered rule, **cap 4 h** / not run |
| Subject | highper-gateway — 967 tracked files, 169 commits, branch `master`, clean tree, **not adopted** (no `.project/`). **Unmaintained since 2026-05-16 by operator decision** — attention moved to other projects — and **red on its own CI** at this SHA. Both are recorded below and neither disqualifies it |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | **not run** — see §0 |
| Baseline before the kit | **TAKEN 2026-09-09, on Linux** -- build green, tests do not compile. See the Baseline section |
| Instruments verified live | **not yet** — this is the trial's own question |
| Copy isolation verified | **YES on 2026-09-09, and again 2026-09-10 on a REBUILT copy** — the first was destroyed by scratchpad reaping and reported itself intact via `git ls-files`. §0b carries the evidence and the new path |

## 0. Pre-flight — recorded, and one box FAILS

Run 2026-09-09 against kit `9ce8b70`.

| box | command | result |
|---|---|---|
| Working tree clean | `git status` | **PASS** — clean |
| CI green every platform | `gh run list --branch main` | **PASS** — `9ce8b70` success, four checks |
| Full local Windows conformance | `tests/conformance.sh` | **NOT RUN** — ~1 h on this machine; CI covers ubuntu and macOS, Windows is unverified for this SHA |
| **No unfixed critical** | `kit-preflight.sh --criticals` | **FAIL — STOP. 12 outstanding.** |
| Unassessable criticals | `kit-preflight.sh --unassessable` | **9** — excluded from the gate and still true |
| Superseded criticals | `kit-preflight.sh --superseded` | **32** — excluded, and each was real |
| Copy isolated | `kit-preflight.sh --isolated <copy>` | **PASS** — no remote, no shared object store |

> **The table above is the pre-flight AS RUN on 2026-09-09 and is not edited.** Later the same day
> the gate moved **12 -> 7** and the kit SHA moved from `9ce8b70` to `bedc22e`. Recorded here rather
> than rewritten, because a pre-flight that silently reports today's numbers cannot be compared with
> the next trial's:
>
> | | then | now |
> |---|---|---|
> | criticals gate | 12 | **7** |
> | unassessable | 9 | 9 |
> | superseded | 32 | **35** |
>
> Two closed on evidence (`627b9764` fixed in `validate.py`; `5c1284da` enforced at
> `kit-claim.sh:158`) and three were superseded by **ADR 0011**, which decided claims are recorded
> in committed artefacts and not derived into the index -- retiring the three findings that objected
> to index-time derivation specifically. The remaining seven are three claim-identity findings, due
> at the second census, and four rationale defects in the design document.
>
> **The box still FAILS.** Seven is not zero, and the trial task's fifth blocker requires zero.

**All 12 outstanding criticals are anchored in one file**, `docs/design-input/2026-08-27-census-store.md`
— a design for a feature that was never built. Verified:

```sql
SELECT DISTINCT file_path FROM finding
 WHERE severity='critical' AND fixed_at IS NULL
   AND unassessable_at IS NULL AND superseded_at IS NULL;
-- docs/design-input/2026-08-27-census-store.md
```

### The operator parked the census store, and that does NOT clear this box

`T-20260826-a-verified-claim-about-the-tree-has-no-a` is moved to **`on-hold`** by operator
decision on 2026-09-09. **The gate is unchanged at 12, deliberately.** `kit-preflight.sh:209-217`
queries the `finding` table with no join to `task` and no state predicate at all, and §0 of the
protocol says why in its own words:

> *"**Not filtered by task state.** An earlier revision read `AND t.state='progress'`, so a critical
> on a *done* task did not count — closing the task cleared the pre-flight exactly as well as fixing
> the defect… **A gate you can satisfy by editing a status field is not a gate.**"*

So parking is a true statement about the work — nobody is working the census store — and it is
**not** a route through the pre-flight. It was offered as one in the session that produced this
file, and that was wrong; the correction is recorded here rather than in a message that scrolls
away.

### What would actually unblock this trial — the operator's decision, not taken here

1. **Disposition the 12** under the 2026-09-09 ruling: they are design-stage findings, and the
   ruling says such a finding closes when the design is fixed. Most need the design fixed first, so
   this is not free.
2. **Amend §0's box** to read *no unfixed critical in shipped code*. Defensible on the grounds that
   a gate protecting a trial from defective shipped code is being held by criticals against an
   unbuilt design — but it is a protocol change, argued and recorded, never a bypass.

**Neither has been done. This trial has not started.**

## 0b. Pre-flight — RE-RUN 2026-09-10 against kit `50226b8`, and two boxes are the operator's

**§0 above is the pre-flight as run on 2026-09-09 and stays unedited**, gate box failing at 12. It
is not amended into a pass: the record of a trial that could not start is worth more than a tidy
table. This section is a **second, dated pre-flight** for the run that can now start.

**What changed between them:** the twelve criticals were dispositioned on evidence over PRs #78-#86
— none by amending §0's box, which is the bypass the 2026-09-09 record named and refused.

| box | command | result |
|---|---|---|
| Working tree clean | `git status` | **PASS** — clean at `50226b8` |
| CI green every platform | `gh run list --branch main` | **PASS** — `50226b8`, four checks, read unfiltered |
| Full local Windows conformance | `tests/conformance.sh` | see **Windows conformance** below |
| **No unfixed critical** | `kit-preflight.sh --criticals` | **PASS — "no unfixed critical outstanding"** |
| Unassessable criticals | `kit-preflight.sh --unassessable` | **9** — unchanged from 2026-09-09 |
| Superseded criticals | `kit-preflight.sh --superseded` | **39** — was 32 |
| `git rev-parse HEAD` recorded | | `50226b8f8fb92cc78c7adb45c8174017bdcf58ef` |
| Spend capture live | `kit-preflight.sh --spend` | **this trial's own question** — see §0 of 2026-09-09 |
| Findings capture live | `kit-review-record.sh` | **PASS** — 7 findings through the real loop, PR #79 |
| Copy isolated | `kit-preflight.sh --isolated <copy>` | **PASS** — see **The subject copy** below |
| Baseline before the kit | | **PASS** — taken 2026-09-09, unchanged; the subject is untouched |
| The question written down | | **PASS** — header table, corrected 2026-09-09 |
| **Time-box stated** | | **PASS — 1 h, stated by the operator 2026-09-11**; a recorded STOP / CONTINUE / RETRY at each boundary, cap 4 h — see the amendment at the end of §0b |
| Stop rules stated | | **PASS** — recorded below |
| Abort path stated | | **PASS** — recorded below |

### The kit SHA is frozen at `50226b8`, and the check for it can fail

Every command above ran against that tree. **This record itself lands on top of it**, so a tree
carrying this file is one docs-only commit ahead. Before the first trial command, run:

```sh
git -C <the kit checkout> diff --stat 50226b8..HEAD
```

**Only `docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md` may appear.** Anything else and the
pre-flight above describes a different kit than the one about to run, and it must be re-run.

> **SUPERSEDED 2026-09-11** by the working-tree check in the amendment at the end of §0b. Kept
> rather than deleted, because it was wrong in a way worth seeing: it read `HEAD`, and the plugin
> is loaded from the working tree.

### The subject copy — REBUILT, and the reason is a finding

**The copy this file previously named was destroyed**, and the way it failed is worth recording
because nothing announced it:

```
.git/objects   0 files, no packs, 177K total
git log        fatal: bad object HEAD
git ls-files   967          <- the stale index, answering as if intact
```

It lived in a **session scratchpad**, which is reaped. A later reader running `git ls-files` — the
same command that produced the "967 files" figure in this document — would have been told the copy
was fine. **The lesson is the location, not the loss:** a subject copy prepared by one session for
another session to use must not live anywhere a session owns.

Rebuilt 2026-09-10 by §4's procedure, at a path outside every repository and every scratchpad:

```
copy:      D:\trials\highper-gateway-05c56eb
made by:   git clone --no-hardlinks <subject> <copy>   then   git remote remove origin
verified:  HEAD 05c56eb   169 commits   967 files   branch master   clean
           remotes 0   alternates none   .project absent (not adopted)
control:   kit-preflight.sh --isolated <copy>  ->  "isolated -- no remote, no shared object store"
```

**Two checkouts of this subject exist on the machine and only one is this trial's subject:**

| path | HEAD | commits | files | tree |
|---|---|---|---|---|
| `D:\personal-github\highper-gateway` | `05c56eb` | 169 | 967 | clean — **this one**, and it matches the baseline |
| `D:\my-opensource\highper-gateway` | `4da4c07` | 217 | 971 | dirty — **not this trial's subject** |

Cloning the second would change the subject silently and invalidate every figure in this document.
The copy above carries `05c56eb` in its own directory name so the mistake is visible in a path.

### Windows conformance

`116 passed, 0 failed` on `5116200` (2026-09-10). A second full run was started on `50226b8`, the
frozen SHA, and its result is recorded here rather than assumed:

**RESULT: 116 passed, 0 failed, 0 skipped.** Same figure as the `5116200` run, one step wider than
the 2026-09-09 suite because F1d added a step.

**One caveat, stated because the alternative is a measurement nobody can check.** The run was
started against the `50226b8` tree and **this file was edited while it was in flight** — so the
tree was not constant for its whole duration. Why that does not invalidate it, checked rather than
asserted:

- `grep -n 'docs/TRIALS' tests/conformance.sh` returns **one** line, and it only asserts
  `docs/TRIALS/TEMPLATE.md` exists. **No step reads this file.**
- `validate.py` walks `.md` under `agents/` and the plugin directories, not `docs/TRIALS/`, and it
  was run by hand on the final tree: 7 ok, 0 warnings, 0 errors.
- CI ran the full suite on the exact branch tree on ubuntu and macOS, both green.

A Windows run over a tree that never moved has **not** been done. If that is wanted before the
trial, it is one command and about an hour:

```sh
KIT=$(pwd) WORK=<empty scratch dir> bash tests/conformance.sh
```

The three commits between `5116200` and `50226b8` are data-only — `.project/plans/default.tsv`, one
task file, one `events.ndjson` line — but "data-only" is an argument and the box asks for a run, so
it was run.

### Stop rules — stated before the run, per §0

Stop and record what you have when **any** of these holds. None is a judgement call at the moment it
fires; the judgement was making the list.

1. **The time-box expires.** Whatever has been produced is the result.
2. **The same kit defect blocks progress three times.** Not three defects — the same one, three
   times. A kit that cannot get past its own defect is the finding.
3. **Any VOID condition in §3 is hit.**

### Abort path — stated before the run, per §0

If the kit **crashes or corrupts state mid-trial**, the trial is recorded as **ABORTED at that
point, with the cause**. It is never silently restarted: a restarted trial has a contaminated index
and is no longer comparable with any other trial, which is the whole reason this protocol exists.

### The one box the operator must judge, and it is not the time-box

§0's unassessable box defines **three things that are stops**, and the first one needs a human:

> *An unassessable critical on a task this trial will exercise. The blind spot is then inside the
> path being measured, and any finding the trial produces there cannot be told from the one nobody
> could judge. Check the `task_id` column the command prints against the trial's scope.*

The nine unassessable criticals sit on **five** tasks, and every one of them is plausibly inside
this trial's path:

| task | findings | why it is arguably in scope |
|---|---|---|
| `T-20260808-a-task-id-matching-no-task-file-is-count` | 3 | the trial ingests a foreign backlog into tasks — a task id matching no file is that failure mode |
| `T-20260808-record-how-a-task-was-executed-so-kit-wo` | 2 | "each carries how it was executed" is an acceptance criterion of the trial task itself |
| `T-20260801-nothing-invokes-kit-finding-so-the-findi` | 2 | whether a finding lands is one of this trial's two questions |
| `T-20260808-kit-cfg-strips-space-and-tab-from-a-valu` | 1 | the profile is read on every path the trial exercises |
| `T-20260808-an-apostrophe-in-a-tier-rule-breaks-the-` | 1 | tier floors meeting brownfield paths is a named degradation this trial measures |

**This is recorded as a question and not ticked.** The other two stop conditions do NOT fire, and
both were checked rather than assumed: the count is **9, unchanged** since 2026-09-09 (condition 2
is about it going UP), and **0 of the 9 print `(no reason recorded)`** (condition 3).

A defensible answer is to run anyway and carry the five task ids in the report, so a finding landing
on one of those paths is read next to the blind spot rather than instead of it. That is a decision,
not a formality, and it is the operator's.

### AMENDED 2026-09-11 — the one-hour rule, a safety deviation, the opening prompt, the copy-back

Written before the first trial command, at the operator's direction: *"try for an hour and do
either a retry or a continue based on built state and choice."* Everything below is
pre-registered, so the decision at each boundary is made against criteria fixed now rather than
invented after seeing the first hour.

#### Time-box: 1 hour, then a recorded decision — cap 4 hours

At each 1-hour boundary the session stops and writes a boundary report. The operator then chooses
exactly one of three, and the choice is recorded with the time and the reason:

| choice | when | what it means for the record |
|---|---|---|
| **STOP** | the instrument question is answered — both readings present, or absent with a stated reason — **or** any stop rule fired | the result is what exists. Outcome COMPLETE, or as the stop rule says |
| **CONTINUE** | **all** of: no stop rule or VOID condition fired; the three state checks below are clean; a next activity is named | +1 hour on the **same** copy and index. Same trial, one record |
| **RETRY** | the attempt was set up wrong in a way every later reading would inherit — wrong profile values already indexed, the plugin not loaded, an operator or setup error | attempt 1 is recorded as its own outcome (VOID, naming the setup cause), its copy renamed `…-attempt1` and kept, a fresh copy made by §4, `--isolated` re-run, a new time-box. **The index is never reused** |

**Cap: 4 hours of trial time across all continuations.** At the cap, STOP is the only choice.

**RETRY is not the abort path.** If the *kit* crashes or corrupts state, the attempt is
**ABORTED** — a result about the kit, recorded as one. Any later attempt is then a second trial
with its own record, never a resumption. RETRY exists for mistakes in *setting up* an attempt;
using it to erase a kit failure is the silent restart §0 forbids.

**State checks at a boundary**, all three required for CONTINUE:

    git -C D:/trials/highper-gateway-05c56eb status --short   # only kit-produced paths, plus the one deviation below
    bash D:/personal-github/cck/coding-kit/tooling/kit-index.sh    # from inside the copy: clean
    bash D:/personal-github/cck/coding-kit/tooling/kit-status.sh   # from inside the copy: clean

#### The kit under test is the WORKING TREE, so the check is on the working tree

The plugin is loaded from `D:\personal-github\cck\coding-kit` as it sits on disk, not from a
commit. **So the drift check earlier in this section was aimed at the wrong thing twice.** It
compared `50226b8..HEAD` against a one-file list, which any task filed since breaks while nothing
the plugin loads has changed; and it read `HEAD`, while an uncommitted edit or a switched branch
changes the plugin without moving `HEAD` at all. It is replaced by two checks that can fail, run
immediately before the session starts:

    git -C D:/personal-github/cck/coding-kit status --short
    git -C D:/personal-github/cck/coding-kit diff --stat 50226b8 -- tooling tests hooks skills agents templates .claude-plugin validate.py

**Both must print nothing.** The first says the working tree is what git says it is; the second
says nothing the plugin loads or runs differs from the frozen SHA. **While the trial session is
open, nobody edits or switches branches in the kit checkout** — including to write this record.

#### One deviation from an untouched subject, made for safety, and how to undo it

The copy carried the subject's **tracked** `.claude/settings.local.json`: 24 pre-approved
commands, among them `Bash(git *)` and seven naming `D:\my-opensource\highper-gateway` (six `git -C`,
one `nerdctl build`) — the
*other* checkout of this subject, which has uncommitted changes. User-level settings on this
machine pre-approve **nothing**, so that file would have been the trial session's only
pre-approval, and **any command beginning `git` — including against the real, dirty checkout —
would have run with no prompt.** `kit-preflight.sh --isolated` checks remotes and alternates only,
so it passed. Filed as a kit defect, `T-20260911-the-isolation-check-passes-while-the-cop`.

**Moved out of the copy before the trial**, byte-identical, to
`D:\trials\highper-gateway-05c56eb.settings.local.json.orig`. The copy's `git status` therefore
shows exactly one change before the kit runs — ` D .claude/settings.local.json` — and
`--isolated` still passes. Restore with:

    git -C D:/trials/highper-gateway-05c56eb checkout -- .claude/settings.local.json

**What it costs the trial:** the session will prompt for commands the subject had pre-approved, so
prompt frequency on this run is not a measure of the kit's friction. Recorded so it is not read as
one.

#### A known condition: the subject's CLAUDE.md is a gateway response policy

47 lines committed in `9bc8af3` (2026-05-02), beginning *"rules apply to every response unless
explicitly overridden by the route configuration"*: CITE OR REFUSE, refusal tokens such as
`NO_SOURCE_PROVIDED`, and a rule that any turn with more than 500 pasted characters opens by listing
three claims with confidence ratings. Claude Code loads it anyway. **Left untouched.** The kit's own
adoption step 2 — *"append templates/CLAUDE.kit.md to your CLAUDE.md"* — runs inside the trial, and
how that template sits beside an existing policy is a brownfield observation. The opening prompt
below is over 500 characters, so the session's first reply is expected to open with that list. That
is the subject, not a defect.

#### The stop condition §0b left open is still open

§0's first unassessable stop — *an unassessable critical on a task this trial will exercise* —
applies to all five tasks tabulated above. The operator directed a one-hour run; that direction is
**not** recorded here as a ruling on this box, because it was not stated as one. The opening prompt
carries the five ids so that anything the session sees on those paths is flagged next to the blind
spot. **If the operator rules the box a STOP, the trial does not start.**

#### The opening prompt, verbatim

Pasted as the first message of the plugin session. The rules in it are the kit's working agreement
for this run, which `CLAUDE.kit.md` does not carry; putting them in the prompt rather than in the
subject's files keeps the adoption the kit's own.

```text
This session is a TRIAL of the coding-kit plugin. It is not development work on this project.

Subject: this directory - an isolated copy of highper-gateway at 05c56eb, with no remote.
Kit: loaded as a plugin from D:\personal-github\cck\coding-kit. Its scripts are in tooling\ there.
Protocol: D:\personal-github\cck\coding-kit\docs\TRIAL-PROTOCOL.md
Record: D:\personal-github\cck\coding-kit\docs\TRIALS\2026-09-09-highper-gateway-plugin-mode.md
Read both if useful. Write to neither.

The question: does the kit, loaded as a plugin, produce readings on a subject it did not author?
Specifically: does any scope=subagent spend row appear, and does any finding land?

Time-box: 60 minutes. Run `date -u` first and write the time into your notes as the start.
At 60 minutes, stop wherever you are and write the boundary report below. Do not continue past it
on your own judgement - continuing is my decision.

Rules for this session:
1. Write only inside this directory. Nothing into the kit repository, and nothing into
   D:\personal-github\highper-gateway or D:\my-opensource\highper-gateway - not by Bash either.
2. Never mark a task done. Never run kit-resolve.sh with --fixed, --unassessable or --superseded.
3. File, don't fix. A kit defect is written down in the notes. It is not fixed, and it is not
   quietly worked around.
4. Do not write a Via: trailer on any commit. Propose a value in your summary.
5. Propose values for commands.build, commands.test, commands.lint, commands.typecheck and
   tier.rule, and wait for my confirmation before writing them.
6. If the kit crashes or corrupts state, stop. The trial is ABORTED at that point, with the cause.
   Do not restart it.

Keep a running log at .project/trial-notes.md - one timestamped line per observation: what you ran,
what the kit did, what surprised you, and every kit defect with the command that shows it. That
file is copied back into the kit afterwards, so write it for a reader who was not here.

Order of work:
1. kit-init.sh, then append the kit's templates\CLAUDE.kit.md to CLAUDE.md (adoption step 2).
2. Propose the profile values and wait for me.
3. kit-index.sh, then kit-plan.sh. Report the cluster sizes, and whether packs were written or
   withheld.
4. Pick one small, real task from the subject's roadmap and run it the kit's way: task-context,
   the work at its tier, the reviewer agents, their findings recorded.
5. kit-status.sh, then check the two readings.

Five kit tasks carry criticals nobody can judge. If anything you see touches one of them, say so in
the notes by its id:
T-20260808-a-task-id-matching-no-task-file-is-count
T-20260808-record-how-a-task-was-executed-so-kit-wo
T-20260801-nothing-invokes-kit-finding-so-the-findi
T-20260808-kit-cfg-strips-space-and-tab-from-a-valu
T-20260808-an-apostrophe-in-a-tier-rule-breaks-the-

Boundary report at 60 minutes, in the notes and in your reply:
- spend: a scope=subagent row, yes or no, with the query and its output
- findings: a finding landed, yes or no, with the row
- state: `git status --short`, and whether kit-index.sh and kit-status.sh ran clean
- what is built so far
- your recommendation - STOP, CONTINUE (one more hour on this state) or RETRY (a fresh copy) -
  with the reason, against the criteria in section 0b of the trial record. The choice is mine.
```

#### Copy-back — manual, after the session ends, from a kit session

Nothing moves results from the copy into the kit, and the copy has no remote by design. That is
the shape that lost verified claims before — `T-20260826-a-verified-claim-about-the-tree-has-no-a`:
*"delivered into an isolated working copy that had no remote."* So the copy-back is a step,
written before the run:

1. **Close the trial session first.** The kit checkout is the plugin; writing into it mid-trial
   changes the kit under test.
2. Copy, unchanged, into `docs/TRIALS/2026-09-09-highper-gateway-plugin-mode/`:
   `.project/trial-notes.md`, `.project/events.ndjson`, `.project/tasks/`,
   `.claude/project-profile.md`, plus the output of `kit-status.sh`, §1's per-agent spend query,
   and `git log --oneline 05c56eb..HEAD` and `git status --short` from the copy, each as `.txt`.
3. Run `python3 validate.py` before committing. It checks `.md` files for baked `/home/` and
   `/Users/` paths; a copied file that trips it is **exempted deliberately or left out**, never
   edited — it is evidence.
4. **Transcripts go to `D:\trials\transcript-archive\`, never into this repository.** The
   repository is public, and a transcript carries local paths and everything pasted into it.
   Claude Code's default cleanup deletes them after 30 days, which is why they are archived at
   all. Reviewer transcripts sit one level down, in each session's `subagents/` folder.
5. Then fill **Cost**, **Findings**, **Which brownfield degradations bit** and **Three kinds of
   finding** from the copied files. Kit defects become kit tasks with the operator's confirmation;
   subject defects become a proposal to the owner; methodology becomes an edit to §3.

## Baseline — taken 2026-09-09, BEFORE the kit touched the subject

`kit_footprint=none` was asserted in the same run that produced these numbers, not assumed. The
protocol requires the baseline before adoption because it cannot be reconstructed afterwards.

### Why Linux, and why this is the whole point

**Both this subject and aeon use io_uring, which is a Linux kernel API.**
`docs/ARCHITECTURE.md` names `io_backend.rs` as the *"io_uring backend (Linux)"* -- an
interface-first adapter whose OS-specific options are not fully integrated yet. The project's own
CI is `runs-on: ubuntu-latest`. **A Windows run therefore measures the compatibility shim, not the
subject**, and any earlier aeon-versus-highper-gateway comparison taken on Windows was comparing
two projects' Windows fallbacks.

So the environment is recorded as DATA, per
`T-20260826-the-trial-environment-is-recorded-as-pro`, and the field that makes a bad run
detectable is `io_uring_symbols`. On Windows it is zero.

```
image_distro      Debian GNU/Linux 12 (bookworm)   via nerdctl, rust:1-bookworm
kernel            6.6.87.2-microsoft-standard-WSL2
cores             8
io_uring_symbols  507                              <- the control; zero on Windows
rustc / cargo     1.98.0
cmake             3.25.1                           <- SUPPLIED, see finding 1
go                1.19.8
subject files     967      commits 169      head 05c56eb
kit_footprint     none
```

### Result

| | command | exit | seconds |
|---|---|---|---|
| **Build** | `cargo build --release -p highper-gateway` | **0** | 579 |
| **Test** | `cargo test --workspace --lib -- --test-threads=4` | **101** | 167 |

**The build passes on Linux.** The tests do not fail at runtime and do not fail on io_uring --
**they fail to compile**, so `cargo test` ran zero tests:

```
highper-gateway/src/runtime/signals.rs:238:47
error[E0308]: mismatched types: expected `Sender<ReloadTrigger>`, found `UnboundedSender<_>`
error: could not compile `highper-gateway` (lib test) due to 1 previous error; 60 warnings emitted
```

### Two SUBJECT findings, not applied

Per the three-kinds split below: delivered to the owner as a proposal, never applied here.

1. **Undeclared system dependency on `cmake`**, via `quiche 0.24 -> boringssl`. `.github/workflows/ci.yml`
   installs no system packages, so the build succeeds only because the `ubuntu-latest` runner image
   happens to ship cmake. On clean Debian with a Rust toolchain it fails at 151-156s with
   *"is `cmake` not installed?"*. Reproduced twice.
2. **The `--lib` test target does not compile at `05c56eb`.** Production `setup_signals_with_reload`
   takes a **bounded** `mpsc::Sender<ReloadTrigger>` (`signals.rs:50`, using `try_send` at `:92`),
   while two test sites still build `mpsc::unbounded_channel()` (`:200`, `:238`). The nearest
   `#[cfg(test)]` above the error is `:161`, so this is test-only -- the library itself builds.
   **The larger question was not the line, and it is now answered.** CI runs the same command, so
   the job had to be red or not running. **It is red** -- see the CI table below. That was checked
   before the run rather than discovered in the write-up, which is the difference between a
   recorded condition and an excuse.

### The subject's own CI, on the same SHA — red, and red before the kit arrived

Queried 2026-09-09 against `highperapp/highper-gateway`, run `25968962590`, head `05c56eb` — the
trial subject's exact commit:

| | job |
|---|---|
| **failure** | Test |
| **failure** | Check |
| **failure** | Clippy |
| **failure** | Security Audit |
| success | Build Release |
| success | Format |
| success | Validate Configs |

**Four of seven failing, and the last four CI runs are all failures, all dated 2026-05-16.**

**This is a parked project, not a neglected one.** The operator stopped work on it in May 2026 and
moved to other projects; nothing has been pushed since. The record says so here because a reader
arriving at this file in a year would otherwise infer decay, and because the trial protocol asks
what state the subject was in before the kit touched it.

**And it is the right kind of subject for a trial.** `design-input/2026-08-16-artifact-model-and-distribution.md`
section 3.3 argues explicitly for archived or unmaintained subjects: real accreted debt, and a
**frozen target, so two trials months apart remain comparable**. A moving subject would make the
second trial incomparable with this one.

**The baseline reproduces their CI independently.** `Build Release` green against
`cargo build --release` exit 0; `Test` red against `cargo test --workspace --lib` exit 101. Two
machines, two toolchains, same split — which is evidence the baseline measures the subject rather
than this environment, and it is a stronger check than either result alone.

`Check` and `Clippy` failing is consistent with the same single `E0308`: both compile the test
target, and `Clippy` runs `-D warnings` against the 60 warnings the build emitted. `Security Audit`
is `cargo-audit` and is a different thing — an advisory in the dependency tree, unexamined here.

### Two consequences for how this trial must be read

1. **Attribution.** The subject was already failing four jobs before the kit existed on it, so a
   finding the kit produces is **not** evidence the kit found something new unless it is checked
   against this table. Recorded before the run precisely so it cannot be decided afterwards.
2. **A free oracle, and it is the most valuable thing on this page.** The kit *should* independently
   surface the class of defect CI is already failing on. If a full run does not notice a test target
   that will not compile, **that is a finding about the kit** — and a sharper one than a green
   subject could ever have produced. This is the ground-truth injection that section 3.3 asks for,
   except that the subject supplied it rather than us.

### What this settles about the platform confusion

The difference between aeon passing and this subject not was **never io_uring and never Windows**.
At `05c56eb` this test target compiles nowhere. On Windows that is indistinguishable from the
missing backend; on a kernel with 507 io_uring symbols there is nothing else left to attribute it
to.

### Method — three false starts, recorded because the protocol asks for methodology findings

None was a subject defect and all three were mine:

1. Git Bash rewrote `/out/script.sh` into a Windows path; the container never ran the script.
2. `cmake` missing in the image -- a real subject finding, but not a baseline.
3. A `python` edit adding cmake died on a cygwin fork error, so the container silently re-ran the
   OLD script and failed identically.

**All three reported exit 0**, because the wrapper read the status of the last command in a
pipeline rather than of the thing under test -- `docs/LESSONS.md` section 12, *"a status read from
the wrong process"*. Each was caught by reading the log, never by the exit code. The final script
carries a hard abort if `cmake` is absent, so it can no longer produce a number that describes the
image instead of the subject.

### Reproduction

```sh
nerdctl run --rm -v <subject>:/src:ro -v <scratch>:/out   -v hg-target:/work/target -v hg-registry:/usr/local/cargo/registry   rust:1-bookworm bash /out/baseline3.sh
```

On Git Bash, prefix with `MSYS_NO_PATHCONV=1` or `/out/...` is rewritten before nerdctl sees it.

## Cost

*Not measured — the trial has not run.* When it does, plugin mode is the reason: kit-development
mode structurally emits **zero** `scope=subagent` rows, so every per-agent figure taken from a
development session is empty by construction rather than by result.

- BTE by tier / scope / provenance / model — pending
- BTE by agent — pending
- Raw counters — pending
- Wall-clock and API time, separately — pending

## Findings

*None. Not run.*

- By agent — pending
- Rejected by the recorder (`finding-gap` rows) — pending
- Escape rate by tier over both provenance populations — pending, and expected to have **no
  `via:kit` denominator** on a first run, which must be reported as an absent denominator rather
  than as zeroes shaped like a rate

## Which brownfield degradations bit

*Not measured.* The three to watch, from the protocol:

- Over-tiering from an empty edge table
- Co-change: usable graph, or withheld
- Planner ordering on a backlog it did not author

## Three kinds of finding

*None yet.* The split is stated in advance so it cannot be decided after the fact:

1. **Kit defects** — filed as tasks before any is fixed
2. **Subject defects** — delivered to highper-gateway's owner as a proposal, never applied
3. **Methodology** — folded back into `TRIAL-PROTOCOL.md` §3, with a detection

## Not exercised

Everything. Named rather than omitted, because an untested component named as untested is
information and one left out reads as fine:

- **Plugin mode itself** — the session that prepared this file is kit-development mode and cannot
  produce a `scope=subagent` row at all.
- **`kit-spend.sh` against a foreign subject.** Note before running: it writes into the
  **subject's** tracked `events.ndjson`. That is why the trial runs against an isolated copy at
  `D:\trials\highper-gateway-05c56eb` and not against `D:\personal-github\highper-gateway`.
- **Cluster packs.** ~~`.project/packs/` is empty in the kit and would be empty here too;
  `skills/task-context` step 4 loads a pack and there has never been one to load.~~
  **CORRECTED 2026-09-10: the kit now writes 17 packs.** Its largest cluster is **64 of 135 tasks
  (47%)**, under the 60% cap that was withholding them when this line was written at 65%. So
  `skills/task-context` step 4 has something to load *in the kit*. **What this trial exercises is
  still unknown**: packs on the subject depend on the subject's own clustering, which nobody has
  measured. Corrected rather than deleted, because "empty" and "withheld by a cap" are different
  facts and only one of them was ever true.
- ~~**The Windows conformance suite** for kit SHA `9ce8b70`.~~ **RUN 2026-09-10 on the frozen SHA
  `50226b8`: 116 passed, 0 failed** — see §0b, including the caveat that the tree moved during it.

## Disputed

*Nothing. No finding has been produced to dispute.*

## Setup already done, so a run can start immediately

> **CORRECTED 2026-09-10.** This section named `<scratchpad>/trial-highper`, and that copy no longer
> exists — a session scratchpad is reaped, and the remains answered `git ls-files` with 967 as if
> intact. The path below is outside every repository and every scratchpad for exactly that reason.
> §0b carries the evidence; the old path is recorded here rather than quietly swapped.

```
copy:      D:\trials\highper-gateway-05c56eb
verified:  HEAD 05c56eb, 169 commits, 967 files, master, clean, remotes: [], alternates: none
           kit-preflight.sh --isolated -> exit 0     (re-verified 2026-09-10)
```

The run itself must happen in a **plugin-mode session**, which is the one thing the preparing
session cannot supply:

```
cd D:\trials\highper-gateway-05c56eb
claude --plugin-dir D:\personal-github\cck\coding-kit
```

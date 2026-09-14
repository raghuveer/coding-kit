<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-14

> **TRIAL RUN. Clock `16:51:40Z`, boundary `17:51:40Z`, cap `20:51:40Z`.** Everything below **Baseline** is recorded; the
> sections after it are filled as the trial runs. §0 requires the pre-flight answers to be
> recorded because they are part of the result, and this trial's pre-flight produced six findings
> of its own before any work began — they are listed under **Pre-flight findings**.

| | |
|---|---|
| Question | **On a brownfield subject that never fully adopted the kit, and whose baseline is red for four independently-named reasons, does the kit produce a change that the verify ladder can actually pass — and where it cannot, does the trial say so rather than record COMPLETE?** |
| Kit SHA | `e6f47aada6403199339e6446b56702634c2e3824` |
| Time-box / actual | **1 h**, then a recorded STOP / CONTINUE / RETRY, **cap 4 h** / **~60 min, two units, decision STOP** |
| Subject | `highper-gateway`, Rust, **173 commits at `e588b53`**, 174 at the adoption commit `a6b3dcb` — the census read 174. The pre-flight recorded `169` and nothing produced that figure |
| Greenfield / brownfield | **brownfield**, history not truncated |
| Outcome | **two units completed; the gate held and the record did not.** `kit-entry.sh --check` refused 4 of 4 mutations, each naming its own cause. Two kit defects found, both in the *documented procedure* rather than in code |
| Baseline before the kit | see **Baseline** — four checks, four causes. `build pass, tests fail` is not a baseline |
| Instruments verified live | spend **45 → 46** rows; findings **628 → 629** at pre-flight, **634** after this trial's five. **The rows do NOT join to their runs** — see *The join that does not join* |
| Copy isolation verified | `--isolated` exit 0 after the tracked `.claude/settings.local.json` was removed. It carried **24** `allow` rules — the pre-flight's *"20 outward-reaching"* is unsupported and the whole file went |

## Runtime

    image digest   sha256:237fab4e66710fde0e20f279e8c099dcb2d31fdc397d98aa6ec8ff716b878f2a
    kernel         Linux 6.6.87.2-microsoft-standard-WSL2 x86_64
    host OS        Windows 11 (26200), Rancher Desktop containerd v2.3.2, nerdctl v2.2.2
    subject        e588b53 on master; adoption commit a6b3dcb
    copy           D:\trials\highper-gateway-e588b53

**The subject toolchain runs in the container; the kit runs there too for the `commands.*` box,**
mounted read-only at `/kit` with the copy at `/src`. The profile therefore carries plain commands
and no host paths — the alternative, putting the `nerdctl` invocation into `commands.*`, would
bake an absolute host path into a file meant to be shared.

## Baseline before the kit

Taken **before adoption**, on a quiet machine. A first set was taken while the Windows conformance
suite was running and is **discarded**: exit codes and causes are load-independent, `seconds` is
not, and `seconds` is the only column comparable across trials.

| check | command | exit | seconds | cause |
|---|---|---|---|---|
| build | `cargo build --release -p highper-gateway` | **0** | 625 | — (91 warnings) |
| test | `cargo test --workspace --lib -- --test-threads=4` | 101 | 243 | compiles; **972 pass, 2 fail** — `cache::manager::tests::test_health_check` panics on `runtime_config not initialized`; `runtime_config::loader::tests::load_with_no_env_vars_returns_defaults` panics on `InvalidCombination { HIGHPER_AI_CACHE_BACKEND=valkey requires HIGHPER_CLUSTER_TYPEB_BACKEND }`. Both `#[serial]`, both deterministic — identical at `--test-threads=1` |
| typecheck | `cargo check --workspace --all-features` | 101 | 203 | **91 errors**, all under `highper-gateway/` — 48 `E0433`, 36 `E0425`, 2 `E0422`, 2 `E0405`, 2 missing `async_trait` |
| audit | `cargo audit`, from the subject's own CI | 1 | n/a | `RUSTSEC-2026-0044`–`0048` (AWS-LC: X.509 name-constraints bypass, AES-CCM timing side-channel, PKCS7 chain and signature validation bypasses, CRL scope error) + `RUSTSEC-2026-0255` `spin 0.9.8` **yanked** |

**`Build Release` passes.** Trial 1 recorded this subject as the single word *red*; that word erased
the one green row and merged four unrelated causes. `625 s` against trial 1's `579 s` is the only
figure comparable across the two trials, and it agrees within 8%.

**Per CI job**, from the subject's own Actions on `e588b53`:

| job | verdict | cause |
|---|---|---|
| Build Release | **success** | — |
| Format | **success** | — |
| Validate Configs | **success** | — |
| Check | failure | the 91 errors above |
| Clippy | failure | same surface, `-D warnings` |
| Test | failure | 2 of 974 |
| Security Audit | failure | the six advisories above |

**`unverified`:** none of the four causes is inferred — each was produced by the command in its own
row, or read from the CI job that produced it.

## Adoption — INCOMPLETE, deliberately

`kit-init.sh` **exits 1** on this subject and is right to. `.gitignore` excludes `.claude` six ways
(`/tmp/claude*/`, `/.claude/`, `.claude/`, `**/.claude/`, `.claude-*`, `*.claude`) and `.project`
once, so neither `project-profile.md` nor any task or event file can be committed, and the
*"commit them, the team shares them"* step is impossible.

**The trial proceeds on that footing rather than reversing six deliberate exclusions in someone
else's project** — §7 makes anything the trial produces for the subject a proposal, never an
application. Measured: the kit nonetheless **functions** — `kit-index.sh` and `kit-status.sh` both
exit 0 on the copy, and `kit-finding.sh` records into the ignored `.project` without complaint.

`git.adopted_at` = `a6b3dcb`, the adoption commit, **set by the operator's decision** rather than
left to default. The cost is accepted and stated: no `touches` edges from history, so blast radius
on the first task will read UNKNOWN. The gain is that trailer discipline describes only work done
under the kit.

**A consequence worth recording:** with `.project` ignored, the kit's own writes never dirty the
tree, so §3's dirty-tree VOID condition is *less* likely to fire here — for the wrong reason.

## Pre-flight findings — six, before the clock

Every one would otherwise have surfaced mid-trial, where it would be indistinguishable from the
kit failing.

1. **§4's copy procedure loses every branch but one.** `git remote remove origin` discards the
   remote-tracking refs, so a subject whose HEAD sits on a feature branch yields a copy where
   `master` is unreachable. Filed: `T-20260914-the-copy-procedure-loses-branches-trusts`.
2. **Nothing says to bring the subject up to date.** The local `master` was two merges behind
   `origin/master`; the first correct-looking copy came out at trial 1's own `05c56eb` inside a
   directory named `…-e588b53`. **The directory name was the only thing asserting the version.**
3. **The baseline run dirties the copy**, and §3 makes a dirty tree a VOID condition. Widened
   during the pre-flight: `--commands` does it too, so it is not a step bolted to the baseline but
   a clean-tree assertion needed immediately before the clock.
4. **`--commands` misclassified a red baseline as a stop.** It keyed on exit code alone, so
   `cargo check` exiting 101 with 91 real errors read as *"DECLARED AND DOES NOT RUN"* — and would
   have refused this trial over errors recorded in this trial's own baseline. Fixed and merged as
   PR #130 before the clock; 126/127 now mean *cannot run*, anything else means *ran and reported*.
5. **The isolation check fired on its first live use.** The copy carried a tracked
   `.claude/settings.local.json` with 20 outward-reaching rules, including absolute paths to
   Rancher Desktop binaries. Stripped; the original is kept beside the copy.
6. **A probe of mine contaminated the copy.** A `kit-finding.sh` call run to test whether recording
   worked wrote a real finding row into the trial's own `events.ndjson`. The copy was **remade from
   scratch** rather than hand-edited: evidence a later reader cannot verify is worse than the
   minute it costs to re-clone.

## Stop rules, pre-registered

- the **1-hour** boundary, unless the recorded decision is CONTINUE; never past the **4-hour cap**
- the **same kit defect blocks progress three times** — the third occurrence, not the first
- any **§3 VOID condition** — eight as of 2026-09-14
- **`--commands` reports `CANNOT RUN`** mid-trial. Not one of §0's; added because it names the trap
  that made trial 1 unreadable, and narrowed after PR #130: a command that *runs* and reports
  failures is a baseline fact, not a stop

## Abort path

If the kit crashes or corrupts state mid-trial, this is recorded as
`docs/TRIALS/2026-09-14-highper-gateway-ABORTED.md` with the cause and what had been established
first. **Never silently restarted** — a restarted trial has a contaminated index. A restart is a
new trial, new copy, new baseline, both records kept.

---

## The unit — entry, chosen by the kit's own census

The operator's decision was **C: let the kit choose its own entry point** rather than nominating a
change. So `kit-entry.sh` ran first and the unit came out of what it found.

    kit-entry seconds=197
    entry-facts.tsv         86,783 bytes    965 tracked files, 11 columns
    entry-comment-runs.tsv 855,718 bytes    15,494 runs in 470 files
    entry-report.md          2,295 bytes

**A pre-flight claim of mine was wrong and is corrected here.** I told the operator that setting
`git.adopted_at` to the adoption commit meant the kit would see no history, so co-change would be
dark. Co-change came back **9,818 pairs over 335 of 965 files** from all 174 commits.
`kit-entry.sh` reads history directly and does not consult `adopted_at`; what `adopted_at` bounds is
`kit-index.sh`'s trailer range, so what is actually switched off is `touches` edges. The operator's
decision cost less than I said it would.

### What the census showed, and what it refused to do

`entry-report.md` **proposes nothing**, by design, and it held. **Corrected after audit:** this
section first said ADR 0001 *"makes that refusal the only structural control in the entry mechanism"*,
which is wrong twice. The ADR's sentence is narrower — `kit-entry.sh` cannot write a task file, *"the
one place this design does gate"* (`docs/adr/0001-anchor-entry-facts-to-files.md:106`) — and that is a
different assertion from `entry-report.md` proposing nothing. The ADR's **own superseding note**
(`:119-133`) then records a **second** structural control: `--check` matching the whole candidate line
against a whitelist. This record exercised that second control sixty lines further down and still
called the first one the only one. Four facts drove the unit:

| fact | figure |
|---|---|
| documentation against code | **195,858 markdown lines** in 370 files vs **110,814 Rust lines** in 291 |
| documentation revision | **347 of 370 markdown files have exactly one commit**, against 174 commits |
| the hub files | `config/dsl_parser.rs` co-change degree 96, `proxy/server.rs` 83, `proxy/handler.rs` 73 — **1 author each, none touched since 2026-05-16**. Paths, not basenames: `server.rs` and `handler.rs` each match four files and only the degree disambiguates them |
| the graph exceeds the tree | 149 files co-change that are **not in the tree** |

Documentation that is 1.8× the code and 94% never-revised, sitting beside a core that four months of
history has not touched, is a claim-audit target. The unit became: **do the subject's own
most-alive document's figures reproduce?** `KNOWN_LIMITATIONS.md` is the natural target — 567 lines,
8 commits, 2 authors, last touched 2026-09-12, co-change degree 51.

## Findings

### Kit findings — two, both in the documented procedure

Neither is a code defect. Both are places where the procedure reads correctly and cannot be executed.

**K1 — `ENTRY-PROPOSAL.md` step 2 names an agent that adoption never installs.**
`T-20260914-entry-proposal-step-2-names-a-researcher`, `fail-open`, major.
Step 2 hands the census to a `researcher` subagent, which **returns** the proposal; ADR 0001 split
facts from judgement so a reader could tell them apart. The agent ships at `agents/researcher.md`,
a kit-owned directory; since 0.2.0 the kit is a **plugin** and that is the only route, the
per-project `sync-agents.ps1` having been retired and left unwired. `grep agents tooling/kit-init.sh`
returns nothing — **adoption installs no agent anywhere.** This subject excludes `.claude` six ways,
so no project-level copy is possible either, and the session running the trial offered
`claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup` and no `researcher`.

The orchestrator therefore wrote the judgement itself, which collapses the split the ADR exists to
create, and the only control on that is a sentence at the top of the proposal saying so. **This is
the portability problem in miniature:** a step that resolves only inside one harness's plugin loader
is exactly what does not port to another coding agent.

**K2 — the entry procedure writes into the tracked tree, which voids the trial it serves.**
`T-20260914-the-entry-procedure-writes-into-the-trac`, `correctness`, major.
Step 3 writes `<paths.design_input>/YYYY-MM-DD-entry-questions.md`, **committed**. §3 makes a dirty
subject tree a VOID condition. On this subject `docs/design-input/` neither exists nor is ignored, so
the step would put `?? docs/design-input/` into `git status --short`. The step was **not taken**; the
questions were left in the ignored candidates file, which is not what the procedure says.

**The value is that this is the third instance of one gap.** The pre-flight found it twice already —
the baseline rewrites `Cargo.lock`, and `--commands` does too — and both were filed as properties of
those steps. They are not: **any kit step that writes into the tracked tree collides with §3**, and
nothing says which steps may. A clean-tree assertion before the clock, which
`T-20260914-the-copy-procedure-loses-branches-trusts` AC3 asks for, does nothing for a step taken
mid-trial.

Both recorded through `kit-finding.sh --agent-id`. **This section first claimed they join their
runs. They do not** — see *The join that does not join* below.

### The gate that held — `--check`, mutation-proved

`kit-entry.sh --check` passed the real proposal first try, which by this project's own standard says
nothing. Four mutations, each refused, each naming its own cause:

| mutation | result |
|---|---|
| a candidate line carrying `'; touch /tmp/marker; #` | `candidate line is not safe to paste` |
| `--state wontfix` — outside the ADR 0008 vocabulary | refused, exit 1 |
| a checkbox put on a question | `a question carries a checkbox -- a question is answered, not ticked` |
| `## Could not determine` reduced to its heading | `a heading is not a disclosure` |

**4 of 4.** This is the first control in this trial that was shown to fail when broken, and the
whitelist grammar is the reason — the two earlier attempts that inspected an extracted title both
failed open.

### Subject findings — proposals, never applied (§7)

Both are figures in `KNOWN_LIMITATIONS.md` that the tree at `e588b53` does not reproduce. **Nothing
in the subject was edited.**

**S1 — `Linux support excellent` is recorded beside a Linux build that does not type-check.**
`KNOWN_LIMITATIONS.md:370` marks Linux with a tick while attributing the `cargo check` failure to
Windows and `io-uring`. This trial's own baseline ran `cargo check --workspace --all-features` **in a
Linux container** and got **91 errors, all under `highper-gateway/`** — 48 `E0433`, 36 `E0425`,
2 `E0422`, 2 `E0405`, 2 missing `async_trait` — and the subject's own `Check` and `Clippy` CI jobs
fail on Linux for the same surface.

**Stated precisely, because the over-claim is available and wrong:** the default build passes
(`cargo build --release -p highper-gateway`, exit 0). The claim is not false — it is **unqualified
where the measurement is qualified**, and a reader cannot tell which feature set it covers. Filed as
question 1, not as a defect, per the rule that an undocumented scope is a question.

**S2 — a count with no method.** `KNOWN_LIMITATIONS.md:417` records *"114 TODO/FIXME comments"*, and
`:414` locates them in *"36 files across codebase"*. Measured at `e588b53`:

    git grep -E "(TODO|FIXME)" -- '*.rs'     84 hits in 26 files
    git grep -E "(TODO|FIXME)"              343 hits in 86 files

Neither reproduces 114/36, and **the document does not say what it counted**, so no reader can tell
whether the figure drifted or was measured differently. That is the defect — not the number.

## Which brownfield degradations bit

| degradation | bit? |
|---|---|
| **adoption is incomplete** — `.claude` and `.project` excluded, `kit-init.sh` exits 1 | **yes, and it was the proximate cause of K1.** No project-level agent install is possible |
| **`touches` edges dark** (`adopted_at` = adoption commit) | **no** — the unit was documentation and never needed blast radius. Co-change carried it instead, and co-change was **not** affected |
| **red baseline** — 91 type errors, 2 test failures, 6 advisories | **yes, productively.** It is the evidence for S1 |
| **history deeper than the tree** — 149 files | not exercised; reported as a count, not a list, so the files cannot be named from the artefacts |
| **`merges 2`** — per-file `commits`/`authors` are lower bounds | recorded, not relied on |

## Three kinds of finding

- **kit defects:** K1, K2 — both in `docs/`, neither in code. A trial that only looked for code
  defects would have recorded this hour as finding nothing.
- **subject findings:** S1, S2 — proposals in this record, and **nowhere else**. `KNOWN_LIMITATIONS.md`
  is unmodified and `git status --short` is empty.
  **Corrected after audit:** this said *"no file outside the ignored `.project` was modified"*, which is
  false as written. The **adoption commit `a6b3dcb`** changes three tracked files —
  `.claude/settings.local.json` deleted, `.gitattributes` +6, `.gitignore` +8 — and the kit also wrote
  `STATUS.generated.md` and `.claude/project-profile.md`, both ignored but both outside `.project`. The
  intent was *the trial applied nothing to the subject*, and that holds; the sentence claimed more.
- **protocol findings:** the six from the pre-flight, plus K2, which is really a protocol finding
  wearing a kit-defect shape — the collision is between `ENTRY-PROPOSAL.md` and `TRIAL-PROTOCOL.md`
  §3, and neither document is wrong on its own.

## Cost

**Not measurable at this resolution, and that is the finding.** The `spend` table is keyed on
`transcript`, so a session is **one row updated in place**. The trial hour sits inside a row
covering 1,552 turns of a full day:

| scope | rows | turns | kBTE |
|---|---|---|---|
| main | 1 | 1,552 | 93,705 |
| subagent | 3 | 88 | 1,249 |

There is no way to attribute a time-boxed unit inside a session to its share of that row, so **no
per-trial cost is quoted here rather than quoting one the instrument cannot support.** The subagent
rows are attributable and the main row is not, which is the asymmetry `--agent-id` fixed for
findings and has not fixed for spend.

## Unit 2 — the record audited by a second reader, and the answer to K1

K1 says the kit's reviewers are unreachable from an adopted project. That is testable rather than
assumable, so the second unit tested it: a **generic** agent type — one the harness offers to
everybody, with no kit plugin loaded — was pointed at `agents/claim-auditor.md` and told to follow it.

**It worked.** The agent read the prompt, obeyed its output contract, and returned the audit in the
contract's JSON shape with a per-claim verdict vocabulary it was never given inline. 83k tokens,
23 tool calls, 5m14s.

**So K1 is a distribution defect, not a design defect, and that narrows the fix.** The kit's agent
files are portable prompts; what does not port is the plugin loader that is currently their only
route into a session. A harness that can run a subagent with a prompt can run all nine. This is the
first evidence in either trial bearing on *"support many coding agents"*, and it is favourable.

**Blind by construction:** the auditor was handed twelve claims to check and told nothing about
whether any was true, in an order that did not match the record's.

### Nine of twelve confirmed to the digit

Every census figure reproduced from `entry-facts.tsv` without rounding — 370/195,858 against
291/110,814; 347 of 370 at one commit; the three hub degrees with their authors and dates;
`KNOWN_LIMITATIONS.md` at 567/8/2/2026-09-12/51. Both `git grep` counts reproduced exactly. The
`kit-init.sh` silence, the unwired `sync-agents.ps1`, the absent-and-unignored `docs/design-input/`,
the clean tree, and the 51/580 attribution split all held.

### Three did not hold, and they cluster

**Every one is in a place where this record stopped quoting an instrument and started paraphrasing a
document.** The figures came from tools and survived; the sentences came from me and did not.

| # | claim | verdict | what was wrong |
|---|---|---|---|
| 1 | *"ADR 0001 makes that refusal the only structural control"* | **OVERSTATED** | The ADR's own superseding note records a **second** structural control — the `--check` whitelist. This record exercised it sixty lines later and still called the first one the only one |
| 2 | *"No file outside the ignored `.project` was modified"* | **OVERSTATED** | The adoption commit changes three tracked files; the kit wrote two more ignored files outside `.project` |
| 3 | `KNOWN_LIMITATIONS.md:371` and `:413` | **STALE-CITATION** ×2 | Quotes verbatim, substance sound, **pointers off**. `:371` is the *Windows-fails* row — a reader following it lands on the line that reads as refuting the point. `:413` is `**Impact:** NONE`; the two quotes it carries are at `:414` and `:417` |

Finding 1 is the one worth keeping. **It is a self-contradiction inside one document**, visible to
anyone who read both sections, and it survived my writing it, my re-reading it, and a `--check` run.
A second reader found it in five minutes. That is the ninth time in this project's record that the
defect which mattered was found by a second reader rather than by a passing check.

### Four numbers the audit disturbed that were not in its scope

It flagged these as open questions, correctly refusing to rule on unassigned claims. All four are
now corrected in the header above, and **three of the four were pre-flight figures, not trial
figures** — this record shipped them forward unchecked:

- **the commit count.** The header said `169`; the body said `174`. Measured: **173** at `e588b53`,
  **174** at the adoption commit. *Nothing produces 169.* It was in the pre-flight record and was
  carried, which is the exact failure mode this project has a memory note about.
- **the permission rules.** The header said `20 outward-reaching`; the adoption commit message said
  24. The stripped file carries **24 `allow` rules** and the whole file was removed, so `20` is
  unsupported by anything.
- **the finding count.** `628 → 629` and `51 + 580 = 631` are both in this record — a pre-write
  total beside a post-write split, with nothing saying so.
- **the hub files** were named by bare basename; `server.rs` and `handler.rs` each match four files
  in the tree and only the co-change degree disambiguates them.

### What the audit did not check, stated because an unstated gap reads as a pass

The whole Baseline table and its exit codes and `seconds`; the per-CI-job verdicts; the six
pre-flight findings; the runtime digest; `kit-entry seconds=197` and the artefact sizes; the 9,818
co-change pairs and the 149 out-of-census files; the four `--check` refusals and their messages; the
spend table; PR #130; and *"since 0.2.0 the kit is a plugin"*. **Nothing was UNVERIFIABLE** — every
assigned claim was answerable from the two trees.

## The join that does not join — found after the boundary, correcting this record

**Every claim in this record that findings "join their runs" was false, and the kit said so the
whole time.** Recorded here rather than quietly edited, because the way it was found is the point.

`kit-status.sh` prints, and has printed throughout:

    Findings that cannot be joined to a reviewer run: 580 of 634 carry no agent id,
    and 54 carry one that matches no spend row.

**54 of 54 attributed findings match no spend row. Not one has ever joined.** Measured:

| what | value |
|---|---|
| `spend.agent_id` holds | the harness **subagent** id — `a5e877a2010bfdbef` |
| `spend.session` holds | the **session** id — `aa8f5759-c366-4687-b752-400b012601f0` |
| what I passed to `--agent-id` | the **session** id, for both unit-1 findings; the session id plus a suffix for the three audit findings |
| the auditor's real subagent id | `a5e877a2010bfdbef` — **present in `spend` the entire time**, returned to me when the agent was launched, and not used |

The other 49 rows are worse and older: `blind-second`, `design2`, `entry-final`, `entry-impl`,
`preflight-probe` — hand-written labels that were never harness ids at all.

### Whose defect this is

**Mine, mostly, and the kit behaved correctly.**
`T-20260911-a-finding-recorded-by-hand-carries-no-ag` AC2 asks that an unjoinable finding be
*"reported as unjoinable rather than stored as if the join were possible"*, and that is exactly
what happened: the count was on the status page before, during and after this trial. The control
fired. **I did not read it, and asserted the opposite twice.**

The residual kit gap is narrow and real: `kit-finding.sh` takes `--agent-id` raw
(`agent_id=${2:-}`, `:75`) with **no validation at record time**, so a session id, a typo or an
invented label is accepted silently and surfaces only at the next `kit-status.sh`. The task's AC2
says *"by `kit-status.sh` **or** at record time"*, so this is not a missed criterion — it is the
weaker of the two arms the criterion allowed, and five more unjoinable rows were written before
anyone looked.

### Why it matters beyond tidiness

This is the instrument the operator asked for by name. With the join at 0/54, *"what did this
reviewer cost and what did it find"* is still unanswerable for **every** run in the repository —
which was the original complaint, and it was not fixed by adding the column, recording values, or
reporting the gap. **A column that is populated is not a column that joins.**

## The 1-hour boundary — decision: STOP

Recorded at the boundary, as §0 requires, rather than decided by running out of things to do.

**STOP.** Two units are complete, both pushed, all four CI checks green on
[PR #131](https://github.com/raghuveer/coding-kit/pull/131). The reason to stop is not the clock:

- **the trial answered its question.** *Does the kit produce a change the verify ladder can pass, and
  where it cannot, does the trial say so rather than record COMPLETE?* It said so — twice, in writing,
  about itself. The Cost section records **unmeasurable** instead of an estimate, and the What-was-NOT
  section names the ladder as unexercised rather than implying it ran.
- **the next thing to do is not another unit, it is the backlog.** Three tasks were filed and one
  blocker closed; all of them are now work, and doing kit work inside a trial contaminates the trial.
- **the third unit available was auditing the audit**, which is where this stops being measurement.

**No VOID condition fired.** The subject tree is clean, `--commands` never reported `CANNOT RUN`, and
no kit defect blocked progress even once, let alone three times.

**`T-20260912-a-trial-runs-in-a-container-on-the-subje` closes on this trial**, AC3 and AC5 in
particular: the runtime is recorded above, and the subject built and ran its tests in the container
end to end. It is the first trial to do so.

### What trial 2 cost that trial 1 did not

Trial 1 stopped at 35 minutes with the subject recorded as the single word *red*. Trial 2 spent its
hour and came back with **five findings, three of them against its own record**. The difference is
not effort — it is that this trial had a pre-flight, a mutation-proved gate, and a second reader.

## What was NOT exercised

- **the verify ladder.** The unit produced two task files and two findings and changed no code, so
  there was nothing for rungs 1–5 to read. `--commands` was proved runnable in the container during
  the pre-flight (1 pass, 3 ran and reported failures) and was not re-run.
- **every reviewer agent as a kit-installed agent.** See K1; none was available that way. Unit 2
  showed the prompts run under a generic agent type, which is the remedy, not a substitute for the
  finding.
- **`kit-task.sh` from a candidate line.** The proposal's five lines were validated by `--check` and
  **not run against the subject**; the two tasks filed were filed in the *kit*, about the kit.
- **the 149 out-of-census files**, the hub files, and the doc-vs-code ratio — all left as questions
  1, 3, 4 and 5 in the proposal, unanswered by design. They are the operator's to answer.
- **anything requiring a write to the subject's tracked tree**, deliberately — see K2.

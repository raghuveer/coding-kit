# CLAUDE.md

<!-- Append to the target repo's CLAUDE.md. Keep it this short: every line here is
     paid on every request of every session. If deleting a line does not change
     behaviour, leave it deleted. -->

## Working agreement

- Declare a tier (T0-T3) before spawning any reviewer. Untiered work is either
  overspend or a missing control, and afterwards you cannot tell which.
- Truth lives in task files and git trailers. `STATUS.generated.md` and
  `.project/index.db` are derived — never edit them, and never treat them as input
  that outranks the text they came from.
- Never write outside the project root.

- **Verify in CI, not locally. Push, open the PR, read three legs.** As of 2026-09-17 every
  platform the kit supports runs the full suite in CI:

      conformance (ubuntu-latest)    ~1m 07s   required
      conformance (macos-latest)     ~2m 17s   required
      conformance (windows-latest)   ~5m 20s   required (since 2026-09-18)

  Windows joined the matrix in PR #137. It used to cost **an hour** on this machine, and the
  earlier version of this rule told you to start that local run in parallel with the push. **Do
  not.** That hour buys nothing CI does not deliver in five minutes, and the reason the local run
  is slow is a fault on this machine, not a property of Windows — it spawns processes at
  ~1,015 ms against a runner's 12-14 ms. See `T-20260822`.

  Run the suite locally only with a reason you can say out loud: a filtered `--only <name>` while
  iterating, or a defect you cannot reproduce in CI. A full local Windows run is now the exception.

  **`conformance (windows-latest)` is a REQUIRED check as of 2026-09-18.** All five must be green
  to merge. It was advisory from #137 until then, and was promoted on six green observations with
  no failures after the two defects below were fixed -- three consecutive on `main`, three on PRs.
  **That holds for the Windows leg:** every `main` Windows leg from `73dcaf7` to `1fe3268`
  (2026-09-17 to 2026-09-19 14:40) printed no `FAIL` line.

  **But the same runs were not clean elsewhere, and from 2026-09-19 neither was Windows.** From
  `73dcaf7` three steps reset the suite's failure tally (`bad=0` on the variable it exited with),
  so a run could print `FAIL` and exit 0. Runs on 2026-09-14/15 printed none; from 2026-09-17 to
  2026-09-26 every green `main` run hid at least one:

  - the python-only fixture removed `/usr/bin` on Unix -- ubuntu and macOS, from `73dcaf7`;
  - the state lists written twice -- all three legs, Windows included, from `ebfa55c` (09-19);
  - `kit-index.sh` unparseable by bash 3.2 in POSIX mode -- every macOS run from `ca4e589` (09-19),
    a real regression;
  - one sign-off check on macOS, 1 run in 36, not reproduced in five attempts -- instrumented, not
    fixed.

  PR #182 fixed the first three and the tally, and CI now fails a run whose `FAIL` lines and
  summary disagree, or that prints no summary at all.

  **Read CI by its `FAIL` lines, not only its colour.** In `gh run view --job <id> --log` every line
  is prefixed with the job, the step and a timestamp, so count the suite's lines with
  `grep -c 'Z   FAIL  '` and confirm the `PASS` count is non-zero. Two traps met while doing it: the
  log is EMPTY until the whole run has finished, and each step's script is echoed into the log, so
  a bare grep for `FAIL` matches the script's own text.

  **A red Windows leg now blocks merges.** That is the point of promoting it, and it is reversible
  in seconds: remove the context from branch protection. The one demonstrated flake is a network
  one -- `choco` returned a 504 mid-session on 2026-09-17 -- which the install step now answers
  with three retries, a sqlite.org fallback, and a hard `command -v sqlite3` verify that fails
  closed. If the leg reddens on an install rather than an assertion, read that step first.

  The baseline this file carried until 2026-09-17 -- "expected red, 31 FAIL / 71 PASS" -- is gone
  because both defects behind it are fixed: gawk 5.4.1 rejecting `globre`'s `/\052+/` (#144), and
  `subprocess.run(["bash", ...])` reaching `C:\Windows\System32\bash.exe`, the WSL launcher,
  instead of Git's bash (#146). The second hid the first: until the index could build, 53 steps
  never ran at all, so "71 PASS" was never a measurement of anything.

  **A branch push alone triggers nothing** — the workflow fires on `pull_request` and on pushes to
  `main`. Open the PR, or CI never starts. PRs are also what keep `main` green: only verified work
  merges.

  **Never let a run finish against a tree you are editing.** If CI goes red, fix and push again —
  do not read the output of a run whose inputs changed under it, because it measured a state that
  never existed. This is the part of the old rule that was never about Windows.

- Commits carrying real change carry `Task-Id:` and `Tier:` trailers.
- `Via:` records HOW the work was done — `kit`, `agent`, `manual`. Optional; absent
  means `unknown`, which is reported as unknown. Escape rate is reported over the
  kit-run population **and** over every task, side by side — so provenance changes
  what a number means, never whether an escape is visible.
  **If you are an agent reading this: do not write `Via:` on your own commits.** Propose
  a value in your summary and stop there. A self-reported `via: kit` from the agent that
  did the work is the one value nobody should take on trust.

- `Fixes-Escape-Of: <task-id>` records that this change fixes a defect an EARLIER task's
  review should have caught. It is the numerator of escape rate, and **it has never been
  written here — 0 commits in 324.** Nothing was hiding it: it is read by `kit-trailers.sh`
  and documented in README and HANDOFF. It was simply absent from this file, which is the
  one a session actually reads.
  **If you are an agent reading this: propose it in your summary and stop**, as with `Via:`.
  The reason differs and is worth knowing — `Via: kit` flatters the pipeline, so a
  self-report is worthless; this one INCRIMINATES it, so the risk is not a false claim but a
  claim never made. Silence here reads as "nothing escaped" when it means "nobody looked".

- A finding is marked addressed with `kit-resolve.sh --finding ID --fixed`, which clears it from
  the outstanding-criticals gate. **If you are an agent reading this: propose the mark in your
  summary and stop.** A session certifying its own output is the one signature that carries no
  information, and this is the same rule as `Via:` for the same reason.

- **Never narrate planning or tool selection.** Output findings, actions and results — not what
  you are about to do, not what you need next, not a list of the calls you are considering. Turn
  instructions ask an agent to work out its next steps *privately*; rendering that reasoning as
  visible text is the failure, and it is not fixed by renaming it. Recorded because it happened
  five times in one session on 2026-09-12, twice after the agent had stated it would stop and
  once after it had renamed the prefix rather than dropped it. The operator asked whether
  `/clear` or a restart would help: neither would, because the instruction being mis-executed is
  re-injected every turn, which is why the correction belongs here instead.

**For the operator, not the agent** — every instruction in this block is yours:

- A finding that **cannot be judged at all** — the record does not say what it was — is marked
  `kit-resolve.sh --finding ID --unassessable --reason TEXT`. It leaves the criticals gate and
  stays in the record permanently; `kit-status.sh` reports the count as a standing blind spot and
  never folds it into zero. `--reason` is required, because a mark that clears a gate without
  saying why is the laundering the gate exists to prevent. **This is yours, not the agent's**, for
  the same reason `--fixed` is. It is not a synonym for `--fixed`: addressed and unjudgeable are
  different claims and the tool refuses to record both at once.
- A finding whose **subject was withdrawn** — the design it reviewed was rejected, the revision it
  criticised was replaced — is marked
  `kit-resolve.sh --finding ID --superseded --by NAME`. A fourth claim, not a synonym for any of
  the three above: `--fixed` would say it was addressed and nothing was, `--unassessable` says
  nobody can tell what it said and these are perfectly legible, `--false` says it was never real
  and **it was — being real is why the subject died.** Collapsing that into "fixed" erases the
  most valuable thing a review does.

  **The guard is a marker in the tree, not the flag.** `--superseded` is refused unless the
  finding's own `file_path` carries a `Superseded-by:` line naming the same thing `--by` does. So
  the withdrawal is reviewable in a diff and lands in front of the next reader of the subject.
  It is refused outright when the finding records no `file_path`, and when the file is **absent** —
  deleting the evidence must not be the cheapest way out of the gate. Like `--unassessable`, it
  leaves the criticals gate, stays in the record permanently, and `kit-status.sh` counts it
  separately rather than folding it into zero. **Yours, not the agent's**, for the same reason.
- A finding that was **never a defect** — a probe, a reviewer's false positive — is marked
  `kit-vindicate.sh --finding ID --false --note TEXT`. A fifth claim, and the note is REQUIRED:
  this mark retires one named finding from the criticals gate on its own, with no
  sole-of-its-class test standing behind it, so it must say why. Do not reach for `--fixed`
  (nothing was addressed), `--unassessable` (these are perfectly legible) or `--superseded`
  (nothing was withdrawn).

  The older `--task ID --class CLASS` form is **kept and is not a synonym**: it refutes every
  finding sharing that pair, which is right when a reviewer's whole class on a task was noise
  and wrong for a single row. 604 of 635 findings here share a pair with at least one other, so
  the class form is the one that needs care. `kit-status.sh` counts the two apart and never
  folds either into zero. **Yours, not the agent's**, for the same reason as `--fixed`.
- You run `kit-resolve.sh --fixed`, after deciding the fix is real. `--commit` must resolve, and
  a mark whose commit later leaves the history is reported on rebuild. A REVERT is not detected.
- You put `Via:` on the trailer, after deciding it.
- You put `Fixes-Escape-Of:` on the trailer, after deciding the defect genuinely escaped a
  prior review rather than being new work. Until one is written, every escape-rate numerator
  in every report is zero by construction, and `kit-status.sh` now says so rather than
  printing a clean-looking `0`.
- Retract a wrong value with `Via: unknown` on a later commit, never with `Via: manual`;
  those mean different things and only one is a claim.
- Nothing mechanically stops an actor with commit access from writing `Via: kit`. This is
  a convention you enforce, not a gate the kit closes.

> Why the split: the earlier wording — "**you** set it, not the agent that did the work" —
> was written for the operator and lives in the file the model reads every session, so it
> told the model to set it. The retraction sentence then landed inside the paragraph
> addressed to the agent, which was the same defect a second time. Instructions here are
> grouped by who they are for.

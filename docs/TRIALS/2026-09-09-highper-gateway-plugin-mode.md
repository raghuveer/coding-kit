<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-09, plugin mode

> **PREPARED, NOT RUN.** Section 0 below is filled in; everything after it is empty on purpose and
> says why. The protocol requires the pre-flight answers to be recorded *before* the first command
> — *"Record the answers; they are part of the result"* — so this file exists at pre-flight rather
> than after, and a reader can see what was true before anyone touched the subject.

| | |
|---|---|
| Question | **Does the kit, loaded as a plugin, produce readings on a subject it did not author?** Specifically: does any `scope=subagent` spend row appear, and does any finding land, on a 967-file PHP subject with 169 commits. Written before the first command. |
| Kit SHA | `9ce8b70` (`main`, all four CI checks green) |
| Time-box / actual | not set / not run |
| Subject | highper-gateway — 967 tracked files, 169 commits, branch `master`, clean tree, **not adopted** (no `.project/`) |
| Greenfield / brownfield | **brownfield**, history intact, not truncated |
| Outcome | **not run** — see §0 |
| Baseline before the kit | not taken |
| Instruments verified live | **not yet** — this is the trial's own question |
| Copy isolation verified | **YES** — `kit-preflight.sh --isolated` exit 0, `git remote -v` prints nothing |

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
  `…/scratchpad/trial-highper` and not against `D:\personal-github\highper-gateway`.
- **Cluster packs.** `.project/packs/` is empty in the kit and would be empty here too;
  `skills/task-context` step 4 loads a pack and there has never been one to load.
- **The Windows conformance suite** for kit SHA `9ce8b70`.

## Disputed

*Nothing. No finding has been produced to dispute.*

## Setup already done, so a run can start immediately

```
copy:      <scratchpad>/trial-highper
verified:  169 commits, 967 files, remotes: []   kit-preflight.sh --isolated -> exit 0
```

The run itself must happen in a **plugin-mode session**, which is the one thing the preparing
session cannot supply:

```
cd <scratchpad>/trial-highper
claude --plugin-dir D:\personal-github\cck\coding-kit
```

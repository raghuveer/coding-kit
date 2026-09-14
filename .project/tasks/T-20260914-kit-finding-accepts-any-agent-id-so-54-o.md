---
id: T-20260914-kit-finding-accepts-any-agent-id-so-54-o
title: kit-finding accepts any agent id so 54 of 54 attributed findings join nothing
epic: feedback-loop
tier: T2
lang: bash
paths: tooling/kit-finding.sh, tooling/kit-review-record.sh, tests/conformance.sh
state: created
---

## Intent


## Acceptance criteria

- [ ] 
- [ ] 

## Notes

## Intent

`kit-finding.sh` takes `--agent-id` raw — `agent_id=${2:-}` at `:75` — and writes it into the event
with no check that it resolves to anything. **Measured 2026-09-14: 54 of 54 attributed findings in
this repository match no spend row. The join has never worked once.**

    sqlite3 .project/index.db "select f.agent_id, count(*),
      (select count(*) from spend s where s.agent_id=f.agent_id)
      from finding f where f.agent_id != '' group by f.agent_id"

    aa8f5759-c366-4687-b752-400b012601f0          2   0
    aa8f5759-c366-4687-b752-400b012601f0-audit    3   0
    blind-second                                 16   0
    design2                                      15   0
    entry-final                                  12   0
    entry-impl                                    5   0
    preflight-probe                               1   0

Two distinct causes, and the vocabulary is the first:

1. **`spend.agent_id` is the harness SUBAGENT id; `spend.session` is the session id.** Trial 2
   passed the *session* id to `--agent-id` for all five of its findings. The auditor's real
   subagent id — `a5e877a2010bfdbef` — was in `spend` the whole time and was returned to the caller
   when the agent was launched. Nothing said which of the two was wanted; the flag's help says
   *"the reviewer RUN"*, which is true and does not disambiguate two ids that are both per-run.
2. **49 of the 54 are not ids at all** — `blind-second`, `design2`, `entry-final`, `entry-impl`,
   `preflight-probe` are hand-written labels. Nothing refused them.

## What this is NOT

**Not a missed criterion on `T-20260911-a-finding-recorded-by-hand-carries-no-ag`.** Its AC2 asks
that an unjoinable finding be reported as unjoinable *"by `kit-status.sh` **or** at record time"*,
and `kit-status.sh` has printed the count correctly throughout. **The control fired and was not
read** — this task exists because the later of the two arms lets bad rows accumulate silently until
someone looks, and five more were written during trial 2 before anyone did.

## Acceptance criteria

- [x] `kit-finding.sh` and `kit-review-record.sh` **refuse, or loudly warn on, an `--agent-id` that
      resolves to no spend row** at record time. Refusing outright may be wrong — the spend row can
      arrive after the finding — so the decision to make is whether this is a refusal or a warning
      that names the value it could not find.
- [x] The help text says **which** id is wanted, in words that distinguish it from the session id,
      and names where a caller gets it. `"the reviewer RUN"` does not, because both ids are per-run.
- [ ] The 54 existing rows are dispositioned rather than left: either backfillable from the
      transcripts, or marked permanently unjoinable so the count stops reading as a live backlog.
- [x] A conformance step passes a well-formed id that matches nothing and asserts the new behaviour.
      Mutation-proved: remove the check and the step goes red.

## Notes

Filed 2026-09-14 from trial 2, after the boundary. **The trial record asserted twice that its
findings joined their runs; both claims were false and are corrected in
`docs/TRIALS/2026-09-14-highper-gateway.md` under *The join that does not join*.**

This is the instrument the operator asked for by name. With the join at 0/54, *"what did this
reviewer cost and what did it find"* remains unanswerable for every run in the repository — the
original complaint — and it was not fixed by adding the column, recording values, or reporting the
gap. **A column that is populated is not a column that joins.**

### Evidence, 2026-09-14 — PR #132. AC3 deliberately NOT done.

| AC | where to verify |
|---|---|
| 1 — refuse or loudly warn at record time | `kit_findings.py --check-agent-id`, wired into `kit-finding.sh` after `PY` is set. **Warns, never refuses**, and leaves the exit status alone — a reviewer's spend row is written by a Stop hook and can arrive after the finding, so refusing trades a silent non-join for a lost finding |
| 2 — the help says WHICH id, distinguishably | `kit-finding.sh` header and `skills/verify-ladder/SKILL.md`: *"IT IS THE SUBAGENT ID, NOT THE SESSION ID"*, with why the session id cannot identify a run |
| 3 — the 54 existing rows dispositioned | **NOT DONE.** Still 54. A separate change; the count on the status page is honest today and would stop being honest if this shipped as "closed" |
| 4 — a conformance step, mutation-proved | three arms added to the existing step. **Three mutations, three failures, each on its own arm**: remove the check → arm 5; warn on everything → arm 4; drop the session diagnosis → arm 6 |

**Found while doing AC2 and fixed here:** `kit-finding.sh -h` was `sed -n '4,8p' "$0"` — a hardcoded
range that **had already outgrown itself**. `--vocab` and `--contract` are real flags documented in
that same block and **neither had ever been printed by `--help`**. Nothing failed. The help block is
now derived, with its own conformance step, mutation-proved by restoring the old range.

**This task does not close.** AC3 is open and the 54 rows still join nothing.

---
id: T-20260826-a-verified-claim-about-the-tree-has-no-a
title: A verified claim about the tree has no artefact so a census cannot be recorded
epic: reporting
tier: T3
paths: tooling/schema.sql, tooling/kit-index.sh, tooling/kit-claim.sh, tooling/kit_claims.py, tooling/kit-status.sh
blocked_by: T-20260826-no-agent-owns-verifying-documented-claim
state: created
---

## SPLIT 2026-08-28 — this is now Task A of three

Two approach reviews returned REVISE (17 findings, then 22). The second recommended splitting, and
the operator accepted. **This task is now Task A: the store — artefact capture, derivation, and
AC5 reporting.**

| | task | carries |
|---|---|---|
| **A** | **this** | D1, artefact capture, derivation, AC5 |
| B | `T-20260828-claim-dispositions-so-feedback-on-a-cens` | D2 — dispositions, the fifth vocabulary, the ADR 0006 conversation |
| C | `T-20260828-census-diff-and-the-attribution-control-` | AC6 diff, D3 attribution, variance measurement |

The reviewer's argument, which is the point of splitting: landing all three together risks **AC6 —
the criterion this task's own text calls the whole point — being the part that gets cut** when the
rest runs long. AC4 and AC6 move to B and C respectively; AC1, AC2, AC3, AC5 and AC7 stay here.

## Why this line of work exists — the operator's framing, recorded as his

Stated 2026-08-28, and it is the standard the whole census effort is held to:

> The goal is to document, so we can do next-level deeper analysis to create tasks with
> dependencies with complete picture, so we move forward while we will have **findings as data
> points reference w.r.t. created tasks**. These are required for coding kit's developers. For
> those coding kit users who are application developers... who choose this coding kit as a means to
> streamline Agentic AI-assisted application development and maintenance to cater their short-term
> to long-term strategic business needs. The findings and tasks, if we maintain, will help anybody
> who chooses to go the extra mile to contribute or improve — **irrespective of whether they share
> improvements back or not**.
>
> First success is encouraging but predictable; **deterministic, quantifiable and qualitative
> outcomes from coding kit is necessary** for me as its developer, when taking it to its tech-savvy
> application developer community who are aspiring to use GenAI adoption for their software
> development work.

Two consequences that bear directly on this task's design, rather than being background:

1. **Findings must be traceable to the tasks they produced**, in both directions. That is why the
   split lists inherited findings by id rather than re-narrating them, and why a disposition (task
   B) is content rather than metadata.
2. **"Deterministic and quantifiable" is an acceptance standard, not an aspiration.** It is why
   AC5 demands a fraction with its denominator rather than an adjective, and why task C's
   attribution control must refuse rather than annotate.

## Findings on this task that belong to A

39 findings are recorded here across two reviews. B and C list the ones they inherit; the rest are
A's, and the six criticals below block implementation:

| id | what |
|---|---|
| `…:962` | `census_id` undefined — answered in revision 2, verify it survives |
| `…:269` | **`claim_key` is still undefined** — suffix, `id_ambiguous` and ordinal all proposed, none designated. Task C is entirely downstream of this |
| `…:65e` | `normalise` is said to run at index time, but `kit-index.sh` contains **zero** `python3` and is awk |
| `…:5c1` | `census_id` and `--unit` become path components with **no refusal rule** — `kit-plan.sh:108-129` records a T3 review finding `../../docs` in a committed file, and the fix chosen there was to refuse, not slug |
| `…:627` | `validate.py:193-209` walks the whole tree and fails on `/Users/` or `/home/` in any `.json`. A verbatim foreign-subject artefact turns `commands.test` **permanently red with no legal repair** |
| `…:e02` | **AC5's numerator contradicts its own worked example** — "other than CONFIRMED" is 237/489 (48%), not the 173/489 (35%) printed beside it. Correct wording: *neither CONFIRMED nor UNVERIFIABLE* |

Majors owned here include the CRLF byte-for-byte claim (`…:501`), the `census_id` refuse-vs-write
contradiction that makes step 1 unimplementable as written (`…:281`), the manifest timing horn
(`…:7e4`), and the missing retry loop (`…:926`).

## Intent

Measured on 2026-08-26 during the highper-gateway reconciliation: **303 claims were verified
against the tree and none of them are in the kit.**

The run produced, per use case, a set of assertions extracted from a roadmap, each checked against
the source and classified `CONFIRMED / STALE-CITATION / OVERSTATED / UNDERSTATED / UNVERIFIABLE`
with evidence. That is 303 durable, re-checkable facts about a real codebase. **They came back as
prose in a subagent's reply**, were pasted into a markdown file, and are now unqueryable. Only the
18 rows the two reviewers emitted reached the `finding` table, because `kit-finding.sh` is the
only structured intake the kit has.

So the most valuable artefact this kit has produced on a real subject cannot be counted, diffed,
re-checked on a later commit, or reported by `kit-status.sh`. A second reconciliation six months
from now could not tell you which verdicts changed.

**A finding is not the right shape for this and must not be stretched into one.** A finding says
*"this code is defective."* A census claim says *"this document asserts X; the tree says Y."* The
subject of a finding is code; the subject of a claim is a **claim**. Recording 303 roadmap
assertions as findings would flood the criticals gate with rows that are not defects and would
make `findings-outpace-dispositions` structurally unfixable.

## Acceptance criteria

- [ ] A claim is recordable with at least: the source document and where in it, the assertion in
      one line, the verdict from a closed vocabulary, the evidence path, and whether the location
      was RE-DERIVED or copied from the source document.
- [ ] The vocabulary has ONE home and is asserted against by `tests/conformance.sh`, exactly as
      the finding vocabulary is against `kit-finding.sh --vocab`. It drifted across four locations
      once already.
- [ ] **`UNVERIFIABLE` is a first-class verdict, not an absence.** The 2026-08-26 run needed it
      immediately: `src/ha` and `src/health` are described as "empty directories" and git cannot
      track an empty directory, so the claim cannot be checked from a clone. A schema that forces
      a true/false answer there manufactures a wrong one.
- [ ] Claims are **orthogonal to findings** and land in a separate table. A claim that leads to a
      defect may reference a finding; it must not become one.
- [ ] `kit-status.sh` reports the census: counts by verdict, and the **drift rate as a fraction
      with its denominator**. "37 of 112 stale" — never an adjective.
- [ ] Re-running a census on a later commit produces a **comparable** result: which verdicts
      changed, which claims are new, which disappeared. If two censuses cannot be diffed, this
      task has not been done — that is the whole point of recording them.
- [ ] Mutation proof: a claim recorded with an invalid verdict is rejected, and the batch records
      nothing, matching `kit-finding.sh`'s all-or-nothing rule.

## Notes

**Do not design this before `T-20260826-no-agent-owns-verifying-documented-claim`.** That task
decides who produces claims and in what shape; this one decides where they land. Building the
store first risks a schema fitted to one hand-written prompt rather than to a contract. **Recorded
as `blocked_by:` in the frontmatter as of 2026-08-27** — it sat here as prose for a day, which is
this task's own defect one level up: a fact written where a person will read it and no machine
will, so `kit-plan` could not see an ordering the text asserted.

The key is `blocked_by` with an **underscore**, though the CLI flag that writes it is
`--blocked-by` with a hyphen. Writing the hyphen form in frontmatter is accepted silently, yields
no edge, and `kit-index.sh` plus `kit-plan.sh` both run clean — see
`T-20260827-an-unknown-frontmatter-key-is-discarded-`.

## CORRECTION 2026-08-27 — there is no test fixture

**This section previously said:** *"The 2026-08-26 output is the test fixture. 303 real claims
across 16 use cases, with verdicts and evidence, in `docs/RECONCILIATION-2026-08-26.md` in the
trial copy. Any schema proposed here should be able to hold that document losslessly."*

**That is false, and it was false when written.** `docs/RECONCILIATION-2026-08-26.md` is 131 lines
holding a **16-row table of per-use-case counts**. It contains exactly one verdict token in the
whole file. The 303 individual claims — assertion, verdict, evidence, each — are in no artefact.

Verified 2026-08-27 by enumeration, not assumed:

- The 2026-08-27 aeon run has the same shape: 489 claims survive as a 157-line narrative with a
  ranked top-16, no per-claim record.
- **All 35 subagent transcripts from both trials are gone.** The `spend` rows preserve every
  `agent_id`; a search across all 15 project transcript directories under
  `~/.claude/projects/` found **0 of 35** matching `agent-<id>.jsonl`. Checked the trial copies'
  own project directories (`…tmp-aeonm-copy`, `…tmp-trial-copy`) as well as the kit's — all empty
  of subagent transcripts.

So **792 verified claims have been produced and none survives at claim granularity.** Not
"unqueryable" — absent. Nothing can be re-checked, diffed, or attributed.

**Consequences for this task, which are the reason to record the correction rather than fix the
sentence:**

1. **There is no free test data.** Any schema built here must be validated against a census that
   does not yet exist. Manufacturing a fixture by hand risks fitting the schema to the example.
2. **This raises the task's priority rather than lowering it.** The argument was "our best
   artefact is unqueryable". The real argument is "our best artefact evaporates, and each new one
   costs ~35k BTE per claim to produce" — 11.1M and 17.0M BTE spent, nothing durable retained.
3. **The next census must be the fixture.** Build the contract and the store first, then run
   census #3 against a real subject, and that run is both the first surviving census and the
   validation of the schema. Running a census first spends another eight figures of BTE producing
   a third narrative that also disappears.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md` kit defect 1;
`docs/TRIALS/2026-08-27-aeon-reconciliation.md`.

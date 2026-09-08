---
id: T-20260826-no-agent-owns-verifying-documented-claim
title: No agent owns verifying documented claims against the tree
epic: agent-contracts
tier: T2
paths: agents, docs/agents-README.md, templates/project-profile.md
state: completed
---

## Intent

The kit ships eight agents: `researcher`, `coder`, `documenter`, `adr-scribe`, `tester`,
`approach-reviewer`, `implementation-reviewer`, `security-reviewer`.

On 2026-08-26 the job that unblocked an entire brownfield session was *"read what this document
claims about the code, check each claim against the tree, and return a verdict with evidence."*
**It matched none of the eight**, so it ran on sixteen `general-purpose` subagents driven by a
prompt written by hand for that one run.

The mismatch is not cosmetic. Each shipped agent is defined by a different relationship to the
work:

| agent | subject | when |
|---|---|---|
| `researcher` | a decision not yet made | before |
| `coder` | a change to make | during |
| the three reviewers | a change just made | after |
| `documenter` / `adr-scribe` | a record of what happened | after |
| **the missing one** | **a claim already written down** | **before anything is planned** |

**On brownfield this is the FIRST job, not an auxiliary one.** You cannot tier, plan, or scope
work on an unfamiliar codebase whose documentation you have not checked. The 2026-08-26 trial
demonstrated the cost of skipping it: three of four candidate tasks selected from the roadmap were
already done, and the two genuinely valuable ones only became visible after the census.

## What the hand-written prompt had to say, and why it belongs in a contract

Three instructions were load-bearing and would be lost if this stays ad hoc:

1. **Re-derive every location.** A line number copied out of the document being audited is not
   evidence. On this subject a `cargo fmt --all` had invalidated every citation six hours after
   the document was written.
2. **`UNVERIFIABLE` is preferred over a guess**, and the reason must be given. Without it an agent
   asked to classify an unobservable claim will manufacture a verdict.
3. **Read only.** The subject of the work is a document, and the output is a proposal.

## Acceptance criteria

- [ ] An agent contract exists for this job, with a name that says what it does to a claim rather
      than what it reads.
- [ ] The three rules above are IN the contract, not in the operator's prompt.
- [ ] Its verdict vocabulary is the one from
      `T-20260826-a-verified-claim-about-the-tree-has-no-a`, read from a single home rather than
      restated — the finding vocabulary drifted across four locations once and produced agents
      whose output the recorder rejected.
- [ ] Output is structured DATA on the same principle as the reviewers': one JSON object, no
      prose to parse. Every defect in the old harvester came from parsing.
- [ ] `docs/agents-README.md` places it in the pipeline and says explicitly that on brownfield it
      runs BEFORE tiering and planning.
- [ ] The model tier is justified against measurement, not assumed — and this is **the same
      experiment as the criterion below, not a second piece of work**. The 2026-08-26 run cost
      **6,547,551 BTE across 17 subagents** for 303 claims, which is what the tier *costs* and not
      what it *proves*.
- [ ] **AMENDED 2026-09-08 — the original is kept immediately below rather than overwritten,
      because why it failed is the point.** The contract is demonstrated by auditing one unit
      **twice at two model tiers** — same subject at a pinned `subject_sha` with a clean tree, the
      shipped contract as the instrument, byte-identical prompts — and the two arms compared
      **claim by claim against each other**. One variable moves. Divergence is a finding about the
      contract or about the tier, not automatically a regression.
    - Comparison against the 2026-08-26 and 2026-08-27 runs is admissible **only** against what
      survives them: the aggregate per-use-case counts and the ~ten narrated exemplars. **The
      per-claim verdicts of both runs do not exist** — not unqueryable, absent — and are not an
      admissible baseline.
    - Any such comparison is a **sanity check and never proof**. Those runs used a hand-written
      prompt; comparing one to a run of the shipped contract moves the model *and* the instrument,
      and a diff in which more than one variable moved is uninterpretable under D3's attribution
      rule.
- [ ] ~~**WITHDRAWN 2026-09-08.** It is demonstrated on the 2026-08-26 corpus and its verdicts
      compared against that run. Divergence is a finding about one of the two, not automatically a
      regression.~~ Unmeetable by anyone, at any cost, for two independent reasons: the corpus was
      delivered into an isolated copy with no remote and does not exist at claim granularity, and
      the comparison it asks for would move two variables even if it did. Filed and reproduced as
      `T-20260907-ac7-names-a-corpus-that-no-longer-exists`.

## Notes

**The gap this closes is the one the operator described independently.** Three of their projects —
`highper-gateway`, `aeon`, `medha` — were paused for the same stated reason: unmanageable in a
single-agent workflow. The subagent pipeline existed a month before the worst of it and was still
unusable for *"not having an established starting point."* A census IS that starting point, and
the kit has no agent for it.

**Do not fold this into `researcher`.** `researcher` produces a design input for a decision not yet
made and its output is attacked by `approach-reviewer`. This agent audits assertions that already
exist and its output is a map. Merging them would give one agent two subjects, which is how
`domain` and `pattern` collapsed into one field until the taxonomy was split.

**Sequencing:** this decides the contract, `T-20260826-a-verified-claim...` decides the store.
Design this one first; building the store against a hand-written prompt would fit the schema to an
accident.

## The AC6 / AC7 amendment, 2026-09-08

**Amended on the operator's instruction**, on the reasoning filed in
`T-20260907-ac7-names-a-corpus-that-no-longer-exists` and reproduced there before filing.

**What was wrong with AC7:** it named a baseline that had already evaporated when it was written.
792 verified claims across the 2026-08-26 and 2026-08-27 runs, roughly 6.5M and 13.9M BTE, were
delivered into isolated copies with **no remote** and survive nowhere at claim granularity; all 35
subagent transcripts are gone too. The criterion could not be met by anyone at any cost, and no
amount of care in running it would have fixed that.

**Why AC6 and AC7 became one criterion.** They were asking for the same run. AC6 wanted a tier
comparison; AC7 wanted a demonstration against a baseline. A two-arm run of the shipped contract on
one pinned subject is both — and it is the only shape in which exactly one variable moves.

**Status of the amended criterion — a recommendation, not a mark.** The experiment at
`docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/` appears to satisfy it: pinned subject
(`05c56eb`, clean tree, zero commits since the original audit), shipped contract, byte-identical
prompts, `opus` against `sonnet`, both arms' raw JSON committed, compared claim by claim. The
historical figures are used there as a sanity check and explicitly not as proof. **The box is left
unticked deliberately** — per the working agreement the close is the operator's, and two contract
defects the experiment exposed are still open:
`T-20260908-a-cited-range-that-still-contains-its-su` and
`T-20260908-the-contract-requires-a-production-calle`. Neither blocks this criterion; both change
what a future census means.

**What did NOT change:** the withdrawn text stays visible above. ADRs 0005 and 0006 are kept
unedited here for the same reason — the record should show what was wrong, not only what replaced
it.

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 2.

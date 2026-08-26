---
id: T-20260826-no-agent-owns-verifying-documented-claim
title: No agent owns verifying documented claims against the tree
epic: agent-contracts
tier: T2
paths: agents, docs/agents-README.md, templates/project-profile.md
state: created
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
- [ ] The model tier is justified against measurement, not assumed. The 2026-08-26 run cost
      **6,547,551 BTE across 17 subagents** for 303 claims; whether a cheaper model reaches the
      same verdicts is answerable and unanswered.
- [ ] It is demonstrated on the 2026-08-26 corpus and its verdicts compared against that run.
      Divergence is a finding about one of the two, not automatically a regression.

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

Source: `docs/TRIALS/2026-08-26-highper-gateway-reconciliation.md`, kit defect 2.

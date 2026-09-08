---
id: T-20260908-the-contract-requires-a-production-calle
title: The contract requires a production-caller check and tells the auditor not to leave the unit to make it
epic: agent-contracts
tier: T2
lang: bash
paths: agents/claim-auditor.md, docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/README.md, docs/MODELS.md
state: created
---

## Intent

`docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/README.md:158-163` proposes:

> **The reachability question belongs in the contract.** The opus arm performed it unprompted; the
> sonnet arm did not. […] the contract should require it rather than hope for it […] it may be that
> the tier is required *only because the contract leaves reachability implicit.*

**The premise is false and this task exists to replace it.** The contract does not leave
reachability implicit. `agents/claim-auditor.md:61-76` names it first of three, in bold, with
evidence:

> **Ask the three questions the checks are blind to.** […]
> - **Does it have a production caller?** A subsystem can compile, be fully unit-tested, be `pub`
>   and re-exported — and be reached from nothing a shipped artefact runs.

Nothing was performed "unprompted". Both arms were given it. Filing the README's recommendation as
written would file a gap that is not there.

**The real defect is a contradiction between two sections of the same contract**, and it is worth
more than the gap it replaces.

## The contradiction

| section | line | instruction |
|---|---|---|
| How to work a document | `:64` | **Does it have a production caller?** — answerable only by searching the whole tree for construction sites |
| Scope discipline | `:158-160` | **"Audit the unit you were assigned and no other."** *"Wandering makes two agents report the same claim with different verdicts and nothing able to tell which is which."* |

A production-caller check **is** leaving the unit. The contract requires it in one section and
warns against it in another, gives no rule for resolving the two, and the warning names exactly the
outcome the experiment produced — two agents, same claims, different verdicts.

## Reproduced 2026-09-08 from the committed JSON

The two arms resolved the contradiction in opposite directions, and each did so **openly**.

**Sonnet chose scope discipline, and said so in its own `narrative`:**

> "I did not check any file outside `src/tls/`, `src/config/schema.rs`, `src/runtime_config/`,
> `.github/workflows/`, and `examples/configs/` — **sufficient to check every claim in this unit**,
> but I did not survey the rest of the tree."

That is the reachability check being declined, declared, and justified as sufficient — under a
contract section that says declining is correct. It then returned **zero** `OVERSTATED` verdicts on
a subject whose recorded dominant failure mode is overstatement.

**Where each arm actually looked**, counted from every `src/**.rs` path in the evidence, notes and
narrative of both files:

| | src paths cited | outside `src/tls/` | the discriminating one |
|---|---|---|---|
| opus | 17 | 4 | **`src/proxy/handler.rs`** — the shipped request path |
| sonnet | 13 | 4 | none — config schema and `runtime_config` only |

Both left the module. **Only opus entered the code that runs in production**, which is where a
production caller either exists or does not. Sonnet's four outside files are configuration
plumbing: they say how a thing is *configured*, never whether it is *constructed*.

That is the whole five-claim `OVERSTATED` gap, and it is a scoping decision rather than an
analytical one.

## Why this matters more than the version it replaces

The README's framing implies a **cheap fix**: state the reachability requirement and the gap
between tiers narrows, so the expensive tier may not be needed. That fix is unavailable — the
requirement is already stated in bold.

What is actually available is narrower and testable: **tell the auditor how far it may travel to
answer the caller question.** Sonnet did not fail to know the question. It answered a scoping
instruction that pointed the other way.

This does not overturn the experiment's conclusion — the opus tier still produced the findings and
the cheap tier still did not. It removes the escape hatch the README offered from it, and
`README.md:162-163` ("it may be that the tier is required *only because*…") should be corrected
rather than quoted forward.

## Acceptance criteria

- [ ] `agents/claim-auditor.md` resolves the contradiction explicitly: a rule saying that following
      a symbol to its construction sites is **required and is not "wandering"**, and what the
      auditor may read outside its unit while still not grading claims that belong to another unit.
- [ ] `Scope discipline` is amended in the same commit so the two sections cannot be read as
      opposed — the current text is not wrong on its own terms and must keep the property it
      protects, which is that no two agents grade the same claim.
- [ ] The narrative requirement distinguishes *"I did not check outside the unit"* from *"I checked
      for callers and found none"*. Sonnet's sentence is currently contract-compliant and reads as
      diligence; the two are opposite results and must not share a sentence.
- [ ] `README.md:158-163` is corrected: "unprompted" and "leaves reachability implicit" are refuted
      by `agents/claim-auditor.md:61-76`, and the correction is recorded rather than the text
      silently replaced.
- [ ] `docs/MODELS.md` cites the experiment for the tier decision **and** notes that its one
      proposed cheaper alternative was withdrawn on inspection, so nobody re-derives it.

## Notes

Filed 2026-09-08 on the operator's instruction to file "the reachability question", after checking
the premise. **What was asked for could not be filed as stated** — the contract already carries the
requirement — so the defect underneath it is filed instead, and the false premise is recorded here
rather than left in the README to be quoted forward.

Reproduced from `arm-opus.json` and `arm-sonnet.json`, not from the README. The `src/proxy/handler.rs`
asymmetry and sonnet's own scope sentence are not in the write-up; they are what makes this a
scoping defect rather than a claim about model ability.

**Not a duplicate of `T-20260908-a-cited-range-that-still-contains-its-su`.** That one is the
`STALE-CITATION` definition and accounts for 3 of the 8 disagreements between the arms. This one is
the reachability scoping rule and accounts for the other 5. Together they explain every disagreement
in the unit, which is why neither should be closed by fixing the other.

**Tier declared T2, not classified.** Cross-section edit to a shipped contract that changes what
every future audit does and how much it costs; reversible as text, but every census taken under the
old wording becomes non-comparable. Run `tier-classify` rather than trusting this line.

**Deliberately does not choose the travel limit.** "Follow the symbol, do not grade another unit's
claims" is the obvious candidate and is a spend decision as much as a correctness one — a census is
split across agents partly to bound context. That is the operator's call.

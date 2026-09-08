---
id: T-20260908-a-cited-range-that-still-contains-its-su
title: A cited range that still contains its subject has no verdict in the contract
epic: agent-contracts
tier: T2
lang: bash
paths: agents/claim-auditor.md, tooling/kit-claim.sh, docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/README.md
state: created
---

## Intent

`agents/claim-auditor.md:92-93` defines the verdict:

> **`STALE-CITATION`** — the assertion is true; the location it cites has moved or gone. The
> substance survives, the pointer does not. Do not use this for a claim that is also wrong.

Documents cite **ranges**, not points. When the document cites `foo.rs:346-415` and the function it
describes now sits at `355-394`, the pointer has *moved* and the cited range *still contains the
subject*. The contract answers "moved or gone"; it does not answer **"moved but still containing"**,
and that is the majority shape of a citation in the one unit measured.

Two readings are defensible and the contract endorses neither:

- **Containment is sufficient** — a reader following the citation lands on the thing. `CONFIRMED`.
- **The pointer is the claim** — the document asserted a location and the location is wrong.
  `STALE-CITATION`.

**Until this is settled, no stale-citation rate from any run is comparable to any other**, because
two conforming auditors grade the same tree differently.

## Reproduced 2026-09-08 from the committed JSON, not from the write-up

Re-derived by reading `arm-opus.json` and `arm-sonnet.json` directly. Every citation-shaped claim in
the unit, with whether the document's cited range still contains the subject the auditor found:

| doc claim | cited range | where it actually is | still contains? | opus | sonnet |
|---|---|---|---|---|---|
| ROADMAP:188 ALPN | `manager.rs:244-248` | `253-257` | **no** — disjoint | STALE | STALE |
| ROADMAP:189 CertResolver | `manager.rs:179-318` | `266-334` | **no** — runs past the end | STALE | STALE |
| ROADMAP:217 UC3.C `needs_renewal` | `acme.rs:199-204` | `205-209` | **no** — adjacent, disjoint | STALE | STALE |
| ROADMAP:197 OCSP retry/backoff | `ocsp_fetcher.rs:86-277` | `215-254` | **yes** | CONFIRMED | STALE |
| ROADMAP:209 UC3.A request body | `ocsp_fetcher.rs:346-415` | `355-394` | **yes** | CONFIRMED | STALE |
| ROADMAP:214 UC3.B `attach_ocsp_response` | `ocsp_stapler.rs:97-136` | `95-137` | **yes** | CONFIRMED | STALE |

**Containment predicts the disagreement in all six cases.** Where the cited range no longer contains
the subject, both arms agree it is stale. Where it still does, they split — every time, in the same
direction. This is not model noise and it is not a difference in care: it is two auditors applying
two readings of one under-specified sentence.

(The seventh citation-shaped claim, ROADMAP:206, is a commit hash that resolves to nothing. Both
arms called it STALE. It is not a range case and it is not affected.)

The sharpest single instance is UC3.B, where the disagreement is visible **inside one arm's own
row**: sonnet's `note` reads *"Doc cites :97-136, near-exact"* and its `verdict` is
`STALE-CITATION`. A citation the auditor itself describes as near-exact was graded as drift.

## What it costs, quantified

Stale-citation rates from the two arms, as recorded and as they would read under the other reading:

| | as recorded | if the three containment cases were graded the other way |
|---|---|---|
| opus | 4 / 24 = **17%** | 7 / 24 = 29% |
| sonnet | 8 / 20 = **40%** | 5 / 20 = 25% |

The headline 40%-against-17% gap is **roughly half an artefact of the ambiguity**, not a measurement
of the models. `docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/README.md:112-120` says the rate
should not be quoted until this is fixed; this task is what would let it be quoted.

Note this cuts both ways and is not a case for either reading — under containment-is-stale the
*expensive* arm is the one that under-reports.

## What the contract does say, and why none of it resolves this

Checked before assuming the gap was real:

- **Rule 1, "RE-DERIVE EVERY LOCATION"** (`agents/claim-auditor.md:31-36`) governs the location the
  auditor **emits as evidence**. It says nothing about how to **grade** the location the document
  cited. Both arms obeyed it — both re-derived, both reported `RE-DERIVED`, and they still disagreed.
- **The `location` axis** (`RE-DERIVED` / `COPIED`) records the auditor's own provenance. It is
  explicitly "a separate axis from the verdict" (`tooling/kit-claim.sh:55-56`) and cannot carry this.
- **`kit-claim.sh --vocab`** prints bare tokens with no definitions, so the vocabulary's stated
  single home does not define the term at all.
- The word "range" appears nowhere in `agents/claim-auditor.md` in this sense.

## A second gap found while checking the first

The definition exists in **two** places and only one of them is guarded:

- `agents/claim-auditor.md:92-93` — the prose the auditor reads.
- `tooling/kit-claim.sh:37-41` — a comment block carrying the same five definitions.

`tests/conformance.sh:224-261` compares only the **token list** (`CONFIRMED STALE-CITATION …`)
between `--vocab` and each agent's inlined copy. It does not compare the definitions. So a fix
applied to one file and not the other passes conformance green, and the two definitions drift
silently — which is the failure the vocabulary guard was written to prevent, one level down.
The step's `seen -eq 0` denominator assertion is sound and is not what is wrong here.

## Acceptance criteria

- [ ] `agents/claim-auditor.md` states the verdict for a cited range that still contains its subject,
      as a rule an auditor can apply without judgement — including the degenerate cases: a range that
      contains the subject **and** ~130 unrelated lines, and a cited range the subject now
      *encloses* (UC3.B's shape, where doc `97-136` sits inside actual `95-137`).
- [ ] The same rule lands in `tooling/kit-claim.sh`'s definition block in the same commit, worded
      consistently.
- [ ] The three disputed claims in `arm-opus.json` / `arm-sonnet.json` are re-graded **on paper** under
      the chosen rule and the result recorded in the experiment README. The committed JSON is
      **not** edited — it is the raw record of what each arm returned and it stays that way.
- [ ] `docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/README.md` §4 and §5 are corrected or annotated
      so the stale-citation row is either quotable or explicitly marked as not.
- [ ] Either conformance compares the definitions and not just the token lists, or a task is filed
      for that with this one named as the instance that found it.

## Notes

Filed 2026-09-08 on the operator's instruction, reproduced before filing per the standing agreement.
Found by the two-arm experiment in PR #35, which named it as a contract defect rather than a result;
this is that defect written down where it can be worked.

**Reproduced from the JSON, not carried forward from the README.** The README's §5 names three
disagreeing claims; reading the raw arms confirms those three and adds the containment rule that
predicts all six citation cases, which the README does not state.

**This is a defect in a contract, not in code**, and like
`T-20260907-ac7-names-a-corpus-that-no-longer-exists` it is filed as a task rather than a finding —
findings here are recorded by reviewer agents and attributing this to one would be false attribution.

**Tier declared T2, not classified.** The edit is wording in two files, which reads T1. It is declared
T2 because the ladder's T3 row names *contested behaviour* and both readings are genuinely defensible,
while its own criterion of reversibility keeps it below T3 — a wrong choice here is re-wordable, though
every census recorded under it would need re-grading. Run `tier-classify` rather than trusting this line.

**Not decided here, deliberately.** Which reading is right determines what a whole verdict class
counts, and the census store's schema is still open on
`T-20260826-a-verified-claim-about-the-tree-has-no-a`. That is the operator's call.

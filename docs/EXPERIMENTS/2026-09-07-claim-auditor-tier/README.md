<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# `claim-auditor` model tier: opus against sonnet, one unit, one variable

Run 2026-09-07. This is the experiment `docs/MODELS.md` has been asking for since PR #27 — the one
that decides whether `claim-auditor`'s `opus` tier is *required* or merely *what the two measured
runs happened to use*.

**Result up front: the tier is required. The cheaper arm returned zero OVERSTATED verdicts on a
subject whose dominant failure mode is overstatement, and missed it for one identifiable reason.**

---

## 1. What this is, and what it is NOT

**This is an experiment artefact, not a census.** It is deliberately NOT under `.project/census/`.
The census store is unbuilt and its schema is the subject of ten open criticals on
`T-20260826-a-verified-claim-about-the-tree-has-no-a`; writing these two files there would fit that
schema to whatever this one run happened to emit, which is the exact mistake
`tooling/kit-claim.sh` was ordered to prevent.

When the store lands, these two artefacts are candidate **input** to it, not a precedent for it.

The raw JSON from both arms is committed verbatim beside this file — `arm-opus.json`,
`arm-sonnet.json` — for the reason `T-20260907-ac7-names-a-corpus-that-no-longer-exists` records:
the 2026-08-26 and 2026-08-27 censuses, 792 verified claims and ~6.5M BTE, were delivered into
isolated copies with no remote and **survive nowhere**. Summarising these into this README and
discarding the JSON would repeat that exactly.

## 2. Design

| held constant | |
|---|---|
| subject | `highper-gateway` @ `05c56eb206142e5e5920b9430f3e83d1dc8881ad`, working tree clean (`subject_dirty = 0`) |
| unit | `docs/planning/ROADMAP.md` §2.3 UC3 — TLS termination, ACME, mTLS, OCSP, CRL (lines 184-233) |
| instrument | `agents/claim-auditor.md` as shipped, read by both arms from the same path |
| prompt | byte-identical apart from nothing — the same text was sent to both |
| **varied** | **model only: `opus` vs `sonnet`** |

The subject has not moved since it was audited: last commit 2026-05-16, zero commits since
2026-08-26. That is the variable usually hardest to pin and it cost nothing here.

**Unit chosen** for claim density, `file:line` citations on nearly every claim (so citation drift
is directly observable), and security relevance — two arms disagreeing about whether OCSP
verification exists matters more than disagreeing about a heading.

## 3. Cost

| | opus | sonnet |
|---|---|---|
| claims returned | **24** | 20 |
| tokens | 134,687 | 129,738 |
| wall clock | 10m 30s | 7m 34s |

**Token volume is within 4%.** The saving from the cheaper tier is therefore almost entirely the
per-token price difference, not less work — the cheap arm did not do less, it did the same amount
of work and reached different conclusions.

## 4. Verdict distributions, against the historical run

| verdict | opus | sonnet | 2026-08-26 run (303 claims, 16 units) |
|---|---|---|---|
| CONFIRMED | 10 (42%) | 10 (50%) | 142 (47%) |
| STALE-CITATION | 4 (17%) | 8 (40%) | 48 (16%) |
| **OVERSTATED** | **5 (21%)** | **0 (0%)** | **50 (17%)** |
| UNDERSTATED | 4 (17%) | 2 (10%) | 31 (10%) |
| UNVERIFIABLE | 1 (4%) | 0 (0%) | ~32 (11%) |

<sub>Counts computed from the committed JSON, not by hand — an earlier hand tally of this table
said 23 claims and 9 CONFIRMED for the opus arm and was wrong on both. Re-derive from the files
rather than quoting this table forward.</sub>

The historical column is a **sanity check, not proof** — one unit against a 16-unit aggregate, and
the 2026-08-26 run used a hand-written prompt rather than this contract.

Read that way it still says something clear. **The opus arm tracks the historical distribution on
every row.** The sonnet arm does not: it returns 0% where history says 17%, and 40% where history
says 16%.

## 5. Agreement, claim by claim

Over the 20 claims both arms raised: **11 full agreements (55%), 1 partial, 8 disagreements.**

Every one of the 8 disagreements has one of exactly two causes.

### Cause 1 — reachability (5 claims). This is the real finding.

The opus arm checked, for each capability the document calls current state, **whether anything in
the shipped binary constructs it**. The sonnet arm checked whether the code exists and does what it
says. On this subject those are different questions with different answers:

| claim | sonnet | opus | what opus found |
|---|---|---|---|
| "mostly working; some silent stubs" | CONFIRMED | **OVERSTATED** | four of ten current-state bullets have no production caller |
| TLS passthrough parses SNI | CONFIRMED | **OVERSTATED** | `extract_sni` / `passthrough_tls` called from nowhere outside the module |
| cert hot-reload *with validation* | CONFIRMED | **OVERSTATED** | `CertificateReloader` is tests-only; the shipped startup path stores PEM **without validation** |
| ACME HTTP-01 + TTL store | STALE-CITATION | **OVERSTATED** | `Handler::new` hard-codes `challenge_store` to `None`; the route can never answer |
| CRL fetcher + delta framework | CONFIRMED | **OVERSTATED** | `CrlChecker` constructed only in its own tests; no client cert is ever CRL-checked |

**This is not a subtle difference of opinion. It is the dominant failure mode of this subject**, and
the 2026-08-26 trial said so in advance:

> The dominant failure mode is unreachable code, not drift. Twelve of sixteen use cases contain a
> subsystem that compiles, is tested, and is never called.

The cheap arm returned an audit in which that category does not appear at all. A planner acting on
it would budget ~1 day for UC3.C — and, per the opus arm, spend it writing code that changes
nothing observable, because the stub it patches has no callers and the working implementation
already exists next door.

### Cause 2 — an ambiguity in the contract, not a difference in ability (3 claims)

On UC3.A, UC3.B and the OCSP fetcher, the document cites a **line range** that still contains the
function it describes, but whose start line has moved. Sonnet called all three STALE-CITATION;
opus called them CONFIRMED, on the ground that the cited range still contains the subject.

**Both readings are defensible and the contract does not say which is right.** This is a defect in
`agents/claim-auditor.md`, not evidence about either model, and it should be fixed before either
arm's stale-citation rate is quoted as a measurement.

## 6. Where the two arms agreed, and it matters

Both independently found things the document gets wrong, which is evidence the contract works at
both tiers for the easier half of the job:

- **A cited commit hash resolves to nothing.** The roadmap credits B11.1 to `fef5bb4`; both arms
  re-derived the real commit as `2ab3586`, same date. Opus additionally found the same wrong SHA
  copied forward from `ROADMAP_v1.md:3252` — it was never re-derived, only propagated.
- **UC3.G is already done.** `acme.directory_url` and its example config exist and are wired in.
  Both arms then found the *real* narrower defect the roadmap does not mention:
  `effective_directory_url()` has zero callers, so `staging: true` is inert.
- **UC3.B is worse than documented** — the attach path is not a no-op in a live path, it is never
  called at all.

## 7. What this answers, and what it does not

**Answers `docs/MODELS.md`'s open question.** The `opus` tier is required, on this subject, for the
category of finding that made the audit worth running. `MODELS.md:16` should stop reading
*"unjustified"* and start reading *"measured 2026-09-07; see `docs/EXPERIMENTS/…`"*.

**Does not answer** whether the tier is required on a subject whose failure mode is drift rather
than unreachability. One unit, one subject, one language. The result is a floor — *there exists a
real subject where the cheap tier loses the main finding* — not a general law.

`[judgement]` The floor is enough. The tier question was asked because nobody had evidence either
way; there is now evidence one way, and the burden moves to whoever wants to lower the tier.

## 8. What should follow

1. **Amend `docs/MODELS.md`** to cite this experiment instead of calling the tier unjustified.
2. **Fix the range-containment ambiguity** in `agents/claim-auditor.md` before quoting any
   stale-citation rate.
3. **AC6 is answered; AC7 is not**, and cannot be — see
   `T-20260907-ac7-names-a-corpus-that-no-longer-exists`. This experiment is what AC7 should have
   asked for.
4. **The reachability question belongs in the contract.** The opus arm performed it unprompted; the
   sonnet arm did not. If it is the dominant failure mode on brownfield subjects, the contract
   should require it rather than hope for it — which would also narrow the gap between tiers, and
   is a cheaper fix than mandating `opus` forever.

Item 4 is the one worth arguing about: it may be that the tier is required *only because the
contract leaves reachability implicit.*

<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — what identifies a claim, who computes it, and when

> # ⚠ REJECTED 2026-09-08. Do not build from this document.
>
> Two `approach-reviewer` passes, run in parallel with no sight of each other, returned **REJECT**
> and **REVISE** — 37 findings, 9 critical. Both replies are committed verbatim beside this file as
> `2026-09-08-claim-identity-review-a.json` and `-b.json`; read those, not this.
>
> **The diagnosis below does not hold**, and everything after it rests on the diagnosis. Both
> reviewers refuted it independently and by different routes: a hash over *raw* claim text is
> content-derived yet immune to `normalise` being redefined, so one value can serve both jobs; and
> the "no single value works" argument is circular, true only under an unstated premise — *re-keying
> must stay free* — which this document then sells as the payoff of the split it justifies.
>
> **Kept unedited, deliberately**, exactly as ADRs 0005 and 0006 are: the record should show what
> was wrong, not only what replaced it. Three things have moved on since, all in
> `2026-08-27-census-store.md`: **D5** decides what a disposition attaches to, **F1b** states the
> refusal rule this file defers as "a separate question", and **F1c** defines `unit` — which this
> file uses in *both* its identifiers and never defines, the first thing both reviewers named.
>
> Two statements below are now simply false of the tree and are not corrected in place: *"three of
> the ten open criticals"* (the count has moved twice since), and *"the label on the first row is
> wrong"* in §"What this does not settle" (it was relabelled, and the finding is marked fixed).

**Task:** `T-20260826-a-verified-claim-about-the-tree-has-no-a`
**Tier:** T3 — inherited from that task's `tier.rule: tooling/kit-index.sh T3` trigger.
**Answers three of the ten open criticals on that task.** It does not revise the census store
design; it settles the one question three of its criticals are asking in different words.

## The three criticals, quoted

| id | class | says |
|---|---|---|
| `26925ff4` | correctness | `claim_key` is still undefined: suffix, `id_ambiguous` and ordinal are all proposed and none designated; an ordinal in the key breaks AC6 across censuses |
| `b032ddaf` | false-rationale | "Re-keying stays free forever" is falsified by D2 in the same revision: a claim-disposition event must name a claim, freezing the key in the committed log |
| `65e3d2a2` | correctness | `normalise` is said to run at index time and never in awk, but `kit-index.sh` contains zero `python3` invocations and is awk; F4 is relocated, not fixed |

## The diagnosis: one name is being asked to do two incompatible jobs

Revision 2 has a single `claim_key` and needs it to do two things that pull in opposite
directions:

| job | needs an identity that is | because |
|---|---|---|
| **match a claim across two censuses** — the store's AC6 | derived from **content**, and unchanged when the claim moves in the document | a claim that shifted down twenty lines is the same claim. A diff that reports it as *disappeared + new* fails AC6, which says plainly that if two censuses cannot be diffed the task has not been done |
| **anchor a disposition to a claim** — D2 | **committed and unrecomputable** | a disposition is append-only and names a claim. If what it names can be recomputed, then changing `normalise` silently retargets it at a different claim, and the record says something nobody wrote |

The first job **forbids the ordinal**, because position moves. The second job **forbids a content
hash**, because a hash is exactly what gets recomputed. Revision 2 offers both mechanisms for one
key, which is why the reviewer reports that none is designated: **the text cannot designate one
without breaking the other job.**

That is the finding under `26925ff4` and `b032ddaf` read together. It is not that the author failed
to choose. It is that no single value satisfies both, so the choice as framed has no answer.

## The proposal: two identifiers, one job each

### 1. `claim_ref` — the disposition anchor. A coordinate, not a hash.

```
claim_ref = (census_id, unit, ordinal)
```

A position in a committed artefact file, read straight off the JSON's ordered `claims` array.

- It is what a `claim-disposition` event names, and it **is** frozen there — correctly, because a
  coordinate into a file that does not change cannot come to mean something else.
- It needs no normalisation, no hashing and no new dependency. It is three fields copied.
- **This answers `b032ddaf`.** Re-keying stays free because **nothing committed names
  `claim_key`**. What is frozen is a coordinate, and a coordinate was never going to be re-keyed.
  The revision's claim was true of the mechanism and false of the sentence it was attached to.

### 2. `claim_key` — the cross-census matcher. Derived, disposable, never committed.

```
claim_key = hash(subject_repo, source_document, unit, normalise(claim_text))
```

**No ordinal.** It lives only in the derived table, and is dropped and rebuilt with the index like
everything else `ADR 0004` governs.

- **This answers `26925ff4`.** With the ordinal out, an edit that inserts one claim no longer
  renumbers every claim below it into *disappeared + new*, so AC6's diff survives ordinary
  document editing.
- The occurrence suffix, the `id_ambiguous` flag and the `claim_id_collisions` counter all stay.
  They now decorate a **purely derived** value, so getting any of them wrong costs a rebuild and
  nothing else — which is the property revision 2 wanted and could not have while the key was also
  the anchor.
- The within-unit ordinal remains available as the collision tiebreak, because `claim_ref` already
  carries it. It is used to *disambiguate a display*, never to *form the matching key*.

These are the same three mechanisms revision 2 proposed. The change is that they are **assigned to
jobs** rather than offered as alternatives to each other.

## The hole this opens, and the control that closes it

Revision 2, line 247:

> A unit re-run mid-census **overwrites its own file** in the same `census_id` directory. That is
> correct — a corrected audit of one unit replaces the failed one, and git holds the prior version.

If the artefact can be overwritten then `(census_id, unit, ordinal)` is **not** a coordinate into an
immutable file, and a disposition written before the overwrite points at whatever now occupies that
ordinal. Silently. That is the same shape as deleting a `Superseded-by:` marker being the cheapest
way out of a gate.

**Control: the disposition event carries `unit_sha`** — the hash of the artefact file as it stood
when the disposition was made. At index time, a disposition whose `unit_sha` does not match the
artefact's current hash is reported as **stale** and **not applied**. It is not deleted, and it is
not silently honoured.

This keeps line 247's rule intact and makes its consequence visible. It is a control that can fail:
seed a census, disposition a claim, overwrite the unit, rebuild, and assert the disposition is
reported stale rather than applied to the new claim at that ordinal.

## `65e3d2a2` — `normalise` has no mechanism, and the honest answer is that one must be built

The design says `normalise` "is defined **once, in `kit_claims.py`, and applied only at index
time** — never in awk". Verified against the tree on 2026-09-08:

- `kit-index.sh` contains **zero** `python3` invocations.
- `tooling/kit_claims.py` **does not exist**.
- The cited precedent `kit_findings.py` is invoked by `kit-finding.sh` at **emit** time — not by
  `kit-index.sh` at index time. `kit-resolve.sh` and `kit-review-record.sh` invoke it the same way,
  all on the write path.

So the reviewer is right and the wording understates it: the design moved the work to a place that
has no mechanism to do it, and named a precedent that runs on the other side of the boundary.

| option | cost | consequence |
|---|---|---|
| **A. `kit-index.sh` invokes `kit_claims.py` for census ingestion** | `python3` becomes a dependency of the **derive** path, not only the write path | the design as written becomes true. Today a fresh clone can rebuild the index with no python at all; after this it cannot |
| **B. `normalise` in awk** | `tolower` plus two `gsub`s, no new dependency | `tolower` is locale-dependent in awk and subjects are not guaranteed ASCII. It also puts one definition in two languages, which is the drift this repo files against itself elsewhere |
| **C. `normalise` at emit time in `kit-claim.sh`** | matches the existing precedent exactly | **rejected on architecture**: it writes a normalised value into the committed artefact, which is the thing raw-artefact-verbatim exists to prevent |

**Recommended: A, stated as a new mechanism rather than an existing one.** B trades a dependency
for a correctness risk in the one direction this store cannot absorb, and C is out.

One consequence worth naming rather than discovering: under this proposal `normalise` is needed
**only** for `claim_key`, which is purely derived. So if A is judged too expensive, the fallback is
not to reimplement it in awk — it is to accept a coarser matcher and say so in the diff output.
AC6 asks for a comparable result, not a perfect one.

## What this does not settle

- `5c1284da` — `census_id` and `--unit` as path components with no refusal rule. Separate question;
  the precedent is `kit-plan.sh:125`, which already refuses a `--goal` outside
  `[letters digits . _ -]`.
- `e02d6b62` — the AC5 drift label. The numbers are internally consistent (173 + 64 = 237,
  489 − 64 = 425); the **label** on the first row is wrong.
- `627b9764` — `validate.py` versus verbatim foreign artefacts. Latent, not firing: the two
  artefacts committed on 2026-09-07 contain zero matching paths.
- **The matcher's quality.** F15's variance measurement still bounds the best case and still has
  not been run. This document decides what the key *is*, not how well it matches.

## For the reviewer — the three things I would attack first

1. **Is the artefact immutable enough for a coordinate?** The `unit_sha` control assumes a unit file
   is replaced atomically as a whole. If a unit can be appended to, or written incrementally, the
   control is weaker than it looks and `claim_ref` inherits that weakness.
2. **Two identifiers is more apparatus than one.** The entire argument for it is that no single
   value satisfies both jobs. If that is wrong — if some third form does satisfy both — this
   document is wrong from the diagnosis down, not just in its choice.
3. **Option A makes `python3` a dependency of the derive path.** Three write-path scripts already
   require it, so this is not a new dependency for the kit; it *is* a new one for `kit-index.sh`,
   which every adopter runs and which can currently rebuild from a clone with no python present.

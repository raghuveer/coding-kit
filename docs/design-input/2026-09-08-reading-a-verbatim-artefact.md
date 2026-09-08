<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design question — how the derive path reads a verbatim artefact

> # ⚠ WITHDRAWN 2026-09-08. The premise below is false. Do not cost from this document.
>
> **Superseded-by: docs/design-input/2026-08-27-census-store.md**
>
> Ten critical findings were anchored here. Each was classified by three readers -- the author and
> two independent verifiers who could not see each other or the author's split. **Both verifiers
> returned the same result: eight die with this document, two transfer.** The author had called
> nine/one and was overruled on `0cb26a61`; the reason is recorded below because the correction is
> more useful than the count.
>
> **The two that transfer were RE-FILED against the surviving design before any mark was made**,
> because `--by` names one target and cannot carry a per-finding destination:
>
> | original | re-filed as | the live defect |
> |---|---|---|
> | `edf8adcc` | `e71bd25e` | step 2 specifies no per-artefact isolation while F12 guarantees committed artefacts may be malformed -- and F12 is now executing code at `tooling/kit-claim.sh:212-226` |
> | `cb39b589` | `6a07968d` | the claims-as-events route is excluded on a ~270KB sizing argument that D5 concedes at `:239-244` with ~200KB of disposition text |
>
> **The eight that die** attack this document's own reasoning and have no carrier elsewhere: the
> false `jf()` premise, the inverted `T-20260808` citation (filed twice, by both reviewers), the
> "gates everything else" framing (also filed twice), the CI-measurement self-contradiction,
> option B's "one language rather than two", and `readfile()` returning NULL. Neither `readfile`
> nor `json_each` nor `sqlite3` appears anywhere in the surviving design, whose derive path is
> `kit_claims.py`.
>
> **Why the author's `0cb26a61` call was wrong, recorded because the mistake generalises.** It was
> kept alive by reading it as *"derivation must distinguish an absent artefact from an empty one"*
> -- a broader claim than the finding makes. A finding is superseded on its own text, not on a
> generalisation constructed from it, and constructing one to keep it alive is the same move that
> produced five wrong premises in a single day. **If that broader question matters, it needs filing
> on its own evidence; no finding currently holds it.**
>
> **One number in this file was wrong and is corrected here rather than left disagreeing with
> itself.** Finding `7a26f0d9` reported arm-sonnet at `103/114`; the banner below reports
> `116/116`. Recounted definitively on 2026-09-09 over every field actually present in each claim:
> **arm-opus 142/143, arm-sonnet 116/116, total 258/259.** The banner is right, the finding's
> sonnet figure is wrong on both numerator and denominator -- and its conclusion, that the premise
> was false, stands regardless, which is why this document is withdrawn.
>
> Two `approach-reviewer` passes, run in parallel with no sight of each other, both returned
> **REJECT** — 40 findings, 10 critical. Both replies are committed beside this file as
> `2026-09-08-parser-question-review-a.json` and `-b.json`. Read those, not this.
>
> **The load-bearing sentence is false, and it sits under a heading that says "verified".** This
> document asserts *"No claim in them is reachable by `jf()`"*. One reviewer emulated `jf()`
> against both committed artefacts and recovered most of them; the author then re-ran it
> independently and got:
>
> ```
> arm-opus.json    142/143 claim field values byte-exact
> arm-sonnet.json  116/116
> claim 44/44 · source_loc 44/44 · verdict 44/44 · location 44/44
> ```
>
> **258 of 259 field values recover byte-exact through the reader this document says reaches none
> of them**, and every field the contract marks REQUIRED comes back at 100%. The artefacts are
> pretty-printed one field per line and `jf()` is a per-line function. The real gap is **record
> assembly and ordinals**, not parsing — a smaller and different problem, and one the option table
> never costs because the premise said there was nothing there.
>
> **Everything downstream is therefore costed against a problem that is not the problem.** Four
> other defects, each verified: the prior art cited as supporting option B (`T-20260808`) in fact
> **forbids** it — its acceptance criterion bars *"string interpolation of user-authored text"*
> into SQL and its scope excludes *"agent transcripts"* by name; the measurement is reported as
> decisive in one section and as unrun in another, 43 lines apart; all three measured data points
> are 3.45+ while the floor proposed is 3.38, and `readfile()` returns a BLOB whose JSON handling
> changed **at 3.45**; and the claim that this question *"gates everything else"* was never checked
> against the task's other open criticals — `627b9764` is **upstream** of the artefact format
> itself.
>
> **Two options were missing and both reviewers found them independently:** claims emitted as
> sanitised single-line events through the existing `kit_findings.py` writer and `jf()` reader,
> and the documented `ingest.extra` **adapter seam**, which is language-agnostic and means A-vs-B
> was never the real fork. `jq` is never named. Neither is *defer*.
>
> **The honest disposition of `cd31c6bf` is DEFERRED TO STEP 2**, which both reviewers reached
> separately: revision 2's step 1 is a T2 commit that *"locks nothing"*, so nothing here gates it.
> The question is real and premature.
>
> **Kept unedited below**, as ADRs 0005 and 0006 are, and as the rejected claim-identity input is:
> the record should show what was wrong, not only what replaced it.


**Task:** `T-20260826-a-verified-claim-about-the-tree-has-no-a`
**Tier:** T3 — inherited from that task's `tier.rule: tooling/kit-index.sh T3` trigger.
**Status: a QUESTION with costed options, not a proposal.** Two design inputs from this author were
rejected by four reviewers in one day, both on a premise the author had constructed rather than
found. This document deliberately does not recommend. It states what is true, what each option
costs, and what would have to be measured before anyone chooses.

## The question

`cd31c6bf`, critical, open: *"The derive path has no JSON parser for a verbatim artefact; `jf()` is
a single-line regex blind past an escaped quote, so ingestion is forced regardless of normalise."*

Both approach reviewers reached this independently and both said it is forced by the **artefact
format** chosen in revision 2 — *commit the auditor's raw JSON verbatim* — and not by any identity
or normalisation decision. **It gates everything else: until it is answered, every identity
decision is a decision about rows nothing can read.**

## What is true today, verified 2026-09-08

- `kit-index.sh` contains **zero** `python3` invocations. Its only JSON reader is `jf()` at
  `:816-819`: `match(s, "\"" k "\"[ ]*:[ ]*\"[^\"]*\"")` — one line, one string, and blind past an
  escaped quote by construction.
- `tooling/kit_claims.py`, which revision 2 names as normalise's home, **does not exist**.
- The committed artefacts are nested and pretty-printed, and their `narrative` field contains both
  newlines and escaped quotes. **No claim in them is reachable by `jf()`.**
- `python3` is a dependency of the **write** path only — `kit-finding.sh`, `kit-resolve.sh`,
  `kit-review-record.sh` all invoke `kit_findings.py`. A fresh clone can rebuild the index today
  with no python present.

## The options, costed

### A — `kit-index.sh` invokes a python reader

What revision 2 already says, without a mechanism. Makes the design true as written.

- **Cost:** `python3` becomes a dependency of the **derive** path, not just the write path. Every
  adopter runs `kit-index.sh`; today they can rebuild from a clone with no python.
- **Forces a decision it does not currently have:** what `kit-index.sh` does on a machine with no
  python and a populated `.project/census/`. Skipping drops census rows and every disposition out
  of the gate — fail-open. Aborting breaks index rebuild for every adopter, including those who
  never ran a census.
- **Second cost, named by a reviewer and easy to miss:** it introduces a second SQL-emitting path
  into a pipeline whose one-leading-space rule (`kit-index.sh:141-158`) is the entire defence
  against sqlite3 dot-commands. An emitter that does not indent reopens `.shell`.

### B — `sqlite3` reads it, using JSON1

**`sqlite3` is already a hard dependency of `kit-index.sh`.** Verified working on this machine
against a real committed artefact, sqlite3 3.53.4:

```
sqlite3 :memory: "SELECT json_extract(readfile('…/arm-opus.json'), '$.subject');"
  -> UC3 TLS ACME mTLS OCSP CRL

sqlite3 :memory: "SELECT key, json_extract(value,'$.verdict') FROM
                  json_each(json_extract(readfile('…/arm-opus.json'),'$.claims'));"
  -> 0 | OVERSTATED
     1 | STALE-CITATION
     2 | STALE-CITATION
```

- **No new dependency, and one language rather than two.**
- **`json_each` returns `key` as the array index**, so the within-unit ordinal that `claim_ref`
  needs falls out of the parse rather than being counted separately. Whether it is 0- or 1-based is
  a decision, not a discovery.
- **It is aligned with an open T3 task rather than against it:**
  `T-20260808-shrink-the-embedded-awk-surface-by-movin` — *"Shrink the embedded awk surface by
  moving parsing into SQL"* — already argues this direction for the quoting and dialect traps that
  cost this repository a day.
- **The version gate has a precedent in this repo.** `kit-plan.sh:479-485` reads
  `sqlite3 --version`, computes `PACKS_OK` for `>= 3.25`, and degrades with a warning rather than
  failing. JSON1 is compiled in by default from **3.38**; before that it is optional. So B needs
  the same shape of gate at a higher floor.
- **`readfile()` is a function of the sqlite3 CLI, not of the library.** `kit-index.sh` uses the
  CLI, so this holds — but it is a constraint on how the reader may be invoked, and it should be
  stated rather than discovered.

**MEASURED 2026-09-08, and this is what decided it.** A temporary probe step ran on both CI
platforms against a real committed artefact:

| platform | sqlite3 | `json_extract` + `readfile` | `json_each` ordinals |
|---|---|---|---|
| `ubuntu-latest` | **3.45.1** | ok — `UC3 TLS ACME mTLS OCSP CRL` | ok — `0 | OVERSTATED`, `1 | STALE-CITATION` |
| `macos-latest` | **3.50.6** | ok — same string | ok — same rows |
| this machine (Windows) | 3.53.4 | ok | ok |

All three are above 3.38, all carry JSON1, all parse the same artefact to the same values. **The
portability objection to B is answered for CI.** The probe was closed unmerged rather than kept: a
permanent probe is noise in a suite whose point is that a green means something.

**What this does NOT establish, and B still owes:** an ADOPTER's sqlite3. The kit runs wherever it
is installed, and a long-term-support distribution can ship 3.34 or older, where JSON1 is optional
at compile time. So B still needs the version gate — `kit-plan.sh:479-485` is the shape, at a 3.38
floor rather than 3.25 — and it needs a stated answer for what an adopter below that floor gets.
That answer is the same undecided question option A carries about a missing `python3`, which is
worth noticing before B is chosen for avoiding it.

### C — intake writes a flat sidecar; the artefact stays verbatim

`kit-claim.sh` writes the artefact byte-exact **and** a derived, single-line-per-claim form the
existing awk can already read.

- **Costs nothing on the derive path** and keeps the raw-artefact guarantee intact.
- **But it puts a derived file in a committed directory**, which is the thing ADR 0004 governs, and
  it means the sidecar and the artefact can disagree. The kit's answer elsewhere is that derived
  things are rebuildable and not committed — a sidecar is neither.
- Pushes the parsing cost to the write path, where python already lives, so it is A's dependency
  moved rather than removed.

### D — change the artefact format so awk can read it

Rejected on architecture, recorded so nobody re-derives it. The verbatim artefact exists because
792 claims were summarised into counts and lost. Reformatting the auditor's reply to suit the
reader re-introduces exactly that.

## What no option changes

None of these settle identity. `claim_key`'s composition, the positional occurrence suffix, and
`source_document` against the artefact's per-unit `source` are open regardless. This question is
**upstream** of those, not a substitute for them.

## For the reviewer

Three things worth attacking first:

1. **Is the framing itself right?** This document assumes the derive path must read claims at all.
   If the store's first useful version records artefacts and defers derivation entirely, the
   question may not need answering yet — and the sequence in revision 2 already puts artefact
   capture at step 1 and derivation at step 2, as separate commits.
2. **B looks free and probably is not.** One machine, one sqlite3 build, one artefact. The CI
   measurement is unrun. Treat the demonstration above as an existence proof on one platform, not
   as a portability claim.
3. **C may be a fifth option in disguise.** If the sidecar is *not* committed and is rebuilt by
   intake, it is a cache, and the question becomes who rebuilds it on a fresh clone — which is the
   same question `kit-plan.sh --packs` already answers for cluster packs and could be reused.

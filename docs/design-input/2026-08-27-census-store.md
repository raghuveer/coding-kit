<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Design input — the census store

> **THE DERIVATION HALF IS SUPERSEDED, 2026-09-09. Step 1 stands.**
>
> Superseded-by: docs/adr/0011-claims-are-recorded-in-artefacts-not-the-index.md
>
> **Scope, stated precisely, because a marker on a whole file is read as a verdict on all of it.**
> What is superseded is this document's step 2 -- deriving claims into `index.db`, the `claim` and
> `census` tables, `normalise` at index time, and the ingestion path that needs a JSON parser
> inside `kit-index.sh` -- **and, added 2026-09-09, this document's EXCLUSION OF THE
> CLAIMS-AS-EVENTS ROUTE.** ADR 0011 was amended the day it was accepted to consider that route as
> option D and reject it on F12: capture writes the reply verbatim before validation, and a
> line-oriented append-only log cannot take an unvalidated blob. The exclusion this document made
> without costing is now made with an argument, which is what `6a07968d` and `65e35340` asked for. **Step 1 is NOT superseded**: `kit-claim.sh` and `kit_manifest.py` are
> shipped, carry 52 conformance references, and captured this repository's first census on
> 2026-09-09.
>
> **Why.** Validating that census against this document's own contract took about twenty lines of
> Python over a committed JSON file -- 9 claims, 0 violations, no index and no `awk`. The kit's
> standing rule is that text is truth and the index is a disposable cache; claims in committed
> artefacts are already text.
>
> **What this marker DOES and does NOT carry, corrected 2026-09-09.** It now also carries the
> INDEX-TIME KEY: `claim_key` is specified at :310 (F4) as computed at index time, and the shipped
> artefact contract emits no key at all, so `26925ff4` and `e1c2ce2b` criticise a mechanism this
> marker withdraws. It does **NOT** carry `3e76f904` -- `source_document` per census against
> `source` per unit is a defect in the SHIPPED artefact format, both fields exist today, and no
> derivation is involved. Nor the four rationale findings. ADR 0011 states the split and why the
> first version of this note got it wrong.
>
> Kept unedited below, on the same grounds as ADR 0005, ADR 0006 and ADR 0010: the review is the
> value, and a design deleted from the tree takes its findings with it.


**Task:** `T-20260826-a-verified-claim-about-the-tree-has-no-a`
**Tier:** T3 — trigger `tier.rule: tooling/kit-index.sh T3`.
**Blocked-by, satisfied:** the `claim-auditor` contract, merged in PR #27 (`38e648c`).

**Revision 2, 2026-08-28.** Revision 1 was reviewed by `approach-reviewer` and returned **REVISE**
— 5 critical, 9 major, 3 minor, recorded as 17 findings against this task and narrated in
`2026-08-27-census-store-review.md`. This revision answers them. Where a finding is dissolved
rather than solved, that is said, because the difference matters to whoever reads this next.

## Four decisions made by the operator, recorded as his

**D1 — the census is recorded IN THE KIT REPO.**

> **Bounded by D4 below (2026-09-07).** This sentence reads as a universal rule; the
> rationale under it only ever covered the candidate case. D4 is the scoping rule. Not rewritten
> here, because a decision is corrected in front of the reader rather than edited out of sight.

The rationale is his and is not a storage convenience. highper-gateway and aeon were used as
**brownfield project candidates**, evaluated to validate the kit's strengths and to identify
improvement areas explicitly. What the audits produced is therefore *"findings of evaluation of
both brownfield project candidates"* — data belonging to the kit's own development record, to be
tested against as the kit improves. Secondarily it is of use when those projects are actually
developed with this kit, in a **token-economics context, to prevent duplicate work**. Millions of
tokens and clock time were spent; neither is free.

This settles review finding **F6**, which the reviewer correctly identified as unaddressed and
unaddressable by the design as written.

**D2 — claims carry dispositions, and discarding is a recorded act.**

Once findings are data, they can be shown, and opinions, inputs and feedback can be logged **on
specific points**. A false positive, or one judged less important, **may be discarded — and the
discarding is itself recorded as such**, never a deletion. The purpose is that when more developers
contribute later, they have the history clearly.

This answers the reviewer's open question 4 and is the same principle the finding vocabulary
already embodies: `--unassessable` and `--superseded` leave the gate and stay in the record
permanently, because a mark that clears a gate without saying why is the laundering the gate exists
to prevent.

**D3 — the census is a re-runnable reference, not only a record.**

Stated by the operator 2026-08-28, and it is a stronger requirement than "diff two censuses":

> Findings recorded so we can use that for audit and to share feedback, that can be used for
> improving coding kit and **to later validate coding kit recursively, against same reference**.
> Every evaluation audit to be logged **separately** so that learnings can be tracked and a
> **summary can be generated** whenever needed. In future, for discovery sessions and project
> requirements gathering sessions, we can create a **summary document as an artifact** where code
> is evaluated along with **user inputs and decisions made**.

Three consequences, and revision 2 as first written supported only one of them.

**1. A census is a benchmark, so the KIT's own version must be pinned.** To re-run an audit later
and attribute a difference, three variables must be recorded, because a diff in which more than one
moved is uninterpretable:

| variable | recorded as | why |
|---|---|---|
| the subject tree | `subject_sha`, `subject_dirty` | the code may have changed |
| the auditor | `auditor_model` | model nondeterminism and tier changes |
| **the kit** | **`kit_sha`, `kit_version`** | **the thing being validated recursively** |

Revision 2 recorded the first two and **not the third** — which would have made the recursive
validation D3 asks for impossible, since a changed verdict could not be attributed to the kit
improvement it was meant to measure. `kit_sha` and `kit_version` are added to the manifest.

**A diff must refuse to be read as a kit result when more than one variable moved.** The census
diff reports which of the three differ between the two runs, and says plainly that a diff with two
or more moving is not attributable. That is a control that can fail, not a caveat in prose.

**2. Separate logging per audit is already the structure, and is now also a requirement.**
`.project/census/<census_id>/` per evaluation was chosen for `census_id` reasons; D3 makes it
load-bearing for a second reason — learnings tracked per audit rather than pooled.

**3. Summary generation is a named downstream consumer.** Not built by this task, but the schema
must not preclude it. Two shapes are wanted and they are different:

- a **census summary** — per subject, per audit: verdict counts, drift fractions, dispositions,
  and what changed since the previous census of the same subject.
- a **discovery-session summary document** — the artefact of
  `T-20260827-discovery-is-a-multi-session-phase-with-`, combining code evaluation with **user
  inputs and decisions made**. That means dispositions and their reasons are not incidental
  metadata; they are **content of the eventual document**, and must be retrievable with their
  claim, their author and their date.

The store's obligation is therefore to keep a claim, its verdict, its evidence, its disposition and
that disposition's reason **retrievable together**, and to keep the raw artefact that carries the
auditor's narrative. It is not to generate either summary.

**D4 — a census is PROJECT-SCOPED by default. The kit repo is the fallback for a subject that
is being used to evaluate the kit.**

Stated by the operator 2026-09-07, in his words above the agent's draft, which keyed the
fallback on adoption rather than on purpose. The correction is recorded in §"what his wording
changes" below rather than absorbed silently.

Raised on reading a summary that stated the census is stored in the kit repo as settled general
design:

> Do you mean in project scope or coding-kit repo? The claims about the project, to be stored in
> project's scope right? [...] We are using highper-gateway and aeon as evaluation candidates of
> this coding-kit's capabilities.

**The rule:**

| Case | Is the subject being used to evaluate the kit? | The census lives in | Why |
|---|---|---|---|
| **Normal use** — a team audits its own project | no | the **subject's** `.project/census/`, tracked there | the same scope as every other artefact the kit produces |
| **Candidate evaluation** — the kit is the thing under test | yes | the **kit** repo, marked foreign | the audit's output is the kit's development record, not the subject's |

**This bounds D1 rather than contradicting it.** D1's rationale was always the candidate case and
never claimed to be more: highper-gateway and aeon were evaluated *to validate the kit*, so what
those audits produced is the kit's own development record. What the design did was state that
conclusion as a universal rule — *"the census is recorded IN THE KIT REPO"* — without noticing the
rationale underneath it only reached one case. The second approach review caught this and it is
still an open critical: *"design never says which repo stores a census."*

**Why project scope is the default and not the exception.** Every artefact the kit produces is
project-scoped: tasks, findings, events and spend all live in the adopting repository's
`.project/`. `kit_active()` is `[ -f "$(kit_profile "$1")" ]` and every script refuses when it is
false, on the stated principle that the kit does not create state in a repository that did not opt
in. A census in the kit repo would be **the only artefact that breaks that scope**, and the case
that makes it untenable is not hypothetical: an adopter auditing a client codebase would have that
client's claims land in a repository belonging to someone else.

**What his wording changes, and it is not cosmetic.** The agent's draft made the fallback trigger
on **adoption** — `kit_active` against the subject, a mechanical test needing no declaration. The
operator's wording triggers it on **purpose**: *a subject that is being used to evaluate the kit*.
These are different rules and they disagree on real cases:

| subject | adopted the kit? | being used to evaluate the kit? | draft said | **D4 says** |
|---|---|---|---|---|
| highper-gateway, aeon | no | yes | kit repo | **kit repo** |
| an adopter auditing its own project | yes | no | subject repo | **subject repo** |
| a repository that adopted the kit and is then used as an evaluation subject | yes | yes | subject repo | **kit repo** |
| a non-adopted repository audited for its own sake | no | no | kit repo | **neither — see below** |

The operator's rule is the correct one, and the third row is why: **adoption does not tell you whose
question the audit answers.** A repository can run the kit on itself and later be used as an
evaluation candidate; the claims produced by the second activity belong to the kit's development
record no matter how well instrumented the subject is. Purpose is the load-bearing fact and
adoption was only ever a proxy for it that happened to hold for the two subjects to hand.

**The cost of the correct rule, stated rather than hidden.** Purpose is **declared, not derived**.
Nothing in the tree can compute "is this subject being used to evaluate the kit", so the manifest
must carry it as a recorded field set by the operator — the same standing as `Via:`, which the kit
also refuses to infer. A census whose purpose is unset must be refused rather than defaulted, since
defaulting either way silently misfiles it.

**The fourth row, decided by the operator 2026-09-07.** A non-adopted repository audited for its
own sake has no `.project/` to write to and no evaluation purpose to justify the kit repo. The
draft's mechanical rule covered it **by accident**, sending it to the kit repo; D4 correctly
declines to, which is what made the gap visible.

> In "a non-adopted repo audited for its own sake" scenario, the subject must adopt the kit first
> and census to be write in subject repo as kit state.

So the fourth row is **not a fifth storage location**: it resolves into the second by requiring
adoption first, after which the census lands in the subject's own `.project/census/` like any
other kit state. This is the rule the kit already enforces everywhere else — `kit_active()` is
`[ -f "$(kit_profile "$1")" ]`, and the kit does not create state in a repository that did not opt
in. A census is kit state and gets no exemption.

The **mechanism** is filed as `T-20260907-a-census-on-a-subject-that-has-not-adopt` (T2, blocked by
this task's store), because a rule with no mechanism is a convention. The failure it guards is not
a crash but intake choosing a plausible directory and succeeding, and the trap it must avoid is
being written as a bare `kit_active` guard — that would refuse the **first** row, which is
legitimately non-adopted and must still record. Keying on purpose rather than adoption is exactly
why D4 is worded as it is.

**What this does not change.** The F6/F7 machinery stands unaltered — `subject_repo`,
`subject_remote`, `subject_sha`, `subject_dirty`, `kit_sha`, `kit_version`, and the control that a
foreign census must never leak into an unqualified total. It simply becomes the apparatus of the
**fallback** case rather than of every case. D3's three-variable attribution rule is untouched: a
census is a re-runnable reference wherever it is stored.

**What it re-opens, and must be restated rather than assumed.** F6/F7 currently says *"a census
whose `subject_repo` is the kit itself is the only one that may appear unqualified."* Under D4 the
normal case is a census stored in the subject's own repository describing that same repository,
which is equally unqualified **there**. The rule generalises to: **a census may appear in an
unqualified total only when its `subject_repo` is the repository storing it.** The conformance step
F6/F7 demands must test that form, or it will fail every correctly-scoped adopter census.

**D5 — a disposition attaches to the CLAIM and references the OBSERVATION it was made against.**

Stated by the operator 2026-09-08, answering the question two independent approach reviewers
converged on as the one that decides the store's identity design:

> attaching to the claim while referencing to specific observation, adds context to future
> readers (human or model both)

**This is a third answer, and neither of the two the reviews framed.** Census-local dispositions
were rejected because a re-run re-opens all ~489 judgements and D2's history resets on each use.
Claim-attached-only was rejected by review A, which showed it must join old claim to new on
`claim_key`, making what a committed record *reaches* depend on `normalise` — `b032ddaf` verbatim.
D5 takes the first half of the second and repairs it with provenance.

**The mechanism this selects is `the disposition embeds its subject`** — review A's alternative,
which the 2026-09-08 claim-identity design input never considered. The disposition event carries:

| carries | for | so that |
|---|---|---|
| the claim it judges, **as text or content hash at judgement time** | attachment | the record is self-describing and needs no live pointer to be readable |
| `census_id`, `unit`, ordinal, and the artefact's hash | reference | a future reader knows exactly what was in front of the person who judged |
| the disposition and its required reason | the judgement itself | unchanged from D2 |

> **REVISED 2026-09-10 — the hash is specified. Closes `322f03aa`.** The row above and the
> reference row below both said *hash* and named no mechanism, no party and no width, which is
> three unstated choices in a field that has to be reproducible by a stranger years later. The
> kit already answered this twice and the design cited neither:
>
> | | |
> |---|---|
> | **mechanism** | `git hash-object --stdin`. Precedent: `tooling/kit-accel.sh:186` and `tooling/kit-spend.sh:127`. It keeps the dependency set at `git`, which the kit already requires, and needs no new tool |
> | **width** | **16 hex characters**, `cut -c1-16` — the same width both precedents use. Not full-length, because these are correlation handles rather than security boundaries, and a truncated one is legible in a diff |
> | **party** | **the writer of the disposition**, never the auditor. An auditor that supplies its own subject hash is attesting to what it wants judged, which is the self-certification rule that governs `Via:` and `--fixed` |
> | **input** | the artefact **file bytes as committed**, not a re-serialisation. `git hash-object` on the path is therefore the operation, and a reader can re-run it |
>
> **What this does NOT make the hash.** It is not tamper-evidence and must not be described as
> such: an actor who can rewrite the artefact can recompute the hash, and `kit-guard.sh` does not
> match `Bash`. It answers *which bytes were in front of the judge*, which is the question D5 asks
> of it and the only one it can answer.

**Why the reference half is not decoration.** The operator names *"future readers (human or model
both)"*, and for a model it is load-bearing: a disposition without its subject recorded is a verdict
whose evidence must be re-derived from a tree that has moved. With the subject carried, a later
reader compares what was judged against what is there now and sees the difference itself.

**What this settles.** Carrying a disposition forward stops being a silent join and becomes a
**reported comparison**: *this was judged against this text; the current census says this; they are
identical, or they differ, and here is how.* `normalise` then affects suggestion and display and
never what a committed record reaches — which answers `b032ddaf` properly, rather than by the
claim-identity input's assertion that nothing committed names the key.

**What it does NOT settle, listed so nothing is assumed.** ~~`unit` is still undefined and is a
component of every identity proposed so far.~~ **Superseded the same day by F1c below, which
defines it.** `source_document` (manifest, per-census) still conflicts with the artefact's own
per-unit `source`. The derive path still has no JSON parser for a verbatim pretty-printed artefact,
which is forced by this document's own §"raw artefact first" choice and not by any normaliser. The
occurrence suffix is still positional. ~~`5c1284da`'s refusal rule is still a precondition rather
than a follow-on.~~ **Superseded the same day by F1b below, which states the rule.**

> **Both strikethroughs were written hours before the sections that closed them, and neither was
> revisited when they landed.** Two independent validators, given only the finding text and the
> tree, each reported the same thing: within one file, `:224` said `unit` was undefined and `:356`
> defined it, ~130 lines apart, with nothing linking them. That is the defect this document files
> against other people's work — two artefacts carrying one fact with nothing comparing them —
> committed by the author of the rule. Corrected in front of the reader rather than edited out.

**And it introduces one cost that must be named rather than discovered.** A self-describing
disposition is larger than a pointer: at ~489 claims a census, dispositions carrying claim text plus
a reason add on the order of 200KB to `events.ndjson` per fully-dispositioned census — the same
order as F13's concern, which the raw-artefact architecture was chosen to avoid. Carrying a content
hash instead of the text bounds it, at the cost of the reader no longer seeing the subject without
resolving something. **That trade is not decided here.**

## The problem, measured

**792 verified claims across two runs; none survives at claim granularity.** highper-gateway's 303
became a 16-row count table; aeon's 489 became a 157-line narrative. All 35 subagent transcripts
are gone — the `spend` rows preserve every `agent_id`, and a search across all 15 project
transcript directories found 0 of 35. Cost to produce: 11,066,325 and 17,015,010 BTE, stable at
~35k BTE per claim.

## The architecture change: raw artefact first, everything else derived

Revision 1 proposed writing claims straight into `.project/events.ndjson` as the durable form. The
reviewer's **F14** identified the alternative it never costed, and D1/D2 independently demand it:

> **Commit the auditor's raw JSON verbatim, one file per audited unit. Derive everything else.**

```
.project/census/<census_id>/
    manifest.json          subject repo/SHA/dirty, document, operator, dates, units, purpose
    <unit>.json            the auditor's reply, VERBATIM — narrative and claims, unmodified
    ...                    one per audited unit
                                    │
                                    ▼  derived, disposable, rebuildable
              .project/index.db     claim table + claim_disposition
                                    │
                                    ▼
                          kit-status.sh, census diff
```

The artefact directory is **committed**. The table is **derived** and may be dropped and rebuilt,
exactly as `ADR 0004` requires of every derived thing in this repository.

### What this dissolves rather than solves

| review finding | status under revision 2 |
|---|---|
| **F4** `normalise` unspecified; writer-or-indexer unstated | **RETRACTED 2026-09-10. Closes `b032ddaf`.** This row said re-keying stays free forever because `claim_key` is computed at index time. **Both halves are now withdrawn** and the replacement is shorter than the claim it replaces. There is no index time: ADR 0011 decided claims are recorded in committed artefacts and not derived into the index, and `kit-claim.sh --contract` emits no key at all. And there is no key to re-key: **D5 embeds the subject in the disposition**, as text or as the 16-character hash specified above, so nothing joins an old claim to a new one and the freedom this row claimed is not needed rather than available. `b032ddaf` was right that a disposition naming a claim freezes something in the committed log -- what it freezes is the SUBJECT, deliberately, which is what makes the record self-describing. The defect was asserting freedom that the same revision had already spent. <br><br> **⚠ Bounded by D5 (2026-09-08). "Re-keying stays free forever" is not established, and "computed at index time" has no mechanism.** Review A: free re-keying is true of the bytes on disk and false of which claims a committed record *reaches*, once a disposition must carry forward. Review B: `65e3d2a2` is open — `kit-index.sh` has zero python invocations and `kit_claims.py` does not exist. Under D5 a disposition carries its own subject, so this row's conclusion is reached by a different route than its argument. Not rewritten, per this document's own convention. |
| **F5** sequence inverted — step 2 decides what step 1 froze | **Dissolved.** Step 1 freezes nothing. The variance measurement can now run before, during or after without penalty. |
| **F11** torn writes: 15KB–270KB batch, no lock, concurrent `spend` appenders | **Dissolved.** A unit is one file written once, not an append to a log shared with 18 subagents' `spend` hooks. There is no interleaving to protect against. |
| **F13** one census adds ~270KB to a 237KB log the awk hot loop re-hashes every run | **Dissolved for the log.** Artefacts are separate files; `events.ndjson` does not grow per claim. The derived-table build cost remains and is budgeted below. |
| **F16** `sanitise` maps `\`→`'`, mangling Windows evidence paths | **Reduced to recoverable.** The raw artefact preserves the original byte-for-byte; only the derived row is sanitised, and the original is always one file read away. |
| **F12** no retry loop; a rejected unit loses ~1M BTE | **Reduced.** The raw reply is saved **before** validation, so a unit that fails validation still has its data. Validation failure becomes a re-derivation problem, not a data-loss event. A correction loop is still wanted and is now an optimisation rather than a safeguard. |

Six of fourteen dissolved or materially reduced by one structural choice. That is the argument for
it, and it is the reviewer's, not mine.

### F1 — `census_id`, now defined

**`census_id` is the directory name, allocated by the operator when a census begins.** Slug form,
`<subject>-<date>`: `aeon-2026-08-27`.

It is not derived from content, and could not be. The reviewer proved every derived candidate
fails: the subject tree SHA makes a repeat audit of the same tree indistinguishable from the first,
destroying the very measurement meant to validate the key; an intake timestamp makes each of ~18
subagents its own census, so a "census-to-census diff" compares fragments.

Consequences, stated:

- A unit re-run mid-census **overwrites its own file** in the same `census_id` directory. That is
  correct — a corrected audit of one unit replaces the failed one, and git holds the prior version.
- Two audits of the same subject are **two directories**, which is what makes them diffable.
- `census_id` uniqueness is a directory-creation collision. Refuse, do not merge.

### F3 — collision, now handled by adopting the whole precedent

> **⚠ Bounded by D5 (2026-09-08). Read this section as OPEN, not as settled.** `26925ff4` records
> that suffix, `id_ambiguous` and ordinal are all proposed here and none designated. The attempt to
> designate one — `docs/design-input/2026-09-08-claim-identity.md` — was **REJECTED** by two
> independent approach reviewers; both replies are committed beside it. Three things they establish
> that bear directly on the text below: the **occurrence suffix is itself positional**, so an
> ordinal-free key is not position-free; `kit-index.sh:865-904`'s argument that the suffix is safe
> rests on the log being **append-only**, which census artefacts are not; and `unit` — a component
> of every key proposed so far — **is not a field the auditor emits**. Not rewritten, for the
> reason D1 is not rewritten: a design is corrected in front of the reader.

`claim_key = hash(subject_repo, source, subject, normalise(claim_text))` still collides when a
document repeats wording across units — which `claim-auditor.md:140` actively encourages by
instructing the agent to keep the document's own framing.

Revision 1 cited the finding-id precedent and took half of it. Revision 2 takes all of it:

- a byte-identical repeat gets an **occurrence suffix**, as `kit-index.sh:881-904` does;
- a true collision sets an **`id_ambiguous` flag** on the row, as `finding.id_ambiguous`
  (`schema.sql:156-161`) does;
- and a **meta counter** `claim_id_collisions` is exposed, as `finding_id_collisions`
  (`kit-index.sh:1001`) is, so the ambiguity is said out loud rather than silently absorbed.

Because the artefact is a per-unit file with an **ordered** `claims` array, the within-unit
**ordinal** is available for free as the disambiguator — the reviewer's second uncosted
alternative. It is safe here in a way the old finding counter was not: that counter was *global*,
so an unrelated event renumbered every finding after it; an ordinal scoped to one immutable unit
file cannot be moved by anything.

`normalise` is specified as: lowercase, collapse internal whitespace, strip trailing punctuation.
It is defined **once, in `kit_claims.py`, and applied only at index time** — never in awk, never
in the committed artefact.

### F1c — `unit`, and the scope it is defined in

Closes the approach review's first required change: *"`unit` is a component of both identifiers and
is defined nowhere."* True, and worse than it sounds — `agents/claim-auditor.md` emits `source`,
`subject`, `narrative`, `claims` and **no `unit` at all**, verified against both committed artefacts.

**The scope question decides the answer, so it comes first.** There are four places `unit` could be
defined and they are not interchangeable:

| scope | supplied by | cost | detects a mislabelled artefact? |
|---|---|---|---|
| the auditor contract, as a new required output field | the agent | changes a shipped contract, and the 44 existing rows have no such field — an agent cannot backfill an artefact it already returned | yes |
| **the census manifest, declared before any audit runs** | **the operator** | **none to the contract, and it works retroactively because the operator writes the manifest** | **yes, by comparison** |
| the intake CLI alone — `kit-claim.sh --unit` | the operator, at capture | none | **no** — nothing binds the label to what was audited |
| derived from the artefact filename | nobody | none | no, and circular: the filename comes from `--unit` |

**The contract has already answered it.** `agents/claim-auditor.md:158` reads *"Audit the unit you
were assigned and no other"*, and `:53` *"Read the assigned unit"*. **A unit is an INPUT to an
audit, not a discovery of one.** Something must therefore assign it before the agent runs, and the
only thing that exists at that moment is the manifest. Defining `unit` in the contract's output
would be recording the assignment in the one place that cannot make it.

**The definition.** `unit` is a **slug declared in the census manifest** before any audit runs, and
refused under F1b's rule. `kit-claim.sh --unit` must name a unit the manifest already declares; an
undeclared unit is **refused rather than created**, for the reason an undeclared `census_id`
collision is refused rather than merged — intake choosing a plausible name and succeeding is the
failure mode, not intake crashing.

**`subject` is not the unit, and is more useful for not being it.** The auditor's `subject` is the
agent's own label for what it *understood* it was auditing. Stored beside the declared `unit`, a
divergence between them is **observable** — that is the scope-discipline breach of `:158` becoming
a reportable fact instead of a hope. Collapsing the two would spend the only independent signal
there is on saving one field.

**Measured, with its limits stated.** Both arms of the 2026-09-07 experiment returned
`subject = "UC3 TLS ACME mTLS OCSP CRL"` — byte-identical across two independent runs, which is a
point in favour of it being stable. It is **n=2, one day, one prompt, one document**, so it is not
evidence that it is stable enough to be identity. And it contains spaces, so under F1b it could
never have been a path component at all.

**A contradiction inside this document, introduced by F1b and fixed here.** The artefact tree above
named the file `<subject>.json` while F1b requires `<unit>` to match `[A-Za-z0-9._-]+`, which
`"UC3 TLS ACME mTLS OCSP CRL"` fails. The tree now reads `<unit>.json`. The old form is recorded
here rather than silently corrected.

**What this unblocks immediately.** Review A's migration finding was that the first data this design
would meet — the 44 rows under `docs/EXPERIMENTS/2026-09-07-claim-auditor-tier/` — cannot supply a
component of either identifier. Under this definition they can: a manifest naming their unit is
written by the operator, with **no contract change and no edit to the artefacts**.

**Still open, and not settled here:** `source_document` (a manifest, per-census field) against the
artefact's own per-unit `source`. Same class of question, different field; it is not folded in
silently.

### F1b — `census_id` and `--unit` are refused, not rewritten, and the precedent is not enough

**States the rule `5c1284da` asks for.**

> **CLOSED 2026-09-09 by the operator, and the split below is what resolved.** Two independent
> validators divided PARTLY/ADDRESSED on whether a rule stated in prose closes a finding about a
> rule, and the unanimity rule left it unmarked. It is no longer prose: `tooling/kit-claim.sh:158`
> and `:249` refuse any `--census` or `--unit` outside `[A-Za-z0-9._-]`, which excludes the
> separator, so neither can become a traversing path component. `:243` records that the same
> grammar admits `.` and `..` and that both are refused separately. Shipped in `772e5c5`.
> The mark cites that commit; this paragraph is amended in the same commit as the mark, so the
> record and the design cannot say different things about the same finding.

The paragraph as written on 2026-09-09 said the finding remained open, deliberately, and that
reasoning stood until the code caught up with it. This sentence previously read *"Closes
`5c1284da`"* — a closure the record never showed, written by the same hand that left it open,
and believed hours later by that hand as fact. **A design does not get to mark its own
findings.** Both become **path components** (`.project/census/<census_id>/<unit>.json`) and,
under D5, **committed identity** — a disposition references the observation by them. So a bad value
is not a bad directory name; it is a forged anchor that outlives the run.

**The rule.** `census_id` and `--unit` are each refused unless they match `[A-Za-z0-9._-]+`, **and**
are refused outright when the whole value is `.` or `..`. Refused, never rewritten — for the reason
`kit-plan.sh:121-122` already gives about goal ids: *"a silently rewritten goal id is a second name
for the operator's goal"*, and a second name for a census is worse, because D5 makes it identity.

**Why the precedent is adopted and then tightened.** `kit-plan.sh:123-129` is the right shape and
its charset **includes the dot**, so `.` and `..` pass it. Verified 2026-09-08 by running the
`case` pattern alone against a table of inputs: `..` → ACCEPTED, `.` → ACCEPTED, `a..b` → ACCEPTED,
`bad/name` → REFUSED, `''` → REFUSED.

**What that costs `kit-plan.sh` today: nothing, and that was tested rather than assumed.** A
throwaway repo was adopted, seeded and planned with `--goal ..`. `.project/` survived intact, no
pack escaped into it, and no plan row was written. The reason is not the guard — it is that
`rm -rf` refuses a path ending in `..` on its own (*"refusing to remove '.' or '..' directory:
skipping"*, exit 0). **The earlier reading of this as a destructive defect in `kit-plan.sh` is
withdrawn; it was checked before being filed and it does not hold.**

**Why the census store cannot rely on that.** `rm` protects a deletion. This store's exposure is a
**write** and a **record**: `mkdir -p .project/census/../` resolves to `.project/`, an artefact
written there lands beside `events.ndjson` rather than under a census, and D5 then commits `.` or
`..` as the observation reference of every disposition made against it. Nothing in `rm` reaches
any of that, which is why the rule is stated here rather than inherited.

### F2 — the rationale, corrected

Revision 1 argued the pair key was needed because *"findings use `INSERT OR REPLACE` on a content
id — re-recording the same finding should dedupe."* **That is false about the code it cited.**
`kit-index.sh:879-880` hashes the whole event line including `"at"`, which `kit_findings.py:261`
stamps at emit time; a finding re-recorded a second later produces a different id and a second row.
The indexer says so itself at line 872: *"the id is stable for as long as the event is."*

The true reason for `(census_id, claim_key)`: **a census is an observation, not a fact.** Two
audits of the same document are two observations of it, and both must persist for either to be
comparable. `INSERT OR REPLACE` buys idempotent rebuild of one artefact set — nothing more, and
nothing about dedup.

### F6/F7 — foreign subjects, now first-class

Because the census lives in the kit repo (D1) while describing another tree, **every claim carries
its subject**. The manifest records, per census:

`subject_repo` · `subject_remote` · `subject_sha` · `subject_dirty` · `source_document` ·
`audited_at` · `recorded_at` · `auditor_model` · **`kit_sha`** · **`kit_version`** ·
**`units`** · **`purpose`**

**`units` and `purpose` were both required by decisions above and missing from this list.**
`units` is the declaration F1c defines — the manifest is named as `unit`'s home, so a manifest
schema that does not list it points into a container whose specified fields exclude the thing it
holds. `purpose` is D4's: the census's storage location keys on *whether the subject is being used
to evaluate the kit*, which "nothing in the tree can compute", so it must be a recorded field —
and D4 says a census whose purpose is unset is **refused rather than defaulted**. Both gaps were
found by two independent validators reading this document against its own decisions, neither by
the author of either decision.

`kit_sha` and `kit_version` are per D3: without them a re-run cannot be attributed to the kit
change it exists to measure.

`subject_sha` and `subject_dirty` are captured **by the operator from the subject tree** and
written into the manifest — not `git rev-parse HEAD` in the kit, which would record the kit's own
SHA, and not by the auditor, which has `Read, Grep, Glob` and no Bash. `subject_dirty` follows
`kit-checkpoint.sh:17`, which already records exactly this alongside HEAD.

**The trap this creates, and the control for it.** A census about aeon must never make
`STATUS.generated.md` report aeon's 35% drift as the kit's. `kit-status.sh` reports census figures
**per `subject_repo`, always named, never aggregated into this project's own numbers**, and a
census whose `subject_repo` is the kit itself is the only one that may appear unqualified. This
needs a conformance step that fails if a foreign census leaks into an unqualified total — a control
that can fail, not a convention.

### F10/AC5 — the drift rate and its denominator, now decided

Reported as **two fractions, both with explicit denominators, never as an adjective**:

```
drift        173/489   (35%)   claims that DO NOT HOLD, over all claims
drift-judged 173/425   (41%)   the same numerator, over claims that could be judged
unverifiable  64/489   (13%)   reported alongside, never folded into either
```

**"Claims that do not hold" means every verdict except `CONFIRMED` and except `UNVERIFIABLE`.** A
claim nobody could check is not a claim that is wrong, and folding it into drift would be the same
error the third row exists to prevent.

> **CORRECTED 2026-09-08, closing `e02d6b62`.** The first row previously read *"verdicts other than
> CONFIRMED, over all claims"*. That label is wrong and its own numbers say so: `UNVERIFIABLE` is a
> verdict other than `CONFIRMED`, so the labelled quantity is 173 + 64 = **237 of 489 (48%)**, not
> the 173 (35%) printed beside it. The arithmetic that shows which half was wrong: 489 − 64 = 425,
> the denominator of row 2, so **173 is the judged-only numerator** — correct for row 2 and paired
> in row 1 with an all-claims denominator under a label that describes a third quantity entirely.
> **The numbers were right and the label was wrong**, which is why this is a relabel rather than a
> recount. Corrected in place with the old wording quoted, because a section whose entire purpose
> is to stop a denominator being picked silently must not have its own denominator error edited out
> of sight.

The reviewer was right that this is genuinely ambiguous and that the AC exists to force the choice.
Both are printed because they answer different questions — how much of the document is wrong, and
how much of the checkable document is wrong — and printing one silently picks an argument.

### F15 — the variance measurement, operationalised and demoted

Revision 1 said it *"decides everything"* and scheduled it before the design was fixed. Both were
wrong. Under revision 2 nothing depends on it being done first, because nothing is frozen.

It is now specified rather than gestured at: **metric** = Jaccard similarity over normalised claim
text within one unit, plus per-claim verdict agreement on the intersection; **n** = 3 units × 2 runs
rather than 1 × 2, so spread is visible; **decision rule** = below 0.8 mean similarity, claim-level
diffing is reported as best-effort only and per-subject verdict counts become the headline.

And its status is stated honestly: it measures the **same-document noise floor**, not AC6's
condition, which is a re-run against a *later commit* where tree and document have both moved. It
bounds the matcher's best case. It does not decide everything.

### AC4 — a claim may reference a finding

Unaddressed in revision 1. A `claim.finding_id` column, nullable, referencing `finding.id`. A claim
that leads to a defect points at it; the claim does not become one. This is the AC's second half
and it was simply missed.

### AC7 — the mutation proof, committed to

`tests/conformance.sh:2003-2097` is the template: it proves `before == after` on a poisoned batch,
round-trips hostile input in every field, and asserts empty differs from absent. The claim
equivalent proves: an invalid verdict rejects the **whole unit** and records nothing; an invalid
`location` likewise; a claim over 200 characters rejects the batch; `"claims": []` records a
measurement while an absent key is refused; and a foreign-subject census does not appear in an
unqualified status total.

## Dispositions (D2)

A second vocabulary, in `kit-claim.sh --vocab` beside the verdicts, and **operator-only** for the
same reason `--fixed` is: a session certifying its own output is the one signature carrying no
information.

| disposition | meaning |
|---|---|
| `accepted` | the claim stands; it is real and worth acting on |
| `false-positive` | the audit was wrong about the tree — a finding about the auditor |
| `low-value` | true but not worth acting on, with the reason |
| `actioned` | a task or finding was raised from it; carries the id |
| `deferred` | real, not now, with the reason |

Every disposition carries a required reason and is recorded as a `claim-disposition` event —
append-only, never a deletion, never an edit to the claim row. An undispositioned claim is
**neither accepted nor discarded**, and `kit-status.sh` reports that count as a standing figure the
same way unassessable findings are, rather than folding it into zero.

This is what makes the census usable the way D2 describes: opinions and feedback logged on specific
points, discards recorded as discards, and a history a later contributor can read.

## Sequence, revised

The old "durability first, then measure, then freeze" ordering is gone — it was an artefact of a
design that froze things.

1. **Artefact capture** — `kit-claim.sh --census ID --unit NAME --json` writes the reply verbatim
   under `.project/census/<census_id>/`, after manifest creation. T2. **Durability is complete at
   this step and nothing is locked in.**
2. **Derivation** — `kit_claims.py` + schema + `kit-index.sh` ingestion, reading artefacts, not
   events. T3, its own commit, `security-reviewer` per the profile.
3. **Dispositions** — `kit-claim.sh --disposition`, operator-only, `claim-disposition` events.
4. **Reporting and diff** — `kit-status.sh` per-subject figures, both drift fractions, the census
   diff.
5. **Variance measurement** — whenever; it now informs the diff's presentation rather than gating
   the design.

## Still open, and named rather than buried

- **F12's correction loop** is reduced but not built. A rejected unit keeps its data; re-deriving
  is manual until something automates it.
- **Derived-table build cost** at ~489 rows per census is bounded but unmeasured. It no longer
  touches the `events.ndjson` hot loop, which was the reviewer's actual concern.
- **The reviewer's question 3**, the auditor's `narrative`: answered by architecture. The raw
  artefact holds it verbatim. Whether the derived table also surfaces it is a reporting decision,
  not a durability one.
- **Whether a 489-claim reply fits one subagent response** — the reviewer flagged it as unchecked
  and it remains unchecked. It bears on unit granularity, not on this design.
- **F17**: the task frontmatter says `tier: T2` and omits `kit-index.sh` from `paths:`, so the
  derived `tier_floor` cannot see the T3 trigger. Fixed alongside this revision.

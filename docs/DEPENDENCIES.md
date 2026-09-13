<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Dependencies — the backlog audited edge by edge, 2026-09-13

`kit-plan.sh` sequences the backlog from one edge type: `blocked_by:` in a task file. Before this
audit **17 task files carried 23 such edges**, against **200 task files** — and the bodies of those
files referenced each other **273 times**. Almost every dependency this project has reasoned about
lived in prose, where nothing reads it.

That gap has a filed name already: `docs/design-input/2026-08-18-the-plan-is-the-unreviewed-artefact.md`
proposed extracting `T-\d{8}-` references from bodies and comparing them against `blocked_by`. This
is that extraction, run, judged, and applied.

**It is also an audit of the opposite error.** A dependency declared that does not exist pushes work
behind other work for no reason, and `kit-plan.sh` obeys it silently. Seven of the references below
are cases where the author had already decided the relation is *not* a blocker and wrote so. Those
are recorded as decisions, not converted.

## What changed

| | before | after |
|---|---|---|
| task files carrying `blocked_by:` | 17 | 26 |
| blocking edges | 23 | 42 |
| open tasks the plan holds in layer 1, gated | 7 | 15 |
| non-blocking relations recorded anywhere | 0 | 171 |

Nineteen edges were added: **11** promoted from prose across the backlog, and **8** on
`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie`, which is what the second brownfield trial
needs and is set out in its own section below.

## How this was derived

Every step is a command, so the audit can be re-run rather than believed.

1. **Candidate set** — for each task file, every `T-2026\d{4}-[a-z0-9-]+` in the body that is not
   the file's own id and not already in its `blocked_by:`. 273 references.
2. **Narrowed to live work** — both ends `open`/`created` (ADR 0008 resolves the legacy spellings).
   **175 candidate edges, 94 source tasks, 88 target tasks.**
3. **Judged one at a time**, from the paragraph containing the reference. Not from the title: a
   title says what a task is, never whether another task must land first.
4. **Applied.** Blocking edges to `blocked_by:` frontmatter. Everything else to
   [`dependency-map.tsv`](dependency-map.tsv), which carries the relations frontmatter cannot.

**Two artefacts, and they do not overlap.** `blocked_by:` is the only home for a blocking edge —
`kit-plan.sh` reads it and nothing reads the TSV. The TSV holds only relations that are *not*
orderings. This is deliberate: `T-20260826-two-artefacts-carrying-one-fact-with-not` is a filed
defect class in this repository, and a map that restated the frontmatter would be instance nine.

## The relation vocabulary

One edge type was not enough to record what the bodies actually say. Ten relations, of which
exactly one reaches the planner:

| relation | n | reaches `kit-plan`? |
|---|---:|---|
| `blocks` | 42 | **yes** — `blocked_by:` frontmatter |
| `related` | 111 | no |
| `umbrella-member` | 18 | no — see open decision 1 |
| `split-from` | 10 | no |
| `sequencing` | 7 | no — argued, not declared |
| `instance-of` | 7 | no |
| `not-a-blocker` | 7 | no — **the source task says so in its own words** |
| `co-decide` | 5 | no |
| `file-conflict` | 5 | no |
| `subsumes` | 1 | no |

All seven `not-a-blocker` edges in the full 273 are live, so none was lost by narrowing to open
work. Seven is small against 175, and it is seven more than any tool could have told you.

## The 11 promoted edges, with the sentence that justifies each

Each row is a dependency the task's own author wrote down and did not declare. The quotation is from
the dependent task's body.

| dependent | now blocked by | why |
|---|---|---|
| `T-20260802-record-spend-per-task-so-estimate-can-be` | `T-20260801-validate-a-task-s-recorded-tier-against-` | *"Tier accuracy is a prerequisite, not an adjacent concern... A forecast on those tiers reads low and then overruns."* Two of three measured tiers were too low. |
| `T-20260731-component-model-for-polyglot-and-moderni` | `T-20260819-legacy-candidate-selection-is-unresearch` | *"None of that can be earned without a subject, and no subject can be chosen without this."* The component model's field names are *"seeded, not earned"* and the instruction is to bind them to a real project. |
| `T-20260731-component-model-for-polyglot-and-moderni` | `T-20260822-the-overlay-is-scoped-to-modernization-i` | *"Modernization runs through three unbuilt things in order: the solution overlay, then [the component model], then the modernization delta."* |
| `T-20260815-ac6-modernization-delta-is-claimed-but-u` | `T-20260731-component-model-for-polyglot-and-moderni` | Third position in the same ordering sentence. |
| `T-20260811-a-retro-artefact-that-closes-the-kaizen-` | `T-20260812-status-has-no-time-dimension-so-daily-ac` | *"the retro artefact should consume this window rather than grow its own"* — building it first produces the second reporting path that task exists to prevent. |
| `T-20260819-nothing-computes-whether-a-change-is-hig` | `T-20260808-make-the-security-assurance-cadence-a-po` | Its AC2 puts the trigger in the profile beside `tier.rule`, and AC3 requires the rule to have **one home**. Declaring the trigger before the cadence defines that home creates the second home AC3 forbids. `T-20260819-researcher-carries-no-security-baseline-` already declares the same blocker. |
| `T-20260812-kit-init-leaves-a-footprint-in-an-adopte` | `T-20260912-paths-state-moves-the-state-directory-bu` | *"`T-20260812-kit-init-leaves-a-footprint-in-an-adopte` has to undo whatever this task writes."* An uninstaller written against the old layout would not find the new one. |
| `T-20260731-validate-the-priority-weights-against-es` | `T-20260912-kit-plan-treats-on-hold-as-plannable-so-` | Its own 2026-09-11 note traces the single score of 20.000 to a parked task the planner still scores. Recalibrating weights against an ordering with a known scoring defect measures the defect. **The weakest of the eleven** — the task's first acceptance criterion is escape data, not this — and the one to strike first if the gate reads too tight. |
| `T-20260912-trial-isolation-relies-on-a-file-tool-gu` | `T-20260912-a-trial-runs-in-a-container-on-the-subje` | *"This also supplies, cheaply, the OS-level boundary that [it] asks for."* A container is a boundary the agent does not enforce on itself; a file-tool guard is one it can route around via Bash, which trial 1 did six times. |
| `T-20260808-cluster-packs-are-generated-and-read-by-` | `T-20260817-a-cluster-pack-file-list-ignores-declare` | The ROI experiment measures what a pack is worth. Trial 1 loaded a pack that *"was nearly EMPTY — it named the sibling task and recorded no files"*, because no commit carried a `Task-Id` yet. Measuring the economics of an empty pack measures the pack builder's defect. |
| `T-20260816-kit-event-can-mint-privileged-event-kind` | `T-20260816-two-shell-writers-build-event-json-unesc` | *"Removing that argument would close most of this task as a side effect."* Recorded as `subsumes` as well as declared: the order is not just cheaper, doing it the other way round is wasted work. |

## What brownfield trial 2 needs — 8 blockers on the trial task

`T-20260808-trial-the-kit-on-one-unfamiliar-brownfie` had five blockers and **all five are
completed**, so it read as ready work. It is not: trial 1 ran under it on 2026-09-09, produced a
result the record itself calls into question, and 7 of its 11 acceptance criteria are still open.

The eight below come from trial 1's own record. Each one is a reason a second trial would produce a
number that cannot be read, or an isolation boundary that does not hold. **The test applied was not
"is this a defect trial 1 found" — it found more than eight — but "would trial 2 measure the wrong
thing without it".**

| # | blocker | tier | what it invalidates in trial 2 |
|---|---|---|---|
| 1 | `T-20260912-a-declared-rung-whose-tooling-fails-has-` | T3 | **The verdict itself.** Rungs 1 and 2 had tooling declared and failing — a state the ladder does not name — so the run could be neither satisfied nor declared unavailable. Three reviews passed a change that does not compile and the trial recorded **COMPLETE**. Without this, trial 2 can do it again. |
| 2 | `T-20260912-a-trial-runs-in-a-container-on-the-subje` | T2 | **Rungs 1–3, which never ran.** The subject is Linux-first; trial 1 ran on a Windows host where the crate does not build at all. This is also the cause of #1 rather than a separate wish. |
| 3 | `T-20260912-the-baseline-records-that-the-subject-is` | T2 | **Comparability with trial 1** — the reason to run a second trial on the same subject. Trial 1's baseline recorded pass/fail with no cause, one job's cause was generalised to four, and the wrong attribution stood for three days. |
| 4 | `T-20260911-the-isolation-check-passes-while-the-cop` | T2 | **The isolation claim.** The copy's own settings pre-approved `Bash(git *)` against another checkout of the subject and `kit-preflight.sh --isolated` still returned 0. Caught by hand in preparation, not by the check. |
| 5 | `T-20260911-kit-status-reports-spend-with-no-as-of-t` | T2 | **Every cost figure.** Trial 1 reported 6,902.9 kBTE for a main loop that had spent 10,259.6 — a reading taken inside the session, 33% low. |
| 6 | `T-20260911-a-finding-recorded-by-hand-carries-no-ag` | T2 | **Per-reviewer attribution.** All 11 findings carry `agent_id: ""` while all 3 reviewer spend rows carry an id, so no finding joins to the reviewer that produced it. Judging a second reviewer is one of the things a trial is for. |
| 7 | `T-20260911-a-carried-over-finding-is-recorded-as-a-` | T3 | **Every finding count.** 11 rows for 5 defects, because a carried-over finding is re-recorded each round with nothing linking it to its original. |
| 8 | `T-20260911-kit-init-next-steps-omit-choosing-git-ad` | T2 | **The central brownfield degradation.** `kit-init.sh`'s printed next steps omit choosing `git.adopted_at`, which `INSTALL.md:155` makes the first brownfield step. Trial 1 followed the printed order, left it unset, and got *"97 of 98 non-trivial commits carry no Task-Id"* — 0 `touches` edges, blast radius UNKNOWN, and over-tiering to T3 on a half-day change. |

**Deliberately not declared, and why.** These were considered and left out; each is a real defect and
none of them makes a trial-2 measurement unreadable.

- `T-20260911-kit-status-per-model-spend-lines-end-in-` (K8) — a CR on Windows. Trial 2 runs on
  Linux (#2), so it cannot fire there. Still a kit defect on the development machine.
- `T-20260911-kit-guard-refuses-the-harness-scratchpad` (K7) — the container in #2 is the boundary
  this is about; a design tension, not a bug, and the trial record says so.
- `T-20260911-kit-init-prints-the-claude-remedy-when-t` (K5) — wrong remedy text in a message. It
  cost minutes in trial 1 and misleads; it does not corrupt a measurement.
- `T-20260801-nothing-invokes-kit-finding-so-the-findi` — **the closest call.** In plugin mode 11 of
  11 findings landed only because the session ran `kit-finding.sh --json` by hand. Recording by hand
  is now a documented procedure that worked, so this is not declared — but if trial 2 is meant to
  exercise the feedback loop rather than work around it, this is the ninth blocker.

## Claims the record already refutes

Three sequencing arguments in the backlog are contradicted by measurements taken since they were
written. None was converted into an edge, and each is left in the TSV as `sequencing` rather than
silently dropped.

1. **"Roughly half the emitted findings are currently rejected for unknown classes"** —
   `T-20260801-nothing-invokes-kit-finding-so-the-findi`, arguing that the vocabulary must be fixed
   before the plumbing or the sample will be biased. Trial 1 measured **0 rejected of 11**, 0
   `finding-gap` rows, on `claude-sonnet-5`. n = 1 agent, so the claim is not disproved — but it is
   no longer a measurement, and it should not gate the plumbing on its own.
2. **"`T-20260814-one-entry-mechanism-brownfield-is-the-ge` is completed"** — written in
   `T-20260822-the-overlay-is-scoped-to-modernization-i`. It is `open`. The argument built on it does
   not depend on the state, but the sentence is false today.
3. **`T-20260808-task-state-cannot-express-no-longer-rele` "may already be satisfied"** —
   `T-20260912-kit-plan-treats-on-hold-as-plannable-so-` notes ADR 0008 added `cancelled` for exactly
   that purpose *"which is worth checking separately"*. Nobody has checked. One `cancelled` task
   exists.

## Broken references

Four ids appear in bodies and resolve to no task file. Three are benign and one is a typo.

| reference | verdict |
|---|---|
| `T-20260802-spend-rows-key-on-a-shared-transcript-so` | **benign** — a recorded rename, in the sentence that records it. |
| `T-20260801-cross-project-accelerator-aggregation` | **benign in the body** — it is the worked example inside `T-20260808-a-task-id-matching-no-task-file-is-count`, which is a task *about* unresolvable ids. **Not benign in history:** commit `aa377ed` carries it as a real `Task-Id` trailer with the wrong date prefix, and it is the one id `kit-status.sh` reports unresolved. The task exists as `T-20260731-cross-project-accelerator-aggregation`. A trailer in merged history cannot be corrected without a rewrite. |
| `T-20260826-a-verified-claim...` | **benign** — an ellipsis in prose. |
| `T-20260810-the-suite-that-gates-every-control-has-` | **typo** — one character short of `...has-n`, in `T-20260912-conformance-runs-on-one-core-so-the-only`. Corrected in this change. |

## Open decisions — three, and none of them is mine to take

1. **The state-and-context umbrella.** `T-20260912-state-and-context-management-has-no-unif` names
   18 open tasks as its subject matter. If that design is to lead, it should block those 18 and the
   plan should say so; if the patches proceed piecemeal, the design task is documentation of a
   problem rather than a gate. **Eighteen edges hang on this answer and none was written.** They are
   recorded as `umbrella-member` in the TSV so the question stays visible.
2. **The weights edge (#8 in the promoted table).** Argued from the task's own note rather than from
   a sentence saying "prerequisite". Strike it if the gate reads too tight.
3. **The ninth trial-2 blocker** — whether trial 2 must exercise the findings loop or may record by
   hand again. See the list above.

## What would make this maintainable

This audit is a snapshot, and the next twenty tasks will write dependencies in prose exactly as the
last two hundred did. The mechanical form is already specified in
`docs/design-input/2026-08-18-the-plan-is-the-unreviewed-artefact.md`: extract every `T-\d{8}-`
reference from a body, require it to appear in `blocked_by:` or in this map, and fail otherwise.

That is a check that can fail, it is deterministic, and it is not built. It is **proposed, not
filed** — filing is the operator's.

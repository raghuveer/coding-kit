---
id: T-20260912-state-and-context-management-has-no-unif
title: State and context management has no unifying design so a dozen open tasks patch it piecemeal
epic: components
tier: T2
lang: markdown
paths: docs/design-input
state: created
---

## Intent

The kit's state, and the context it puts in front of an agent, are its two load-bearing mechanisms.
**Neither has one design.** Decisions exist in pieces:

- ADR 0004 — the plan is text; the index is derived from it;
- ADR 0008 — task states and their partitions;
- ADR 0011 — claims live in artefacts, not the index;
- `HANDOFF.md:174` — *"The plan is state, not context"*;
- design input `2026-09-09-one-core-many-adapters`, §7 — the remaining token levers are peak
  context window and model mix.

That design input's §10 also proposed *"reduce peak context per session and measure it against
escape rate"*. It was never filed. This task covers it.

Meanwhile, open tasks fix the seams one at a time:

- **Packs and task-context:**
  - `T-20260808-cluster-packs-are-generated-and-read-by-`
  - `T-20260817-task-context-reads-the-task-spec-at-step`
  - `T-20260820-task-context-has-no-branch-for-a-missing`
  - `T-20260817-a-cluster-pack-file-list-ignores-declare`
  - `T-20260817-a-touches-edge-is-never-checked-against-`
  - `T-20260911-kit-status-re-decides-pack-withholding-w`
- **The plan and the index:**
  - `T-20260820-kit-plan-computes-the-ordering-before-re`
  - `T-20260821-kit-plan-writes-two-meta-keys-the-indexe`
  - `T-20260821-if-stale-watches-the-head-file-which-git`
  - `T-20260818-nothing-reviews-the-plan-so-a-wrong-orde`
  - `T-20260808-decompose-kit-index-along-the-seam-it-al`
- **Task state:**
  - `T-20260819-vocabularies-live-in-shell-constants-so-`
  - `T-20260822-legacy-state-spellings-in-task-files-sho`
  - `T-20260808-task-state-cannot-express-no-longer-rele`
  - `T-20260822-derived-owner-flips-to-whoever-committed`
- **Session state:**
  - `T-20260811-restore-session-state-from-checkpoint-co`
  - `T-20260827-discovery-is-a-multi-session-phase-with-`
- **Measuring context:**
  - `T-20260911-kit-status-reports-spend-with-no-as-of-t`
- **Filed alongside this one:**
  - `T-20260912-kit-plan-treats-on-hold-as-plannable-so-` (parked tasks)
  - `T-20260912-paths-state-moves-the-state-directory-bu` (`paths.state`)

**Where the context actually goes, measured.** In the 2026-09-09 highper-gateway trial, the main
loop's spend rows record the size of its context window at each reading. It read **145,641** tokens
at turn 51 and **324,496** at turn 267, the turn that ended the trial. At that point the main loop
accounted for **10,259.6 of 11,014.2** billed input-token-equivalents (kBTE), which is 93.1%.
(`events.ndjson` in the trial's evidence directory; the rows are cumulative, and the indexer keeps
the last one per transcript.)

The kit's own standing charge is small by comparison:

- about 840 tokens for eight agent descriptions (nine ship today), measured in the adapters design
  input;
- the 33 lines of `CLAUDE.kit.md`.

Caching is near its floor, at a cache-read ratio of 97.5% (`DESIGN-NOTES.md` §0).

**Operator direction, 2026-09-11:** *"while using markdown files are ok where necessary, we need to
plan state management and context management with a clear focus."*

## Acceptance criteria

- [ ] A design input under `docs/design-input/`, containing:
      - **a state inventory:** every piece of state the kit reads or writes, whether it is source
        or derived, committed or local, and who writes it and who reads it;
      - **a context model:** what enters an agent's context, when, and at what measured cost —
        resident, per session and per task. It includes peak context per session measured against
        the escape rate, which is the measure the adapters design input's §10 proposed;
      - **a stated rule** for when state is markdown, when it is derived (sqlite), and when it is
        not persisted;
      - **the open tasks listed above, mapped onto it,** with an order.
- [ ] Every number is produced by a named command or cites the artefact it came from. A number that
      cannot be measured today is marked as such.
- [ ] It separates what belongs to the portable core from what belongs to an agent adapter.
- [ ] It proposes and does not decide. It files nothing and marks nothing itself, and an independent
      reviewer reads it before any ADR is drafted from it.

## Notes

**Tier T2 on risk, not because of a floor.** The docs floor is T1, but this document sets the order of
about twenty tasks.

The terms it uses are defined by the glossary task filed alongside it.

Filed at the operator's direction of 2026-09-11, before any design is written.

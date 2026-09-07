---
id: T-20260907-an-opt-in-adapter-for-structural-edges-s
title: An opt-in adapter for structural edges so blast radius does not depend on history
epic: measurement
tier: T3
lang: bash
blocked_by: T-20260808-co-change-has-no-eval-harness-so-its-sco
paths: tooling/kit-index.sh, tooling/schema.sql, skills/task-context/SKILL.md, docs/ADAPTERS.md, tests/conformance.sh
state: created
---

## Intent

Every signal the kit has for blast radius is derived from **history**, and on a brownfield
repository on day one both of them are weak or absent:

| signal | source | state on day one of a brownfield adoption |
|---|---|---|
| `touches` edges | `Task-Id` git trailers | **empty by construction** — the repo has no kit trailers |
| co-change | raw commit history | present, at **recall@10 = 0.24** — three related files in four are missing |

`skills/task-context/SKILL.md` states both consequences itself, in steps 5 and 6. Neither signal
reads the code. Nothing in the kit answers *what does this symbol actually call, and who calls it,
in the tree as it stands right now* — a question that needs no trailers, no history, and no model.

This task adds that as a **third source, through the existing ingest seam**, and measures whether
it earns its place.

## Why this is not the storage question the blocking task closed

The blocking task records, as CLOSED, that five graph databases were evaluated against the
`cochange` table and **no engine changes which files come back** — because the query is one indexed
`ORDER BY weight DESC LIMIT 10` over a precomputed adjacency list. That verdict stands and this
task does not re-open it.

**A different engine over the same derivation is not the same proposal as a different derivation.**
That research changed where co-change rows are stored; this changes where the rows come from —
tree-sitter over the working tree instead of `git log` over history. The blocking task's own
conclusion is that *"the bottleneck is signal quality"*; a signal computed from a different input
is a candidate under exactly that conclusion, not an evasion of it.

## Why this is blocked, and must stay blocked

0.24 is `n=1`, produced by hand, and the blocking task exists because **nothing can tell whether it
moved**. Adding a second source before the harness exists means replacing one unmeasured signal
with two, and calling the result an improvement. That is the failure this task would otherwise
commit and then have to be reviewed for.

The blocking task's ground truth — *files that actually changed together in commits held out of the
training window* — is the right target for a structural signal too, and is not circular: it is
derived from held-out commits, not from the co-change score being tested. **This task reuses that
harness and that ground truth. It must not build a second one.**

## Scope: adapter, never a dependency

`INSTALL.md:9-11` promises **no language runtime — no Node, no Python, no PowerShell** —
deliberately, so a Go or Rust team can adopt the kit without installing a toolchain. Every
off-the-shelf structural-graph tool surveyed carries a runtime; `trailhq/Graft`, the one read at
source, declares `engines.node >= 20`.

So the two obvious shapes are both refused up front:

- **Bundling or requiring one** breaks that promise for precisely the audience it was written for.
- **Reimplementing multi-language structural parsing in `bash` with no runtime** is not a capability
  this kit can carry, and is the wrong side of the support-kit scope boundary. The kit's settled
  position on tools it does not own is **ship the adapter, never the scanner** — the same reasoning
  `T-20260825-a-security-rung-on-the-ladder-satisfied-` applies to security scanners.

What is left is what `docs/ADAPTERS.md` already defines and needs no amendment to support:

```
ingest.extra: tools/structural-edges.sh    # repo-relative and git-tracked, both enforced
```

The adapter emits SQL for a **new relation, `calls`**, kept distinct from `touches` so the
history-derived and tree-derived signals stay separately measurable — which the recall comparison
below requires. An adopter who sets nothing gets exactly today's behaviour.

`ADAPTERS.md`'s binding constraint holds: *"an adapter that puts something in the index that exists
nowhere else breaks it."* A structural graph is itself a regenerable cache, so the graph and
`index.db` can both be deleted and rebuilt from the tree. The derived-index invariant survives.

## Preconditions — operator decisions this task cannot make

Recorded as gates rather than assumptions. **The first can kill this task outright.**

- [ ] **Is an optional language runtime acceptable at all?** `INSTALL.md` currently reads as an
      absolute. Opt-in makes it conditional, which changes a published promise rather than a file.
      If the answer is no, this task is closed unbuilt and that is a legitimate outcome.
- [ ] **Which tool, and does its telemetry disqualify it?** Graft's is anonymous and allowlist-
      enforced in source, flushed by a detached process at most daily. "A detached process posts
      daily" is still a sentence some client engagements will refuse, and the kit would be the
      thing that recommended it. A tool with no telemetry, or a telemetry-off flag, ranks higher.
- [ ] **Confirm `calls` as a new relation** rather than reusing `touches`.

## Acceptance criteria

- [ ] The adapter is invoked through `ingest.extra` **only**, with no change to the built-in
      sources, and a repository that sets nothing produces a byte-identical index to today's.
- [ ] Structural edges are measured **through the blocking task's harness**, on the same held-out
      window, reported as recall@10 beside co-change's re-measured figure. n and the window stated.
- [ ] **Marginal recall is reported, not just absolute.** The union of both signals against
      co-change alone — a structural signal that returns the files co-change already returns adds a
      dependency and nothing else, and that outcome must be reportable rather than absorbed.
- [ ] `task-context` step 5 traverses `calls` edges, and step 6's rule is preserved verbatim for
      the new signal: **it widens blast radius and never bounds it.** A tier is not lowered because
      a structural query came back short.
- [ ] Conformance proves the adapter path with the tool **absent**: a declared `ingest.extra` whose
      executable is not installed must degrade to today's behaviour with a warning, never fail the
      index. `kit-index.sh --if-stale` runs at the start of every session and must not become a
      hard dependency on a tool the adopter may not have.
- [ ] Cost is measured against the `--if-stale` path. `ADAPTERS.md` records that built-ins run
      inline because a bare process spawn costs ~0.2s on Windows; this machine has been measured at
      ~1000ms spawns. **If the adapter lands near that, it is gated behind explicit invocation
      rather than the session-start path**, and that decision is recorded with its number.
- [ ] `docs/ADAPTERS.md` gains the structural-source example; `docs/DESIGN-NOTES.md` carries the
      new recall figures with method and date, as the blocking task requires for co-change.
- [ ] Mutation proof: an adapter emitting a `calls` edge to a path absent from the tree is refused,
      not indexed. (Same defect class as
      `T-20260817-a-touches-edge-is-never-checked-against-`.)

## What would falsify this task

Stated so a later session can close it cheaply instead of re-arguing it:

1. **Recall.** Structural edges do not beat 0.24 on the same eval set.
2. **Overlap.** They beat it, but land on files co-change already returns — marginal value near
   zero at any absolute recall.
3. **Polyglot.** The tool's language coverage misses a candidate subject's primary language, so the
   adapter returns little on precisely the repositories that motivated it. Both current candidates
   (highper-gateway, aeon) are polyglot.
4. **Cost.** The spawn cost makes `--if-stale` expensive enough that the adapter cannot sit on the
   session-start path, and explicit invocation turns out to be a path nothing takes.

Any one of these is sufficient. Record the result either way — **a source that loses is as useful
to record as one that wins**, which is the rule the blocking task already sets for scoring changes.

## Notes

Filed 2026-09-07 from `docs/design-input/2026-09-07-graft-as-a-structural-source.md`, which reads
`trailhq/Graft` at source and works through integrate-vs-replicate. That document is the argument;
this is the work. Its §6 falsifiers and §7 operator questions are reproduced above rather than
referenced, so this task stands alone.

Graft is named throughout as the tool that was actually read, not as the tool that was chosen. The
adapter contract is tool-agnostic by construction; **selecting the tool is part of this task, not an
input to it.**

Tier declared T3, not classified — `tooling/kit-index.sh` in `paths` floors it at T3 under
`tier.rule` regardless, the same way the blocking task was corrected from T2. Run `tier-classify`
before starting work rather than trusting this line.

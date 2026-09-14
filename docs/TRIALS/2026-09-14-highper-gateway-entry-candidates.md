# Entry candidates — highper-gateway @ e588b53

> **Preserved trial evidence.** On the subject this file lives at `.project/entry-candidates.md`,
> which that repository ignores, so it would be lost with the copy. `ENTRY-PROPOSAL.md` step 3 calls
> it committed; on this subject it cannot be. Copied here unaltered.

Produced 2026-09-14 from `.project/entry-facts.tsv`, `.project/entry-comment-runs.tsv` and
`.project/entry-report.md`. **Nothing here has been filed.** The operator runs the lines they
accept, or does not.

**Procedure deviation, recorded:** `docs/ENTRY-PROPOSAL.md` step 2 says a `researcher` subagent
returns this text. That agent is not available — see the `Could not determine` section. The
orchestrator produced the judgement itself, which is a weaker arrangement: the reader of this file
cannot tell the census apart from the author of the census.

## Open questions

1. Why does KNOWN_LIMITATIONS.md record `Linux support excellent` while `cargo check --workspace
   --all-features` fails on Linux with 91 errors. The default build passes - is the claim scoped to
   default features and simply unqualified.
   evidence: KNOWN_LIMITATIONS.md:371, docs/TRIALS/2026-09-14-highper-gateway.md:46
   answer:

2. What did the `114 TODO/FIXME comments in 36 files` count include. Measured at e588b53 the
   figure is 84 in 26 `.rs` files, or 343 in 86 tracked files of every kind. Neither reproduces it,
   and the document does not say what it counted.
   evidence: KNOWN_LIMITATIONS.md:413, KNOWN_LIMITATIONS.md:418
   answer:

3. The co-change graph holds 149 files that are not in the tree - a restructure, a deletion, or
   history that predates the current layout. Which.
   evidence: .project/entry-report.md
   answer:

4. 347 of 370 markdown files have exactly one commit, against 174 commits of history. Is
   documentation written once by intent, or has it drifted from code that moved without it.
   evidence: .project/entry-facts.tsv
   answer:

5. Four source files carry a co-change degree above 55 with a single author each -
   `dsl_parser.rs` 96, `server.rs` 83, `handler.rs` 73, `dsl_converter.rs` 56 - and none has been
   touched since 2026-05-16. Is that a stable core or an unowned one.
   evidence: .project/entry-facts.tsv
   answer:

## Candidate tasks

- [ ] KNOWN_LIMITATIONS records two figures that the tree does not reproduce
      evidence: KNOWN_LIMITATIONS.md:371, KNOWN_LIMITATIONS.md:413
      kit-task.sh --title 'KNOWN LIMITATIONS records two figures the tree does not reproduce' --tier T1 --lang markdown --paths 'KNOWN_LIMITATIONS.md'

- [ ] A documented count carries no method so no reader can reproduce it
      evidence: KNOWN_LIMITATIONS.md:413
      kit-task.sh --title 'A documented count carries no method so no reader can reproduce it' --tier T1 --lang markdown --paths 'KNOWN_LIMITATIONS.md'

- [ ] Documentation exceeds code and 94 percent of it was written once - 195858 markdown lines
      against 110814 Rust lines, 347 of 370 files at one commit
      evidence: .project/entry-facts.tsv
      kit-task.sh --title 'Documentation exceeds code and 94 percent of it was written once' --tier T1 --lang markdown

- [ ] The known-limitations document already inventories the TODO backlog
      evidence: KNOWN_LIMITATIONS.md:410
      kit-task.sh --title 'The known-limitations document inventories the TODO backlog' --state completed --via manual --paths 'KNOWN_LIMITATIONS.md' --tier T0

- [ ] Windows native support is documented as not working and a fix is deferred to v1.2.0 - not
      work to schedule from a census
      evidence: KNOWN_LIMITATIONS.md:359
      kit-task.sh --title 'Windows native support is deferred to v1.2.0 by decision' --state cancelled --tier T0

## Could not determine

- **the `researcher` subagent named by `docs/ENTRY-PROPOSAL.md` step 2 does not exist in the
  session running this trial.** The kit ships it at `agents/researcher.md` and since 0.2.0 is
  distributed as a plugin, so the agent exists only where that plugin is installed in the harness.
  `kit-init.sh` mentions agents nowhere. On this subject `.claude` is excluded six ways, so no
  project-level copy is possible either. Indistinguishable from: not installed / not supported by
  this harness / withheld.
- the 149 out-of-census co-change files are reported as a count, not a list, so which files they
  are cannot be read from the artefacts.
- per-file `commits` and `authors` are **lower bounds**: the report records `merges 2`.
- `touches` edges: empty, and expected to be - `git.adopted_at` is the adoption commit by the
  operator's decision. Not indistinguishable from withheld here only because the trial record says
  so; the artefacts alone could not tell.

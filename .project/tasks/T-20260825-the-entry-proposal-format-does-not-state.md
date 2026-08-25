---
id: T-20260825-the-entry-proposal-format-does-not-state
title: The entry proposal format does not state the title charset its own check enforces
epic: validation
tier: T2
paths: docs/ENTRY-PROPOSAL.md, tooling/kit-entry.sh
state: created
---

## Intent

K-2 of the highper-gateway trial, 2026-08-24.

`researcher` was given the `docs/ENTRY-PROPOSAL.md` format verbatim and wrote candidate titles
that name paths, because naming the file is the clearest way to say what the work is:

    3.1.F delete the orphaned src/admin/api.rs
    3.7.A write docs/MONITORING.md ...

The title whitelist is `A-Za-z0-9`, space, `.`, `_`, `-`. `/` is not in it, so `kit-entry.sh`
refuses them: *"kit: candidate line is not safe to paste"*. **At least 10 of 103 candidates**
on this subject.

**The format section never states the charset.** It appears only in the grammar block under
*"What `--check` does and does not enforce"*, positioned after the format section, and expressed
as a grammar rather than as an instruction to whoever is writing titles. So the document teaches
one thing and the validator enforces another, and the author finds out after producing a hundred
candidates.

This is a documentation-versus-tool disagreement, which is the same shape as the two
`MIGRATION.md` rows and the licence declaration: **two artefacts carry one fact and nothing
compares them.**

## Acceptance criteria

- [ ] Resolved in ONE direction, not both, and the choice is stated:
      **either** the format section states the charset where an author will read it before
      writing, **or** the whitelist admits `/`. Doing both leaves the same disagreement with a
      smaller gap.
- [ ] If the whitelist is widened, the reason it exists is preserved. It is a **paste-safety**
      rule — these lines are pasted into a shell command — so `/` must be shown to be safe in
      that context before it is admitted, not merely convenient. A path is safe in a quoted
      argument; the check is whether every consumer quotes.
- [ ] If the format section states the charset instead, it says what to write **instead of** a
      path, because "do not name paths" leaves an author with no way to identify a file.
- [ ] A check that the documented charset and the enforced charset agree, so this cannot drift
      again. The two live in different files and nothing currently reads one against the other.
- [ ] Mutation proof: change one to disagree with the other and the check goes red.

## Notes

**The interesting half is where the rule was placed, not what it says.** It was written under a
heading about what `--check` does and does not enforce — accurate, and invisible to the person
who needed it. An author reads the format section and stops. Rules that constrain authoring
belong where authoring is described, and this is worth stating in the fix because the same
document will grow more rules.

**10 of 103 is a floor, not a count.** Only the refused lines were counted; nobody checked how
many surviving titles were reworded around the limit before being written down.

Reproduced 2026-08-24 during the highper-gateway trial; see
`docs/TRIALS/2026-08-24-highper-gateway.md` K-2.

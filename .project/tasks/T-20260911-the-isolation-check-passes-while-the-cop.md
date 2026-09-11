---
id: T-20260911-the-isolation-check-passes-while-the-cop
title: The isolation check passes while the copy's own settings pre-approve git against other checkouts
epic: validation
tier: T2
paths: tooling/kit-preflight.sh, docs/TRIAL-PROTOCOL.md, tests/conformance.sh
state: created
---

## Intent

`kit-preflight.sh --isolated <copy>` answers *"is there a path back from the trial copy to the
subject?"* by checking two things: a git remote, and an `alternates` entry
(`tooling/kit-preflight.sh:39-65`). **A trial copy can carry a third path that it does not model —
its own Claude Code settings.**

Reproduced 2026-09-11 on `D:\trials\highper-gateway-05c56eb`, the copy prepared for the
highper-gateway trial:

- The subject **tracks** `.claude/settings.local.json`, so `git clone` brings it into the copy.
- It pre-approves 24 commands, including **`Bash(git *)`**, and **seven** entries naming
  `/d/my-opensource/highper-gateway` — six `git -C` commands and one `nerdctl build`. That path is
  **a second checkout of the same subject, outside the copy, with uncommitted changes.**
- User-level settings on the machine pre-approve **nothing** (`~/.claude/settings.json`, 0 allow
  entries), so this file would be the trial session's only pre-approval.
- `kit-preflight.sh --isolated` printed *"isolated -- no remote, no shared object store"* and
  exited 0.

So any command beginning `git` — `git -C <the other checkout> push`, `checkout -- .`,
`reset --hard` — would run in the trial session **with no prompt**, against a repository the copy
exists to protect. `TRIAL-PROTOCOL.md` §4 rests on *"the removed remote is what makes the procedure
hold when the guard cannot"*. A pre-approved `git *` routes around the removed remote entirely,
because it never needs the copy's remote.

**Why the kit owns this rather than the subject.** Pre-approving git in its own repository is the
subject's business. Printing "isolated" about a copy is the kit's claim, and the claim is printed
while it is false.

## Acceptance criteria

- [ ] `--isolated` reads the copy's Claude Code project settings (`.claude/settings.json` and
      `.claude/settings.local.json`) and **names** every allow rule that is unscoped for a command
      able to reach outside the copy (`Bash(git *)`, `Bash(git:*)`, `Bash(*)`), or that names an
      absolute path outside the copy.
- [ ] It **fails** on them rather than warning. The check's whole job is to stand between an agent
      and the subject, and a warning printed beside "isolated" reads as a pass.
- [ ] Mutation proof: a fixture copy with `Bash(git *)` in a tracked `settings.local.json` fails;
      the same copy without it passes; a rule scoped inside the copy passes.
- [ ] The success line names what was checked, so "isolated" is never printed about a property
      the check did not test.
- [ ] `TRIAL-PROTOCOL.md` §4 gains the step and says what it still cannot see: a permission rule is
      not a sandbox, and a prompted command can still be approved by a human.

## Notes

**Mitigated for the 2026-09-09 highper-gateway trial by hand**, recorded in that trial's §0b: the
file was moved out of the copy, byte-identical, to
`D:\trials\highper-gateway-05c56eb.settings.local.json.orig`, with the restore command beside it.
That is a procedure, not a control — which is this task's point.

**Not fixed before the trial, deliberately.** `tooling/` is plugin-loaded, and the trial freezes
everything the plugin loads at `50226b8`. Fixing it now would change the kit under test.

Filed before any fix, per the working agreement. Found while answering the operator's question
about what approvals the trial session would need.

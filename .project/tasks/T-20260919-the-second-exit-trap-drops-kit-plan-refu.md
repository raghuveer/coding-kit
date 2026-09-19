---
id: T-20260919-the-second-exit-trap-drops-kit-plan-refu
title: The second EXIT trap drops KIT_PLAN_REFUSED so one temp file leaks on every index
epic: reporting
tier: T2
paths: tooling/kit-index.sh
state: created
---

## Intent

**`kit-index.sh` sets its EXIT trap twice, and the second one is not a superset of the first.**

    :219   trap 'rm -f "$SQL" "$KIT_REFUSED" "$KIT_PLAN_REFUSED" "$KIT_SEEN" "$DECL_OUT"' EXIT
    :1730  trap 'rm -f "$SQL" "$KIT_REFUSED" "$KIT_SEEN" "$NEW" "$DECL_OUT"' EXIT

A second `trap ... EXIT` REPLACES the first rather than adding to it, and the replacement drops
`$KIT_PLAN_REFUSED`. That file is created by `mktemp` at `:218` on every run, so **one temp file
is left behind by every successful index**, in whatever `TMPDIR` points at.

**This is pre-existing, not introduced by the branch that found it.** The same asymmetry is on
`main`, at `:219` and `:1577`, with the same omission. It has presumably leaked one file per index
for as long as both traps have existed.

**How it was found, which is the part worth keeping.** A conformance step written to cover a
DIFFERENT leak -- `T-20260817-a-cluster-pack-file-list-ignores-declare` added `$DECL_OUT` to the
first trap and forgot to initialise it, so under `set -u` the whole trap died on a repository with
no task files -- failed on its first run against the already-fixed code, and the residue it
reported was this one. The step counts files in a redirected `TMPDIR` before and after, so it sees
any leak rather than the one it was written for.

## Acceptance criteria

- [ ] Every temp file `kit-index.sh` creates is removed on exit, on a repository with task files
      and on one without
- [ ] The two traps cannot drift apart again: either one trap covers every name, or the second is
      derived from the first rather than retyped
- [ ] A conformance step fails if any temp file survives a run — the step exists already under
      `T-20260817`; this criterion is that it stays green for the right reason
- [ ] `$NEW` is checked too: it is named only by the second trap, so the reverse asymmetry is
      confirmed rather than assumed

## Notes

Filed 2026-09-19. The defect is one line; the reason it is filed separately from the fix is that
it is not the branch's defect, and folding a pre-existing leak into a pack-listing change would
hide it from the escape record.

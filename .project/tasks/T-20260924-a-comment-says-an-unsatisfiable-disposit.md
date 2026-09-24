---
id: T-20260924-a-comment-says-an-unsatisfiable-disposit
title: A comment says an unsatisfiable disposition exits 2 and the code exits 3
epic: agent-contracts
tier: T2
lang: bash
paths: tooling/kit-preflight.sh
state: created
---

## Intent

`tooling/kit-preflight.sh:487-489`, the header of the red-disposition gate, says `=unsatisfiable`
*"exits 2 rather than 0 or 1 so a caller can tell the two stops apart"*. The code exits **3**
(`:587`), and a comment ninety lines further down explains why 2 was abandoned: 2 already means
not-a-repo, not-adopted and bad usage in the same script. The header states the claim the later
comment refutes.

Found 2026-09-24 by a read-only verifier reconciling the open findings of
`T-20260912-a-declared-rung-whose-tooling-fails-has-`; re-checked by grep on `main` at `a158d0a`.
The code is right. The comment a reader meets first is wrong about the one number a caller keys on.

## Acceptance criteria

- [ ] The header comment names exit 3, or points at the comment that explains it, and says nothing about 2 as the VOID signal.
- [ ] `grep -n 'exits 2' tooling/kit-preflight.sh` returns nothing that describes the unsatisfiable path.

## Notes

Same shape as the per-rung line `328f07b3` already records against the parent task: text left
behind on a path whose behaviour changed.

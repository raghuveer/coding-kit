---
id: T-20260926-a-tracked-path-with-an-apostrophe-breaks
title: A tracked path with an apostrophe breaks kit-index under bash 3.2
epic: conformance
tier: T3
lang: bash
paths: tooling/kit-index.sh, tests/conformance.sh
state: created
---

## Intent

`tooling/kit-index.sh` builds the tracked-path table with
`printf "... VALUES('%s');" "${_tf//'/''}"` -- the pattern substitution inside DOUBLE QUOTES.
Bash 5 yields `it''s.md`; **bash 3.2 keeps the backslashes and yields `it''s.md`**, which is not
valid SQL. So on macOS's `/bin/bash`, any repository that tracks a path containing an apostrophe
fails to index. Line 662 already uses the safe form: an unquoted assignment, then the variable.

Found 2026-09-26 by both blind reviewers of PR #182, independently; reproduced in a bash:3.2.57
container (quoted `it''s.md`, unquoted `it''s.md`). Introduced by `7039da2` (2026-09-19). The
end-to-end failure on a real macOS runner is inferred from the expansion plus sqlite's rejection
of the SQL, not yet observed.

## Acceptance criteria

- [ ] The expansion uses the form bash 3.2 and 5 agree on.
- [ ] A conformance fixture tracks a path with an apostrophe, so the macOS leg (bash 3.2) exercises it.
- [ ] Other double-quoted `${var//pat/rep}` uses in `tooling/*.sh` checked for the same shape.

## Notes

PR #182's claim that tooling "parses under bash 3.2" was a parse check; this is a runtime difference
a parse check cannot see.

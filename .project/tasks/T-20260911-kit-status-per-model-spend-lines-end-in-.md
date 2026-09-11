---
id: T-20260911-kit-status-per-model-spend-lines-end-in-
title: kit-status per-model spend lines end in a carriage return on Windows
epic: portability
tier: T2
lang: bash
paths: tooling/kit-status.sh, tests/conformance.sh
state: created
---

## Intent

On Windows, `kit-status.sh`'s per-model spend lines end in a carriage return. In the 2026-09-09
highper-gateway trial's `kit-status.txt`, lines 56-57 — `> - claude-opus-5  6902k` and
`> - claude-sonnet-5  754k` — each end in a CR byte, and no other of its 91 lines does.

`q()` (`kit-status.sh:32`) is a bare `sqlite3` call, and `:483` sends its multi-row output straight
to stdout. Four other multi-row outputs in the same file — `:871`, `:887`, `:909` and `:923` — pipe
through `tr -d '\r'`. This one was missed.

Small, but not free: anything that reads the report as data gets a CR inside the value, and the
trial's evidence directory needed `-text` to store the file unchanged.

## Acceptance criteria

- [ ] No line `kit-status.sh` writes carries a CR, on any platform. The fix is made once, in `q()`
      or at the output, not by adding a fifth `tr` beside the four.
- [ ] A conformance step asserts that `STATUS.generated.md` contains no CR byte. Because `sqlite3`
      emits no CR on Linux and macOS, the step must inject one (a `sqlite3` wrapper that emits
      CRLF), or it cannot fail where CI runs.

## Notes

Proposed at T1 and filed at T2, the floor `tooling/**` sets in this repository's profile.

Found in the highper-gateway plugin-mode trial, kit defect K8 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`, while checking that the trial's evidence
was copied byte for byte. Filed before any fix.

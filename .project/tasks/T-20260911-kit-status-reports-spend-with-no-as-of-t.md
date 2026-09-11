---
id: T-20260911-kit-status-reports-spend-with-no-as-of-t
title: kit-status reports spend with no as-of time so a reading inside a session omits the latest turns
epic: measurement
tier: T2
lang: bash
paths: tooling/kit-status.sh, tests/conformance.sh
state: created
---

## Intent

`kit-status.sh` reports spend with no as-of time, so a reader cannot tell a current figure from one
that stopped minutes or hours ago.

The main loop's spend rows are written by the `Stop` hook at the **end** of each turn, and the index
keeps the latest row per transcript. So a `kit-index.sh` run inside a turn sees, at best, the row the
previous turn wrote.

On the 2026-09-09 highper-gateway trial, the final `kit-status.sh` (14:09Z) reported the main loop
at **6,902.9 kBTE**. That row was written at **13:57:34Z**. The trial's own boundary-report turn
ended at 14:10:54Z at **10,259.6 kBTE**, so the status understated the main loop by a third and
nothing on the page said so. The reconciliation is from `events.ndjson` in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode/`.

## Acceptance criteria

- [ ] Every spend figure `kit-status.sh` prints carries, per scope, the time of the newest row it
      includes.
- [ ] When `events.ndjson` holds a newer `spend` event for a transcript than the index does, the
      report says the index is behind, and by how long, instead of printing the older figure as
      current.
- [ ] A conformance step appends a later spend row for a transcript after indexing and asserts that
      the behind-notice fires; after a rebuild, it asserts the notice does not fire.

## Notes

The protocol side of the same finding is methodology M1 in the trial record: read the final figure
after the session closes. This task is the kit's side — whoever reads the figure should be able to
see how old it is.

Found in the highper-gateway plugin-mode trial, kit defect K4 in
`docs/TRIALS/2026-09-09-highper-gateway-plugin-mode.md`. Filed before any fix.

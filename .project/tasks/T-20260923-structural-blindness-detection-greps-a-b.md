---
id: T-20260923-structural-blindness-detection-greps-a-b
title: Structural blindness detection greps a basename so it is blind on Rust
tier: T2
lang: bash
state: created
---

## Intent

`docs/TRIAL-PROTOCOL.md` §3 carries the detection for the one VOID condition that leaves no
trace — a per-file review structurally blind to a defect whose halves live in different files.
The detection is:

    git grep -lF "$(basename F)" -- . ':!docs' ':!.project' ':!*.md' | grep -v "^F$"

It greps for the **filename**. That is true of the kit's own shell scripts, which name each
other as `kit-guard.sh`, and false of every language whose module system drops the extension.

**Measured on trial 3, 2026-09-23.** Run on all three changed files
(`plugin/ffi.rs`, `plugin/wasm.rs`, `plugin/host_functions.rs`) it returned **nothing** — which
reads as "no other file could hold the other half". Asked by module stem instead, it returned
**six**: `plugin/mod.rs`, `types.rs`, `trait_def.rs`, `config.rs`, `manager.rs`, `hot_reload.rs`.
Every one of them genuinely could hold the other half, and `mod.rs` and `trait_def.rs` are where
the reviewers' findings actually landed.

A control that returns empty on an entire language is the exact shape §3 exists to catch: it
reads as a pass and it asked nothing.

## Acceptance criteria

- [ ] The detection finds the related files on a Rust subject, demonstrated on this trial's
      three files, returning the six rather than zero.
- [ ] It still finds them on a shell subject — `kit-guard.sh` must still return
      `hooks/hooks.json` among its six, which is the case §3 was written from.
- [ ] Where it cannot know the convention, it says so rather than returning empty. An empty
      result must be distinguishable from "asked and found none".
- [ ] §3's row carries the new form, and the old one is kept with what it missed, per §3's own
      practice of keeping superseded detections visible.

## Notes

Trial 3 record: `docs/TRIALS/2026-09-20-highper-gateway.md`, K2 / M-1.

Languages this affects: Rust, Python, Go, Java, TypeScript — anything importing by stem.

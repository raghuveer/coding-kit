---
id: T-20260912-the-transcript-reader-parses-one-vendor-
title: The transcript reader parses one vendor's field names inside the portable core
epic: portability
tier: T2
lang: bash
paths: tooling/kit-spend.sh, docs/ADAPTERS.md
state: created
---

## Intent

`kit-spend.sh:214` parses `input_tokens`, `output_tokens`, `cache_read_input_tokens` and
`cache_creation_input_tokens` -- one vendor's transcript schema -- and it does so **inside the
portable core**, not behind the adapter seam `docs/ADAPTERS.md` already defines for every other
ingest source.

The kit is meant to work with any coding agent. Today a second host has no path to a spend row
short of editing the core, which is precisely the boundary violation the ingest contract exists
to prevent. The seam is already built and already has a producer-swap contract; this reader
simply never used it.

## Acceptance criteria

- [ ] The reader is reachable through the ingest-adapter contract (`emit` / `fingerprint`), so a second host supplies its own without touching the core
- [ ] The existing reader stays the default, and spend rows produced after the move are identical to those produced before it on the same transcript
- [ ] `docs/ADAPTERS.md` documents the spend producer beside the existing ones, including what a host must supply and what degrades if it cannot
- [ ] A conformance step runs a stub spend adapter emitting two rows and asserts they land, so the seam is proven by something other than the shipped reader

## Notes

Pairs with `T-20260912-the-spend-price-vector-is-hard-coded-to-`: that one makes the price
configurable, this one makes the reading portable. Neither is useful alone -- a portable reader
priced with one vendor's weights is still one vendor's answer.

`T-20260819-the-claude-adapter-is-16-files-but-nothi` counts the adapter surface; this reader is
one of the files that count has never included, because it lives in `tooling/`.

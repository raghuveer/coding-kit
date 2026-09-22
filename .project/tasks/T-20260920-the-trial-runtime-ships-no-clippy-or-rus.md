---
id: T-20260920-the-trial-runtime-ships-no-clippy-or-rus
title: The trial runtime ships no clippy or rustfmt so two ladder rungs have no tooling
epic: validation
tier: T2
paths: docs/trial-runtime/Dockerfile
state: created
---

## Intent

**Two of the verify ladder's rungs cannot run in the runtime the protocol prescribes.**

Measured 2026-09-20 on `cck-trial`
(`sha256:372fc7a9d8648f21110bc50efd1def80661f2e513ede3328369a95a7722b9d29`):

    cargo clippy --locked   exit 1   'cargo-clippy' is not installed for the toolchain '1.98.1-x86_64-unknown-linux-gnu'
    cargo fmt --check       exit 1   'cargo-fmt'   is not installed for the toolchain '1.98.1-x86_64-unknown-linux-gnu'

`rust:1-bookworm` ships `cargo` and `rustc` and not the `clippy` or `rustfmt` components. The
Dockerfile's own header lists every package it installs and why — *"EVERY PACKAGE BELOW WAS NAMED
BY A MANIFEST, NOT GUESSED"* — and that method read the subject's build dependencies. **Lint and
format are not build dependencies, so the method that produced a correct list for rung 1 could not
see rungs 3 and 4.**

**This is the 2026-09-09 failure in its exact shape, one layer out.** That trial recorded COMPLETE
while declared tooling could not run. Here the tooling cannot run because the runtime does not carry
it, and the rung is `unsatisfiable` under the vocabulary landed on 2026-09-20 — so a trial in this
image either stops at pre-flight or proceeds with two rungs it cannot satisfy.

**Adding `rustup component add clippy rustfmt` is probably the whole fix**, and it is deliberately
not applied here: changing the runtime changes the digest, and §0 records the digest as part of the
result. Doing it mid-pre-flight without recording why is the class of move §2 makes void.

## Acceptance criteria

- [x] The runtime carries the tooling for every rung the ladder declares, or the Dockerfile states
      which rungs it deliberately cannot serve and what that costs a trial
- [x] The method is corrected, not just the list. The manifest-reading rule produced a right answer
      for build dependencies and a silent gap for verification tools; whatever replaces it names
      where rung tooling comes from
- [x] A check that can fail: the image is asserted to provide each declared rung's command, and a
      mutation removing one takes it red
- [x] The digest is re-recorded and the change is dated, since §0 treats it as part of the result

### Fixed 2026-09-20

`RUN rustup component add clippy rustfmt` added to `docs/trial-runtime/Dockerfile`, with the
reason stated where the next reader of that file meets it: the apt list above it was read from the
subject's declared BUILD dependencies, so it served rung 1 and could not see rungs 3 and 4.

**The method is corrected, not just the list.** The Dockerfile now says that rung tooling does not
come from the subject's manifest, because lint and format tools are not build dependencies — which
is why a right answer for rung 1 produced a silent gap for two other rungs.

**Digest re-recorded**, since §0 treats it as part of the result:
`sha256:372fc7a9d864…` → `sha256:e5ed7efcc9b5…`

**Measured after**: `cargo clippy --locked` now RUNS (exit 101, one real error,
*"this loop never actually loops"*) and `cargo fmt --check` passes. Both rungs moved from
**unsatisfiable** to a disposition a human can make.

## Notes

Found 2026-09-20 taking the trial-3 pre-flight baseline, alongside
`T-20260920-the-copy-procedure-produces-crlf-on-a-wi`. Both were invisible until the pre-flight was
executed rather than read, which is the argument for §0 existing at all.

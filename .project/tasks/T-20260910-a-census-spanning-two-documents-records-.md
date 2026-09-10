---
id: T-20260910-a-census-spanning-two-documents-records-
title: A census spanning two documents records a manifest source that contradicts its units
epic: reporting
tier: T2
lang: python
state: created
---

## Intent

`3e76f904`, critical, and it stayed in the gate on 2026-09-09 when the other two claim-identity
findings were superseded. It is not a keying question and does not wait for the second census.

**Both fields ship today:**

    tooling/kit_manifest.py:44   ("source_document", ...)   REQUIRED on every manifest
    tooling/kit-claim.sh:93      "source": "docs/ROADMAP.md"   per unit, in the artefact

A manifest names ONE `source_document` for the whole census. Each captured unit names its own
`source`. For a single-document census they agree by luck. **For a census spanning two documents
the manifest contradicts its own units**, in the committed artefact, with no derivation involved --
which matters more since ADR 0011 made the artefact the record rather than a staging area.

The first census (`handoff-invariants-2026-09-09`) is single-document, so the defect is latent
rather than visible. That is why it has to be decided before the second census and not after.

## Acceptance criteria

- [ ] The relationship is decided and written down: is `source_document` a **constraint** every unit
      must match, a **default** a unit may override, or **redundant** and removed? Three different
      answers and the artefact format cannot hold all three.
- [ ] Whichever is chosen, a check that can fail: a unit whose `source` disagrees with the
      manifest's `source_document` is either refused at capture, or recorded and reported. **Refusing
      it at capture needs care** -- F12 says a reply that fails validation keeps its data, so a
      refusal must not discard the tokens that produced it.
- [ ] The existing census is asserted unaffected, not assumed: `handoff-invariants-2026-09-09` has
      one unit and one document.
- [ ] If `source_document` survives, `kit_manifest.py`'s REQUIRED list says what it means when units
      disagree. A required field with undefined semantics is the shape this repository files against
      itself.

## Notes

Filed 2026-09-10 from the disposition of the three claim-identity criticals. Two were superseded by
ADR 0011 because they criticise a `claim_key` computed at index time -- `census-store.md:310` (F4) --
and the shipped artefact contract emits no key at all. This one survives because its subject is the
artefact schema rather than the derivation, and ADR 0011 was amended to say so after first claiming
all three were unaffected.

**Not a blocker on the brownfield trial by mechanism**, but it is one of the three criticals holding
that gate at 3, so it blocks in practice.

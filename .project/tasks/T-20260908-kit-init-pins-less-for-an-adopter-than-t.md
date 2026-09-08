---
id: T-20260908-kit-init-pins-less-for-an-adopter-than-t
title: kit-init pins less for an adopter than the kit pins for itself, and nothing pins a census artefact
epic: adoption
tier: T2
lang: bash
paths: tooling/kit-init.sh, .gitattributes, tests/conformance.sh
state: created
---

## Intent

`kit-init.sh` writes an adopting repository exactly two `.gitattributes` entries. The kit gives
itself more than that, on the same files, for reasons it states in its own comments.

| file | the kit pins for ITSELF | `kit-init.sh` gives an ADOPTER |
|---|---|---|
| `.project/events.ndjson` | `merge=union` **`text eol=lf`** (`.gitattributes:20`) | `merge=union` only (`kit-init.sh:123`) |
| `.project/plans/*.tsv` | `text eol=lf` | `text eol=lf` (`kit-init.sh:139`) ✓ |
| `*.json` | `text eol=lf` (added `ad68aad`) | **nothing** |

Two gaps, and the first is the one nobody was looking for.

## Gap 1 — the adopter's event log is not pinned, and the kit's own comment says why that matters

The kit's `.gitattributes:16-19` explains its own pin:

> append-only shared log: take both sides rather than conflicting. **Pinned to LF for the same
> reason as `*.md` above — it is READ as data, and the indexer stores whole lines of it as
> `event.payload`, so a CRLF checkout would carry the CR into the row.**

`kit-init.sh:121-124` writes `merge=union` and stops. So the reason the kit gives for pinning its
own log — *the indexer stores whole lines as `event.payload`* — applies identically to every
adopter and is not acted on for any of them. An adopter on Windows gets `\r` inside recorded event
payloads.

Note the contrast one screen down: `kit-init.sh:136-141` pins the plan to LF and explains at length
why (`a CRLF checkout would carry a CR into the goal id and the task digest`). The same author, the
same file, the same argument, applied to one of the two files it covers.

## Gap 2 — a census artefact is unpinned wherever D4 puts it

`ad68aad` pinned `*.json` **in the kit repo** after an approach review found every tracked `.json`
was `i/lf w/crlf`. That fix does not travel: `find templates accelerators -iname '*gitattributes*'`
returns nothing, and `kit-init.sh` writes no `*.json` rule.

**D4 makes this the normal case, not the edge case.** A census is project-scoped by default and
lives in the *subject's* `.project/census/`, so the artefacts D5 references by hash are in the
adopter's repo — the one place nothing pins them. The kit fixed the defect for the only repository
where the census is the *fallback* location, and left it open for the default one.

## Reproduced 2026-09-08

- `grep -n "events.ndjson" .gitattributes` → `.project/events.ndjson merge=union text eol=lf`
- `grep -n "events.ndjson merge=union" tooling/kit-init.sh` → line 123, no `text eol=lf`
- `grep -n "eol=lf" tooling/kit-init.sh` → only the two `plans/*.tsv` lines
- `find templates accelerators -iname '*gitattributes*'` → empty

## Acceptance criteria

- [ ] `kit-init.sh` pins `.project/events.ndjson` to `text eol=lf` alongside `merge=union`, for the
      reason the kit's own `.gitattributes` already gives.
- [ ] It pins whatever covers a census artefact — `*.json` or a `.project/census/**` rule — with
      the choice argued, since a bare `*.json` in an adopter's repo touches files the kit does not
      own.
- [ ] **The idempotence trap is not re-introduced.** `kit-init.sh:132-135` records that
      `grep -q 'plans/'` matched any unrelated attribute (`plans/*.pdf binary` was enough), silently
      suppressed the pin, and printed the success line anyway. Any new pin uses the exact-line
      `grep -qxF` form and reports failure when the append fails.
- [ ] A conformance step adopts a throwaway repo and asserts the resulting `.gitattributes`
      contains every rule the kit relies on — driven from a list with one home, so a rule added to
      the kit and not to `kit-init.sh` fails rather than passing unnoticed.
- [ ] The step asserts a non-empty denominator, so a fixture that adopts nothing cannot report green.

## Notes

Filed 2026-09-08 on the operator's instruction, reproduced before filing.

**Found by an approach-review verifier, not by the author of the fix it follows.** While confirming
that `ad68aad` closed the CRLF half of `38f178a2`, the verifier noted the fix does not ship —
`templates/` carries no `.gitattributes` and D4 puts the normal-case census in the subject's repo.
Gap 1 surfaced only on reading `kit-init.sh` to write this task up.

**This is the asymmetry, stated plainly: the kit protects itself and not its adopters, on files it
reads as data.** That is worth more than either individual pin, and it is why the fourth criterion
asks for a list with one home rather than three more `printf` lines.

**Tier declared T2, not classified.** `tooling/**` has a T2 floor and this writes into a file the
adopting repository already owns, where a wrong pattern affects files the kit did not create. Run
`tier-classify` rather than trusting this line.

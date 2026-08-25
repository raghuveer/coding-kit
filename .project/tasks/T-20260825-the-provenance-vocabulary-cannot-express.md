---
id: T-20260825-the-provenance-vocabulary-cannot-express
title: The provenance vocabulary cannot express AI-assisted work done without the kit
epic: measurement
tier: T2
paths: tooling/kit-lib.sh, docs/adr, templates/project-profile.md
state: created
---

## Intent

K-7 of the highper-gateway trial, found in the walkthrough with the subject's maintainer on
2026-08-24. **This is the finding a trial produces that no amount of reading the code would.**

`kit_via_vocab` is exactly four values — `kit agent manual unknown` (`tooling/kit-lib.sh:126`).

Asked how the subject was actually built, the maintainer said: *"before I started creating
sub-agents, mostly up to Sonnet 4.5 on Claude subscription"* — a human driving an assistant
interactively. No kit. No subagents. **None of the four values says that:**

| value | why it is wrong here |
|---|---|
| `kit` | false — the kit was not involved |
| `agent` | implies an agent ran it |
| `manual` | erases the assistant entirely |
| `unknown` | honest, but discards information the maintainer actually has |

The trial's own proposal had written `--via manual` on all ten completed candidates. Under the
maintainer's account that is **false on all ten**, and `unknown` is the only defensible value
available today — which means the kit forces a choice between a false statement and a discarded
one.

## Why this is not an edge case

Escape rate is reported over `via:kit` **and** over `all`, deliberately, so that provenance
changes what a number means rather than whether an escape is visible. The population *between*
those two — **AI-assisted but not kit-run** — has no name. On brownfield that population is most
of the backlog, and the maintainer reports a second project in the same state.

**A kit whose thesis is human-plus-AI collaboration cannot currently label the ordinary case of
it.** That is a gap in the measurement vocabulary, and it lands on Charter dimension 2: a
denominator that cannot describe the population it counts is not a measurement.

## Acceptance criteria

- [ ] The vocabulary can express **AI-assisted, not kit-run**. Whether that is one new value or
      a second orthogonal axis is the design question — see Notes; do not assume the answer.
- [ ] The vocabulary has ONE home. `kit_via_vocab` is already that home and every consumer reads
      from it; adding a value must not reintroduce a second list. The finding vocabulary drifted
      across four locations once and produced agents whose output the recorder rejected.
- [ ] **Existing values keep their meaning.** `Via:` is written into commit history and history
      cannot be amended, so any change is additive. Redefining `manual` to mean "no AI" would
      silently rewrite the meaning of every commit already carrying it.
- [ ] `kit-status.sh` reports the new population separately rather than folding it into `all`.
      Folding it in reproduces the exact problem: a bucket that cannot be told from its
      neighbours.
- [ ] The trailer validator accepts the new value and rejects unknown ones, as now.
- [ ] ADR-shaped, because it has options and consequences and it changes a frozen vocabulary.
      The README declares trailers frozen once adopted, so this needs the reasoning recorded,
      not just the value added.

## Notes

**The design question, stated so it is not decided by accident.** `via` currently answers *who
did the work*. The maintainer's case needs *two* facts — was an assistant involved, and was the
kit involved — and one enum expressing a cross product grows badly: `agent`, `assisted`,
`assisted-agent`, `manual` is four values for two booleans, and the next distinction makes it
eight. A second key, or a value plus a modifier, may be the better shape. **Deciding this by
adding one value because one value was what the trial needed is how a vocabulary becomes a
list.**

**Back-filling is constrained and the constraint is already recorded.** `Via:` is a git trailer
and a written commit cannot gain one; back-fill uses the lowercase `via:` frontmatter key, and a
`Via:` trailer beats it. So whatever value is added must be usable from frontmatter, or it
cannot describe pre-adoption history — which is the only history this value is for.

Found 2026-08-24 in the maintainer walkthrough; see
`docs/TRIALS/2026-08-24-highper-gateway.md` K-7.

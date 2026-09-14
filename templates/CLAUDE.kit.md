<!-- Append to the target repo's CLAUDE.md. Keep it this short: every line here is
     paid on every request of every session. If deleting a line does not change
     behaviour, leave it deleted. -->

## Working agreement

- Declare a tier (T0-T3) before spawning any reviewer. Untiered work is either
  overspend or a missing control, and afterwards you cannot tell which.
- Truth lives in task files and git trailers. `STATUS.generated.md` and
  `.project/index.db` are derived — never edit them, and never treat them as input
  that outranks the text they came from.
- Never write outside the project root.
- Commits carrying real change carry `Task-Id:` and `Tier:` trailers.
- `Via:` records HOW the work was done — `kit`, `agent`, `manual`. Optional; absent
  means `unknown`, which is reported as unknown. Escape rate is reported over the
  kit-run population **and** over every task, side by side — so provenance changes
  what a number means, never whether an escape is visible.
  **If you are an agent reading this: do not write `Via:` on your own commits.** Propose
  a value in your summary and stop there. A self-reported `via: kit` from the agent that
  did the work is the one value nobody should take on trust.
- `Fixes-Escape-Of: <task-id>` records that this change fixes a defect an EARLIER task's
  review should have caught. It is the numerator of escape rate, and **it has never been
  written here — 0 commits in 324.** Nothing was hiding it: it is read by `kit-trailers.sh`
  and documented in README and HANDOFF. It was simply absent from this file, which is the
  one a session actually reads.
  **If you are an agent reading this: propose it in your summary and stop**, as with `Via:`.
  The reason differs and is worth knowing — `Via: kit` flatters the pipeline, so a
  self-report is worthless; this one INCRIMINATES it, so the risk is not a false claim but a
  claim never made. Silence here reads as "nothing escaped" when it means "nobody looked".


**For the operator, not the agent** — every instruction in this block is yours:

- You put `Via:` on the trailer, after deciding it.
- You put `Fixes-Escape-Of:` on the trailer, after deciding the defect genuinely escaped a
  prior review rather than being new work. Until one is written, every escape-rate numerator
  in every report is zero by construction, and `kit-status.sh` now says so rather than
  printing a clean-looking `0`.
- Retract a wrong value with `Via: unknown` on a later commit, never with `Via: manual`;
  those mean different things and only one is a claim.
- Nothing mechanically stops an actor with commit access from writing `Via: kit`. This is
  a convention you enforce, not a gate the kit closes.
- Back-filling a task finished before adoption? The frontmatter key is lowercase `via:`.
  `Via:` is the git trailer, and a commit already written cannot gain one.

> Why the split: this file is read by the agent every session, so an instruction addressed
> to "you" is read by the model as its own. Instructions are grouped by who they are for.

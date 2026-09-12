---
id: T-20260819-the-claude-adapter-is-16-files-but-nothi
title: The Claude adapter is 16 files but nothing records that or names the second one
epic: components
tier: T2
lang: markdown
paths: docs/DESIGN-NOTES.md, docs/ADAPTERS.md, .claude-plugin/plugin.json
state: open
---

## Intent

The kit is already two layers and **nothing says so**, which means the boundary is real but
undefended: any change may quietly cross it and nobody would notice until a port was attempted.

Measured 2026-08-18:

| | |
|---|---|
| `CLAUDE_PLUGIN_ROOT` in `tooling/` | **0 occurrences** |
| Model names or `anthropic` in `tooling/` or `tests/` | **none** |
| What the `.claude/` references in `tooling/` are | 12 × the path to `project-profile.md` — a directory name |
| The harness-coupled surface | **16 files**: `skills/` 5, `agents/` 8, `hooks/` 1, `.claude-plugin/` 2 |

So the **portable core** is 18 shell scripts, a sqlite schema and text files, knowing nothing about
Claude beyond a folder name; the **adapter** is 16 files. `tooling/kit-review-record.sh` was built
as the seam deliberately — its header states that `--cmd` *"is the only thing that knows how a
reviewer is invoked here, so no harness name, CLI or model appears in this file."*

Porting to another coding agent is therefore **writing a second adapter, not refactoring**. That is
a materially different piece of work from what it looks like from outside, and it is currently
recorded nowhere — it exists only as a Note in
`T-20260818-relicense-from-mit-to-apache-2-0-while-s` saying a rename is "deliberately not bundled",
which is a deferral rather than a record.

## Acceptance criteria

- [ ] The two-layer boundary is **documented where a contributor will hit it**, with the one
      genuine hardcode named: `kit_profile()` in `kit-lib.sh` fixes `.claude/project-profile.md`,
      and `paths.*` config keys already exist as the pattern for making it a value.
- [ ] A check that the boundary holds — no harness name, model name or `CLAUDE_*` variable appears
      under `tooling/`. It is true today, and true-by-accident becomes false the first time someone
      reaches for convenience. This is the cheap half and it is worth doing even if no port ever
      happens.
- [ ] What a second adapter must supply is enumerated from the 16 files rather than guessed:
      skill equivalents, agent definitions, the hook surface, and a manifest.
- [ ] **Do not port before the kit has been validated once.** The brownfield trial has never run.
      Generalising an unvalidated design is `T-20260808-cluster-packs-are-generated-and-read-by-`
      at architecture scale — built at both ends, documented, never measured. This criterion is a
      sequencing constraint and exists to be argued with, not silently dropped.
- [ ] The rename to a generic identity is decided **with** this, not before it. The name should
      follow from what the kit proves to be; renaming twice is the avoidable cost.

## Notes

Filed 2026-08-19 from an audit that found the finding recorded in conversation and in a Note, but
nowhere a future reader would look.

Licence work is separate and already filed
(`T-20260818-relicense-from-mit-to-apache-2-0-while-s`) — Apache 2.0 is the right licence for a
multi-adapter end product, but it does not depend on the port and should not wait for it.

**The operator's stated goal** is a kit usable with Claude Code as a plugin and subsequently with
other coding agents. The measurement above says that goal is closer than it appears; this task
exists so the distance is recorded rather than re-derived by whoever picks it up.

**2026-09-11 — spend capture is adapter behaviour living in the portable core, and the boundary
check as written would miss it.**

The second acceptance criterion checks that no harness name, model name or `CLAUDE_*` variable
appears under `tooling/`. That passes today: no non-comment line in `tooling/*.sh` uses a `CLAUDE_*`
variable. Yet `tooling/kit-spend.sh` depends entirely on Claude Code's formats:

- **the hook payload fields** `transcript_path` and `agent_type` (`kit-spend.sh:75-76`);
- **the transcript directory layout** `<session>/subagents/agent-<id>.jsonl`, with a `.meta.json`
  beside each file (`:88`, `:108`, `:122`, `:141`);
- **Anthropic's usage fields** in each transcript line: `input_tokens`, `output_tokens`,
  `cache_read_input_tokens` and `cache_creation_input_tokens` (`:211-214`).

So per-agent spend — one of the two readings the 2026-09-09 highper-gateway trial confirmed — works
only under Claude Code, even though the script lives in the core.

The enumeration this task asks for ("the hook surface") should name spend capture explicitly: a
reader per adapter that emits the kit's own `spend` event. And the boundary check needs a second
form, one that looks for foreign data formats, not just names.

**A second dependency of the same kind:** `kit-charter.sh:50` reads `.claude-plugin/plugin.json`.

**The sequencing criterion's premise is now out of date.** It says *"the brownfield trial has never
run"*, but trial records now exist for:

- 2026-08-12 — `fd`, a throwaway subject;
- 2026-08-24 and 2026-08-26 — highper-gateway;
- 2026-08-27 — aeon;
- the plugin-mode run of 2026-09-11, recorded as `2026-09-09-highper-gateway-plugin-mode`, which
  ran on Claude Code only.

Whether they meet the criterion is the operator's call.

Operator direction, 2026-09-11: the kit is meant to work with any coding agent.

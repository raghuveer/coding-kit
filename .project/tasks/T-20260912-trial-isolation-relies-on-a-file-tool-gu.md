---
id: T-20260912-trial-isolation-relies-on-a-file-tool-gu
title: Trial isolation relies on a file-tool guard instead of an OS-level boundary around the agent
epic: validation
tier: T2
lang: markdown
paths: docs/TRIAL-PROTOCOL.md, docs/TRIALS/TEMPLATE.md
state: created
---

## Intent

`docs/TRIAL-PROTOCOL.md` §4 isolates a trial with two things: a removed git remote, and `kit-guard`.
It says itself that the guard *"does not see Bash at all — no `git push`, no `rm`, no redirect. So
non-destructiveness is a procedure *you* enforce"* (`TRIAL-PROTOCOL.md:377-379`).

**The 2026-09-09 highper-gateway trial found one hole in preparation, and hit the other during the
run:**

- **In preparation:** the copy's own settings pre-approved `Bash(git *)` against another checkout
  of the subject. This was found before the run and removed by hand
  (`T-20260911-the-isolation-check-passes-while-the-cop`).
- **During the run:** the session wrote six files outside the copy through Bash, while the guard
  refused the one Write it did see. Nothing reached the kit repository or either real checkout
  (trial notes, 14:05:06Z; `T-20260911-kit-guard-refuses-the-harness-scratchpad`; methodology M2
  in the trial record).

**What an OS-level boundary adds.** Anthropic's AI-native SDLC playbook isolates Claude Code at the
operating system — filesystem and network isolation, with `failIfUnavailable` so a session refuses
to start when the sandbox cannot. Claude Code's own documentation ("Configure the sandboxed Bash
tool") says those limits apply to every shell command and its child processes, and adds three that
shape this task:

- **It covers the Bash tool only.** Read and Edit are governed by permission rules.
- **It runs on macOS, Linux and WSL2 — native Windows is not supported.** Without
  `failIfUnavailable`, an unsupported platform falls back to running unsandboxed, with only a
  warning. This repository's trials run on a Windows host.
- **By default it allows writes** to the working directory, the session temp directory (`$TMPDIR`
  points there) and any added directory. So the default already permits some writes outside the
  copy.

For agents other than Claude Code, sandboxes were not checked and may not exist. Where there is no
agent sandbox, a container or VM whose only writable mount is the copy provides the same
OS-level boundary. That form works for any agent.

**Which platforms a trial runs on is the subject's decision, not the kit's.** Per the operator on
2026-09-11, a trial runs on each operating system the subject supports today, and moves to the
others its project plans as they arrive.

**highper-gateway, as the worked example.**

- **Its goal, from its owner:** *"use io_uring for linux and its alternatives for other operating
  systems"*.
- **Today:** Linux. The alternative backend files exist
  (`src/runtime/{epoll_backend,hybrid_stream,io_uring_shim}.rs`), but the adapter is not complete,
  and `tokio-uring` is an unconditional dependency (`highper-gateway/Cargo.toml:13`) — which fits
  the failed native Windows build. So its trials run on Linux now — on a Windows host, that means
  inside WSL2 or a container.
- **Next:** its trials cover Windows and macOS once the alternatives land.
- **Its documentation says more than the code does today.** `KNOWN_LIMITATIONS.md:371` reads
  *"Windows native builds work but testing limited"*, and the 2026-09-09 trial found a native
  Windows build fails. That is a subject finding for the owner. So the pre-flight takes the
  platform list from the owner and records any mismatch with the docs, rather than trusting the
  docs alone.

**One cost for the kit.** The conformance suite drives spend capture with fixture transcripts. The
kit's live plugin mode on Windows — hooks under Git Bash, `CLAUDE_PLUGIN_ROOT` — is exercised only
by a trial. A Linux-only trial leaves that path untested until a subject that supports Windows is
trialled.

## Acceptance criteria

- [ ] §4 states the requirement for any agent: **an OS-level boundary around the trial session**,
      either the agent's own sandbox or a container or VM whose only writable mount is the copy.
      The Claude Code sandbox, run under WSL2 on a Windows host, is the first worked example; no
      single agent's flags define the protocol. A platform with neither kind of boundary cannot
      start a trial.
- [ ] §4 assigns each control to what it actually sees. The OS boundary is primary for shell
      commands. `kit-guard` and the agent's file-tool permission rules are primary for file writes.
      The removed remote is defence in depth.
- [ ] Network egress is in scope: the boundary allows only the destinations the run needs (package
      registries, for example), and the trial record lists what was allowed.
- [ ] A pre-flight box, run through the agent's own shell inside the trial session (a probe from the
      operator's terminal tests nothing): writes to the subject's original checkout, and to any path
      outside the copy named in the agent's configuration, are refused. The sandbox refuses to start rather than
      falling back (`failIfUnavailable`, or the equivalent for the chosen boundary).
- [ ] §4 says whether the session temp directory stays writable. That is the same decision as K7's
      open question about where temporary files belong, and both record one answer.
- [ ] The protocol names what the boundary still does not cover, and how each gap is handled:
      a human approving a prompted command, and a verification environment that needs network
      (the trial's container spent about 15 minutes downloading crates).
- [ ] `docs/TRIALS/TEMPLATE.md` records the boundary a trial used — which kind, which platform, its
      configuration — so two trials can be compared.
- [ ] The pre-flight records the platforms the subject's owner says it supports today, runs the trial
      on those, and records any mismatch with the subject's own documentation as a subject finding.

## Notes

**Filed separately, but it lands with three siblings.** All four change the trial protocol:

- `T-20260911-the-isolation-check-passes-while-the-cop` — its criterion that *"a permission rule is
  not a sandbox"*;
- `T-20260911-kit-guard-refuses-the-harness-scratchpad` (K7) — where temporary files belong;
- methodology item M2 in the highper-gateway trial record, proposed for §3 but not yet written.

Landing them together avoids four overlapping edits to one document.

**A portability flag on the first sibling.** It proposes that `tooling/kit-preflight.sh` read
`.claude/settings*.json`, which would put a Claude-specific file in the portable core. Worth
resolving there.

**T2 on risk, not because of a floor:** docs floor at T1, but this is the primary isolation control
for every future trial.

Source: idea 2 from the operator's review of Anthropic's playbook, 2026-09-11; limits quoted from
Claude Code's sandbox documentation, read the same day. Filed before any change to the protocol.

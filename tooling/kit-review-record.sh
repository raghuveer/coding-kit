#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-review-record.sh --task ID|--unattributed --agent NAME --cmd '<command>'
#                      [--prompt-file F] [--max-attempts N] [--model M] [--agent-id X]
# kit-review-record.sh --task ID|--unattributed --agent NAME --reply-file F
#                      [--model M] [--agent-id X]        [a reply already in hand; no retry]
#
# Run a reviewer, validate what it returns, hand back the validator's own diagnostics if it was
# refused, and record the result. The loop that closes the findings circuit.
#
# WHY THIS EXISTS. The contract asks a reviewer to return one JSON object. Across four live
# runs it was ignored three times -- a reporting tool was called instead, an object arrived
# wrapped in a fence, a summary ran to 208 characters. Each time a human read the diagnostics
# and fixed the reply by hand, which is exactly the intervention this task's first acceptance
# criterion forbids. A system prompt is a request. This is the mechanism.
#
# WHAT IT DOES NOT DO: spawn the reviewer itself. `--cmd` is supplied by the caller and is the
# only thing that knows how a reviewer is invoked here, so no harness name, CLI or model
# appears in this file. The contract with that command is one line:
#
#     it reads a prompt on stdin and writes the reviewer's whole reply to stdout.
#
# `--reply-file` IS THE SECOND DOOR, AND IT EXISTS BECAUSE THAT CONTRACT CANNOT ALWAYS BE MET.
# In plugin mode a reviewer is an Agent-tool subagent: there is no command that reads stdin and
# writes stdout, so `--cmd` has no satisfiable value and the only remaining path was a human
# typing `kit-finding.sh --json`. Measured on the 2026-09-09 highper-gateway trial: 11 of 11
# findings landed that way, by hand, which is the intervention acceptance criterion 1 forbids.
#
# This door takes the reply the orchestrator already holds and runs it through the SAME
# validation, the SAME recorder and the SAME gap-on-refusal. What it cannot do is RETRY, and
# that is a property of the situation rather than a shortcut: a correction restates the original
# request -- `kit_findings.py --correction` requires `--original-file` and exits 2 without it --
# and a caller holding one finished reply has nothing to re-ask with. So `--reply-file` closes
# the RECORDING half of the loop and leaves the COMPLIANCE half open, and says so rather than
# reporting a bounded retry that never happened.
#
# WHAT `--cmd` DOES NOT PREVENT -- read this before trusting a review's independence.
# Whatever tool restriction you put in that command is a REQUEST to the harness, not a
# boundary this script imposes. Demonstrated 2026-08-16: a reviewer launched with exactly
# `--allowedTools "Read,Grep,Glob" --disallowedTools "ReportFindings"` ran `Bash` anyway --
# the session transcript shows the `tool_use` with `is_error: false`. So:
#
#   - A reviewer CAN read anything the operator can read, run shell commands, and in
#     principle edit the code it is reviewing. `agents/*-reviewer.md` saying "read-only by
#     design" is behavioural shaping and nothing more.
#   - Nothing here compares the tools an agent declared against the tools it used. The one
#     violation seen was noticed only because the reviewer disclosed it unprompted.
#   - What IS enforced: the reply is written to a file and validated, never executed, and
#     `kit-guard.sh` refuses Write/Edit/NotebookEdit outside the project root -- though that
#     hook does not match `Bash`, so a shell command is not covered.
#
# If a review's independence has to survive an uncooperative reviewer, isolate the process
# (a container, a copy with no remote per `kit-preflight.sh --isolated`) and diff the tree
# afterwards. Do not rely on the flag. `SECURITY.md` §3 carries the full account.
#
# ATTEMPTS ARE BOUNDED and the bound is not a formality: a reviewer that cannot satisfy the
# contract in N tries will not satisfy it in twenty, and an unbounded loop against a paid
# endpoint is a bill, not a retry. When the attempts run out the failure is RECORDED as a
# finding-gap, because a review whose findings were refused is a hole in the measurement and
# the one thing it must not be is silent.
set -uo pipefail
. "$(dirname "$0")/kit-lib.sh"
PY="$(dirname "$0")/kit_findings.py"
FIND="$(dirname "$0")/kit-finding.sh"

ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
kit_active "$ROOT" || { kit_warn "kit not adopted here (no .claude/project-profile.md)"; exit 2; }

task=""; agent=""; cmd=""; prompt_file=""; max=3; model=""; agent_id=""; unattributed=0
reply_file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --task) task=${2:-}; shift; shift ;;
    --unattributed) unattributed=1; shift ;;
    --agent) agent=${2:-}; shift; shift ;;
    --agent-id) agent_id=${2:-}; shift; shift ;;
    --model) model=${2:-}; shift; shift ;;
    --cmd) cmd=${2:-}; shift; shift ;;
    --reply-file) reply_file=${2:-}; shift; shift ;;
    --prompt-file) prompt_file=${2:-}; shift; shift ;;
    --max-attempts) max=${2:-}; shift; shift ;;
    -h|--help) sed -n '4,6p' "$0"; exit 0 ;;
    *) kit_warn "unknown argument: $1"; exit 2 ;;
  esac
done
[ -n "$agent" ] || { kit_warn "missing --agent"; exit 2; }
# EXACTLY ONE DOOR. Both would be ambiguous about which reply is authoritative, and neither
# leaves nothing to record -- so both are usage errors, refused before anything is written.
if [ -n "$cmd" ] && [ -n "$reply_file" ]; then
  kit_warn "--cmd and --reply-file are alternatives; pass one"
  kit_warn "  --cmd runs a reviewer and retries; --reply-file records a reply you already hold"
  exit 2
fi
if [ -z "$cmd" ] && [ -z "$reply_file" ]; then
  kit_warn "missing --cmd (it reads a prompt on stdin, writes the reply to stdout)"
  kit_warn "  or --reply-file, if you already hold the reviewer's reply"
  exit 2
fi
case "$max" in ''|*[!0-9]*) kit_warn "--max-attempts must be a number"; exit 2 ;; esac
[ "$max" -ge 1 ] || { kit_warn "--max-attempts must be at least 1"; exit 2; }

ATTR=""
[ -n "$task" ] && ATTR="--task $task"
[ "$unattributed" = 1 ] && ATTR="--unattributed"
[ -n "$ATTR" ] || { kit_warn "missing --task (or --unattributed)"; exit 2; }

# THE REPLY-IN-HAND PATH. No prompt, no invocation, no retry -- validate, record, and on
# refusal leave the same `rejected` gap the loop leaves, because a review whose findings were
# refused is a hole in the measurement whichever door it came through.
#
# The recorder's own diagnostics go to stderr unchanged. `--correction` is deliberately NOT
# called: it restates the original request and requires `--original-file`, which does not exist
# here, and a correction with nothing to correct is how an empty review was once recorded as a
# measurement.
if [ -n "$reply_file" ]; then
  [ -f "$reply_file" ] || { kit_warn "no such --reply-file: $reply_file"; exit 2; }
  [ -s "$reply_file" ] || {
    kit_warn "--reply-file '$reply_file' is empty; refusing to record nothing"
    kit_warn "  an empty reply is not an empty review -- a reviewer that found nothing"
    kit_warn "  returns {\"findings\": []}, which records a gap meaning exactly that"
    exit 2
  }
  # shellcheck disable=SC2086
  if bash "$FIND" $ATTR --agent "$agent" --agent-id "$agent_id" --model "$model" \
       --json < "$reply_file"; then
    exit 0
  fi
  # THE GAP IS ALREADY WRITTEN, and a second one here is a defect this task has seen before.
  # `kit-finding.sh`'s emit() records a `rejected` gap itself when a batch is refused
  # (kit-finding.sh:128-134). Measured: the recorder alone moves the gap count by exactly one,
  # and this door wrote another on top -- TWO rows for one refused review. That is the
  # double-gap shape round 5 recorded as a minor, reintroduced one file over, which is the
  # "filed the class, never swept for it" failure docs/LESSONS.md S4 names. Caught by the
  # conformance step below before it shipped, because that step asserts the COUNT.
  #
  # One owner for the gap, as principle 1 of this task's approach requires. Deleting the
  # recorder's instead would replace a double count with silence, which is worse than the bug.
  kit_warn "the reply in '$reply_file' was refused; the recorder logged the gap"
  kit_warn "  NOT retried: a correction restates the request, and this door has none."
  kit_warn "  Re-ask the reviewer with the diagnostics above, then record its next reply."
  exit 1
fi

# The first prompt is the caller's. Subsequent ones are the validator's, verbatim.
#
# A MISSING prompt is a usage error, refused before the first attempt. This was written as
# `[ -n "$f" ] && prompt=$(cat "$f")`, which ignored both a failing `cat` and an omitted flag:
# the reviewer was handed an empty prompt, replied with nothing, and that recorded as
# `reason=empty` -- the value meaning "a review looked and found nothing" -- and the loop exited
# 0. A review that never happened, reported as a clean one, inside the mechanism built to stop
# exactly that. Found critical in round 5.
[ -n "$prompt_file" ] || {
  kit_warn "missing --prompt-file: there is nothing to ask the reviewer"
  kit_warn "  refusing before the first attempt rather than reviewing an empty prompt"
  exit 2
}
prompt=$(cat "$prompt_file") || {
  kit_warn "could not read --prompt-file '$prompt_file'"
  exit 2
}
[ -n "$prompt" ] || {
  kit_warn "--prompt-file '$prompt_file' is empty; refusing to review nothing"
  exit 2
}

WORKDIR=$(mktemp -d 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/kitrev.$$")
mkdir -p "$WORKDIR"
# shellcheck disable=SC2064
trap "rm -rf '$WORKDIR'" EXIT INT TERM

attempt=1
while :; do
  # The prompt goes in as a FILE, not down a pipe. Piped, a reviewer that does not read all of
  # stdin kills `printf` with SIGPIPE, and under `set -o pipefail` the pipeline reports failure
  # -- so a perfectly good review was discarded as a broken command and a false gap recorded.
  # Nothing obliges a caller's command to drain stdin, so nothing may depend on it.
  printf '%s' "$prompt" > "$WORKDIR/prompt"
  sh -c "$cmd" < "$WORKDIR/prompt" > "$WORKDIR/reply" 2> "$WORKDIR/err"
  rc=$?
  if [ "$rc" != 0 ]; then
    # The reviewer command itself failed. That is not a contract violation and retrying a
    # broken invocation is how a loop burns a budget on nothing.
    kit_warn "the reviewer command exited $rc on attempt $attempt; not retrying"
    sed 's/^/  /' "$WORKDIR/err" >&2
    break
  fi

  # Exit 3 means REFUSED-and-here-is-the-correction. Anything else non-zero is the validator
  # itself failing -- missing python3, an undecodable reply -- and must not be read as a
  # refusal: `correction` is empty in that case, so the loop would resend an EMPTY prompt for
  # every remaining attempt and burn the budget reviewing nothing.
  # --original-file is the CALLER'S request every time, not the previous attempt's prompt: the
  # retry must restate what was asked, and compounding corrections would bury it.
  correction=$(python3 "$PY" --correction --original-file "$prompt_file" \
                 < "$WORKDIR/reply"); crc=$?
  if [ "$crc" != 0 ] && [ "$crc" != 3 ]; then
    kit_warn "the validator failed with exit $crc, which is not a refusal; not retrying"
    break
  fi
  if [ "$crc" = 0 ]; then
    # Accepted. Record through the one door, which validates again on its own account.
    # shellcheck disable=SC2086
    if bash "$FIND" $ATTR --agent "$agent" --agent-id "$agent_id" --model "$model" \
         --json < "$WORKDIR/reply"; then
      [ "$attempt" -gt 1 ] &&
        printf 'kit: accepted on attempt %s of %s\n' "$attempt" "$max" >&2
      exit 0
    fi
    kit_warn "the recorder refused a reply the validator accepted -- not retrying"
    break
  fi

  if [ "$attempt" -ge "$max" ]; then
    kit_warn "$agent did not satisfy the findings contract in $max attempt(s)"
    kit_warn "  the last reply is not recorded; its findings exist only in that reply"
    break
  fi
  printf 'kit: attempt %s refused, sending the diagnostics back\n' "$attempt" >&2
  prompt=$correction
  attempt=$((attempt + 1))
done

# Every path out of the loop above is a failure, and a failed review must leave a row. Silence
# here is the open circuit this whole task exists to close: an empty finding table reads as
# "nothing escaped" when it means "nothing was recorded".
# shellcheck disable=SC2086
gap=$(python3 "$PY" --gap-event rejected $ATTR --agent "$agent" --agent-id "$agent_id") &&
  printf '%s\n' "$gap" >> "$ROOT/$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")/events.ndjson"
exit 1

#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-vindicate.sh --finding ID (--real | --false) [--note TEXT]        [aim at ONE row]
# kit-vindicate.sh --task ID --class CLASS (--real | --false) [--note TEXT]   [a whole class]
#
# Marks whether a finding was actually a defect. Without this the promotion ladder
# runs on raw occurrence counts, which include reviewer false positives — and an
# accelerator built from unvindicated findings launders noise into shared config
# that every future project then loads.
#
# TWO SCOPES, AND THEY ARE NOT INTERCHANGEABLE. `--class` was the only door for a long
# time, and it updates EVERY finding matching (task, class). Measured 2026-09-15: 604 of
# 635 findings here live in a (task, class) pair holding more than one row, so for 95% of
# the table the class door cannot say "this one was never a defect" without also saying
# it about its neighbours. That is why the criticals gate only honours a class refutation
# when the finding is the sole one of its class on its task -- and why, until `--finding`
# existed, the one verb that made the right claim about a false positive could not be
# aimed at the row that needed it.
#
# `--finding` names a row and is unambiguous by construction, so the gate honours it
# without that guard. The scope is recorded in the event and indexed, because once
# `vindicated` is written the two are otherwise indistinguishable.
#
# OPERATOR-RESERVED, like `kit-resolve.sh --fixed` and `--unassessable`, and for the reason
# .claude/CLAUDE.md gives for those: a session certifying its own output is the one
# signature that carries no information. If you are an agent reading this, propose the mark
# in your summary and stop. Nothing here enforces that -- it is a convention the operator
# enforces, stated where the next reader of this file will hit it.
set -uo pipefail
. "$(dirname "$0")/kit-lib.sh"
ROOT=$(kit_root) || exit 0
kit_active "$ROOT" || exit 0

task=""; class=""; verdict=""; finding=""; note=""
while [ $# -gt 0 ]; do
  case "$1" in
    --finding) finding=${2:-}; shift; shift ;;
    --task) task=${2:-}; shift; shift ;;
    --class) class=${2:-}; shift; shift ;;
    --real)  verdict=1; shift ;;
    --false) verdict=0; shift ;;
    --note)  note=${2:-}; shift; shift ;;
    -h|--help) sed -n '4,30p' "$0"; exit 0 ;;
    *) kit_warn "unknown argument: $1"; exit 2 ;;
  esac
done

# REFUSE THE MIXTURE RATHER THAN PICKING ONE. A command carrying both a row and a class
# has two different meanings and no way to tell which was intended; silently preferring
# either would write a mark the caller did not ask for.
if [ -n "$finding" ] && { [ -n "$task" ] || [ -n "$class" ]; }; then
  kit_warn "--finding names one row; --task/--class name a whole class. Use one or the other."
  exit 2
fi
if [ -n "$finding" ]; then
  [ -n "$verdict" ] || { kit_warn "usage: --finding ID (--real|--false) --note TEXT"; exit 2; }
  # A REASON IS REQUIRED ON A ROW MARK, and is not on a class mark. The asymmetry is
  # deliberate: this mark retires one named finding from the criticals gate on its own,
  # with no sole-of-its-class test standing behind it, and the kit's rule for every other
  # mark that clears a gate is that it must say why. `--unassessable --reason` is refused
  # without one for the same reason. The class mark is unchanged because changing it would
  # break callers to fix a different command's problem.
  [ -n "$note" ] || {
    kit_warn "--finding requires --note TEXT: a mark that retires a finding must say why"
    exit 2; }
else
  [ -n "$task" ] && [ -n "$class" ] && [ -n "$verdict" ] || {
    kit_warn "usage: --finding ID (--real|--false)   |   --task ID --class CLASS (--real|--false)"
    exit 2; }
fi

STATE_DIR=$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")
mkdir -p "$ROOT/$STATE_DIR"
# `note` was accepted and DISCARDED before today -- two shifts and nothing written. A
# reason the caller took the trouble to supply, dropped on the floor, is worse than one
# that was never asked for.
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
scope=class; [ -n "$finding" ] && scope=finding
printf '{"task":"%s","kind":"vindication","at":"%s","class":"%s","finding":"%s","scope":"%s","vindicated":%s,"note":"%s"}\n' \
  "$(esc "$task")" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(esc "$class")" \
  "$(esc "$finding")" "$scope" "$verdict" "$(esc "$note")" \
  >> "$ROOT/$STATE_DIR/events.ndjson"

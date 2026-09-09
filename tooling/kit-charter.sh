#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-charter.sh    print the facts docs/CHARTER.md section 4 is about, computed now
#
# DRIFT REMOVED BY CONSTRUCTION, NOT BY A CHECK. `docs/CHARTER.md` section 4 is titled "What
# exists today -- measured, not claimed". It was measured on 2026-08-24 and TYPED IN, and by
# 2026-09-09 six of its figures were wrong: 138 tasks against 169, 442 findings against 621, a
# criticals gate of "0 actionable" against 12, 8 agents against 9, 19 tooling scripts against 20,
# and a 58-step conformance suite against 67.
#
# Every one of those numbers was already computed by something that ships. `validate.py` prints
# the agent and script counts on every run. `tests/conformance.sh` derives its own step count FROM
# ITSELF, with the comment "A second copy is a copy that drifts, and this repository has already
# paid for that once." `kit-status.sh` regenerates the task and finding counts.
# `kit-preflight.sh --criticals` computes the gate. The kit measured all of it and the charter
# re-typed it.
#
# WHY THIS IS NOT A CI GATE. The obvious fix is a step that fails when a typed figure disagrees
# with a computed one. It would go red the moment anyone files a task -- a gate that a normal,
# correct action breaks, which is the shape `kit-preflight.sh:78` already refuses and which three
# rejected designs on 2026-09-09 walked into. So section 4 stops carrying numbers instead, and
# cites this command. A figure that is never typed cannot drift.
#
# WHAT IT DOES NOT COVER, said out loud. Section 4 also makes JUDGEMENTS -- "not yet written, and
# that is a point in an iterative process rather than a gap" -- and names eight tasks as designed
# but not built. The judgements are not checkable and this command does not reach them. The task
# ids ARE checkable and are resolved below, because a charter citing a task that no longer exists
# is the drift nobody would notice.
set -uo pipefail
. "$(dirname "$0")/kit-lib.sh"

ROOT=$(kit_root) || exit 0
kit_active "$ROOT" || exit 0
PROFILE=$(kit_profile "$ROOT")
STATE_DIR=$(kit_cfg "$PROFILE" paths.state ".project")
TASK_DIR="$ROOT/$(kit_cfg "$PROFILE" paths.tasks "$STATE_DIR/tasks")"
DB="$ROOT/$STATE_DIR/index.db"

row() { printf '  %-26s %s\n' "$1" "$2"; }
# A fact the command cannot compute prints `no reading` and is never omitted. A row that silently
# disappears is how a report stops meaning what its reader thinks it means -- the same argument
# kit-preflight.sh:112-118 makes about a gate's exclusions.
NR_='no reading'

printf 'Kit facts, computed %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '=================================================\n\n'

printf 'Distribution\n'
PJ="$ROOT/.claude-plugin/plugin.json"
if [ -f "$PJ" ]; then
  row 'plugin version' "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PJ" | head -1)"
else
  row 'plugin version' "$NR_"
fi
row 'agents'   "$(ls -1 "$ROOT/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')"
row 'skills'   "$(ls -1d "$ROOT/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')"
row 'tooling scripts' "$(ls -1 "$ROOT/tooling"/*.sh "$ROOT/tooling"/*.py 2>/dev/null | wc -l | tr -d ' ')"
# Derived from the suite the way the suite derives it from itself, for the reason its own comment
# gives: a second copy is a copy that drifts.
row 'conformance steps' "$(grep -c '^if step "' "$ROOT/tests/conformance.sh" 2>/dev/null || printf '%s' "$NR_")"
adr_all=$(ls -1 "$ROOT/docs/adr"/*.md 2>/dev/null | wc -l | tr -d ' ')
adr_rej=$(grep -l 'Status:\*\* \*\*REJECTED' "$ROOT/docs/adr"/*.md 2>/dev/null | wc -l | tr -d ' ')
row 'ADRs' "$adr_all ($adr_rej rejected and kept)"
printf '\n'

if [ -f "$DB" ] && sqlite3 "$DB" "SELECT COUNT(*) FROM task;" >/dev/null 2>&1; then
  Q() { sqlite3 -noheader "$DB" "$1" 2>/dev/null; }
  printf 'The record\n'
  row 'tasks' "$(Q 'SELECT COUNT(*) FROM task;')"
  Q "SELECT '  '||state||': '||COUNT(*) FROM task GROUP BY state ORDER BY COUNT(*) DESC;" |
    while IFS= read -r l; do printf '  %-26s %s\n' '' "$l"; done
  row 'findings' "$(Q 'SELECT COUNT(*) FROM finding;')"
  Q "SELECT '  '||severity||': '||COUNT(*) FROM finding GROUP BY severity ORDER BY COUNT(*) DESC;" |
    while IFS= read -r l; do printf '  %-26s %s\n' '' "$l"; done
  # THE GATE'S OWN PREDICATE, not a simpler one. `--unfixed` on kit-resolve.sh filters on
  # fixed_at alone and so counts superseded and unassessable findings too; it over-reported this
  # number by 41 on 2026-09-09 and has its own filed defect. This is what kit-preflight.sh asks.
  row 'criticals gate' "$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical'
        AND fixed_at IS NULL AND unassessable_at IS NULL AND superseded_at IS NULL;")"
  row '  of which fixed' "$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND fixed_at IS NOT NULL;")"
  row '  unassessable' "$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND unassessable_at IS NOT NULL;")"
  row '  superseded' "$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND superseded_at IS NOT NULL;")"
  printf '\n'
  printf 'Instrumented, and whether there is a reading\n'
  sp=$(Q 'SELECT COUNT(*) FROM spend;')
  spt=$(Q 'SELECT COUNT(DISTINCT task_id) FROM spend;')
  row 'spend rows' "${sp:-0} across ${spt:-0} task(s)"
  sub=$(Q "SELECT COUNT(*) FROM spend WHERE scope='subagent';")
  row '  of which subagent' "${sub:-0}"
  goals=$(Q 'SELECT COUNT(*) FROM goal;')
  row 'goals' "${goals:-0}"
  l0=$(Q 'SELECT COUNT(*) FROM plan_item WHERE layer=0;')
  pt=$(Q 'SELECT COUNT(*) FROM plan_item;')
  row 'plan layer 0' "${l0:-0} of ${pt:-0} planned"
  packs=$(ls -1 "$ROOT/$STATE_DIR/packs"/*/*.md 2>/dev/null | wc -l | tr -d ' ')
  row 'cluster packs on disk' "$packs"
else
  printf 'The record\n'
  row 'index' "$NR_ -- run kit-index.sh"
  printf '\n'
fi
printf '\n'

printf 'Trials and experiments\n'
row 'trials'      "$(ls -1 "$ROOT/docs/TRIALS"/*.md 2>/dev/null | wc -l | tr -d ' ')"
row 'experiments' "$(ls -1d "$ROOT/docs/EXPERIMENTS"/*/ 2>/dev/null | wc -l | tr -d ' ')"
printf '\n'

# THE HALF OF SECTION 4 THAT IS NOT A COUNT. It names tasks as designed-but-not-built. A task id
# that no longer resolves is drift a reader cannot see, so every id the charter cites is looked up
# and its state printed. All eight resolved on 2026-09-09; this is the check that says so next time.
printf 'Task ids cited in CHARTER.md\n'
C="$ROOT/docs/CHARTER.md"
if [ -f "$C" ] && [ -d "$TASK_DIR" ]; then
  grep -o 'T-2026[0-9]\{4\}-[a-z0-9-]*' "$C" 2>/dev/null | sort -u | while IFS= read -r id; do
    [ -n "$id" ] || continue
    if [ -f "$TASK_DIR/$id.md" ]; then
      st=''
      [ -f "$DB" ] && st=$(sqlite3 -noheader "$DB" "SELECT state FROM task WHERE id='$id';" 2>/dev/null)
      row "$(printf '%.40s' "$id")" "${st:-present}"
    else
      row "$(printf '%.40s' "$id")" 'UNRESOLVED -- no such task file'
    fi
  done
else
  row 'charter' "$NR_"
fi
exit 0

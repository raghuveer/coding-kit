#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-criteria.sh [--closed-with-open] [--all]   report acceptance criteria, per task
#
# THE SMALLEST THING THAT WAS NEVER TRIED. Four mechanisms were designed on 2026-09-09 for the
# operator's ruling that an implementation is correct only when the design is implemented
# contextually -- an obligation ledger, its revision, ADR 0010's state gate, and a criterion
# disposition vocabulary. Seven blind approach reviews rejected all four. In every case the
# MEASUREMENT survived re-derivation and the MECHANISM did not, and the last review's closing
# recommendation is this file: report the numbers with no new glyph, no marker grammar and no
# validator, and let what the operator does about them say what vocabulary is actually wanted.
#
# So this REFUSES NOTHING and gates NOTHING. It prints. Exit 0 whether the news is good or bad,
# for the reason kit-preflight.sh:78 already records about its own boxes: a standing fact the
# report must carry is not a stop, and a gate nobody can satisfy is worse than no gate.
#
# WHY NOT A SECTION IN kit-status.sh. `STATUS.generated.md` is gitignored (`.gitignore:4`,
# confirmed with `git check-ignore -v`), so a report written there lands in no diff, no pull
# request and no CI log. The one fact this is meant to put in front of a human would go where a
# human never looks. It prints to stdout instead, and adding it to the generated file later is a
# decision about plumbing rather than about whether the number exists.
#
# THE SECTION RULE IS THE STRICT ONE AND THE COST IS NAMED. A task's criteria run from
# `## Acceptance criteria` to the NEXT HEADING OF ANY LEVEL. The looser rule -- stop only at a
# level-1/2 heading, so a `### Added 2026-08-19` block stays inside -- yields different numbers
# from the same files: 675 unticked against 664 across open tasks, measured both ways on
# 2026-09-09. Two published designs quoted figures from the rule they had not chosen, so the rule
# is stated here in the code that implements it. **Boxes outside the section are COUNTED AND
# PRINTED as `out-of-section`, not silently dropped**, because a count that quietly covers less
# than its heading claims is the defect this repository keeps filing against itself. Measured
# 2026-09-09: 852 boxes inside the section, 30 outside, 882 in the files -- and the report prints
# that reconciliation so a reader can check the arithmetic rather than trust it. Of the 30, 19 sit
# under sub-headings INSIDE a criteria block in 3 files and would be counted by the looser rule;
# the rest are elsewhere in the file entirely.
#
# STATE COMES FROM THE INDEX, AND THE DISAGREEMENT IS PRINTED. `kit-index.sh:1258-1265` makes the
# last transition win, so a task file's own `state:` is not authoritative. Measured 2026-09-09:
# **30 of 169 files disagree with the index about their own state, and 4 carry no `state:` key at
# all.** A reader who opens a file this report calls `completed` may find `state: open` in it. That
# is printed rather than reconciled, because reconciling it is a different task
# (`T-20260822-legacy-state-spellings-in-task-files-sho`) and hiding it would make this report the
# second artefact carrying one fact with nothing comparing them.
set -uo pipefail
. "$(dirname "$0")/kit-lib.sh"

MODE=summary
while [ $# -gt 0 ]; do
  case "$1" in
    --closed-with-open) MODE=closed; shift ;;
    --all)              MODE=all; shift ;;
    -h|--help)          sed -n '4,4p' "$0"; exit 0 ;;
    *) kit_warn "unknown argument: $1"; exit 2 ;;
  esac
done

ROOT=$(kit_root) || exit 0
kit_active "$ROOT" || exit 0
PROFILE=$(kit_profile "$ROOT")
STATE_DIR=$(kit_cfg "$PROFILE" paths.state ".project")
TASK_DIR="$ROOT/$(kit_cfg "$PROFILE" paths.tasks "$STATE_DIR/tasks")"
DB="$ROOT/$STATE_DIR/index.db"

[ -d "$TASK_DIR" ] || {
  kit_warn "no task directory at ${TASK_DIR#$ROOT/} -- nothing to report"; exit 0; }

# The index supplies state. If it is missing the report still runs and says so, rather than
# refusing: the criteria counts do not depend on it and are worth having on their own.
STATES=""
if [ -f "$DB" ] && sqlite3 "$DB" "SELECT COUNT(*) FROM task;" >/dev/null 2>&1; then
  STATES=$(sqlite3 -noheader -separator '	' "$DB" "SELECT id, state FROM task;" 2>/dev/null)
else
  kit_warn "index at ${DB#$ROOT/} is missing or unreadable -- state is read from each file"
  kit_warn "  instead, which kit-index.sh:1258-1265 says is not authoritative. Run kit-index.sh."
fi

# ONE awk over every file. Not one process per file: a bare spawn costs ~1015 ms on this machine
# (docs/TRIAL-PROTOCOL.md:255, benchmark printed beside it), and 169 of them would make this
# unusable where it is most wanted.
#
# A box is `- [x]` at column 0. Measured across all 882 boxes in all 169 task files on
# 2026-09-09: the bullet is `-` in 882 of 882 and the indentation is 0 in 882 of 882. Boxes are
# matched at column 0 deliberately, so an indented example inside a criterion's prose is not
# counted as a criterion. CR is stripped: 6 task files are CRLF in this working tree, including
# both files carrying the only two `[~]` glyphs in the repository.
printf '%s\n' "$STATES" | awk -v taskdir="$TASK_DIR" -v mode="$MODE" '
  BEGIN { FS = "\t" }
  # first stream: id -> state from the index
  NF == 2 { st[$1] = $2; next }
  END {
    cmd = "ls -1 \"" taskdir "\" 2>/dev/null"
    while ((cmd | getline f) > 0) {
      if (f !~ /\.md$/) continue
      id = f; sub(/\.md$/, "", id)
      ids[++n] = id
      path = taskdir "/" f
      insec = 0; met = 0; open = 0; other = 0; out = 0; seen = 0
      while ((getline line < path) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^## +Acceptance criteria[ ]*$/) { insec = 1; seen = 1; continue }
        isbox = (line ~ /^- \[.\]/)
        if (isbox) tall++
        if (line ~ /^#+ /) { if (insec) insec = 0; continue }
        if (!isbox) continue
        if (!insec) { out++; continue }
        g = substr(line, 4, 1)
        if (g == "x" || g == "X") met++
        else if (g == " ") open++
        else other++
      }
      close(path)
      hassec[id] = seen; M[id] = met; O[id] = open; X[id] = other; OUT[id] = out
      tm += met; to += open; tx += other; tout += out
      if (!seen) nosec++
    }
    close(cmd)

    for (i = 1; i <= n; i++) {
      id = ids[i]; s = (id in st) ? st[id] : "?"
      if (s == "completed" && O[id] > 0) { cwo[++ncwo] = id }
    }

    if (mode == "all") {
      printf "%-52s %-12s %5s %5s %5s\n", "TASK", "STATE", "met", "open", "other"
      for (i = 1; i <= n; i++) {
        id = ids[i]; s = (id in st) ? st[id] : "?"
        if (!hassec[id]) { printf "%-52s %-12s %s\n", substr(id,1,52), s, "no criteria recorded"; continue }
        printf "%-52s %-12s %5d %5d %5d\n", substr(id,1,52), s, M[id], O[id], X[id]
      }
      print ""
    }

    if (mode == "closed" || mode == "summary") {
      print "Completed tasks with criteria still open"
      print "----------------------------------------"
      if (ncwo == 0) print "  none"
      for (i = 1; i <= ncwo; i++) {
        id = cwo[i]
        printf "  %-52s  %d open of %d\n", substr(id,1,52), O[id], M[id] + O[id] + X[id]
      }
      print ""
    }

    print "Totals"
    print "------"
    printf "  task files            %d\n", n
    printf "  with a criteria section %d   (no criteria recorded: %d)\n", n - nosec, nosec
    printf "  criteria met          %d\n", tm
    printf "  criteria open         %d\n", to
    printf "  criteria other glyph  %d\n", tx
    printf "  out-of-section boxes  %d   (outside the section; not counted above)\n", tout
    printf "  completed with open   %d\n", ncwo
    # THE FAIL-OPEN GUARD. A report whose rows look complete while criteria quietly go missing is
    # this design'"'"'s own failure mode, and asserting the ROW count against the TASK count does not
    # catch it -- a task that loses four criteria still produces a row. So the boxes are
    # reconciled against every box in the files: if these disagree, the parser dropped something.
    printf "  ---- reconciliation ----\n"
    printf "  accounted (met+open+other+out) %d\n", tm + to + tx + tout
    printf "  boxes found in files           %d", tall
    if (tm + to + tx + tout != tall) printf "   MISMATCH -- the parser dropped %d", tall - (tm + to + tx + tout)
    printf "\n" 
  }
'

# The state disagreement, printed rather than reconciled. See the header.
if [ -n "$STATES" ]; then
  dis=0; nost=0
  for f in "$TASK_DIR"/*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    fs=$(sed -n 's/^state:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$f" | head -1 | tr -d '\r')
    if [ -z "$fs" ]; then nost=$((nost + 1)); continue; fi
    case "$fs" in
      open) fs=created ;; done) fs=completed ;;
      progress|started|unblocked) fs=in-progress ;; blocked) fs=on-hold ;;
    esac
    is=$(printf '%s\n' "$STATES" | awk -F'\t' -v i="$id" '$1==i {print $2}')
    [ -n "$is" ] && [ "$is" != "$fs" ] && dis=$((dis + 1))
  done
  printf '  file/index state differs %d   (index wins; see this script'"'"'s header)\n' "$dis"
  printf '  files with no state key  %d\n' "$nost"
fi
exit 0

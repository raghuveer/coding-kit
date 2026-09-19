#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# Cross-platform conformance run.
#
#   KIT=/path/to/kit WORK=/path/to/empty/scratch bash tests/conformance.sh
#   ... bash tests/conformance.sh --only 'escape'      one step, in seconds
#   ... bash tests/conformance.sh --list               the step names to match on
#
# Builds a deterministic fixture -- fixed author AND committer dates, so every commit SHA
# is identical on every machine -- then exercises the pipeline end to end and prints a
# fingerprint of the derived index. Two platforms running this must produce the same
# fingerprint; when they did not, it surfaced two real defects at once (see 0.5.2).
#
# The fixture is deliberately awkward: a squash-shaped commit whose trailers git will not
# parse, module pairs that co-change, and a file in every commit that must be dropped as a
# hub. A fixture that only exercises the happy path proves the happy path.
set -uo pipefail

# --- step selection --------------------------------------------------------
# `--only PATTERN` (repeatable, case-insensitive ERE, OR-ed) runs just the steps
# whose names match. It exists to make ONE mutation proof cheap: proving a single
# control can fail is the discipline this suite is for, and paying a whole run for
# it got that discipline batched into overnight runs instead of used.
#
# The full run is the only thing that proves conformance, and it is what CI runs.
# A filtered run is therefore built to be impossible to mistake for a whole one:
# the tally says PARTIAL and names how many steps did not run, the fingerprint is
# labelled as covering the chain rather than the suite, and a pattern matching no
# step exits 2 instead of reporting a clean zero-step pass. "Nothing ran" reading
# as green is the exact defect shape this repository keeps shipping -- see
# docs/LESSONS.md S1.
#
# Steps are not all independent. Most build and destroy their own fixture, but two
# groups share one, and those carry a chain name as `step`'s second argument.
# Selecting a chain member runs that chain from its start through the selected
# step, and says so. No step ever runs without the fixture it reads.
# Absolute, because a step below re-invokes this file to check the filter's own
# guarantees, and by then the fixture steps may have changed directory.
SELF=${BASH_SOURCE[0]:-$0}
SELF=$(cd "$(dirname "$SELF")" && pwd)/$(basename "$SELF")
ONLY=''; LIST=0
add_only() { if [ -z "$ONLY" ]; then ONLY=$1; else ONLY="$ONLY|$1"; fi; }
while [ $# -gt 0 ]; do
  case $1 in
    --only)   [ $# -ge 2 ] || { printf 'conformance: --only needs a pattern\n' >&2; exit 2; }
              add_only "$2"; shift 2 ;;
    --only=*) add_only "${1#--only=}"; shift ;;
    --list)   LIST=1; shift ;;
    -h|--help)
      printf 'usage: KIT=<kit> WORK=<scratch> bash %s [--only PATTERN]... [--list]\n' "$SELF"
      exit 0 ;;
    *) printf 'conformance: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

# The step list is read back out of this file rather than kept in a table beside it.
# A second copy is a copy that drifts, and this repository has already paid for that
# once with the finding vocabulary.
STEP_TABLE=$(
  sed -n 's/^if step "\([^"]*\)"\(.*\); then$/\1|\2/p' "$SELF" |
  { n=0; while IFS='|' read -r _nm _ch; do
      n=$((n+1))
      printf '%s|%s|%s\n' "$n" "$_nm" "$(printf '%s' "$_ch" | tr -d '[:space:]')"
    done; }
)
STEP_COUNT=$(printf '%s\n' "$STEP_TABLE" | grep -c '^[0-9]')
# The parser is checked against a looser count of the same lines. A step written in a
# shape the strict pattern misses would otherwise vanish from the table silently: it
# would still RUN on a full run, but `--only` could never name it and the "N of M"
# figure above would be wrong. Counting zero is the same defect at full size.
STEP_DECLARED=$(grep -c '^if step ' "$SELF")
if [ "${STEP_COUNT:-0}" -eq 0 ] || [ "$STEP_COUNT" != "$STEP_DECLARED" ]; then
  printf 'conformance: internal error -- the step self-parser read %s of %s step lines in %s.\n' \
    "${STEP_COUNT:-0}" "$STEP_DECLARED" "$SELF" >&2
  printf '  Steps must be written exactly `if step "name" [chain]; then` ... `fi`.\n' >&2
  exit 2
fi
# Selection is by name and de-duplicated by name, so two steps sharing one would be
# announced as a single step and could never be told apart by `--only`. They are unique
# today; this is what keeps that true rather than assumed.
STEP_UNIQUE=$(printf '%s\n' "$STEP_TABLE" | cut -d'|' -f2 | sort -u | grep -c '^.')
if [ "$STEP_UNIQUE" != "$STEP_COUNT" ]; then
  printf 'conformance: internal error -- %s step names for %s steps; these are duplicated:\n' \
    "$STEP_UNIQUE" "$STEP_COUNT" >&2
  printf '%s\n' "$STEP_TABLE" | cut -d'|' -f2 | sort | uniq -d | sed 's/^/  /' >&2
  exit 2
fi

if [ "$LIST" = 1 ]; then
  printf '%s\n' "$STEP_TABLE" | while IFS='|' read -r _i _nm _ch; do
    if [ -n "$_ch" ]; then printf '%3s  %s  [chain: %s]\n' "$_i" "$_nm" "$_ch"
    else                   printf '%3s  %s\n' "$_i" "$_nm"; fi
  done
  exit 0
fi

KIT=${KIT:?set KIT to the kit checkout}
WORK=${WORK:?set WORK to an empty scratch dir}

SELECTED=''; PULLED=0

if [ -n "$ONLY" ]; then
  _hit=$(printf '%s\n' "$STEP_TABLE" | while IFS='|' read -r _i _nm _ch; do
           printf '%s' "$_nm" | grep -Eiq -- "$ONLY" && printf '%s|%s|%s\n' "$_i" "$_nm" "$_ch"
         done)
  if [ -z "$_hit" ]; then
    printf 'conformance: --only %s matched no step, so nothing would run.\n' "$ONLY" >&2
    printf '  A run of zero steps is not a pass. `--list` shows the names.\n' >&2
    exit 2
  fi
  SELECTED=$(printf '%s\n' "$_hit" | cut -d'|' -f2)
  # Pull in each selected step's chain, from the chain's start up to that step.
  for _c in $(printf '%s\n' "$_hit" | cut -d'|' -f3 | grep -v '^$' | sort -u); do
    _max=$(printf '%s\n' "$_hit" |
           while IFS='|' read -r _i _nm _ch; do [ "$_ch" = "$_c" ] && printf '%s\n' "$_i"; done |
           sort -n | tail -1)
    _pre=$(printf '%s\n' "$STEP_TABLE" |
           while IFS='|' read -r _i _nm _ch; do
             [ "$_ch" = "$_c" ] && [ "$_i" -le "$_max" ] && printf '%s\n' "$_nm"
           done)
    SELECTED=$(printf '%s\n%s' "$SELECTED" "$_pre")
  done
  SELECTED=$(printf '%s\n' "$SELECTED" | grep -v '^$' | sort -u)
  _nsel=$(printf '%s\n' "$SELECTED" | grep -c '^.')
  PULLED=$((_nsel - $(printf '%s\n' "$_hit" | grep -c '^.')))
  printf '=== FILTERED RUN --only %s\n' "$ONLY"
  printf '    %s of %s steps will run' "$_nsel" "$STEP_COUNT"
  [ "$PULLED" -gt 0 ] && printf ', %s of them pulled in to build a shared fixture' "$PULLED"
  printf '.\n'
fi

ok=0; bad=0; skipped=0; ran=0; filtered=0
step_selected() { [ -z "$ONLY" ] || printf '%s\n' "$SELECTED" | grep -qxF -- "$1"; }
step() {
  if step_selected "$1"; then ran=$((ran+1)); printf '\n=== %s\n' "$1"; return 0; fi
  filtered=$((filtered+1)); return 1
}
check() { if [ "$1" = 0 ]; then ok=$((ok+1)); printf '  PASS  %s\n' "$2"
          else bad=$((bad+1)); printf '  FAIL  %s\n' "$2"; fi; }
# A control that could not run is not a control that passed. It does not fail the suite --
# an unrunnable check is not a defect -- but it is counted and named in the tally, because
# the tally and the exit code are what CI reads and "N passed, 0 failed" over a check that
# never executed is the same green-that-means-nothing this suite exists to refuse.
skip()  { skipped=$((skipped+1)); printf '  SKIP  %s — %s\n' "$2" "$1"; }

if step "environment"; then
uname -srm 2>/dev/null || echo "(no uname)"
bash --version | head -1; git --version; sqlite3 --version | awk '{print "sqlite3 "$1}'
(awk --version 2>/dev/null || awk -W version 2>&1) | head -1
# The kit shells out to python3 from kit-finding.sh, kit-resolve.sh, kit-review-record.sh,
# kit-claim.sh and kit-plan.sh. It was not reported here, so a platform without it looked
# like fourteen unrelated finding failures rather than one missing interpreter. Report every
# interpreter the kit depends on, not only the ones that were interesting the day this was
# written. Never fails the run -- it is the environment banner, not a gate.
python3 --version 2>&1 | head -1 || echo "python3: ABSENT"
command -v python3 >/dev/null 2>&1 || echo "python3: NOT ON PATH"
python  --version 2>&1 | head -1 || echo "python: ABSENT"

# DIAGNOSTIC, and temporary. conformance (windows-latest) reports 14 failures whose assertions
# say only "got 2, wanted 0" and "recorded 0 critical(s)" -- every step redirects stderr to
# /dev/null, so the CAUSE is never printed anywhere. Two hypotheses were formed from the tally
# alone and BOTH were wrong: a second gawk-version defect like globre (swept: no octal escapes
# and no non-standard regex escapes anywhere), and a missing python3 (this banner now shows it
# present). Guessing from a tally is what produced both. This runs the first failing path once
# and prints what it actually says.
( pd="${WORK:-/tmp}.pydiag"; rm -rf "$pd"; mkdir -p "$pd/.claude" "$pd/.project/tasks"
  cd "$pd" || exit 0
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  printf -- '---
id: T-d
title: d
tier: T2
---
b
' > .project/tasks/T-d.md
  git add -A >/dev/null 2>&1 && git commit -q --no-verify -m seed >/dev/null 2>&1
  echo "--- kit-finding.sh, stderr shown ---"
  bash "$KIT/tooling/kit-finding.sh" --task T-d --agent implementation-reviewer     --class race --severity major --lang bash --summary "diagnostic probe, not a real finding" 2>&1 |
    sed 's/^/    /' | head -20
  echo "    exit=$? events=$(grep -c '"kind":"finding"' .project/events.ndjson 2>/dev/null)"
  echo "--- which bash does each layer resolve? ---"
  echo "    shell sees:  $(command -v bash)"
  python3 -c "import shutil,sys; print('    python sees:', shutil.which('bash'))" 2>&1 | head -2
  python3 -c "import subprocess,sys; r=subprocess.run(['bash','-c','echo ok'],capture_output=True); print('    bash -c echo ok -> rc=%s out=%r err=%r' % (r.returncode, r.stdout[:80], r.stderr[:80]))" 2>&1 | head -3
  echo "--- kit_findings.py --contract, stderr shown ---"
  python3 "$KIT/tooling/kit_findings.py" --contract 2>&1 | sed 's/^/    /' | head -5
  rm -rf "$pd" ) 2>&1 || true
fi

if step "scripts are executable in the git index"; then
# Not on disk: git on Windows cannot read the msys exec bit, so a chmod there never reaches
# the index and the file lands non-executable on Linux. The index is the shared truth.
#
# THE SELECTOR MUST MATCH CI'S, and it did not. This loop filtered to `.sh$|commit-msg`, while
# the workflow's "Exec bits survive a fresh clone" step checks EVERYTHING under tooling/ except
# schema.sql. So `kit_findings.py` landed at 100644 on 2026-08-10 and CI went red for EIGHT
# consecutive commits while this step stayed green -- a local gate weaker than the remote one
# is a local gate that certifies nothing.
#
# Selected the same way CI selects: anything tracked under tooling/ or templates/*.sh, minus a
# named exception list. A file that genuinely should not be executable is added HERE, visibly,
# rather than by narrowing the pattern until it stops complaining.
nx=0
for f in $(git -C "$KIT" ls-files tooling 'templates/*.sh'); do
  case "$f" in
    tooling/schema.sql) continue ;;   # data, never executed
  esac
  m=$(git -C "$KIT" ls-files -s "$f" | awk '{print $1}')
  [ "$m" = 100755 ] || { echo "  $m $f"; nx=1; }
done
check $nx "every script is 100755, by CI's own selector"
fi

# Name the word the match dies on. "class list differs" alone sends the reader to compare two
# lists by eye, and the difference that actually occurred was an invisible byte -- so the one
# thing the message must not do is leave the reader looking at two lists that appear equal.
#
# DEFINED AT FILE SCOPE, not inside the step that first needed it. It used to live inside the
# finding-vocabulary block, which works for a full run and breaks under `--only`: a filtered run
# of any OTHER step that calls it got `first_divergence: command not found` and then printed
# `breaks at ""`, sending the reader to look at an empty string. The check still failed, so the
# hole was invisible until a second step used the helper -- and it could only ever surface on the
# drift path, i.e. exactly when the diagnostic matters. A guard's error message needs the same
# can-it-fail scrutiny as the guard.
first_divergence() {  # <expected list> <flattened agent text>
  _pre=""
  for _w in $1; do
    if [ -n "$_pre" ]; then _try="$_pre $_w"; else _try="$_w"; fi
    case "$2" in *"$_try"*) _pre="$_try" ;; *) printf '%s' "$_w"; return ;; esac
  done
}

if step "--help prints every flag the usage block documents"; then
# A HELP TEXT BOUND TO LINE NUMBERS IS WRONG SILENTLY. `kit-finding.sh -h` was
# `sed -n '4,8p' "$0"` -- a hardcoded range that had already outgrown itself: `--vocab` and
# `--contract` are real flags, documented in the same block, and neither had ever been printed
# by --help. Nothing failed. The header then grew on 2026-09-14 and clipped again.
#
# Asserted against the FILE rather than against a list written here, so this cannot drift the
# way the thing it is testing drifted. Every `# kit-finding.sh ...` usage line in the header
# must appear in the --help output; a range that clips any of them goes red.
h=$(bash "$KIT/tooling/kit-finding.sh" --help 2>&1)
miss=""
while IFS= read -r line; do
  case "$h" in *"$line"*) ;; *) miss="$miss
    $line" ;; esac
done <<EOF
$(awk '/^# kit-finding\.sh /{print} /^#$/{if(seen)exit} /^# kit-finding\.sh /{seen=1}' "$KIT/tooling/kit-finding.sh")
EOF
[ -z "$miss" ] || echo "  usage lines the --help output does not contain:$miss"
# And the two flags that were invisible for the whole life of the old range, named explicitly:
# a generic check that happened to pass while they were missing is what let this sit.
case "$h" in *"--vocab"*) ;; *) echo "  --help does not mention --vocab"; miss=x ;; esac
case "$h" in *"--contract"*) ;; *) echo "  --help does not mention --contract"; miss=x ;; esac
[ -z "$miss" ]
check $? "no usage line is clipped, --vocab and --contract included"
fi


if step "finding vocabulary has not drifted"; then
# The reviewers have no Bash, so they cannot run `kit-finding.sh --vocab` and the lists are
# inlined in their instructions. That is the only form they can use, and it is exactly the
# duplication the script's own header warns about -- the vocabulary already diverged across
# four locations once, and the agents emitted classes the recorder rejected. Inlining is
# safe only while something checks it, so this checks it.
V=$(bash "$KIT/tooling/kit-finding.sh" --vocab)
VC=$(printf '%s' "$V" | sed -n 's/^class:[[:space:]]*//p')
VS=$(printf '%s' "$V" | sed -n 's/^severity:[[:space:]]*//p')
drift=0
for a in "$KIT"/agents/*.md; do
  grep -q 'kit-finding.sh' "$a" || continue
  # CR is deleted BEFORE the newlines become spaces. Without that, a list wrapped across a
  # line flattens to `...style<CR> unclassified` on a CRLF checkout and matches nothing --
  # which reported all three reviewers as drifted while every one of them was correct. A
  # guard that is red for a reason unrelated to what it guards stops being read.
  flat=$(tr -d '\r' < "$a" | tr '\n' ' ' | tr -s ' ')
  case "$flat" in *"$VC"*) ;; *)
    echo "  class list differs: $(basename "$a") — breaks at \"$(first_divergence "$VC" "$flat")\""
    echo "    kit-finding.sh --vocab: $VC"; drift=1 ;;
  esac
  case "$flat" in *"$VS"*) ;; *)
    echo "  severity list differs: $(basename "$a") — breaks at \"$(first_divergence "$VS" "$flat")\""
    echo "    kit-finding.sh --vocab: $VS"; drift=1 ;;
  esac
done
check $drift "every agent's inlined vocabulary matches kit-finding.sh --vocab"
fi

if step "claim vocabulary has not drifted"; then
# The same guard as the finding vocabulary above, for the census verdicts, and for the same
# reason: `claim-auditor` has tools Read/Grep/Glob and no Bash, so it cannot run
# `kit-claim.sh --vocab` and the lists are inlined in its instructions. Inlining is safe only
# while something checks it. The finding vocabulary drifted across four locations once and the
# agents emitted values the recorder rejected outright; nothing about that failure was specific
# to findings.
V=$(bash "$KIT/tooling/kit-claim.sh" --vocab)
VV=$(printf '%s' "$V" | sed -n 's/^verdict:[[:space:]]*//p')
VL=$(printf '%s' "$V" | sed -n 's/^location:[[:space:]]*//p')
drift=0
seen=0
for a in "$KIT"/agents/*.md; do
  grep -q 'kit-claim.sh' "$a" || continue
  seen=$((seen + 1))
  # CR deleted BEFORE newlines become spaces -- on a CRLF checkout a list wrapped across a line
  # otherwise flattens to `...UNDERSTATED<CR> UNVERIFIABLE` and matches nothing, which once
  # reported all three reviewers as drifted while every one was correct.
  flat=$(tr -d '\r' < "$a" | tr '\n' ' ' | tr -s ' ')
  case "$flat" in *"$VV"*) ;; *)
    echo "  verdict list differs: $(basename "$a") — breaks at \"$(first_divergence "$VV" "$flat")\""
    echo "    kit-claim.sh --vocab: $VV"; drift=1 ;;
  esac
  case "$flat" in *"$VL"*) ;; *)
    echo "  location list differs: $(basename "$a") — breaks at \"$(first_divergence "$VL" "$flat")\""
    echo "    kit-claim.sh --vocab: $VL"; drift=1 ;;
  esac
done
# A LOOP THAT MATCHES NOTHING MUST NOT PASS. The finding-vocabulary step above has this hole:
# rename the agent, drop the tool mention, or move the vocabulary out of the file, and its
# `continue` skips every agent, `drift` stays 0, and the step reports green having compared
# nothing. That is precisely a control that cannot fail. Assert the denominator instead.
if [ "$seen" -eq 0 ]; then
  echo "  no agent mentions kit-claim.sh — the vocabulary has no inlined copy to check"
  echo "  (this is a FAILURE, not a pass: the guard compared nothing)"
  drift=1
fi
check $drift "the claim vocabulary is inlined in $seen agent(s) and matches kit-claim.sh --vocab"
fi

if step "no agent is told to run a tool it does not have"; then
# implementation-reviewer was told to run kit-finding.sh --vocab with tools: Read, Grep,
# Glob. It guessed the classes instead, and 3 of its 4 would have been rejected.
ungranted=0
for a in "$KIT"/agents/*.md; do
  # `tr -d '\r'` here and in every other reader of a checked-out file below. .gitattributes
  # pins *.md to LF, and a test that only passes while it does is a test of the reader's git
  # configuration. This one survived a CRLF checkout by luck -- the tool name it looks for is
  # never last on the line -- and the vocabulary check three steps down did not.
  tools=$(tr -d '\r' < "$a" | sed -n 's/^tools:[[:space:]]*//p' | head -1)
  case "$tools" in *Bash*) continue ;; esac
  if grep -qE 'Run `kit-[a-z-]+\.sh' "$a"; then
    echo "  $(basename "$a") has no Bash but is told to run a script"; ungranted=1
  fi
done
check $ungranted "no Bash-less agent is instructed to execute a script"

# The same shape for Write, and it is here because the Bash-only version above missed a live
# defect for months. `researcher.md` is granted Read, Grep, Glob, WebFetch, WebSearch and its
# Output section told it to WRITE a document to a directory. A design was built on the
# assumption that researcher could produce its own artefact, an approach review killed that
# design on exactly this point, and this step -- which exists to catch an agent told to use a
# tool it does not have -- said nothing, because it only ever looked for Bash.
#
# The matcher has to be narrower than "mentions write". Three lines in the no-Write agents
# talk about writes without instructing one: approach-reviewer and security-reviewer discuss
# check-then-act races ("separated from its write by an await"), and researcher says "Do not
# write the decision record". So a line must name write/create/save AND a file-ish object
# (a directory, a path, a .md) AND not be a prohibition. A prohibition that trips this check
# would train the next author to delete the prohibition, which is the wrong repair.
#
# KNOWN LIMIT, found by this check firing on its own fix: it matches TEXT, so prose that
# quotes the forbidden shape trips it. The sentence in researcher.md explaining what the old
# instruction said had to be reworded to stop describing the defect in the defect's own words.
# That is a real cost and it is stated rather than hidden, because the next author will hit it
# and the wrong repair is to weaken the matcher. `T-20260809-lint-the-kit-for-untrusted-text-interpol`
# is the same class one level up.
ungrantedw=0
for a in "$KIT"/agents/*.md; do
  tools=$(tr -d '\r' < "$a" | sed -n 's/^tools:[[:space:]]*//p' | head -1)
  case "$tools" in *Write*|*Edit*) continue ;; esac
  hit=$(tr -d '\r' < "$a" |
        grep -inE '(write|writes|create|save)[^.]*(director|\.md|file path|to a file)' |
        grep -viE 'do not|does not|never |rather than|instead of|without ' |
        grep -viE '(the )?(caller|orchestrator|operator|human)[^.]*(write|save|create)' | head -1)
  if [ -n "$hit" ]; then
    echo "  $(basename "$a") has no Write but is told to produce a file: ${hit%%:*}"
    ungrantedw=1
  fi
done
check $ungrantedw "no Write-less agent is instructed to produce a file"
fi

if step "a script broken by an apostrophe names the apostrophe"; then
# Every awk program here is a multi-line single-quoted shell string, so an apostrophe typed
# inside one -- almost always an English possessive in a comment -- closes it and everything
# after is reinterpreted as shell. It happened twice on 2026-08-08 in the same file.
#
# `bash -n` DETECTS it and is already commands.lint. What it does not do is locate it: both
# times it reported the line where parsing finally broke, tens of lines below the cause,
# naming an unrelated token. So this step does not re-detect; it DIAGNOSES, by reporting the
# nearest comment-with-an-apostrophe at or above the line bash names.
#
# A standalone scanner was tried first and rejected on measurement, not taste: tracking
# single-quote parity to decide whether a line sits inside a program flags 21 lines of this
# tree, because an apostrophe inside a DOUBLE-quoted string -- `sed "s/'/''/g"` -- flips the
# same counter. Separating those needs a shell tokeniser, which is more machinery than the
# defect is worth. Anchoring to the line bash already found needs none.
#
# NOT COVERED, and worth saying: two stray apostrophes re-balance the quoting, so the script
# parses, runs, and hands awk a silently altered program. `bash -n` cannot see that and
# neither can this. Nothing has hit it yet.
apos_suspect() {   # <file> <line bash blamed> -- nearest comment carrying a bare apostrophe
  awk -v lim="$2" '
    FNR > lim { exit }
    /^[ \t]*#/ {
      line = $0; gsub(/\047"\047"\047/, "@", line)     # the escaped idiom is the correct form
      if (index(line, "\047")) { n = FNR; t = substr(line, 1, 70) }
    }
    END { if (n) printf "    likely cause %s:%d: %s\n", FILENAME, n, t }' "$1"
}
brk=0
for f in "$KIT"/tooling/*.sh "$KIT"/tooling/commit-msg "$KIT"/tests/conformance.sh; do
  [ -f "$f" ] || continue
  err=$(bash -n "$f" 2>&1) && continue
  brk=1
  printf '  %s\n' "$err"
  apos_suspect "$f" "$(printf '%s' "$err" | sed -n 's/.*line \([0-9]*\).*/\1/p' | head -1)"
done
check $brk "every script parses"

# And the diagnosis itself is exercised on a fixture that carries the defect, so the guard is
# not merely green because the tree is clean today.
ap="$WORK.apos"; rm -rf "$ap"; mkdir -p "$ap"
{ printf '#!/usr/bin/env bash\n'
  printf 'echo start\n'
  printf "awk '\n"
  printf '  BEGIN { x = 1 }\n'
  printf "  # the operator's own note -- this apostrophe closes the program\n"
  printf '  { print x }\n'
  printf "' /dev/null\n"
  printf 'echo end\n'; } > "$ap/broken.sh"
( err=$(bash -n "$ap/broken.sh" 2>&1) && exit 1          # must NOT parse
  ln=$(printf '%s' "$err" | sed -n 's/.*line \([0-9]*\).*/\1/p' | head -1)
  apos_suspect "$ap/broken.sh" "$ln" | grep -q ':5:' )   # and line 5 is the apostrophe
check $? "the diagnosis points at the apostrophe, not at where parsing broke"
rm -rf "$ap"
fi

if step "a domain outside the declared industries is dropped, not stored"; then
# An unknown class is rejected loudly. A wrong domain was accepted SILENTLY and polluted the
# industry accelerator it feeds -- reviewers put the finding's subject there (`caching`,
# `cache-adapter-design`) because nothing said what a domain was. The `pattern` axis is where
# that belongs now, and a domain the project never declared must not survive.
step_dir="$WORK.dom"; rm -rf "$step_dir"; mkdir -p "$step_dir/.claude" "$step_dir/.project"
( cd "$step_dir" || exit 1
  git init -q -b main 2>/dev/null
  printf -- '---
paths.state: .project
accelerator.industry: .claude/bfsi.md
---
' > .claude/project-profile.md
  : > .claude/bfsi.md
  printf '%s' '{"findings":[{"class":"fail-open","severity":"major","lang":"go","pattern":"cache-port","domain":"not-an-industry","summary":"a domain that no project declared must be dropped"}]}' \
    | bash "$KIT/tooling/kit-finding.sh" --task T --agent a --json >/dev/null 2>&1
  grep -q '"domain":""' .project/events.ndjson && grep -q '"pattern":"cache-port"' .project/events.ndjson )
check $? "undeclared domain dropped, pattern retained"
rm -rf "$step_dir"
fi

if step "a trivial commit still has its trailers checked"; then
# git.trivial_pattern means trailers are not REQUIRED, not that they are not CHECKED. The
# early return let a `docs:` commit carry a typo'd Task-Id, which then indexed as a titleless
# phantom task -- and a pushed commit message cannot be corrected.
tx="$WORK.exempt"; rm -rf "$tx"; mkdir -p "$tx"
( cd "$tx" || exit 1
  git init -q -b main 2>/dev/null
  mkdir -p .claude .project/tasks
  printf -- '---
paths.tasks:  .project/tasks
paths.state:  .project
---
' > .claude/project-profile.md
  printf -- '---
id: T-real
title: r
tier: T1
---
b
' > .project/tasks/T-real.md
  printf 'docs: x

Task-Id: T-nope
Tier: T9
' > bad.txt
  printf 'docs: x
' > ok.txt
  bash "$KIT/tooling/kit-trailers.sh" message bad.txt 2>&1 | grep -q "matches no task" || exit 1
  bash "$KIT/tooling/kit-trailers.sh" message bad.txt 2>&1 | grep -q "invalid  Tier" || exit 1
  [ -z "$(bash "$KIT/tooling/kit-trailers.sh" message ok.txt 2>&1)" ] || exit 1 )
check $? "exempt commit: absence allowed, wrong values still reported"
rm -rf "$tx"
fi

if step "DCO sign-off is required only where the project asks for it"; then
# A contribution policy is the project's, not the kit's, so git.require_signoff defaults to
# false and adopting the kit never silently starts rejecting a project's own commits. The
# default is the half of this worth testing: a control that is on everywhere is a control
# that gets turned off everywhere. The other half is that git.trivial_pattern does NOT waive
# it -- that exemption is about bookkeeping, and a docs commit is as copyrightable as any
# other, so exempting it would put the commits nobody reads outside the record.
dc="$WORK.dco"; rm -rf "$dc"; mkdir -p "$dc"
prof_dco() { printf -- '---\npaths.tasks:  .project/tasks\npaths.state:  .project\n%s---\n' "$1" \
             > "$dc/.claude/project-profile.md"; }
( cd "$dc" || exit 1
  git init -q -b main 2>/dev/null
  mkdir -p .claude .project/tasks
  printf 'docs: x\n\nbody\n' > nosob.txt
  printf 'docs: x\n\nbody\n\nSigned-off-by: A Dev <a@b.c>\n' > sob.txt
  printf 'docs: x\n\nbody\n\nSigned-off-by: nobody\n' > badsob.txt
  t() { bash "$KIT/tooling/kit-trailers.sh" message "$1" 2>&1; }

  prof_dco ''                                   # key absent: nothing is said about sign-off
  [ -z "$(t nosob.txt)" ] || exit 1

  prof_dco 'git.require_signoff: true
'
  printf '%s' "$(t nosob.txt)"  | grep -q 'missing  Signed-off-by' || exit 1
  printf '%s' "$(t badsob.txt)" | grep -q 'invalid  Signed-off-by' || exit 1
  [ -z "$(t sob.txt)" ] || exit 1

  prof_dco 'git.require_signoff: yes
'                                               # unrecognised: fails closed and says so
  printf '%s' "$(t nosob.txt)" | grep -q 'missing  Signed-off-by' || exit 1 )
check $? "off by default, enforced when asked, not waived by the trivial pattern"
rm -rf "$dc"
fi

if step "the sign-off requirement has an adoption boundary"; then
# 0.11.0 shipped git.require_signoff with no boundary and it turned every open pull request red
# the moment it merged -- commits written before the rule existed cannot gain a trailer without
# rewriting published history. The argument against that was already inside kit-trailers.sh,
# under git.adopted_at, and the rule was added anyway. Nothing tested it, which is why.
#
# ANCESTRY CANNOT EXPRESS THIS and the fixture proves it rather than asserting it: the
# pre-rule commit here is built on a BRANCH cut before the boundary and merged after, so it
# is a DESCENDANT of the pre-adoption tip. An `--is-ancestor` boundary exempts nothing.
sb="$WORK.signoff"; rm -rf "$sb"; mkdir -p "$sb"
prof_sb() { printf -- '---\npaths.tasks:  .project/tasks\npaths.state:  .project\ngit.require_signoff: true\n%s---\n' "$1" \
            > "$sb/.claude/project-profile.md"; }
( cd "$sb" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  mkdir -p .claude .project/tasks

  # t0 base, then an OLD commit on a side branch, then the boundary on main, then a NEW commit.
  export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z"
  echo base > a.txt; git add -A; git commit -q -m "chore: base"
  git checkout -q -b side
  export GIT_AUTHOR_DATE="2026-01-02T00:00:00Z" GIT_COMMITTER_DATE="2026-01-02T00:00:00Z"
  echo old > b.txt; git add -A; git commit -q -m "docs: written before the rule existed"
  OLD=$(git rev-parse HEAD)
  git checkout -q main
  export GIT_AUTHOR_DATE="2026-01-03T00:00:00Z" GIT_COMMITTER_DATE="2026-01-03T00:00:00Z"
  echo rule > c.txt; git add -A; git commit -q -m "chore: the rule lands"
  BND=$(git rev-parse HEAD)
  git checkout -q side
  export GIT_AUTHOR_DATE="2026-01-04T00:00:00Z" GIT_COMMITTER_DATE="2026-01-04T00:00:00Z"
  echo new > d.txt; git add -A; git commit -q -m "docs: written after the rule, unsigned"
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

  # The premise: the old commit is NOT an ancestor of the boundary. If this ever becomes false
  # the fixture stopped testing what it claims to, so it is asserted rather than assumed.
  git merge-base --is-ancestor "$OLD" "$BND" 2>/dev/null &&
    { echo "  fixture broken: the old commit IS an ancestor of the boundary"; exit 1; }

  t() { bash "$KIT/tooling/kit-trailers.sh" range "$1" --enforce 2>&1; }

  # No boundary: BOTH unsigned commits are refused -- the 0.11.0 behaviour.
  prof_sb ''
  printf '%s' "$(t "$OLD..HEAD")" | grep -q 'missing  Signed-off-by' || exit 1
  printf '%s' "$(t "main..$OLD")" | grep -q 'missing  Signed-off-by' || exit 1

  # With the boundary: the pre-rule commit is exempt, the post-rule one is still refused.
  prof_sb "git.signoff_adopted_at: $BND
"
  printf '%s' "$(t "main..$OLD")" | grep -q 'missing  Signed-off-by' &&
    { echo "  pre-rule commit was refused despite the boundary"; exit 1; }
  printf '%s' "$(t "$OLD..HEAD")" | grep -q 'missing  Signed-off-by' ||
    { echo "  post-rule commit was exempted by the boundary"; exit 1; }

  # A boundary naming no commit FAILS CLOSED and says so. Exempting everything on a typo is
  # the quiet way a gate stops gating.
  prof_sb "git.signoff_adopted_at: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
"
  printf '%s' "$(t "main..$OLD")" | grep -q 'is not a commit in this repository' || exit 1
  printf '%s' "$(t "main..$OLD")" | grep -q 'missing  Signed-off-by' || exit 1 )
check $? "pre-rule commits exempt, post-rule still refused, a bad boundary fails closed"
rm -rf "$sb"
fi

if step "kit-init refuses to claim success when the profile is ignored"; then
# kit-init.sh printed "commit .claude/project-profile.md -- the team shares them" and exited 0
# in a repository whose .gitignore already excluded .claude. `git add` then refused, AFTER the
# tool had reported success. Greenfield cannot surface it: an empty repo has no .gitignore to
# conflict with, which is why it survived to be found on two unrelated brownfield subjects.
#
# The fixture uses the SECOND subject's four patterns verbatim rather than a minimal `.claude/`,
# because `*.claude` matching the directory `.claude` is the non-obvious one -- a matcher written
# by hand would very likely miss it, and that is the reason `git check-ignore` is the authority
# here rather than any pattern logic of the kit's own.
ki="$WORK.ignored"; rm -rf "$ki"; mkdir -p "$ki"
( cd "$ki" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  echo x > a.txt

  # 1. A repository with NO conflicting ignore rules: adoption succeeds and the profile stages.
  git add -A >/dev/null 2>&1; git commit -q -m "chore: seed" 2>/dev/null
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1 || { echo "  clean repo: kit-init exited non-zero"; exit 1; }
  git add .claude/project-profile.md >/dev/null 2>&1 || { echo "  clean repo: git add refused the profile"; exit 1; }

  # 2. The same repository once .claude is excluded: adoption must REFUSE to report success.
  rm -rf .claude .project
  printf '.claude/\n**/.claude/\n.claude-*\n*.claude\n' > .gitignore
  git add -A >/dev/null 2>&1; git commit -q -m "chore: ignore .claude" 2>/dev/null
  out=$(bash "$KIT/tooling/kit-init.sh" 2>&1); rc=$?
  [ "$rc" != 0 ] || { echo "  ignored profile: kit-init exited 0 and claimed success"; exit 1; }
  printf '%s' "$out" | grep -q 'ADOPTION IS INCOMPLETE' ||
    { echo "  ignored profile: no diagnostic naming the problem"; exit 1; }
  # It must name the RULE, not merely the file. "something ignores it" sends the reader hunting.
  printf '%s' "$out" | grep -q '\.gitignore' ||
    { echo "  ignored profile: diagnostic does not name the excluding rule"; exit 1; }

  # 3. THE REMEDY IT PRINTS MUST WORK. A warning that suggests a fix which does not fix it is
  #    worse than no warning: it spends the reader's trust and their time. Negating the file
  #    ALONE does not work -- git cannot re-include under an excluded directory -- so this also
  #    pins the fact that the printed form re-includes the directory first.
  printf '\n!.claude/\n.claude/*\n!.claude/project-profile.md\n' >> .gitignore
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1 || { echo "  after the printed remedy: still non-zero"; exit 1; }
  git add .claude/project-profile.md >/dev/null 2>&1 ||
    { echo "  after the printed remedy: git add still refuses"; exit 1; }

  # 4. And the naive form must NOT be what we recommend: prove it fails, so nobody "simplifies"
  #    the message later into something that looks tidier and silently stops working.
  #
  #    THE DIRECTORY MUST EXIST for this to test anything. `git check-ignore` evaluates
  #    `.claude/` -- a directory-only pattern -- differently when no such directory is present,
  #    and the first draft of this step deleted it first and got the opposite answer. The
  #    assertion caught a flaw in itself rather than in the code, which is the only reason the
  #    naive form ended up measured instead of assumed.
  #    AND the index must be reset, and `--no-index` used. `git check-ignore` consults the index
  #    by DEFAULT, so a file the previous assertion just staged is reported as NOT ignored no
  #    matter what the patterns say. That default is correct for kit-init.sh -- an already
  #    tracked profile CAN be committed, so there is nothing to warn about -- and wrong here,
  #    where the question is what the patterns alone do. Two different questions, one command.
  rm -rf .project
  git reset -q
  rm -rf .claude && mkdir -p .claude && echo x > .claude/project-profile.md
  printf '.claude/\n!.claude/project-profile.md\n' > .gitignore
  git check-ignore -q --no-index .claude/project-profile.md ||
    { echo "  negating the file alone now works -- the message can be simplified, re-check it"; exit 1; } )
check $? "exits non-zero, names the rule, and prints a remedy that actually works"
rm -rf "$ki"
fi

if step "pre-push blocks a wrong trailer while it can still be amended"; then
# commit-msg is skippable and absent for anyone who never ran kit-init; CI catches correctly
# but only after the push, when a commit message can no longer be changed. This repository
# carries a permanent phantom task from exactly that gap.
pp="$WORK.push"; rm -rf "$pp"; mkdir -p "$pp/remote" "$pp/work"
( cd "$pp/remote" || exit 1
  git init -q --bare -b main 2>/dev/null
  cd "$pp/work" && git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  git remote add origin "$pp/remote"
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  [ -x .git/hooks/pre-push ] || exit 1
  mkdir -p .project/tasks
  printf -- '---
id: T-real
title: r
tier: T2
---
b
' > .project/tasks/T-real.md
  sed -i.bak 's|^git.trailer_enforcement:.*|git.trailer_enforcement:  enforce|' .claude/project-profile.md
  rm -f .claude/project-profile.md.bak
  git add -A && git commit -q --no-verify -m "chore: seed"
  echo x > a.txt && git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-typo
Tier: T2"
  # KIT_PUSH_MAIN=1 ON BOTH, and the FIRST one is why it matters. pre-push now also refuses a
  # direct push to the default branch, so without the override this step would refuse every
  # push -- and the "must be REFUSED" assertion would pass whether or not the trailer check
  # worked at all. A step that goes green for the wrong reason is the failure this suite exists
  # to catch, and widening the hook introduced one here.
  #
  # The override isolates what this step tests. Branch policy is exercised where it belongs, in
  # the step below; this one is about a typo'd Task-Id being catchable while it is still one
  # amend away.
  KIT_PUSH_MAIN=1 git push origin main >/dev/null 2>&1 && exit 1   # must be REFUSED: bad trailer
  git commit -q --amend --no-verify -m "feat: w

Task-Id: T-real
Tier: T2"
  KIT_PUSH_MAIN=1 git push origin main >/dev/null 2>&1 || exit 1 ) # must now succeed
check $? "refuses a typo'd Task-Id, accepts it once amended"

# THE BRANCH RULE, TESTED ON ITS OWN. The step above needs KIT_PUSH_MAIN=1 to isolate what it
# tests, so without this the rule would be exercised only as a side effect of being overridden --
# which is the same as not being tested. Both directions and the override, on a fixture whose
# trailers are VALID, so a refusal can only be the branch rule.
( cd "$pp/work" || exit 1
  git checkout -q -b feature 2>/dev/null
  echo y > b.txt && git add -A
  git commit -q --no-verify -m "feat: v

Task-Id: T-real
Tier: T2"
  # A feature branch is allowed.
  git push -q origin feature >/dev/null 2>&1 || { echo "  a feature branch was refused"; exit 1; }
  git checkout -q main 2>/dev/null
  git merge -q --no-edit feature >/dev/null 2>&1
  # main is refused without the override...
  git push origin main >/dev/null 2>&1 && { echo "  a direct push to main was ALLOWED"; exit 1; }
  # ...and allowed with it. An override that must be typed is a decision; a hook without one is
  # a hook people delete -- the same argument kit-guard.sh:5 makes about over-blocking.
  KIT_PUSH_MAIN=1 git push origin main >/dev/null 2>&1 || { echo "  the override did not work"; exit 1; }
  exit 0 )
check $? "a feature branch pushes, a direct push to main is refused, and the override works"
rm -rf "$pp"
fi

if step "spend is measured per agent, from that agent's own transcript" spend; then
# The defect this replaced: every SubagentStop received the SESSION transcript, which holds
# no subagent records at all, so each row was main-loop cost wearing an agent's name. The
# fixture therefore puts DIFFERENT numbers in the two transcripts -- a reader that fell back
# to the session file would produce the main loop's figures under the agent's label, and pass
# a test that only counted rows.
#
# Totals are cumulative per transcript, so recording twice must not double the cost, and
# Stop's sweep must not re-record what SubagentStop already wrote.
sx="$WORK.spend"; rm -rf "$sx"; mkdir -p "$sx/src" "$sx/sess/subagents"
( cd "$sx" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---
id: T-s
title: s
tier: T2
---
b
' > .project/tasks/T-s.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  printf '{"type":"assistant","message":{"model":"m-main","usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":1000,"output_tokens":500}}}
' > sess.jsonl
  printf '{"type":"assistant","message":{"model":"m-sub","usage":{"input_tokens":5,"cache_creation_input_tokens":400,"cache_read_input_tokens":0,"output_tokens":200}}}
' > sess/subagents/agent-A1.jsonl
  printf '{"agentType":"implementation-reviewer","spawnDepth":1}' > sess/subagents/agent-A1.meta.json
  # SubagentStop, then Stop, then both again: four firings, and only two things happened.
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id A1 --agent security-reviewer
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl"
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id A1 --agent security-reviewer
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl"
  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-s
Tier: T2
Task-Status: done"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  rows=$(Q "SELECT COUNT(*) FROM spend;")
  sub=$(Q "SELECT agent||'/'||agent_id||'/'||model||'/'||tok_out||'/'||context FROM spend WHERE scope='subagent';")
  main=$(Q "SELECT '['||agent||']/'||model||'/'||tok_out FROM spend WHERE scope='main';")
  att=$(Q "SELECT COUNT(*) FROM spend WHERE task_id='T-s';")
  # 10 + 0x1.25 + 1000x0.1 + 500x5 = 2610, and 5 + 400x1.25 + 0 + 200x5 = 1505. The raw sum
  # of the same counters is 2115 -- pricing a cache read like fresh input and output like
  # neither. If this ever equals 2115 the weighting has been dropped.
  w=$(Q "SELECT SUM(tok_in*100 + cache_write*125 + cache_read*10 + tok_out*500)/100 FROM spend;")
  [ "$rows" = 2 ] && [ "$att" = 2 ] && [ "$w" = 4115 ] &&
  [ "$sub" = "security-reviewer/A1/m-sub/200/405" ] && [ "$main" = "[]/m-main/500" ] )
check $? "one row per transcript, agent rows from agent files, main loop unlabelled"
fi

if step "concurrent spend firings append one event, not one per firing" spend; then
# kit-spend.sh reads the WHOLE event log into seen[] and only then appends, so two hooks firing
# at once for the same transcript both read the pre-append state and both write. It needs one
# hook registered TWICE for one transcript -- a local .claude/settings.json plus --plugin-dir.
# Stop and SubagentStop alone key on DIFFERENT transcripts and never collide, which is why this
# repository's own log is clean and why the step above -- four SEQUENTIAL firings -- passes
# against the defect and could never have caught it.
#
# This asserts EVENTS, not rows. Rows were never wrong: last-write-wins collapses duplicates and
# no cost figure moved. The committed append-only log is what a duplicate damages, and the event
# count is the only place it is visible -- keeping those two halves apart is the point.
#
# THREE ROUNDS, not one. Measured on the unfixed script: 17 of 20 concurrent pairs duplicated,
# so a single round would pass against the defect roughly one time in seven. Three rounds of
# three firings puts a false pass below one in three hundred, and the message names the round.
sc="$WORK.spendlock"; rm -rf "$sc"; mkdir -p "$sc/src"
( cd "$sc" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":10,"output_tokens":5}}}
' > sess.jsonl
  bad=""
  for round in 1 2 3; do
    : > .project/events.ndjson
    bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" &
    bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" &
    bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" &
    wait
    n=$(grep -c '"kind":"spend"' .project/events.ndjson 2>/dev/null)
    [ "$n" = 1 ] || bad="$bad round$round=$n"
  done
  [ -n "$bad" ] && { echo "  concurrent firings duplicated:$bad (wanted 1 event each)"; exit 1; }
  # A lock that outlives the hook makes every later firing pay the retry bound before falling
  # through, so the cleanup is asserted rather than assumed.
  [ -d .project/.spend.lock ] && { echo "  the lock directory outlived the hook"; exit 1; }
  exit 0 )
check $? "concurrent firings append one event, and the lock does not outlive them"
rm -rf "$sc"
fi

if step "spend records the peak context of a series, not only the reading it ended on" spend; then
# `context` is the LAST reading a transcript produced. Context FALLS as well as rises --
# compaction reclaims it -- so a session that peaked high and ended low reports the low number,
# and "reduce peak context" cannot be asked of it at all. Measured on this repository before the
# column existed: one transcript ends at 270k having peaked at 963k, 3.6x apart.
#
# THE SERIES ALREADY EXISTED. kit-spend.sh appends a new event whenever a transcript's totals
# move, so the log holds the readings and nothing new is recorded -- the peak is derived.
#
# `readings` is asserted alongside, because peak == final has TWO meanings and only one of them
# is about context: a series that never fell, or no series at all. A fixture that cannot tell
# them apart would pass against a build that dropped the peak entirely.
pk="$WORK.peak"; rm -rf "$pk"; mkdir -p "$pk/.claude" "$pk/.project/tasks"
( cd "$pk" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-k\ntitle: k\ntier: T2\n---\nb\n' > .project/tasks/T-k.md
  git add -A && git commit -q --no-verify -m seed
  # A series whose TOKEN totals rise (they are cumulative) while CONTEXT rises then falls --
  # the real shape, and the one a final reading gets wrong. Distinct, well-formed timestamps
  # matter: the ingest sorts by timestamp THEN total, so a malformed `at` silently reorders the
  # series and the highest-total row wins instead of the last one. That was this step's first
  # fixture, and it failed for that reason rather than for the defect it is about.
  {
    printf '{"task":"","kind":"spend","at":"2026-01-01T00:00:00Z","transcript":"tfall","scope":"main","agent":"","agent_id":"","session":"s","model":"m","turns":10,"tok_in":1,"tok_out":100,"cache_read":0,"cache_write":0,"context":100,"pack_loads":0}\n'
    printf '{"task":"","kind":"spend","at":"2026-01-02T00:00:00Z","transcript":"tfall","scope":"main","agent":"","agent_id":"","session":"s","model":"m","turns":20,"tok_in":1,"tok_out":200,"cache_read":0,"cache_write":0,"context":900,"pack_loads":0}\n'
    printf '{"task":"","kind":"spend","at":"2026-01-03T00:00:00Z","transcript":"tfall","scope":"main","agent":"","agent_id":"","session":"s","model":"m","turns":30,"tok_in":1,"tok_out":300,"cache_read":0,"cache_write":0,"context":250,"pack_loads":0}\n'
  } >> .project/events.ndjson
  # A single-reading transcript, so the two meanings of peak == final are distinguishable.
  printf '{"task":"","kind":"spend","at":"2026-01-09T00:00:00Z","transcript":"tonce","scope":"main","agent":"","agent_id":"","session":"s","model":"m","turns":5,"tok_in":1,"tok_out":5,"cache_read":0,"cache_write":0,"context":500,"pack_loads":0}\n' >> .project/events.ndjson
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  fin=$(Q "SELECT context      FROM spend WHERE transcript='tfall';")
  pkv=$(Q "SELECT context_peak FROM spend WHERE transcript='tfall';")
  rds=$(Q "SELECT readings     FROM spend WHERE transcript='tfall';")
  one=$(Q "SELECT readings     FROM spend WHERE transcript='tonce';")
  [ "$fin" = 250 ] || { echo "  final reading is $fin, wanted 250 (the series ends low)"; exit 1; }
  [ "$pkv" = 900 ] || { echo "  peak is $pkv, wanted 900 -- the peak is not being derived"; exit 1; }
  [ "$rds" = 3 ]   || { echo "  readings is $rds, wanted 3"; exit 1; }
  [ "$one" = 1 ]   || { echo "  single-reading transcript reports readings=$one, wanted 1"; exit 1; }
  # And the report must SAY it, or the column is derived into a file nobody reads.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Peak context' STATUS.generated.md || { echo "  the status file does not report peak context"; exit 1; }
  # AND an index predating the column must SAY so rather than drop the section. kit-status's q()
  # sends stderr to /dev/null and returns empty on a missing column, so "no such column" and
  # "nothing to report" are one string -- without this the section would silently vanish from a
  # generated file and read as "no peaks", which is the absent-read-as-benign shape this
  # repository keeps paying for.
  sqlite3 .project/index.db "ALTER TABLE spend DROP COLUMN context_peak;" >/dev/null 2>&1 ||
    { echo "  could not drop the column to test the stale-index arm"; exit 1; }
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'UNAVAILABLE: this index predates' STATUS.generated.md ||
    { echo "  a stale index dropped the peak section instead of naming it"; exit 1; }
  exit 0 )
check $? "a series that ends low still reports its peak, and a lone reading is not a peak"
rm -rf "$pk"
fi

if step "a reviewer's findings reach the table, and an unrecorded review is visible"; then
# The defect: reviewers emitted correctly formatted blocks and NOTHING consumed them. A real
# project that had run a T2 and a T3 review held zero finding rows, and every escape-rate number
# in the README was computed from that empty table -- `T3 0/13` reading as "nothing escaped"
# while meaning "nothing was recorded".
#
# This step used to exercise a hook that scraped those blocks out of a transcript. That
# component is DELETED, not repaired (docs/LESSONS.md S5): the reviewer returns structured data
# and the orchestrator records it, so there is no parser left to defend. What survives from the
# old step is everything that was never about scraping -- attribution after the fact, tier
# resolution, and the requirement that a review recording nothing SAYS so.
fl="$WORK.floop"; rm -rf "$fl"; mkdir -p "$fl/src"
( cd "$fl" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---
id: T-r
title: r
tier: T2
---
b
' > .project/tasks/T-r.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  F="$KIT/tooling/kit-finding.sh"

  # A reviewer that cannot know its task says so, rather than having one guessed for it.
  printf '%s' '{"findings":[{"class":"fail-open","severity":"major","lang":"sql","summary":"the first of two recorded before any task transition"},{"class":"correctness","severity":"minor","lang":"bash","summary":"the second of two recorded before any task transition"}]}' \
    | bash "$F" --unattributed --agent security-reviewer --json >/dev/null 2>&1

  # A review that found nothing is a MEASUREMENT and must survive as one. Silence here is what
  # let an empty table read as a clean record.
  printf '%s' '{"findings":[]}' | bash "$F" --unattributed --agent tester --json >/dev/null 2>&1
  grep -q '"kind":"finding-gap"' .project/events.ndjson || exit 1

  bash "$KIT/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM finding WHERE task_id IS NULL OR task_id='';")" = 2 ] || exit 1
  grep -q 'finding(s) unattributed' STATUS.generated.md || exit 1

  # The task then commits, and the same heuristic that binds spend binds these -- including the
  # tier, without which escape-rate-by-tier reports every finding as untiered.
  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-r
Tier: T2
Task-Status: progress"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM finding WHERE task_id='T-r' AND tier='T2';")" = 2 ] || exit 1
  # And the summary survived the whole trip, which is the column that makes a row readable.
  [ "$(Q "SELECT COUNT(*) FROM finding WHERE task_id='T-r' AND summary LIKE '%recorded before any task transition%';")" = 2 ] )
check $? "an empty review is recorded as a gap, and attribution and tier follow the task"
rm -rf "$fl"
fi
if step "a subagent whose transcript cannot be found is reported, not costed" spend; then
# The alternative -- writing the row anyway from whatever transcript is at hand -- is the
# defect. Nothing is recorded, and the fact that nothing was recorded is.
( cd "$sx" || exit 1
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id GHOST --agent coder
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id GHOST --agent coder
  # THE PHANTOM, and it is the case a real session is full of: the harness fires for something
  # that was never an agent -- no name, no transcript. Measured 19 times in one trial against 3
  # real subagents, several mid-turn, one before any subagent existed. Fired twice here for the
  # same reason the named one is: once is not evidence that it is not counted per firing.
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id PHANTOM
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id PHANTOM
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  rows=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM spend;" | tr -d '\015')
  gaps=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='spend-gap';" | tr -d '\015')
  unt=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='spend-untracked';" | tr -d '\015')
  # The NAMED agent is still a gap and still loud -- that is a subagent run whose cost is missing,
  # and suppressing it would be the filter-hides-real-work failure this split exists to avoid.
  # The unnamed one is recorded, once, under its own kind, and never as an unmeasured run.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q '1 subagent run(s) unmeasured' STATUS.generated.md || exit 1
  grep -q '1 stop firing(s) were not subagent runs' STATUS.generated.md || exit 1
  [ "$rows" = 2 ] && [ "$gaps" = 1 ] && [ "$unt" = 1 ] )
check $? "a named agent with no transcript is a gap; an unnamed stop firing is not"
rm -rf "$sx"
fi

if step "a CRLF profile and CRLF task files parse identically to LF"; then
# A Windows checkout of a repo without `*.md text eol=lf` puts CR on the end of every line of
# the profile and of every task file. The readers trimmed space and tab, so `paths.tasks`
# became `.project/tasks<CR>` -- naming no directory, finding no tasks, and reporting an empty
# backlog rather than an error.
#
# THIS STEP CANNOT FAIL UNDER A LENIENT AWK. The gawk in git-bash strips CR on input, so the
# defect is invisible there; a POSIX awk keeps it. Running the assertion anyway would be a
# green that means "not exercised", which is the failure mode this suite exists to refuse. So
# the awk is probed first, and if it strips CR the step re-runs the kit under `gawk
# -v BINMODE=3` -- which is what every other awk does by default -- and says which mode it
# used. If neither is available it reports NOT EXERCISED rather than passing.
cr_len=$(printf 'x\r\n' | awk 'NR==1{print length($0)}')
cx="$WORK.crlf"; rm -rf "$cx"; mkdir -p "$cx/.claude" "$cx/.project/tasks" "$cx/shim"
awkmode=native
if [ "$cr_len" = 1 ]; then
  printf 'x\r\n' > "$cx/probe"
  if command -v gawk >/dev/null 2>&1 && [ "$(gawk -v BINMODE=3 'NR==1{print length($0)}' "$cx/probe")" = 2 ]; then
    printf '#!/usr/bin/env bash\nexec gawk -v BINMODE=3 "$@"\n' > "$cx/shim/awk"
    chmod +x "$cx/shim/awk"; awkmode="BINMODE=3 shim"
  else
    awkmode="NOT EXERCISED"
  fi
fi
printf '  awk keeps CR: %s\n' "$awkmode"
# Which legs this platform can actually discriminate on, probed rather than assumed. The
# first version of this step asserted three readers and could only detect one; the other two
# were being cleaned upstream by the platform before the reader under test ever ran, so
# reverting either fix left the step green. Naming what is masked is the difference between a
# test and a claim.
#
#   $(...)  msys2 bash drops a trailing CR in command substitution, and kit_cfg returns its
#           single value through one -- so kit_cfg's own strip is unobservable there. kit_cfg_all
#           writes straight to stdout and is testable everywhere the awk keeps CR.
#   sed     msys2 GNU sed strips CR in text mode, and TIER_RULES is piped through one. So the
#           \r in floorof's trim classes is unreachable from a fixture on this platform: it is
#           defence behind kit_cfg_all's strip, not a separately covered path. Do not assert it.
# `tr -d ' '` on every wc capture. BSD wc pads its count to a column width and GNU wc does
# not, so a bare comparison against a number is true on Linux and false on macOS. Two of
# these shipped today and took the macOS conformance run red while Linux stayed green — the
# first platform-specific defect this suite has caught in its own test code rather than in
# the kit.
subst_cr=$(v=$(printf 'x\r\n'); printf '%s' "$v" | wc -c | tr -d ' ')
[ "$subst_cr" = 2 ] && substleg="exercised" || substleg="masked by \$(...) on this shell"
printf '  kit_cfg leg:  %s\n' "$substleg"
if [ "$awkmode" = "NOT EXERCISED" ]; then
  skip "this awk strips CR on input and cannot be made to keep it" \
       "CRLF input yields the same values as LF"
else
  ( cd "$cx"
    [ -x shim/awk ] && PATH="$PWD/shim:$PATH" && export PATH
    git init -q -b main 2>/dev/null
    printf -- '---\r\npaths.tasks:  .project/tasks\r\npaths.state:  .project\r\ntier.default: T1\r\ntier.rule: src/** T3\r\ntier.rule: lib/** T2\r\n---\r\n' > .claude/project-profile.md
    printf -- '---\r\nid: T-crlf\r\ntitle: c\r\ntier: T1\r\nepic: e1\r\npaths: src/a.go\r\n---\r\n\r\nbody\r\n' > .project/tasks/T-crlf.md

    # LEG 1 -- kit_cfg_all, asserted on its own bytes. It writes to stdout with no command
    # substitution anywhere in the path, so this is the one reader in kit-lib.sh whose strip
    # can be proven on any platform whose awk keeps CR. Two rules so the assertion does not
    # rest on the last line, which a caller's $(...) would clean anyway.
    . "$KIT/tooling/kit-lib.sh"
    kit_cfg_all .claude/project-profile.md tier.rule > rules.out
    [ "$(tr -cd '\r' < rules.out | wc -c | tr -d ' ')" = 0 ] || exit 1

    # LEG 2 -- the indexer's frontmatter parser, end to end. stderr is captured rather than
    # discarded: an awk fatal in this pass leaves kit-index.sh exiting 0 with tasks missing,
    # so a step that throws the diagnostics away cannot see its own fixture half-indexed.
    bash "$KIT/tooling/kit-index.sh" >/dev/null 2>index.err
    [ -s index.err ] && exit 1

    # `sed $'s/\r$//'`, NOT `tr -d '\015'`. The $'...' form is not cosmetic:
    # BSD sed reads a bare \r as a literal `r`, so the shell must expand the byte first. sqlite3 terminates lines with CRLF here, which is
    # why the rest of this file strips CR -- but the artifact under test IS a CR, and deleting
    # every one of them makes `T1<CR>/e1<CR>/T3` compare equal to `T1/e1/T3`. Strip the line
    # terminator only. This was the defect that left four of five one-part reverts green.
    n=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM task;" | sed $'s/\r$//')
    r=$(sqlite3 .project/index.db "SELECT tier||'/'||epic||'/'||COALESCE(tier_floor,'-') FROM task WHERE id='T-crlf';" | sed $'s/\r$//')
    [ "$n" = 1 ] && [ "$r" = "T1/e1/T3" ] )
  check $? "CRLF input yields the same values as LF (kit_cfg_all + frontmatter)"
fi
rm -rf "$cx"
fi

if step "a broken tier.rule cannot empty the index, and a lost task file fails closed"; then
# `globre` left `[`, `]` and `\` unescaped, so `tier.rule: src/[ab T3` compiled to an invalid
# regex and awk took a FATAL mid-pass: three of four tasks vanished, the survivor lost its
# tier and its floor, and kit-index.sh exited 0 having printed the DB path. A typo in a
# documented config field, silently shortening the backlog, in the control that decides how
# many reviewers a change gets.
#
# Two halves, because the fix has two: the rule is refused where TIER_RULES is built (one
# place, so the SQL floor path cannot receive it either), and the task pass now counts the
# files it READ. The count is what catches the general case -- awk exits 0 after skipping an
# argument it could not read, so status alone never notices a task going missing.
gx="$WORK.glob"; rm -rf "$gx"; mkdir -p "$gx/.claude" "$gx/.project/tasks"
( cd "$gx" || exit 1
  git init -q -b main 2>/dev/null
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "tier.default: T1"; echo "tier.rule: src/[ab T3"; echo "tier.rule: src/** T2"
    echo "---"; } > .claude/project-profile.md
  for i in 1 2 3 4; do
    printf -- '---\nid: T-%s\ntitle: t%s\ntier: T3\npaths: src/a.go\n---\nb\n' "$i" "$i" > ".project/tasks/T-$i.md"
  done

  # HALF 1 -- the uncompilable rule is refused by name and the build still completes. The
  # surviving rule must still apply: refusing one rule is not licence to drop the floor.
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>a.err || exit 1
  grep -q 'tier.rule ignored' a.err || exit 1
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM task;' | tr -d '\015')" = 4 ] || exit 1
  [ "$(sqlite3 .project/index.db "SELECT COUNT(*) FROM task WHERE tier_floor='T2';" | tr -d '\015')" = 4 ] || exit 1

  # HALF 1b -- the refusal must survive to the artifact. kit-status.sh runs the indexer with
  # stderr discarded, so a warning that lives only on a terminal reaches nobody, and the file
  # then blames "no declared paths:" for a floor that is missing because a rule was thrown
  # away. Those are different causes and the benign one must not stand in for the other.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'refused as unusable' STATUS.generated.md || exit 1

  # HALF 2 -- a task file the reader cannot read. A directory named *.md is the portable way
  # to make awk skip an argument while still exiting 0, which is precisely the case a status
  # check misses. The run must fail, NAME the file, and leave the GOOD index alone --
  # yesterday's correct backlog beats today's truncated one.
  mkdir -p .project/tasks/T-lost.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>b.err && exit 1
  grep -q 'not read: .*T-lost.md' b.err || exit 1
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM task;' | tr -d '\015')" = 4 ] || exit 1
  rm -rf .project/tasks/T-lost.md

  # HALF 2b -- and an EMPTY task file is not that. `kit-task.sh` writes a skeleton for a human
  # to fill in, so a zero-byte task file is an ordinary intermediate state; awk fires no rule
  # for it, which is indistinguishable from unreadable to anything counting records. Failing
  # the build on it took the whole derived-state layer down, permanently, from a committed
  # stub. It must be named and skipped, and the build must still succeed.
  : > .project/tasks/T-draft.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>c.err || exit 1
  grep -q 'no content' c.err || exit 1
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM task;' | tr -d '\015')" = 4 ] || exit 1
  rm -f .project/tasks/T-draft.md

  # HALF 3 -- and it recovers. A guard that stays latched after the cause is gone is a guard
  # people work around.
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>/dev/null || exit 1
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM task;' | tr -d '\015')" = 4 ] )
check $? "bad rule refused and recorded, lost file fails closed, empty file does not"
rm -rf "$gx"
fi

if step "an ingest adapter cannot reach sqlite3's dot-commands"; then
# Adapter stdout is fed to the sqlite3 CLI through a file redirect, not through a driver, so a
# line whose FIRST character is `.` was a dot-command rather than SQL. `.shell touch x` ran a
# shell with the operator's permissions, on a path an agent can reach: the profile naming the
# adapter is an ordinary in-root file, and kit-guard.sh permits every in-root write by design.
# The refusal filter is a blacklist of schema-altering STATEMENTS and could not see `.shell`,
# `.system`, `.import`, `.load` or `.output`. The fix indents emitted lines by one space, which
# closes the channel without naming a command; sqlite3 then parses them as SQL and fails.
#
# TWO HALVES, and half 1 is why half 2 means anything. An absent marker proves nothing if the
# adapter never ran -- so half 1 shows adapter output genuinely reaching the database, and only
# then does half 2's absence say the dot-command was refused rather than never attempted.
dx="$WORK.dotcmd"; rm -rf "$dx"; mkdir -p "$dx/.claude" "$dx/.project/tasks"
( cd "$dx" || exit 1
  git init -q -b main 2>/dev/null
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "ingest.extra: .claude/probe.sh"; echo "---"; } > .claude/project-profile.md

  # HALF 1 -- adapter output reaches the database. If this stops being true the step is
  # measuring nothing, so it fails rather than skipping.
  printf '#!/usr/bin/env bash\n[ "$1" = emit ] && echo "INSERT OR REPLACE INTO meta(key,value) VALUES(\047probe\047,\0471\047);"\nexit 0\n' > .claude/probe.sh
  # Tracked, per ADR 0003 -- otherwise the adapter never executes and BOTH halves below pass on a
  # refusal instead of on the property they name. The dot-command half in particular would then
  # be asserting that a command which never ran did not run.
  git add .claude/probe.sh >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>p.err || exit 1
  [ "$(sqlite3 .project/index.db "SELECT value FROM meta WHERE key='probe';" | tr -d '\015')" = 1 ] || exit 1

  # HALF 2 -- the same channel carrying a dot-command executes nothing. The build FAILS, which
  # is the intended outcome: an indented dot-command is not valid SQL, and fail-closed on a
  # malformed adapter is the behaviour the surrounding code already relies on.
  printf '#!/usr/bin/env bash\n[ "$1" = emit ] && printf ".shell touch PWNED-DOTCMD\\n"\nexit 0\n' > .claude/probe.sh
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>q.err && exit 1
  [ -e PWNED-DOTCMD ] && exit 1
  exit 0 )
check $? "an adapter's dot-command is parsed as SQL, never executed as a shell"
rm -rf "$dx"
fi

if step "only a committed, repo-relative adapter runs"; then
# ADR 0003 option C. The project chooses WHICH adapter; the kit constrains whether something
# nobody chose can run. The profile sits inside the root where kit-guard.sh permits every write
# by design, so an agent could write an adapter and a profile line in one turn and get execution
# on the next index -- and kit-index.sh --if-stale is step 1 of task-context, so that is ordinary
# use rather than a contrived trigger.
#
# THREE ASSERTIONS, and the middle one is why the other two mean anything: a guard that refused
# every adapter would satisfy both refusals and silently delete the ADAPTERS.md seam.
#
# What this does NOT prove, per ADR 0003: an agent holding Bash can git add and commit, and the
# guard does not match Bash. This binds a confused agent, a copied profile and an ad-hoc path.
ac="$WORK.adapt"; rm -rf "$ac"; mkdir -p "$ac/.claude" "$ac/.project/tasks" "$ac/tools-x"
( cd "$ac" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email fixture@x; git config user.name fixture
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "ingest.extra: tools-x/adapter.sh"; echo "---"; } > .claude/project-profile.md

  # 1. UNTRACKED -- the shape an agent produces. It must not execute.
  printf '#!/usr/bin/env bash\ntouch "EXECUTED-UNTRACKED"\n' > tools-x/adapter.sh
  rm -f EXECUTED-UNTRACKED
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ -e EXECUTED-UNTRACKED ] &&
    { printf '    ^ an untracked adapter executed\n' >&2; exit 1; }

  # 2. TRACKED -- the seam still works. Without this the step passes on a guard that refuses
  #    everything, which would be a worse defect than the one being fixed.
  printf '#!/usr/bin/env bash\n[ "$1" = emit ] && echo "INSERT OR REPLACE INTO meta(key,value) VALUES(\047adapterprobe\047,\0471\047);"\nexit 0\n' > tools-x/adapter.sh
  git add -A >/dev/null 2>&1; git commit -qm fixture >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  [ "$(sqlite3 -noheader .project/index.db \
       "SELECT value FROM meta WHERE key='adapterprobe';" | tr -d '\015')" = 1 ] ||
    { printf '    ^ a committed adapter did NOT run; the seam is broken\n' >&2; exit 1; }

  # 3. ABSOLUTE -- names code this repository does not contain, so no review here saw it.
  sed 's|ingest.extra: tools-x/adapter.sh|ingest.extra: /tmp/kit-adapter-abs.sh|' \
    .claude/project-profile.md > p.tmp && mv p.tmp .claude/project-profile.md
  printf '#!/usr/bin/env bash\ntouch "%s/EXECUTED-ABS"\n' "$PWD" > /tmp/kit-adapter-abs.sh
  rm -f EXECUTED-ABS
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ -e EXECUTED-ABS ] &&
    { printf '    ^ an absolute-path adapter executed\n' >&2; exit 1; }
  rm -f /tmp/kit-adapter-abs.sh
  exit 0 )
check $? "untracked and absolute adapters are refused, a committed one still runs"
rm -rf "$ac"
fi

if step "the write guard refuses every tool its matcher fires on"; then
# The guard matched Write|Edit|NotebookEdit and read only "file_path". NotebookEdit names its
# target "notebook_path", so the extraction came back empty, the no-target branch fail-opened,
# and a NotebookEdit anywhere on disk went through unexamined -- while SECURITY.md listed the
# tool by name under "enforced mechanically". Write outside exited 2; NotebookEdit outside
# exited 0.
#
# The check that was supposed to cover this greps hooks.json for the matcher STRING. That
# passes while the guard is broken, and would pass on a guard that refused nothing at all. It
# is a fine protocol assertion and stays where it is; it is not a behavioural one, so this step
# exercises the guard instead of reading it.
#
# BOTH DIRECTIONS PER TOOL. A guard that refused everything would pass an outside-only test and
# make the kit unusable, so each tool must also be allowed inside the root.
gt="$WORK.guard"; rm -rf "$gt"; mkdir -p "$gt"
( cd "$gt" || exit 1
  git init -q -b main 2>/dev/null
  : > inside.txt

  # Both probe paths are absolute and derived from git's OWN spelling of the root, not from
  # $PWD. On msys, Windows Temp is reachable as both /tmp/... and /c/Users/.../Temp/... -- two
  # spellings of one directory that `pwd -P` cannot collapse, because the alias is a mount and
  # not a symlink. A relative probe resolved against $PWD then lands in the other spelling and
  # the guard refuses it: fail-CLOSED, and a property of where this fixture happens to sit
  # rather than of the guard. Using one spelling for both sides tests inside-versus-outside,
  # which is what this step is for.
  root=$(git rev-parse --show-toplevel 2>/dev/null) ||
    { printf '    ^ fixture is not a git repository; the guard would exit 0 unexamined\n' >&2; exit 1; }
  inside="$root/inside.txt"
  outside="$root/../kit-guard-probe-outside.txt"

  for pair in "Write file_path" "Edit file_path" "NotebookEdit notebook_path"; do
    # shellcheck disable=SC2086
    set -- $pair; t=$1; k=$2
    printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$t" "$k" "$outside" |
      bash "$KIT/tooling/kit-guard.sh" >/dev/null 2>&1
    [ $? = 2 ] || { printf '    ^ %s outside the root was NOT refused\n' "$t" >&2; exit 1; }
    printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$t" "$k" "$inside" |
      bash "$KIT/tooling/kit-guard.sh" >/dev/null 2>&1
    [ $? = 0 ] || { printf '    ^ %s inside the root WAS refused\n' "$t" >&2; exit 1; }
  done

  # The drift check AC3 asks for. The matcher lives in hooks.json and the key mapping lives in
  # kit-guard.sh; they agreed by luck until they did not. Adding a fourth tool to the matcher
  # without teaching the guard its key now fails here rather than failing open in production.
  mt=$(grep -o '"matcher": "[^"]*"' "$KIT/hooks/hooks.json" | head -1 |
       sed 's/.*"matcher": "//; s/"$//')
  [ -n "$mt" ] || { printf '    ^ could not read the PreToolUse matcher\n' >&2; exit 1; }
  for t in $(printf '%s' "$mt" | tr '|' ' '); do
    case " Write Edit NotebookEdit " in
      *" $t "*) ;;
      *) printf '    ^ hooks.json matches %s but this step has no key for it, so the guard\n' "$t" >&2
         printf '      is untested for it -- add the tool key here and to kit-guard.sh\n' >&2
         exit 1 ;;
    esac
  done
  exit 0 )
check $? "every matched tool is refused outside the root and allowed inside it"
rm -rf "$gt"
fi

if step "the generic event writer cannot mint a kind the indexer acts on"; then
# kit-event.sh takes the KIND as a free argument and splices its third argument in as raw JSON,
# validating neither. Before the refusal it was a skeleton key:
#   kit-event.sh T-x finding-fixed '{"finding":"<id>","fixed":1}'
# set fixed_at on a real finding after a reindex, with kit_findings.py never invoked -- forging
# the one artefact .claude/CLAUDE.md reserves to the operator. The same route minted findings
# whose class and severity were outside kit-finding.sh --vocab.
#
# THE LIST IS DERIVED, NOT RESTATED. kit-index.sh's `k=="..."` branches are the authority for
# which kinds it MUTATES a row for, as against merely recording. This step reads them out of the
# indexer and requires kit-event.sh to refuse each one, so teaching the indexer to act on a fifth
# kind without guarding it here goes red instead of quietly reopening the hole. A list copied
# into this file would drift the way the guard's tool keys drifted from its matcher.
#
# ASSERTED ON STATE, NOT ON EXIT CODE. A refusal that exits 2 and appends anyway is the failure
# mode worth catching, so the log must be byte-identical afterwards.
ex="$WORK.evkind"; rm -rf "$ex"; mkdir -p "$ex/.claude" "$ex/.project/tasks"
( cd "$ex" || exit 1
  git init -q -b main 2>/dev/null
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"
  } > .claude/project-profile.md

  kinds=$(grep -oE 'k=="[a-z-]+"' "$KIT/tooling/kit-index.sh" |
          sed 's/k=="//; s/"$//' | sort -u)
  [ -n "$kinds" ] || { printf '    ^ no acting kinds found in kit-index.sh; nothing was tested\n' >&2; exit 1; }

  bash "$KIT/tooling/kit-event.sh" T-probe note >/dev/null 2>&1   # a kind it may write
  before=$(cksum .project/events.ndjson 2>/dev/null)
  [ -n "$before" ] || { printf '    ^ the writer did not create a log; the rest proves nothing\n' >&2; exit 1; }

  for k in $kinds; do
    bash "$KIT/tooling/kit-event.sh" T-forge "$k" '{"finding":"x","fixed":1}' >/dev/null 2>&1
    after=$(cksum .project/events.ndjson 2>/dev/null)
    [ "$after" = "$before" ] || {
      printf '    ^ kit-event.sh wrote a %s line; the indexer acts on that kind\n' "$k" >&2; exit 1; }
  done

  # And the recorder still records. A guard that refused everything would pass every assertion
  # above while making the script useless -- the same shape as a write guard that blocks its own
  # project root.
  bash "$KIT/tooling/kit-event.sh" T-probe via >/dev/null 2>&1 || exit 1
  [ "$(cksum .project/events.ndjson)" != "$before" ] || {
    printf '    ^ a non-acting kind was refused too; the guard is too broad\n' >&2; exit 1; }
  exit 0 )
check $? "acting kinds are refused, ordinary kinds still record"
rm -rf "$ex"
fi

if step "an unassessable critical leaves the gate and stays in the record"; then
# Nine criticals predate the `summary` column, so the pre-flight gate could never reach zero:
# permanently red, or bypassed -- and a gate bypassed once is bypassed always. Two shapes were
# rejected before this one. Marking them `--fixed` writes a false statement into an append-only
# committed log. Excluding summary-less rows by query would exempt every FUTURE critical whose
# summary is missing, turning a bounded historical problem into an unbounded hole.
#
# So the exclusion is per-finding and deliberate: the operator marks one unassessable WITH A
# REASON, and only marks leave the gate. The three properties below are what make that honest
# rather than a clearance, and all three are asserted because any one alone can pass while the
# mechanism is a laundering machine.
ua="$WORK.unassess"; rm -rf "$ua"; mkdir -p "$ua/.claude" "$ua/.project/tasks"
( cd "$ua" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email fixture@x; git config user.name fixture
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"
  } > .claude/project-profile.md
  printf -- '---\nid: T-g\ntitle: g\ntier: T1\n---\nb\n' > .project/tasks/T-g.md

  printf '%s' '{"findings":[{"class":"fail-open","severity":"critical","summary":"a critical recorded for the gate fixture"}]}' |
    bash "$KIT/tooling/kit-finding.sh" --task T-g --agent security-reviewer --json >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1

  # 1. UNMARKED, IT COUNTS. Without this the rest could pass on a gate that never fired.
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 &&
    { printf '    ^ the gate passed with an unmarked critical outstanding\n' >&2; exit 1; }

  fid=$(sqlite3 -noheader .project/index.db \
        "SELECT id FROM finding WHERE severity='critical' LIMIT 1;" | tr -d '\015')
  [ -n "$fid" ] || { printf '    ^ no finding id; nothing was tested\n' >&2; exit 1; }

  # 2. A BLANK REASON IS REFUSED, and nothing is appended. This is the anti-laundering property:
  # a disposition that removes a finding from a gate without saying why is the thing being
  # avoided, so the refusal is asserted on the LOG, not on an exit code.
  pre=$(cksum .project/events.ndjson)
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --unassessable --reason "  " >/dev/null 2>&1 &&
    { printf '    ^ a blank reason was accepted\n' >&2; exit 1; }
  [ "$(cksum .project/events.ndjson)" = "$pre" ] ||
    { printf '    ^ a refused mark still appended to the log\n' >&2; exit 1; }

  # 3. A FINDING THAT CARRIES A SUMMARY CANNOT TAKE THIS MARK. Without this the route is a
  # general-purpose way to clear the criticals gate rather than a narrow hatch for rows whose
  # text does not survive. The refusal is proved, not just the acceptance -- a mechanism tested
  # only on the case it should allow is untested on the case that matters.
  pre2=$(cksum .project/events.ndjson)
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --unassessable \
       --reason "trying to launder a readable finding" >/dev/null 2>&1 &&
    { printf '    ^ a finding WITH a summary accepted --unassessable\n' >&2; exit 1; }
  [ "$(cksum .project/events.ndjson)" = "$pre2" ] ||
    { printf '    ^ the refused mark still appended\n' >&2; exit 1; }

  # 4. WITH THE SUMMARY GONE, THE MARK IS ACCEPTED, IT LEAVES THE GATE -- and is still reported.
  # The summary is cleared directly because the nine real rows predate the column entirely;
  # there is no supported route that produces a summary-less finding today, which is the point.
  sqlite3 .project/index.db "UPDATE finding SET summary='' WHERE id='$fid';" || exit 1
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --unassessable \
       --reason "predates the summary column; not recoverable" >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 ||
    { printf '    ^ the gate still blocks on a critical marked unassessable\n' >&2; exit 1; }

  # Excluded from the GATE, never from the RECORD. A mechanism that merely hid the row would
  # satisfy the assertion above and be exactly the laundering this exists to prevent.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1 || exit 1
  grep -q 'UNASSESSABLE' STATUS.generated.md ||
    { printf '    ^ the excluded critical vanished from the status file\n' >&2; exit 1; }
  [ -n "$(sqlite3 -noheader .project/index.db \
          "SELECT unassessable_reason FROM finding WHERE id='$fid';" | tr -d '\015')" ] ||
    { printf '    ^ the reason was not stored\n' >&2; exit 1; }
  exit 0 )
check $? "marked unassessable clears the gate, blank reasons are refused, the row stays reported"
rm -rf "$ua"
fi

if step "a superseded critical needs a marker in its subject, and a live subject is refused"; then
# The FOURTH disposition. 31 findings on one task review a design document whose successor opens
# by rejecting it, and none of the three existing verbs fits: `--fixed` is false because nothing
# was fixed, `--unassessable` is false AND mechanically refused because they carry summaries, and
# `--false` is worst because they were real -- being real is why the design died. So the task
# could never close, no matter how much correct work was done on it.
#
# The danger is the obvious one: on that same task, 26 of 57 open findings point at subjects that
# are STILL LIVE. A verb guarded only by "did you pass --by" would have cleared all 57. So the
# guard is a `Superseded-by:` marker in the subject FILE, and the refusal is what is asserted
# here -- an acceptance-only test would pass on a mechanism with no guard at all.
sp="$WORK.supersede"; rm -rf "$sp"; mkdir -p "$sp/.claude" "$sp/.project/tasks" "$sp/docs"
( cd "$sp" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email fixture@x; git config user.name fixture
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"
  } > .claude/project-profile.md
  printf -- '---\nid: T-s\ntitle: s\ntier: T1\n---\nb\n' > .project/tasks/T-s.md
  printf '# design one\n\nstill standing.\n' > docs/old.md
  printf '# design two\n\nrejects design one.\n'  > docs/new.md

  printf '%s' '{"findings":[{"class":"correctness","severity":"critical","file":"docs/old.md","line":3,"summary":"a critical against a design that will later be withdrawn"}]}' |
    bash "$KIT/tooling/kit-finding.sh" --task T-s --agent approach-reviewer --json >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1

  # 1. UNMARKED, IT COUNTS. Without this every assertion below could pass on a gate that never
  # fired in the first place.
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 &&
    { printf '    ^ the gate passed with an unmarked critical outstanding\n' >&2; exit 1; }

  fid=$(sqlite3 -noheader .project/index.db \
        "SELECT id FROM finding WHERE severity='critical' LIMIT 1;" | tr -d '\015')
  [ -n "$fid" ] || { printf '    ^ no finding id; nothing was tested\n' >&2; exit 1; }

  # 2. THE SUBJECT IS LIVE, SO THE MARK IS REFUSED -- and nothing is appended. This is THE
  # property. docs/old.md exists and carries no marker, which is the state every live subject is
  # in, so a guard that passes here is a general-purpose exit from the criticals gate.
  pre=$(cksum .project/events.ndjson)
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by docs/new.md >/dev/null 2>&1 &&
    { printf '    ^ a finding whose subject still stands accepted --superseded\n' >&2; exit 1; }
  [ "$(cksum .project/events.ndjson)" = "$pre" ] ||
    { printf '    ^ a refused mark still appended to the log\n' >&2; exit 1; }

  # 3. A BLANK --by IS REFUSED, the same anti-laundering property --reason carries: a disposition
  # that clears a gate without naming what cleared it is a clearance.
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by "  " >/dev/null 2>&1 &&
    { printf '    ^ a blank --by was accepted\n' >&2; exit 1; }

  # 4. THE MARKER MUST NAME WHAT --by NAMES. Otherwise the citation is decorative: any marked
  # file would clear a mark citing anything at all.
  printf '# design one\n\n> **Superseded-by: docs/new.md**\n\nrejected.\n' > docs/old.md
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by docs/other.md >/dev/null 2>&1 &&
    { printf '    ^ a marker naming X accepted a mark citing Y\n' >&2; exit 1; }

  # 4a. THE FOUR REPRODUCED DEFEATS. The first version of this step used only `docs/other.md` for
  # the mismatch case -- a string sharing no substring boundary with the marker, which is the one
  # case a SUBSTRING test also refuses. So the step passed while `grep -qF -- "$by"` accepted every
  # substring of the marker line, and two reviewers found it independently at critical severity.
  # `--by '-'` was accepted against the live repository and wrote `"by":"-"` into the committed log.
  # Each case below fails on the pre-fix code; none of them did before.
  #
  # A test that only exercises the cases a control was written against cannot tell you the control
  # holds. These are the cases it was NOT written against.
  for bad in '-' 'Superseded' 'Superseded-by' 'docs' 'd' 'new.md'; do
    bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by "$bad" >/dev/null 2>&1 &&
      { printf '    ^ --by %s satisfied a marker naming docs/new.md\n' "$bad" >&2; exit 1; }
  done
  # A newline made `grep -F` read --by as a pattern LIST whose empty element matched every line.
  # Written with a literal so command substitution cannot strip it -- the first attempt to test
  # this passed because $(printf '...\n') drops the trailing newline and tested nothing.
  _nl='
'
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by "docs/new.md${_nl}" >/dev/null 2>&1 &&
    { printf '    ^ a newline in --by was accepted\n' >&2; exit 1; }
  # SELF-SUPERSESSION BY BASENAME. The self-check was exact equality against the full path sitting
  # under a substring match, so the bare filename cleared both halves.
  printf '# design one\n\n> **Superseded-by: old.md**\n\nrejected.\n' > docs/old.md
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by old.md >/dev/null 2>&1 &&
    { printf '    ^ a document superseded itself by basename\n' >&2; exit 1; }
  printf '# design one\n\n> **Superseded-by: docs/new.md**\n\nrejected.\n' > docs/old.md
  # THE TOOL'S OWN PRESCRIBED MARKER MUST BE ACCEPTED. The refusal message tells the operator to
  # write `> **Superseded-by: X**`, so the matching rule has to strip the emphasis it asks for.
  # A guard whose remedy it rejects is worse than no guard, and this function has made that exact
  # mistake once already, on the character class that finds the line.
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by docs/new.md >/dev/null 2>&1 ||
    { printf '    ^ the marker this tool tells the operator to write was refused\n' >&2; exit 1; }
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --open --note "undo the probe above" >/dev/null 2>&1

  # 4b. A TRAILING --by MUST EXIT, NOT HANG. `shift 2` with one argument left shifts nothing and
  # there is no `set -e`, so the parse loop spun forever -- triggered by the exact typo this
  # command's own error message invites. Bounded, because the failure mode of a regression here is
  # an infinite loop that would hang the whole suite rather than fail one step.
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by >/dev/null 2>&1
    [ $? = 124 ] &&
      { printf '    ^ a trailing --by hung the argument parser\n' >&2; exit 1; }
  fi

  # 5. NOW IT IS ACCEPTED, and it leaves the gate. Asserted after the four refusals so this
  # cannot be the only thing the step proves.
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --superseded --by docs/new.md >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 ||
    { printf '    ^ the gate still blocks on a critical marked superseded\n' >&2; exit 1; }

  # Excluded from the GATE, never from the RECORD, and never reported as addressed -- a design
  # that died because a review found problems with it is evidence the review worked.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1 || exit 1
  grep -q 'SUPERSEDED' STATUS.generated.md ||
    { printf '    ^ the excluded critical vanished from the status file\n' >&2; exit 1; }
  grep -q 'all marked addressed' STATUS.generated.md &&
    { printf '    ^ status claims every critical was addressed; one was superseded\n' >&2; exit 1; }
  [ "docs/new.md" = "$(sqlite3 -noheader .project/index.db \
          "SELECT superseded_by FROM finding WHERE id='$fid';" | tr -d '\015')" ] ||
    { printf '    ^ what superseded it was not stored\n' >&2; exit 1; }

  # 6. A SUBJECT THAT WAS DELETED IS NOT A SUBJECT THAT WAS SUPERSEDED. Without this, removing
  # the evidence is the cheapest route out of the gate.
  printf '%s' '{"findings":[{"class":"correctness","severity":"critical","file":"docs/gone.md","line":1,"summary":"a critical whose subject file is not in the tree at all"}]}' |
    bash "$KIT/tooling/kit-finding.sh" --task T-s --agent approach-reviewer --json >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  gid=$(sqlite3 -noheader .project/index.db \
        "SELECT id FROM finding WHERE file_path='docs/gone.md' LIMIT 1;" | tr -d '\015')
  [ -n "$gid" ] || { printf '    ^ the absent-subject finding was not recorded\n' >&2; exit 1; }
  bash "$KIT/tooling/kit-resolve.sh" --finding "$gid" --superseded --by docs/new.md >/dev/null 2>&1 &&
    { printf '    ^ a finding whose subject file is absent accepted --superseded\n' >&2; exit 1; }
  exit 0 )
check $? "superseded needs a matching marker in the subject; live and deleted subjects refused"
rm -rf "$sp" "$sp.empty"
fi

if step "a failed build leaves the previous index alone and keeps saying so"; then
# Two halves of one defect. `fl` was the only value on the task INSERT not passed through
# q(), so `tier.rule: src/** T3','x` ended the SQL literal early: the statement failed, the
# surrounding transaction still committed, and every task landed with tier NULL. Then the
# half-written DB was newer than every source, so the next --if-stale run -- the one that
# fires at session start -- declared it fresh and said nothing. One announcement, then silence,
# over a backlog with no tiers.
ax="$WORK.apos"; rm -rf "$ax"; mkdir -p "$ax/.claude" "$ax/.project/tasks"
( cd "$ax" || exit 1
  git init -q -b main 2>/dev/null
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "tier.rule: src/** T3','x"; echo "---"; } > .claude/project-profile.md
  # After the profile, so kit-init leaves it alone — it is here for the .gitignore entries the
  # last assertions check, which is the same writer a real adopting repository gets.
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-1\ntitle: t\ntier: T1\npaths: src/a.go\n---\nb\n' > .project/tasks/T-1.md

  # HALF 1 -- an apostrophe in a profile value cannot reach the SQL. It is refused as a
  # non-tier before it gets there, and the build completes with the tier column intact.
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>a.err || exit 1
  grep -q 'is not a tier' a.err || exit 1
  [ "$(sqlite3 .project/index.db "SELECT tier FROM task WHERE id='T-1';" | tr -d '\015')" = T1 ] || exit 1

  # HALF 1b -- the bypass that made the first version of that refusal worthless. It read the
  # LAST whitespace field as the tier while the splitter downstream cut at the FIRST, so a
  # three-field rule passed validation on its trailing `T3` and handed `',x T3` to the
  # consumers as a floor. That sorts below every real tier, so `tier < tier_floor` never fired
  # and the under-tiered task simply stopped being reported -- exit 0, nothing refused, the
  # whole below-floor section gone from the status file. The load-bearing assertion is the
  # LAST one: refusing the rule is only worth anything if a genuine floor still reports.
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "tier.rule: src/** ',x T3"; echo "---"; } > .claude/project-profile.md
  printf -- '---\nid: T-under\ntitle: u\ntier: T0\npaths: src/a.go\n---\nb\n' > .project/tasks/T-under.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>d.err || exit 1
  grep -q 'expected <path-glob> <tier>' d.err || exit 1
  [ -z "$(sqlite3 .project/index.db "SELECT tier_floor FROM task WHERE id='T-under';" | tr -d '\015')" ] || exit 1
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "tier.rule: src/** T3"; echo "---"; } > .claude/project-profile.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>/dev/null || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Below their tier floor' STATUS.generated.md || exit 1
  rm -f .project/tasks/T-under.md

  # HALF 2 -- a statement that fails MID-EXECUTION must not leave a corpse. An extra ingest
  # adapter emitting invalid SQL is the reachable way to produce one. The good index must
  # survive untouched, and -- the part that made this dangerous -- the NEXT run must still
  # fail rather than mistaking a newer mtime for a fresh index.
  # The adapter is declared FIRST and the index rebuilt while it is still harmless, so that
  # when it turns bad no watched file is touched. Otherwise --if-stale sees a newer profile
  # and rebuilds for that reason, and the assertion below passes on the fixture rather than on
  # the fix: an ingest.extra adapter is in neither the mtime WATCH list nor the fingerprint
  # loop, so its failure is exactly the one that used to go quiet after announcing itself once.
  printf '#!/usr/bin/env bash\nexit 0\n' > .claude/bad.sh
  # TRACKED, because ADR 0003 makes an untracked adapter refuse to run. This fixture is about
  # what happens when an adapter emits bad SQL, so the adapter has to reach execution at all --
  # otherwise the step would pass for the wrong reason, on a refusal rather than on the failure
  # it exists to test. Adding it is what a real project does with an adapter it intends to use.
  git add .claude/bad.sh >/dev/null 2>&1
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "ingest.extra: .claude/bad.sh"; echo "---"; } > .claude/project-profile.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>/dev/null || exit 1
  printf '#!/usr/bin/env bash\n[ "$1" = emit ] && echo "INSERT INTO nosuchtable VALUES(1);"\nexit 0\n' > .claude/bad.sh
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>b.err && exit 1
  grep -q 'left unchanged' b.err || exit 1
  [ "$(sqlite3 .project/index.db "SELECT tier FROM task WHERE id='T-1';" | tr -d '\015')" = T1 ] || exit 1
  [ -e .project/index.db.new ] && exit 1                      # no half-built file left behind
  bash "$KIT/tooling/kit-index.sh" --if-stale >/dev/null 2>c.err && exit 1
  grep -q 'index build failed' c.err || exit 1
  # And the temp file and the failure marker are both ignored, so a kill that outruns the
  # trap cannot leave a derived database staged by the next `git add -A`.
  git check-ignore -q .project/index.db.new || exit 1
  git check-ignore -q .project/index.db.failed || exit 1

  # HALF 3 -- and it recovers, with the index rebuilt rather than merely left alone.
  rm -f .claude/bad.sh
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>/dev/null || exit 1
  [ "$(sqlite3 .project/index.db "SELECT tier FROM task WHERE id='T-1';" | tr -d '\015')" = T1 ] )
check $? "apostrophe refused before the SQL, failed build preserves the index and stays loud"
rm -rf "$ax"
fi

if step "a commit touching nothing watched still makes the index stale"; then
# THE DEFECT THIS BINDS. `--if-stale` decided freshness partly on the mtime of `.git/HEAD`,
# which on a branch holds the text `ref: refs/heads/main` and is NOT rewritten by a commit --
# the commit moves `refs/heads/<branch>`. Measured on this repository before the fix:
# `.git/HEAD` was seventeen minutes older than the tip it pointed at, so `--if-stale` reported
# FRESH with history moved past the last build. Every git-derived input -- `touches`, and
# through it `tier_floor`, blast radius and co-change -- was invisible to the check, and
# `skills/task-context` step 1 is exactly this command.
#
# THE COMMIT MUST TOUCH NOTHING IN THE WATCH LIST, which is the whole design of this fixture.
# A test that also edited a task file, the profile or events.ndjson would see the mtime path
# fire, PASS ON THE BROKEN VERSION, and prove nothing. `src/a.go` is in none of them.
#
# It asserts on DERIVED DATA rather than on the database's mtime: a `touches` edge that only
# exists if the commit was actually read. An mtime assertion would pass on a rebuild that
# ingested nothing.
hs="$WORK.hstale"; rm -rf "$hs"; mkdir -p "$hs/.claude" "$hs/.project/tasks" "$hs/src"
( cd "$hs" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email fixture@x; git config user.name fixture
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"; } \
    > .claude/project-profile.md
  { echo "---"; echo "id: T-1"; echo "title: t"; echo "tier: T1"; echo "state: open"; echo "---"; } \
    > .project/tasks/T-1.md
  echo seed > src/seed.txt
  git add -A >/dev/null 2>&1
  git commit -qm "seed" >/dev/null 2>&1 || exit 1

  # Build once, with the index newer than every source. This is the state a session starts in.
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  [ "$(sqlite3 .project/index.db \
      "SELECT COUNT(*) FROM edge WHERE src='T-1' AND dst='f:src/a.go' AND rel='touches';" \
      | tr -d '\015')" = 0 ] || exit 1

  # A commit that touches ONLY an unwatched path. No task file, no profile, no event log.
  echo x > src/a.go
  git add src/a.go >/dev/null 2>&1
  git commit -q -F - >/dev/null 2>&1 <<'MSG' || exit 1
add a.go

Task-Id: T-1
Tier: T1
MSG

  # On the broken version this prints the path and exits 0 without ingesting anything.
  bash "$KIT/tooling/kit-index.sh" --if-stale >/dev/null 2>&1 || exit 1
  [ "$(sqlite3 .project/index.db \
      "SELECT COUNT(*) FROM edge WHERE src='T-1' AND dst='f:src/a.go' AND rel='touches';" \
      | tr -d '\015')" = 1 ] || exit 1

  # And it settles: a second run with nothing moved must NOT rebuild, or `--if-stale` has been
  # turned into an unconditional rebuild and the ~39s it exists to avoid is spent every session.
  _before=$(sqlite3 .project/index.db "SELECT value FROM meta WHERE key='head_commit';" | tr -d '\015')
  [ "$_before" = "$(git rev-parse HEAD)" ] || exit 1
  bash "$KIT/tooling/kit-index.sh" --if-stale >/dev/null 2>&1 || exit 1 )
check $? "a commit outside the watch list is seen, and an unchanged HEAD is not rebuilt"
rm -rf "$hs"
fi

if step "the two floor sources agree on a non-ASCII path, and ? is refused"; then
# A tier floor is derived twice and the two derivations must agree. `globre` turns the glob
# into an awk regex for the DECLARED-paths source; the same glob goes to SQLite GLOB for the
# TOUCHED-files source. Two ways they diverged on a non-ASCII name, both measured:
#
#   `?` -> regex `.`, one BYTE here, where GLOB's `?` is one CHARACTER. src/?.go matched
#         src/é.go on the SQL side and not on the awk side. Refused now rather than fixed:
#         a byte-correct one-character matcher needs hex escapes inside an awk program, and
#         macOS ships an awk that does not interpret them.
#   git   renders any path above 0x7F as `"src/\303\251.go"` by default, so the touches edge
#         was recorded under a name matching no glob at all -- the touched-files floor simply
#         never applied. Fixed with core.quotepath=false, which is the load-bearing half.
#
# The test name uses a character with NO canonical decomposition, so macOS NFD/NFC cannot
# fail this for an unrelated reason.
nx="$WORK.nonascii"; rm -rf "$nx"; mkdir -p "$nx/.claude" "$nx/.project/tasks" "$nx/src"
if ( cd "$nx" && printf 'x\n' > "src/ß.go" && [ -f "src/ß.go" ] ) 2>/dev/null; then
  ( cd "$nx" && git init -q -b main 2>/dev/null
    git config user.email a@b.c; git config user.name T
    # hub_pct 100 so nothing is filtered as a hub: with the default 20 and a two-commit
    # fixture the threshold is 0.4, every file is a hub, and the cochange table comes out
    # EMPTY -- which would make the co-change assertion below pass against anything.
    { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
      echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
      echo "cochange.hub_pct: 100"; echo "tier.rule: src/** T3"; echo "---"; } > .claude/project-profile.md
    printf -- '---\nid: T-decl\ntitle: d\ntier: T1\npaths: src/ß.go\n---\nb\n' > .project/tasks/T-decl.md
    printf -- '---\nid: T-touch\ntitle: t\ntier: T1\n---\nb\n' > .project/tasks/T-touch.md
    git add -A && git commit -q --no-verify -m "chore: seed"
    # Two files in ONE commit, so the pair produces a co-change row. The flag was added to
    # BOTH git invocations and only the touches one was covered; a mangled name here splits
    # one file into two nodes and nothing noticed.
    printf 'y\n' > "src/ß.go"; printf 'y\n' > src/plain.go; git add -A
    git commit -q --no-verify -m "feat: w

Task-Id: T-touch
Tier: T1"
    bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
    # The co-change pass, asserted on the real name. Reverting core.quotepath on that
    # invocation alone leaves the touches assertions below green, which is how it shipped
    # untested the first time.
    [ "$(sqlite3 .project/index.db "SELECT COUNT(*) FROM cochange WHERE src='f:src/ß.go' OR dst='f:src/ß.go';" | sed $'s/\r$//')" -ge 1 ] || exit 1

    # The assertion with teeth: the SAME file, reached by the two different sources, must
    # produce the same floor. Before core.quotepath=false the declared side said T3 and the
    # touched side said nothing at all.
    d=$(sqlite3 .project/index.db "SELECT COALESCE(tier_floor,'-') FROM task WHERE id='T-decl';" | sed $'s/\r$//')
    t=$(sqlite3 .project/index.db "SELECT COALESCE(tier_floor,'-') FROM task WHERE id='T-touch';" | sed $'s/\r$//')
    [ "$d" = T3 ] && [ "$t" = T3 ] || exit 1
    # And the file is recorded under its own name, not an octal-escaped one.
    sqlite3 .project/index.db "SELECT id FROM node WHERE type='file';" | sed $'s/\r$//' | grep -qxF 'f:src/ß.go' || exit 1

    # A path git will ONLY report escaped -- one containing a backslash, a quote or a control
    # byte -- is not healed by core.quotepath=false, which covers bytes above 0x7F and nothing
    # else. Measured: `src/i\j.go` still arrives as `"src/i\\j.go"`, and recording that as a
    # node gave a file matching no rule and a floor that silently did not apply. It must be
    # DROPPED and COUNTED, and the count must reach the status file.
    #
    # Built through nested tree objects because git refuses such a name in a worktree on
    # Windows; the object database takes it, which is also how it would arrive from a POSIX
    # checkout where the name is perfectly legal.
    bl=$(printf 'z\n' | git hash-object -w --stdin)
    st=$(printf '100644 blob %s\ti\\j.go\n' "$bl" | git mktree)
    rt=$( { git ls-tree HEAD^{tree}; printf '040000 tree %s\tsrcq\n' "$st"; } | git mktree )
    cq=$(git commit-tree "$rt" -p HEAD -m "feat: q

Task-Id: T-touch
Tier: T1")
    git update-ref refs/heads/main "$cq"
    bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
    [ "$(sqlite3 .project/index.db "SELECT COUNT(*) FROM node WHERE id LIKE '%j.go%';" | sed $'s/\r$//')" = 0 ] || exit 1
    [ "$(sqlite3 .project/index.db "SELECT value FROM meta WHERE key='paths_unusable';" | sed $'s/\r$//')" = 1 ] || exit 1
    bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
    grep -q 'could not be indexed' STATUS.generated.md || exit 1

    # `?` is refused by name, and refusing it does not take the build down.
    { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
      echo "tier.default: T1"; echo "tier.rule: src/?.go T3"; echo "---"; } > .claude/project-profile.md
    bash "$KIT/tooling/kit-index.sh" >/dev/null 2>q.err || exit 1
    grep -q '? is not supported in a glob' q.err || exit 1 )
  check $? "same floor from both sources on a non-ASCII path; ? refused by name"
else
  skip "this filesystem would not take a non-ASCII filename" \
       "same floor from both sources on a non-ASCII path"
fi
rm -rf "$nx"
fi

if step "the glob converter parses under POSIXLY_CORRECT, and the floor it derives is unchanged"; then
# `globre` turned a glob's `*` into a regex with `gsub(/\052+/, ".*", r)`. An octal escape inside
# a REGEX LITERAL is rejected by gawk under --posix, and by stock gawk 5.4.1 in DEFAULT mode --
# the runner's awk, found by conformance (windows-latest). It fails at PARSE time, so the whole
# of kit-index.sh dies before it reads anything: the ingest refuses, the index is not rebuilt,
# and `POSIXLY_CORRECT=1`, the pre-push check docs/LESSONS.md 12 prescribes, cannot be run on
# the largest script in the kit.
#
# THIS ASSERTS THE FLOOR, NOT THE EXIT STATUS. On the defect the ingest refuses and LEAVES THE
# PREVIOUS INDEX IN PLACE -- correct, announced, and indistinguishable from success to anything
# that only checks whether the script ran. A fresh fixture plus a derived value is what makes
# the difference visible.
#
# It is NOT a Windows step. It runs everywhere, because the defect is a gawk version and gawk
# runs everywhere; ubuntu's mawk and macOS's BSD awk simply never rejected the construct, which
# is why two green legs sat beside this for a month.
px="$WORK.posixawk"; rm -rf "$px"; mkdir -p "$px/.claude" "$px/.project/tasks" "$px/src"
( cd "$px" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"
    echo "tier.rule: src/** T3"; echo "---"; } > .claude/project-profile.md
  printf -- '---
id: T-p
title: p
tier: T1
paths: src/a.go
---
b
' > .project/tasks/T-p.md
  printf 'x
' > src/a.go
  git add -A && git commit -q --no-verify -m "chore: seed"
  rm -f .project/index.db
  POSIXLY_CORRECT=1 bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  # No index at all is the shape of the defect: the parse died before any ingest.
  [ -f .project/index.db ] || { echo "  no index was written under POSIXLY_CORRECT=1"; exit 1; }
  f=$(sqlite3 .project/index.db "SELECT COALESCE(tier_floor,'-') FROM task WHERE id='T-p';" | sed $'s/\r$//')
  [ "$f" = T3 ] || { echo "  floor under POSIXLY_CORRECT=1 was '$f', wanted T3"; exit 1; }
  # And the same tree without the variable must agree, or the fix has changed what a glob means.
  rm -f .project/index.db
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  g=$(sqlite3 .project/index.db "SELECT COALESCE(tier_floor,'-') FROM task WHERE id='T-p';" | sed $'s/\r$//')
  [ "$g" = "$f" ] || { echo "  floor differs with and without POSIXLY_CORRECT: '$g' vs '$f'"; exit 1; }
  exit 0 )
check $? "kit-index parses under POSIXLY_CORRECT and derives the same floor either way"
rm -rf "$px"
fi

if step "paths.tasks has one default, it follows paths.state, and a misplaced backlog is named" ; then
# `paths.tasks` had TWO defaults: `$STATE_DIR/tasks` in kit-charter and kit-criteria, and a
# hardcoded `.project/tasks` in seven other scripts. Reproduced 2026-09-11 in fresh repositories:
# move `paths.state` and omit `paths.tasks`, and those seven look in the OLD place, find nothing,
# and kit-index indexes ZERO TASKS while warning only that the plan is stale. An empty backlog
# and a misconfigured one are the same output, and only one of them is fine.
#
# THREE ARMS, and the third is the one that keeps the second honest. A warning that fires on a
# genuinely empty backlog would be a nag an adopter learns to ignore -- and every adopting
# repository is empty by definition, so that arm is not hypothetical.
pt="$WORK.pathstasks"; rm -rf "$pt"
mk() { # mk <dir> <state> <tasksline> <taskdir>
  rm -rf "$1"; mkdir -p "$1/.claude" "$1/$4"
  ( cd "$1" || exit 1
    git init -q -b main 2>/dev/null
    git config user.email a@b.c; git config user.name T
    { echo "---"; echo "paths.state: $2"; [ -n "$3" ] && echo "$3"
      echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
    printf -- '---\nid: T-p\ntitle: p\ntier: T2\n---\nb\n' > "$4/T-p.md"
    git add -A >/dev/null 2>&1; git commit -q --no-verify -m seed >/dev/null 2>&1 )
}
(
  # Arm 1 -- THE DEFECT ITSELF. paths.state moved, paths.tasks absent. The default must follow
  # the state directory, so the task is found. Before this it indexed zero and said nothing.
  mk "$pt.a" ".kit" "" ".kit/tasks"
  ( cd "$pt.a" && bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 )
  n=$(sqlite3 "$pt.a/.kit/index.db" "SELECT COUNT(*) FROM task;" 2>/dev/null | tr -d '\015')
  [ "${n:-0}" = 1 ] || { echo "  arm 1: paths.state moved and paths.tasks absent indexed ${n:-0} task(s), wanted 1"; exit 1; }

  # Arm 2 -- a misplaced backlog is NAMED, not silently indexed as zero.
  mk "$pt.b" ".project" "paths.tasks: .kit/tasks" ".project/tasks"
  out=$( cd "$pt.b" && bash "$KIT/tooling/kit-index.sh" 2>&1 )
  case "$out" in
    *"task files EXIST under"*) ;;
    *) echo "  arm 2: tasks under .project/tasks with paths.tasks elsewhere produced no warning"; exit 1 ;;
  esac

  # Arm 3 -- a genuinely EMPTY backlog must stay silent, or the warning is a nag and an
  # adopting repository trips it on day one.
  rm -rf "$pt.c"; mkdir -p "$pt.c/.claude" "$pt.c/.project/tasks"
  ( cd "$pt.c" || exit 1
    git init -q -b main 2>/dev/null
    git config user.email a@b.c; git config user.name T
    { echo "---"; echo "paths.state: .project"; echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
    git add -A >/dev/null 2>&1; git commit -q --no-verify -m seed >/dev/null 2>&1 )
  out=$( cd "$pt.c" && bash "$KIT/tooling/kit-index.sh" 2>&1 )
  case "$out" in
    *"task files EXIST under"*) echo "  arm 3: an empty backlog was reported as misconfigured"; exit 1 ;;
  esac
  exit 0 )
check $? "the default follows paths.state, a misplaced backlog is named, and an empty one is not"
rm -rf "$pt.a" "$pt.b" "$pt.c"
fi

if step "the state directory moves: rules, attributes and messages follow paths.state" ; then
# Reproduced twice in fresh repositories on 2026-09-11: adopt, set paths.state to something other
# than .project, re-run kit-init.sh, and the derived database and the packs are UNTRACKED rather
# than ignored -- so the next `git add -A` commits them -- while the event log loses merge=union
# and the plan loses its LF pin. kit-init's own checks pass in exactly that configuration and
# print their success lines anyway.
#
# THE ORDER MATTERS AND IS THE POINT: adopt at the DEFAULT layout first, so the old kit-written
# lines exist, THEN move. A fixture that configures the new layout before adopting never
# exercises the case an adopter is actually in.
#
# Asserted through git check-ignore and git check-attr rather than string matching. The defect
# was a substring check believing itself -- asserting on the text of .gitignore would repeat the
# original mistake in the test.
mv="$WORK.movedstate"; rm -rf "$mv"; mkdir -p "$mv/src"
( cd "$mv" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  echo x > src/a; git add -A; git commit -q --no-verify -m seed
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1

  # Move the state directory, the way an adopter would whose repo already ignores .project.
  sed -i.bak 's|^paths.state:.*|paths.state:  .kit|; s|^paths.tasks:.*|paths.tasks:  .kit/tasks|'     .claude/project-profile.md 2>/dev/null || exit 1
  grep -q '^paths.state:  .kit' .claude/project-profile.md ||
    { echo "  fixture: the profile did not take the new paths.state"; exit 1; }
  rm -f .claude/project-profile.md.bak
  mkdir -p .kit/tasks
  # The FIRST adoption created .project/tasks legitimately -- that was the layout then. Clear it,
  # so what the assertion below sees is RE-creation by the second run and not the leftovers of
  # the first. kit-init.sh:12 used to mkdir a hardcoded .project/tasks on every run, leaving an
  # empty one beside the real backlog for a project that had moved.
  rm -rf .project
  out=$(bash "$KIT/tooling/kit-init.sh" 2>&1)

  printf -- '---\nid: T-m\ntitle: m\ntier: T2\n---\nb\n' > .kit/tasks/T-m.md
  git add -A >/dev/null 2>&1; git commit -q --no-verify -m "chore: seed the moved layout" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  git add -A >/dev/null 2>&1; git commit -q --no-verify -m "chore: plan" >/dev/null 2>&1
  idxout=$(bash "$KIT/tooling/kit-index.sh" 2>&1)

  ign() { git check-ignore -q "$1"; }
  att() { git check-attr "$1" -- "$2" 2>/dev/null | sed 's/.*: //'; }

  ign .kit/index.db   || { echo "  .kit/index.db is NOT ignored -- the next git add commits it"; exit 1; }
  ign .kit/packs/x.md || { echo "  .kit/packs/ is NOT ignored"; exit 1; }
  [ "$(att merge .kit/events.ndjson)" = union ] ||
    { echo "  .kit/events.ndjson merge is $(att merge .kit/events.ndjson), wanted union"; exit 1; }
  [ "$(att eol .kit/plans/default.tsv)" = lf ] ||
    { echo "  .kit/plans/default.tsv eol is $(att eol .kit/plans/default.tsv), wanted lf"; exit 1; }
  [ ! -d .project ] || { echo "  kit-init RE-CREATED .project after paths.state moved"; exit 1; }

  # kit-init must NAME the lines it wrote for the old location, by their exact text, or an
  # adopter has no way to find them -- it records no previous location.
  case "$out" in
    *".project/index.db*"*) ;;
    *) echo "  kit-init did not name the stale .project/index.db* line it wrote earlier"; exit 1 ;;
  esac

  # THE STALE PIN GOES FIRST, and that ordering is the whole value of this arm.
  #
  # The first adoption wrote `.project/plans/*.tsv text eol=lf`. Leave it in place and a
  # kit-index that still checks the LITERAL finds it, stays quiet, and the assertion below
  # passes for entirely the wrong reason -- which is what it did until a mutation said so.
  # With only the CURRENT location pinned, a literal check has nothing to find and must warn.
  grep -v '^.project/plans/\*.tsv text eol=lf$' .gitattributes > .gitattributes.t &&
    mv .gitattributes.t .gitattributes
  grep -qxF '.kit/plans/*.tsv text eol=lf' .gitattributes ||
    { echo "  fixture: the pin for the moved location is missing, so this arm proves nothing"; exit 1; }
  case "$(bash "$KIT/tooling/kit-index.sh" 2>&1)" in
    *"does not pin it to LF"*) echo "  a LF-pin warning fired while the pin for $PWD was present"; exit 1 ;;
  esac
  # ...and one after it is removed too. A check that cannot complain is not a check.
  grep -v 'plans/\*.tsv text eol=lf' .gitattributes > .gitattributes.t && mv .gitattributes.t .gitattributes
  case "$(bash "$KIT/tooling/kit-index.sh" 2>&1)" in
    *"does not pin it to LF"*) ;;
    *) echo "  no LF-pin warning after the pin was removed"; exit 1 ;;
  esac
  exit 0 )
check $? "index.db and packs ignored, log union, plan lf, no .project, stale lines named"
rm -rf "$mv"
fi

if step "the kit runs where only python is named python, and says so when neither exists"; then
# Five scripts shell out to an interpreter -- kit-finding.sh, kit-resolve.sh,
# kit-review-record.sh, kit-claim.sh, kit-plan.sh -- and all of them hardcoded `python3`.
# Windows ships `python.exe`, and `python3` there is frequently absent or a Microsoft Store
# execution alias that is not an interpreter at all.
#
# THE SECOND ARM IS THE ONE THAT MATTERS. Before kit_python, an absent interpreter surfaced as
# "finding rejected by the contract; nothing recorded" -- a claim about the DATA, from a check
# that had never run -- and in kit-resolve.sh as "the event could not be serialised". Both are
# false and both send the reader to the wrong place. A tool may fail; it may not misattribute.
py=""; for c in python3 python; do command -v "$c" >/dev/null 2>&1 && py=$(command -v "$c") && break; done
if [ -z "$py" ]; then
  skip "no python interpreter on this machine to build the fixture from"        "the kit runs where only python is named python"
else
  pf="$WORK.pyfall"; rm -rf "$pf"; mkdir -p "$pf/.claude" "$pf/.project/tasks" "$pf/shim"
  ( cd "$pf" || exit 1
    git init -q -b main 2>/dev/null
    git config user.email a@b.c; git config user.name T
    { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
      echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
    printf -- '---
id: T-x
title: x
tier: T2
---
b
' > .project/tasks/T-x.md
    git add -A && git commit -q --no-verify -m seed
    # A shim named `python` ONLY, forwarding to whatever real interpreter this machine has.
    printf '#!/usr/bin/env bash
exec "%s" "$@"
' "$py" > shim/python
    chmod +x shim/python
    # The REAL PATH minus every directory holding a python3, rather than a hand-built one.
    # A narrow PATH was the first attempt and it proved nothing: without git the kit is
    # correctly INERT, so the recorder exited 0 having written nothing and the arm read as a
    # pass for the fix. Remove one tool; keep the rest of the environment intact.
    nopy3=""
    _oldifs=$IFS; IFS=:
    for _d in $PATH; do
      [ -n "$_d" ] || continue
      if [ -x "$_d/python3" ] || [ -x "$_d/python3.exe" ]; then continue; fi
      nopy3="$nopy3:$_d"
    done
    IFS=$_oldifs
    nopy3="$PWD/shim$nopy3"
    if PATH="$nopy3" command -v python3 >/dev/null 2>&1; then
      echo "  fixture: python3 still reachable, the arm would prove nothing"; exit 1
    fi
    # Arm 1: python3 is NOT on PATH and a finding is still recorded.
    PATH="$nopy3" bash "$KIT/tooling/kit-finding.sh" --task T-x       --agent implementation-reviewer --class race --severity major --lang bash       --summary "recorded on a box where python3 does not exist" >/dev/null 2>&1 ||
      { echo "  arm 1: no finding recorded when only python exists"; exit 1; }
    n=$(grep -c '"kind":"finding"' .project/events.ndjson 2>/dev/null)
    [ "${n:-0}" -ge 1 ] || { echo "  arm 1: recorder exited 0 but wrote nothing"; exit 1; }
    # Arm 2: NEITHER interpreter. It must fail, and the message must name the interpreter
    # rather than blaming the finding.
    # Arm 2 strips the shim too, so NEITHER name resolves -- while keeping git, or the kit
    # would be inert and exit 0, which is not the refusal this arm is looking for.
    nopy=""
    _oldifs=$IFS; IFS=:
    for _d in $PATH; do
      [ -n "$_d" ] || continue
      if [ -x "$_d/python3" ] || [ -x "$_d/python3.exe" ] || [ -x "$_d/python" ] || [ -x "$_d/python.exe" ]; then continue; fi
      nopy="$nopy:$_d"
    done
    IFS=$_oldifs
    nopy=${nopy#:}
    out=$(PATH="$nopy" bash "$KIT/tooling/kit-finding.sh" --task T-x       --agent implementation-reviewer --class race --severity major --lang bash       --summary "this one cannot be recorded" 2>&1); rc=$?
    [ "$rc" != 0 ] || { echo "  arm 2: recorded a finding with no interpreter at all"; exit 1; }
    case "$out" in
      *"no python3 (or python 3.x) on PATH"*) ;;
      *) echo "  arm 2: failed without naming the interpreter -- said: $out"; exit 1 ;;
    esac
    case "$out" in
      *"rejected by the contract"*)
        echo "  arm 2: blamed the contract for a missing interpreter"; exit 1 ;;
    esac
    exit 0 )
  check $? "a finding records with only python present, and a missing interpreter is named as one"
  rm -rf "$pf"
fi
fi

if step "provenance is recorded, defaulted and split out of the rate it would dilute"; then
# Escape rate was computed over EVERY task regardless of whether this pipeline had ever run on
# one. On a brownfield adoption most of the backlog is pre-existing or hand-done, so the
# denominator filled with work the kit never reviewed and the headline metric was diluted from
# the first day -- in the direction that makes tiering look ineffective.
#
# Four things have to hold together, and the last is the one with teeth: a bogus value must
# not be stored, an unrecorded task must be `unknown` rather than quietly counted, the trailer
# must beat the frontmatter the way tier already does, and the rate must report the kit-run
# population SEPARATELY while NAMING the rest by value.
vx="$WORK.via"; rm -rf "$vx"; mkdir -p "$vx/.claude" "$vx/.project/tasks" "$vx/src"
( cd "$vx" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  printf -- '---\nid: T-kit\ntitle: k\ntier: T2\nvia: kit\n---\nb\n'   > .project/tasks/T-kit.md
  printf -- '---\nid: T-man\ntitle: m\ntier: T2\nvia: manual\n---\nb\n' > .project/tasks/T-man.md
  printf -- '---\nid: T-none\ntitle: n\ntier: T2\n---\nb\n'             > .project/tasks/T-none.md
  printf -- '---\nid: T-bad\ntitle: b\ntier: T2\nvia: made-up\n---\nb\n' > .project/tasks/T-bad.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-man
Tier: T2
Via: agent"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  # frontmatter honoured; a value outside the vocabulary becomes unknown rather than stored;
  # absence becomes unknown; and the TRAILER beats the frontmatter, as tier does -- T-man
  # declares `manual` in its file and the commit says `agent`.
  got=$(sqlite3 .project/index.db "SELECT group_concat(id||'='||via,' ') FROM (SELECT id,via FROM task ORDER BY id);" | sed $'s/\r$//')
  [ "$got" = "T-bad=unknown T-kit=kit T-man=agent T-none=unknown" ] || exit 1

  # The rate reports the kit-run population beside the whole one, and names the rest by value
  # WITH its escape count. `unknown` must appear as itself -- folding it into `manual` would
  # turn "nobody recorded this" into a claim. One of the four tasks is `kit`; all four are T2.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -qE '^- T2 +0 / 1 via:kit +0 / 4 all$' STATUS.generated.md || exit 1
  grep -q 'Other provenance' STATUS.generated.md || exit 1
  grep -qE '^- unknown +2 task\(s\), 0 escape\(s\)$' STATUS.generated.md || exit 1
  grep -qE '^- agent +1 task\(s\), 0 escape\(s\)$' STATUS.generated.md || exit 1

  # The trailer validator rejects a value outside the vocabulary and accepts one inside it.
  printf 'feat: x\n\nTask-Id: T-kit\nTier: T2\nVia: made-up\n' > m.txt
  bash "$KIT/tooling/kit-trailers.sh" message m.txt 2>&1 | grep -q 'invalid  Via' || exit 1
  printf 'feat: x\n\nTask-Id: T-kit\nTier: T2\nVia: kit\n' > m2.txt
  [ -z "$(bash "$KIT/tooling/kit-trailers.sh" message m2.txt 2>&1)" ] || exit 1

  # THE FAIL-CLOSED DERIVATION FILTER. `kit-event.sh <task> via` writes through the generic
  # ndjson reader, which stores the WHOLE JSON LINE as payload -- that is how a JSON blob once
  # landed in task.via and dropped a task carrying a recorded escape out of the headline metric.
  # The `payload IN (vocabulary)` clause on the derivation is what closes it, and NOTHING
  # exercised it: `kit-event.sh` appeared zero times in this suite, so deleting the clause left
  # every step green. Found in the T3 review of 2026-08-10.
  bash "$KIT/tooling/kit-event.sh" T-kit via >/dev/null 2>&1 ||
    { printf '    ^ kit-event.sh failed; the filter was never exercised\n' >&2; exit 1; }
  # The EVENT MUST EXIST before its absence can be mistaken for the filter working. Asserting
  # only `via = kit` afterwards passes identically when kit-event.sh wrote nothing at all -- a
  # vacuous check, inside the test added because the filter had no test. Found 2026-08-12.
  ev=$(grep -c '"kind":"via"' .project/events.ndjson)
  [ "${ev:-0}" -ge 1 ] ||
    { printf '    ^ no via event was written, so this proves nothing\n' >&2; exit 1; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  # The blob must NOT become the provenance, and the honest earlier value must survive.
  blob=$(sqlite3 .project/index.db "SELECT via FROM task WHERE id='T-kit';" | tr -d '\015')
  [ "$blob" = "kit" ] || { printf '    ^ a kit-event payload reached task.via: %s\n' "$blob" >&2; exit 1; }

  # A FUTURE-DATED trailer must not pin provenance. `at` is the AUTHOR date, which is whatever
  # GIT_AUTHOR_DATE said, so ordering the derivation by it let one commit declare itself last
  # forever and no later retraction could reach it. Ordering by `seq` -- AUTOINCREMENT over a
  # `--reverse` walk -- is the order history actually happened in.
  #
  # Without this commit the fixture cannot tell the two orderings apart: every other commit here
  # shares one fixed date, so `at DESC, seq DESC` and `seq DESC` agree and the mutation survives.
  echo f > src/f; git add -A
  GIT_AUTHOR_DATE="2099-01-01T00:00:00+00:00" git commit -q --no-verify -m "feat: dated ahead

Task-Id: T-kit
Tier: T2
Via: kit"

  # A human RETRACTS an earlier Via: kit with Via: unknown. `unknown` is in the vocabulary, so
  # the guard used to discard it and promotion into via:kit was one-way -- the design forbids
  # using `manual` for this, because the two mean different things.
  echo r > src/r; git add -A
  git commit -q --no-verify -m "chore: retract

Task-Id: T-kit
Tier: T2
Via: unknown"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  back=$(sqlite3 .project/index.db "SELECT via FROM task WHERE id='T-kit';" | tr -d '\015')
  [ "$back" = "unknown" ] || { printf '    ^ Via: unknown did not retract; via is %s\n' "$back" >&2; exit 1; }

  # And with no task left in the kit population, the report must SAY so and NAME the tier,
  # rather than print 0 / 0 in the shape of a measurement. Named per tier because a global
  # gate let one via:kit task anywhere silence the notice for every other tier.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'absent denominator' STATUS.generated.md ||
    { printf '    ^ no empty-denominator notice after the retraction\n' >&2; exit 1; }
  grep -qE '^> \*\*No task in [^*]*T2[^*]*records having been run' STATUS.generated.md ||
    { printf '    ^ the notice does not name the tier it is about\n' >&2; exit 1; } )
check $? "via: vocabulary honoured, unknown by default, trailer wins, rate splits and names"
rm -rf "$vx"
fi

if step "a recorded escape cannot be filtered out of the report"; then
# The failure this exists to make impossible: an escape is recorded, the task is then moved out
# of `via='kit'`, and the metric reads clean while the database says otherwise. It is not
# hypothetical -- one documented command wrote the column and dropped a task carrying a
# recorded escape out of the report entirely, and a later `chore:` commit carrying
# `Via: manual` can still relabel a task with nothing warning that the population changed.
#
# So the relabel is performed here on purpose and the escape must survive it. The `via:kit`
# column is ALLOWED to drop the task -- that is the column's job. The `all` column and the
# provenance breakdown are not.
ex="$WORK.esc"; rm -rf "$ex"; mkdir -p "$ex/.claude" "$ex/.project/tasks" "$ex/src"
( cd "$ex" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "paths.status: STATUS.generated.md"; echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  printf -- '---\nid: T-esc\ntitle: e\ntier: T2\n---\nb\n' > .project/tasks/T-esc.md
  printf -- '---\nid: T-fix\ntitle: f\ntier: T2\n---\nb\n' > .project/tasks/T-fix.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-esc
Tier: T2
Via: kit"
  echo y > src/b; git add -A
  git commit -q --no-verify -m "fix: repair

Task-Id: T-fix
Tier: T2
Via: kit
Fixes-Escape-Of: T-esc"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  # While both tasks are kit-run the two columns agree, which is the uninteresting case.
  grep -qE '^- T2 +1 / 2 via:kit +1 / 2 all$' STATUS.generated.md || exit 1

  # Relabel the ESCAPED task out of the measured population. Nothing else changes.
  git commit -q --allow-empty --no-verify -m "chore: retag

Task-Id: T-esc
Tier: T2
Via: manual"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  sqlite3 .project/index.db "SELECT via FROM task WHERE id='T-esc';" | sed $'s/\r$//' | grep -qx manual || exit 1

  # The escape left the kit column and stayed in the report.
  grep -qE '^- T2 +0 / 1 via:kit +1 / 2 all$' STATUS.generated.md || exit 1
  grep -qE '^- manual +1 task\(s\), 1 escape\(s\)$' STATUS.generated.md || exit 1

  # And the general claim, executed rather than argued: the escapes the report shows sum to the
  # escapes the database holds. A report that can read zero while the database cannot is the
  # thing being ruled out, so it is asserted as an identity and not as a spot check.
  dbesc=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='escaped';" | sed $'s/\r$//' | tr -d ' ')
  shown=$(grep -oE '[0-9]+ / [0-9]+ all' STATUS.generated.md | awk '{s+=$1} END{print s+0}')
  [ "$dbesc" = 1 ] || exit 1
  [ "$shown" = "$dbesc" ] || exit 1

  # The residue. This was written when it could NOT be reached through the front door: every id
  # in a trailer got a task row invented for it, so an escape belonging to no task was
  # unreachable and only a seeded row could exercise the branch. That invention has since been
  # removed, and the reachable version of this case is now covered end to end by the ghost step
  # below. The seeded form is kept rather than replaced, because it pins the reader --
  # kit-status.sh -- against a state regardless of which producer creates it, and an adapter is
  # a producer this suite does not run.
  #
  # The index is derived and disposable, which is what makes writing to it legitimate here.
  sqlite3 .project/index.db "INSERT INTO event(task_id,kind,at) VALUES('T-vanished','escaped','2026-01-01T00:00:00Z');"
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'belong to no task in this index' STATUS.generated.md || exit 1

  # The identity that actually holds, and the one the two columns plus the residue are built to
  # satisfy: everything stored is somewhere in the report. Asserting `shown = stored` instead
  # would have been true only by the accident of there being no residue.
  dbesc=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='escaped';" | sed $'s/\r$//' | tr -d ' ')
  shown=$(grep -oE '[0-9]+ / [0-9]+ all' STATUS.generated.md | awk '{s+=$1} END{print s+0}')
  orph=$(grep -oE '\*\*[0-9]+ recorded escape' STATUS.generated.md | tr -dc '0-9')
  [ "$dbesc" = 2 ] || exit 1
  [ $((shown + ${orph:-0})) = "$dbesc" ] || exit 1

  # The same identity again, with one NULL id in `task`. SQLite does not enforce NOT NULL on a
  # TEXT PRIMARY KEY, and `x NOT IN (set holding NULL)` is NULL rather than true for every x --
  # so an unguarded residue subquery reports zero orphans here while the database still holds
  # one, and hides every other orphan with it. The report would read clean through the very
  # guard written to stop it reading clean.
  #
  # Seeded directly for the same reason as the row above: kit-index.sh rejects a blank id on
  # every insert, so this state is unreachable through shipped code TODAY and the guard would
  # otherwise be a claim nobody ever executed.
  sqlite3 .project/index.db "INSERT INTO task(id) VALUES(NULL);"
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'belong to no task in this index' STATUS.generated.md || exit 1
  dbesc=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='escaped';" | sed $'s/\r$//' | tr -d ' ')
  shown=$(grep -oE '[0-9]+ / [0-9]+ all' STATUS.generated.md | awk '{s+=$1} END{print s+0}')
  orph=$(grep -oE '\*\*[0-9]+ recorded escape' STATUS.generated.md | tr -dc '0-9')
  [ "$dbesc" = 2 ] || exit 1
  [ $((shown + ${orph:-0})) = "$dbesc" ] || exit 1 )
check $? "escape survives a relabel out of via:kit; nothing stored is missing from the report, and a NULL id cannot silence the residue"
rm -rf "$ex"
fi

if step "a Task-Id matching no task file is named, not counted as work"; then
# One character in a pushed commit -- T-20260801 where T-20260731 was meant -- became a
# permanent open T1 task with no title and no epic: in the Open list, in the backlog count, and
# in the escape-rate denominator of a tier nobody ever assigned it. kit-trailers.sh warns at
# commit time and pre-push blocks before it is shared; both work, and neither reaches history
# that is already pushed, which is the only case this covers.
#
# Dropping it silently would trade a visible wrong number for an invisible one, so the whole
# behaviour is asserted together: absent from the backlog AND from the metrics, present in the
# report with the commit that introduced it, and reconciled with no migration when the file
# turns up later.
gh="$WORK.ghost"; rm -rf "$gh"; mkdir -p "$gh/src"
( cd "$gh" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-real\ntitle: r\ntier: T2\n---\nb\n' > .project/tasks/T-real.md
  git add -A && git commit -q --no-verify -m "chore: seed"

  # Spend is recorded BEFORE the ghost's commit, so the ghost's own status transition is the
  # next one after it -- precisely what the attribution heuristic binds to.
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":100}}}\n' > sess.jsonl
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" >/dev/null 2>&1

  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: w

Task-Id: T-ghost
Tier: T1
Task-Status: progress"
  sha=$(git rev-parse --short=7 HEAD)
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # Not a task. The node survives, so the edges that point at the id still resolve.
  [ "$(Q "SELECT COUNT(*) FROM task WHERE id='T-ghost';")" = 0 ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM node WHERE id='T-ghost' AND type='task';")" = 1 ] || exit 1
  # Scoped to the Open section on purpose: the id DOES appear in the report, two sections
  # lower, and a bare `grep -v` for it would pass by finding the wrong line -- or fail by
  # finding the right one. Absent from the backlog and present in the report is the whole
  # behaviour, so each half is asserted where it belongs.
  sed -n '/^## Open/,/^## Closed/p' STATUS.generated.md | grep -qE '^- T-ghost' && exit 1
  # Backticks are part of the assertion, not incidental formatting: the id is rendered as a
  # code span precisely so a hostile id cannot act as markup, and a test matching the bare id
  # would go green again the day that escaping is dropped.
  grep -qE '^- `T-ghost`  '"$sha"'  seen as: .*progress' STATUS.generated.md || exit 1

  # Out of the DERIVED metrics too, not just the list -- the tier it was never assigned has no
  # row at all. Checking the Open list alone would pass while the denominator stayed wrong.
  grep -qE '^- T1 +' STATUS.generated.md && exit 1

  # And the cost does not vanish into it. Bound to an id with no task row, the spend would be
  # dropped by every figure in the report (all of which join `task`) while the unattributed
  # warning counts only a NULL task_id -- neither attributed nor reported, which is worse than
  # unattributed. It stays NULL, and the existing warning says so.
  [ "$(Q "SELECT COUNT(*) FROM spend WHERE task_id IS NULL OR task_id='';")" = 1 ] || exit 1
  grep -q 'spend record(s) unattributed' STATUS.generated.md || exit 1

  # The arrangement the first version of this test avoided, which is why it proved nothing: a
  # REAL task's transition, later than the ghost's. Skipping the ghost must not become binding
  # to whatever comes next -- that is not "unattributed", it is the cost of one task charged to
  # another, at another tier, reading as correct. Measured before the fix: it landed on T-real.
  echo z > src/c; git add -A
  git commit -q --no-verify -m "feat: unrelated

Task-Id: T-real
Tier: T2
Task-Status: done"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM spend WHERE task_id='T-real';")" = 0 ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM spend WHERE task_id IS NULL OR task_id='';")" = 1 ] || exit 1

  # The file arrives afterwards, which is a normal sequence rather than an error. There is no
  # reconciliation pass to run: the file emits the row, the derivation only adds what is
  # missing, and the id is a real task on the next index -- with the waiting spend attached.
  printf -- '---\nid: T-ghost\ntitle: g\ntier: T1\n---\nb\n' > .project/tasks/T-ghost.md
  git add -A && git commit -q --no-verify -m "chore: file it"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM task WHERE id='T-ghost';")" = 1 ] || exit 1
  grep -qE '^- T-ghost +g +\[T1\]' STATUS.generated.md || exit 1
  grep -q '## Unresolved task ids' STATUS.generated.md && exit 1
  grep -qE '^- T1 +0 / 0 via:kit +0 / 1 all$' STATUS.generated.md || exit 1
  [ "$(Q "SELECT COUNT(*) FROM spend WHERE task_id='T-ghost';")" = 1 ] || exit 1 )
check $? "a ghost id is out of the backlog and every metric, named with its commit, and reconciles when filed"
rm -rf "$gh"
fi

if step "an unknown blocker still blocks, and an id cannot hide itself from the report"; then
# Two failures found by review of the change above, both of which it introduced.
#
# 1. TOPOLOGY BEATS PRIORITY is kit-plan.sh's first stated rule, and not inventing a task row
#    silently defeated it: the depends_on edge survives, its target has no task row, and the
#    planner's filter drops the CONSTRAINT rather than the task. Measured against the parent
#    commit -- a task blocked by an unfiled id moved from layer 1 to layer 0, first in the
#    plan, as though nothing were in its way. An unknown blocker is not a satisfied one.
# 2. A task id is arbitrary text from a git trailer, and this whole feature exists for history
#    that never passed the commit-msg hook. Rendered raw, an id beginning `<!--` sorts first
#    under BINARY collation and comments out every row below it AND the count. A report its own
#    input can silence is not a control.
ub="$WORK.unblock"; rm -rf "$ub"; mkdir -p "$ub/src"
( cd "$ub" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-A\ntitle: a\ntier: T2\nblocked_by: T-B-unfiled\n---\nb\n' > .project/tasks/T-A.md
  # T-C depends on T-D as well as on T-A, which is what makes the scoring assertion below
  # possible: T-C is withheld through T-A, while T-D survives and has a withheld dependent.
  printf -- '---\nid: T-C\ntitle: c\ntier: T1\nblocked_by: T-A,T-D\n---\nb\n'      > .project/tasks/T-C.md
  printf -- '---\nid: T-D\ntitle: d\ntier: T1\n---\nb\n'                           > .project/tasks/T-D.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  echo x > src/a; git add -A
  git commit -q --no-verify -m "feat: a

Task-Id: <!-- T-hidden
Tier: T1
Task-Status: progress"
  echo y > src/b; git add -A
  git commit -q --no-verify -m "feat: b

Task-Id: T-zzz-sorts-after
Tier: T1
Task-Status: done"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh" >"$PWD/plan.out" 2>"$PWD/plan.err"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # The blocked task is withheld, and so is what waits behind it. T-D is untouched, which is
  # what stops "withhold" from quietly meaning "plan nothing".
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE task_id='T-A';")" = 0 ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE task_id='T-C';")" = 0 ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE task_id='T-D';")" = 1 ] || exit 1
  # Withheld silently is the same defect wearing a different face: a task missing from the plan
  # reads as a task the plan judged unimportant.
  grep -q 'T-A blocked by T-B-unfiled' plan.err || exit 1

  # The id is inert, the rows after it survive, and the count still says three.
  grep -qF '`<!-- T-hidden`' STATUS.generated.md || exit 1
  grep -qF '`T-zzz-sorts-after`' STATUS.generated.md || exit 1
  grep -qE '^> \*\*3 task id\(s\) are referenced' STATUS.generated.md || exit 1
  # Origin is shown rather than guessed: a trailer id carries its commit, a blocked_by id names
  # the file that declared it -- where "correct the trailer" would be advice about no trailer.
  grep -qF 'declared by `.project/tasks/T-A.md`' STATUS.generated.md || exit 1
  # Dropping a finished task's history is deliberate; being unable to tell it happened is not.
  # T-zzz-sorts-after completed and has no file, so the cost of that drop is stated.
  grep -qE '^> \*\*1 id\(s\) carry a recorded ' STATUS.generated.md || exit 1

  # EVERY field is escaped, not only the id -- the assertion above pins the path, this one pins
  # the event kinds. `Task-Status:` is checked against no vocabulary, so a trailer puts arbitrary
  # text into `seen as:`; hardening the id alone held only while the id sat first on the line,
  # which is an accident of field order rather than a property of the fix.
  grep -qE 'seen as: `[a-z,]+`$' STATUS.generated.md || exit 1

  # The magnitude, not just the trigger, and in the index rather than only on a stderr this
  # very fixture redirects away. Measured before it existed: 22 open tasks, one mistyped
  # blocked_by, one task planned and twenty-one gone, reported by a single line naming a root.
  grep -qE 'open task\(s\) withheld' plan.err || exit 1
  [ "$(Q "SELECT value FROM meta WHERE key='plan_withheld:default';")" = "2 3" ] || exit 1

  # ON STDOUT, and asserted there specifically. The finding this answers was that the magnitude
  # reached nobody when stderr was dropped -- and the first fix for it moved the number into the
  # index and then read it back out through kit_warn, which is stderr again. A test that greps
  # only plan.err passes just as happily with the stdout line deleted: mutation-checked, and it
  # did exactly that. The channel is the fix, so the channel is what gets asserted.
  grep -qE '^# 2 of 3 open task\(s\) withheld' plan.out || exit 1

  # Priority must not be inflated by work that cannot be released. T-D survives and its only
  # dependent, T-C, is withheld; scoring it over the raw graph counts that dependent anyway.
  # w_unblocks=3, w_tier=1, T-D is T1, so the score is 3*0 + 1 = 1 when withheld descendants
  # are excluded and 3*1 + 1 = 4 when they are not. Pinned exactly, because "not zero" would
  # pass either way.
  [ "$(Q "SELECT printf('%.1f',score) FROM plan_item WHERE task_id='T-D';")" = "1.0" ] || exit 1

  # A NULL id cannot empty the section. Same SQLite deviation the residue query was hardened
  # against; the query added alongside it was not, and one NULL row blanked a bullet, put the
  # count out of step with the rows, and could remove the section outright.
  sqlite3 .project/index.db "INSERT INTO node(id,type,path,title) VALUES(NULL,'task',NULL,NULL);"
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -qE '^> \*\*3 task id\(s\) are referenced' STATUS.generated.md || exit 1
  grep -qE '^- $' STATUS.generated.md && exit 1

  # The FOURTH field. Three were stripped and a comment claimed all of them; the commit sha went
  # out raw, and a backtick plus a newline in it fabricated a bullet and moved the rendered count
  # with it, because the count is `grep -c .` over lines rather than rows. Both are asserted --
  # the row count AND the printed number -- because either alone passes while the other is wrong.
  sqlite3 .project/index.db "UPDATE event SET commit_sha='ab'||CHAR(96)||'cd'||CHAR(10)||'- fabricated row'
                              WHERE task_id='T-zzz-sorts-after';"
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(sed -n '/^## Unresolved/,/^> /p' STATUS.generated.md | grep -c '^- ')" = 3 ] || exit 1
  grep -qE '^> \*\*3 task id\(s\) are referenced' STATUS.generated.md || exit 1
  grep -qF '- fabricated row' STATUS.generated.md && exit 1

  # A FAILING PLAN QUERY MUST REACH THE CALLER. It stopped doing so when the withheld read-back
  # became the last command in the script: a `case` matching nothing returns 0, so empty stdout
  # and success -- indistinguishable from "no work left" -- was what an orchestrator received.
  # The existing exit-status check only ever exercised the success path, so it went quiet at the
  # same time and said nothing.
  #
  # Injected with a shim rather than raced. The realistic cause is kit-index.sh swapping the
  # database underneath a concurrent run at session start, and a race this suite loses on purpose
  # is a race it will also lose by accident on someone else's machine.
  realsq=$(command -v sqlite3)
  mkdir -p shimbin
  { printf '#!/usr/bin/env bash\n'
    printf 'for a in "$@"; do case "$a" in *"ORDER BY p.layer, p.rank"*) exit 1 ;; esac; done\n'
    printf 'exec "%s" "$@"\n' "$realsq"; } > shimbin/sqlite3
  chmod +x shimbin/sqlite3
  PATH="$PWD/shimbin:$PATH" bash "$KIT/tooling/kit-plan.sh" --next 5 >/dev/null 2>&1
  [ $? -ne 0 ] || exit 1
  rm -rf shimbin

  # Spend naming an id with no task row is in a figure or in the warning, never neither: the
  # figures that join `task` drop it, and a test for NULL alone would never mention this row.
  sqlite3 .project/index.db "INSERT INTO spend(transcript,scope,at,turns,tok_in,tok_out,cache_read,cache_write,context,task_id)
                             VALUES('tr-x','main','2026-01-01T00:00:00Z',1,10,10,0,0,0,'T-B-unfiled');"
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'spend record(s) unattributed' STATUS.generated.md || exit 1 )
check $? "an unfiled blocker withholds its dependents and is reported; a hostile id cannot suppress the section"
rm -rf "$ub"
fi

if step "a reviewer returns findings as data, and a bad batch records nothing"; then
# The structured contract that replaced the prose block. Three properties matter and none is
# visible by inspection: a rejected batch must record NOTHING (a half-stored review is a
# finding table that disagrees with the review it came from), a summary must survive the trip
# through the append-only log intact, and an empty review must be distinguishable from a
# review that never happened.
sj="$WORK.sjson"; rm -rf "$sj"; mkdir -p "$sj/src"
# `cd || exit` rather than `cd && <one command>`: chaining only the next command left every
# later line running in whatever directory the shell was already in, and with no `set -e` a
# failed cd would have run kit-init.sh and committed a fixture task INSIDE THE KIT'S OWN REPO.
( cd "$sj" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-j\ntitle: j\ntier: T2\n---\nb\n' > .project/tasks/T-j.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  F="$KIT/tooling/kit-finding.sh"
  # NOT `grep -c ... || echo 0`: grep prints 0 AND exits 1 when it matches nothing, so that
  # idiom yields the two-line string "0\n0" and every later comparison against it is false.
  # It is in LESSONS as a known trap and it bit here anyway, silently, until the counts differed.
  nfind() { _c=$(grep -c '"kind":"finding"' .project/events.ndjson 2>/dev/null); printf '%s' "${_c:-0}"; }
  before=$(nfind)

  # One good finding and one with an unknown class. All-or-nothing means NEITHER is stored.
  printf '%s' '{"findings":[{"class":"fail-open","severity":"major","summary":"a real one that must not be stored either"},{"class":"invented","severity":"major","summary":"the one that poisons the batch"}]}' \
    | bash "$F" --task T-j --agent implementation-reviewer --json >/dev/null 2>&1
  rej=$?
  after=$(nfind)

  # Hostile input in EVERY string field, not only `summary`. The first version of this case put
  # the quote in `summary` alone, and that is precisely why the critical stayed invisible to CI:
  # `lang`, `pattern`, `domain` and `file` reached the writer unsanitised and a quote in any of
  # them corrupts the line permanently. A backslash and a quote are what the awk reader cannot
  # see past, and a CR inside the string splits one event into two malformed lines.
  # Written with a QUOTED heredoc, not printf: printf collapses `\\` into a lone backslash and
  # produces JSON that is invalid for a reason unrelated to what is being tested, which is how
  # this case first went red. The payload has to reach the validator exactly as a reviewer
  # would send it.
  cat > hostile.json <<'HOSTILE'
{"findings":[{"class":"correctness","severity":"nit","lang":"ba\"sh","pattern":"a\\b","domain":"x\"y","file":"a\"b.sh","line":42,"summary":"the guard reads \"x\" and a \\ breaks it"}]}
HOSTILE
  bash "$F" --task T-j --agent implementation-reviewer --json < hostile.json >/dev/null 2>&1
  good=$?

  # Empty is a measurement; a missing key is not the same statement.
  printf '%s' '{"findings":[]}' | bash "$F" --task T-j --agent tester --json >/dev/null 2>&1
  empty=$?
  printf '%s' '{}' | bash "$F" --task T-j --agent tester --json >/dev/null 2>&1
  nokey=$?

  # The two gap reasons mean opposite things: `empty` is evidence, `rejected` is a hole where
  # findings existed and were refused. Recording only the first -- which is what the first
  # version did -- kept the harmless half and dropped the harmful one.
  ge=$(grep -c '"kind":"finding-gap","at":"[^"]*","agent":"tester"' .project/events.ndjson)
  gr=$(grep -c '"reason":"rejected"' .project/events.ndjson)
  gm=$(grep -c '"reason":"empty"' .project/events.ndjson)

  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  rows=$(Q "SELECT COUNT(*) FROM finding;")
  summ=$(Q "SELECT summary FROM finding;")
  loc=$(Q "SELECT file_path||':'||line_no FROM finding;")
  # Read back the OTHER hostile fields too. Asserting only `summary` is what let the critical
  # through: the row can be present and readable while lang or pattern carries an injected key.
  oth=$(Q "SELECT lang||'|'||pattern FROM finding;")
  # Every line of the append-only log must still be one parseable JSON object.
  pyok=$(python3 -c "
import json,sys
bad=0
for l in open('.project/events.ndjson','rb').read().decode('utf-8').split(chr(10)):
    if l.strip():
        try: json.loads(l)
        except Exception: bad+=1
print(bad)" 2>/dev/null || echo 99)

  [ "$rej" = 2 ] && [ "$before" = "$after" ] && [ "$good" = 0 ] &&
  [ "$empty" = 0 ] && [ "$nokey" = 2 ] && [ "$rows" = 1 ] && [ "$pyok" = 0 ] &&
  [ "$loc" = "a'b.sh:42" ] && [ "$oth" = "ba'sh|a'b" ] &&
  [ "${gr:-0}" -ge 1 ] && [ "${gm:-0}" -ge 1 ] &&
  [ "$summ" = "the guard reads 'x' and a ' breaks it" ] )
check $? "one bad finding records none, hostile input in every field round-trips, empty differs from absent"

# A caller handing over a review must never have it swallowed. Outside an adopted project the
# recorder used to exit 0 having consumed stdin and written nothing -- success reported over a
# destroyed review.
nj="$WORK.notadopted"; rm -rf "$nj"; mkdir -p "$nj"
( cd "$nj" || exit 1
  git init -q -b main 2>/dev/null
  printf '%s' '{"findings":[{"class":"fail-open","severity":"major","summary":"this review must not be swallowed"}]}' \
    | bash "$KIT/tooling/kit-finding.sh" --task T --agent x --json >/dev/null 2>&1
  [ $? -ne 0 ] )
check $? "a piped review is refused, not silently discarded, outside an adopted project"
rm -rf "$nj"
rm -rf "$sj"
fi

if step "a finding has a stable id and can be marked addressed"; then
# Two properties, and the first is load-bearing for the second.
#
# IDENTITY. The id used to be `at:n`, n counting indexed findings in sorted order, so an event
# merged in from a branch with an earlier timestamp renumbered every finding after it --
# measured on this repository's own log, one inserted line moved all 219. A mark keyed on such
# an id does not fail to resolve; it silently reattaches to the NEIGHBOURING finding, which is
# worse than no mark. So the mutation to watch for here is any return to a positional counter.
#
# ADDRESSED. `vindicated` says whether a finding was REAL. Nothing said whether it was FIXED,
# so "is there an open critical on this task" was uncomputable and the trial protocol's first
# pre-flight box was waved through on its first execution. The two facts are orthogonal and
# this proves all four combinations are representable, not merely that a column exists.
rs="$WORK.resolve"; rm -rf "$rs"; mkdir -p "$rs"
( cd "$rs" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-r\ntitle: r\ntier: T2\n---\nb\n' > .project/tasks/T-r.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  EV=.project/events.ndjson
  F="$KIT/tooling/kit-finding.sh"; R="$KIT/tooling/kit-resolve.sh"
  Q() { sqlite3 .project/index.db "$1" 2>/dev/null | tr -d '\015'; }
  reindex() { rm -f .project/index.db; bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1; }
  # Real commits, because `--commit` must now RESOLVE. The fixture used to cite `deadbee` and
  # `aaaaaaa`, which is exactly the defect an approach reviewer named: a mark with no evidence
  # and a mark citing a SHA that never existed were the same row, and the second reads as
  # substantiated. A fixture that cannot tell them apart cannot catch it either.
  newsha() { git commit -q --no-verify --allow-empty -m "fixture commit $1"; git rev-parse HEAD; }

  printf '%s' '{"findings":[{"class":"fail-open","severity":"critical","summary":"the first one, which gets fixed"},{"class":"correctness","severity":"critical","summary":"the second one, which stays open"}]}' \
    | bash "$F" --task T-r --agent implementation-reviewer --json >/dev/null 2>&1
  reindex
  ids0=$(Q "SELECT group_concat(id,' ') FROM finding ORDER BY at,id;")
  n0=$(Q "SELECT COUNT(*) FROM finding;")

  # THE MERGE. An event from a branch whose clock ran earlier -- the case .gitattributes'
  # merge=union makes routine. Nothing about the two findings above changed, so nothing about
  # their ids may change either.
  printf '%s\n' '{"task":"T-r","kind":"finding","at":"2000-01-01T00:00:00Z","agent":"other-branch","class":"perf","severity":"minor","lang":"bash","summary":"recorded on a branch with an earlier clock"}' >> "$EV"
  reindex
  ids1=$(Q "SELECT group_concat(id,' ') FROM finding WHERE at > '2001' ORDER BY at,id;")
  n1=$(Q "SELECT COUNT(*) FROM finding;")

  # A BYTE-IDENTICAL duplicate is two rows, not one. Pre-contract findings carry no summary, so
  # two distinct defects on one task in one second serialise alike; collapsing them would drop a
  # finding silently, which is the failure mode this file exists to refuse.
  dupline='{"task":"T-r","kind":"finding","at":"2000-01-02T00:00:00Z","agent":"o","class":"perf","severity":"nit","lang":"bash"}'
  printf '%s\n%s\n' "$dupline" "$dupline" >> "$EV"
  reindex
  ndup=$(Q "SELECT COUNT(*) FROM finding WHERE at='2000-01-02T00:00:00Z';")

  # THE GOLDEN ID. A fixed event line must always produce this exact id -- here, on the other
  # CI platform, and after any rewrite of the hash. The id is FNV-1a 32 over the line, and awk
  # arithmetic is IEEE double: an implementation that multiplies without splitting into 16-bit
  # halves needs 55 bits of mantissa, silently rounds, and computes a different value on a
  # different awk. Every id in the repository would then depend on which machine last indexed.
  #
  # This is asserted END TO END, through kit-index.sh, on purpose. The first version of this
  # check pasted the algorithm into the test and compared it against the published vectors --
  # which proves an algorithm correct without proving it is the one in use, and a mutation that
  # broke the multiply inside kit-index.sh SURVIVED it. LESSONS S1, found by mutating rather
  # than by reading.
  printf '%s\n' '{"task":"T-r","kind":"finding","at":"2000-01-03T00:00:00Z","agent":"golden","class":"perf","severity":"nit","lang":"bash","summary":"a fixed line whose id must not move"}' >> "$EV"
  reindex
  gold=$(Q "SELECT id FROM finding WHERE at='2000-01-03T00:00:00Z';")

  fid=$(Q "SELECT id FROM finding WHERE summary LIKE 'the first one%';")
  oid=$(Q "SELECT id FROM finding WHERE summary LIKE 'the second one%';")

  # A typo must fail where it is typed. Appending a mark for an id no finding has puts a line
  # in a permanent log that can only ever be reported as an orphan, while the operator saw
  # exit 0 and believed it landed.
  evb=$(grep -c '"kind":"finding-fixed"' "$EV" 2>/dev/null); evb=${evb:-0}
  bash "$R" --finding "T-r:nosuchid" --fixed >/dev/null 2>&1; bogus=$?
  eva=$(grep -c '"kind":"finding-fixed"' "$EV" 2>/dev/null); eva=${eva:-0}

  SHA_FID=$(newsha fid)
  bash "$R" --finding "$fid" --fixed --commit "$SHA_FID" --note "closed by the one-writer move" \
    >/dev/null 2>&1; markrc=$?
  bash "$KIT/tooling/kit-vindicate.sh" --task T-r --class fail-open --real >/dev/null 2>&1
  # Rebuilt FROM SCRATCH, not updated in place. A mark that lived only in the database would
  # be erased by the next reindex -- present, plausible, and gone.
  reindex
  fx=$(Q "SELECT COALESCE(fixed_at,'NULL') FROM finding WHERE id='$fid';")
  fc=$(Q "SELECT COALESCE(fixed_commit,'NULL') FROM finding WHERE id='$fid';")
  # Read through --list, the reader this field was added for. Selecting the column directly
  # proves the column is populated and says nothing about whether anything surfaces it, which
  # is the whole complaint the note was filed under.
  case "$(bash "$R" --list --task T-r 2>/dev/null)" in
    *"(fixed: closed by the one-writer move)"*) fnote=1 ;; *) fnote=0 ;;
  esac
  vd=$(Q "SELECT COALESCE(vindicated,'NULL') FROM finding WHERE id='$fid';")
  openc=$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND fixed_at IS NULL;")

  # ALL FOUR COMBINATIONS, CONSTRUCTED. The criterion this fixture is cited for claims the four
  # vindicated-by-fixed states are representable, and BOTH reviewers of the T3 round found that
  # only `--real` was ever exercised -- `vindicated=0` appeared nowhere, so at most three
  # existed and the fourth was asserted by the tick alone. `false and fixed` is the interesting
  # one: a reviewer was wrong AND the code was changed anyway, which one column cannot say.
  # `correctness` is vindicated real and left UNFIXED, which is the real-and-open corner --
  # without it three of the four counts below could be satisfied by one finding each.
  bash "$KIT/tooling/kit-vindicate.sh" --task T-r --class correctness --real >/dev/null 2>&1
  bash "$KIT/tooling/kit-vindicate.sh" --task T-r --class perf --false >/dev/null 2>&1
  pid=$(Q "SELECT id FROM finding WHERE class='perf' AND at='2000-01-03T00:00:00Z';")
  SHA_PID=$(newsha pid)
  bash "$R" --finding "$pid" --fixed --commit "$SHA_PID" >/dev/null 2>&1
  reindex
  c_rf=$(Q "SELECT COUNT(*) FROM finding WHERE vindicated=1 AND fixed_at IS NOT NULL;")
  c_ro=$(Q "SELECT COUNT(*) FROM finding WHERE vindicated=1 AND fixed_at IS NULL;")
  c_ff=$(Q "SELECT COUNT(*) FROM finding WHERE vindicated=0 AND fixed_at IS NOT NULL;")
  c_fo=$(Q "SELECT COUNT(*) FROM finding WHERE vindicated=0 AND fixed_at IS NULL;")
  four=0
  [ "${c_rf:-0}" -ge 1 ] && [ "${c_ro:-0}" -ge 1 ] &&
  [ "${c_ff:-0}" -ge 1 ] && [ "${c_fo:-0}" -ge 1 ] && four=1

  # A SECOND TASK. With one task in the fixture, a change that keyed the indexer's per-finding
  # arrays by task would pass everything above while silently scoping identity to a task --
  # ids, duplicate detection and mark resolution are all repository-wide, and nothing here
  # showed that until there were two tasks to be wide across.
  printf -- '---\nid: T-r2\ntitle: r2\ntier: T2\n---\nb\n' > .project/tasks/T-r2.md
  git add -A && git commit -q --no-verify -m "chore: second task"
  printf '%s' '{"findings":[{"class":"fail-open","severity":"critical","summary":"a critical on the OTHER task, same class as the first"}]}' \
    | bash "$F" --task T-r2 --agent implementation-reviewer --json >/dev/null 2>&1
  reindex
  tid=$(Q "SELECT id FROM finding WHERE summary LIKE 'a critical on the OTHER task%';")
  SHA_TID=$(newsha tid)
  bash "$R" --finding "$tid" --fixed --commit "$SHA_TID" >/dev/null 2>&1
  reindex
  t2fx=$(Q "SELECT COALESCE(fixed_commit,'NULL') FROM finding WHERE id='$tid';")
  t1fx=$(Q "SELECT COALESCE(fixed_commit,'NULL') FROM finding WHERE id='$fid';")

  # Retraction. A fix that turned out not to be one must be expressible, or the mark is a
  # one-way door and the first mistake is permanent.
  bash "$R" --finding "$fid" --open >/dev/null 2>&1
  reindex
  fx2=$(Q "SELECT COALESCE(fixed_at,'NULL') FROM finding WHERE id='$fid';")
  vd2=$(Q "SELECT COALESCE(vindicated,'NULL') FROM finding WHERE id='$fid';")

  # THREE MARKS BACK TO BACK. Ordering must not depend on how fast the machine is. At
  # whole-second resolution these land in one second and the tie breaks on the TEXT of the
  # line -- `"fixed":0}` sorts before `"fixed":1,"commit":...` -- so the retraction is applied
  # first, the fix wins, and `--open` silently does nothing. That is what happened: green here,
  # red on ubuntu-latest, because a container is fast enough to put them in the same second.
  # Timestamps are sub-second now, and this asserts the property rather than the format.
  SHA_A=$(newsha a)
  bash "$R" --finding "$oid" --fixed --commit "$SHA_A" >/dev/null 2>&1
  bash "$R" --finding "$oid" --open >/dev/null 2>&1
  SHA_B=$(newsha b)
  bash "$R" --finding "$oid" --fixed --commit "$SHA_B" >/dev/null 2>&1
  reindex
  lastw=$(Q "SELECT COALESCE(fixed_commit,'NULL') FROM finding WHERE id='$oid';")
  # No two marks may share a timestamp -- if any do, the one that loses is decided by string
  # order, which is not a fact about when it happened. Compared against the NUMBER OF MARKS
  # rather than a literal, so adding a case to this fixture cannot quietly weaken it.
  nat=$(grep -o '"kind":"finding-fixed","at":"[^"]*"' "$EV" | sort -u | wc -l | tr -d ' ')
  nmk=$(grep -c '"kind":"finding-fixed"' "$EV"); nmk=${nmk:-0}

  # A REAL COLLISION. Two DIFFERENT lines, one `at`, one FNV-1a 32 hash -- found by brute force
  # (1.7M tries, tools in the task notes) because this pair cannot be written by hand and the
  # fail-closed path cannot be exercised without one. A control that cannot run is not a
  # control, and refusing to apply a mark to an ambiguous id is the whole reason the collision
  # is detected at all.
  printf '%s\n' '{"task":"T-r","kind":"finding","at":"2000-01-04T00:00:00Z","agent":"collide","class":"compliance","severity":"nit","lang":"bash","summary":"collision fixture 1549599"}' >> "$EV"
  printf '%s\n' '{"task":"T-r","kind":"finding","at":"2000-01-04T00:00:00Z","agent":"collide","class":"compliance","severity":"nit","lang":"bash","summary":"collision fixture 1712382"}' >> "$EV"
  reindex
  ncol=$(Q "SELECT COUNT(*) FROM finding WHERE at='2000-01-04T00:00:00Z';")
  colmeta=$(Q "SELECT value FROM meta WHERE key='finding_id_collisions';")
  # Both rows survive -- neither line is dropped -- but a mark on the shared base id is
  # withheld, because attaching it to one of them would be a guess that asserts a specific
  # defect was fixed.
  # REFUSED WHERE IT IS TYPED. This used to be accepted with exit 0 and a success message while
  # every rebuild silently discarded it -- and the fixture asserted BOTH halves of that
  # mismatch on adjacent lines without noticing it was documenting a false success.
  HEADSHA=$(git rev-parse HEAD)
  bash "$R" --finding "2000-01-04T00:00:00Z:77087be7" --fixed --commit "$HEADSHA" >/dev/null 2>&1
  colmark=$?
  reindex
  ambflag=$(Q "SELECT COUNT(*) FROM finding WHERE at='2000-01-04T00:00:00Z' AND id_ambiguous=1;")

  # The indexer keeps its own refusal, and it is now the only way an ambiguous mark can arrive:
  # written on a branch where the colliding line did not yet exist and merged in afterwards.
  # Planted by hand for that reason -- kit-resolve refuses it at the keyboard, so a fixture that
  # only went through the command could no longer reach this path at all.
  printf '{"kind":"finding-fixed","at":"2030-06-02T00:00:00.000000Z","task":"T-r","actor":"fixture","finding":"2000-01-04T00:00:00Z:77087be7","fixed":1}\n' >> "$EV"
  reindex
  colfixed=$(Q "SELECT COUNT(*) FROM finding WHERE at='2000-01-04T00:00:00Z' AND fixed_at IS NOT NULL;")
  ambmeta=$(Q "SELECT value FROM meta WHERE key='finding_ambiguous_marks';")

  # A SHA THAT DOES NOT RESOLVE IS NOT EVIDENCE. `deadbee` was accepted by the old code and by
  # this fixture, which is how a mark citing a commit that never existed came to read as
  # substantiated.
  bash "$R" --finding "$oid" --fixed --commit deadbeefdeadbeef >/dev/null 2>&1; badsha=$?
  # A mark whose commit later leaves the history is reported rather than left resolving to air.
  #
  # TWO marks citing the SAME vanished SHA, deliberately. The counter reports "fix mark(s)" and
  # was counting DISTINCT commits, so three marks on one dead SHA under-reported as one. With a
  # single planted mark the two behaviours give the same number and the mutation reverting it
  # SURVIVED -- a fixture that cannot tell the fix from the defect is not evidence for either.
  mid=$(Q "SELECT id FROM finding WHERE at='2000-01-01T00:00:00Z';")
  _n=1
  for _f in "$pid" "$mid"; do
    printf '{"kind":"finding-fixed","at":"2030-06-01T00:00:0%s.000000Z","task":"T-r","actor":"fixture","finding":"%s","fixed":1,"commit":"%s"}\n' \
      "$_n" "$_f" "0000000000000000000000000000000000000001" >> "$EV"
    _n=$((_n + 1))
  done
  reindex
  missmeta=$(Q "SELECT value FROM meta WHERE key='finding_fix_commit_missing';")
  # The mark carries its task, so a task timeline shows its findings being resolved. Compared
  # against the number of marks made on T-r findings rather than a literal: EVERY one must carry
  # it, and a literal would quietly stop covering the marks added later in this fixture.
  marktask=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-fixed' AND task_id='T-r';")
  marksonr=$(Q "SELECT COUNT(*) FROM event e WHERE e.kind='finding-fixed'
                 AND EXISTS (SELECT 1 FROM finding f WHERE f.task_id='T-r'
                              AND e.payload LIKE '%'||f.id||'%');")

  # An orphan mark ALREADY IN the log -- from a hand edit, or a merge that brought the mark
  # without the finding -- is reported. Applied as an UPDATE it would match nothing and exit 0,
  # which is a gate reading clean because its evidence never arrived.
  printf '%s\n' '{"kind":"finding-fixed","at":"2030-01-01T00:00:00Z","actor":"fixture","finding":"nothing-has-this-id","fixed":1}' >> "$EV"
  rm -f .project/index.db
  orph=$(bash "$KIT/tooling/kit-index.sh" 2>&1 >/dev/null | grep -c 'name no known finding')

  # A WHOLE-SECOND MARK DENOTES THE START OF ITS SECOND. Timestamps are compared as strings and
  # `.` sorts before `Z`, so `...:07Z` landed AFTER every `...:07.######Z` -- backwards. Here a
  # hand-written whole-second RETRACTION is planted in the same second as the microsecond fix
  # that precedes it in time; the fix must still win. Every mark this command writes is
  # sub-second, so without a planted one this reordering is untestable and invisible.
  t2sec=$(Q "SELECT substr(fixed_at,1,19) FROM finding WHERE id='$tid';")
  printf '{"kind":"finding-fixed","at":"%sZ","actor":"fixture","finding":"%s","fixed":0}\n' "$t2sec" "$tid" >> "$EV"
  reindex
  t2keep=$(Q "SELECT COALESCE(fixed_commit,'NULL') FROM finding WHERE id='$tid';")

  # `--at` is the ordering key, not a label, and it was taken on trust.
  python3 "$KIT/tooling/kit_findings.py" --resolve --finding x --fixed 1 --at "yesterday" \
    >/dev/null 2>&1; atbad=$?
  python3 "$KIT/tooling/kit_findings.py" --resolve --finding x --fixed 1 --at "2026-01-01T00:00:00Z" \
    >/dev/null 2>&1; atgood=$?

  # WHAT REACHES THE FILE ANYONE READS. The indexer announced orphaned and ambiguous marks on
  # stderr alone, and stderr from a run inside kit-status.sh, a hook or CI is seen by nobody --
  # so the criticals list could be short for the one reason that must never be quiet.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_orph=$(grep -c 'name no known finding' STATUS.generated.md); s_orph=${s_orph:-0}
  s_amb=$(grep -c 'REFUSED as ambiguous' STATUS.generated.md); s_amb=${s_amb:-0}

  # CLOSING A TASK IS NOT FIXING ITS CRITICALS, and a REFUTED critical is not outstanding work.
  # A third task carries one of each: the gate used to filter `state='progress'`, so closing the
  # task cleared it exactly as well as fixing the defect.
  printf -- '---\nid: T-r3\ntitle: r3\ntier: T2\n---\nb\n' > .project/tasks/T-r3.md
  git add -A && git commit -q --no-verify -m "chore: third task"
  printf '%s' '{"findings":[{"class":"fail-open","severity":"critical","summary":"critical on a task that then gets closed"},{"class":"race","severity":"critical","summary":"critical that a reviewer later refuted"}]}' \
    | bash "$F" --task T-r3 --agent implementation-reviewer --json >/dev/null 2>&1
  bash "$KIT/tooling/kit-vindicate.sh" --task T-r3 --class race --false >/dev/null 2>&1
  printf '{"task":"T-r3","kind":"done","at":"2030-07-01T00:00:00Z"}\n' >> "$EV"
  reindex
  r3state=$(Q "SELECT state FROM task WHERE id='T-r3';")
  gatecount=$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND fixed_at IS NULL
                  AND COALESCE(vindicated,1) <> 0;")
  gateclosed=$(Q "SELECT COUNT(*) FROM finding f JOIN task t ON t.id=f.task_id
                   WHERE f.severity='critical' AND f.fixed_at IS NULL
                     AND COALESCE(f.vindicated,1) <> 0
                     AND t.state IN (SELECT state FROM state_class WHERE is_closed = 1);")
  gaterefuted=$(Q "SELECT COUNT(*) FROM finding WHERE severity='critical' AND fixed_at IS NULL
                    AND vindicated=0;")
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_closed=$(grep -c 'already done or abandoned' STATUS.generated.md); s_closed=${s_closed:-0}
  s_refuted=$(grep -c 'excluded as refuted' STATUS.generated.md); s_refuted=${s_refuted:-0}

  # A CLASS-SCOPED REFUTATION IS NOT A JUDGEMENT ON EVERY FINDING OF THAT CLASS. kit-vindicate
  # keys on (task, class), so a `--false` about one finding also refutes a critical sharing its
  # class -- which would then leave the gate having never been judged. T-r3 carries two
  # `fail-open` findings for exactly this: one critical, one minor.
  printf '%s' '{"findings":[{"class":"fail-open","severity":"minor","summary":"a harmless fail-open sharing the class of the critical"}]}' \
    | bash "$F" --task T-r3 --agent implementation-reviewer --json >/dev/null 2>&1
  bash "$KIT/tooling/kit-vindicate.sh" --task T-r3 --class fail-open --false >/dev/null 2>&1
  reindex
  ambigref=$(Q "SELECT COUNT(*) FROM finding f WHERE f.severity='critical' AND f.fixed_at IS NULL
                 AND f.vindicated=0 AND NOT 1 = (SELECT COUNT(*) FROM finding g
                        WHERE COALESCE(g.task_id,'')=COALESCE(f.task_id,'')
                          AND COALESCE(g.class,'')=COALESCE(f.class,''));")
  pfrc=$(cd "$rs" && bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1; echo $?)
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_ambigref=$(grep -c 'refutation that cannot be trusted' STATUS.generated.md); s_ambigref=${s_ambigref:-0}
  # The notice above is driven by its own counter, so it survives a regression in the LIST. The
  # list is what a reader acts on: T-r3 must still be IN it, because its critical carries a
  # refutation that cannot be trusted and is therefore still outstanding. Without this, reverting
  # the gate predicate to the too-eager `COALESCE(vindicated,1) <> 0` changed nothing any
  # assertion looked at -- a mutation survived and said so.
  s_r3crit=$(sed -n '/## Outstanding criticals/,/^## /p' STATUS.generated.md | grep -c 'T-r3')
  s_r3crit=${s_r3crit:-0}
  # The listing must agree with the gate about that finding rather than calling it plain OPEN.
  case "$(bash "$R" --list --task T-r3 2>/dev/null)" in *"OPEN?"*) listagree=1 ;; *) listagree=0 ;; esac
  # And EVERY mark records WHO made it -- what the `Via:` analogy claimed and did not have.
  # The two marks this fixture plants by hand carry `"actor":"fixture"` for the same reason a
  # real one carries an email: a mark with no actor is a mark nobody can be asked about, and
  # the invariant is worth more than the two exceptions would be.
  markactor=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-fixed'
                  AND (actor IS NULL OR actor='');")


  # AN ABSENT COUNTER IS NOT A ZERO COUNTER. Reading them with ${x:-0} made a stale index assert
  # that no mark had failed to apply -- the same fail-open as this section's critical, one level
  # down, shipped by the fix for it.
  sqlite3 .project/index.db "DELETE FROM meta WHERE key LIKE 'finding_%';" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_absent=$(grep -c 'ABSENT from this index' STATUS.generated.md); s_absent=${s_absent:-0}
  reindex

  # THE CLEAN CASE MUST BE ABLE TO PRINT. Its line began with `-`, which bash printf parses as
  # an option, so it errored to stderr and emitted NOTHING -- an empty section, which reads as
  # no criticals. It had never run, in this case or in the failure case below.
  # Its own commit: reusing SHA_FID here put several marks in the log carrying that SHA, and the
  # "survives a rebuild" assertion selects the mark BY its commit -- so the subquery returned
  # three timestamps and compared them against one. The message read "got X, wanted X" with the
  # difference off the end of the line, which is its own small lesson about naming a condition.
  SHA_ALL=$(newsha all)
  for c in $(Q "SELECT id FROM finding WHERE severity='critical' AND fixed_at IS NULL;"); do
    bash "$R" --finding "$c" --fixed --commit "$SHA_ALL" >/dev/null 2>&1
  done
  reindex
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_none=$(grep -c 'none outstanding' STATUS.generated.md); s_none=${s_none:-0}

  # THE UNMEASURABLE CASE. An index built before `fixed_at` existed passes the readability
  # check at the top of kit-status.sh, because `task` is intact -- only this section notices.
  # Silence there is the critical its own T3 round found.
  # DROP COLUMN needs SQLite 3.35+, and its status was DISCARDED. On an older toolchain the
  # column survived, the two assertions below went red, and they blamed the code for something
  # that was never about the code -- the CRLF-guard failure again, where a check red for an
  # unrelated reason stops being read.
  sqlite3 .project/index.db "ALTER TABLE finding DROP COLUMN fixed_at;" >/dev/null 2>&1
  altrc=$?
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  s_unmeas=$(grep -c 'NOT MEASURED' STATUS.generated.md); s_unmeas=${s_unmeas:-0}
  s_falseclean=$(grep -c 'none outstanding' STATUS.generated.md); s_falseclean=${s_falseclean:-0}
  # Same broken index: a listing must FAIL rather than print nothing and exit 0.
  bash "$R" --list --severity critical >/dev/null 2>&1; listrc=$?
  reindex
  # ...and a genuinely empty result is a different statement, SAID rather than left blank. The
  # first version asserted only exit 0 -- which was already true before the fix, so it could not
  # fail for the thing it was named after. The message is what is checked now.
  listemptymsg=$(bash "$R" --list --severity nosuchseverity 2>&1); listempty=$?
  case "$listemptymsg" in *"not a failed query"*) listesaid=1 ;; *) listesaid=0 ;; esac

  # Probing a database that is not there must not CREATE one: `sqlite3 <path> <query>` does.
  # A stray empty index.db is later read as an index with no tasks in it.
  ( cd "$rs" || exit 1; rm -f .project/index.db
    bash "$R" --finding "anything" --fixed >/dev/null 2>&1 )
  strays=0; [ -f .project/index.db ] && strays=1
  reindex

  # THE AMBIGUITY PROBE AGAINST AN INDEX THAT PREDATES ITS COLUMN. This read `2>/dev/null` with
  # `${amb:-0}`, so the column error became "not ambiguous", the refusal was skipped, and the
  # tool printed "recorded" for a mark every rebuild would discard. Nothing exercised it -- the
  # stale-index case above drops `fixed_at` and tests the REPORT, not the mark path -- so a
  # mutation restoring the old probe survived and said so.
  sqlite3 .project/index.db "ALTER TABLE finding DROP COLUMN id_ambiguous;" >/dev/null 2>&1
  precolalt=$?
  bash "$R" --finding "$oid" --fixed --commit "$SHA_A" >/dev/null 2>&1; precolrc=$?
  reindex

  want() { [ "$2" = "$3" ] || { printf '    ^ %s: got %s, wanted %s\n' "$1" "$2" "$3" >&2; exit 1; }; }
  want "an earlier-dated merge adds a finding" "$n1" "$((n0 + 1))"
  want "  ...and renumbers none of the others" "$ids1" "$ids0"
  want "identical lines stay two findings"     "$ndup" 2
  want "a fixed line has a fixed id"           "$gold" "2000-01-03T00:00:00Z:addbabbf"
  want "an unknown id is refused"              "$bogus" 2
  want "  ...and nothing is appended"          "$eva" "$evb"
  want "a known id is accepted"                "$markrc" 0
  want "the mark survives a rebuild"           "$fx" "$(Q "SELECT at FROM event WHERE kind='finding-fixed' AND payload LIKE '%'||'$SHA_FID'||'%';")"
  want "  ...carrying its commit"              "$fc" "$SHA_FID"
  want "  ...and its note, surfaced by --list" "$fnote" 1
  want "all four vindicated x fixed states"    "$four" 1
  want "a mark on a second task applies"       "$t2fx" "$SHA_TID"
  want "  ...without disturbing the first"     "$t1fx" "$SHA_FID"
  want "vindicated is untouched by fixing"     "$vd" 1
  want "one critical fixed leaves one open"    "$openc" 1
  want "--open retracts the fix"               "$fx2" "NULL"
  want "  ...without retracting the verdict"   "$vd2" 1
  want "the last of three rapid marks wins"    "$lastw" "$SHA_B"
  want "  ...no two marks share a timestamp"   "$nat" "$nmk"
  want "an orphan mark is named, not ignored"  "$orph" 1
  want "a colliding pair stays two rows"       "$ncol" 2
  want "  ...and the collision is counted"     "$colmeta" 1
  want "a mark on that id is REFUSED when typed" "$colmark" 2
  want "  ...so nothing is marked fixed"       "$colfixed" 0
  want "  ...and both rows are flagged"        "$ambflag" 2
  want "a merged-in ambiguous mark is refused" "$ambmeta" 1
  want "a SHA that does not resolve is refused" "$badsha" 2
  want "both marks on one dead SHA counted"    "$missmeta" 2
  want "every mark carries its task"           "$marktask" "$marksonr"
  want "the stale-index fixture was built"     "$altrc" 0
  want "an empty listing SAYS it is empty"     "$listesaid" 1
  want "a whole-second mark starts its second" "$t2keep" "$SHA_TID"
  want "a malformed --at is refused"           "$atbad" 2
  want "  ...and a legal one is not"           "$atgood" 0
  # `completed`, not `done`. The fixture still WRITES `Task-Status: done` -- legacy spellings stay
  # valid input forever -- and the indexer resolves it through state_alias, so what is STORED is
  # the canonical value. Asserting the written word here would have passed whether or not the
  # alias table did anything, which is the point of checking the stored one. See docs/adr/0008.
  want "the closing task is really closed"     "$r3state" "completed"
  want "  ...its critical still counts"        "$gateclosed" 1
  want "  ...and status names it"              "$s_closed" 1
  want "an ambiguous refutation does NOT retire" "$ambigref" 1
  want "  ...so the gate still says STOP"      "$pfrc" 1
  want "  ...and status names the doubt"       "$s_ambigref" 1
  want "  ...and still LISTS the task"         "$s_r3crit" 1
  want "  ...and --list agrees with the gate"  "$listagree" 1
  want "no mark lacks an actor"                "$markactor" 0
  want "a refuted critical leaves the gate"    "$gaterefuted" 1
  want "  ...and the exclusion is named"       "$s_refuted" 1
  want "absent counters are not read as zero"  "$s_absent" 1
  want "status reports the orphan"             "$s_orph" 1
  want "status reports the refusal"            "$s_amb" 1
  want "a clean repo says so out loud"         "$s_none" 1
  want "an unmeasurable gate says NOT MEASURED" "$s_unmeas" 1
  want "  ...and never says none outstanding"  "$s_falseclean" 0
  want "a broken listing fails, not empties"   "$listrc" 1
  want "an empty listing says it is empty"     "$listempty" 0
  want "probing a missing index makes no db"   "$strays" 0
  want "the id_ambiguous fixture was built"    "$precolalt" 0
  want "a pre-column index refuses the mark"   "$precolrc" 2 )
check $? "finding ids survive a merge, and addressed is recorded, retractable and independent of vindicated"
rm -rf "$rs"
fi

if step "every agent's declared tier matches the table that documents it"; then
# MODELS.md names a tier per agent and the frontmatter declares one; nothing compared them, so a
# tier could be raised in one place and read the other way in the other. The vocabulary already
# taught this: a list restated in four locations had drifted in all four, and the fix was not
# vigilance but a check. Same shape, and cheap enough that there was no reason to wait for the
# drift to happen first.
drift=0
for a in "$KIT"/agents/*.md; do
  nm=$(basename "$a" .md)
  declared=$(sed -n 's/^model: //p' "$a" | tr -d '\r' | head -1)
  [ -n "$declared" ] || { echo "  $nm declares no model:"; drift=1; continue; }
  # The row that names this agent, then the tier in that row's second column.
  documented=$(grep -F "\`$nm\`" "$KIT/docs/MODELS.md" | grep '^|' |
               sed -n 's/^[^|]*|[^|]*| *`\([a-z]*\)` *|.*/\1/p' | head -1)
  # A PINNED MODEL ID IS ALREADY CAUGHT HERE, and it is caught for the WRONG REASON, which is a
  # defect this repository files against other checks routinely. Measured 2026-09-14 by mutation:
  # pinning `model: claude-sonnet-5` in frontmatter alone reports the tier disagreement, which is
  # correct and useful; pinning it in BOTH the frontmatter and the table reports "is not named in
  # the MODELS.md table", because the extractor above matches [a-z]* and a hyphenated value simply
  # fails to parse. Right outcome, wrong cause -- and the remedy a reader would follow from that
  # message is "add a table row", which is not the fix.
  #
  # So the alias rule is asserted DIRECTLY and first. MODELS.md states it as a rule with a
  # consequence: a full model ID "cannot be overridden by environment, it does not follow a version
  # upgrade, and on Bedrock, Google Cloud's Agent Platform or Microsoft Foundry -- where the same
  # model is addressed by an inference profile ARN, a version name or a deployment name -- it does
  # not resolve at all."
  #
  # NO VENDOR LIST, deliberately. The test is the SHAPE of the value, not membership of a set of
  # names: a tier alias is a bare lowercase word, and every way of pinning a product carries
  # version or vendor detail -- `claude-sonnet-5`, `us.anthropic.claude-...`, `arn:aws:bedrock:...`,
  # `gpt-4o`. A hardcoded {opus,sonnet,haiku} would be this kit's adapter vocabulary frozen into a
  # control, and a second adapter with a different tier spelling would have to edit the check.
  case "$declared" in
    *[!a-z]*) echo "  $nm declares '$declared', which is not a tier alias -- a bare lowercase"
              echo "    word like 'opus'. A pinned model id cannot be remapped by environment"
              echo "    and does not resolve on Bedrock, Vertex or Foundry. See docs/MODELS.md."
              drift=1; continue ;;
  esac
  if [ -z "$documented" ]; then
    echo "  $nm is not named in the MODELS.md table"; drift=1
  elif [ "$declared" != "$documented" ]; then
    echo "  $nm declares '$declared', MODELS.md says '$documented'"; drift=1
  fi
done
check $drift "agent frontmatter and MODELS.md agree on every tier"
fi

if step "the pre-flight gates are commands, and a cp -r copy does not pass isolation"; then
# The two criticals the first trial execution left open, and both are about a gate that reads
# fine and does the wrong thing.
#
# ISOLATION. §4 mandated `git clone` then `git remote remove origin`, and §0 permitted "A COPY
# or a clone with its remote removed". A `cp -r` copy duplicates `.git/config` verbatim, so it
# keeps `origin` pointed at the subject -- and `git push` is a Bash call, which kit-guard.sh
# does not match. The removal procedure covered only the route nobody would take when in a
# hurry. The rule is now a PROPERTY of the copy and this proves the property is checked for
# both routes, especially the one that used to slip through.
pf="$WORK.preflight"; rm -rf "$pf"; mkdir -p "$pf"
( cd "$pf" || exit 1
  git init -q -b main subject 2>/dev/null
  ( cd subject || exit 1
    git config user.email a@b.c; git config user.name T
    echo hello > f.txt; git add -A; git commit -q --no-verify -m "seed" )
  P="$KIT/tooling/kit-preflight.sh"

  # The route that used to pass: a plain recursive copy. It has origin only if the source had
  # one, so give the source a remote first -- which is what a real subject has.
  git -C subject remote add origin https://example.invalid/subject.git
  cp -r subject copy_cp
  bash "$P" --isolated copy_cp >/dev/null 2>&1; cprc=$?

  # The route the protocol described, done right and done wrong.
  git clone -q --no-hardlinks subject clone_ok 2>/dev/null
  git -C clone_ok remote remove origin 2>/dev/null
  bash "$P" --isolated clone_ok >/dev/null 2>&1; okrc=$?
  git clone -q --no-hardlinks subject clone_bad 2>/dev/null
  bash "$P" --isolated clone_bad >/dev/null 2>&1; badrc=$?

  # A --shared clone BORROWS the subject`s object store through `alternates`: a path back that
  # `git remote -v` cannot show, and one that makes `git gc` in either repository able to
  # affect the other. Written as a plain `git clone` first, which was wrong -- a local clone
  # hardlinks objects but writes no alternates file, so the check passed and the assertion was
  # measuring nothing. Hardlinks and alternates are different mechanisms and only one of them
  # is what this detects.
  git clone -q --shared subject clone_alt 2>/dev/null
  git -C clone_alt remote remove origin 2>/dev/null
  bash "$P" --isolated clone_alt >/dev/null 2>&1; altrc2=$?

  # "Not a repository" and "no such path" must NOT read as isolated. A check that passes when
  # it could not run is the shape this whole file exists to refuse.
  mkdir -p notarepo
  bash "$P" --isolated notarepo >/dev/null 2>&1; nrrc=$?
  bash "$P" --isolated /nonexistent-path-for-conformance >/dev/null 2>&1; nprc=$?

  want() { [ "$2" = "$3" ] || { printf '    ^ %s: got %s, wanted %s\n' "$1" "$2" "$3" >&2; exit 1; }; }
  want "a cp -r copy is NOT isolated"        "$cprc"  1
  want "a clone with origin is NOT isolated" "$badrc" 1
  want "a --shared clone is NOT isolated"    "$altrc2" 1
  want "a de-remoted clone IS isolated"      "$okrc"  0
  want "a non-repository is not a pass"      "$nrrc"  1
  want "a missing path is not a pass"        "$nprc"  2 )
check $? "isolation is checked as a property of the copy, by whichever route it was made"

# SPEND. §0 queried the index straight after running an agent. Hooks append EVENTS; spend rows
# exist only once kit-index.sh derives them -- so a live recorder failed a check written to
# detect a dead one, and the box said STOP to a working kit.
sp="$WORK.spendpf"; rm -rf "$sp"; mkdir -p "$sp"
( cd "$sp" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A
  # THE SEED IS DATED BEFORE THE EVENTS BELOW, which are hand-written with January dates. Left
  # at wall time the fixture says a commit landed eight months after the last reading, and
  # `--spend`'s recency arm reads that -- correctly -- as a recorder that stopped. That is not
  # what this step is about: it asserts that spend is judged from the EVENT LOG rather than
  # from whatever the last rebuild held, and the commit date is incidental setup. Pinning it
  # makes the fixture internally consistent (work, then readings after it) instead of weakening
  # the arm that noticed.
  GIT_AUTHOR_DATE="2025-01-01T00:00:00Z" GIT_COMMITTER_DATE="2025-01-01T00:00:00Z"     git commit -q --no-verify -m "chore: seed"
  P="$KIT/tooling/kit-preflight.sh"
  # THE TWO FAULTS MUST REPORT DIFFERENTLY, and asserting only the exit code cannot see that --
  # a mutation that deleted the no-events branch survived, because the other branch also
  # returned 1 and the check could not say which. "The hook never fired" and "the hook fired
  # and nothing derived it" have different causes and different fixes; the message is the
  # deliverable, not the status.
  nonemsg=$(bash "$P" --spend 2>&1); nonerc=$?
  case "$nonemsg" in *"no spend EVENT has ever been recorded"*) nonesaid=1 ;; *) nonesaid=0 ;; esac

  # An event the indexer cannot derive a row from: kit-index.sh skips a spend event with no
  # transcript, so this is the "hook fired, derivation produced nothing" state exactly.
  printf '%s\n' '{"kind":"spend","at":"2026-01-01T00:00:00Z","transcript":"","scope":"session","agent":"x","model":"sonnet","turns":1,"tok_in":10,"tok_out":20,"cache_read":0,"cache_write":0,"context":100}' \
    >> .project/events.ndjson
  rm -f .project/index.db
  undermsg=$(bash "$P" --spend 2>&1); underrc=$?
  case "$undermsg" in *"no spend row was derived"*) undersaid=1 ;; *) undersaid=0 ;; esac

  # One spend EVENT that DOES derive, and no index at all: the exact state after an agent
  # finishes, and the state in which the old box said STOP to a working kit.
  printf '%s\n' '{"kind":"spend","at":"2026-01-02T00:00:00Z","transcript":"t1","scope":"session","agent":"x","model":"sonnet","turns":1,"tok_in":10,"tok_out":20,"cache_read":0,"cache_write":0,"context":100}' \
    >> .project/events.ndjson
  rm -f .project/index.db
  bash "$P" --spend >/dev/null 2>&1; liverc=$?
  want() { [ "$2" = "$3" ] || { printf '    ^ %s: got %s, wanted %s\n' "$1" "$2" "$3" >&2; exit 1; }; }
  want "no spend event at all is a STOP"   "$nonerc" 1
  want "  ...and names the dead hook"      "$nonesaid" 1
  want "an underived event is a STOP"      "$underrc" 1
  want "  ...and names the OTHER fault"    "$undersaid" 1
  want "a live hook passes without a prior rebuild" "$liverc" 0 )
check $? "spend capture is judged from the event log, not from whatever the last rebuild held"
rm -rf "$pf" "$sp"
fi


if step "a reply already in hand is recorded, and a refused one still leaves a gap"; then
# In plugin mode a reviewer is an Agent-tool subagent: there is no command that reads a prompt on
# stdin and writes a reply to stdout, so `--cmd` has no satisfiable value and the retry loop has
# no caller shape. Measured on the 2026-09-09 highper-gateway trial -- 11 of 11 findings landed
# only because a human typed `kit-finding.sh --json`, which is the intervention acceptance
# criterion 1 forbids.
#
# THE LOAD-BEARING ASSERTION IS THE REFUSED REPLY, NOT THE ACCEPTED ONE. `kit-finding.sh --json`
# already records a good reply, so a test that only checked that would pass against the door not
# existing at all. What it does NOT do is leave a row when it refuses -- the refused findings
# exist only in the reply, and silence there is the open circuit this task is named after.
#
# THE GAP HAS EXACTLY ONE OWNER, and this step asserts the count rather than its existence for
# that reason. `kit-finding.sh`'s emit() already records a `rejected` gap when a batch is refused,
# so a door that writes its own produces TWO rows for one refused review -- the double-gap shape
# round 5 of this task recorded as a minor, and which was reintroduced here and caught by this
# step before it shipped. Asserting `>= 1` would have passed against both the duplicate and the
# silence; only the exact count separates them.
#
# MUTATIONS, each of which must take this step red on its own:
#   (a) write a gap in the --reply-file path too   -> two rows for one refusal, grej becomes 2
#   (b) remove emit()'s gap in kit-finding.sh      -> refusal goes silent, grej becomes 0
#   (c) accept --cmd and --reply-file together     -> ambiguity about which reply is real
#   (d) accept an empty --reply-file               -> records nothing and exits 0
rf="$WORK.replyfile"; rm -rf "$rf"; mkdir -p "$rf/src"
( cd "$rf" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-h\ntitle: h\ntier: T2\n---\nb\n' > .project/tasks/T-h.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # A compliant reply, as an Agent-tool subagent would have returned it.
  printf '%s' '{"verdict":"REVISE","narrative":"n","findings":[{"class":"fail-open","severity":"major","lang":"bash","summary":"recorded through the reply-in-hand door with no command to run"}]}' > good.json
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent implementation-reviewer \
    --reply-file good.json >/dev/null 2>&1
  okrc=$?

  # A reply the validator refuses: severity outside the vocabulary. The recorder rejects the
  # whole batch -- and the GAP is what this door adds over calling the recorder directly.
  printf '%s' '{"verdict":"REJECT","narrative":"n","findings":[{"class":"fail-open","severity":"Catastrophic","summary":"an unknown severity, so the whole batch is refused"}]}' > bad.json
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent tester \
    --reply-file bad.json >/dev/null 2>&1
  badrc=$?

  # An EMPTY file is not an empty review. A reviewer that found nothing returns {"findings":[]},
  # which records a gap meaning exactly that; an empty file means the caller has nothing.
  : > empty.json
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent tester \
    --reply-file empty.json >/dev/null 2>&1
  emptyrc=$?

  # ... and that distinction must hold: the genuine empty review still records its own gap.
  printf '%s' '{"findings":[]}' > none.json
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent documenter \
    --reply-file none.json >/dev/null 2>&1
  nonerc=$?

  # Exactly one door. Both, or neither, is a usage error before anything is written.
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent tester \
    --cmd 'true' --reply-file good.json >/dev/null 2>&1
  bothrc=$?
  bash "$KIT/tooling/kit-review-record.sh" --task T-h --agent tester >/dev/null 2>&1
  neitherrc=$?

  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  rows=$(Q "SELECT COUNT(*) FROM finding;")
  summ=$(Q "SELECT summary FROM finding WHERE agent='implementation-reviewer';")
  grej=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-gap' AND payload LIKE '%\"reason\":\"rejected\"%';")
  gemp=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-gap' AND payload LIKE '%\"reason\":\"empty\"%';")
  # The gap must name WHICH review, not merely exist: a count alone cannot tell a refused
  # tester review from a refused anything-else.
  gwho=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-gap' AND payload LIKE '%\"agent\":\"tester\"%' AND payload LIKE '%\"reason\":\"rejected\"%';")

  [ "$okrc"      = 0 ] || exit 1     # a good reply records and exits clean
  [ "$badrc"     = 1 ] || exit 1     # a refused reply fails, and does not pretend otherwise
  [ "$emptyrc"   = 2 ] || exit 1     # an empty FILE is a usage error, not an empty review
  [ "$nonerc"    = 0 ] || exit 1     # an empty REVIEW is a measurement and records fine
  [ "$bothrc"    = 2 ] || exit 1     # both doors is ambiguous
  [ "$neitherrc" = 2 ] || exit 1     # neither door leaves nothing to do
  [ "$rows" = 1 ] || exit 1          # only the compliant reply became a row
  [ "$grej" = 1 ] || exit 1          # THE ASSERTION THIS STEP EXISTS FOR
  [ "$gwho" = 1 ] || exit 1          # and it names the review that was refused
  [ "$gemp" = 1 ] || exit 1          # the genuine empty review is still its own kind of gap
  case "$summ" in *"reply-in-hand door"*) ;; *) exit 1 ;; esac
  exit 0 )
check $? "a reply already in hand is recorded, and a refused one still leaves a gap"
rm -rf "$rf"
fi
if step "a refused review is retried with the diagnostics, boundedly"; then
# The contract asks a reviewer for one JSON object. Across four live runs it was ignored three
# times, and each time a human read the diagnostics and repaired the reply by hand -- the
# intervention acceptance criterion 1 forbids. This is the mechanism that replaces the human.
#
# The reviewer here is a FIXTURE, not a model: it fails the first time and succeeds only if the
# validator's own diagnostics actually reach it. That is what makes this deterministic enough
# to live in CI, and it is also the assertion -- a loop that retried blindly would still pass a
# test that only counted attempts.
rr="$WORK.retry"; rm -rf "$rr"; mkdir -p "$rr/src"
( cd "$rr" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---
id: T-r
title: r
tier: T2
---
b
' > .project/tasks/T-r.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # Bad first: fenced, and a summary past the 200-character cap. Good second, but ONLY if the
  # correction reached it.
  cat > rev.sh <<'REV'
#!/usr/bin/env bash
n=$(cat "$STATE" 2>/dev/null || echo 0); n=$((n+1)); printf '%s' "$n" > "$STATE"
prompt=$(cat)
if [ "$n" = 1 ]; then
  # Deliberately non-compliant three ways at once: prose preamble, a code fence, and a summary
  # past the 200-character cap. PRIOR-REPLY-MARKER is what attempt 2 looks for to prove the
  # retry carried this reply back; without it, "resend the same review" is addressed to a
  # process that cannot see what it said.
  long=$(awk 'BEGIN{printf "PRIOR-REPLY-MARKER "; while(i++<210)printf "x"}')
  printf 'Sure, here you go:\n\n```json\n{"verdict":"REJECT","findings":[{"class":"fail-open","severity":"major","summary":"%s"}]}\n```\n' "$long"
  exit 0
fi
# The retry must carry BOTH the diagnostics AND the original request. Checking only for the
# diagnostics passed while the request was being dropped -- and a stateless reviewer with no
# request returns nothing, which records as reason=empty: "a review looked and found nothing".
# Observed against a real reviewer on 2026-08-12.
case "$prompt" in
  *"REFUSED by the findings contract"*)
    case "$prompt" in
      *ORIGINAL-REQUEST-MARKER*)
        # And the reviewer's OWN previous reply must have come back with it, or "send that
        # same review again" is an instruction it cannot follow.
        case "$prompt" in
          *PRIOR-REPLY-MARKER*)
            printf '{"verdict":"REJECT","narrative":"n","findings":[{"class":"fail-open","severity":"major","lang":"bash","summary":"the diagnostics came back and this reply is the correction"}]}' ;;
          *) printf '{"findings":[]}' ;;
        esac ;;
      *) printf '{"findings":[]}' ;;
    esac ;;
  *) printf '{"findings":[]}' ;;
esac
REV
  # The marker is how the fixture proves the RETRY still carried the original request. Without
  # something from the request to look for, the check can only see the diagnostics and cannot
  # tell a coherent retry from one that dropped what was being asked.
  printf 'review it  ORIGINAL-REQUEST-MARKER' > p.txt
  STATE="$PWD/calls"; export STATE; rm -f "$STATE"
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent implementation-reviewer \
    --cmd "bash $PWD/rev.sh" --prompt-file p.txt --max-attempts 3 >/dev/null 2>&1
  ok=$?
  tries=$(cat "$STATE")

  # A reviewer that never complies must STOP, and must leave a row saying findings were lost.
  cat > never.sh <<'NEV'
#!/usr/bin/env bash
cat >/dev/null
n=$(cat "$STATE" 2>/dev/null || echo 0); printf '%s' "$((n+1))" > "$STATE"
echo "I will not comply."
NEV
  STATE="$PWD/calls2"; export STATE; rm -f "$STATE"
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent tester \
    --cmd "bash $PWD/never.sh" --prompt-file p.txt --max-attempts 2 >/dev/null 2>&1
  gave=$?
  tries2=$(cat "$STATE")

  # A reviewer command that itself fails is NOT a contract violation, and retrying a broken
  # invocation is how a loop spends a budget on nothing.
  # It COUNTS its calls, and the assertion is the count. Asserting only the exit status could
  # not tell "abandoned after one attempt" from "retried three times and gave up" -- both end
  # at 1 -- so the mutation that retried a broken invocation survived this check until the
  # count was added. A check that cannot distinguish the defect from the fix is decoration.
  cat > broke.sh <<'BRK'
#!/usr/bin/env bash
cat >/dev/null
n=$(cat "$STATE" 2>/dev/null || echo 0); printf '%s' "$((n+1))" > "$STATE"
exit 7
BRK
  STATE="$PWD/calls3"; export STATE; rm -f "$STATE"
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent tester \
    --cmd "bash $PWD/broke.sh" --prompt-file p.txt --max-attempts 3 >/dev/null 2>&1
  brc=$?
  tries3=$(cat "$STATE")

  # A MISSING prompt is a usage error before the first attempt. Ignoring it handed the reviewer
  # an empty prompt, whose empty reply recorded as reason=empty -- "a review found nothing" --
  # and exited 0. A review that never happened, reported clean. Critical, round 5.
  STATE="$PWD/calls4"; export STATE; rm -f "$STATE"
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent tester \
    --cmd "bash $PWD/rev.sh" --prompt-file no-such-file.txt --max-attempts 3 >/dev/null 2>&1
  nofile=$?
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent tester \
    --cmd "bash $PWD/rev.sh" --max-attempts 3 >/dev/null 2>&1
  noflag=$?
  # Neither may have called the reviewer at all.
  called=$([ -f "$STATE" ] && cat "$STATE" || printf '0')

  # A reviewer that does not read its stdin must not look like a broken command: piped, SIGPIPE
  # killed printf and pipefail reported the whole pipeline as failed.
  printf '#!/usr/bin/env bash\nprintf %%s "{\\"findings\\":[{\\"class\\":\\"race\\",\\"severity\\":\\"nit\\",\\"summary\\":\\"this reviewer never read its stdin at all\\"}]}"\n' > nodrain.sh
  # The prompt must EXCEED the pipe buffer, or this control cannot fail. A short prompt fits in
  # the buffer, `printf` completes before the non-draining reader exits, and no SIGPIPE ever
  # happens -- so the mutation that pipes the prompt again passed this check until the prompt
  # got big. Real review prompts are briefs, not one-liners.
  awk 'BEGIN{while(i++<200000)printf "x"}' > big.txt
  bash "$KIT/tooling/kit-review-record.sh" --task T-r --agent documenter \
    --cmd "bash $PWD/nodrain.sh" --prompt-file big.txt --max-attempts 2 >/dev/null 2>&1
  nodrain=$?

  # A validator that FAILS is not a reviewer that was refused. Read as a refusal, the empty
  # correction became the next prompt and every remaining attempt reviewed nothing.
  bt="$PWD/brokenval"; mkdir -p "$bt"
  cp "$KIT/tooling/kit-review-record.sh" "$KIT/tooling/kit-finding.sh" "$KIT/tooling/kit-lib.sh" "$bt/"
  printf 'import sys\nsys.exit(1)\n' > "$bt/kit_findings.py"
  STATE="$PWD/calls5"; export STATE; rm -f "$STATE"
  bash "$bt/kit-review-record.sh" --task T-r --agent tester \
    --cmd "bash $PWD/never.sh" --prompt-file p.txt --max-attempts 4 >/dev/null 2>&1
  badval=$?
  tries5=$(cat "$STATE" 2>/dev/null || printf '0')

  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  rows=$(Q "SELECT COUNT(*) FROM finding;")
  summ=$(Q "SELECT summary FROM finding WHERE agent='implementation-reviewer';")
  gaps=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-gap';")
  # The gap must say WHICH review and WHY, not merely exist -- asserting the count alone was
  # the round-5 finding against this very fixture.
  gtask=$(Q "SELECT COUNT(*) FROM event WHERE kind='finding-gap' AND task_id='T-r' AND payload LIKE '%\"agent\":\"tester\"%' AND payload LIKE '%\"reason\":\"rejected\"%';")

  # Named one at a time. Ten conditions in a single `&&` chain report only "false", and a
  # fixture that cannot say WHICH guarantee broke costs a debugging session every time it goes
  # red. `check` cannot be used in here -- its counters would not survive the subshell -- so
  # the subshell names the failure and exits, and the one check outside reports it.
  want() { [ "$2" = "$3" ] || { printf '    ^ %s: got %s, wanted %s\n' "$1" "$2" "$3" >&2; exit 1; }; }
  want "corrected reply accepted"        "$ok"      0
  want "  ...on the second attempt"      "$tries"   2
  want "incorrigible reviewer gives up"  "$gave"    1
  want "  ...after exactly max attempts" "$tries2"  2
  want "broken command not retried"      "$brc"     1
  want "  ...called exactly once"        "$tries3"  1
  want "unreadable prompt refused"       "$nofile"  2
  want "missing prompt flag refused"     "$noflag"  2
  want "  ...reviewer never called"      "$called"  0
  want "non-draining reviewer accepted"  "$nodrain" 0
  want "  ...validator failure attempts" "$tries5"  1
  want "findings recorded"               "$rows"    2
  want "summary survived"                "$summ"    "the diagnostics came back and this reply is the correction"
  # Two tester gaps are expected here -- the incorrigible reviewer and the broken command --
  # so this asserts the SHAPE (task and reason are present and right), not an exact count.
  [ "$gtask" -ge 1 ] || { printf '    ^ no gap names both its task and reason=rejected\n' >&2; exit 1; }
  [ "$badval" != 0 ] || { printf '    ^ a validator failure exited 0\n' >&2; exit 1; }
  [ "$gaps" -ge 2 ] )
check $? "a refused reply is corrected and recorded; an incorrigible one stops and leaves a gap"
rm -rf "$rr"
fi

if step "the finding contract is defined in exactly one place"; then
# The vocabulary was restated in four files once and they all drifted. The FIELD LIST is the
# same hazard: an agent that lists the fields from memory will list them wrongly the day one
# changes. `kit-finding.sh --contract` is the single home, and this asserts the recorder and
# the validator still agree about what a finding is.
C=$(bash "$KIT/tooling/kit-finding.sh" --contract 2>/dev/null)
printf '%s' "$C" | grep -q 'summary   required' &&
printf '%s' "$C" | grep -q 'class     required' &&
printf '%s' "$C" | grep -q 'severity  required'
check $? "--contract names the three required fields"

# Both accessors answer "what may I send you", which is asked while READING, from wherever the
# reader happens to be standing. Run from a directory that is not an adopted project -- which
# is where the docs are read -- they must still answer. `--contract` did not, and the fix for
# that had no test, so moving it back inside the arg loop would have gone unnoticed. Run from a
# scratch dir with no profile, and also as a NON-first argument, which was a second regression.
nc="$WORK.nocontract"; rm -rf "$nc"; mkdir -p "$nc"
( cd "$nc" || exit 1
  bash "$KIT/tooling/kit-finding.sh" --contract 2>/dev/null | grep -q 'summary   required' || exit 1
  bash "$KIT/tooling/kit-finding.sh" --vocab 2>/dev/null | grep -q '^class:' || exit 1 )
check $? "--contract and --vocab answer outside an adopted project"
bash "$KIT/tooling/kit-finding.sh" --task T --vocab 2>/dev/null | grep -q '^class:'
check $? "and answer when they are not the first argument"
rm -rf "$nc"
# The validator must not carry its own copy of the vocabulary: it has to ASK for it, or the two
# drift the moment a class is added. Proved by narrowing the vocabulary at its one source and
# watching a previously-valid class be refused.
#
# The POSITIVE CONTROL is the point. The first version of this asserted only a non-zero exit,
# so it passed on a failed cp, a missing python3, or a syntax error -- a check that could not
# fail, in the guard against exactly that class, found by a T3 reviewer the next day
# (docs/LESSONS.md S1). Now the same copied tree must ACCEPT the finding before the narrowed
# one rejects it; if the copy is broken, the positive half fails and the step goes red.
vb="$WORK.vocabbreak"; rm -rf "$vb"; mkdir -p "$vb"
cp "$KIT/tooling/kit_findings.py" "$KIT/tooling/kit-lib.sh" "$KIT/tooling/kit-finding.sh" "$vb/"
GOOD='{"findings":[{"class":"fail-open","severity":"major","summary":"valid under the real vocabulary"}]}'
printf '%s' "$GOOD" | python3 "$vb/kit_findings.py" --validate >/dev/null 2>&1
pos=$?
sed -i.bak 's/^CLASSES=.*/CLASSES="only-this-one"/' "$vb/kit-finding.sh"; rm -f "$vb/kit-finding.sh.bak"
printf '%s' "$GOOD" | python3 "$vb/kit_findings.py" --validate >/dev/null 2>&1
neg=$?
[ "$pos" = 0 ] && [ "$neg" -ne 0 ]
check $? "the validator reads the vocabulary rather than restating it (accepts, then refuses)"
rm -rf "$vb"
fi

if step "an uninstrumented project is not reported as a free one"; then
# Spend is a MEASUREMENT, so its absence is information and must be printed. The section used
# to be gated on a non-empty table with no else, which made "the hooks never fired" and "the
# work cost nothing" byte-identical. Measured on the kit's own repo: 0 rows after twelve days
# and not one mention of cost in the output.
#
# BOTH branches are exercised. A step that only ran the populated one could not fail for the
# defect being fixed, which is the shape this suite exists to refuse.
sp="$WORK.spendrep"; rm -rf "$sp"; mkdir -p "$sp/sess/subagents" "$sp/src"
( cd "$sp" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---
id: T-s
title: s
tier: T2
---
b
' > .project/tasks/T-s.md
  git add -A && git commit -q --no-verify -m "chore: seed"

  # EMPTY: the section must exist and must say it is not a zero.
  bash "$KIT/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q '^## Spend' STATUS.generated.md ||
    { printf '    ^ no Spend section at all when the table is empty\n' >&2; exit 1; }
  grep -q 'not a measurement of zero' STATUS.generated.md ||
    { printf '    ^ empty spend does not say it is unavailable rather than zero\n' >&2; exit 1; }
  grep -q 'UNAVAILABLE, not zero' STATUS.generated.md || exit 1
  # It must NOT print the populated section's furniture on an empty table.
  grep -q 'Billable input-token-equivalents' STATUS.generated.md &&
    { printf '    ^ the populated header printed with no rows behind it\n' >&2; exit 1; }

  # POPULATED: the real section returns, and the empty notice goes away.
  printf '{"type":"assistant","message":{"model":"m1","usage":{"input_tokens":10,"cache_creation_input_tokens":400,"cache_read_input_tokens":1000,"output_tokens":200}}}
' > sess/subagents/agent-A1.jsonl
  printf '{"agentType":"implementation-reviewer","spawnDepth":1}' > sess/subagents/agent-A1.meta.json
  : > sess.jsonl
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" --agent-id A1 --agent implementation-reviewer
  bash "$KIT/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Billable input-token-equivalents' STATUS.generated.md ||
    { printf '    ^ the populated Spend section did not return\n' >&2; exit 1; }
  grep -q 'not a measurement of zero' STATUS.generated.md &&
    { printf '    ^ the empty notice printed alongside real rows\n' >&2; exit 1; }
  # And the recorder itself works -- the hypothesis that it was broken was wrong, and this is
  # what keeps that answer true rather than remembered.
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM spend;' | tr -d '\015')" = 1 ] )
check $? "empty spend says unavailable, populated spend reports, and the recorder records"
rm -rf "$sp"
fi

if step "a pack load is counted from the transcript, and the generator is not a pack"; then
# "Do packs lower context per turn" cannot be asked of a population that does not say which
# side it is on, so kit-spend.sh counts pack loads from the transcript itself -- derived, never
# declared by the session, the same rule as Via:.
#
# The assertion that bites is the SECOND one. The first pattern written for this matched
# kit-plan.sh's own generator line, so a session that merely READ the planner scored as a pack
# consumer; on this repository that put three sessions on the treated arm that did not belong
# there. A fixture with only a real pack header would pass either way.
pk="$WORK.packcount"; rm -rf "$pk"; mkdir -p "$pk"
( cd "$pk" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A && git commit -q --no-verify -m "chore: seed"

  # One RENDERED header (a pack was loaded) and one FORMAT STRING (the planner was read).
  # Only the first is a pack load.
  printf '{"type":"user","content":"<!-- GENERATED by kit-plan.sh (goal default, cluster 7). Frozen -->"}\n' >  t.jsonl
  printf '{"type":"user","content":"printf \\"<!-- GENERATED by kit-plan.sh (goal %%s, cluster %%s). Frozen\\""}\n' >> t.jsonl
  printf '{"type":"assistant","message":{"model":"m1","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":500,"output_tokens":1}}}\n' >> t.jsonl

  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/t.jsonl"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  n=$(sqlite3 .project/index.db "SELECT COALESCE(SUM(pack_loads),-1) FROM spend WHERE scope='main';" | tr -d '\015')
  [ "$n" = 1 ] ||
    { printf '    ^ pack_loads=%s, expected 1 (0 = not counted, 2 = the generator counted as a load)\n' "$n" >&2; exit 1; } )
check $? "a pack load is counted from the transcript, and the generator is not a pack"
rm -rf "$pk"
fi

if step "the main-loop report separates cost per turn from session length"; then
# The By-scope rows say the main loop dominates and say nothing about why, and the answer is
# the lever DESIGN-NOTES section 0 leaves open once caching is exhausted: per-turn cost is mean
# context. This step guards the report that states it.
#
# The assertion with teeth is the LAST one. A grep for the heading passes when every session
# falls in one bucket, and passes again if the per-turn figure is really a per-session total --
# both of which look like a working report. So the fixture builds two transcripts that differ
# on BOTH axes and requires the reported context-per-turn to rise with them.
sl="$WORK.spendlen"; rm -rf "$sl"; mkdir -p "$sl"
( cd "$sl" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A && git commit -q --no-verify -m "chore: seed"

  # BRIEF: 5 turns, 1k re-read on each.   SHORT: 70 turns, 10k on each.
  # Written as loops rather than one long literal so the turn counts are visible as numbers.
  turn() { printf '{"type":"assistant","message":{"model":"m1","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":%s,"output_tokens":1}}}\n' "$1"; }
  i=0; : > brief.jsonl; while [ $i -lt 5  ]; do turn 1000  >> brief.jsonl; i=$((i+1)); done
  i=0; : > short.jsonl; while [ $i -lt 70 ]; do turn 10000 >> short.jsonl; i=$((i+1)); done

  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/brief.jsonl"
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/short.jsonl"
  bash "$KIT/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1

  grep -q 'Main loop, by session length' STATUS.generated.md ||
    { printf '    ^ the per-turn report is absent with two main transcripts recorded\n' >&2; exit 1; }
  B=$(sed -n 's/^- brief .*, \([0-9][0-9]*\)k context per turn$/\1/p' STATUS.generated.md | head -1)
  S=$(sed -n 's/^- short .*, \([0-9][0-9]*\)k context per turn$/\1/p' STATUS.generated.md | head -1)
  [ -n "$B" ] && [ -n "$S" ] ||
    { printf '    ^ a bucket did not render (brief=%s short=%s)\n' "$B" "$S" >&2; exit 1; }
  [ "$S" -gt "$B" ] ||
    { printf '    ^ context per turn does not rise with session length (brief=%s short=%s)\n' "$B" "$S" >&2; exit 1; } )
check $? "the main-loop report separates cost per turn from session length"
rm -rf "$sl"
fi

if step "the trial protocol's unit matches the one the kit computes"; then
# docs/TRIAL-PROTOCOL.md fixes the unit a trial reports in, and a document is the easiest place
# for a number to drift out of agreement with the code. The weights are computed in exactly one
# place -- BTE in kit-status.sh -- and the protocol restates them in prose because a person has
# to read them. That restatement is the risk, so it is checked: the finding vocabulary was
# restated in four files once and all four drifted.
P="$KIT/docs/TRIAL-PROTOCOL.md"
[ -f "$P" ]; check $? "the trial protocol exists"
# Pulled from the source rather than typed here, so this step cannot itself become a third copy.
#
# EXACTLY ONE definition, asserted first. A second `BTE=` line would make the sed emit eight
# fields, and `set --` would then check only the first four while reporting success -- the
# check would silently stop covering the definition that was actually in use.
NBTE=$(grep -c '^BTE=' "$KIT/tooling/kit-status.sh")
[ "$NBTE" = 1 ]
check $? "kit-status.sh defines BTE exactly once (found $NBTE)"
W=$(sed -n 's/^BTE="(s\.tok_in\*\([0-9]*\) + s\.cache_write\*\([0-9]*\) + s\.cache_read\*\([0-9]*\) + s\.tok_out\*\([0-9]*\))"/\1 \2 \3 \4/p' "$KIT/tooling/kit-status.sh")
set -- $W
# Scaled by 100 in the SQL so the weights stay integers; the prose states them unscaled.
[ "${1:-}" = 100 ] && [ "${2:-}" = 125 ] && [ "${3:-}" = 10 ] && [ "${4:-}" = 500 ]
check $? "the weights are still 1 / 1.25 / 0.1 / 5 in kit-status.sh (read: $W)"
grep -q 'input×1 + cache-write×1.25 + cache-read×0.1 + output×5' "$P"
check $? "and the protocol states those same four weights"
# The protocol's central warning: the harness per-agent figure is context size, not cost. If
# that sentence goes, the next trial quotes the wrong column exactly as the first one did.
grep -q 'final context size' "$P" && grep -qi 'do NOT use the harness' "$P"
check $? "the protocol still warns off the harness per-agent figure"

# The two criticals the T2 review found before first use. Both are one sentence away from
# regressing, and both would be paid for by a trial on a real client codebase.
#
# 1. Isolation. "A copy or a read-only clone" left origin pointing at the subject, and git push
#    is a Bash call the guard never sees. The removed remote IS the control.
#
#    This checked for `git remote -v` in the prose, which was true of the document while its
#    §0 still offered "A COPY" as an alternative -- a phrasing that skipped the removal
#    entirely, since `cp -r` duplicates .git/config with origin intact. Prose agreeing with
#    prose is not the property. The check is now the COMMAND both sections point at, and
#    whether it actually refuses each route is proved in its own step.
grep -q 'git remote remove origin' "$P" && grep -q 'kit-preflight.sh --isolated' "$P"
check $? "the protocol removes the remote and verifies isolation with a command"
# §0 must not reintroduce the alternative that made the removal optional. Named exactly, so
# that rewording the box is fine and re-offering an unverified copy is not.
if grep -q 'A COPY or a clone with its remote removed' "$P"; then
  check 1 "S0 no longer offers an unverified copy as an alternative"
else
  check 0 "S0 no longer offers an unverified copy as an alternative"
fi
# The guard's matcher is quoted in the protocol as the reason. If the hook ever grows Bash
# coverage that sentence becomes false, so tie it to the hook rather than to prose.
grep -q '"matcher": "Write|Edit|NotebookEdit"' "$KIT/hooks/hooks.json"
check $? "the guard still matches only Write|Edit|NotebookEdit, as the protocol states"
# 2. The per-agent figure. The protocol must not mandate one the kit does not emit while also
#    forbidding the only way to derive it -- that pair is what made revision 1 unexecutable.
grep -q 'It does \*\*not\*\* emit a per-agent figure' "$P"
check $? "the protocol says plainly that no per-agent BTE is emitted"
# Asserted against the TRACKED SCHEMA, never against .project/index.db. That file is gitignored
# and derived, so it exists on a developer's machine and NOT on a fresh CI clone -- the first
# version of this check queried it, passed locally for that reason alone, and went red on both
# CI platforms within one push. LESSONS.md S9: the gate you cannot run locally is the one that
# catches you. A conformance check must depend only on what is committed.
sed -n '/CREATE TABLE spend/,/^);/p' "$KIT/tooling/schema.sql" | grep -qE '^  agent  *TEXT'
check $? "and spend still declares the agent column the protocol's query groups by"

# §7 names a template. Revision 1 named a shape with no file, so every trialist would have
# invented one and comparability would have died at the artefact.
[ -f "$KIT/docs/TRIALS/TEMPLATE.md" ]
check $? "the report template §7 points at exists"
fi

if step "the via vocabulary is defined in exactly one place"; then
# The finding vocabulary was restated in four locations once, and the agents then emitted
# values the recorder threw away. This one has a single definition in kit-lib.sh and every
# consumer reads it from there; a literal copy anywhere else is the drift starting again.
#
# The pattern comes from the definition rather than being typed here. Spelling it out would
# have made this file the second copy -- which it was, on the first run, and the check caught
# itself. A test that cannot be written without violating the rule it enforces is telling you
# something about the rule; here it just meant: ask the source.
( . "$KIT/tooling/kit-lib.sh"
  VOCAB=$(kit_via_vocab)
  copies=$(grep -rlF "$VOCAB" "$KIT/tooling" "$KIT/tests" 2>/dev/null | wc -l | tr -d ' ')
  [ "$copies" = 1 ] || { echo "  '$VOCAB' appears in $copies file(s), expected 1:"
                         grep -rlF "$VOCAB" "$KIT/tooling" "$KIT/tests" 2>/dev/null | sed 's/^/    /'; }
  [ "$copies" = 1 ] )
check $? "one definition of the via vocabulary, read by every consumer"
fi

if step "the state vocabulary has one home and its aliases actually bind"; then
# docs/adr/0008. "Is this task closed?" was the literal 'done','abandoned' in NINETEEN places
# across four files while the vocabulary itself was declared once, so the partition could disagree
# with itself and nothing would notice. Same rule as the via vocabulary above, same reason.
#
# THE PATTERNS COME FROM THE DEFINITIONS, never spelled out here -- writing them literally would
# make this file the second copy, which is the failure the via step already caught in itself.
# EXISTENCE IS ASSERTED BEFORE USE, and that is not defensive noise. Run against a tree without
# these definitions, an unguarded `$(kit_state_measured)` expands to the EMPTY STRING, and every
# assertion below then compares against nothing -- one of them passed that way on the first
# attempt, which is a green check that cannot fail (docs/LESSONS.md section 1) inside the step
# written to prevent exactly that.
( . "$KIT/tooling/kit-lib.sh"
  for _get in kit_state_vocab kit_state_closed kit_state_activity kit_state_measured kit_state_plannable kit_state_legacy; do
    command -v "$_get" >/dev/null 2>&1 || { echo "  $_get is not defined"; exit 1; }
    [ -n "$($_get)" ] || { echo "  $_get is empty"; exit 1; }
  done
  for _get in kit_state_vocab kit_state_closed kit_state_activity kit_state_measured kit_state_plannable; do
    V=$($_get)
    n=$(grep -rlF "$V" "$KIT/tooling" "$KIT/tests" 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" = 1 ] || { echo "  '$V' appears in $n file(s), expected 1"; exit 1; }
  done )
check $? "each state definition appears in exactly one file"

# THE ALIAS TABLE MUST BIND, NOT MERELY BE DOCUMENTED. This is the assertion that would rot
# silently: a mapping written down but never applied looks identical to one that is applied,
# until a query returns nothing. So it is checked end to end -- a task file written the old way,
# and a trailer written the old way, both landing on canonical values in the index.
sv="$WORK.state"; rm -rf "$sv"; mkdir -p "$sv/.claude" "$sv/.project/tasks" "$sv/src"
( cd "$sv" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email fixture@x; git config user.name fixture
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  # Written the LEGACY way, which task files may do forever -- 132 in this repository still do.
  for t in A B; do
    { echo "---"; echo "id: T-$t"; echo "title: t"; echo "tier: T1"; echo "state: open"; echo "---"; } \
      > ".project/tasks/T-$t.md"
  done
  echo x > src/a; git add -A >/dev/null 2>&1
  git commit -q -F - <<'MSG' || exit 1
seed

Task-Id: T-B
Tier: T1
Task-Status: done
MSG
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1 || exit 1
  s() { sqlite3 .project/index.db "SELECT state FROM task WHERE id='$1';" | tr -d '\015'; }
  # `state: open` in the file -> `created` in the index. No file was rewritten to achieve it.
  [ "$(s T-A)" = created ]   || { echo "  T-A is '$(s T-A)', expected created"; exit 1; }
  # `Task-Status: done` in an immutable commit -> `completed`. 127 real commits depend on this.
  [ "$(s T-B)" = completed ] || { echo "  T-B is '$(s T-B)', expected completed"; exit 1; }
  grep -q '^state: open$' .project/tasks/T-A.md || { echo "  the task file was rewritten"; exit 1; }

  # CLOSED AND MEASURED ARE DIFFERENT SETS, and this is the distinction the whole change exists
  # for. `cancelled` leaves the open backlog without counting toward what the pipeline achieved;
  # `abandoned` does count, because it was real work. A single boolean cannot express that, and a
  # test that only checked is_closed would pass on a design that had collapsed them.
  q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  [ "$(q "SELECT is_closed||is_measured FROM state_class WHERE state='cancelled';")" = 10 ] ||
    { echo "  cancelled is not closed-and-unmeasured"; exit 1; }
  [ "$(q "SELECT is_closed||is_measured FROM state_class WHERE state='abandoned';")" = 11 ] ||
    { echo "  abandoned is not closed-and-measured"; exit 1; }
  [ "$(q "SELECT is_closed||is_measured FROM state_class WHERE state='completed';")" = 11 ] ||
    { echo "  completed is not closed-and-measured"; exit 1; } )
check $? "a legacy file and a legacy trailer both land on canonical states, and cancelled is closed but unmeasured"

# The validator accepts BOTH vocabularies. Rejecting the legacy spellings would make `git log`
# unverifiable against 127 commits that already carry them, and history cannot be amended.
# Run inside the fixture, because `message` resolves Task-Id against the backlog there.
( cd "$sv" || exit 1
  . "$KIT/tooling/kit-lib.sh"
  # Same guard, same reason: without it the legacy loop below iterates over an empty list on a
  # tree that has no legacy vocabulary, and the step reports PASS having tested one nonsense value.
  for _get in kit_state_vocab kit_state_legacy; do
    command -v "$_get" >/dev/null 2>&1 || { echo "  $_get is not defined"; exit 1; }
    [ -n "$($_get)" ] || { echo "  $_get is empty"; exit 1; }
  done
  tv() { printf 'x\n\nTask-Id: T-A\nTier: T1\nTask-Status: %s\n' "$1" > m.txt
         bash "$KIT/tooling/kit-trailers.sh" message m.txt 2>&1; }
  for v in $(kit_state_vocab); do
    printf '%s' "$(tv "$v")" | grep -q 'invalid  Task-Status' &&
      { echo "  canonical '$v' was rejected"; exit 1; }
  done
  for p in $(kit_state_legacy); do
    printf '%s' "$(tv "${p%%:*}")" | grep -q 'invalid  Task-Status' &&
      { echo "  legacy '${p%%:*}' was rejected"; exit 1; }
  done
  # And the guard still bites: a value in NEITHER vocabulary is refused. Without this the two
  # loops above would pass against a validator that had stopped checking anything at all.
  printf '%s' "$(tv nonsense)" | grep -q 'invalid  Task-Status' ||
    { echo "  a nonsense state was ACCEPTED"; exit 1; }
  rm -f m.txt )
check $? "both vocabularies validate, and a value in neither is still refused"

# THE PROSE COPIES DRIFT TOO, and nothing was watching them. The single-home check above greps
# only tooling/ and tests/, so README.md and docs/HANDOFF.md each carried a hand-written list of
# the vocabulary that went stale the moment it changed -- found exactly that way. A reader-facing
# table is legitimate documentation rather than a second definition, so it is not banned; it is
# required to AGREE. Values, not formatting: the two files render them differently on purpose.
( . "$KIT/tooling/kit-lib.sh"
  for f in "$KIT/README.md" "$KIT/docs/HANDOFF.md"; do
    line=$(grep -m1 'Task-Status:' "$f") || { echo "  no Task-Status row in ${f##*/}"; exit 1; }
    for v in $(kit_state_vocab); do
      printf '%s' "$line" | grep -qF -- "$v" ||
        { echo "  ${f##*/} omits '$v' from its Task-Status row"; exit 1; }
    done
  done )
check $? "the reader-facing tables list the same states the code defines"

# NOTHING CHECKED INSTALL.md AT ALL until this step, and that is how it came to claim
# `kit-init.sh` "exits 0" outside a repository when kit-init.sh:4 is `exit 1` -- a warning built
# on a hazard that does not exist, found by a readiness review rather than by the suite.
#
# A general "no false claims" check is not possible. Two specific properties are:
#
#   Every tooling script INSTALL.md tells an adopter to run must EXIST. A document naming a
#   script that was renamed or deleted sends the reader to a command that fails.
#
#   The brownfield path must reach the census. kit-entry.sh worked for weeks while INSTALL.md
#   mentioned it ZERO times, so the one mechanism that turns an unknown codebase into an
#   inventory was unreachable from the section a brownfield adopter reads -- documented as an
#   open decision in docs/design-input/2026-08-16 section 4.2 and settled by pointing at it.
( miss=0
  for s in $(grep -oE 'tooling/kit-[a-z-]+\.sh' "$KIT/INSTALL.md" | sort -u); do
    [ -f "$KIT/$s" ] || { echo "  INSTALL.md names $s, which does not exist"; miss=1; }
  done
  grep -q 'kit-entry\.sh' "$KIT/INSTALL.md" ||
    { echo "  INSTALL.md never mentions kit-entry.sh: the census is unreachable from the adoption path"; miss=1; }
  [ "$miss" = 0 ] )
check $? "INSTALL.md names only scripts that exist, and its adoption path reaches the census"

# AN EVENT KIND IS NOT A TASK STATE, and confusing them is a defect this change made FIVE times.
# `state_class` holds the canonical seven; an event carries whatever word was current when it was
# recorded, and 87 events in this repository say `progress`. So `e.kind IN (SELECT state FROM
# state_class ...)` matches nothing written before the rename, and the failure is SILENT -- the
# join simply returns no rows, so attribution, ownership, closed_at and the deleted-task notice
# all quietly did nothing. Two instances were found by conformance, then two more, then a fifth.
#
# docs/LESSONS.md section 4: "Filing a defect class is not the same as sweeping for it, and the
# sweep is the cheap half." This IS the sweep, kept. Anything reading an event kind resolves it
# through state_alias first; state_class is for classifying a task's current state.
( n=$(grep -rn "kind IN (SELECT state FROM state_class" "$KIT/tooling" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" = 0 ] || { echo "  $n site(s) compare an event kind to state_class; use state_alias:"
                    grep -rn "kind IN (SELECT state FROM state_class" "$KIT/tooling" | sed 's/^/    /'; }
  [ "$n" = 0 ] )
check $? "no query compares an event kind against the canonical-only state table"

# AND NO QUERY SPELLS THE PARTITION OUT AGAIN. The change replaced nineteen longhand copies of
# the closed set with one definition -- and the TWENTIETH was in this file, inside a query THIS
# SUITE runs, where the single-home check could not see it: that check compares the definition
# STRING, and a partition written out inside a WHERE clause is not that string. It returned 0
# where it wanted 1, and CI caught it.
#
# `tests` is searched as well as `tooling` for exactly that reason.
#
# The pattern is deliberately not quoted in this comment. Written out, it matches ITSELF and the
# step fails on its own prose -- which is what happened first, and is the same self-catch the via
# vocabulary step above records about its own first run.
( n=$(grep -rnE "state (NOT )?IN \('(done|completed|abandoned|cancelled)'" "$KIT/tooling" "$KIT/tests" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" = 0 ] || { echo "  $n site(s) spell the closed partition out longhand; join state_class:"
                    grep -rnE "state (NOT )?IN \('(done|completed|abandoned|cancelled)'" "$KIT/tooling" "$KIT/tests" | sed 's/^/    /'; }
  [ "$n" = 0 ] )
check $? "the closed partition is never written longhand, in tooling or in the suite itself"
rm -rf "$sv"
fi

if step "a tier below its floor is reported"; then
# Under-tiering is silent and it is the dangerous direction. Two of three recorded tiers in a
# real backlog were below their floor -- and a floor computed only from touched files would
# have caught NONE of them, because 7 of 8 open tasks had no commits yet. Hence the declared
# paths source, which is what this exercises.
#
# Its own directory: an earlier version of this check mutated the shared fixture and broke
# the losslessness comparison three steps later.
tf="$WORK.floor"; rm -rf "$tf"; mkdir -p "$tf"
( cd "$tf" || exit 1
  git init -q -b main 2>/dev/null
  mkdir -p .claude .project/tasks
  { echo "---"
    echo "paths.tasks:  .project/tasks"
    echo "paths.state:  .project"
    echo "tier.default: T1"
    echo "tier.rule: src/adapters/** T3"
    echo "tier.rule: src/core/** T2"
    echo "---"; } > .claude/project-profile.md
  printf -- '---
id: T-under
title: u
tier: T1
paths: src/adapters/Q.ts
---
b
' > .project/tasks/T-under.md
  printf -- '---
id: T-above
title: a
tier: T3
paths: src/core/X.ts
---
b
' > .project/tasks/T-above.md
  printf -- '---
id: T-none
title: n
tier: T0
---
b
' > .project/tasks/T-none.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  u=$(sqlite3 .project/index.db "SELECT tier_floor FROM task WHERE id='T-under';" | tr -d '\015')
  a=$(sqlite3 .project/index.db "SELECT tier_floor FROM task WHERE id='T-above';" | tr -d '\015')
  n=$(sqlite3 .project/index.db "SELECT COALESCE(tier_floor,'null') FROM task WHERE id='T-none';" | tr -d '\015')
  b=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM task WHERE tier_floor IS NOT NULL AND tier < tier_floor;" | tr -d '\015')
  [ "$u" = T3 ] && [ "$a" = T2 ] && [ "$n" = null ] && [ "$b" = 1 ] )
check $? "floor from declared paths; below flagged, above not, no-basis distinguished"
rm -rf "$tf"
fi

if step "the step filter cannot report a vacuous pass"; then
# `--only` is a development-loop convenience, but two of its failure modes are the exact
# shape this suite exists to refuse: a pattern that matches nothing reporting a clean run,
# and a filtered run reading like a whole one. Neither is visible by inspection and both
# are cheap to assert, so they are asserted rather than trusted.
#
# Every nested run is marked, and a marked run skips this step. Relying on the patterns
# below never naming this step is not enough: the `--bogus` case is a full run the moment
# its guard stops working, and that full run re-enters this step. Mutating that guard away
# turned the suite into a fork bomb, which is why the sentinel is here and not the comment
# that used to be.
if [ -n "${KIT_CONFORMANCE_NESTED:-}" ]; then
  skip "this run is itself one of those nested checks" "the step filter's own guarantees"
else
fx="$WORK.filter"; rm -rf "$fx"; mkdir -p "$fx"
export KIT_CONFORMANCE_NESTED=1
KIT="$KIT" WORK="$fx" bash "$SELF" --only 'zz-no-step-is-called-this' >"$fx/vac.out" 2>&1; rc=$?
[ "$rc" = 2 ]; check $? "a pattern matching no step exits 2 rather than passing with nothing run"
grep -q 'matched no step' "$fx/vac.out"; check $? "and names the pattern that matched nothing"

KIT="$KIT" WORK="$fx" bash "$SELF" --list >"$fx/list.out" 2>&1; rc=$?
nl=$(grep -c '^ *[0-9]' "$fx/list.out")
[ "$rc" = 0 ] && [ "${nl:-0}" -ge 2 ]; check $? "--list names the steps ($nl found) so a pattern can be chosen"

KIT="$KIT" WORK="$fx" bash "$SELF" --only 'environment' >"$fx/part.out" 2>&1
grep -q '^=== PARTIAL RUN' "$fx/part.out"; check $? "a filtered run announces itself as partial"
# The full run's tally is this line and nothing else on it. A filtered run that ever
# printed it would be indistinguishable from conformance in a pasted terminal.
grep -Eq '^=== [0-9]+ passed, [0-9]+ failed$' "$fx/part.out"; rc=$?
[ "$rc" -ne 0 ]; check $? "and never prints the full run's tally line"

KIT="$KIT" WORK="$fx" bash "$SELF" --only 'environment' --only 'validate' >"$fx/two.out" 2>&1
# Asserted on the selection line rather than by counting `=== ` headers, because the
# banners are `=== ` lines too and counting them passed this at four.
grep -qE '^ +2 of [0-9]+ steps will run\.$' "$fx/two.out"
check $? "two --only patterns select two steps, not one and not all"

# Paired with --only so that a build which stops refusing unknown arguments runs one cheap
# step rather than the whole suite. The discrimination is the same -- refused is exit 2,
# ignored is a clean exit 0 -- and the cost when it is ignored is bounded.
KIT="$KIT" WORK="$fx" bash "$SELF" --only 'environment' --bogus >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ]; check $? "an unknown argument exits 2 rather than being ignored"
unset KIT_CONFORMANCE_NESTED
rm -rf "$fx"
fi
fi

if step "entry analysis reports an undocumented choice and writes no task"; then
# ADR 0001. The entry mechanism turns a codebase into FACTS, anchored to files, and writes no
# task anywhere. Both halves are asserted here, and the presence half is why this step exists:
# design 1's fixture asserted only absences, so a kit-entry.sh consisting of `exit 0` passed it.
#
# The fixture holds three source files chosen to pin the scanner from both directions:
# retry.go carries an undocumented constant (a real choice, no explanation), cache.go carries a
# 12-line rationale block, edge.go a 9-line one. The 9-line block must appear AT ITS TRUE
# LENGTH: the tool applies no minimum on the way out, because two of ten independently
# nominated rationale sites in this repository sit in runs of 3 and 5 lines and any >=10 gate
# discards them permanently. A filter the reader applies is recoverable; one the writer applies
# is not.
#
# No `grep -P`: BSD grep on the macOS runner does not have it, and the TSV field checks are awk.
en="$WORK.entry"; rm -rf "$en"; mkdir -p "$en/src"
( cd "$en" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1

  printf 'package main\n\nconst maxRetries = 7\n' > src/retry.go
  { echo 'package main'; echo
    echo '// Cache entries are evicted on write, not on read, because a read-path eviction'
    echo '// walks the whole map under the same lock the request holds. Measured at 40ms of'
    echo '// added tail latency on a 50k-entry cache, which is worse than the memory it saves.'
    echo '// The obvious simplification -- evict lazily when a reader finds a stale entry --'
    echo '// was tried and reverted: it moves the walk onto the hot path rather than removing'
    echo '// it, and it makes eviction time depend on read traffic, so a quiet cache never'
    echo '// evicts at all and a busy one evicts twice. Do not reintroduce it without a'
    echo '// benchmark on a cache of at least 50k entries, and read the revert first.'
    echo '// The write-path walk is bounded by the batch size, which is why it is acceptable'
    echo '// here and would not be acceptable on the read path.'
    echo '// See also the eviction test, which fails if this becomes lazy again.'
    echo '// Twelve lines, deliberately: this block is the fixture for run-length 12.'
    echo 'func evict() {}'; } > src/cache.go
  { echo 'package main'; echo
    echo '// Nine lines, deliberately. This block exists to prove the scanner applies no'
    echo '// minimum length of its own: it must appear in the runs file at length 9, not be'
    echo '// filtered out. Real rationale in this repository lives in runs this short --'
    echo '// kit-guard.sh carries three lines and kit-index.sh five -- so a scanner that'
    echo '// drops short runs drops exactly the rationale a reader most needs, while'
    echo '// reporting a clean list that looks complete. That failure is invisible: the'
    echo '// output is well-formed and simply missing things, which is the shape this'
    echo '// whole suite exists to refuse. Nine comment lines, counted: an off-by-one here'
    echo '// is caught by the exact-length assertion below rather than absorbed by it.'
    echo 'func edge() {}'; } > src/edge.go

  # A doc-shaped file, so the doc_shaped column is exercised in BOTH states. The column is
  # specified by ADR 0001 and was simply absent from the first implementation -- the table had
  # ten columns where the design says eleven, and nothing here noticed, because no assertion
  # named it. An unasserted column is an unimplemented column that happens to be documented.
  mkdir -p docs && printf '# Note\n\nWhy the retry count is 7.\n' > docs/note.md
  : > src/empty.py
  printf '.eslintrc\n' > .eslintrc
  # Committed now, deleted below. It lands in the co-change graph and NOT in the census, which is
  # the only way the coverage fraction's two populations can differ inside a fixture.
  printf 'package main\n// gone\nfunc gone() {}\n' > src/gone.go
  { echo 'int main(void) {'; echo '/*'; echo 'no leading star on these lines'
    echo 'and the block still runs to its close'; echo '*/'; echo 'return 0; }'; } > src/block.c
  git add -A && git commit -q --no-verify -m "chore: seed"
  printf 'package main\n\nconst maxRetries = 7\nvar _ = maxRetries\n' > src/retry.go
  rm -f src/gone.go
  git add -A && git commit -q --no-verify -m "feat: second commit"

  before=$(ls .project/tasks 2>/dev/null | wc -l | tr -d ' ')
  bash "$KIT/tooling/kit-entry.sh" >/dev/null 2>&1 || exit 1

  R=.project/entry-report.md; F=.project/entry-facts.tsv; C=.project/entry-comment-runs.tsv
  [ -f "$R" ] && [ -f "$F" ] && [ -f "$C" ] || exit 1

  # PRESENCE. Exact values, not `!= 0`. Three source files are counted and the three files
  # kit-init.sh commits are excluded AND counted -- an exclusion nobody can see is
  # indistinguishable from a file that was missed.
  grep -qx 'tracked_files 7'   "$R" || exit 1
  grep -qx 'skipped kit-owned 3' "$R" || exit 1
  grep -qx 'commits 2'         "$R" || exit 1
  grep -qE '^history (ok|degenerate|unavailable)' "$R" || exit 1
  grep -qE '^cochange (ok|empty)' "$R" || exit 1
  grep -qx 'comment_runs 3 in 3 files' "$R" || exit 1

  # Both run lengths pinned exactly, so a scanner off by one is red, and so is one that
  # silently reimposes a minimum length and drops the 9.
  awk -F'\t' '$1=="src/cache.go" && $4==12 {f=1} END{exit !f}' "$C" || exit 1
  awk -F'\t' '$1=="src/edge.go"  && $4==9  {f=1} END{exit !f}' "$C" || exit 1
  # The undocumented choice is REPORTED as a zero, never omitted. A file with no explanation is
  # the case the whole mechanism exists to surface, and dropping it would read as "nothing to
  # ask about here".
  awk -F'\t' '$1=="src/retry.go" && $4==0 {f=1} END{exit !f}' "$F" || exit 1
  # doc_shaped is field 10, and BOTH states are pinned: a file under a docs path is 1, a source
  # file is 0. Asserting only the 1 would pass against a column hardcoded to 1.
  awk -F'	' '$1=="docs/note.md" && $10==1 {f=1} END{exit !f}' "$F" || exit 1
  awk -F'	' '$1=="src/retry.go" && $10==0 {f=1} END{exit !f}' "$F" || exit 1
  # The census reconciles: every subject file is a row or a counted exclusion.
  grep -qx 'reconciled ok' "$R" || exit 1
  # Four behaviours from the previous review round had NO assertion until now. An unasserted
  # behaviour is indistinguishable from an unimplemented one -- which is exactly how doc_shaped
  # came to be specified in ADR 0001 and in the design, absent from the code, and green anyway.
  grep -qx 'merges 0' "$R" || exit 1
  grep -qx 'skipped scanfail 0' "$R" || exit 1
  # An empty file is TEXT with no content, not binary. It gets a row with lines 0.
  awk -F'\t' '$1=="src/empty.py" && $3==0 {f=1} END{exit !f}' "$F" || exit 1
  # A /* */ block whose interior lines carry no leading * is ONE run, at its true length.
  awk -F'\t' '$1=="src/block.c" && $4==4 {f=1} END{exit !f}' "$C" || exit 1
  # A subject's own root dotfile belongs to the SUBJECT, not to the kit.
  awk -F'\t' '$1==".eslintrc" {f=1} END{exit !f}' "$F" || exit 1

  # ABSENCE. Necessary, not sufficient -- every assertion above already failed for an
  # `exit 0` implementation.
  after=$(ls .project/tasks 2>/dev/null | wc -l | tr -d ' ')
  [ "$before" = "$after" ] || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(sqlite3 .project/index.db 'SELECT COUNT(*) FROM task;' | tr -d '\015 ')" = 0 ] || exit 1


  # No artefact may contain a line that reads as a task file's own grammar.
  grep -qE '^(id|tier|state): ' "$R" "$F" "$C" && exit 1
  exit 0 )
check $? "entry analysis reports the choice, counts its exclusions, and writes no task"
rm -rf "$en"
fi

if step "co-change coverage divides by the population it counted"; then
# `cochange ok N pairs, M of T files` printed `84 of 81` on this repository: a fraction above one.
# The numerator counted every file in the co-change graph -- task files, kit-owned files, files
# deleted years ago -- and the denominator counted only subject files that exist NOW. Two different
# populations, and the tell was that the answer was impossible rather than merely wrong.
#
# This needs its own repository. The entry fixture has two commits, and `cochange.hub_pct` treats a
# file appearing in more than 20% of commits as a hub -- so at two commits EVERY file is suppressed,
# the graph is empty, and an assertion placed there passes on `cochange empty` without ever reaching
# the branch. The first version of this check did exactly that and survived the mutation that
# reintroduces the defect.
cc="$WORK.cochange"; rm -rf "$cc"; mkdir -p "$cc/src"
( cd "$cc" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  # gone.go is committed and then deleted: it lives in the graph and not in the census, which is
  # the only way a fixture can make the two populations differ.
  printf 'package main\nfunc gone() {}\n' > src/gone.go
  git add -A && git commit -q --no-verify -m "chore: seed"
  # Twelve commits, each touching a disjoint pair, so no file exceeds the 20% hub threshold and
  # pairs actually form.
  i=1
  while [ "$i" -le 12 ]; do
    j=$((i + 1))
    printf 'package main\n// f%s\nfunc f%s() {}\n' "$i" "$i" > "src/f$i.go"
    printf 'package main\n// g%s\nfunc g%s() {}\n' "$j" "$j" > "src/g$j.go"
    git add -A && git commit -q --no-verify -m "feat: pair $i"
    i=$((i + 1))
  done
  rm -f src/gone.go
  git add -A && git commit -q --no-verify -m "chore: drop gone"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-entry.sh" >/dev/null 2>&1 || exit 1
  R=.project/entry-report.md
  # The branch must actually be REACHED. On `cochange empty` everything below is vacuous, which is
  # how the first version of this check passed while measuring nothing.
  ccline=$(grep '^cochange ok ' "$R") || { echo "  the co-change graph is empty -- this step measured nothing"; exit 1; }
  m=$(printf '%s' "$ccline" | sed 's/.* \([0-9][0-9]*\) of \([0-9][0-9]*\) files.*/\1/')
  t=$(printf '%s' "$ccline" | sed 's/.* \([0-9][0-9]*\) of \([0-9][0-9]*\) files.*/\2/')
  [ "$m" -le "$t" ] || { echo "  coverage $m exceeds census $t"; exit 1; }
  # Positive half: the populations DO differ here, so the notice naming the difference must appear.
  # The inequality alone would still pass against a numerator counted over the whole graph.
  grep -q 'outside the census' "$R" || { echo "  the out-of-census notice is missing"; exit 1; }
  exit 0 )
check $? "co-change coverage counts subject files on both sides, and names what the graph holds beyond them"
rm -rf "$cc"
fi

if step "a proposal that cannot be pasted safely is refused, and a question is not a checkbox"; then
# The judgement half of the entry mechanism produces prose, and a fixture cannot gate a model.
# What it CAN gate is the file the orchestrator wrote from that prose, which is what --check reads.
#
# Two of these are the design's own rules rather than formatting taste. A question carries no
# checkbox, because the task this serves says an undocumented choice is a QUESTION and never work,
# and a tickbox invites closing instead of answering. And a candidate title must survive being
# pasted into a shell -- ADR 0001 recorded that as enforced by nobody, on the grounds that the tool
# never sees the titles, which stopped being true the moment the tool read the written proposal.
pr="$WORK.prop"; rm -rf "$pr"; mkdir -p "$pr"
( cd "$pr" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A && git commit -q --no-verify -m "chore: seed"
  { echo '## Open questions'; echo
    echo '1. Why is the retry count 7?'; echo '   evidence: src/retry.go:3'; echo '   answer:'; echo
    echo '## Candidate tasks'; echo
    echo '- [ ] Document the retry budget'
    echo "      kit-task.sh --title 'Document the retry budget' --tier T1"; echo
    echo '## Could not determine'; echo
    echo '- co-change: empty'; } > good.md

  bash "$KIT/tooling/kit-entry.sh" --check good.md >out.txt 2>&1 || exit 1
  grep -q 'proposal conforms' out.txt || exit 1
  # It said "none filed by this check", so prove it: no task file appeared.
  [ "$(ls .project/tasks 2>/dev/null | wc -l | tr -d ' ')" = 0 ] || exit 1

  # Each refusal separately, because one boolean over six conditions cannot say which broke.
  want() { bash "$KIT/tooling/kit-entry.sh" --check "$1" >/dev/null 2>&1; [ "$?" = 1 ] || { echo "  not refused: $2"; return 1; }; }
  sed "s/Document the retry budget' --tier/Document \`whoami\` budget' --tier/" good.md > backtick.md
  sed "s/Document the retry budget' --tier/Document \$(id) budget' --tier/"    good.md > dollar.md
  sed "s/Document the retry budget' --tier/Doc; rm -rf . budget' --tier/"      good.md > semi.md
  sed 's/^1\. Why/- [ ] Why/'            good.md > tickbox.md
  grep -v 'Could not determine'          good.md > nogaps.md
  grep -v 'kit-task.sh --title'          good.md > noline.md
  sed "s/Document the retry budget' --tier/Doc's budget' --tier/"  good.md > quote.md
  sed "s/Document the retry budget' --tier/Doc | tee b' --tier/"   good.md > pipe.md
  sed "s/Document the retry budget' --tier/Doc \& b' --tier/"      good.md > amp.md
  sed "s/Document the retry budget' --tier/Doc < b' --tier/"       good.md > lt.md
  sed "s/Document the retry budget' --tier/Doc > b' --tier/"       good.md > gt.md
  rc=0
  # Every character the docs claim is refused, not a sample of three. ADR 0001 asserted that a
  # conformance step proved EACH refusal while only three were tested -- and the quote, the one
  # that ends the quoting, was the one silently broken.
  want quote.md    'a single quote in a title'  || rc=1
  want pipe.md     'a pipe in a title'          || rc=1
  want amp.md      'an ampersand in a title'    || rc=1
  want lt.md       'a < in a title'             || rc=1
  want gt.md       'a > in a title'             || rc=1
  # Scoping the counts made these two INVISIBLE rather than wrong, which trades one silent state
  # for another. They are refused.
  { cat good.md; echo "      kit-task.sh --title 'Stray line' --tier T1"; } > stray.md
  sed 's/^- co-change: empty/- [ ] co-change: empty/' good.md > latebox.md
  want stray.md    'a kit-task.sh line outside the section' || rc=1
  want latebox.md  'a checkbox after the candidate section' || rc=1
  want backtick.md 'a backtick in a title'      || rc=1
  want dollar.md   'a $(...) in a title'        || rc=1
  want semi.md     'a semicolon in a title'     || rc=1
  want tickbox.md  'a checkbox on a question'   || rc=1
  want nogaps.md   'no could-not-determine'     || rc=1
  want noline.md   'a candidate with no kit-task.sh line' || rc=1
  # A usage error is NOT a refusal: exit 2 means the question could not be asked.
  bash "$KIT/tooling/kit-entry.sh" --check /nonexistent >/dev/null 2>&1; [ "$?" = 2 ] || rc=1
  exit $rc )
check $? "a conforming proposal passes, thirteen malformed ones are refused, and --check files nothing"

# THE CANDIDATE GRAMMAR CARRIES DISPOSITIONS NOW, and widening a whitelist is the fail-open
# direction by construction: every flag added is a shape that used to be refused. The comment on
# that regex records two earlier attempts that both failed open, one of them green on ubuntu and
# red on macos, so this is checked on both rather than reasoned about.
#
# THE FIRST ASSERTION IS THE REGRESSION ONE. A widened pattern that stopped accepting the
# original four-flag line would break every proposal ever written, and would do it while all the
# new cases passed.
dp="$WORK.disp"; rm -rf "$dp"; mkdir -p "$dp"
( cd "$dp" || exit 1
  # A GIT REPOSITORY **AND AN ADOPTED KIT**. kit-entry.sh runs kit_root and kit_active before it
  # reaches the --check branch, so a bare mkdir fails with "not a git repository" and a bare
  # `git init` fails with "kit not adopted here". Neither message matches `conforms` OR `not safe
  # to paste`, so the accept cases and the refuse cases BOTH fail and the step reports nothing
  # about the grammar it exists to test.
  #
  # Worth stating because it was got wrong twice in a row: a broken fixture does not announce
  # itself as broken, it announces the feature as broken. And had this step contained only
  # refusal cases it would have gone GREEN -- every line "refused", for entirely the wrong
  # reason. The accept cases are what make the fixture's own health observable.
  git init -q -b main 2>/dev/null
  mkdir -p .claude
  { echo "---"; echo "paths.tasks:  .project/tasks"; echo "paths.state:  .project"
    echo "tier.default: T1"; echo "---"; } > .claude/project-profile.md
  prop() { { printf '## Open questions\n\n1. Why?\n   evidence: a.go:1\n   answer:\n\n'
             printf '## Candidate tasks\n\n- [ ] C\n      evidence: a.go:1\n      %s\n\n' "$1"
             printf '## Could not determine\n\n- nothing\n'; } > p.md
           bash "$KIT/tooling/kit-entry.sh" --check p.md 2>&1; }
  ok()  { printf '%s' "$(prop "$1")" | grep -q 'conforms' ||
            { echo "  REFUSED but should pass: $1"; exit 1; }; }
  no()  { printf '%s' "$(prop "$1")" | grep -q 'not safe to paste' ||
            { echo "  ACCEPTED but should refuse: $1"; exit 1; }; }

  ok "kit-task.sh --title 'Plain' --tier T1 --lang go --epic core"
  ok "kit-task.sh --title 'Already there' --state completed --via manual --paths 'docs/a.md'"
  ok "kit-task.sh --title 'Moot' --state cancelled"
  ok "kit-task.sh --title 'Glob' --paths 'src/adapters/**'"
  ok "kit-task.sh --title 'Blocked' --blocked-by T-x,T-y"
  # Legacy spellings stay valid input everywhere, including here: a census reading a repository
  # that predates ADR 0008 quotes what it finds rather than translating it.
  ok "kit-task.sh --title 'Legacy' --state done"
  # ORDER MUST NOT MATTER. The first version of this grammar was a fixed sequence of optional
  # groups, so flags had to appear in the order the pattern listed them -- and the refusal said
  # "not safe to paste", which is not what was wrong with the line. CI caught it on a case this
  # suite had written in the obvious order rather than the pattern's order.
  ok "kit-task.sh --title 'Reordered' --state completed --tier T1"
  ok "kit-task.sh --title 'Reordered' --epic core --lang go"
  ok "kit-task.sh --title 'Bare'"

  no "kit-task.sh --title 'Bad state' --state nonsense"
  no "kit-task.sh --title 'Bad via' --via nobody"
  # --paths reaches a frontmatter key and the line is PASTED into a shell, so every metacharacter
  # that could make it more than a path is refused. One case per class, not one case in general.
  no "kit-task.sh --title 'Semi' --paths 'src/a; rm -rf /'"
  no "kit-task.sh --title 'Subst' --paths 'src/\$(whoami)'"
  no "kit-task.sh --title 'Tick' --paths 'src/\`id\`'"
  no "kit-task.sh --title 'Pipe' --paths 'src/a|b'"
  no "kit-task.sh --title 'Redir' --paths 'src/a>b'"
  # An unknown flag, and a valid line with a shell command appended. Order-independence is a
  # REPEATED alternation, so the risk it introduces is that anything could repeat -- these pin
  # that only the named flags may, and that the line still has to end where it says it does.
  no "kit-task.sh --title 'Unknown flag' --frobnicate x"
  no "kit-task.sh --title 'Trailing' --tier T1 ; rm -rf /" )
check $? "candidate dispositions are accepted, and a value outside either vocabulary is not"

# AND THE GATE READS THE VOCABULARY RATHER THAN RESTATING IT. A literal list in kit-entry.sh
# would be the twenty-sixth copy of the rule docs/adr/0008 gave one home, in the file whose job
# is refusing unsafe input -- where going stale fails CLOSED and looks like a malformed proposal.
( grep -qE 'kit_state_vocab|kit_state_legacy' "$KIT/tooling/kit-entry.sh" ||
    { echo "  kit-entry.sh does not read the state vocabulary from its definition"; exit 1; }
  grep -qE "state \((created|completed|cancelled)\|" "$KIT/tooling/kit-entry.sh" &&
    { echo "  kit-entry.sh spells the state vocabulary out in its pattern"; exit 1; }
  exit 0 )
check $? "the candidate grammar derives its vocabularies instead of copying them"
rm -rf "$dp"
rm -rf "$pr"
fi

if step "greenfield and an imported history are the same mechanism, not special cases"; then
# The task's first acceptance criterion is that ONE mechanism handles all three starting
# conditions -- greenfield being brownfield with an empty inventory, modernization being
# brownfield plus a stack delta. That claim is cheap to make and was, in the design, entirely
# untested: the branches existed and had never once executed.
#
# THIS STEP COVERS TWO OF THE THREE. Greenfield and an imported history are here. MODERNIZATION IS
# NOT: its source-to-target delta lives in the solution overlay, which is unbuilt, so there is
# nothing to express it with and nothing to assert. Deferred by the operator on 2026-08-16 rather
# than quietly counted as covered -- see T-20260815-ac6-modernization-delta-is-claimed-but-u. An
# earlier version of this comment named all three conditions above a step that tests two, which is
# the shape where a reader checks the box because the comment said so.
#
# Three cases, because a state that is always the same value is not a state:
#   A  greenfield        no subject files at all      -> tracked_files 0, and it must not hang
#   B  imported history  files, exactly one commit    -> history degenerate, facts still full
#   C  the same repo     after a second commit        -> history ok
# C is what stops B passing for a script with `history degenerate` hardcoded. Without it the
# other two assertions are satisfied by a constant.
#
# Case A is also the `awk` with no file operands hazard, which this repo has been bitten by:
# an awk invoked with zero files reads stdin and waits forever, and a suite that hangs is
# read as a slow machine rather than as a defect.
gf="$WORK.green"; gi="$WORK.import"; rm -rf "$gf" "$gi"; mkdir -p "$gf" "$gi"
R=.project/entry-report.md; F=.project/entry-facts.tsv; C=.project/entry-comment-runs.tsv
( cd "$gf" || exit 1
  # --- A. greenfield: the kit is adopted and nothing else exists yet ---
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A && git commit -q --no-verify -m "chore: kit only"
  bash "$KIT/tooling/kit-entry.sh" >/dev/null 2>&1 || exit 1
  grep -qx 'tracked_files 0' "$R" || exit 1
  grep -qx 'comment_runs 0 in 0 files' "$R" || exit 1
  grep -qx 'markers 0' "$R" || exit 1
  # The facts file is a HEADER and no rows -- not an empty file, which would be
  # indistinguishable from a run that died before writing anything.
  [ "$(awk 'END{print NR}' "$F")" = 1 ] || exit 1
  [ "$(awk 'END{print NR}' "$C")" = 0 ] || exit 1
  exit 0 )
gfa=$?
# NOT `( ... ) || exit 1`. At top level that `exit` terminates the whole suite: the step prints
# its heading, nothing else, no verdict and no tally, and CI sees a non-zero status with no FAIL
# line to explain it. A mutation found this -- emptying the facts header made case A fail, and
# the run vanished instead of reporting. Each case's status is captured and both are handed to
# `check`, which is the only thing that records a result.
( cd "$gi" || exit 1
  # --- B. a vendor import: the kit files and the whole subject in ONE commit ---
  # It has to be one commit. Adopting, committing, then adding the sources is a TWO-commit
  # repository and reports `history ok` -- which is what the first version of this fixture
  # actually built, so it asserted `degenerate` against a repo that was not.
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  mkdir -p src
  printf 'package main\n// one\n// two\n// three\nfunc a() {}\n' > src/a.go
  printf 'package main\nfunc b() {}\n' > src/b.go
  git add -A && git commit -q --no-verify -m "chore: vendor import"
  bash "$KIT/tooling/kit-entry.sh" >/dev/null 2>&1 || exit 1
  grep -qx 'tracked_files 2' "$R" || exit 1
  grep -qx 'commits 1' "$R" || exit 1
  grep -qx 'history degenerate: single-commit history' "$R" || exit 1
  # The history is degenerate; the FILE FACTS are not. A single-commit subject must still get
  # its census, or "modernization is brownfield plus a delta" is false at the first subject
  # that arrives as a vendor drop.
  awk -F'\t' '$1=="src/a.go" && $4==3 {f=1} END{exit !f}' "$C" || exit 1

  # --- C. the same repository, one commit later ---
  # Without this, B is satisfied by a script with the string hardcoded. A state that only ever
  # takes one value is not a state.
  printf 'package main\nfunc b() { _ = 1 }\n' > src/b.go
  git add -A && git commit -q --no-verify -m "feat: second"
  bash "$KIT/tooling/kit-entry.sh" >/dev/null 2>&1 || exit 1
  grep -qx 'history ok' "$R" || exit 1
  grep -qx 'commits 2' "$R" || exit 1
  exit 0 )
gib=$?
[ "$gfa" = 0 ] && [ "$gib" = 0 ]
check $? "greenfield reports zeroes without hanging, a one-commit import reports degenerate history, and a second commit clears it"
[ "$gfa" = 0 ] || echo "  ^ the greenfield case failed"
[ "$gib" = 0 ] || echo "  ^ the imported-history case failed"
rm -rf "$gf" "$gi"
fi

if step "validate.py"; then
(cd "$KIT" && { python3 validate.py >/dev/null 2>&1 || python validate.py >/dev/null 2>&1; })
check $? "validate.py exits 0"
fi

if step "census allocation records all three attribution variables, or refuses"; then
# D3 names three variables that must be recorded for a re-run to be attributable -- the subject
# tree, the auditor, and the kit -- and says "a diff in which more than one moved is
# uninterpretable". Before this, none of them could be recorded at all: capture refused a missing
# manifest and nothing wrote one, so D3 was a caveat in prose in a document that calls it "a
# control that can fail, not a caveat in prose".
#
# WHAT THE KIT MAY DERIVE IS THE POINT OF THE TEST. kit_sha and kit_version are about the kit and
# are computed. subject_sha and subject_dirty are NOT: the design says deriving them here would
# record the kit's own HEAD as the subject, and a census whose subject_sha is silently the kit's
# is worse than one with none, because it looks attributable. So the operator supplies them and a
# manifest missing either is refused rather than written with a blank -- a blank attribution
# variable is indistinguishable from one that did not move.
#
# Every assertion matches its own diagnostic, and NO ASSERTION USES A PIPE: this file runs under
# `set -o pipefail`, and a command that exits non-zero by design piped into grep reports the
# command's status, not grep's. That cost a green-on-two-platforms, red-on-macOS run once.
if ! command -v python3 >/dev/null 2>&1; then
  skip "python3 is not on PATH" "census allocation records the attribution variables"
else
ca="$WORK.alloc"; rm -rf "$ca"; mkdir -p "$ca"
( cd "$ca" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1 || { echo "  kit-init failed in the fixture"; exit 1; }

  ini() { printf '%s' "$(bash "$KIT/tooling/kit-claim.sh" --census "$@" 2>&1)"; }
  want() { _m=$1; shift; _o=$(ini "$@")
           case "$_o" in *"$_m"*) return 0 ;; esac
           echo "  missing diagnostic: $_m"; return 1; }

  FULL="--purpose evaluation --subject-repo r --subject-sha 05c56eb --subject-dirty 0"
  FULL="$FULL --source-document docs/ROADMAP.md --auditor-model opus --units u1,u2"

  # D4: purpose is declared, never defaulted.
  want 'purpose is required' c1 --init --subject-repo r --subject-sha s --subject-dirty 0 \
       --source-document d --auditor-model m --units u1 || exit 1
  # D3, variable one: the subject tree.
  want 'subject_sha is required' c1 --init --purpose p --subject-repo r --subject-dirty 0 \
       --source-document d --auditor-model m --units u1 || exit 1
  want 'subject_dirty must be exactly 0 or 1' c1 --init --purpose p --subject-repo r \
       --subject-sha s --subject-dirty yes --source-document d --auditor-model m --units u1 || exit 1
  # D3, variable two: the auditor.
  want 'auditor_model is required' c1 --init --purpose p --subject-repo r --subject-sha s \
       --subject-dirty 0 --source-document d --units u1 || exit 1
  # F1c and F1b, on the write path.
  want 'units is required' c1 --init --purpose p --subject-repo r --subject-sha s \
       --subject-dirty 0 --source-document d --auditor-model m || exit 1
  want 'is not a usable name' c1 --init --purpose p --subject-repo r --subject-sha s \
       --subject-dirty 0 --source-document d --auditor-model m --units 'a b' || exit 1
  want 'is declared twice' c1 --init --purpose p --subject-repo r --subject-sha s \
       --subject-dirty 0 --source-document d --auditor-model m --units u1,u1 || exit 1
  want 'must contain only letters' 'c/1' --init --purpose p --subject-repo r --subject-sha s \
       --subject-dirty 0 --source-document d --auditor-model m --units u1 || exit 1

  # Nothing above may have created anything.
  [ -e .project/census/c1/manifest.json ] && { echo "  a refused --init still wrote a manifest"; exit 1; }

  _o=$(ini c1 --init $FULL)
  case "$_o" in *allocated*) ;; *) echo "  refused a complete --init: $_o"; exit 1 ;; esac

  # ALL THREE VARIABLES PRESENT AND NON-EMPTY. Asserted by reading the file, not by trusting the
  # success line -- the whole defect class here is a record that looks complete and is not.
  m=.project/census/c1/manifest.json
  for k in subject_sha subject_dirty auditor_model kit_sha kit_version; do
    grep -q "\"$k\"" "$m" || { echo "  manifest has no $k"; exit 1; }
  done
  grep -q '"kit_sha": ""' "$m" && { echo "  kit_sha was written blank"; exit 1; }
  # kit_sha must be the KIT's HEAD, never the subject's -- the subject repo here has no commits,
  # so a derived-from-cwd implementation would produce an empty or different value.
  ksha=$(git -C "$KIT" rev-parse HEAD 2>/dev/null)
  grep -q "$ksha" "$m" || { echo "  kit_sha is not the kit's HEAD"; exit 1; }
  grep -q '"subject_sha": "05c56eb"' "$m" || { echo "  subject_sha is not what the operator gave"; exit 1; }

  # A census is allocated once; re-init must refuse rather than re-point existing artefacts.
  want 'already exists' c1 --init $FULL || exit 1

  # And capture works against what allocation wrote -- the two halves must actually meet.
  # F1d MADE THAT LITERAL, and this fixture was the first thing it caught: the payload said
  # `"source":"d"` against a manifest allocating `docs/ROADMAP.md`, which is exactly the
  # contradiction `3e76f904` describes, sitting in the suite that was meant to prove the two
  # halves meet. The reply now audits the document the census declares.
  printf '%s' '{"source":"docs/ROADMAP.md","subject":"U","claims":[]}' |
    bash "$KIT/tooling/kit-claim.sh" --census c1 --unit u1 --json >/dev/null 2>&1 ||
    { echo "  capture refused a manifest that --init wrote"; exit 1; }
  exit 0 )
check $? "all three D3 variables are recorded, kit_sha is the kit's, and a census allocates once"
rm -rf "$ca"
fi
fi

if step "census capture refuses what it cannot verify, and writes the rest verbatim"; then
# Step 1 of the census store: `kit-claim.sh --census ID --unit NAME --json`. The store's own
# sequence says of it "Durability is complete at this step and nothing is locked in", so this
# tests durability and refusal and nothing about identity or derivation.
#
# EVERY REFUSAL IS MATCHED ON ITS OWN DIAGNOSTIC, NOT ON A NON-ZERO EXIT. The first version of
# this step asserted only that capture failed, and BOTH mutations of the code passed it: delete
# the `.`/`..` guard and `..` is still refused one step later by the absent-manifest check;
# delete the absent-manifest refusal and it is still refused by the manifest reader. A test that
# accepts any refusal cannot tell a guard that fires from a guard that has been removed, which is
# the control-that-cannot-fail shape this suite exists to refuse. Matching the message is what
# makes each assertion name the guard it is testing.
#
# Two assertions are not refusals, and they are the ones the design turns on: the artefact is
# byte-identical to what was sent, and a MALFORMED reply is still captured. F12 -- "The raw reply
# is saved BEFORE validation, so a unit that fails validation still has its data."
cc="$WORK.census"; rm -rf "$cc"; mkdir -p "$cc"
( cd "$cc" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1 || { echo "  kit-init failed in the fixture"; exit 1; }

  PAY='{"source":"d.md","subject":"U","narrative":"n","claims":[]}'
  # NO PIPE ANYWHERE IN AN ASSERTION, and the first version of this step got it wrong on the one
  # platform it was not developed on. `cap ... | grep -q` passed on Linux and Windows and FAILED on
  # macOS: grep -q exits on its first match, printf then takes EPIPE, and under `set -o pipefail`
  # the pipeline reports printf's failure rather than grep's success -- so a diagnostic that WAS
  # present read as missing. The licence step below records the same trap in the other direction.
  # Capture into a variable and match with `case`, which involves no second process at all.
  cap() { printf '%s' "$(printf '%s' "$PAY" | bash "$KIT/tooling/kit-claim.sh" "$@" 2>&1)"; }
  want() { _m=$1; shift; _out=$(cap "$@")
           case "$_out" in *"$_m"*) return 0 ;; esac
           echo "  missing diagnostic: $_m"; return 1; }

  want 'no manifest at' --census c1 --unit u1 --json || exit 1
  [ -e .project/census/c1/u1.json ] && { echo "  wrote an artefact with no manifest"; exit 1; }

  mkdir -p .project/census/c1
  printf '%s' '{"units":["u1"]}' > .project/census/c1/manifest.json
  want "no non-empty 'purpose'" --census c1 --unit u1 --json || exit 1
  printf '%s' '{"purpose":"   ","units":["u1"]}' > .project/census/c1/manifest.json
  want "no non-empty 'purpose'" --census c1 --unit u1 --json || exit 1
  printf '%s' '{"purpose":"evaluation"}' > .project/census/c1/manifest.json
  want "no 'units' array" --census c1 --unit u1 --json || exit 1

  # F1d, manifest level. Asserted BEFORE the valid capture so the "nothing was written"
  # half means something: at this point in the fixture no artefact exists yet.
  printf '%s' '{"purpose":"evaluation","units":["u1"]}' > .project/census/c1/manifest.json
  want "no non-empty 'source_document'" --census c1 --unit u1 --json || exit 1
  [ -e .project/census/c1/u1.json ] && { echo "  captured into a census with no source_document"; exit 1; }

  printf '%s' '{"purpose":"evaluation","source_document":"d.md","units":["u1"]}' > .project/census/c1/manifest.json
  want 'is not declared in' --census c1 --unit u2 --json || exit 1

  # F1b, and the two axes are asserted SEPARATELY because the charset alone admits `.` and `..`
  # -- kit-plan.sh's own pattern does -- and either resolves the census directory to its parent.
  want 'must contain only letters' --census 'c/1' --unit u1 --json || exit 1
  want 'must contain only letters' --census c1 --unit 'u 1' --json || exit 1
  want "may not be '.' or '..'" --census .. --unit u1 --json || exit 1
  want "may not be '.' or '..'" --census c1 --unit .. --json || exit 1
  want "may not be '.' or '..'" --census c1 --unit . --json || exit 1

  _out=$(printf '' | bash "$KIT/tooling/kit-claim.sh" --census c1 --unit u1 --json 2>&1)
  case "$_out" in *'empty reply on stdin'*) ;;
    *) echo "  an empty reply was not refused by name"; exit 1 ;; esac
  [ -e .project/census/c1/u1.json ] && { echo "  wrote an artefact for an empty reply"; exit 1; }

  _out=$(cap --census c1 --unit u1 --json)
  case "$_out" in *captured*) ;; *) echo "  refused a valid capture"; exit 1 ;; esac
  printf '%s\n' "$PAY" > expected.json
  cmp -s expected.json .project/census/c1/u1.json || { echo "  artefact is not verbatim"; exit 1; }

  _out=$(printf 'not json at all' | bash "$KIT/tooling/kit-claim.sh" --census c1 --unit u1 --json 2>&1) ||
    { echo "  refused a malformed reply, losing its data"; exit 1; }
  grep -q 'not json at all' .project/census/c1/u1.json ||
    { echo "  malformed reply was not captured verbatim"; exit 1; }
  case "$_out" in *'source NOT CHECKED (F1d)'*) ;;
    *) echo "  an unchecked unit entered the census without saying so"; exit 1 ;; esac

  # F1d, `3e76f904`. THE ONLY REFUSAL IN THIS SCRIPT THAT WRITES THE FILE FIRST, so it is
  # asserted on three things at once: a non-zero exit, its own diagnostic naming BOTH documents,
  # and the artefact still on disk byte-for-byte. A refusal after the write does not weaken F12,
  # and this is what proves it rather than asserting it.
  #
  # REDIRECTED FROM A FILE, NOT PIPED. The status of the capture is the assertion here, and under
  # `set -o pipefail` a pipeline reports the wrong member's status -- the trap recorded above.
  printf '%s\n' '{"source":"OTHER.md","subject":"U","narrative":"n","claims":[]}' > mismatch.json
  _out=$(bash "$KIT/tooling/kit-claim.sh" --census c1 --unit u1 --json < mismatch.json 2>&1) &&
    { echo "  a unit auditing another document was accepted"; exit 1; }
  case "$_out" in *'audits a different document'*) ;;
    *) echo "  the F1d mismatch was not refused by name"; exit 1 ;; esac
  case "$_out" in *'source_document: d.md'*) ;;
    *) echo "  the refusal did not name the document the census declares"; exit 1 ;; esac
  case "$_out" in *'reply source:'*'OTHER.md'*) ;;
    *) echo "  the refusal did not name the document the reply audits"; exit 1 ;; esac
  cmp -s mismatch.json .project/census/c1/u1.json ||
    { echo "  a unit refused by F1d lost its data (F12)"; exit 1; }

  # An envelope that parses and omits `source` is refused rather than skipped: skipping it is an
  # opt-out from the constraint, which is a check that cannot fail.
  printf '%s\n' '{"subject":"U","narrative":"n","claims":[]}' > nosource.json
  _out=$(bash "$KIT/tooling/kit-claim.sh" --census c1 --unit u1 --json < nosource.json 2>&1) &&
    { echo "  a reply with no source opted out of F1d"; exit 1; }
  case "$_out" in *"carries no 'source'"*) ;;
    *) echo "  the missing source was not refused by name"; exit 1 ;; esac
  cmp -s nosource.json .project/census/c1/u1.json ||
    { echo "  a reply refused for having no source lost its data (F12)"; exit 1; }
  exit 0 )
check $? "each capture guard is asserted by its own diagnostic, and a valid reply lands verbatim"
rm -rf "$cc"
fi

if step "every committed census artefact audits the document its manifest declares"; then
# F1d against the RECORD rather than against a fixture. `3e76f904` is a defect in the shipped
# artefact format, so the assertion that matters is about the artefacts this repository has
# actually committed -- the first census was captured before the constraint existed and is
# asserted here rather than assumed to have been consistent.
#
# The count is printed in the result line on purpose. A tree with no census passes this step
# vacuously, and a reader who cannot see "0 checked" cannot tell that apart from a real pass --
# the same reason the vocabulary step names the number of agents it found.
f1d=0; f1dn=0
for _man in "$KIT"/.project/census/*/manifest.json; do
  [ -f "$_man" ] || continue
  _cd=$(dirname "$_man")
  for _art in "$_cd"/*.json; do
    [ -f "$_art" ] || continue
    case "$_art" in */manifest.json) continue ;; esac
    f1dn=$((f1dn+1))
    _v=$(MAN="$_man" ART="$_art" python3 "$KIT/tooling/kit_manifest.py" --source 2>&1)
    case "$_v" in
      OK) ;;
      *) echo "  ${_art#$KIT/}: $_v"; f1d=1 ;;
    esac
  done
done
check $f1d "$f1dn committed census artefact(s) audit the document their manifest declares"
fi

if step "a verbatim artefact may cite a foreign home path, and nothing else may"; then
# `627b9764`: validate.py walks the whole tree and fails on /home/ or /Users/ in any .json.
# A census artefact is an auditor's reply about ANOTHER repository and legitimately cites that
# repository's evidence paths, so a single foreign census would have turned `commands.test`
# permanently red. Reproduced 2026-09-09 with a realistic artefact before the exemption existed.
#
# THE EXEMPTION IS THE RISK, NOT THE CHECK. Weakening this check is how a real baked path gets
# through -- validate.py's own comment records a previous narrowing that silently discarded
# a real developer path. So this step asserts the exemption is narrow on BOTH axes it claims:
# a .sh in the very same directory still fails, and the same .json one directory up still fails.
# A step that only proved the artefact passes would be a check that cannot fail.
if ! command -v python3 >/dev/null 2>&1; then
  skip "python3 is not on PATH" "the verbatim-artefact exemption is narrow"
else
va="$WORK.artefact"; rm -rf "$va"; mkdir -p "$va/docs/EXPERIMENTS/c1" "$va/.claude-plugin"
cp "$KIT/validate.py" "$va/validate.py"
printf '{
  "name": "x",
  "license": "Apache-2.0"
}
' > "$va/.claude-plugin/plugin.json"
cp "$KIT/LICENSE" "$va/LICENSE"; : > "$va/NOTICE"
# THE FIXTURE CANNOT BE A LITERAL HERE. This file is a .sh, so validate.py scans it -- writing
# the payload out in full would make the suite fail its own check, which it did on the first
# attempt. `/home/alice` alone does not match (the regex needs a further `/`), so the path is
# assembled at runtime and no matching literal exists in the file.
PAY_DIR="/home/alice"
PAY='{"evidence":"'"$PAY_DIR"'/subject/src/tls.rs:88"}'
( cd "$va" || exit 1
  # Capture then match, for the reason the licence step below records: this file runs under
  # `set -o pipefail`, so a pipe would carry validate.py's own non-zero status past the grep.
  v() { printf '%s' "$(python3 validate.py 2>&1)"; }
  printf '%s' "$PAY" > docs/EXPERIMENTS/c1/unit.json          # the exempt case
  v | grep -q 'absolute path baked in' && { echo "  artefact .json was still refused"; exit 1; }
  printf '%s' "$PAY" > docs/EXPERIMENTS/c1/unit.sh            # same dir, executable
  v | grep -q 'absolute path baked in' || { echo "  a .sh in an artefact dir was exempted"; exit 1; }
  rm -f docs/EXPERIMENTS/c1/unit.sh
  printf '%s' "$PAY" > docs/outside.json                      # .json, outside the roots
  v | grep -q 'absolute path baked in' || { echo "  a .json outside the roots was exempted"; exit 1; }
  rm -f docs/outside.json
  # And the second declared root behaves the same as the first.
  mkdir -p .project/census/c1
  printf '%s' "$PAY" > .project/census/c1/unit.json
  v | grep -q 'absolute path baked in' && { echo "  census artefact was refused"; exit 1; }
  exit 0 )
check $? "an artefact .json is exempt; a .sh beside it and a .json outside the roots are not"
rm -rf "$va"
fi
fi

if step "the declared licence and the LICENSE file are compared"; then
# validate.py resolves ROOT from its own location, so a copy of it in a scratch tree checks
# that tree. Without this, the licence check would be exercised only by this repository
# being correct -- which proves the check RUNS, and never that it can fail. Two files each
# holding half of one fact is the shape that produced the check; nothing compared them, so
# a relicence could move the declaration and leave the text, and stay green.
if ! command -v python3 >/dev/null 2>&1; then
  skip "python3 is not on PATH" "the declared licence is compared with LICENSE"
else
lc="$WORK.lic"; rm -rf "$lc"; mkdir -p "$lc/.claude-plugin"
cp "$KIT/validate.py" "$lc/validate.py"
decl() { printf '{\n  "name": "x",\n  "license": "%s"\n}\n' "$1" > "$lc/.claude-plugin/plugin.json"; }
( cd "$lc" || exit 1
  # Capture, then match. This file runs under `set -o pipefail` and validate.py exits 1 by
  # design on every case below except the first two -- so `validate.py | grep -q` would carry
  # validate.py's status past a grep that matched, and every assertion that a control FIRES
  # would read as the assertion failing. The trap belongs to any checker tested for its
  # non-zero exit, which is most of them.
  v() { printf '%s' "$(python3 validate.py 2>&1)"; }
  decl Apache-2.0; cp "$KIT/LICENSE" LICENSE; : > NOTICE
  python3 validate.py >/dev/null 2>&1 || exit 1
  decl MIT                                      # the declaration moved, the text did not
  v | grep -q 'FAIL  licence' || exit 1
  decl Apache-2.0; rm -f NOTICE                 # section 4(d) with nothing to reproduce
  v | grep -q 'no NOTICE file' || exit 1
  : > NOTICE; decl EUPL-1.2                     # unknown id: unverified, not verified-clean
  v | grep -q 'warn  licence' || exit 1 )
check $? "agreement passes, and each way of disagreeing is reported"
rm -rf "$lc"
fi
fi

if step "deterministic fixture" fixture; then
rm -rf "$WORK"; mkdir -p "$WORK/src" "$WORK/lib"; cd "$WORK" || exit 1
export GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.com
export GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.com
export GIT_AUTHOR_DATE="2026-01-01T00:00:00+00:00" GIT_COMMITTER_DATE="2026-01-01T00:00:00+00:00"
git init -q -b main; git config core.autocrlf false; git config commit.gpgsign false
bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
printf -- '---\nid: T-a\ntitle: bound retry\ntier: T2\nlang: go\nepic: e1\n---\n\nbody\n' > .project/tasks/T-a.md
printf -- '---\nid: T-b\ntitle: add jitter\ntier: T1\nlang: go\nepic: e1\nblocked_by: T-a\n---\n\nbody\n' > .project/tasks/T-b.md
printf 'seed\n' > README.md
git add -A && git commit -q --no-verify -m "chore: seed"
# Kept for the FINGERPRINT report. The seed commit is the only one whose content comes from
# OUTSIDE this script -- kit-init.sh copies the profile template in -- so it is where an
# environmental difference enters, and every commit after it is printf output. Reporting it
# separates "the kit's files differ" from "this script changed".
SEED=$(git rev-parse HEAD)

# 24 paired commits: each module's two files always change together, README changes in
# every one and must be dropped as a hub, and 24 gives hub_pct a real denominator.
for m in 1 2 3 4 5 6 7 8; do
  for r in 1 2 3; do
    printf '%s%s\n' "$m" "$r" > "src/m${m}.go"
    printf '%s%s\n' "$m" "$r" > "lib/m${m}_util.go"
    printf '%s%s\n' "$m" "$r" > README.md
    git add -A && git commit -q --no-verify -m "chore: module $m rev $r"
  done
done

printf 'x\n' > src/a.go; git add -A
git commit -q --no-verify -m "feat: one

Task-Id: T-a
Tier: T2
Task-Status: started"
# Trailers stranded before a later paragraph: what GitHub squash-merge produces.
printf 'y\n' > src/b.go; git add -A
git commit -q --no-verify -m "feat: squashed with co-author

* work

Task-Id: T-b
Tier: T1
Task-Status: done

Co-authored-by: X <x@example.com>"
echo "  commits: $(git rev-list --count HEAD)"
# Moves whenever templates/project-profile.md changes, because kit-init.sh copies it into
# the fixture's first commit. That is the cost of also using this as a drift detector:
# it forces a template edit to be noticed rather than silently changing what two
# platforms are comparing. Update it deliberately, never to make a red run go green.
# Moved TWICE on 2026-08-08, each time deliberately and each time with the cause
# established BEFORE re-pinning -- exactly one blob differing between the old and new seed
# trees, and that difference being exactly the intended edit. That is the work this check
# exists to force, and both times it forced it.
#   1. kit-init.sh writes `.project/index.db*` rather than `.project/index.db`, because the
#      indexer builds into `index.db.new` and marks a failed build with `index.db.failed`.
#   2. templates/project-profile.md now documents which tier.rule globs are refused, and
#      kit-init.sh copies that template into the fixture's first commit.
#   3. 2026-08-15: templates/project-profile.md gained `paths.adr` and `paths.design_input`
#      (ADR 0001). Same cause as 2 -- kit-init.sh copies the template into the seed commit.
#      The cause was established BEFORE re-pinning, as this comment requires, and the
#      evidence is: the previous commit still PASSED on the old pins, so the suite was not
#      broken; `git ls-tree -r` of the old and new seed trees differ in EXACTLY ONE blob,
#      `.claude/project-profile.md`; and `git cat-file -p` of the two blobs differs by
#      exactly the six added lines and nothing else. A full fresh-clone run was 64 passed,
#      1 failed, that one being this check -- so nothing else moved with it.
#   4. 2026-08-15: kit-init.sh now adds kit-entry.sh's four artefacts to the adoption
#      .gitignore, and .gitignore is in the seed commit. PREDICTED before the run rather than
#      diagnosed after it -- the mechanism is identical to 2 and 3, and a check whose next
#      failure you can name in advance is a check that is understood. Evidence, same discipline:
#      exactly one blob differs between the seed trees (`.gitignore`), its content differs by
#      exactly the four added lines, and the run was 67 passed with this as the only failure.
#   5. 2026-08-17: kit-init.sh now pins `.project/plans/*.tsv` to LF in the adoption
#      `.gitattributes`, and `.gitattributes` is in the seed commit (ADR 0004 — the plan is
#      committed text the indexer reads as data, so a CRLF checkout would carry a CR into the
#      goal id and the digest). PREDICTED before the run, like 4, and named in the commit that
#      caused it before CI was consulted. Evidence, same discipline, and one addition:
#      exactly one blob differs between the seed trees (`.gitattributes`), by exactly the two
#      added lines and nothing else; this was the ONLY failure across the 50 steps that ran.
#      The addition: the new seed was derived TWICE by independent routes — rebuilt by hand
#      from the fixture's own recipe, and printed by the suite — and the two agreed, which is
#      what distinguishes a re-pin from a guess.
#
#      **DO NOT EDIT THIS FILE WHILE A RUN OF IT IS IN FLIGHT.** These two constants were
#      re-pinned while the run that produced them was still executing, and bash reads a script
#      incrementally: the byte offsets shifted under the interpreter and it resumed mid-token,
#      emitting `line 3229: ow: command not found` and dying before the tally. Everything up to
#      the fixture step had already executed and is sound, but the last step's result and the
#      final `N passed, N failed` line were destroyed by the edit — a measurement invalidated by
#      the person reading it. Wait for the tally, then edit.
#      Specifically checked and PASSING: `delete and rebuild is lossless`, which a T3 security
#      review flagged as the likely second failure now that `plan_stale:` and `plan_refused`
#      rows are in the compared `.dump` and are written AFTER the atomic swap by a different
#      code path. It is not order-dependent. That was the reason for waiting for the whole run
#      before touching these two lines rather than re-pinning on the first red.
#      Re-pinned 2026-08-22, and the reason is nameable rather than "it moved": kit-init.sh
#      stopped writing `.project/entry-candidates.md` into .gitignore, because that file is a
#      model-authored proposal rather than derived output and is now tracked. The fixture commits
#      kit-init's output, so its content changed and its sha followed.
#      The diagnostic said which half moved before anything was touched -- "seed differs: a file
#      kit-init.sh commits is not byte-identical here" -- and ubuntu and macos computed the SAME
#      new pair, which is what makes this a re-pin rather than a reproducibility failure. Two
#      platforms agreeing on a new value is evidence; one platform moving would not be.
#      Re-pinned 2026-08-25, cause named in advance: the relicence added an SPDX header and a
#      commented `git.require_signoff` block to templates/project-profile.md, and kit-init.sh
#      copies that template into the fixture's seed commit. Same mechanism as 2, 3 and 5, and
#      PREDICTED before the run rather than diagnosed after it. Evidence, to the standard the
#      entries above set:
#        - a clean clone of `main` reproduced the OLD pins exactly on this machine (13 passed,
#          0 failed), so the fixture is reproducible here and the move has one cause;
#        - the two seed trees hold six files each and differ in EXACTLY ONE blob,
#          `.claude/project-profile.md`;
#        - that blob differs by exactly the 15 lines added to the template -- 7 of header at
#          the top, 8 of commented key after git.trivial_pattern -- and nothing else;
#        - `git ls-tree -r` on both seeds was compared directly, not inferred from the diff.
#      The two-platform half of note 5's standard is satisfied by CI rather than locally: this
#      is a re-pin only if ubuntu and macos both compute the same pair. If they disagree, this
#      is a reproducibility failure and the pins below are wrong.
#      Re-pinned again 2026-08-25, hours after the entry above and by the same mechanism: the
#      sign-off adoption boundary added eleven commented lines to templates/project-profile.md,
#      which kit-init.sh copies into the seed. PREDICTED before the run. Evidence: the two seed
#      trees hold six files each and differ in EXACTLY ONE blob, `.claude/project-profile.md`,
#      by exactly those eleven lines and nothing else (119 -> 130). The old-pin fixture from the
#      previous re-pin was still on disk, so both trees were compared directly with
#      `git ls-tree -r` rather than one being reconstructed. Two-platform agreement is CI's half.
#      Re-pinned again 2026-09-14, same mechanism a third time: paths.depmap added three lines
#      to templates/project-profile.md, which kit-init.sh copies into the seed. PREDICTED before
#      the run, from the fact that the profile template is the only file this change touches that
#      kit-init.sh commits. Evidence, in the order the standard above asks for it:
#        - a worktree of main reproduced the OLD pins EXACTLY on this machine (head 3110463...),
#          so the fixture is reproducible here and the move has one cause;
#        - `git ls-tree -r` on both seeds, read directly rather than inferred: six files each,
#          differing in EXACTLY ONE blob, `.claude/project-profile.md` (79d2001e -> db58ca53);
#        - `git cat-file -p` on the two blobs differs by exactly the three lines added -- two of
#          comment and the key itself -- and nothing else (130 -> 133).
#      THREE platforms agree on the new pair this time, not two: ubuntu and macos in CI, and a
#      full local run on Windows. All three reported 119 passed, 1 failed, and the one was this.
EXPECT_HEAD=ea78cba2c94cbaca0824c5642c7e11f24086650f
# The seed alone, so a mismatch says WHICH half moved: seed intact means this script changed,
# seed moved means a file kit-init.sh commits did.
EXPECT_SEED=594f8f939b2cd77acb24ae48cf1c1469751d570c
fi

if step "trailer hook" fixture; then
sed -i.bak 's|^git.trailer_enforcement:.*|git.trailer_enforcement:  enforce|' .claude/project-profile.md
rm -f .claude/project-profile.md.bak
printf 'z\n' > src/c.go; git add -A
git commit -q -m "feat: untrailered" >/dev/null 2>&1
[ $? -ne 0 ]; check $? "rejects an untrailered commit"
git commit -q -m "feat: stranded

Task-Id: T-a
Tier: T2

Co-authored-by: Y <y@example.com>" >/dev/null 2>&1
[ $? -ne 0 ]; check $? "rejects trailers stranded before a later paragraph"
git commit -q -m "feat: trailered

Task-Id: T-a
Tier: T2" >/dev/null 2>&1
check $? "accepts a well-formed one"
fi

if step "pipeline" fixture; then
bash "$KIT/tooling/kit-index.sh" > idx.log 2>&1
rc=$?; check $rc "kit-index.sh"
# Show why. Swallowing this cost a full CI round trip to diagnose a one-character fix.
[ $rc = 0 ] || { echo "  --- kit-index.sh output ---"; sed 's/^/  /' idx.log | head -20; }
grep -q "recovered by full-message scan" idx.log; check $? "recovers the squash-stranded trailers"
bash "$KIT/tooling/kit-plan.sh" --next 5 >/dev/null 2>&1; check $? "kit-plan.sh"
bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1; check $? "kit-status.sh"
fi

if step "derived state" fixture; then
sqlite3 -header .project/index.db "SELECT id,state,tier,lang,epic FROM task ORDER BY id;" | tr -d '\r'
sqlite3 .project/index.db "SELECT key,value FROM meta ORDER BY key;" | tr -d '\r'
fi

if step "timestamps are canonical UTC" fixture; then
# %aI would carry the author local offset and render differently across git versions, so
# the same history produced different indexes on different machines and ORDER BY compared
# offsets lexically. Everything must be ...Z.
n=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE at NOT LIKE '%Z';" | tr -d '\r')
[ "${n:-1}" = 0 ]; check $? "every event.at ends in Z"
fi

if step "co-change" fixture; then
CC=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM cochange;" | tr -d '\r')
[ "${CC:-0}" -gt 0 ]; check $? "co-change graph was built ($CC rows)"
sqlite3 .project/index.db "SELECT COUNT(*) FROM cochange WHERE src LIKE '%README%';" | tr -d '\r' | grep -qx 0
check $? "README excluded as a hub"
fi

if step "delete and rebuild is lossless" fixture; then
# THIS STEP COULD NOT HAVE CAUGHT THE DEFECT IT LOOKS LIKE IT COVERS, and that is worth saying
# where the next reader will see it. It rebuilds and then RE-PLANS, so plan_item was always
# repopulated by kit-plan.sh on line 3 regardless of whether kit-index.sh could restore it --
# a rebuild that dropped the plan looked exactly like one that kept it. "Lossless" was true of
# this sequence and false of the one task-context actually runs, which is index WITHOUT a
# replan. That case is covered by its own step at the end of this file, deliberately separate.
sqlite3 .project/index.db ".dump" | tr -d '\r' | LC_ALL=C sort > b.dump
rm -f .project/index.db
bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
bash "$KIT/tooling/kit-plan.sh" --next 5 >/dev/null 2>&1
# `INSERT INTO goal` used to be excluded from both dumps: created_at was strftime('now') in the
# emitted SQL, so it moved on every rebuild and could never match. It comes from the plan file
# now (ADR 0004), which is what makes the goal row comparable at all -- so the exclusion is
# gone and this step covers one more table than it used to.
sqlite3 .project/index.db ".dump" | tr -d '\r' | LC_ALL=C sort > a.dump
cmp -s b.dump a.dump; check $? "rebuild is byte-identical, goal row included"
fi

if step "CI gate" fixture; then
bash "$KIT/tooling/kit-trailers.sh" range "HEAD~1..HEAD" --enforce >/dev/null 2>&1
check $? "passes on a well-formed commit"
fi

if step "FINGERPRINT" fixture; then
H=$(git rev-parse HEAD)
printf '  head    %s\n' "$H"
# The fixture chain is fully determined, so under `--only` these two values are the
# same ones a full run prints -- but they cover the chain, not the suite, and an
# unlabelled fingerprint pasted out of a filtered run would claim otherwise.
[ -n "$ONLY" ] && printf '  (partial run: covers the fixture chain, not conformance)\n'
# sqlite .dump emits sqlite_sequence and PRAGMA writable_schema differently by version, so
# they are excluded: they are dump formatting, not kit state.
printf '  index   %s\n' \
  "$(grep -v 'sqlite_sequence\|writable_schema' a.dump | { sha256sum 2>/dev/null || shasum -a 256; } | awk '{print $1}')"
# The fixture is fully determined -- fixed author and committer dates, fixed content -- so
# HEAD must be the same commit on every machine. A mismatch has two causes and they are not
# the same problem: the fixture drifted, or the FILES IT COMMITS differ between checkouts.
# Say which. Reading only the HEAD mismatch, the obvious conclusion is drift, and once that
# was assumed a CRLF profile template took a template diff, a kit-init diff and a two-version
# fixture rebuild to find. The seed commit is where anything from outside this script enters.
if [ "$H" != "$EXPECT_HEAD" ]; then
  printf '  seed    %s  (expected %s)\n' "$SEED" "$EXPECT_SEED"
  [ "$SEED" = "$EXPECT_SEED" ] &&
    printf '  ^ seed matches, so the divergence is in this script, not in the kit files it commits\n' ||
    printf '  ^ seed differs: a file kit-init.sh commits is not byte-identical here. Compare\n    `git ls-tree -r %s` against a known-good checkout before touching EXPECT_HEAD.\n' "$SEED"
fi
[ "$H" = "$EXPECT_HEAD" ]
check $? "fixture is reproducible (HEAD == $EXPECT_HEAD)"
fi

if step "the plan survives a reindex, identically, and says so when it goes stale"; then
# ADR 0004. `goal` and `plan_item` are written by kit-plan.sh and no source in kit-index.sh
# could rebuild them, so the rebuild -- which starts from a fresh schema -- dropped them.
# skills/task-context step 1 is `kit-index.sh --if-stale` and its step 4 reads `plan_item`, so
# the skill's first step deleted what its fourth step needed. Measured on this repository:
# 77 plan rows and 1 goal to zero, with 11 pack files left on disk looking current.
#
# IDENTITY, not presence. "Some rows came back" would pass with a plan whose layering had been
# lost, and the failure this guards is precisely two implementations drifting: kit-plan.sh
# writes the file and kit-index.sh reads it, and nothing else compares them.
pl="$WORK.plan"; rm -rf "$pl"; mkdir -p "$pl/src"
( cd "$pl" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-P1\ntitle: one\ntier: T2\n---\nb\n'                  > .project/tasks/T-P1.md
  printf -- '---\nid: T-P2\ntitle: two\ntier: T1\nblocked_by: T-P1\n---\nb\n' > .project/tasks/T-P2.md
  printf -- '---\nid: T-P3\ntitle: three\ntier: T3\n---\nb\n'                > .project/tasks/T-P3.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  ROWS="SELECT goal_id,task_id,layer,rank,printf('%.3f',score),cluster FROM plan_item ORDER BY goal_id,task_id;"

  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  Q "$ROWS" > before.rows; Q "SELECT id,title,created_at,state FROM goal;" > before.goal
  [ -s before.rows ] || exit 1                     # a plan of nothing proves nothing
  [ -f .project/plans/default.tsv ] || exit 1      # the plan is a FILE, not only a table

  # The exact reproduction: a task file changes, which is what makes the index stale, and the
  # skill's step 1 then rebuilds. Before ADR 0004 this is where the plan died.
  printf -- '---\nid: T-P3\ntitle: three\ntier: T3\n---\nedited\n' > .project/tasks/T-P3.md
  bash "$KIT/tooling/kit-index.sh" --if-stale >/dev/null 2>&1
  Q "$ROWS" > after.rows; Q "SELECT id,title,created_at,state FROM goal;" > after.goal
  cmp -s before.rows after.rows || exit 1
  # created_at included deliberately: it was strftime('now') in the emitted SQL, so a rebuild
  # re-stamped the goal and no round-trip check could ever have passed.
  cmp -s before.goal after.goal || exit 1

  # A plan that survives its inputs can now outlive them, which the old behaviour could not do.
  # That is the cost of persisting it, and it has to be visible or this trade is a bad one.
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key='plan_stale:default';")" = 0 ] || exit 1
  printf -- '---\nid: T-P4\ntitle: four\ntier: T0\n---\nb\n' > .project/tasks/T-P4.md
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT value FROM meta WHERE key='plan_stale:default';")" = 1 ] || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'computed from a different backlog' STATUS.generated.md || exit 1
  # and it clears, or it is a warning that can never turn off
  bash "$KIT/tooling/kit-plan.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key='plan_stale:default';")" = 0 ] || exit 1

  # A pack with no plan behind it is the state every rebuild used to leave: files on disk,
  # looking current, that task-context step 4 will never load.
  rm -f .project/plans/default.tsv
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM plan_item;")" = 0 ] || exit 1
  grep -q 'with no plan behind them' STATUS.generated.md || exit 1 )
check $? "plan round-trips identically, reports staleness, and orphaned packs are named"
rm -rf "$pl"
fi

if step "a clone recovers its packs from the committed plan, without replanning"; then
# ADR 0004 as amended, and the only CRITICAL the T3 review chain returned. The ADR justified
# committing the plan and ignoring the packs on "a pack is a rebuildable cache of the plan",
# and nothing rebuilt a pack from a plan file: the sole regeneration path recomputed the
# ordering and rewrote the plan with a new digest, so recovering the cache destroyed the thing
# cached. A fresh clone therefore had plan rows and no packs, and skills/task-context step 4
# builds a path from the row and reads nothing — it has no miss branch.
#
# The property under test is NOT "packs appear". It is that they appear WITHOUT the plan
# changing. A --packs that quietly replanned would pass a file-exists check and reintroduce the
# defect, so the plan file is compared byte for byte across the call.
cl="$WORK.clone"; rm -rf "$cl" "$cl.src"; mkdir -p "$cl.src"
( cd "$cl.src" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-C1\ntitle: one\ntier: T2\nepic: e1\n---\nb\n' > .project/tasks/T-C1.md
  printf -- '---\nid: T-C2\ntitle: two\ntier: T1\nepic: e1\n---\nb\n' > .project/tasks/T-C2.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  [ -f .project/plans/default.tsv ] || exit 1
  git add -A && git commit -q --no-verify -m "chore: plan" ) || exit 1
git clone -q --no-hardlinks "$cl.src" "$cl" 2>/dev/null
( cd "$cl" || exit 1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  # The clone's starting state IS the defect: a committed plan, no packs.
  [ -f .project/plans/default.tsv ] || exit 1
  [ -d .project/packs ] && exit 1
  cp .project/plans/default.tsv ../plan.before
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q 'SELECT COUNT(*) FROM plan_item;')" -gt 0 ] || exit 1   # rows, from the committed file
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'no cluster pack on disk' STATUS.generated.md || exit 1 # and the state is ANNOUNCED

  bash "$KIT/tooling/kit-plan.sh" --packs >/dev/null 2>&1 || exit 1
  # The pack step 4 would resolve to now exists...
  g=$(Q "SELECT goal_id FROM plan_item ORDER BY layer,rank LIMIT 1;")
  c=$(Q "SELECT cluster  FROM plan_item ORDER BY layer,rank LIMIT 1;")
  [ -f ".project/packs/$g/c$c.md" ] || exit 1
  # ...and the committed plan was NOT recomputed to get it. This is the whole assertion.
  cmp -s ../plan.before .project/plans/default.tsv || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'no cluster pack on disk' STATUS.generated.md && exit 1  # notice clears
  exit 0 )
check $? "--packs restores packs from a cloned plan and leaves the plan byte-identical"

# A gitignored plan is the quietest way to undo ADR 0004 entirely: everything works on the
# machine that planned, and the published guarantee is false everywhere else. Nothing checked it
# until a T3 review asked. Deliberately NOT the refusal ADR 0003 gives an untracked ingest
# adapter — that is executable code no review has seen and refusing costs nothing, whereas a plan
# file is untracked for an ordinary reason (just written, not yet committed) and refusing would
# break the tool on first use. So the two states report differently, and BOTH are asserted here:
# porting the adapter's refusal would have been the half-ported control this review chain
# flagged twice elsewhere in this change.
( cd "$cl.src" || exit 1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  printf '.project/plans/\n' >> .gitignore
  git rm -q --cached .project/plans/default.tsv >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT value FROM meta WHERE key='plan_ignored:default';")" = 1 ] || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  # The goal must be NAMED, not rendered as `:default` — an off-by-one in the substr that peels
  # the meta key prefix did exactly that, and a notice whose text is wrong is one people stop
  # reading, which is the failure the notice exists to prevent.
  grep -qF 'The plan for `default` is covered' STATUS.generated.md || exit 1
  # ...and it must CLEAR, or it is a warning that can never turn off.
  sed -i.bak '/^\.project\/plans\/$/d' .gitignore && rm -f .gitignore.bak
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key LIKE 'plan_ignored:%';")" = 0 ] || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'covered by' STATUS.generated.md && exit 1
  exit 0 )
check $? "a gitignored plan is reported by name and the notice clears when it is un-ignored"
rm -rf "$cl" "$cl.src" "$(dirname "$cl")/plan.before"
fi

if step "documentation and a single co-edit are not evidence that two tasks are about one thing"; then
# hub_cap assumes a cross-cutting file is HIGH degree. Where the cross-cutting surface is
# documentation it is LOW degree, so the rule kept README.md (degree 5) as evidence while
# excluding tests/conformance.sh (13) as a hub — it dropped the code that indicates shared
# subject matter and kept the prose that does not. Measured on this repository: 28 of 46 leaf
# files were documentation, and 34 of 43 links came from a SINGLE shared file.
#
# THE THIRD ASSERTION IS THE ONE THAT MATTERS. Two rules that only ever REFUSE to union would
# satisfy the first two and destroy clustering entirely, which is a worse defect than the
# over-fusion being fixed. Every check here has an inverse for that reason.
cu="$WORK.clustunion"; rm -rf "$cu"; mkdir -p "$cu/src"
( cd "$cu" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  # No epic on any of them: epic-union would confound every assertion below.
  for t in D1 D2 E1 E2 F1 F2; do
    printf -- '---\nid: T-%s\ntitle: %s\ntier: T2\n---\nb\n' "$t" "$t" > ".project/tasks/T-$t.md"
  done
  printf 'x\n' > README.md; printf 'x\n' > src/a.txt
  printf 'x\n' > src/b.txt; printf 'x\n' > src/c.txt
  git add -A && git commit -q --no-verify -m "chore: seed"
  c() { printf '%s\n' "$2" > "$1"; shift 2; git add -A; git commit -q --no-verify -m "feat: w

Task-Id: $1
Tier: T2"; }
  # D1/D2 share ONLY a doc.               E1/E2 share ONLY ONE code file.
  c README.md   d1 T-D1;  c README.md   d2 T-D2
  c src/a.txt   e1 T-E1;  c src/a.txt   e2 T-E2
  # F1/F2 share TWO code files — the case that must still union.
  printf 'f1\n' > src/b.txt; printf 'f1\n' > src/c.txt; git add -A
  git commit -q --no-verify -m "feat: f1

Task-Id: T-F1
Tier: T2"
  printf 'f2\n' > src/b.txt; printf 'f2\n' > src/c.txt; git add -A
  git commit -q --no-verify -m "feat: f2

Task-Id: T-F2
Tier: T2"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  cl() { Q "SELECT cluster FROM plan_item WHERE task_id='$1';"; }
  [ -n "$(cl T-D1)" ] || exit 1                       # all six must be planned at all
  [ "$(cl T-D1)" != "$(cl T-D2)" ] || exit 1          # a shared DOC is not evidence
  [ "$(cl T-E1)" != "$(cl T-E2)" ] || exit 1          # ONE shared code file is not evidence
  [ "$(cl T-F1)"  = "$(cl T-F2)" ] || exit 1          # TWO shared code files still ARE
  exit 0 )
check $? "a shared doc and a single shared file do not union, two shared files still do"
rm -rf "$cu"
fi

if step "a degenerate cluster withholds its packs and says so, and a raised cap still writes them"; then
# kit-index.sh withholds a co-change graph whose average degree exceeds cochange.max_degree,
# because answering "everything" is worse than an honest unknown. Clustering had no equivalent
# and emitted a 75-of-85-task cluster with full confidence — and the packs built from it were
# about to be the subject of an ROI experiment.
#
# The fixture reproduces the real mechanism rather than a synthetic blob: two epics, bridged by
# ONE low-degree shared file, which is exactly how this repository's seven epics fused. Measured
# there: README.md and SECURITY.md at degree 5 are kept as evidence while tests/conformance.sh at
# 13 is excluded as a hub, so the heuristic keeps the documentation and drops the code.
#
# BOTH directions are asserted. A check that only proves the refusal would pass against a
# mechanism that refused unconditionally, which would be a worse defect than the one being fixed.
#
# THE SMALL-BACKLOG FLOOR IS REGRESSION-TESTED ELSEWHERE, deliberately not duplicated here: the
# `--packs restores packs from a cloned plan` step above builds a TWO-task fixture, and two tasks
# in one cluster is 100% share. The first version of this check had no `cluster.min_tasks` floor
# and that step went red immediately — which is the only reason the defect was found before it
# shipped, since it would have withheld packs on every new or small backlog permanently. If this
# step is ever moved above that one, the floor loses its cover.
cl2="$WORK.clustdeg"; rm -rf "$cl2"; mkdir -p "$cl2"
( cd "$cl2" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  # Lower the floor for this fixture rather than filing ten tasks to clear it. This also
  # exercises `cluster.min_tasks` as a declared knob instead of leaning on its default — and the
  # default is what made this step fail the first time the floor existed, which is the floor
  # doing its job on its own author.
  # INSERTED INTO THE FRONTMATTER, not appended to the file. `kit_cfg` exits at the second
  # `---` (kit-lib.sh), so a key appended after it sits in the prose section and is never read —
  # the step would then fail looking like a broken mechanism rather than a bad fixture.
  sed -i.bak 's|^cluster.hub_cap:.*|&\ncluster.min_tasks: 2|' .claude/project-profile.md && rm -f .claude/project-profile.md.bak
  printf -- '---\nid: T-A1\ntitle: a1\ntier: T2\nepic: alpha\n---\nb\n' > .project/tasks/T-A1.md
  printf -- '---\nid: T-A2\ntitle: a2\ntier: T2\nepic: alpha\n---\nb\n' > .project/tasks/T-A2.md
  printf -- '---\nid: T-B1\ntitle: b1\ntier: T2\nepic: beta\n---\nb\n'  > .project/tasks/T-B1.md
  printf -- '---\nid: T-B2\ntitle: b2\ntier: T2\nepic: beta\n---\nb\n'  > .project/tasks/T-B2.md
  mkdir -p src; printf 'x\n' > src/x.txt; printf 'x\n' > src/y.txt
  git add -A && git commit -q --no-verify -m "chore: seed"
  # TWO non-documentation files, touched by one task from each epic. Both filters must be
  # cleared for the union to happen, and clearing them is the point: this fixture exists to
  # produce a genuine degenerate cluster, not an artificial one.
  #
  # It used to bridge through a single `shared.md`, and A+B broke it for two independent
  # reasons at once — `cluster.ignore_glob` excludes `*.md`, and one shared file no longer
  # meets `cluster.min_shared`. Both were the new rules working. Left as a marker: if this
  # fixture ever stops fusing again, check whether a real rule changed before changing it back.
  printf 'a\n' > src/x.txt; printf 'a\n' > src/y.txt; git add -A
  git commit -q --no-verify -m "feat: a

Task-Id: T-A1
Tier: T2"
  printf 'b\n' > src/x.txt; printf 'b\n' > src/y.txt; git add -A
  git commit -q --no-verify -m "feat: b

Task-Id: T-B1
Tier: T2"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  # The fixture must actually degenerate, or the rest of this step proves nothing.
  [ "$(Q "SELECT COUNT(DISTINCT cluster) FROM plan_item;")" = 1 ] || exit 1
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_largest_pct:default';")" = 100 ] || exit 1
  # Withheld: recorded, removed from disk, and NOT merely unwritten.
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_packs_withheld:default';")" = 1 ] || exit 1
  [ -d .project/packs/default ] && exit 1
  # The ORDERING survives — layers come from topology and ranks from score, and withholding a
  # pack must not cost the plan.
  [ "$(Q "SELECT COUNT(*) FROM plan_item;")" = 4 ] || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Packs are \*\*withheld\*\*' STATUS.generated.md || exit 1
  # And the contradictory advice is suppressed: a withheld pack must not also be reported as a
  # missing one telling the reader to run --packs, which refuses for the same reason.
  grep -q 'no cluster pack on disk' STATUS.generated.md && exit 1

  # THE INVERSE. Raise the cap above the observed share and the packs are written again.
  sed -i.bak 's|^cluster.hub_cap:.*|&\ncluster.max_share: 100|' .claude/project-profile.md && rm -f .claude/project-profile.md.bak
  bash "$KIT/tooling/kit-plan.sh" >/dev/null 2>&1
  [ -d .project/packs/default ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key='cluster_packs_withheld:default';")" = 0 ] || exit 1
  exit 0 )
check $? "degenerate clustering withholds packs, keeps the ordering, and a raised cap restores them"
rm -rf "$cl2"
fi


if step "a parked task and everything behind it leave the plan, named as parked rather than blocked"; then
# docs/adr/0008 left this open -- "both are open, both are plannable, and no evidence here says
# they should differ" -- and asked for evidence. The evidence was that parking changed nothing: a
# task parked on 2026-09-09 was rank 1 before parking and still rank 1 two days later.
#
# THE TAIL IS TWO LEVELS DEEP ON PURPOSE. T-Q and T-R wait on the parked T-P, and T-S waits on
# T-Q, so "everything behind it" is a real assertion rather than a restatement of the root. T-Z
# waits on nothing and must survive, or "withheld" would quietly come to mean "planned nothing" --
# the failure kit-plan.sh:304-308 already warns about for the unfiled-blocker path.
#
# MUTATIONS, each of which must take this step red:
#   (a) drop the `!plannable[...]` seeding in kit-plan.sh   -> T-P returns to the plan
#   (b) put `on-hold` in kit_state_closed instead           -> the depends_on edge is dropped and
#       T-Q/T-R plan at layer 0, ahead of the thing they wait on. The un-park assertions at the
#       end are what catch this one, and they are why this step does not stop at "it is absent".
#   (c) restore kit_plan_digest's closed filter             -> parking leaves the plan "fresh"
pk="$WORK.parked"; rm -rf "$pk"; mkdir -p "$pk/src"
( cd "$pk" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  inplan() { awk -F'\t' -v t="$1" '$2==t{f=1} END{exit !f}' .project/plans/default.tsv; }

  printf -- '---\nid: T-P\ntitle: p\ntier: T2\nstate: created\n---\nb\n'  > .project/tasks/T-P.md
  printf -- '---\nid: T-Q\ntitle: q\ntier: T2\nblocked_by: T-P\n---\nb\n' > .project/tasks/T-Q.md
  printf -- '---\nid: T-R\ntitle: r\ntier: T2\nblocked_by: T-P\n---\nb\n' > .project/tasks/T-R.md
  printf -- '---\nid: T-S\ntitle: s\ntier: T2\nblocked_by: T-Q\n---\nb\n' > .project/tasks/T-S.md
  printf -- '---\nid: T-Z\ntitle: z\ntier: T1\n---\nb\n'                  > .project/tasks/T-Z.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1

  # BEFORE, or the assertion after parking proves nothing: all five are planned, in dependency order.
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE goal_id='default';")" = 5 ] || exit 1

  # Park it. Frontmatter alone is not enough -- state resolves from the LAST TRANSITION EVENT
  # (kit-index.sh:1262) -- so the transition travels as a trailer, which is how a person does it too.
  sed -i.bak 's/^state: created/state: on-hold/' .project/tasks/T-P.md && rm -f .project/tasks/T-P.md.bak
  git add -A && git commit -q --no-verify -m "chore: park p

Task-Id: T-P
Tier: T2
Task-Status: on-hold"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  # STALE. On the closed partition the parked task stayed in the digest, so a plan that no longer
  # matched the backlog still compared fresh and nothing told anyone to replan.
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key='plan_stale:default';")" = 1 ] || exit 1

  bash "$KIT/tooling/kit-plan.sh" >"$PWD/p.out" 2>"$PWD/p.err"

  # The root and all three behind it are out of the PLAN ROWS -- not merely past --next's LIMIT,
  # which is the weaker thing an `--next` assertion would have proved (kit-plan.sh:618).
  for t in T-P T-Q T-R T-S; do
    [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE task_id='$t';")" = 0 ] || exit 1
    inplan "$t" && exit 1
  done
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE task_id='T-Z';")" = 1 ] || exit 1

  # COUNTED, AND ATTRIBUTED TO THE RIGHT CAUSE. The withheld line names its cause out loud --
  # "blocked by an id with no task file" -- so a parked task counted into it would assert an
  # unfiled blocker about work somebody set aside on purpose. That line must not appear at all.
  grep -q '^# 4 of 5 open task(s) parked' p.out || exit 1
  grep -q 'blocked by an id with no task file' p.out && exit 1
  # Named under its root, so the one task to un-park is not buried in its own tail.
  grep -q 'parked — 4/5 open task(s) are held out of the plan on purpose' p.err || exit 1
  grep -qE '^  T-P ' p.err || exit 1

  # The report says so too, with the size of the tail -- invisible from the task itself.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -qE '^- T-P .*\*\*parked\*\*, 2 waiting' STATUS.generated.md || exit 1

  # UN-PARK, AND THE ORDER SURVIVES. This is the assertion that catches mutation (b): if on-hold
  # were classed closed, kit-plan's edge query would have dropped `depends_on` while T-P was
  # parked, and nothing above would have noticed -- absence looks the same either way. Here the
  # tail must come back BEHIND its root, which only holds if the edge was never lost.
  git commit -q --allow-empty --no-verify -m "chore: unpark p

Task-Id: T-P
Tier: T2
Task-Status: in-progress"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  [ "$(Q "SELECT COUNT(*) FROM plan_item WHERE goal_id='default';")" = 5 ] || exit 1
  [ "$(Q "SELECT layer FROM plan_item WHERE task_id='T-P';")" = 0 ] || exit 1
  [ "$(Q "SELECT layer FROM plan_item WHERE task_id='T-Q';")" = 1 ] || exit 1
  [ "$(Q "SELECT layer FROM plan_item WHERE task_id='T-S';")" = 2 ] || exit 1
  exit 0 )
check $? "a parked task and everything behind it leave the plan, named as parked rather than blocked"
rm -rf "$pk"
fi
if step "a small backlog keeps its packs, and the cluster facts survive a reindex"; then
# The step above is the case where the planner and the report AGREE: a genuinely degenerate
# cluster, withheld by both. THIS is the case where they disagreed, and the one the 2026-09-09
# highper-gateway trial hit: a backlog BELOW cluster.min_tasks, where the planner writes the pack
# and kit-status.sh called it withheld anyway, because it re-decided with a literal 60 instead of
# reading the decision. It also asserts what a plain reindex used to erase.
cl3="$WORK.clustsmall"; rm -rf "$cl3"; mkdir -p "$cl3"
( cd "$cl3" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  # ONE task: 100% of the backlog in one cluster, which is what every fresh adoption looks like.
  # cluster.min_tasks is left at its default on purpose — the default is the case that shipped
  # wrong, and a fixture that lowers it would not reproduce the defect at all.
  printf -- '---\nid: T-S1\ntitle: s1\ntier: T2\nepic: solo\n---\nb\n' > .project/tasks/T-S1.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1

  # The planner wrote the pack: one task is under the floor, whatever its share.
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_largest_pct:default';")" = 100 ] || exit 1
  [ "$(Q "SELECT COUNT(*) FROM meta WHERE key='cluster_packs_withheld:default';")" = 0 ] || exit 1
  [ -d .project/packs/default ] || exit 1

  # And the report must not contradict it.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Packs are \*\*withheld\*\*' STATUS.generated.md && exit 1
  grep -q 'Largest cluster in `default` holds 100%' STATUS.generated.md || exit 1

  # THE FACTS SURVIVE A PLAIN REINDEX. Written straight to `meta` they were re-derived by
  # nothing, so every rebuild erased them and withheld packs were then reported as merely missing.
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_largest_pct:default';")" = 100 ] || exit 1

  # THE WITHHOLD DECISION SURVIVES ONE TOO. Lower the floor so this same backlog degenerates,
  # then rebuild: the decision must still be readable, which is what the direct meta write lost.
  sed -i.bak 's|^cluster.hub_cap:.*|&\ncluster.min_tasks: 1|' .claude/project-profile.md && rm -f .claude/project-profile.md.bak
  bash "$KIT/tooling/kit-plan.sh"  >/dev/null 2>&1
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_packs_withheld:default';")" = 1 ] || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(Q "SELECT value FROM meta WHERE key='cluster_packs_withheld:default';")" = 1 ] || exit 1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'Packs are \*\*withheld\*\*' STATUS.generated.md || exit 1
  exit 0 )
check $? "a small backlog keeps its packs, and the cluster facts survive a reindex"
rm -rf "$cl3"
fi

if step "the pre-flight surfaces the blind spot its own criticals box excludes"; then
# AC5 of T-20260813. `--criticals` excludes unassessable findings on purpose — leaving them in
# would make the gate permanently unsatisfiable, since they cannot be judged from what survives.
# The cost is a repository whose every remaining critical is unassessable reporting ZERO and
# passing §0's box with the blind spot intact: a pre-flight box a third state silently satisfies,
# which is the exact defect the criticals chain exists to remove.
blind="$WORK.blind"; rm -rf "$blind"; mkdir -p "$blind"
( cd "$blind" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-U1\ntitle: one\ntier: T2\n---\nb\n' > .project/tasks/T-U1.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  # A finding with NO summary — the historical shape the nine have, and the only shape the
  # unassessable route accepts. kit-finding.sh cannot produce one (summary is required), which
  # is the guard, so the event is written directly to reproduce the pre-summary state.
  printf '{"task":"T-U1","kind":"finding","at":"2026-07-01T00:00:00Z","agent":"security-reviewer","class":"fail-open","severity":"critical","lang":"bash","pattern":"","domain":"","model":"opus"}\n' >> .project/events.ndjson
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # Before the mark: --criticals stops, and there is no blind spot to report.
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 && exit 1
  bash "$KIT/tooling/kit-preflight.sh" --unassessable | grep -q 'no unassessable critical' || exit 1

  fid=$(Q "SELECT id FROM finding WHERE severity='critical' AND (summary IS NULL OR summary='') LIMIT 1;")
  [ -n "$fid" ] || exit 1
  bash "$KIT/tooling/kit-resolve.sh" --finding "$fid" --unassessable --reason "predates the summary column" >/dev/null 2>&1 || exit 1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  # THE THIRD STATE. --criticals now passes; the blind spot is still true and must be named.
  bash "$KIT/tooling/kit-preflight.sh" --criticals >/dev/null 2>&1 || exit 1
  out=$(bash "$KIT/tooling/kit-preflight.sh" --unassessable) || exit 1
  printf '%s' "$out" | grep -q '1 unassessable critical' || exit 1
  # The task and the reason are what §0's stop conditions 1 and 3 are judged against, so an
  # output that reported only a count would disarm both while looking correct.
  printf '%s' "$out" | grep -q 'T-U1' || exit 1
  printf '%s' "$out" | grep -q 'predates the summary column' || exit 1
  # A standing blind spot is NOT a stop: exit 0, or the unsatisfiable gate is back.
  bash "$KIT/tooling/kit-preflight.sh" --unassessable >/dev/null 2>&1 || exit 1
  exit 0 )
check $? "--unassessable names the finding, its task and its reason, and does not itself stop"
rm -rf "$blind"

# The document must CALL the command, not restate the rule — the same discipline the criticals
# box already follows, and the reason this step reads the script's flag list rather than a
# hardcoded name: a flag renamed without the protocol following goes red.
P="$KIT/docs/TRIAL-PROTOCOL.md"
grep -q 'kit-preflight.sh --unassessable' "$P"
check $? "TRIAL-PROTOCOL section 0 calls the command rather than describing it"
grep -qE 'kit-preflight\.sh --unassessable' "$KIT/tooling/kit-preflight.sh"
check $? "and the flag it calls is one kit-preflight.sh documents"
# The report has to carry the number, or §0's "count went up" stop is unevaluable next trial.
grep -q 'Unassessable crits:' "$P"
check $? "the report template carries the count, so the next trial can compare"
# EVERY EXCLUSION FROM --criticals NEEDS A BOX, and this is the check that says so for the fourth
# one. The gate excludes superseded findings exactly as it excludes unassessable ones, so §0 is
# incomplete without it -- and the day the verb landed this repository passed --criticals with
# THIRTEEN excluded criticals behind the zero. A gate is only as honest as the report of what it
# does not count.
grep -q 'kit-preflight.sh --superseded' "$P"
check $? "TRIAL-PROTOCOL section 0 also calls the superseded count"
grep -qE 'kit-preflight\.sh --superseded' "$KIT/tooling/kit-preflight.sh"
check $? "and that flag is one kit-preflight.sh documents too"
fi

if step "every table the schema declares is populated from text, or the index cannot hold it"; then
# AC5 of T-20260817-kit-index-deletes-the-plan-so-task-conte, and the reason it is worded that
# way: `goal` and `plan_item` were lost for two years' worth of rebuilds because nothing
# enumerated what the indexer does and does not fill. A test naming those two tables would have
# been written the day they were fixed and would not cover the SEVENTH table somebody adds next.
#
# So the expectation is DERIVED from the authority -- CREATE TABLE in schema.sql on one side,
# the INSERT targets in kit-index.sh on the other -- and a new table is covered without an edit.
#
# WHAT THIS STEP DOES NOT COVER, measured rather than assumed. It reads SOURCE TEXT, so it sees
# that an INSERT exists and not whether it runs. Proved by mutation: disabling the plan ingest
# with a condition that can never be true left this step fully GREEN while the round-trip step
# above went red. The two are not redundant and neither substitutes for the other -- this one
# catches a table nobody ever wrote a source for, that one catches a source that stopped
# working. Do not let a later cleanup merge them.
S="$KIT/tooling/schema.sql"; I="$KIT/tooling/kit-index.sh"
DECLARED=$(sed -n 's/^CREATE TABLE \([a-z_]*\).*/\1/p' "$S" | sort -u)
[ -n "$DECLARED" ]
check $? "schema.sql declares tables this step can enumerate"
FILLED=$(grep -oE 'INSERT (OR (REPLACE|IGNORE) )?INTO [a-z_]+' "$I" |
         awk '{print $NF}' | sort -u)
MISSING=""; LEAKED=""
for _t in $DECLARED; do
  printf '%s\n' "$FILLED" | grep -qx "$_t" && continue
  case "$_t" in
    # Reserved schema for a feature that does not exist yet: nothing anywhere writes these and
    # both hold zero rows, so "not populated by kit-index.sh" is correct rather than a defect.
    #
    # THE EXEMPTION IS CONDITIONAL AND THE CONDITION IS CHECKED BELOW. The moment any tool
    # inserts into them directly they become state with no text behind it — which is precisely
    # what `plan_item` was, and it survived unnoticed because no test enumerated the tables. A
    # skip list that cannot expire would reproduce that failure on purpose.
    accelerator|accel_candidate)
      _w=$(grep -rlE "INSERT( OR (REPLACE|IGNORE))? INTO $_t([^a-z_]|\$)" "$KIT/tooling" 2>/dev/null |
           grep -v 'kit-index\.sh' || true)
      [ -z "$_w" ] || LEAKED="$LEAKED $_t(written by $(basename "$_w"))"
      continue ;;
  esac
  MISSING="$MISSING $_t"
done
[ -z "$MISSING" ]
check $? "kit-index.sh populates every table it does not delegate (unfilled:${MISSING:-none})"
# The exemption's own premise, asserted rather than assumed. If this fires, the answer is not
# to widen the list above: it is that a second table now needs a text source, exactly as the
# plan did.
[ -z "$LEAKED" ]
check $? "the exempt tables are still written by nothing (${LEAKED:-still unwritten})"
# The specific pair this was written for, asserted by name as well. The derived check above is
# the general property; this is the regression, and a general check that quietly stopped
# covering the original case is how the first version of this defect survived.
printf '%s\n' "$FILLED" | grep -qx plan_item && printf '%s\n' "$FILLED" | grep -qx goal
check $? "and specifically goal and plan_item, which the rebuild used to drop"
fi

if step "every tracked JSON is LF in the index and resolves to the eol attribute"; then
# `.gitattributes` pinned *.sh, *.py, *.sql, *.md, the log, the plan and the licences -- and
# NOT *.json. With core.autocrlf=true every tracked .json was `i/lf w/crlf`: correct in the
# repository and CRLF on disk. The git blob hash therefore stayed stable while a hash of the
# FILE differed between a Windows and a Linux checkout, so a census disposition that
# references an artefact by an on-disk hash would be recorded on one platform and read as
# stale on the other -- D5's provenance half, defeated by a checkout setting.
#
# Found by an approach review on 2026-09-08 and demonstrated the same hour by this repository
# on itself: `git add` warned "LF will be replaced by CRLF the next time Git touches it" on the
# two review artefacts, in the very commit that recorded the finding predicting it.
#
# THE DENOMINATOR IS ASSERTED. A pattern that matched no file would leave the flag at 0 and
# report green having compared nothing -- the same hole the finding-vocabulary step above
# closes with its own `seen -eq 0` check.
jbad=0; jn=0
git -C "$KIT" ls-files --eol '*.json' > "$WORK.jsoneol" 2>/dev/null
while IFS= read -r ln; do
  [ -n "$ln" ] || continue
  jn=$((jn + 1))
  case "$ln" in
    i/lf*) ;;
    *) echo "  index copy is not LF: $ln"; jbad=1 ;;
  esac
  case "$ln" in
    *"attr/text eol=lf"*) ;;
    *) echo "  no eol=lf attribute resolves here: $ln"; jbad=1 ;;
  esac
done < "$WORK.jsoneol"
if [ "$jn" -eq 0 ]; then
  echo "  no tracked .json matched -- the guard compared nothing"
  echo "  (this is a FAILURE, not a pass: an empty denominator is not a clean result)"
  jbad=1
fi
rm -f "$WORK.jsoneol"
check $jbad "all $jn tracked .json are LF in the index and resolve to eol=lf"
fi

if step "the criteria report reconciles every box it found, and reports rather than refuses"; then
# T-20260909. This report exists because four mechanisms for the same ruling were rejected by
# seven blind reviews, and the surviving recommendation was to print the numbers rather than gate
# on them. So the two things worth asserting are the two that would make the printing worthless:
# that a box can go missing without the reader being told, and that a bad number becomes a stop.
crit="$WORK.crit"; rm -rf "$crit"; mkdir -p "$crit"
( cd "$crit" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1

  # One completed task with an unticked criterion -- the population this report was built for.
  # Its LAST box sits under a SUB-HEADING inside the criteria block, which the strict section
  # rule puts out of section. That box is the one a silent parser would drop.
  {
    printf -- '---\nid: T-C1\ntitle: closed with an open box\ntier: T2\nstate: completed\n---\n\n'
    printf -- '## Acceptance criteria\n\n'
    printf -- '- [x] this one was met\n'
    printf -- '- [ ] this one was not\n'
    printf -- '- [~] this one carries the third glyph\n'
    printf -- '\n### Added later\n\n'
    printf -- '- [ ] out of section under the strict rule\n'
  } > .project/tasks/T-C1.md

  # A second task with CRLF line endings, because six task files in the kit are CRLF in the
  # working tree and a report that counts zero boxes there would be quietly wrong.
  {
    printf -- '---\r\nid: T-C2\r\ntitle: crlf\r\ntier: T3\r\nstate: created\r\n---\r\n\r\n'
    printf -- '## Acceptance criteria\r\n\r\n'
    printf -- '- [ ] a criterion in a CRLF file\r\n'
  } > .project/tasks/T-C2.md

  # A third with NO criteria section at all -- must be named, not silently counted as clean.
  printf -- '---\nid: T-C3\ntitle: none\ntier: T1\nstate: created\n---\n\nbody\n' > .project/tasks/T-C3.md

  git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  out=$(bash "$KIT/tooling/kit-criteria.sh" --all 2>/dev/null) || exit 1

  # THE RECONCILIATION IS THE FAIL-OPEN GUARD, and this is what proves it can fail. Five boxes
  # exist across the three files; four are in section and one is not. If the parser ever drops
  # the out-of-section box, accounted becomes 4 while found stays 5 and MISMATCH prints.
  printf '%s' "$out" | grep -q 'accounted (met+open+other+out) 5'   || exit 1
  printf '%s' "$out" | grep -q 'boxes found in files           5'   || exit 1
  printf '%s' "$out" | grep -q 'MISMATCH'                           && exit 1

  # The counts themselves, by glyph, so a change that reclassifies one is caught.
  printf '%s' "$out" | grep -q 'criteria met          1'            || exit 1
  printf '%s' "$out" | grep -q 'criteria open         2'            || exit 1
  printf '%s' "$out" | grep -q 'criteria other glyph  1'            || exit 1
  printf '%s' "$out" | grep -q 'out-of-section boxes  1'            || exit 1

  # CRLF is stripped: T-C2's single box is one of the two open ones counted above, and the task
  # must not read as having no criteria.
  printf '%s' "$out" | grep 'T-C2' | grep -q 'no criteria recorded' && exit 1

  # A task with no section is NAMED. Counted as clean, it would be a task whose criteria vanished
  # and whose row still looked fine -- the exact shape the reconciliation exists to prevent.
  printf '%s' "$out" | grep 'T-C3' | grep -q 'no criteria recorded' || exit 1
  printf '%s' "$out" | grep -q 'no criteria recorded: 1'            || exit 1

  # The completed task with an open criterion is surfaced by id.
  printf '%s' "$out" | grep -q 'completed with open   1'            || exit 1
  # CAPTURED, NOT PIPED. Under `set -o pipefail` a direct pipe into `grep -q` returns 141:
  # grep exits on the first match and the script takes SIGPIPE mid-write. That is a real property
  # of any caller piping this report into a short-circuiting reader, and the house idiom -- assign
  # then grep -- is what every other step here uses.
  cwo=$(bash "$KIT/tooling/kit-criteria.sh" --closed-with-open 2>/dev/null) || exit 1
  printf '%s' "$cwo" | grep -q 'T-C1' || exit 1

  # IT REFUSES NOTHING. The news here is bad -- a completed task has an open criterion -- and the
  # exit status must still be 0. A report that stops is a gate, and this design was chosen
  # precisely because the gate variants were rejected.
  bash "$KIT/tooling/kit-criteria.sh" >/dev/null 2>&1 || exit 1
  exit 0 )
check $? "counts by glyph, reconciles 5 of 5, names the task with no section, and exits 0"
rm -rf "$crit"

# The report must not be wired into the gitignored generated file, which is where it would be
# invisible to a diff, a pull request and CI -- the reason it prints to stdout in the first place.
grep -q 'STATUS.generated.md' "$KIT/tooling/kit-criteria.sh"
gs=$?
[ $gs -ne 0 ] || grep -qE 'WHY NOT A SECTION|gitignored' "$KIT/tooling/kit-criteria.sh"
check $? "any mention of the generated file is the reasoning, not a write into it"
fi

if step "a reference written in prose fails until it is declared"; then
# THE MUTATION IS THE POINT. docs/DEPENDENCIES.md audited 273 prose references by hand on
# 2026-09-13 and the commit that did it said plainly that nothing stopped the next two hundred
# tasks doing the same. A check that only ever passed on an already-audited backlog would be the
# snapshot again wearing a control's clothes, so this step asserts the RED arm first and the
# green arm only after the declaration exists.
#
# Four cases, and three of them are the ones that decide whether the control is usable:
#   1. live -> live, undeclared        MUST fail. Without this the check is decoration.
#   2. the same pair, declared         MUST pass. A row in the map is a decision, not a fix.
#   3. live -> completed, undeclared   MUST pass. The planner cannot order against closed work.
#   4. live -> no task file at all     MUST pass HERE. That is a different fault with its own
#                                      report (kit-status) and its own task; merging the two
#                                      would hand one remedy to two problems.
rx="$WORK.refs"; rm -rf "$rx"; mkdir -p "$rx/src"
( cd "$rx" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  mkdir -p docs
  : > docs/dependency-map.tsv
  w() { printf -- '---\nid: %s\ntitle: %s\ntier: T2\nstate: %s\n---\n%s\n' "$1" "$1" "$2" "$3" > ".project/tasks/$1.md"; }
  w T-20260101-alpha created 'Body cites T-20260101-beta as context.'
  w T-20260101-beta  created 'Nothing here.'
  w T-20260101-gamma completed 'Closed work.'
  git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  bash "$KIT/tooling/kit-plan.sh" --check-refs >/dev/null 2>&1
  [ $? -eq 1 ] || { echo "  case 1: an undeclared live reference did not fail"; exit 1; }

  printf 'T-20260101-alpha\tT-20260101-beta\trelated\n' > docs/dependency-map.tsv
  bash "$KIT/tooling/kit-plan.sh" --check-refs >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "  case 2: a declared reference still failed"; exit 1; }

  w T-20260101-alpha created 'Body cites T-20260101-beta and also T-20260101-gamma.'
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-plan.sh" --check-refs >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "  case 3: a reference to completed work was required to be declared"; exit 1; }

  w T-20260101-alpha created 'Body cites T-20260101-beta and T-20260101-nosuchtask.'
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  out=$(bash "$KIT/tooling/kit-plan.sh" --check-refs 2>&1); rc=$?
  [ $rc -eq 0 ] || { echo "  case 4: an unresolvable id was failed here instead of reported"; exit 1; }
  printf '%s' "$out" | grep -q '1 unresolvable' ||
    { echo "  case 4: the unresolvable id was not counted in the report"; exit 1; }
  exit 0 )
check $? "undeclared fails, declared passes, closed and unresolvable ends do not"
rm -rf "$rx"
fi


if step "spend capture that stopped is not reported as live"; then
# The arm this proves did not exist until 2026-09-14, and its absence was not theoretical:
# capture stopped in this repository on 2026-09-10 and `--spend` reported "spend capture is
# live", exit 0, for four days and 122 commits. Both existing arms are past-tense -- "was
# anything ever recorded", "was anything derived" -- and a recorder that worked and then died
# passes both. Every token figure the project quotes is computed from that series.
#
# TWO ARMS, because only the pair distinguishes the check from a check that always fails:
#   1. a reading with no commit after it        MUST pass  -- live is a real state
#   2. one commit later, nothing re-recorded    MUST fail  -- and name the count
sp="$WORK.spendlive"; rm -rf "$sp"; mkdir -p "$sp/src"
# A second fixture with NO COMMITS, for arm 4. kit-init.sh writes the profile; nothing commits it.
rm -rf "$sp.empty"; mkdir -p "$sp.empty"
( cd "$sp.empty" && git init -q -b main 2>/dev/null && git config user.email a@b.c &&
  git config user.name T && bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1 &&
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":1,"output_tokens":1}}}
' > sess.jsonl ) >/dev/null 2>&1
( cd "$sp" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-s\ntitle: s\ntier: T2\n---\nb\n' > .project/tasks/T-s.md
  echo x > src/a
  git add -A
  # DATES ARE PINNED, and the reason is a measured flake rather than tidiness. The comparator
  # is `git log --since=<reading>`, which resolves to one-second granularity. Left at wall
  # time the seed commit and the reading land in the same second on a fast runner -- measured
  # one second apart on Windows, same second on ubuntu, which is exactly how this step passed
  # locally and failed in CI on its first push. Pinning one commit far before the reading and
  # one far after removes the boundary from the test without weakening what it asserts.
  GIT_AUTHOR_DATE="2020-01-01T00:00:00Z" GIT_COMMITTER_DATE="2020-01-01T00:00:00Z"     git commit -q --no-verify -m "chore: seed"
  # The commit is dated well BEFORE the reading, so arm 1 has a reading newer than every commit.
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100,"output_tokens":50}}}\n' > sess.jsonl
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  bash "$KIT/tooling/kit-preflight.sh" --spend >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "  arm 1: a live recorder was reported as stale"; exit 1; }

  # One commit, no new reading. Nothing else changes.
  echo y > src/b; git add -A
  GIT_AUTHOR_DATE="2035-01-01T00:00:00Z" GIT_COMMITTER_DATE="2035-01-01T00:00:00Z"     git commit -q --no-verify -m "chore: work with no reading"
  out=$(bash "$KIT/tooling/kit-preflight.sh" --spend 2>&1); rc=$?
  [ $rc -eq 1 ] || { echo "  arm 2: work landed with no reading and --spend still exited $rc"; exit 1; }
  printf '%s' "$out" | grep -q "1 commit(s) have landed since" ||
    { echo "  arm 2: the count was not named in the report"; exit 1; }

  # ARM 3 -- A READING THE COMPARATOR CANNOT PARSE MUST NOT PASS. As first shipped this arm
  # broke its own rule: `git log --since=<garbage>` prints nothing, the count came out 0, and a
  # malformed timestamp silently disabled the whole check. Exit 2, never 0: the property could
  # not be evaluated, which is not the same as holding.
  sed -i.bak 's/"at":"[0-9][^"]*"/"at":"not-a-timestamp"/' .project/events.ndjson
  rm -f .project/events.ndjson.bak
  rm -f .project/index.db
  bash "$KIT/tooling/kit-preflight.sh" --spend >/dev/null 2>&1
  [ $? -eq 2 ] || { echo "  arm 3: an unparseable reading did not report as unanswerable"; exit 1; }

  # ARM 4 -- NO COMMITS AT ALL IS A REAL PASS, not an error. Nothing has landed since the reading
  # because nothing has landed. Asked separately from arm 3 so a repository that is merely new is
  # never confused with one whose reading is corrupt.
  cd "$sp.empty" || exit 1
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" >/dev/null 2>&1
  bash "$KIT/tooling/kit-preflight.sh" --spend >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "  arm 4: a repository with no commits was not a pass"; exit 1; }
  exit 0 )
check $? "a reading newer than every commit passes; one commit later it does not"
rm -rf "$sp"
fi


if step "a goal's state is text in the plan and survives a replan"; then
# goal.state has been in schema.sql since the beginning, reserved and UNWRITTEN, with a comment
# saying every rebuild resets it to 'open' and that the condition for using it is a TEXT SOURCE
# first -- because a table nothing can rebuild from text is the second source of truth ADR 0004
# exists to avoid. This is that text source, and these are the four things that make it one.
#
#   1. set, and it reaches the derived row
#   2. REPLANNED WITH NO FLAG, and it is still there -- the whole point. A planner that reset it
#      would silently reopen every milestone anyone had closed, which is the sqlite defect moved
#      into the text rather than fixed.
#   3. a legacy spelling normalises through the SAME state_alias table task states use, which is
#      the argument for reusing the task vocabulary instead of inventing one for milestones
#   4. an unaccepted value is REFUSED, at both doors -- the planner where the operator sees it,
#      and the indexer because a committed plan file is untrusted input parsed into SQL
gs="$WORK.goalstate"; rm -rf "$gs"; mkdir -p "$gs/src"
( cd "$gs" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-g\ntitle: g\ntier: T2\n---\nb\n' > .project/tasks/T-g.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  G() { sqlite3 .project/index.db "SELECT state FROM goal WHERE id='default';" | tr -d '\015'; }

  bash "$KIT/tooling/kit-plan.sh" --goal-state in-progress >/dev/null 2>&1
  grep -q "^#goal_state	in-progress$" .project/plans/default.tsv ||
    { echo "  1: the plan file does not carry the state"; exit 1; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(G)" = "in-progress" ] || { echo "  1: derived row is [$(G)], wanted in-progress"; exit 1; }

  bash "$KIT/tooling/kit-plan.sh" >/dev/null 2>&1
  grep -q "^#goal_state	in-progress$" .project/plans/default.tsv ||
    { echo "  2: a replan with no flag dropped the state"; exit 1; }

  bash "$KIT/tooling/kit-plan.sh" --goal-state done >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  [ "$(G)" = "completed" ] || { echo "  3: legacy 'done' derived as [$(G)], wanted completed"; exit 1; }

  bash "$KIT/tooling/kit-plan.sh" --goal-state bogus >/dev/null 2>&1
  [ $? -eq 2 ] || { echo "  4: the planner accepted an unaccepted state"; exit 1; }
  # The indexer must refuse it on its own, not trust that the planner already did.
  sed -i.bak 's/^#goal_state	done$/#goal_state	bogus/' .project/plans/default.tsv; rm -f .project/plans/default.tsv.bak
  out=$(bash "$KIT/tooling/kit-index.sh" 2>&1)
  printf '%s' "$out" | grep -q "goal_state" ||
    { echo "  4: the indexer loaded a plan file carrying an unaccepted state"; exit 1; }
  exit 0 )
check $? "set, preserved across a replan, normalised from a legacy spelling, refused at both doors"
rm -rf "$gs"
fi

if step "the closed-state line names every closed state the vocabulary declares"; then
# A LIST THAT CANNOT GO RED IS THE POINT OF THIS STEP. Until 2026-09-19 the Closed line named its
# three states as SQL literals, so it reported what someone had hardcoded rather than what
# `kit_state_vocab` declares -- and with the vocabulary frozen at seven, no assertion over the
# CURRENT states could tell the two implementations apart. Both print the same line. So this step
# MUTATES THE VOCABULARY ITSELF, in a copy of the kit, and asks whether the report follows.
#
# That is the only arm that fails on the pre-fix code, and it is arm 2. Arm 1 alone would be a
# green that cannot fail -- exactly what LESSONS.md section 1 refuses -- so it is kept only as the
# control that proves the fixture is sane before the mutation is applied.
#
# Only tooling/ is copied: kit-init.sh reads ../templates, so the fixture is INITIALISED from the
# real kit and only kit-index.sh and kit-status.sh -- the two that source kit-lib.sh's vocabulary
# -- are run from the mutated copy.
cs="$WORK.closedstates"; rm -rf "$cs"; mkdir -p "$cs"
# The copy lives OUTSIDE the fixture repository on purpose: inside it, `git add -A` commits the
# whole kit into the subject's own history, which is both wasteful and a second thing the indexer
# then walks. A trial has the same rule about not writing into the subject.
csk="$WORK.closedstateskit"; rm -rf "$csk"; mkdir -p "$csk" && cp -R "$KIT/tooling" "$csk/tooling"
( cd "$cs" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-done\ntitle: d\ntier: T2\nstate: completed\n---\nb\n'  > .project/tasks/T-done.md
  printf -- '---\nid: T-canc\ntitle: c\ntier: T2\nstate: cancelled\n---\nb\n'  > .project/tasks/T-canc.md
  printf -- '---\nid: T-open\ntitle: o\ntier: T2\nstate: created\n---\nb\n'    > .project/tasks/T-open.md
  git add -A && git commit -q --no-verify -m "chore: seed"

  LINE() { grep -m1 -- '^- .*completed' STATUS.generated.md | tr -d '\015'; }

  # ARM 1 -- the control. Three declared closed states, and `abandoned` has NO rows, so a zero
  # must print rather than the state disappearing. Absent and zero are different statements.
  bash "$csk/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$csk/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(LINE)" = "- 1 completed, 1 cancelled, 0 abandoned" ] ||
    { echo "  1: control line is [$(LINE)], wanted '- 1 completed, 1 cancelled, 0 abandoned'"; exit 1; }

  # ARM 2 -- THE MUTATION. Declare an eighth state, closed, with no rows. A derived line reports
  # it as zero; a hardcoded one omits it silently and this arm goes red, which is the whole
  # assertion. `superseded` is used because it is a real word in this project's finding
  # vocabulary and could plausibly be proposed for tasks one day.
  sed -i.bak "s/printf 'created planned in-progress on-hold completed cancelled abandoned'/printf 'created planned in-progress on-hold completed cancelled abandoned superseded'/" "$csk/tooling/kit-lib.sh"
  sed -i.bak "s/printf 'completed cancelled abandoned'/printf 'completed cancelled abandoned superseded'/"                                         "$csk/tooling/kit-lib.sh"
  grep -q 'abandoned superseded' "$csk/tooling/kit-lib.sh" ||
    { echo "  2: the mutation did not apply -- kit_state_vocab or kit_state_closed was reworded"; exit 1; }

  bash "$csk/tooling/kit-index.sh"  >/dev/null 2>&1
  bash "$csk/tooling/kit-status.sh" >/dev/null 2>&1
  [ "$(LINE)" = "- 1 completed, 1 cancelled, 0 abandoned, 0 superseded" ] ||
    { echo "  2: after adding a closed state the line is [$(LINE)]; a hardcoded list cannot see it"; exit 1; }

  # ARM 3 -- order is the vocabulary's, not the alphabet's. Sorting by name would put abandoned
  # first and silently reorder a published report, so the rowid ordering is asserted rather than
  # left to chance.
  printf '%s' "$(LINE)" | grep -q '^- 1 completed, 1 cancelled, 0 abandoned' ||
    { echo "  3: the states are not in vocabulary declaration order: [$(LINE)]"; exit 1; }
  exit 0 )
check $? "controlled, mutation-proved by an eighth closed state, and ordered by the vocabulary"
rm -rf "$cs" "$csk"
fi


if step "a finding joins the reviewer run that produced it, or is reported as unjoinable"; then
# THE FLAG EXISTED AND THE COLUMN DID NOT. kit-finding.sh has accepted --agent-id since it was
# written and kit_findings.py puts it in the event -- 550 of 628 events in this repository carry
# the key -- but `finding` had no agent_id column, so the indexer had nowhere to store it and the
# value was dropped on every rebuild. The 2026-09-09 trial diagnosed this as a documentation gap,
# which was half of it: the door was undocumented AND the destination did not exist.
#
# THREE ARMS, because "unjoinable" is two different faults and one number hides the second:
#   1. id supplied and matching a spend row  -> the join returns the row
#   2. no id at all                          -> counted as carrying no agent id
#   3. id supplied matching NOTHING          -> counted separately. Not a missing label: it is
#      two id SPACES, which is what this repository's own history shows -- operator run labels
#      on findings against harness subagent ids on spend. "Pass the flag" is the wrong remedy.
fa="$WORK.findagent"; rm -rf "$fa"; mkdir -p "$fa/src" "$fa/sess/subagents"
( cd "$fa" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-f\ntitle: f\ntier: T2\n---\nb\n' > .project/tasks/T-f.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # A reviewer run, recorded the way kit-spend.sh records one.
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":1,"output_tokens":9}}}\n' > sess/subagents/agent-R1.jsonl
  printf '{"agentType":"implementation-reviewer","spawnDepth":1}' > sess/subagents/agent-R1.meta.json
  # --transcript is the SESSION file; kit-spend.sh finds the agent transcript beside it under
  # subagents/, which is the shape the spend step earlier in this file already proves. Handing
  # it the subagent file directly records nothing, silently -- which is how arm 1 first failed.
  printf '{"type":"assistant","message":{"model":"m","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":1,"output_tokens":1}}}\n' > sess.jsonl
  bash "$KIT/tooling/kit-spend.sh" --transcript "$PWD/sess.jsonl" \
    --agent-id R1 --agent implementation-reviewer --session S1 >/dev/null 2>&1

  # THROUGH THE DOCUMENTED DOOR, and that is the point of this arm rather than a detail. The
  # first version recorded through kit-finding.sh, which proves the plumbing and NOT the path an
  # agent is told to use -- and the defect being fixed was precisely that the documented door
  # omitted the flag. A test exercising a different door from the one the documentation names
  # cannot catch that class of defect at all.
  #
  # skills/verify-ladder/SKILL.md names `kit-review-record.sh --reply-file` as the reply-in-hand
  # door, and it is how every one of the 2026-09-09 trial's 11 findings was recorded.
  F() {
    printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"fail-open","severity":"major","lang":"bash","summary":"%s"}]}' "$1" > rep.json
    bash "$KIT/tooling/kit-review-record.sh" --task T-f --agent implementation-reviewer \
      --reply-file rep.json ${2:+--agent-id "$2"} >/dev/null 2>&1
  }
  F "attributed to a real run" R1
  F "recorded with no run at all"
  F "attributed to a run nobody recorded" ghost-run
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  joined=$(Q "SELECT COUNT(*) FROM finding f JOIN spend s ON s.agent_id=f.agent_id WHERE f.agent_id='R1';")
  [ "$joined" = 1 ] || { echo "  arm 1: a finding with a real run id did not join ($joined)"; exit 1; }
  none=$(Q "SELECT COUNT(*) FROM finding WHERE COALESCE(agent_id,'')='';")
  [ "$none" = 1 ] || { echo "  arm 2: findings with no id counted $none, wanted 1"; exit 1; }
  orph=$(Q "SELECT COUNT(*) FROM finding f WHERE COALESCE(f.agent_id,'')<>'' AND NOT EXISTS
              (SELECT 1 FROM spend s WHERE s.agent_id=f.agent_id);")
  [ "$orph" = 1 ] || { echo "  arm 3: findings with an unmatched id counted $orph, wanted 1"; exit 1; }

  # The report must SAY both, or the counts are invisible where anyone reads them.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q "1 of 3 carry no agent id" STATUS.generated.md ||
    { echo "  arm 2: kit-status did not report the unattributed count"; exit 1; }
  grep -q "1 carry one that matches no spend row" STATUS.generated.md ||
    { echo "  arm 3: kit-status did not report the unmatched count separately"; exit 1; }

  # ARMS 4-6: the SAME faults, caught at RECORD time rather than at kit-status time.
  #
  # Arms 1-3 prove the report is right. They cannot prove anyone reads it, and on 2026-09-14 the
  # answer was nobody: this repository stood at 54 of 54 attributed findings matching no spend
  # row while the count sat on the status page, correct, through an entire trial that asserted
  # the opposite twice. AC2 of T-20260911-a-finding-recorded-by-hand-carries-no-ag allowed the
  # report at kit-status time OR at record time; these arms cover the arm it did not take.
  #
  # Captures stderr rather than discarding it, which is the whole difference from F() above.
  FE() {
    printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"fail-open","severity":"major","lang":"bash","summary":"%s"}]}' "$1" > rep.json
    bash "$KIT/tooling/kit-review-record.sh" --task T-f --agent implementation-reviewer \
      --reply-file rep.json ${2:+--agent-id "$2"} 2>&1
  }

  # 4. a run id that DOES resolve must say nothing. This is the arm a broken check fails
  #    loudest on: a warning that fires on everything is not a check, it is noise, and it
  #    trains the reader to skip the line that matters.
  out=$(FE "arm 4 quiet on a real id" R1)
  case "$out" in
    *"SESSION id"*|*"matches no spend row"*|*"nothing can join"*)
      echo "  arm 4: a resolvable agent id was warned about anyway"; exit 1 ;;
  esac

  # 5. an id that resolves to nothing: named, and named as unresolvable rather than as a typo.
  out=$(FE "arm 5 unresolvable id" ghost-run-2)
  case "$out" in
    *"ghost-run-2"*"matches no spend row"*) ;;
    *) echo "  arm 5: an unresolvable agent id drew no record-time advice"; exit 1 ;;
  esac

  # 6. THE ONE THAT WOULD HAVE CAUGHT THE REAL MISTAKE. A session id is not a wrong string, it
  #    is the wrong ID SPACE -- the harness hands the session id to the caller, so it is the
  #    value most likely to be passed in good faith. Generic "does not resolve" wording leaves
  #    the caller to guess; this asserts the diagnosis names it.
  out=$(FE "arm 6 session id mistaken for a run id" S1)
  case "$out" in
    *"SESSION id"*) ;;
    *) echo "  arm 6: a session id passed as a run id was not diagnosed as such"; exit 1 ;;
  esac

  # And the advice must never change the exit status: the finding is recorded either way.
  # Refusing would trade a silent non-join for a lost finding, which is the worse of the two.
  FE "arm 6b still recorded" S1 >/dev/null || \
    { echo "  arm 6b: the advisory turned recording into a failure"; exit 1; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  n=$(Q "SELECT COUNT(*) FROM finding WHERE agent_id='S1';")
  [ "$n" = 2 ] || { echo "  arm 6b: findings warned about were not recorded ($n of 2)"; exit 1; }
  exit 0 )
check $? "the run id reaches the table, joins, and both unjoinable faults are counted apart"
rm -rf "$fa"
fi


if step "a declared rung that does not run is named, and blocks a completion claim"; then
# The ladder had TWO dispositions -- satisfied, or unavailable with the tier raised -- and a
# third state happens: a satisfaction IS declared and does not run. `## Completion` permitted it
# by omission, which is how the 2026-09-09 trial reported COMPLETE over a change that does not
# compile, with two reviewers passing it at rungs 4 and 5.
#
# Three assertions, because the fix has three halves and any one alone is decoration:
#   1. the ladder NAMES the state and says it blocks completion  (prose, asserted as prose)
#   2. TRIAL-PROTOCOL section 3 carries the profile-change VOID condition, which was written in
#      section 2 and never carried here -- the only condition on that list that has actually
#      fired on a real trial
#   3. --commands SEPARATES the three outcomes on a real fixture. This is the load-bearing one:
#      a comment-only declaration (`commands.build: # none`) handed to a shell RUNS and exits 0,
#      so a naive check reports a rung satisfiable when nothing is declared -- the same
#      conflation the ladder gap is about, one layer down.
L="$KIT/skills/verify-ladder/SKILL.md"; T="$KIT/docs/TRIAL-PROTOCOL.md"
bad=0
grep -q "unsatisfiable" "$L" || { echo "  the ladder does not name the third disposition"; bad=1; }
grep -qi "blocks a completion claim\|blocks completion" "$L" ||
  { echo "  the ladder does not say the third disposition blocks completion"; bad=1; }
grep -q "profile changed mid-trial" "$T" ||
  { echo "  section 3 does not carry the profile-change condition"; bad=1; }
grep -q "preflight.sh --commands" "$T" ||
  { echo "  pre-flight does not call --commands before the clock starts"; bad=1; }
check $bad "the ladder names it, and the protocol gates and voids on it"

rd="$WORK.rungdisp"; rm -rf "$rd"; mkdir -p "$rd/src"
( cd "$rd" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  git add -A && git commit -q --no-verify -m "chore: seed"
  P="$KIT/tooling/kit-preflight.sh"
  set_cmd() { sed -i.bak "s|^commands.$1:.*|commands.$1:  $2|" .claude/project-profile.md; rm -f .claude/project-profile.md.bak; }

  # All four declared and runnable -> pass, and nothing reported as undeclared.
  for k in build test lint typecheck; do set_cmd "$k" "true"; done
  out=$(bash "$P" --commands 2>&1); rc=$?
  [ $rc -eq 0 ] || { echo "  arm 1: four runnable commands did not pass (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q "4 pass, 0 ran and reported failures, 0 with nothing declared" ||
    { echo "  arm 1: the counts were not reported"; exit 1; }

  # A COMMENT is not a declaration. Run blindly it exits 0 and reads as satisfiable.
  set_cmd build "# none -- nothing is compiled here"
  out=$(bash "$P" --commands 2>&1); rc=$?
  [ $rc -eq 0 ] || { echo "  arm 2: a comment-only declaration was treated as a failure"; exit 1; }
  printf '%s' "$out" | grep -q "commands.build      NOTHING DECLARED" ||
    { echo "  arm 2: a comment ran as a command instead of reading as undeclared"; exit 1; }

  # RAN AND FAILED IS NOT A STOP. This is the arm the first version got wrong: it classified on
  # exit code alone, so `cargo check` exiting 101 with 91 real type errors was reported as
  # "DECLARED AND DOES NOT RUN" -- a statement about something that did not happen. Section 0's
  # own baseline box blesses this case in as many words: "a subject whose tests already fail is
  # a valid trial subject, but only if you knew that first". Measured against the trial-2 copy,
  # where the old arm would have refused the trial over errors already in its own baseline.
  set_cmd typecheck "sh -c 'exit 101'"
  out=$(bash "$P" --commands 2>&1); rc=$?
  [ $rc -eq 0 ] ||
    { echo "  arm 3: a command that RAN and reported failures was treated as a stop (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q "ran, exit 101 -- a baseline fact" ||
    { echo "  arm 3: a ran-and-failed command was not named as a baseline fact"; exit 1; }

  # COULD NOT RUN IS a stop, and 127 is the shell saying so. This is the state the box exists
  # for: the tooling is absent, and mid-trial there is no non-voiding remedy.
  # BOTH STATES AT ONCE, because the interesting question is whether a stop HIDES the rest. The
  # summary line does not print on a stop -- correctly, there is nothing to summarise -- so the
  # per-rung lines are the only record of what else was found, and a reader who sees only the
  # STOP would conclude the other rungs were never reached.
  set_cmd test "sh -c 'exit 101'"
  set_cmd typecheck "definitely-not-a-real-binary-here"
  out=$(bash "$P" --commands 2>&1); rc=$?
  [ $rc -eq 1 ] || { echo "  arm 4: absent tooling did not stop (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q "CANNOT RUN (exit 127) -- unsatisfiable" ||
    { echo "  arm 4: absent tooling was not named as unable to run"; exit 1; }
  printf '%s' "$out" | grep -q "ran, exit 101 -- a baseline fact" ||
    { echo "  arm 4: the stop hid a rung that ran and reported failures"; exit 1; }
  exit 0 )
check $? "pass, ran-and-failed, cannot-run and nothing-declared are four outcomes, not two"
rm -rf "$rd"
fi

if step "a zero escape count says which zero it is"; then
# The denominator side of this table has refused to read as clean since it was written: an
# absent `via:kit` population is called out as "not a clean result". The NUMERATOR had no such
# guard -- 0 escapes across every tier printed as a plain 0 and read as "nothing escaped", when
# what it meant was that `Fixes-Escape-Of` appeared in 0 of 324 commits because CLAUDE.md never
# mentioned it. kit-review-record.sh:226 names the identical confusion for findings.
#
# TWO ARMS, and the second is what makes the first more than a fixed string: the caveat must
# DISAPPEAR the moment a real escape is recorded, or it becomes decoration that survives its
# own cause.
ez="$WORK.escapezero"; rm -rf "$ez"; mkdir -p "$ez/src"
( cd "$ez" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-old\ntitle: old\ntier: T2\n---\nb\n' > .project/tasks/T-old.md
  printf -- '---\nid: T-new\ntitle: new\ntier: T2\n---\nb\n' > .project/tasks/T-new.md
  echo x > src/a; git add -A && git commit -q --no-verify -m "chore: seed"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q "No escape has ever been recorded" STATUS.generated.md ||
    { echo "  arm 1: a zero numerator printed with no caveat"; exit 1; }

  echo y > src/b; git add -A
  git commit -q --no-verify -m "fix: the defect T-old should have caught

Task-Id: T-new
Tier: T2
Fixes-Escape-Of: T-old"
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  n=$(sqlite3 .project/index.db "SELECT COUNT(*) FROM event WHERE kind='escaped';" | tr -d '\015')
  [ "$n" = 1 ] || { echo "  arm 2: the trailer recorded $n escape(s), wanted 1"; exit 1; }
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q "No escape has ever been recorded" STATUS.generated.md &&
    { echo "  arm 2: the caveat survived a real escape being recorded"; exit 1; }
  exit 0 )
check $? "the caveat appears while nothing is recorded and goes when something is"
rm -rf "$ez"
fi


if step "the baseline template demands a cause, not a verdict"; then
# `build pass/fail, tests pass/fail` was the template's baseline row, and on 2026-09-09 that
# shape recorded a subject as red while its release build PASSED and three CI jobs failed for
# three unrelated reasons. One job's cause stood in for four, and the aggregate word is what got
# quoted afterwards. An aggregate verdict is not a baseline; a later trial cannot tell an old
# failure from a new one, which is the comparison section 2 exists to make legitimate.
#
# Asserted on the TEMPLATE as well as the protocol, deliberately: the protocol is read once and
# the template is copied into every trial report, so the template is where the shape survives.
T="$KIT/docs/TRIALS/TEMPLATE.md"; P="$KIT/docs/TRIAL-PROTOCOL.md"
bad=0
# The per-check table, with a cause column -- not prose about causes somewhere in the file.
grep -qE '^\| check \| command \| exit \| seconds \| cause' "$T" ||
  { echo "  the template has no per-check baseline table with a cause column"; bad=1; }
grep -q 'CI job' "$T" ||
  { echo "  the template does not ask for each CI job's verdict separately"; bad=1; }
# The word itself, because "mark it as unverified" only works if the mark is a fixed token a
# reader can grep for. A synonym per trial is not a mark.
grep -q 'unverified' "$T" ||
  { echo "  the template does not require an unverified cause to be named as such"; bad=1; }
grep -q 'unverified' "$P" ||
  { echo "  the protocol does not require an unverified cause to be named as such"; bad=1; }
# And the old shape must not survive as an instruction anywhere. It may be QUOTED as the defect
# it was -- that is how the reason travels -- so the test is that it never stands alone as the
# thing to record.
if grep -qE '^\| Baseline before the kit \| build pass/fail' "$T"; then
  echo "  the template still instructs the aggregate shape"; bad=1
fi
check $bad "cause per check, per-CI-job verdicts, and unverified named as such"
fi


if step "a copy whose permissions reach outside it is not isolated"; then
# --isolated asked about git: a remote, and an alternates entry. A trial copy carries a THIRD
# path back and the check did not model it. Reproduced 2026-09-11 on the copy prepared for the
# highper-gateway trial: a tracked `.claude/settings.local.json` pre-approving `Bash(git *)` and
# seven entries naming a second checkout of the same subject outside the copy -- and --isolated
# printed "isolated" and exited 0. `git -C <that checkout> reset --hard` would have run with no
# prompt against the repository the copy exists to protect.
#
# FOUR ARMS, and arm 4 is what stops this being a check that refuses everything: a rule scoped
# inside the copy is fine and must still pass, or the gate becomes unsatisfiable and gets waived.
iso="$WORK.isoperm"; rm -rf "$iso"; mkdir -p "$iso/.claude"
( cd "$iso" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  echo x > f; git add -A; git commit -q --no-verify -m seed
  P="$KIT/tooling/kit-preflight.sh"
  W() { printf '%s' "$1" > "$iso/.claude/settings.local.json"; }

  rm -f "$iso/.claude/settings.local.json"
  bash "$P" --isolated "$iso" >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "  arm 1: a copy with no settings was refused"; exit 1; }

  W '{"permissions":{"allow":["Bash(git *)"]}}'
  out=$(bash "$P" --isolated "$iso" 2>&1); rc=$?
  [ $rc -eq 1 ] || { echo "  arm 2: an unscoped Bash(git *) did not fail (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q "unscoped" ||
    { echo "  arm 2: the offending rule was not named"; exit 1; }

  # A REAL path outside the copy, built at runtime rather than written as a literal. A literal
  # would be a baked absolute path, which validate.py refuses -- correctly, and it caught this.
  # Using the fixture's own parent is also the more faithful test: it is exactly the shape the
  # 2026-09-11 copy carried, a sibling checkout beside the copy rather than a fictional one.
  W "{\"permissions\":{\"allow\":[\"Bash(git -C $(dirname "$iso")/elsewhere status)\"]}}"
  out=$(bash "$P" --isolated "$iso" 2>&1); rc=$?
  [ $rc -eq 1 ] || { echo "  arm 3: an absolute path outside the copy did not fail (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q "outside" ||
    { echo "  arm 3: the outside path was not named"; exit 1; }

  W '{"permissions":{"allow":["Bash(cargo test)"]}}'
  out=$(bash "$P" --isolated "$iso" 2>&1); rc=$?
  [ $rc -eq 0 ] || { echo "  arm 4: a rule scoped inside the copy was refused (rc=$rc)"; exit 1; }
  # And the success line must say what it checked, so "isolated" never stands for a property
  # this check did not test.
  printf '%s' "$out" | grep -q "no permission rule" ||
    { echo "  arm 4: the pass line does not name what was checked"; exit 1; }
  exit 0 )
check $? "unscoped fails, outside-path fails, scoped passes, and the pass line says what it tested"
rm -rf "$iso"
fi

if step "a spend figure carries its as-of time, and says when the index is behind"; then
# On the 2026-09-09 trial the final kit-status.sh at 14:09Z reported the main loop at 6,902.9
# kBTE from a row written at 13:57:34Z, while the turn producing the report ended at 14:10:54Z
# at 10,259.6. The page understated the main loop by a THIRD and nothing on it said so. The
# figure was not wrong; it was OLD, and without an as-of those are the same page.
#
# TWO DIFFERENT FAULTS, and the second is the one that needs a notice rather than a timestamp:
#   as-of        how old the newest row IS. Always printed, per scope.
#   index behind a NEWER row is already in events.ndjson and nobody derived it. That figure is
#                not old, it is wrong, and the remedy is a rebuild rather than a caveat.
#
# The third arm is what stops the notice being decoration: after kit-index.sh it must GO.
sa="$WORK.spendasof"; rm -rf "$sa"; mkdir -p "$sa/src"
( cd "$sa" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-a\ntitle: a\ntier: T2\n---\nb\n' > .project/tasks/T-a.md
  git add -A && git commit -q --no-verify -m seed
  EV=.project/events.ndjson
  row() { printf '{"task":"T-a","kind":"spend","at":"%s","transcript":"t1","scope":"main","agent":"","agent_id":"","session":"s","model":"m","turns":1,"tok_in":10,"tok_out":20,"cache_read":0,"cache_write":0,"context":100}\n' "$1" >> "$EV"; }

  row 2026-01-01T00:00:00Z
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'as of 2026-01-01T00:00:00Z' STATUS.generated.md ||
    { echo "  arm 1: the spend figure carries no as-of time"; exit 1; }
  grep -q 'index is BEHIND' STATUS.generated.md &&
    { echo "  arm 1: the behind-notice fired on a current index"; exit 1; }

  # A later event, appended AFTER indexing: exactly the state a reading inside a session hits.
  row 2026-06-01T00:00:00Z
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'index is BEHIND' STATUS.generated.md ||
    { echo "  arm 2: a newer event than the index did not raise the behind-notice"; exit 1; }
  grep -q '2026-06-01T00:00:00Z' STATUS.generated.md ||
    { echo "  arm 2: the notice does not name the newer event's time"; exit 1; }

  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'index is BEHIND' STATUS.generated.md &&
    { echo "  arm 3: the notice survived the rebuild that fixed its cause"; exit 1; }
  grep -q 'as of 2026-06-01T00:00:00Z' STATUS.generated.md ||
    { echo "  arm 3: the as-of did not move to the newer row after rebuilding"; exit 1; }
  exit 0 )
check $? "as-of per scope, a behind-notice when the log is newer, and both correct after a rebuild"
rm -rf "$sa"
fi

if step "a brownfield adopter is told to decide git.adopted_at, and a greenfield one is not"; then
# INSTALL.md makes choosing git.adopted_at the FIRST step of a brownfield adoption, because the
# key decides what the kit believes about every commit predating it. kit-init.sh's printed next
# steps never mentioned it, so the documented step existed and the command that starts adoption
# never led to it.
#
# On the 2026-09-09 trial the session followed the printed order exactly and left it unset. The
# first status read "Trailer discipline degraded. 97 of 98 non-trivial commits carry no Task-Id"
# -- which is what INSTALL.md predicts for the unset case, in as many words. Leaving it unset is
# a legitimate choice; the defect is that it got made BY DEFAULT rather than by the adopter.
#
# TWO ARMS, and the second is the load-bearing one. A line that always prints is not guidance,
# it is noise in the one place an adopter reads carefully -- an empty repository has no earlier
# history to have a policy about.
ad="$WORK.adoptedat"; rm -rf "$ad"
mkdir -p "$ad/withhistory" "$ad/empty"
( cd "$ad/withhistory" || exit 1
  git init -q -b main 2>/dev/null; git config user.email a@b.c; git config user.name T
  echo x > f; git add -A; git commit -q --no-verify -m one
  out=$(bash "$KIT/tooling/kit-init.sh" 2>&1)
  printf '%s' "$out" | grep -q 'git.adopted_at' ||
    { echo "  arm 1: a repo with history was not told to decide git.adopted_at"; exit 1; }
  # Both choices AND their costs, or the adopter cannot decide -- the criterion is explicit that
  # naming the key alone is not enough.
  printf '%s' "$out" | grep -q 'unset' ||
    { echo "  arm 1: the unset choice and its cost are not named"; exit 1; }
  printf '%s' "$out" | grep -q 'INSTALL.md' ||
    { echo "  arm 1: the reader is not pointed at the fuller explanation"; exit 1; }
  exit 0 )
r1=$?
( cd "$ad/empty" || exit 1
  git init -q -b main 2>/dev/null; git config user.email a@b.c; git config user.name T
  out=$(bash "$KIT/tooling/kit-init.sh" 2>&1); rc=$?
  # SILENCE AND DEATH LOOK ALIKE, and the first version of this arm could not tell them apart.
  # Measured: mutating the guard to `if true` makes kit-init.sh exit 128 on an empty repository
  # -- `set -euo pipefail` plus `git rev-list --count HEAD` with no HEAD -- so it printed nothing,
  # and an arm that only checked for absence went GREEN over a crash. Assert the run worked and
  # said its normal piece first; only then does absence mean anything.
  [ $rc -eq 0 ] ||
    { echo "  arm 2: kit-init.sh failed on an empty repository (rc=$rc)"; exit 1; }
  printf '%s' "$out" | grep -q 'copy templates/github-trailer-gate.yml' ||
    { echo "  arm 2: the normal next steps did not print, so absence proves nothing"; exit 1; }
  printf '%s' "$out" | grep -q 'adopted_at' &&
    { echo "  arm 2: an empty repository was asked to choose between two histories it has not got"; exit 1; }
  exit 0 )
r2=$?
[ "$r1" = 0 ] && [ "$r2" = 0 ]
check $? "named with its costs where there is history, silent where there is none"
rm -rf "$ad"
fi


if step "two review rounds are three rows over two defects, not three findings"; then
# A defect a reviewer carried into a later round was recorded as a NEW row with nothing linking
# it to the one it repeats, so per-task and per-agent counts grew with the number of ROUNDS
# rather than of DEFECTS. Measured on the 2026-09-09 trial: 11 rows for 5 defects, two of them
# appearing three times each across rung 4, rung 5 and the re-review -- whose own summaries said
# "Carried over from round 1" with nowhere to put it.
#
# CLASS COULD NOT HAVE SUBSTITUTED. That same carried-over defect was classed `race`, `perf`,
# `race` across its three rows, so this fixture varies the class across the carry-over on
# purpose: a test whose two rounds agreed on class would pass against a (task, class) collapse
# that fails on the real data.
#
# FOUR ASSERTIONS, and the last two are what stop this being a column nobody reads:
#   3 rows, 2 distinct defects, 1 link      the criterion, exactly
#   the link RESOLVES to a real row         a dangling id is not a carried-over defect
#   kit-status SAYS both numbers            the count was always rows; saying which is the fix
#   omitting the field still validates      a reviewer that does not know it must not fail
co="$WORK.carryover"; rm -rf "$co"; mkdir -p "$co/src"
( cd "$co" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-c\ntitle: c\ntier: T2\n---\nb\n' > .project/tasks/T-c.md
  git add -A && git commit -q --no-verify -m seed
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  # Round 1, through the plain door -- and no carries_over, which is the omission arm.
  bash "$KIT/tooling/kit-finding.sh" --task T-c --agent implementation-reviewer \
    --class race --severity major --lang bash --summary "round one defect" >/dev/null 2>&1 ||
    { echo "  omission: a finding without carries_over was refused"; exit 1; }
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  r1=$(Q "SELECT id FROM finding LIMIT 1;")
  [ -n "$r1" ] || { echo "  round 1 recorded no row"; exit 1; }

  # Round 2: one carried over WITH A DIFFERENT CLASS, one genuinely new.
  printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"perf","severity":"major","lang":"bash","summary":"the same defect, carried over","carries_over":"%s"},{"class":"fail-open","severity":"minor","lang":"bash","summary":"a genuinely new one"}]}' "$r1" > r2.json
  bash "$KIT/tooling/kit-finding.sh" --task T-c --agent implementation-reviewer --json < r2.json >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  rows=$(Q "SELECT COUNT(*) FROM finding;")
  link=$(Q "SELECT COUNT(*) FROM finding f JOIN finding e ON e.id=f.carries_over;")
  [ "$rows" = 3 ] || { echo "  rows=$rows, wanted 3"; exit 1; }
  [ "$link" = 1 ] || { echo "  resolving link(s)=$link, wanted 1"; exit 1; }
  [ "$((rows - link))" = 2 ] || { echo "  distinct defects=$((rows-link)), wanted 2"; exit 1; }

  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q '3 finding row(s)\*\* over \*\*2 distinct defect(s)' STATUS.generated.md ||
    { echo "  kit-status does not report rows and defects as different numbers"; exit 1; }

  # A LINK POINTING AT NOTHING IS NOT A CARRIED-OVER DEFECT. Both reviewers noted the dangling
  # branch was never exercised, and a branch no test reaches is a branch that can rot silently.
  # It must NOT lower the distinct count, and it must be named.
  printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"race","severity":"minor","lang":"bash","summary":"names an id that does not exist","carries_over":"2020-01-01T00:00:00Z:dead"}]}' > r3.json
  bash "$KIT/tooling/kit-finding.sh" --task T-c --agent implementation-reviewer --json < r3.json >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q '4 finding row(s)\*\* over \*\*3 distinct defect(s)' STATUS.generated.md ||
    { echo "  a dangling link changed the distinct count; it must not"; exit 1; }
  grep -q 'name an earlier finding that does not exist' STATUS.generated.md ||
    { echo "  the dangling link was not reported"; exit 1; }

  # AND THE PRE-COLUMN INDEX MUST SAY SO rather than print a confident blank. Both reviewers
  # reproduced this independently: the two queries return empty and the line read
  # "N row(s) over N distinct defect(s) --  carried over" with nothing where the count belongs.
  sqlite3 .project/index.db "ALTER TABLE finding DROP COLUMN carries_over;" >/dev/null 2>&1
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'predates carry-over links' STATUS.generated.md ||
    { echo "  an index without the column printed a count instead of saying it cannot"; exit 1; }
  exit 0 )
check $? "3 rows, 2 defects, 1 resolving link, and a report that says which is which"
rm -rf "$co"
fi


if step "the registered hook records, and silence in an unadopted repo stays correct" spend; then
# AC6 of T-20260821-the-kit-does-not-measure-its-own-develop. Asserting that
# .claude/settings.json EXISTS is a source-text assertion and is vacuous -- the criterion
# says to assert the behaviour, so this runs the recorder the way the registration runs it.
#
# The defect it guards is not hypothetical. Capture stopped on 2026-09-10 and nothing
# noticed for four days and 122 commits, because kit-spend.sh resolves its root with
# `git rev-parse --show-toplevel` from the SESSION's directory and exits 0 where no
# .claude/project-profile.md is found. Inertness in a repository that has not adopted the
# kit is CORRECT behaviour -- and it is precisely what hid the outage.
#
# Three assertions, and the second and third are the ones with teeth:
#   1. .claude/settings.json still registers kit-spend.sh on SubagentStop. If the
#      registration is ever dropped or renamed, this goes red instead of going quiet.
#   2. invoked as the hook invokes it, in an ADOPTED repo, it writes a scope=subagent row.
#   3. invoked identically in a repo that has NOT adopted the kit, it writes nothing and
#      exits 0. A recorder that started writing there would be the opposite defect, and
#      that arm is what distinguishes "the hook is wired" from "the hook writes anywhere".
hk="$WORK.hookreg"; rm -rf "$hk"; mkdir -p "$hk/adopted/sess/subagents" "$hk/bare"

# Read the REAL registration out of the committed settings file, not a copy of it.
reg=$(python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    print("unreadable"); sys.exit()
for entry in d.get("hooks", {}).get("SubagentStop", []):
    for h in entry.get("hooks", []):
        if "kit-spend.sh" in h.get("command", ""):
            print("registered"); sys.exit()
print("absent")
' "$KIT/.claude/settings.json")

sub=""; bareev="none"
( cd "$hk/adopted" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf '{"type":"assistant","message":{"model":"m-main","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":9}}}\n' > sess.jsonl
  printf '{"type":"assistant","message":{"model":"m-sub","usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":7}}}\n' > sess/subagents/agent-Z9.jsonl
  printf '{"session_id":"S1","transcript_path":"%s/sess.jsonl","agent_id":"Z9","agent_type":"general-purpose"}' "$PWD" |
    bash "$KIT/tooling/kit-spend.sh" ) >/dev/null 2>&1
sub=$(grep -c '"scope":"subagent"' "$hk/adopted/.project/events.ndjson" 2>/dev/null | tr -d ' \015')
[ -n "$sub" ] || sub=0

# Arm 3. A git repo with no profile: the same invocation must stay silent AND exit 0.
( cd "$hk/bare" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  mkdir -p sess/subagents
  printf '{"type":"assistant","message":{"model":"m-main","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":9}}}\n' > sess.jsonl
  printf '{"type":"assistant","message":{"model":"m-sub","usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":7}}}\n' > sess/subagents/agent-Z9.jsonl
  printf '{"session_id":"S2","transcript_path":"%s/sess.jsonl","agent_id":"Z9","agent_type":"general-purpose"}' "$PWD" |
    bash "$KIT/tooling/kit-spend.sh" ) >/dev/null 2>&1
barerc=$?
[ -e "$hk/bare/.project/events.ndjson" ] && bareev="written"

{ [ "$reg" = "registered" ] || { echo "  .claude/settings.json does not register kit-spend.sh on SubagentStop (read: $reg)"; false; } } &&
{ [ "$sub" = 1 ] || { echo "  adopted repo recorded $sub subagent row(s), wanted 1"; false; } } &&
{ [ "$bareev" = "none" ] || { echo "  an unadopted repo had events written to it"; false; } } &&
{ [ "$barerc" = 0 ] || { echo "  the recorder exited $barerc in an unadopted repo, wanted 0"; false; } }
check $? "registration records in an adopted repo and stays silent, exit 0, in one that is not"
rm -rf "$hk"
fi


if step "a refutation can name one finding of several sharing a class"; then
# The defect: kit-vindicate.sh keyed only on (task, class), and 604 of 635 findings in this
# repository share such a pair with at least one other. So the one verb that makes the right
# claim about a reviewer's false positive -- it was never a defect -- could not be aimed at the
# row that needed it, and the criticals gate defended itself by refusing every class refutation
# that was not the sole finding of its class. Correct, and it left 95% of the table unmarkable.
#
# The fixture is two CRITICAL findings sharing (T-v, fail-open), which is exactly the shape the
# gate refuses. One is named by id. The assertions are that the OTHER one does not move and that
# the gate drops to one -- a step that only counted the gate would pass while refuting both.
#
# MUTATION: widen the row mark back to (task, class) in kit-index.sh and this goes red twice
# over -- the second finding becomes refuted too, and the gate then refuses BOTH because the
# pair is ambiguous, so the count goes to 2 rather than to 0.
vd="$WORK.vindrow"; rm -rf "$vd"; mkdir -p "$vd/src"
( cd "$vd" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-v\ntitle: v\ntier: T2\n---\nb\n' > .project/tasks/T-v.md
  git add -A && git commit -q --no-verify -m "chore: seed"
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  printf '%s' '{"findings":[{"class":"fail-open","severity":"critical","lang":"bash","summary":"the one that was never a defect"},{"class":"fail-open","severity":"critical","lang":"bash","summary":"the one that is real and must survive"}]}' \
    | bash "$KIT/tooling/kit-finding.sh" --task T-v --agent security-reviewer --json >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  n=$(Q "SELECT COUNT(*) FROM finding WHERE task_id='T-v' AND severity='critical';")
  [ "$n" = 2 ] || { echo "  fixture recorded $n critical(s), wanted 2"; exit 1; }

  # ASK THE REAL GATE, do not restate its query. kit-preflight.sh --criticals is the ONE home
  # for this predicate -- its own header says so, after the rule was wrong twice while living in
  # two places. A third copy inlined here would pass while the gate itself was broken, which is
  # the failure this step exists to catch.
  gatecount() {
    out=$(bash "$KIT/tooling/kit-preflight.sh" --criticals 2>&1)
    case "$out" in
      *"no unfixed critical"*) printf '0' ;;
      *"unfixed critical(s) outstanding"*)
        printf '%s' "$out" | tr ' ' '
' | grep -E '^[0-9]+$' | head -1 ;;
      *) printf 'ERR' ;;
    esac
  }
  g0=$(gatecount)
  [ "$g0" = 2 ] || { echo "  the gate held $g0 critical(s) before any mark, wanted 2"; exit 1; }

  # A reason is REQUIRED on a row mark: it retires a finding with no sole-of-its-class test
  # standing behind it, and the kit's rule for a mark that clears a gate is that it says why.
  fid=$(Q "SELECT id FROM finding WHERE task_id='T-v' AND summary LIKE '%never a defect%';")
  [ -n "$fid" ] || { echo "  could not resolve the finding id"; exit 1; }
  bash "$KIT/tooling/kit-vindicate.sh" --finding "$fid" --false >/dev/null 2>&1
  rc=$?
  [ "$rc" = 2 ] || { echo "  --finding without --note exited $rc, wanted 2"; exit 1; }

  bash "$KIT/tooling/kit-vindicate.sh" --finding "$fid" --false \
    --note "a probe row; the reviewer was wrong" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  marked=$(Q "SELECT COALESCE(vindicated,-1)||'/'||COALESCE(vindicated_scope,'-') FROM finding WHERE id='$fid';")
  [ "$marked" = "0/finding" ] || { echo "  the named row reads $marked, wanted 0/finding"; exit 1; }

  # THE ASSERTION THAT MAKES THIS MORE THAN A COUNT: the neighbour sharing the pair is untouched.
  other=$(Q "SELECT COALESCE(vindicated,-1) FROM finding
              WHERE task_id='T-v' AND summary LIKE '%is real%';")
  [ "$other" = "-1" ] || { echo "  the neighbour sharing (task,class) reads $other, wanted unjudged"; exit 1; }

  g1=$(gatecount)
  [ "$g1" = 1 ] || { echo "  the gate holds $g1 critical(s) after one row mark, wanted 1"; exit 1; }

  # The class door is KEPT, and still refuses to retire either of an ambiguous pair.
  bash "$KIT/tooling/kit-vindicate.sh" --task T-v --class correctness --real >/dev/null 2>&1 || {
    echo "  the (task, class) door was broken by the row door"; exit 1; }

  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q 'never having been a defect' STATUS.generated.md || {
    echo "  kit-status does not count refutations apart"; exit 1; }
  exit 0 )
check $? "one row is refuted by id, its neighbour is untouched, and the gate drops by one"
rm -rf "$vd"
fi


if step "a carried-over critical fixed once leaves the gate, and the file agrees with itself"; then
# The defect: `finding.carries_over` existed and ONE summary line read it. Every consumer that
# ACTED on a count still counted rows -- so a critical carried into a second review round was two
# rows, marking it addressed cleared one, and the criticals gate stayed open for work that was
# done. The same generated file then said "2 row(s) over 1 distinct defect(s)" in its header
# while its gate counted 2. One file, two counts of the same findings, disagreeing.
#
# THE GATE IS ASKED, NOT RESTATED. kit-preflight.sh --criticals is the one home for the
# predicate; an inlined copy here would pass while the gate itself was broken.
#
# TWO MUTATIONS, each alone:
#   kit-index.sh stops deriving defect_id      -> the fixed mark clears one row, gate reads 1
#   the gate goes back to f.fixed_at IS NULL   -> same, and the header still says 1 defect
gd="$WORK.gatedefect"; rm -rf "$gd"; mkdir -p "$gd/src"
( cd "$gd" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-g\ntitle: g\ntier: T2\n---\nb\n' > .project/tasks/T-g.md
  echo x > src/a; git add -A && git commit -q --no-verify -m seed
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }
  gatecount() {
    out=$(bash "$KIT/tooling/kit-preflight.sh" --criticals 2>&1)
    case "$out" in
      *"no unfixed critical"*) printf '0' ;;
      *"unfixed critical(s) outstanding"*)
        printf '%s' "$out" | tr ' ' '\n' | grep -E '^[0-9]+$' | head -1 ;;
      *) printf 'ERR' ;;
    esac
  }

  bash "$KIT/tooling/kit-finding.sh" --task T-g --agent implementation-reviewer \
    --class race --severity critical --lang bash --summary "round one, and it is critical" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  r1=$(Q "SELECT id FROM finding LIMIT 1;")
  [ -n "$r1" ] || { echo "  round 1 recorded no row"; exit 1; }

  # Round 2 carries it over, and varies the class -- the real data did, and a fixture whose two
  # rounds agreed on class would pass against a (task, class) collapse that fails in the field.
  printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"perf","severity":"critical","lang":"bash","summary":"the same defect, second round","carries_over":"%s"}]}' "$r1" > r2.json
  bash "$KIT/tooling/kit-finding.sh" --task T-g --agent implementation-reviewer --json < r2.json >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  rows=$(Q "SELECT COUNT(*) FROM finding;")
  defs=$(Q "SELECT COUNT(DISTINCT defect_id) FROM finding;")
  [ "$rows" = 2 ] || { echo "  rows=$rows, wanted 2"; exit 1; }
  [ "$defs" = 1 ] || { echo "  distinct defects=$defs, wanted 1 -- defect_id is not derived"; exit 1; }

  # ONE defect outstanding, not two rows. This arm fails if the gate counts rows.
  g0=$(gatecount)
  [ "$g0" = 1 ] || { echo "  the gate reads $g0 before any fix, wanted 1 (one defect, two rounds)"; exit 1; }

  # Address it ONCE, naming the second round's row.
  r2=$(Q "SELECT id FROM finding WHERE COALESCE(carries_over,'') <> '';")
  [ -n "$r2" ] || { echo "  the carried-over row is not linked"; exit 1; }
  sha=$(git rev-parse HEAD)
  bash "$KIT/tooling/kit-resolve.sh" --finding "$r2" --fixed --commit "$sha" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  # THE CRITERION, EXACTLY: one mark on one round clears the defect.
  g1=$(gatecount)
  [ "$g1" = 0 ] || { echo "  the gate reads $g1 after the defect was addressed once, wanted 0"; exit 1; }

  # AND THE FILE MUST AGREE WITH ITSELF. The header counting defects while the gate counted rows
  # is the self-contradiction that made this findable.
  bash "$KIT/tooling/kit-status.sh" >/dev/null 2>&1
  grep -q '2 finding row(s)\*\* over \*\*1 distinct defect(s)' STATUS.generated.md ||
    { echo "  kit-status does not say 2 rows over 1 defect"; exit 1; }
  # AND THE SENTENCE MUST BE TRUE OF THE ROWS, not only of the defect. One mark on one round
  # leaves the other row unmarked, so "all marked addressed" would assert a disposition nobody
  # recorded -- the same false claim this section already had to remove once for unassessable.
  grep -q 'none outstanding (2 critical finding row(s) over 1 defect(s)' STATUS.generated.md ||
    { echo "  kit-status does not say 2 critical rows over 1 addressed defect"; exit 1; }
  grep -q 'all marked addressed' STATUS.generated.md &&
    { echo "  kit-status claims every ROW was marked when only one was"; exit 1; }
  exit 0 )
check $? "one defect over two rounds, addressed once, leaves the gate and the header agrees"
rm -rf "$gd"
fi


if step "one defect seen twice does not earn an accelerator rule"; then
# kit-accel.sh earned a rule on `HAVING COUNT(*) >= $MIN`, counting finding ROWS. A defect
# carried into a second review round is two rows, so with --min 2 ONE defect in ONE project
# could earn a rule and be proposed into shared config that every future project loads. That is
# the laundering the file's own header says it exists to prevent, arriving through the counter
# instead of through a refuted finding.
#
# The fixture holds both cases so the step cannot pass by proposing nothing at all:
#   (bash, race)      one defect, two rounds   -- must NOT earn
#   (bash, fail-open) two separate defects     -- MUST earn, at the same threshold
#
# MUTATION: put COUNT(*) back in the HAVING clause and the first pair earns, which the step
# names. Without the second pair, deleting the whole query would also pass.
ac="$WORK.acceldefect"; rm -rf "$ac"; mkdir -p "$ac/src"
( cd "$ac" || exit 1
  git init -q -b main 2>/dev/null
  git config user.email a@b.c; git config user.name T
  bash "$KIT/tooling/kit-init.sh" >/dev/null 2>&1
  printf -- '---\nid: T-h\ntitle: h\ntier: T2\n---\nb\n' > .project/tasks/T-h.md
  git add -A && git commit -q --no-verify -m seed
  Q() { sqlite3 .project/index.db "$1" | tr -d '\015'; }

  bash "$KIT/tooling/kit-finding.sh" --task T-h --agent implementation-reviewer \
    --class race --severity major --lang bash --summary "the repeated one, round one" >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1
  r1=$(Q "SELECT id FROM finding WHERE class='race';")
  [ -n "$r1" ] || { echo "  round 1 recorded no row"; exit 1; }

  printf '{"verdict":"REVISE","narrative":"n","findings":[{"class":"race","severity":"major","lang":"bash","summary":"the repeated one, round two","carries_over":"%s"},{"class":"fail-open","severity":"major","lang":"bash","summary":"a distinct defect"},{"class":"fail-open","severity":"major","lang":"bash","summary":"another distinct defect"}]}' "$r1" > r2.json
  bash "$KIT/tooling/kit-finding.sh" --task T-h --agent implementation-reviewer --json < r2.json >/dev/null 2>&1
  bash "$KIT/tooling/kit-index.sh" >/dev/null 2>&1

  # Rows agree with the old counter; defects do not. If these two ever match, the fixture has
  # stopped exercising the difference and every assertion below is vacuous.
  rr=$(Q "SELECT COUNT(*) FROM finding WHERE class='race';")
  rd=$(Q "SELECT COUNT(DISTINCT defect_id) FROM finding WHERE class='race';")
  [ "$rr" = 2 ] && [ "$rd" = 1 ] || {
    echo "  fixture is not exercising the difference: race rows=$rr defects=$rd, wanted 2 and 1"; exit 1; }

  bash "$KIT/tooling/kit-accel.sh" propose --min 2 --out prop.md >/dev/null 2>&1
  [ -f prop.md ] || { echo "  no proposal was written"; exit 1; }

  # SCOPE THE MATCH TO EARNED LINES. The proposal also prints a below-threshold section, and
  # `race` appears there correctly -- a bare grep matched that and read as a pass for the wrong
  # reason. Assign first, then match: the suite runs under pipefail.
  earned=$(grep -F '[earned]' prop.md)
  case "$earned" in *race*)
    echo "  one defect seen twice earned a rule"; exit 1 ;; esac
  case "$earned" in *fail-open*) : ;; *)
    echo "  two distinct defects did NOT earn, so the threshold is not being met at all"; exit 1 ;; esac
  exit 0 )
check $? "rounds of one defect count once, and two real defects still earn at the same threshold"
rm -rf "$ac"
fi

if [ -n "$ONLY" ]; then
  # Deliberately not the same sentence as a full run. `35 passed, 0 failed` over a
  # filtered run would be a worse defect than the slowness the filter cures, so the
  # word PARTIAL, the pattern, and the number of steps that did not run all appear
  # before the counts anyone reads.
  printf '\n=== PARTIAL RUN --only %s\n' "$ONLY"
  printf '=== %d passed, %d failed' "$ok" "$bad"
  [ "$skipped" -gt 0 ] && printf ', %d NOT EXERCISED on this platform' "$skipped"
  printf ' over %d of %d steps; %d did not run\n' "$ran" "$STEP_COUNT" "$filtered"
  printf '=== NOT a conformance pass. Only the full run is, and only CI runs it on every platform.\n'
else
  printf '\n=== %d passed, %d failed' "$ok" "$bad"
  [ "$skipped" -gt 0 ] && printf ', %d NOT EXERCISED on this platform' "$skipped"
  printf '\n'
fi
exit $bad

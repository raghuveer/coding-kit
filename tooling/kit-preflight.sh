#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
# kit-preflight.sh --isolated <copy>     the subject copy has no path back to the subject
# kit-preflight.sh --spend               spend capture is live in THIS repository
# kit-preflight.sh --criticals           no unfixed critical is outstanding in THIS repository
# kit-preflight.sh --unassessable        the standing blind spot --criticals deliberately excludes
# kit-preflight.sh --superseded          the OTHER thing it excludes: findings whose subject died
# kit-preflight.sh --commands            every declared commands.* actually RUNS, before the clock
#
# The checks docs/TRIAL-PROTOCOL.md §0 gates on, as commands rather than as prose. A pre-flight
# box that a human evaluates by reading is a box that gets ticked while tired; two of this
# document's own boxes were wrong for a year in ways nobody noticed until someone ran them.
#
# Exit 0 = the property holds. Exit 1 = it does not, and the reason is printed. Exit 2 = the
# question could not be asked (bad usage, missing path) -- which is NOT a pass, and is why the
# caller must check the status rather than the output.
set -uo pipefail

usage() { printf 'usage: kit-preflight.sh --isolated <copy> | --spend | --criticals | --unassessable | --superseded\n' >&2; exit 2; }

case "${1:-}" in
  --isolated)
    COPY=${2:-}
    [ -n "$COPY" ] || usage
    # Every failure here is loud. A trial that begins against a subject with a live remote is
    # the one outcome the operator explicitly forbade, and `git push` is a Bash call that
    # kit-guard.sh does not match -- so this check is the only thing standing between an agent
    # and the subject's branches.
    if [ ! -d "$COPY" ]; then
      printf 'kit: %s is not a directory -- the question cannot be asked, so this is not a pass\n' "$COPY" >&2
      exit 2
    fi
    if ! git -C "$COPY" rev-parse --git-dir >/dev/null 2>&1; then
      printf 'kit: %s is not a git repository\n' "$COPY" >&2
      printf '  A trial subject must be one: the protocol records a baseline SHA and reads history.\n' >&2
      exit 1
    fi
    fail=0
    remotes=$(git -C "$COPY" remote 2>/dev/null)
    if [ -n "$remotes" ]; then
      printf 'kit: STOP -- the copy still has a remote:\n' >&2
      git -C "$COPY" remote -v 2>/dev/null | sed 's/^/  /' >&2
      printf '  `git push` is a Bash call and the guard hook does not match Bash, so nothing\n' >&2
      printf '  else prevents a push to the subject. Remove it: git -C %s remote remove <name>\n' "$COPY" >&2
      fail=1
    fi
    # A `--shared` or `--reference` clone BORROWS the subject's object store through
    # `alternates` -- a path back that `git remote -v` does not show, and one that lets `git gc`
    # in either repository affect the other.
    #
    # WHAT THIS DOES NOT DETECT: a plain local `git clone` without `--no-hardlinks`. That
    # hardlinks object files rather than writing an alternates entry, so nothing here can see
    # it. Git objects are immutable, so a hardlinked clone cannot corrupt the subject by
    # writing -- but pruning can, which is why the protocol still says `--no-hardlinks`. Said
    # out loud because a check that silently covers less than its heading claims is the defect
    # this file is full of fixes for.
    gd=$(git -C "$COPY" rev-parse --git-dir 2>/dev/null)
    case "$gd" in /*) alt="$gd/objects/info/alternates" ;; *) alt="$COPY/$gd/objects/info/alternates" ;; esac
    if [ -s "$alt" ]; then
      printf 'kit: STOP -- the copy shares an object store with another repository:\n' >&2
      sed 's/^/  /' "$alt" >&2
      printf '  Re-clone with --no-hardlinks. An alternates entry is a path back that\n' >&2
      printf '  `git remote -v` does not show.\n' >&2
      fail=1
    fi
    [ "$fail" = 0 ] || exit 1
    # A THIRD PATH BACK, AND THE COPY CARRIES IT IN A TRACKED FILE. The two checks above ask
    # about git: a remote, and an alternates entry. Neither sees the copy's own Claude Code
    # permissions, and a clone brings them along when the subject tracks them.
    #
    # Reproduced 2026-09-11 on the copy prepared for the highper-gateway trial. Its
    # `.claude/settings.local.json` pre-approved 24 commands including `Bash(git *)`, and SEVEN
    # entries naming a second checkout of the same subject OUTSIDE the copy, with uncommitted
    # changes. User-level settings pre-approve nothing, so that file would have been the trial
    # session's only pre-approval -- and `--isolated` printed "isolated" and exited 0.
    #
    # `git -C <the other checkout> reset --hard` would then run with NO PROMPT, against the
    # repository the copy exists to protect. TRIAL-PROTOCOL.md section 4 rests on "the removed
    # remote is what makes the procedure hold when the guard cannot"; a pre-approved `git *`
    # routes around the removed remote entirely, because it never needs the copy's remote.
    #
    # FAILS, NEVER WARNS. A warning printed beside the word "isolated" reads as a pass, and this
    # check's whole job is to stand between an agent and the subject.
    #
    # Pre-approving git in its OWN repository is the subject's business and is not judged here.
    # Printing "isolated" about a copy is the kit's claim, and the claim is what must be true.
    perm=0
    for _sf in "$COPY/.claude/settings.json" "$COPY/.claude/settings.local.json"; do
      [ -f "$_sf" ] || continue
      # Unscoped reach: a rule whose argument is a bare wildcard can name any path, so the copy
      # boundary means nothing to it. Matched on the RULE SHAPE rather than on a list of command
      # names -- `Bash(*)` reaches further than `Bash(git *)` and a name list would miss it.
      _wide=$(grep -oE '"(Bash|Read|Write|Edit)\([^")]*\*\)"' "$_sf" 2>/dev/null | sort -u)
      # And any rule naming an absolute path that is not inside the copy. Windows and POSIX
      # spellings both, because the copy may be prepared on either.
      _abs=$(grep -oE '"[^"]*(/[a-z]/|[A-Za-z]:\\|/home/|/Users/|/mnt/)[^"]*"' "$_sf" 2>/dev/null |
             grep -vF "$COPY" | sort -u)
      if [ -n "$_wide" ] || [ -n "$_abs" ]; then
        [ "$perm" = 0 ] && printf 'kit: STOP -- the copy carries permissions that reach outside it:\n' >&2
        perm=1
        printf '  %s\n' "${_sf#$COPY/}" >&2
        [ -z "$_wide" ] || printf '%s\n' "$_wide" | sed 's/^/    unscoped: /' >&2
        [ -z "$_abs" ]  || printf '%s\n' "$_abs"  | sed 's/^/    outside:  /' >&2
      fi
    done
    if [ "$perm" != 0 ]; then
      printf '  A pre-approved rule is not a sandbox and not a remote: it lets a command run\n' >&2
      printf '  with no prompt, so the removed remote protects nothing against it. Remove the\n' >&2
      printf '  rules, or scope them inside the copy, before the trial starts.\n' >&2
      exit 1
    fi
    # The line names what was CHECKED, so "isolated" is never printed about a property this
    # check did not test. It still cannot see a human approving a prompt, and says so.
    printf 'kit: %s is isolated -- no remote, no shared object store, no permission rule\n' "$COPY"
    printf '  reaching outside it. A prompted command can still be approved by hand; that is\n'
    printf '  not something a check can see.\n'
    exit 0 ;;

  --unassessable)
    # THE THIRD STATE. `--criticals` excludes `unassessable_at IS NOT NULL` on purpose — those
    # findings cannot be judged from what survives, so leaving them in would make the gate
    # permanently unsatisfiable and no trial could ever run. The cost of that exclusion is that
    # a repository whose every remaining critical is unassessable reports **zero** and the §0
    # box passes, silently, with the blind spot intact. That is the shape TRIAL-PROTOCOL §0 now
    # names, and this is the command it calls.
    #
    # Exit 0 either way, deliberately: a standing blind spot is not a stop, it is something the
    # report must carry. Returning non-zero would make it a gate, and a gate nobody can ever
    # satisfy is the failure the unassessable route was built to remove. The stop conditions are
    # judgement and live in the protocol, not here — this command supplies the NUMBER they are
    # judged against, which is the part a human should not be counting by hand.
    . "$(dirname "$0")/kit-lib.sh"
    ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
    kit_active "$ROOT" || { kit_warn "the kit is not adopted here"; exit 2; }
    STATE_DIR=$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")
    DB="$ROOT/$STATE_DIR/index.db"
    [ -f "$DB" ] || { kit_warn "no index at ${DB#$ROOT/}; run kit-index.sh"; exit 2; }
    n=$(sqlite3 -noheader "$DB" "SELECT COUNT(*) FROM finding
                                  WHERE severity='critical' AND fixed_at IS NULL
                                    AND unassessable_at IS NOT NULL;" 2>&1)
    case "$n" in
      ''|*[!0-9]*)
        kit_warn "the unassessable query FAILED -- this is not a report of zero"
        printf '%s\n' "$n" | sed 's/^/  /' >&2
        kit_warn "  the usual cause is an index older than a column this query reads; rebuild it"
        exit 2 ;;
    esac
    if [ "$n" = 0 ]; then
      printf 'no unassessable critical: --criticals is the whole picture\n'
      exit 0
    fi
    printf '%s unassessable critical(s) — EXCLUDED from --criticals, and still true:\n' "$n"
    sqlite3 -noheader -separator '  ' "$DB" \
      "SELECT id, COALESCE(task_id,'(no task)'), COALESCE(unassessable_reason,'(no reason recorded)')
         FROM finding WHERE severity='critical' AND fixed_at IS NULL
          AND unassessable_at IS NOT NULL ORDER BY task_id, id;" 2>/dev/null |
      tr -d '\r' | sed 's/^/  /'
    printf 'Record this number in the trial report. TRIAL-PROTOCOL section 0 says when it stops you.\n'
    exit 0 ;;

  --superseded)
    # THE FOURTH STATE, and it needs its own box for the same reason the third does: `--criticals`
    # excludes it, so a repository whose every remaining critical was superseded reports ZERO and
    # passes §0 with nothing said. Adding an exclusion to the gate without adding the report that
    # exposes it is how a gate quietly stops meaning what its reader thinks it means -- and this
    # repository was in exactly that state the moment the fourth verb landed: the gate went to
    # zero with thirteen criticals excluded behind it.
    #
    # It is NOT the same blind spot as --unassessable, and merging the two counts would lose the
    # distinction that matters. An unassessable critical is unreadable: nobody can say what it
    # was. A superseded one is perfectly readable, was REAL, and its subject was withdrawn --
    # frequently BECAUSE of it. One is missing evidence; the other is evidence that worked.
    #
    # Exit 0 either way, for the reason --unassessable does: this supplies the number, the
    # protocol supplies the judgement.
    . "$(dirname "$0")/kit-lib.sh"
    ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
    kit_active "$ROOT" || { kit_warn "the kit is not adopted here"; exit 2; }
    STATE_DIR=$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")
    DB="$ROOT/$STATE_DIR/index.db"
    [ -f "$DB" ] || { kit_warn "no index at ${DB#$ROOT/}; run kit-index.sh"; exit 2; }
    n=$(sqlite3 -noheader "$DB" "SELECT COUNT(*) FROM finding
                                  WHERE severity='critical' AND fixed_at IS NULL
                                    AND unassessable_at IS NULL
                                    AND superseded_at IS NOT NULL;" 2>&1)
    case "$n" in
      ''|*[!0-9]*)
        kit_warn "the superseded query FAILED -- this is not a report of zero"
        printf '%s\n' "$n" | sed 's/^/  /' >&2
        kit_warn "  the usual cause is an index older than a column this query reads; rebuild it"
        exit 2 ;;
    esac
    if [ "$n" = 0 ]; then
      printf 'no superseded critical: --criticals is not hiding a withdrawn subject\n'
      exit 0
    fi
    printf '%s superseded critical(s) — EXCLUDED from --criticals, and each one was REAL:\n' "$n"
    sqlite3 -noheader -separator '  ' "$DB" \
      "SELECT id, COALESCE(task_id,'(no task)'), COALESCE(file_path,'(no subject)'),
              'superseded by '||COALESCE(superseded_by,'(not recorded)')
         FROM finding WHERE severity='critical' AND fixed_at IS NULL
          AND unassessable_at IS NULL
          AND superseded_at IS NOT NULL ORDER BY task_id, id;" 2>/dev/null |
      tr -d '\r' | sed 's/^/  /'
    printf 'Record this number in the trial report. These are not repairs; they are subjects that died.\n'
    exit 0 ;;

  --criticals)
    . "$(dirname "$0")/kit-lib.sh"
    ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
    kit_active "$ROOT" || { kit_warn "the kit is not adopted here"; exit 2; }
    STATE_DIR=$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")
    DB="$ROOT/$STATE_DIR/index.db"
    # REFRESH BEFORE QUERYING. This opened the database and queried it, and `index.db` is
    # gitignored -- so the gate's answer was a function of WHEN SOMEONE LAST RAN THE INDEXER,
    # not of the repository. `kit-status.sh` rebuilds only when the file is absent, so a stale
    # index produced a confident number from an unknown point in history. `--spend` already
    # rebuilds first and says why; the same reasoning was never carried one box up.
    #
    # `--if-stale` rather than an unconditional rebuild, because a full build costs ~39s here
    # and this runs at every pre-flight. That is only safe now: until the staleness check
    # compared resolved commits it answered FRESH across a commit, so `--if-stale` here would
    # have inherited exactly the defect this is closing. The two changes are one fix.
    #
    # A build that FAILS refuses rather than falling through to the old file. Reporting a
    # number silently is the one option the acceptance criteria reject, and a gate that
    # answers from a database it could not refresh is that option wearing a rebuild.
    bash "$(dirname "$0")/kit-index.sh" --if-stale >/dev/null 2>&1 || {
      kit_warn "the index could not be refreshed, so the criticals gate cannot be trusted"
      kit_warn "  run kit-index.sh and read its error; this refuses rather than reporting a"
      kit_warn "  count derived from an unknown point in history."
      exit 2; }
    [ -f "$DB" ] || { kit_warn "no index at ${DB#$ROOT/}; run kit-index.sh"; exit 2; }
    # ONE HOME FOR THIS PREDICATE. It used to be inlined in docs/TRIAL-PROTOCOL.md §0 and again
    # in kit-status.sh, which is two copies of a rule that has already been wrong twice -- once
    # filtering by task state, once excluding refutations too eagerly. The document calls this.
    #
    # A refuted critical is excluded ONLY IF the refutation is unambiguous, and there are two
    # ways to be. `kit-vindicate.sh --class` marks every finding matching (task, class), so on a
    # task with two `fail-open` findings a single `--false` about the harmless one also refutes
    # the critical -- and the critical would leave the gate having never been judged. Fail
    # closed: a class-scoped refutation retires a finding only when it is the sole finding of
    # that class on that task.
    #
    # `--finding` names one row and is unambiguous by construction, so it is honoured without
    # that test. Applying the test to it would refuse the precise mark while accepting the
    # imprecise one. A scope missing from the row is read as 'class', because every vindication
    # written before the column existed was one.
    # A finding the operator has explicitly marked unassessable leaves the gate, and ONLY one
    # marked individually does. The exclusion is deliberately not `summary IS NULL` -- that
    # would exempt every FUTURE critical whose summary is missing, turning a bounded historical
    # problem into an unbounded hole. Nine rows predate the summary column and cannot be judged
    # from what survives; each is named by its own `finding-unassessable` event carrying a
    # reason, and kit-status.sh reports the total as a standing blind spot rather than folding
    # it into zero. Excluded from the gate, never from the record.
    # A finding whose SUBJECT was withdrawn leaves the gate on the same terms and for the same
    # reason: it is excluded from the gate and never from the record. It is individually marked,
    # the mark names what withdrew the subject, and kit-resolve.sh refuses it unless the subject
    # file itself carries a matching `Superseded-by:` line -- so this exclusion is reachable only
    # by an operator who wrote the withdrawal into the tree where the next reader will see it.
    # Without the fourth verb, 31 findings reviewing a rejected design sat here permanently and
    # their task could never close no matter how much correct work was done on it.
    # COUNTS DEFECTS, NOT ROWS, and the wording above needed no change because counting rows was
    # what made it untrue: `carries_over` links a repeated finding to the row it repeats, so three
    # rows can be one defect, and "3 unfixed criticals" then named a quantity nobody has.
    #
    # A DEFECT IS ADDRESSED WHEN ANY OF ITS ROUNDS IS. A carried-over critical marked fixed once
    # used to leave its earlier rows unfixed and the gate open for work that was done.
    #
    # COALESCE(defect_id, id) so an index built before the column degrades to exactly the old
    # row-level behaviour rather than to NULL -- where `g.defect_id = f.defect_id` is never true,
    # NOT EXISTS is always true, and the fixed test silently stops applying. That is the failure
    # direction a gate may not take, and it would have looked like more criticals, not fewer.
    n=$(sqlite3 -noheader "$DB" "
      SELECT COUNT(DISTINCT COALESCE(f.defect_id, f.id)) FROM finding f
       WHERE f.severity='critical'
         AND NOT EXISTS (SELECT 1 FROM finding g
                          WHERE COALESCE(g.defect_id, g.id) = COALESCE(f.defect_id, f.id)
                            AND g.fixed_at IS NOT NULL)
         AND f.unassessable_at IS NULL
         AND f.superseded_at IS NULL
         AND NOT (COALESCE(f.vindicated,1) = 0 AND (
               COALESCE(f.vindicated_scope,'class') = 'finding'
               OR 1 = (
               SELECT COUNT(*) FROM finding g
                WHERE COALESCE(g.task_id,'') = COALESCE(f.task_id,'')
                  AND COALESCE(g.class,'')   = COALESCE(f.class,''))));" 2>&1)
    case "$n" in
      ''|*[!0-9]*)
        kit_warn "the criticals query FAILED -- this is not a report of zero"
        printf '%s\n' "$n" | sed 's/^/  /' >&2
        # Name the SHAPE, not one instance of it. This said "an index built before
        # finding.fixed_at existed", which was the only cause when it was written and stopped
        # being so the moment `unassessable_at` was added -- so the message would have sent the
        # reader hunting for the wrong column. Same defect as
        # T-20260809-the-unverified-tier-floor-message-names-; the fix is to describe the class.
        kit_warn "  the usual cause is an index older than a column this query reads"
        kit_warn "  (fixed_at, unassessable_at and superseded_at are each newer than some"
        kit_warn "  indexes); rebuild it"
        exit 2 ;;
    esac
    if [ "$n" != 0 ]; then
      kit_warn "STOP -- $n unfixed critical(s) outstanding"
      kit_warn "  kit-status.sh lists them per task; kit-resolve.sh --list --severity critical"
      kit_warn "  --unfixed names them. Closing a task does not count as fixing its criticals."
      exit 1
    fi
    printf 'kit: no unfixed critical outstanding\n'
    exit 0 ;;

  --spend)
    . "$(dirname "$0")/kit-lib.sh"
    ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
    kit_active "$ROOT" || { kit_warn "the kit is not adopted here"; exit 2; }
    STATE_DIR=$(kit_cfg "$(kit_profile "$ROOT")" paths.state ".project")
    EV="$ROOT/$STATE_DIR/events.ndjson"
    # THE EVENT LOG IS ASKED FIRST, and this ordering is the whole point. Hooks append events;
    # `spend` rows exist only after kit-index.sh derives them. The protocol used to query the
    # index straight after running an agent, which reads whatever the last rebuild contained --
    # so a live recorder failed a check written to detect a dead one. Separating the two
    # questions also separates their causes: no events means the hook never fired, events
    # without rows means the derivation is broken.
    ev=0
    [ -f "$EV" ] && ev=$(grep -c '"kind":"spend"' "$EV" 2>/dev/null)
    ev=${ev:-0}
    bash "$(dirname "$0")/kit-index.sh" >/dev/null 2>&1 || {
      kit_warn "the index could not be rebuilt, so the spend table cannot be trusted"; exit 2; }
    rows=$(sqlite3 -noheader "$ROOT/$STATE_DIR/index.db" "SELECT COUNT(*) FROM spend;" 2>/dev/null)
    rows=${rows:-0}
    if [ "$ev" = 0 ]; then
      kit_warn "STOP -- no spend EVENT has ever been recorded here"
      kit_warn "  The hooks are not firing. They run from SubagentStop and Stop, so a session"
      kit_warn "  started without the plugin loaded records nothing: run the subject under"
      kit_warn "  \`claude --plugin-dir <kit>\`. The entire cost half of a trial would be empty."
      exit 1
    fi
    if [ "$rows" = 0 ]; then
      kit_warn "STOP -- $ev spend event(s) exist but no spend row was derived"
      kit_warn "  The hook fired and the indexer did not pick it up. That is a different fault"
      kit_warn "  from a dead hook and it is in kit-index.sh, not in the harness."
      exit 1
    fi
    # LIVE IS A PRESENT-TENSE CLAIM AND THE CHECK ASKED IT IN THE PAST TENSE. The two arms
    # above fire on "nothing was ever recorded" and "recorded but never derived"; neither
    # notices a recorder that worked for a month and then stopped. It stopped here on
    # 2026-09-10 and this check went on reporting live, exit 0, across four days and 122
    # commits -- green over a dead instrument, sitting on the one series every token figure
    # in the project is computed from.
    #
    # The comparator is COMMITS SINCE THE LAST READING, deliberately not a clock: a wall-time
    # threshold is a number nobody can defend and it fires on a repository that is merely
    # quiet. Work landing with no reading beside it is the actual property.
    #
    # No harness name, no trailer key, nothing model-specific, so an adapter that records
    # spend some other way is measured by this identically.
    last=$(sqlite3 -noheader "$ROOT/$STATE_DIR/index.db" "SELECT MAX(at) FROM spend;" 2>/dev/null | tr -d '\r')
    if [ -n "$last" ]; then
      # AN UNANSWERABLE QUESTION IS NOT A PASS, and as first written this arm broke its own rule.
      # `git log --since=<garbage>` prints nothing and the count came out 0, so a malformed
      # timestamp SILENTLY DISABLED the check -- the same green-over-nothing shape the arm exists
      # to catch, reproduced inside it. `last` comes from the index, which comes from events an
      # adapter or a hand edit may have written, so "it is always well formed" is an assumption
      # rather than a guarantee.
      #
      # Exit 2, matching --isolated: the property could not be evaluated, which is neither a pass
      # nor a failure of the property.
      case "$last" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;;
        *) kit_warn "the last spend reading is not a timestamp this check can compare: '$last'"
           kit_warn "  The comparison cannot be made, so this is NOT a pass. Fix the reading in"
           kit_warn "  $STATE_DIR/events.ndjson, or rebuild the index if only the table is wrong."
           exit 2 ;;
      esac
      # A repository with no commits at all is a real state and a real pass: nothing has landed
      # since the reading because nothing has landed. Asked separately so it is not confused with
      # the next case, where git fails for a reason that leaves the question unanswered.
      if git -C "$ROOT" rev-parse --verify -q HEAD >/dev/null 2>&1; then
        _log=$(git -C "$ROOT" log --since="$last" --format=%H 2>/dev/null); _rc=$?
        if [ "$_rc" != 0 ]; then
          kit_warn "git log failed here, so the comparison could not be made -- NOT a pass"
          exit 2
        fi
        since=$(printf '%s' "$_log" | grep -c '^.')
      else
        since=0
      fi
      if [ "${since:-0}" -gt 0 ]; then
        kit_warn "STOP -- the last spend reading is $last and $since commit(s) have landed since"
        kit_warn "  Capture worked and then stopped, which neither check above can see. The"
        kit_warn "  usual cause is a session whose project root is not this repository:"
        kit_warn "  kit-spend.sh resolves its root from the session's directory and exits 0"
        kit_warn "  in a repo that has not adopted the kit. Every figure derived from spend"
        kit_warn "  is stale by that much."
        exit 1
      fi
    fi
    printf 'kit: spend capture is live -- %s event(s), %s row(s), last reading %s
'       "$ev" "$rows" "${last:-none}"
    exit 0 ;;

  --commands)
    # METHODOLOGY FINDING M5 OF THE 2026-09-09 TRIAL, and the structural half of
    # T-20260912-a-declared-rung-whose-tooling-fails-has-. That trial discovered
    # `commands.typecheck` was unsatisfiable AFTER starting, when the only remedy -- adding
    # protoc to the wrapper -- is a `commands.*` change, which §2 of TRIAL-PROTOCOL.md makes
    # void the trial. It had no non-voiding move left. Asking before the clock starts is the
    # only move that exists.
    #
    # WHAT A RESULT MEANS IS THE LADDER'S, NOT THIS ARM'S: skills/verify-ladder/SKILL.md
    # `## Satisfaction` is the one home, and this arm only asks the question before the clock.
    # It had its own copy of the dispositions once, and the copy and the ladder read a red
    # baseline with opposite outcomes (T-20260923-baseline-and-the-ladder-call-one-fact-ba).
    #
    # THE SEPARATION BELOW is what makes the question askable, and the middle case is the whole
    # reason this is not a one-liner. In this repository `commands.build` reads
    # `# none -- shell and markdown, nothing is compiled`: handed to a shell that is a COMMENT,
    # it runs, it exits 0, and a naive check reports the rung satisfiable when nothing is
    # declared at all. That is the exact conflation the ladder gap is about, reproduced in the
    # control meant to catch it.
    #
    # What the arm DOES with each result -- what each MEANS is the ladder's:
    #
    #   declared, ran, passed        -> reported, no stop
    #   nothing declared (or `#...`) -> reported, no stop
    #   declared, cannot run         -> stop, exit 1
    #   declared, ran, failed        -> stop, exit 1, until each red rung is dispositioned below
    . "$(dirname "$0")/kit-lib.sh"
    ROOT=$(kit_root) || { kit_warn "not a git repository"; exit 2; }
    kit_active "$ROOT" || { kit_warn "the kit is not adopted here"; exit 2; }
    PROFILE=$(kit_profile "$ROOT")
    _bad=0; _ran=0; _none=0; _red=0; _redlist=""
    for _k in build test lint typecheck; do
      _cmd=$(kit_cfg "$PROFILE" "commands.$_k" "")
      case "$_cmd" in
        ''|'#'*) printf 'kit: commands.%-10s NOTHING DECLARED -- unavailable; raise the tier\n' "$_k"
                 _none=$((_none+1)); continue ;;
      esac
      ( cd "$ROOT" && eval "$_cmd" ) >/dev/null 2>&1; _rc=$?
      # RAN AND FAILED IS NOT THE SAME AS COULD NOT RUN, and the first version of this arm said
      # it was. `cargo check` exiting 101 with 91 type errors RAN -- it worked, and it reported
      # the subject's real state. Calling that "DECLARED AND DOES NOT RUN" describes something
      # that did not happen, and it contradicts the baseline box in section 0: "a subject whose
      # tests already fail is a valid trial subject, but only if you knew that first". A gate
      # that stops on a known-red baseline stops on the case the protocol blesses.
      #
      # Found by running this arm against the trial-2 copy, where it would have refused the
      # trial over 91 errors already recorded in that trial's own baseline.
      #
      # 126 and 127 are the shell's own "cannot execute" and "not found": the tooling is absent
      # or unusable, which IS what this box exists to catch, and the one state with no
      # non-voiding remedy mid-trial. Any other non-zero is a tool that ran and found something.
      case "$_rc" in
        0)       printf 'kit: commands.%-10s runs\n' "$_k"; _ran=$((_ran+1)) ;;
        126|127) printf 'kit: commands.%-10s CANNOT RUN (exit %s) -- unsatisfiable\n' "$_k" "$_rc" >&2
                 printf '       %s\n' "$_cmd" >&2
                 _bad=$((_bad+1)) ;;
        *)       printf 'kit: commands.%-10s ran, exit %s -- a baseline fact, not a stop\n' "$_k" "$_rc"
                 _red=$((_red+1)); _redlist="$_redlist $_k:$_rc" ;;
      esac
    done
    if [ "$_bad" -gt 0 ]; then
      kit_warn "STOP -- $_bad declared command(s) CANNOT RUN here"
      kit_warn "  The tooling is absent or unusable. A command that RAN and reported"
      kit_warn "  failures is a baseline fact, not this -- see section 0's baseline box."
      kit_warn "  A rung whose tooling is declared and fails is neither satisfied nor"
      kit_warn "  declarable unavailable. Inside a trial there is no non-voiding remedy:"
      kit_warn "  editing commands.* mid-trial voids it (TRIAL-PROTOCOL.md section 2), so"
      kit_warn "  this has to be answered now rather than discovered later."
      exit 1
    fi
    # A COUNT IS NOT A FINGERPRINT, AND THE FIRST VERSION OF THIS GATE USED A COUNT.
    #
    # Rejected by the second T3 chain on 2026-09-20, by two reviewers independently. The gate
    # compared `KIT_COMMANDS_RED_DISPOSITIONED` against the NUMBER of red commands, so a value
    # given for one set silently blessed a different set of the same size: disposition
    # `test,typecheck` at 2, fix typecheck, let `build` go red instead, and the stale 2 still
    # passed. A single `export` in a shell profile or CI block blessed every same-sized case
    # forever. The comment here previously asserted the opposite and was cited as evidence for
    # it, which made it a false rationale rather than merely a weak check.
    #
    # So the disposition now carries IDENTITY and CLASSIFICATION, not cardinality:
    #
    #   KIT_COMMANDS_RED_DISPOSITIONED="build:101=baseline,test:101=unsatisfiable"
    #
    # The rung names and their exit codes must match exactly what this run observed, in the
    # loop's own fixed order, so a stale value cannot survive a change in WHICH rung is red, in
    # what it exited with, or in how many there are. And each entry carries what the operator
    # decided, because the two branches of this stop are not the same outcome:
    #
    #   =baseline        a known-red subject, which section 0 blesses -- "only if you knew that
    #                    first". Proceed; the ladder judges the rung against this baseline.
    #   =unsatisfiable   the ladder's disposition 3, decided now. The trial is VOID
    #                    rather than answerable, and this exits 2 rather than 0 or 1 so a caller
    #                    can tell the two stops apart.
    #
    # WHETHER CONFIRMING A DISPOSITION MUST RE-RUN EVERY COMMAND: RULED YES, WITH THE COST.
    #
    # `T-20260920-the-disposition-gate-asks-for-a-transcri` asks for this to be answered rather
    # than left implicit, because a reviewer measured the friction and argued it is what pushes an
    # operator to bypass the gate. It must re-run, and the reason is the same one that made the
    # disposition an identity rather than a count: **a disposition is a statement about what THIS
    # run observed.** Accepting a cached red set would bless an observation taken at some other
    # time, which is exactly the staleness that got the count-based version rejected on
    # 2026-09-20. There is no way to know the set is unchanged without looking.
    #
    # BUT THE COST IS NOT WHAT IT WAS REPORTED TO BE, AND THE DIFFERENCE MATTERS. The reviewer
    # wrote that the gate "mandates a second full run", and this comment previously repeated it.
    # Measured: a KNOWN red set is dispositioned in ONE invocation -- set the variable before
    # running and a matching set exits 0 immediately. The second run is needed only when the red
    # set is UNKNOWN or has CHANGED. So the charge is one extra sweep per (subject, red-set), not
    # per trial and not per invocation, and it falls away entirely once a subject is familiar.
    #
    # AND THE EXTRA SWEEP IS THE SUBJECT'S COST, NOT THE KIT'S. On the trial fixture the whole arm
    # runs in ~2.3 s. On the real evaluation subject one rung alone was measured at 1,464 s in
    # container -- that is `cargo check` compiling a dependency tree, and it is what the trial was
    # going to pay at rung 1 regardless. The gate moves that cost EARLIER, to where a remedy is
    # still legal; §2 makes the same edit mid-trial void the trial.
    #
    # THE ANSWER IS PERSISTED, because a disposition that lives only in an environment variable
    # dies with the shell and no later reader can audit it. One event row per run.
    if [ "$_red" -gt 0 ]; then
      _want=""
      for _p in $_redlist; do _want="$_want${_want:+,}$_p"; done
      _got="${KIT_COMMANDS_RED_DISPOSITIONED:-}"
      _gotids=$(printf '%s' "$_got" | tr ',' '\n' | sed 's/=.*$//' | tr '\n' ',' | sed 's/,$//')
      if [ "$_gotids" != "$_want" ]; then
        kit_warn "STOP -- $_red declared command(s) RAN AND REPORTED FAILURES"
        kit_warn "  This script cannot tell a known-red baseline from tooling that could not"
        kit_warn "  run: a missing build dependency and a real compile error both exit 101 --"
        kit_warn "  measured on the 2026-09-09 trial, whose three failures all exited 101."
        kit_warn "  So it does not guess. Disposition each one, by name, before the clock starts:"
        kit_warn ""
        # THE SCAFFOLDING IS PRINTED; THE ANSWER IS NOT. An earlier version printed this line
        # with every rung already set to `=baseline` -- a complete, valid, paste-ready value that
        # classified every failure as answerable. A reviewer pasted it verbatim into the
        # 2026-09-09 scenario on 2026-09-20 and the trial proceeded: the tool handed over its own
        # bypass, pre-formatted, in the message that exists to stop you.
        #
        # The rung names and their exit codes are still printed, because they are tedious to
        # transcribe and getting them wrong is not a judgement, it is a typo -- and an operator
        # who cannot produce the string at all will skip the pre-flight instead, which is worse.
        # What is NOT printed is the part that IS a judgement. `?` is refused by the parser
        # below, so an unedited paste stops exactly as an absent value does.
        kit_warn "    KIT_COMMANDS_RED_DISPOSITIONED=\"$(printf '%s' "$_want" | sed 's/\([^,]*\)/\1=?/g')\""
        kit_warn ""
        kit_warn "  Replace each ? -- there is no default, and an unedited paste is refused."
        kit_warn "  =baseline      a known-red subject. Record the causes in the trial record's"
        kit_warn "                 baseline box; the ladder judges the rung AGAINST it after the"
        kit_warn "                 change (verify-ladder SKILL.md, ## Satisfaction)."
        kit_warn "  =unsatisfiable the rung cannot run. Fix it HERE -- editing commands.* after"
        kit_warn "                 the clock starts voids the trial (TRIAL-PROTOCOL.md section 2)."
        [ -n "$_got" ] && kit_warn "  (the value supplied names \"$_gotids\"; this run observed \"$_want\")"
        exit 1
      fi
      # SPLIT ON COMMA WITH GLOBBING OFF. `for _e in $(... | tr , ' ')` word-split and
      # GLOB-EXPANDED a fully operator-controlled value against the working directory. No
      # fail-open was built from it because the identity check above runs first, but passing
      # operator input through pathname expansion is not something to leave standing.
      _unsat=""; _oldifs=$IFS; IFS=','; set -f
      for _e in $_got; do
        # EXACTLY ONE `=`, CHECKED BY COUNTING. A suffix glob accepted
        # `typecheck:101=unsatisfiable=baseline` as baseline and exited 0 -- an entry that names
        # the blocking classification, silently read as the proceeding one.
        case "$(printf '%s' "$_e" | tr -cd '=' )" in
          '=') ;;
          *) IFS=$_oldifs; set +f
             kit_warn "STOP -- \"$_e\" is not one rung and one disposition"
             kit_warn "  Each entry is exactly rung:exit=baseline or rung:exit=unsatisfiable."
             exit 1 ;;
        esac
        case "${_e##*=}" in
          baseline)      ;;
          unsatisfiable) _unsat="$_unsat ${_e%=*}" ;;
          *) IFS=$_oldifs; set +f
             kit_warn "STOP -- \"$_e\" carries no disposition"
             kit_warn "  Each entry ends =baseline or =unsatisfiable. Nothing else is a decision."
             exit 1 ;;
        esac
      done
      IFS=$_oldifs; set +f
      bash "$(dirname "$0")/kit-event.sh" "" preflight-commands \
        "{\"red\":\"$_want\",\"dispositioned\":\"$_got\"}" >/dev/null 2>&1 || true
      if [ -n "$_unsat" ]; then
        kit_warn "STOP -- rung(s) declared UNSATISFIABLE by the operator:$_unsat"
        kit_warn "  An unsatisfiable rung is not a baseline. It blocks a completion claim, and"
        kit_warn "  inside a trial the outcome is VOID rather than COMPLETE -- see the ladder's"
        kit_warn "  ## Completion. Fix the tooling now; after the clock starts there is no"
        kit_warn "  non-voiding remedy."
        # 3, NOT 2. In this same script 2 already means "not a git repository", "the kit is
        # not adopted here" and bad usage -- the header defines it as "the question could not
        # be asked". A caller seeing 2 could not tell an operator's VOID ruling from a
        # precondition failure, so the previous claim that 2 distinguished them was false.
        exit 3
      fi
    fi
    printf 'kit: %s pass, %s ran and reported failures, %s with nothing declared\n' \
      "$_ran" "$_red" "$_none"
    exit 0 ;;

  *) usage ;;
esac

#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
"""kit_refs.py — every task reference written in prose is declared where a tool reads it.

docs/DEPENDENCIES.md audited the backlog once, by hand, on 2026-09-13: 273 references in
task bodies against 23 declared `blocked_by:` edges. That audit is a snapshot. This is the
invariant it proposed and did not build -- the check that stops the next two hundred tasks
writing dependencies where nothing reads them.

A reference in a body must resolve to ONE of two declarations:

  blocked_by:            frontmatter, the one home for an ordering -- kit-plan.sh reads it
  the dependency map     a relation that is real and is NOT an ordering

Anything else is a dependency the author reasoned about and no tool can see.

Exit 0 = every live reference is declared. Exit 1 = some are not, and they are printed.
Exit 2 = the question could not be asked, which is NOT a pass.
"""
import argparse, os, re, sqlite3, sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Matches the id shape, not a known id. Resolution happens against the task table below, so a
# malformed or aspirational reference is separated from a real one rather than counted as both.
REF = re.compile(r"T-20\d{6}-[a-z0-9-]+")


def frontmatter_and_body(text):
    """The frontmatter block and everything after it. A file without one is all body."""
    if not text.startswith("---"):
        return "", text
    end = text.find("\n---", 3)
    if end == -1:
        return "", text
    return text[3:end], text[end + 4:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tasks", required=True, help="directory of task files (paths.tasks)")
    ap.add_argument("--db", required=True, help="the derived index (paths.state/index.db)")
    ap.add_argument("--map", required=True, help="the dependency map (paths.depmap)")
    a = ap.parse_args()

    for p, what in ((a.tasks, "task directory"), (a.db, "index")):
        if not os.path.exists(p):
            print(f"kit: {what} not found at {p} -- the question cannot be asked, "
                  f"so this is not a pass", file=sys.stderr)
            return 2

    # THE STATE VOCABULARY COMES FROM THE INDEX, never from a constant here. ADR 0008 owns the
    # partitions and `T-20260819-vocabularies-live-in-shell-constants-so-` records what a second
    # copy costs; a check that re-spelled the closed states would be that defect, in the control.
    try:
        c = sqlite3.connect(f"file:{a.db}?mode=ro", uri=True)
        closed = {r[0] for r in c.execute("SELECT state FROM state_class WHERE is_closed=1")}
        alias = dict(c.execute("SELECT written, canonical FROM state_alias"))
        known = dict(c.execute("SELECT id, state FROM task"))
    except sqlite3.Error as e:
        print(f"kit: the index could not be read ({e}) -- not a pass", file=sys.stderr)
        return 2
    if not known:
        print("kit: the index holds no tasks -- run kit-index.sh first; not a pass",
              file=sys.stderr)
        return 2

    def live(tid):
        """Open in the ADR 0008 sense: not closed.

        ON-HOLD IS LIVE HERE, and that is the one place this check is wider than the audit
        that preceded it. ADR 0008: a parked task `keeps its dependency edges and still blocks
        what waits on it`. The 2026-09-13 audit narrowed to `open`/`created` and so never saw
        the eight references at either end of the parked cluster. A relation that survives
        parking is exactly the relation a reader needs when the task is unparked.
        """
        s = known.get(tid)
        return s is not None and alias.get(s, s) not in closed

    # The map is AUTHORED, so it is read as text and never derived. A row is (src, dst); the
    # relation itself is not this check's business -- recording that two tasks are `related`
    # is a decision, and the point is that a decision was made and written down.
    declared = set()
    if os.path.exists(a.map):
        with open(a.map, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("#") or not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) >= 2 and parts[0] != "src":
                    declared.add((parts[0].strip(), parts[1].strip()))

    violations, checked, unresolvable = [], 0, set()
    for fn in sorted(os.listdir(a.tasks)):
        if not fn.endswith(".md"):
            continue
        with open(os.path.join(a.tasks, fn), encoding="utf-8", errors="replace") as fh:
            fm, body = frontmatter_and_body(fh.read())
        m = re.search(r"^id:\s*(\S+)", fm, re.M)
        tid = m.group(1) if m else fn[:-3]
        m = re.search(r"^blocked_by:\s*(.*)$", fm, re.M)
        blocked = {x.strip() for x in m.group(1).split(",") if x.strip()} if m else set()
        if not live(tid):
            continue
        for ref in sorted(set(REF.findall(body))):
            if ref == tid or ref in blocked:
                continue
            # AN ID THAT RESOLVES TO NO TASK IS A DIFFERENT FAULT and leaves by a different
            # door: kit-status.sh reports it and
            # `T-20260808-a-task-id-matching-no-task-file-is-count` owns it. Failing it here
            # would merge "nobody declared this relation" with "this id is a typo", and the
            # remedies are not the same. Counted, reported, not failed.
            if ref not in known:
                unresolvable.add((tid, ref))
                continue
            # A closed end cannot be ordered against, so the planner never reads such an edge
            # and requiring its declaration would be make-work on finished history.
            if not live(ref):
                continue
            checked += 1
            if (tid, ref) not in declared:
                violations.append((tid, ref))

    print(f"kit: {checked} live reference(s) checked, {len(declared)} map row(s), "
          f"{len(unresolvable)} unresolvable reference(s) (reported by kit-status, not failed here)")
    if not violations:
        print("kit: every live task reference is declared")
        return 0
    print(f"\nkit: {len(violations)} reference(s) written in prose and declared nowhere.",
          file=sys.stderr)
    print("     Declare each as an ordering in the task's `blocked_by:`, or as a relation in",
          file=sys.stderr)
    print(f"     {a.map}. Recording a refusal is a result: `not-a-blocker` is a row.\n",
          file=sys.stderr)
    for src, dst in violations:
        print(f"  {src}\n    -> {dst}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

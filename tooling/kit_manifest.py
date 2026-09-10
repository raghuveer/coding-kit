#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
"""Read or write a census manifest. Three modes, one file, no other job.

    (no argument)   answer "may this unit be captured into this manifest?"
                    reads MAN, UNIT -> prints exactly one token
    --source        answer "does this captured artefact audit the declared document?"
                    reads MAN, ART -> prints exactly one token
    --write         validate the fields of a NEW manifest and emit it as JSON
                    reads MAN_* from the environment -> prints JSON, or refuses

WHY `--source` IS A SEPARATE MODE RATHER THAN PART OF THE FIRST. The first mode answers a
question that must be settled BEFORE anything is written; this one reads a file that does not
exist until after the write, because F12 requires the reply to reach disk before it is judged.
One invocation, one question, and the caller cannot ask the second one early.

WHY A FILE RATHER THAN `python3 -c` INSIDE THE SHELL. An inline program lives in a
single-quoted shell string, and an apostrophe inside one closes it -- a trap this repository
has already paid for twice in a single day (docs/LESSONS.md). It is also unreadable in a diff
and untestable on its own. `kit_findings.py` is the precedent: serialisation and validation
live in a python file, and the shell script calls it.

WHY THE ENVIRONMENT RATHER THAN ARGV. `awk -v` and friends process escape sequences in the
value, and a Windows path carries backslashes that then vanish -- recorded on 2026-08-25 after
a splice silently read an empty block. Reading through the environment avoids the whole class.

T-20260809-one-json-reader-and-one-json-writer-at-t governs whether this eventually folds into
`kit_findings.py`. This is a second reader in `tooling/` and is named as such rather than left
to be discovered by the conformance step that task asks for. The writer lives here rather than
in a third file for the same reason.
"""
import json
import os
import re
import sys

# F1b, the same rule tooling/kit-claim.sh enforces on the capture path. Kept here because this
# module validates unit names on the WRITE path, where the shell's copy does not run.
NAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")

# D3's three attribution variables, plus what D4 and F1c require. D3's whole claim is that a
# diff in which more than one of these moved is uninterpretable -- so a manifest missing any of
# them cannot support the comparison a census exists for. Refused rather than written with a
# blank, because a blank attribution variable is indistinguishable from one that never moved.
REQUIRED = (
    ("purpose", "D4 keys the census's storage on purpose and nothing in a tree can compute it"),
    ("subject_repo", "a census about an unnamed subject cannot be reported per subject"),
    ("subject_sha", "D3: the subject tree is one of the three attribution variables"),
    ("subject_dirty", "D3: a dirty tree at the same SHA is a different subject"),
    # F1d: this is a CONSTRAINT, not a label. Every unit captured into the census must carry a
    # `source` equal to it, and `kit-claim.sh` refuses one that does not. A census audits exactly
    # one document; two documents are two censuses. The field previously said "name it", which
    # said nothing about what happens when a unit disagrees -- a required field with undefined
    # semantics, which is the shape this repository files against itself (`3e76f904`).
    ("source_document", "F1d: every unit's `source` must equal it; a census audits one document"),
    ("auditor_model", "D3: the auditor is one of the three attribution variables"),
    ("kit_sha", "D3: the kit is the thing being validated recursively"),
    ("kit_version", "D3: recorded beside kit_sha so a reader need not resolve the SHA"),
    ("recorded_at", "when this manifest was written"),
)

OPTIONAL = ("subject_remote", "audited_at")


def _fail(msg):
    sys.stderr.write("kit-manifest: %s\n" % msg)
    return 2


def read_mode():
    man = os.environ.get("MAN", "")
    unit = os.environ.get("UNIT", "")
    try:
        with open(man, encoding="utf-8") as fh:
            m = json.load(fh)
    except Exception as exc:                      # noqa: BLE001 -- the caller prints it verbatim
        print("BADJSON %s" % exc)
        return 0

    # A manifest that is a list, a string or a number is not a manifest. Say which, rather than
    # letting `.get` raise and the shell report "could not read", which would be true of an
    # unreadable file and of this, and they are different problems.
    if not isinstance(m, dict):
        print("BADJSON manifest is not a JSON object")
        return 0

    # D4: purpose is DECLARED, never derived. A census whose purpose is unset is refused rather
    # than defaulted, because defaulting either way silently misfiles it. Whitespace is not a
    # declaration, so it is stripped before the emptiness test.
    purpose = m.get("purpose")
    if not isinstance(purpose, str) or not purpose.strip():
        print("NOPURPOSE")
        return 0

    # F1c: a unit is an INPUT to an audit. The manifest declares the units before the auditor
    # runs, and an undeclared unit is refused rather than created.
    units = m.get("units")
    if not isinstance(units, list):
        print("NOUNITS")
        return 0

    # F1d, checked on the READ path as well as the write path. `--init` always writes this field,
    # so a manifest without it was hand-written -- and a hand-written manifest that capture accepts
    # is a census whose constraint can never be checked. Refused here rather than warned about at
    # capture, because "the constraint was not verified" printed once into a terminal is not a
    # record of anything. Nothing is written for a manifest this refuses.
    src_doc = m.get("source_document")
    if not isinstance(src_doc, str) or not src_doc.strip():
        print("NOSOURCEDOC")
        return 0

    print("OK" if unit in units else "UNDECLARED")
    return 0


def source_mode():
    """F1d: compare a captured artefact's `source` against the manifest's `source_document`.

    Runs AFTER the artefact is on disk. The token it prints decides the exit status of the
    capture, never whether the bytes survive -- F12 is not negotiable, and this mode cannot
    reach the file it reads until the write has already succeeded.
    """
    man = os.environ.get("MAN", "")
    art = os.environ.get("ART", "")
    try:
        with open(man, encoding="utf-8") as fh:
            m = json.load(fh)
        declared = m["source_document"]
    except Exception as exc:                      # noqa: BLE001 -- the caller prints it verbatim
        print("BADJSON %s" % exc)
        return 0

    # THE ONE HOLE, NAMED RATHER THAN LEFT TO BE FOUND. A reply that is not a JSON object cannot
    # be held to the constraint, and conformance asserts that such a reply is still CAPTURED --
    # F12, "a reply that fails validation keeps its data". So this branch reports that the
    # constraint could not be checked and the capture stands. It is a real gap: an unparseable
    # artefact enters the census unchecked. It is bounded by being unparseable, which every later
    # reader of the census also discovers, and it is the price of F12 rather than an oversight.
    try:
        with open(art, encoding="utf-8") as fh:
            a = json.load(fh)
    except Exception as exc:                      # noqa: BLE001
        print("UNPARSED %s" % exc)
        return 0
    if not isinstance(a, dict):
        print("UNPARSED the reply is not a JSON object")
        return 0

    # A JSON OBJECT IS HELD TO THE RULE. If the envelope parsed then `source` is present or absent
    # by the auditor's choice, and an absent one is refused rather than skipped: skipping it would
    # let any auditor opt out of the constraint by omitting the field, which is a check that
    # cannot fail.
    got = a.get("source")
    if not isinstance(got, str) or not got.strip():
        print("NOSOURCE")
        return 0

    if got.strip() != declared.strip():
        print("SOURCEMISMATCH\t%s\t%s" % (declared.strip(), got.strip()))
        return 0

    print("OK")
    return 0


def write_mode():
    """Build a manifest from MAN_* environment variables, or refuse and name the field."""
    got = {}
    for key, why in REQUIRED:
        val = os.environ.get("MAN_" + key.upper(), "")
        if not val.strip():
            return _fail("%s is required and was empty -- %s" % (key, why))
        got[key] = val.strip()

    # subject_dirty is a flag, not prose. "false", "no" and "" are all things an operator might
    # type meaning clean, and guessing between them is how a dirty tree gets recorded as clean.
    if got["subject_dirty"] not in ("0", "1"):
        return _fail("subject_dirty must be exactly 0 or 1, got %r" % got["subject_dirty"])
    got["subject_dirty"] = int(got["subject_dirty"])

    raw = [u for u in os.environ.get("MAN_UNITS", "").split(",") if u.strip()]
    if not raw:
        return _fail("units is required and was empty -- F1c: a unit is an input to an audit, "
                     "declared before the auditor runs")
    units = []
    for u in raw:
        u = u.strip()
        # F1b on the WRITE path. Declaring a unit the capture path would later refuse produces a
        # manifest nothing can ever be captured into -- a census dead on arrival, discovered only
        # when the first audit comes back.
        if not NAME_RE.match(u) or u in (".", ".."):
            return _fail("unit %r is not a usable name: letters, digits, dot, underscore or "
                         "hyphen, and never '.' or '..' (F1b)" % u)
        if u in units:
            return _fail("unit %r is declared twice; a unit is one file and one ordinal" % u)
        units.append(u)
    got["units"] = units

    for key in OPTIONAL:
        val = os.environ.get("MAN_" + key.upper(), "").strip()
        if val:
            got[key] = val

    # Sorted, so two manifests with the same content are byte-identical whatever order the shell
    # exported things in. A census is a benchmark; its manifest should diff cleanly against the
    # next one rather than churning on key order.
    sys.stdout.write(json.dumps(got, indent=2, sort_keys=True, ensure_ascii=False) + "\n")
    return 0


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--write":
        return write_mode()
    if len(sys.argv) > 1 and sys.argv[1] == "--source":
        return source_mode()
    return read_mode()


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
"""Read or write a census manifest. Two modes, one file, no other job.

    (no argument)   answer "may this unit be captured into this manifest?"
                    reads MAN, UNIT -> prints exactly one token
    --write         validate the fields of a NEW manifest and emit it as JSON
                    reads MAN_* from the environment -> prints JSON, or refuses

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
    ("source_document", "the claims assert things about a document; name it"),
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

    print("OK" if unit in units else "UNDECLARED")
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
    return read_mode()


if __name__ == "__main__":
    sys.exit(main())

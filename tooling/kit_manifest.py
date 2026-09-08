#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Raghuveer Dendukuri
"""Answer one question about a census manifest: may this unit be captured into it?

Reads MAN (manifest path) and UNIT (unit name) from the environment and prints exactly one
token on stdout. It decides nothing else and writes nothing.

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
to be discovered by the conformance step that task asks for.
"""
import json
import os
import sys


def main():
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


if __name__ == "__main__":
    sys.exit(main())

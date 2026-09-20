---
id: T-20260920-the-copy-procedure-produces-crlf-on-a-wi
title: The copy procedure produces CRLF on a Windows host while the repository stores LF
epic: validation
tier: T2
paths: docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

**§4's copy procedure is two lines and neither of them controls line endings.**

    git clone --no-hardlinks <subject> <copy>
    git remote remove origin

Git for Windows sets `core.autocrlf=true` in the SYSTEM config. Measured 2026-09-20:
`git config --system core.autocrlf` → `true`. So every clone taken on this host checks out CRLF
while the repository stores LF, and the trial then mounts that working tree into a Linux container.

On the highper-gateway copy: `Cargo.lock` held **8,473 CR bytes, one per line**, while the
committed blob held **zero**. The subject's own working tree is in the same state for the same
reason, so the copy was a faithful reproduction of a host artefact rather than of the repository.

**THIS IS NOT WHAT BROKE THE BASELINE, AND SAYING SO MATTERS.** The first diagnosis was that CRLF
is why `cargo check --locked` refused. Re-cloning with `-c core.autocrlf=false -c core.eol=lf`
produced a lockfile with zero CR bytes and **the identical refusal** — the real cause was a
one-line gap in the committed lockfile. The CRLF finding survived because it was checked
separately, not because it explained the symptom.

**What it DOES cost.** Every byte-level comparison against the subject is noise: the first diff of
the lockfile reported all 8,473 lines changed for a one-line delta, which is how the wrong
diagnosis got its start. Any trial measuring file content, diff size or checksums on a Windows host
is measuring the host.

`tooling/kit-tooling-facts` equivalents already say *"clone inside the container rather than copying
from Windows, or CRLF becomes a second variable."* **The protocol does not.**

## Acceptance criteria

- [ ] §4's copy procedure pins line endings, or says to clone inside the runtime, and says why
- [ ] The remedy is stated for a host whose SYSTEM config sets `autocrlf` — `--global` being unset
      is not enough, and was unset here while the system value was `true`
- [ ] A check that can fail: a copy taken by the documented procedure is asserted to match the
      committed blob byte for byte, and a mutation that drops the line-ending pin takes it red
- [ ] Whether the existing trial-2 record is affected is checked rather than assumed. That trial
      ran from a copy taken the same way

## Notes

Found 2026-09-20 taking the trial-3 pre-flight baseline. Fourth gap in the same procedure after the
three in `T-20260914-the-copy-procedure-loses-branches-trusts`, and like those it was invisible
until the procedure was executed rather than read.

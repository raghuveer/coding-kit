<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Contributing

## Licence, in one paragraph

This project is under the **Apache License 2.0**. Under [section 5 of that
licence](LICENSE), anything you deliberately submit for inclusion is licensed under the same
terms automatically, unless you say otherwise in the contribution itself. That includes the
express patent grant in section 3. Nothing further is needed to make your contribution usable
here, and **there is no CLA** — no agreement to sign, no account to link, no corporate legal
review to sit through.

What section 5 does *not* do is record that you had the right to send what you sent. That is
what the sign-off below is for.

## Sign your commits (DCO)

Every non-merge commit must carry a `Signed-off-by:` line. `git commit -s` writes it from your
configured `user.name` and `user.email`:

```
Signed-off-by: Jane Doe <jane@example.com>
```

Adding that line means you certify the **Developer Certificate of Origin 1.1**, reproduced in
full at the bottom of this file. In short: you wrote it, or you have the right to pass it on,
and you understand the record is public and permanent.

It is not a copyright assignment and it is not a licence grant — the licence already handled
that. It is a statement about provenance, and it costs one flag.

`git commit -s --amend` fixes a commit you already made. If a branch is missing sign-offs
throughout, `git rebase --signoff <base>` adds them across the range.

### What is checked, and where

`tooling/kit-trailers.sh` validates it in two places — the `commit-msg` hook if you ran
`kit-init.sh`, and the `trailers` job in CI, which is a required check on `main`. It checks
three things:

- the line is **present** on every non-merge commit;
- it parses as `Name <email>` — a sign-off naming nobody records nothing;
- git can actually **see** it. Trailers must sit in the message's final paragraph, together
  with `Task-Id`, `Tier` and `Co-Authored-By`. A blank line above `Co-Authored-By` strands
  everything below it and the gate says so.

Unlike `Task-Id` and `Tier`, the sign-off is **not** waived for `chore:`, `docs:` and `style:`
commits. That exemption exists because a missing task reference on a typo fix costs you a
wrong count. A sign-off is not bookkeeping, and a docs commit is as copyrightable as any
other — exempting the trivial ones would put exactly the commits nobody reads outside the
record the DCO exists to build.

This is switched on by `git.require_signoff: true` in `.claude/project-profile.md`. **It is off
by default in the kit**, so adopting the kit never starts rejecting your project's commits.
Which contributions a project accepts, and on what assertion, is that project's call.

## The other trailers

`Task-Id:` and `Tier:` are this repository's own conventions, not part of the DCO. See
[`README.md`](README.md#trailers--frozen-once-adopted) for what they mean and when they are
required.

## Attribution and AI-assisted contributions

Parts of this project were generated with Claude Code under human direction, and the `NOTICE`
file says so. If you contribute AI-assisted work, sign off exactly as you would otherwise —
the DCO's clause (a) asks whether you have the right to submit the contribution under the
project's licence, and that question has the same answer either way. Use `Co-Authored-By:` if
you want the assistance recorded in the commit; several commits here already do.

---

## Developer Certificate of Origin 1.1

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

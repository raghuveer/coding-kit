---
id: T-20260912-a-trial-runs-in-a-container-on-the-subje
title: A trial runs in a container on the subject's own OS so nothing is installed on the host
epic: validation
tier: T2
paths: docs/TRIAL-PROTOCOL.md
state: created
---

## Intent

Trial 1 ran on Windows and several of its findings were **about Windows** rather than about
the subject or the kit -- carriage returns in spend lines, host paths in logs that could not be
copied back. The subject is Linux-first, and a trial that cannot run on the subject's own
operating system is measuring the wrong thing.

Probed on this machine, 2026-09-12, rather than assumed: Rancher Desktop is running with
containerd v2.3.2 and `nerdctl` v2.2.2. Inside a container the kernel is
`6.6.87.2-microsoft-standard-WSL2` with `io_uring_disabled = 0` and 8 cores, and the working
drive bind-mounts **writable**. The `rust:1-bookworm` image already present carries git, cc,
python3 and curl; it lacks only `sqlite3`, which the kit needs.

So a trial can run on the subject's own operating system **with nothing installed on the host**,
which is the blocker this removes.

## Acceptance criteria

- [ ] A recorded image definition supplies the kit's own dependencies and the subject's toolchain, so a trial does not begin by installing packages by hand
- [ ] `docs/TRIAL-PROTOCOL.md` states how a trial names its runtime -- kernel and image digest -- so two trials are comparable rather than described in prose
- [ ] A trial run records that runtime as evidence alongside its other artefacts
- [ ] No step of the protocol requires installing anything on the host machine
- [ ] The subject builds and its tests run inside the container, proven once end to end

### Evidence, 2026-09-14 — proposed, not certified. AC5 is BLOCKED on a host action.

| AC | state | where to verify |
|---|---|---|
| 1 — a recorded image definition supplying the kit's and the subject's dependencies | **met, 2026-09-12** | `docs/trial-runtime/Dockerfile`, commit `4264b84`. Every package read from the subject's `Cargo.lock` after a first image failed on cmake, not guessed |
| 2 — the protocol states how a trial names its runtime, kernel and image digest | **met, and it predates this task's filing** | §2 *Record every time*: *"`uname -srm` from where the kit actually ran, plus the container image digest if any, plus the host OS. Prose does not compare"* |
| 3 — a trial run records that runtime as evidence | **pending a trial** | §2 requires it and §0 now produces it. Nothing can close this but trial 2 |
| 4 — no step requires installing anything on the host | **met, and now stated rather than implied** | audited: the protocol's only install language is `kit-init.sh` installing hooks *into the copy*, which is not a host install. §0 now states the split — subject toolchain in the container, subject mounted read-only, target to `/tmp`, and the kit needing only `bash`/`git`/`sqlite3`, which adoption already implies |
| 5 — the subject builds and its tests run inside the container, proven once end to end | **the RUNTIME is proven; the criterion as worded is NOT met, and cannot be by the kit** — see below | the run reached the subject's own source and failed there: 91 errors, every one of 110 locations under `highper-gateway/`, zero toolchain failures |

**AC5, run 2026-09-14 and classified rather than summarised.**

    image    sha256:237fab4e66710fde0e20f279e8c099dcb2d31fdc397d98aa6ec8ff716b878f2a
    kernel   Linux 6.6.87.2-microsoft-standard-WSL2 x86_64
    command  cargo check --workspace --all-features   (the subject's own ci.yml)
    copy     git archive of 4bbcd8e, no .git, mounted writable; subject never mounted
    result   exit 101 in 248 s, 2,453 lines

**Three states were possible and it is the third.** Not a runtime fault: **zero** toolchain
failures, and `tikv-jemallocator` — the crate whose autoconf killed the Windows host — compiled
cleanly. Not a stale lockfile: that was run 1, against the subject read-only, which failed in 27 s
because `Cargo.lock` predates the manifest and a read-only mount has no way through. This is the
**subject's own baseline**: 48 × `E0433`, 36 × `E0425`, 2 × `E0422`, 2 × `E0405`, 2 missing
`async_trait` — missing imports and unresolved paths on the `--all-features` path.

**91 errors here against the 90 trial 1 recorded.** The same baseline, reproduced independently on
Linux, which is the first corroboration that figure has ever had.

**So the criterion as worded cannot be met by this kit, and that is the finding.** "The subject
builds" conflates *the runtime is correct* with *the subject is healthy*, and only the first is the
kit's business. The subject does not compile under `--all-features`; that is its owner's, routed by
§7 as a subject finding. Proposed rewording, for the operator rather than taken here: *the runtime
compiles the subject's full dependency graph and reaches its source, with any remaining failure
attributable to the subject.* That is what was proven.

**An interaction with `T-20260912-a-declared-rung-whose-tooling-fails-has-` that neither task
saw separately, and it would have bitten trial 2.** That task's `kit-preflight.sh --commands`
was documented as *"run it in the subject copy"*. For a Linux-first subject on a Windows host
the declared commands fail there — and the check would have reported `unsatisfiable`, which is
the state it exists to catch, when the real fault is the runtime being wrong. §0 now says to run
it wherever the commands are meant to run, which for a containerised subject is inside the
container. Two controls landing on the same day, correct alone and wrong together.

## Notes

This also supplies, cheaply, the OS-level boundary that
`T-20260912-trial-isolation-relies-on-a-file-tool-gu` asks for: today isolation rests on a
file-tool guard inside the agent, which is a guard the agent could route around via Bash. A
container is a boundary the agent does not enforce on itself.

Bind mounts through WSL2 onto NTFS are slow under heavy I/O and a Rust build is heavy I/O. If it
drags, clone into a container volume and bind-mount only the outputs -- worth stating in the
protocol rather than rediscovering per trial.

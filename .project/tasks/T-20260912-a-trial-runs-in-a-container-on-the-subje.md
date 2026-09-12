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

## Notes

This also supplies, cheaply, the OS-level boundary that
`T-20260912-trial-isolation-relies-on-a-file-tool-gu` asks for: today isolation rests on a
file-tool guard inside the agent, which is a guard the agent could route around via Bash. A
container is a boundary the agent does not enforce on itself.

Bind mounts through WSL2 onto NTFS are slow under heavy I/O and a Rust build is heavy I/O. If it
drags, clone into a container volume and bind-mount only the outputs -- worth stating in the
protocol rather than rediscovering per trial.

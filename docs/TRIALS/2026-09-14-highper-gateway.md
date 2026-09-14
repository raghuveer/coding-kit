<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 Raghuveer Dendukuri -->

# Trial: highper-gateway — 2026-09-14

> **PRE-FLIGHT COMPLETE, CLOCK NOT YET STARTED.** Everything below **Baseline** is recorded; the
> sections after it are filled as the trial runs. §0 requires the pre-flight answers to be
> recorded because they are part of the result, and this trial's pre-flight produced six findings
> of its own before any work began — they are listed under **Pre-flight findings**.

| | |
|---|---|
| Question | **On a brownfield subject that never fully adopted the kit, and whose baseline is red for four independently-named reasons, does the kit produce a change that the verify ladder can actually pass — and where it cannot, does the trial say so rather than record COMPLETE?** |
| Kit SHA | `e6f47aada6403199339e6446b56702634c2e3824` |
| Time-box / actual | **1 h**, then a recorded STOP / CONTINUE / RETRY, **cap 4 h** / *pending* |
| Subject | `highper-gateway`, Rust, 169 commits, `e588b53` on `master` |
| Greenfield / brownfield | **brownfield**, history not truncated |
| Outcome | *pending* |
| Baseline before the kit | see **Baseline** — four checks, four causes. `build pass, tests fail` is not a baseline |
| Instruments verified live | spend **45 → 46** rows; findings **628 → 629**, and the row joins to its run |
| Copy isolation verified | `--isolated` exit 0 after 20 outward-reaching permission rules were stripped |

## Runtime

    image digest   sha256:237fab4e66710fde0e20f279e8c099dcb2d31fdc397d98aa6ec8ff716b878f2a
    kernel         Linux 6.6.87.2-microsoft-standard-WSL2 x86_64
    host OS        Windows 11 (26200), Rancher Desktop containerd v2.3.2, nerdctl v2.2.2
    subject        e588b53 on master; adoption commit a6b3dcb
    copy           D:\trials\highper-gateway-e588b53

**The subject toolchain runs in the container; the kit runs there too for the `commands.*` box,**
mounted read-only at `/kit` with the copy at `/src`. The profile therefore carries plain commands
and no host paths — the alternative, putting the `nerdctl` invocation into `commands.*`, would
bake an absolute host path into a file meant to be shared.

## Baseline before the kit

Taken **before adoption**, on a quiet machine. A first set was taken while the Windows conformance
suite was running and is **discarded**: exit codes and causes are load-independent, `seconds` is
not, and `seconds` is the only column comparable across trials.

| check | command | exit | seconds | cause |
|---|---|---|---|---|
| build | `cargo build --release -p highper-gateway` | **0** | 625 | — (91 warnings) |
| test | `cargo test --workspace --lib -- --test-threads=4` | 101 | 243 | compiles; **972 pass, 2 fail** — `cache::manager::tests::test_health_check` panics on `runtime_config not initialized`; `runtime_config::loader::tests::load_with_no_env_vars_returns_defaults` panics on `InvalidCombination { HIGHPER_AI_CACHE_BACKEND=valkey requires HIGHPER_CLUSTER_TYPEB_BACKEND }`. Both `#[serial]`, both deterministic — identical at `--test-threads=1` |
| typecheck | `cargo check --workspace --all-features` | 101 | 203 | **91 errors**, all under `highper-gateway/` — 48 `E0433`, 36 `E0425`, 2 `E0422`, 2 `E0405`, 2 missing `async_trait` |
| audit | `cargo audit`, from the subject's own CI | 1 | n/a | `RUSTSEC-2026-0044`–`0048` (AWS-LC: X.509 name-constraints bypass, AES-CCM timing side-channel, PKCS7 chain and signature validation bypasses, CRL scope error) + `RUSTSEC-2026-0255` `spin 0.9.8` **yanked** |

**`Build Release` passes.** Trial 1 recorded this subject as the single word *red*; that word erased
the one green row and merged four unrelated causes. `625 s` against trial 1's `579 s` is the only
figure comparable across the two trials, and it agrees within 8%.

**Per CI job**, from the subject's own Actions on `e588b53`:

| job | verdict | cause |
|---|---|---|
| Build Release | **success** | — |
| Format | **success** | — |
| Validate Configs | **success** | — |
| Check | failure | the 91 errors above |
| Clippy | failure | same surface, `-D warnings` |
| Test | failure | 2 of 974 |
| Security Audit | failure | the six advisories above |

**`unverified`:** none of the four causes is inferred — each was produced by the command in its own
row, or read from the CI job that produced it.

## Adoption — INCOMPLETE, deliberately

`kit-init.sh` **exits 1** on this subject and is right to. `.gitignore` excludes `.claude` six ways
(`/tmp/claude*/`, `/.claude/`, `.claude/`, `**/.claude/`, `.claude-*`, `*.claude`) and `.project`
once, so neither `project-profile.md` nor any task or event file can be committed, and the
*"commit them, the team shares them"* step is impossible.

**The trial proceeds on that footing rather than reversing six deliberate exclusions in someone
else's project** — §7 makes anything the trial produces for the subject a proposal, never an
application. Measured: the kit nonetheless **functions** — `kit-index.sh` and `kit-status.sh` both
exit 0 on the copy, and `kit-finding.sh` records into the ignored `.project` without complaint.

`git.adopted_at` = `a6b3dcb`, the adoption commit, **set by the operator's decision** rather than
left to default. The cost is accepted and stated: no `touches` edges from history, so blast radius
on the first task will read UNKNOWN. The gain is that trailer discipline describes only work done
under the kit.

**A consequence worth recording:** with `.project` ignored, the kit's own writes never dirty the
tree, so §3's dirty-tree VOID condition is *less* likely to fire here — for the wrong reason.

## Pre-flight findings — six, before the clock

Every one would otherwise have surfaced mid-trial, where it would be indistinguishable from the
kit failing.

1. **§4's copy procedure loses every branch but one.** `git remote remove origin` discards the
   remote-tracking refs, so a subject whose HEAD sits on a feature branch yields a copy where
   `master` is unreachable. Filed: `T-20260914-the-copy-procedure-loses-branches-trusts`.
2. **Nothing says to bring the subject up to date.** The local `master` was two merges behind
   `origin/master`; the first correct-looking copy came out at trial 1's own `05c56eb` inside a
   directory named `…-e588b53`. **The directory name was the only thing asserting the version.**
3. **The baseline run dirties the copy**, and §3 makes a dirty tree a VOID condition. Widened
   during the pre-flight: `--commands` does it too, so it is not a step bolted to the baseline but
   a clean-tree assertion needed immediately before the clock.
4. **`--commands` misclassified a red baseline as a stop.** It keyed on exit code alone, so
   `cargo check` exiting 101 with 91 real errors read as *"DECLARED AND DOES NOT RUN"* — and would
   have refused this trial over errors recorded in this trial's own baseline. Fixed and merged as
   PR #130 before the clock; 126/127 now mean *cannot run*, anything else means *ran and reported*.
5. **The isolation check fired on its first live use.** The copy carried a tracked
   `.claude/settings.local.json` with 20 outward-reaching rules, including absolute paths to
   Rancher Desktop binaries. Stripped; the original is kept beside the copy.
6. **A probe of mine contaminated the copy.** A `kit-finding.sh` call run to test whether recording
   worked wrote a real finding row into the trial's own `events.ndjson`. The copy was **remade from
   scratch** rather than hand-edited: evidence a later reader cannot verify is worse than the
   minute it costs to re-clone.

## Stop rules, pre-registered

- the **1-hour** boundary, unless the recorded decision is CONTINUE; never past the **4-hour cap**
- the **same kit defect blocks progress three times** — the third occurrence, not the first
- any **§3 VOID condition** — eight as of 2026-09-14
- **`--commands` reports `CANNOT RUN`** mid-trial. Not one of §0's; added because it names the trap
  that made trial 1 unreadable, and narrowed after PR #130: a command that *runs* and reports
  failures is a baseline fact, not a stop

## Abort path

If the kit crashes or corrupts state mid-trial, this is recorded as
`docs/TRIALS/2026-09-14-highper-gateway-ABORTED.md` with the cause and what had been established
first. **Never silently restarted** — a restarted trial has a contaminated index. A restart is a
new trial, new copy, new baseline, both records kept.

---

*Sections below are filled as the trial runs.*

## Cost

*pending*

## Findings

*pending*

## Which brownfield degradations bit

*pending*

## Three kinds of finding

*pending*

## What was NOT exercised

*pending*

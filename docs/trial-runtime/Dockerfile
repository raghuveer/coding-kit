# The trial runtime: the subject's own operating system, with the kit's dependencies and the
# subject's both present, so a trial does not begin by installing packages by hand.
#
# WHY THIS EXISTS. Trial 1 ran on a Windows host and several of its findings were about Windows
# rather than about the subject or the kit. Worse, rung 1 of the verify ladder -- "it compiles" --
# was never satisfied: the host build died on jemalloc's autoconf, `--no-default-features` died
# because io-uring does not type-check on Windows at all, and the trial's own container probe ran
# 24.4 minutes and died on a missing protoc. The change was reviewed at rungs 4 and 5 anyway.
#
# EVERY PACKAGE BELOW WAS NAMED BY A MANIFEST, NOT GUESSED. Read from the subject's Cargo.lock
# after a first build failed on cmake, rather than added one rebuild cycle at a time:
#
#   sqlite3             the kit's index; the only gap for the kit alone
#   cmake, g++          quiche and aws-lc-sys build BoringSSL through the cmake crate
#   protobuf-compiler   prost-build and tonic-build shell out to protoc
#   libssl-dev          openssl-sys links against it
#
# THE LIST IS NOW READ FROM THE SUBJECT'S OWN DECLARATION, not from its Cargo.lock. On
# 2026-09-13 the subject committed `4bbcd8e build: declare the system build dependencies the
# project already needs`, which names them in .github/workflows/ci.yml and cites this kit's own
# 2026-09-11 container probe as the reason -- "540 compile lines and then failed on Could not
# find protoc". Reading a manifest was the right method and it is now superseded by a better
# source: the project says what it needs.
#
#   liburing-dev        io-uring, which is why the subject is Linux-first at all
#   nasm, perl          aws-lc-sys assembles and generates during the BoringSSL build
#
# pkg-config and ca-certificates are in the subject's list and already in rust:1-bookworm.
#
# rust:1-bookworm already provides cargo, rustc, cc, pkg-config, git, python3 and curl.
#
# THE TAG IS NOT THE IDENTITY. A trial records the DIGEST this produces, with the kernel it ran
# on -- see docs/TRIAL-PROTOCOL.md section 2, "Record every time". Two trials naming the same tag
# and different digests are not comparable, and the digest is what makes that visible.
#
#   nerdctl build -t cck-trial docs/trial-runtime
#   nerdctl run --rm -v <subject>:/src:ro -w /src \
#     -e CARGO_TARGET_DIR=/tmp/target cck-trial cargo check --locked
#
# The subject is mounted READ-ONLY and the build target sent to /tmp on purpose: section 3 lists a
# dirty subject tree as a VOID condition, so a run that left target/ behind would void the next
# trial before it started.
FROM rust:1-bookworm
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sqlite3 cmake g++ protobuf-compiler libssl-dev \
      liburing-dev nasm perl \
 && rm -rf /var/lib/apt/lists/*

# THE RUNG TOOLING, WHICH THE PACKAGE LIST ABOVE COULD NOT SEE. Every apt package above was read
# from the subject's declared BUILD dependencies, and that method was right for rung 1 and blind
# to rungs 3 and 4 -- lint and format tools are not build dependencies, so nothing in the
# subject's manifest names them. Measured 2026-09-20 on the trial-3 pre-flight:
#
#   cargo clippy --locked   exit 1   'cargo-clippy' is not installed for the toolchain '1.98.1...'
#   cargo fmt --check       exit 1   'cargo-fmt'   is not installed for the toolchain '1.98.1...'
#
# Two rungs of the verify ladder had no tooling in the runtime the protocol prescribes, which is
# the 2026-09-09 failure one layer out: an obligation that cannot run, in the image built to let
# it run. rust:1-bookworm ships cargo and rustc and neither component.
#
# THIS CHANGES THE DIGEST, and section 0 records the digest as part of the result. Done before a
# clock starts, where it is legal; the same edit after one is a commands.* adjacent change that
# section 2 makes void.
RUN rustup component add clippy rustfmt

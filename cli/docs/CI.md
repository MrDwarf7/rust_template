---
title: CI
---

## CI


### Workflows and tools

CI uses separate, parallel workflows for formatting, build/check and clippy, tests, documentation,
and release packaging. Each job installs only the binaries its recipe needs, then runs
`cargo make <recipe>`; CI does not use mise because jobs need only a few tools, not the full
developer toolchain.

`taiki-e/install-action` installs cargo-make in jobs that run recipes and Taplo in formatting jobs.
Its action is pinned to a full commit SHA with a version comment. Rust is installed through
`.github/actions/setup-rust`, which reads `rust-toolchain.toml`.

Generated Makefiles default `CARGO_CMD=mbx`; CI installs mbx with
`jdx/mr-boxington-action@47ce49b32025d93a7a2f4570815afaa2b7092240` (`v1`) so cargo-make commands
use the wrapper and its target cache. Set `CARGO_CMD=cargo` to opt out.

| Concern | Recipe |
| --- | --- |
| Rustfmt and Taplo format checks | `ci-format` |
| Cargo check | `ci-check` |
| Clippy with warnings denied | `ci-clippy` |
| Pedantic Clippy | `ci-clippy-pedantic` |
| Tests | `ci-test` |
| Release build | `ci-build-release` |
| Documentation build | `ci-doc` |

The corresponding task definitions live in `build/common-tasks.toml`. CI checks are non-mutating;
the local `format` task remains a formatter.

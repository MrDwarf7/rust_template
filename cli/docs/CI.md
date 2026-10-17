---
title: CI
---

## CI

> Native preference: version pins live in native files (`rust-toolchain.toml`, `.python-version`),
> not duplicated in shell. `cargo` already exports `CARGO_TARGET_DIR` -- use it directly; do not
> redefine `TARGET_DIR` as a second source of truth.

### Toolchain and developer tools

| Tool          | Pin file                                           | Composite input                                                   | Bump procedure                                                                 |
| ------------- | -------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Rust          | `rust-toolchain.toml` (`channel` + `components`)   | `setup-rust` `inputs.toolchain` (default reads file)              | Edit `rust-toolchain.toml`, verify `cargo make ci-check` locally               |
| Python        | `.python-version` (e.g. `3.12`)                    | `setup-python` `inputs.python-version`                            | Edit `.python-version` + any `Makefile.toml` env that pins it, verify `uv run` |
| uv            | `setup-python` `inputs.uv-version` (`latest`)      | `setup-python`                                                    | Bump in `setup-python/action.yml` default                                      |
| GCC/Clang     | `setup-gcc` `inputs.gcc-version` / `clang-version` | `setup-gcc`                                                       | Edit `setup-gcc/action.yml` defaults + this doc                                |
| Project tools | `mise.toml` (`latest`, 24-hour release age)        | Local: cargo-make selects mbx or falls back to cargo; CI runs mbx | Update `mise.toml`; use `mise-action@v5` if CI needs dev tools                 |

### Setup actions

- `.github/actions/setup-rust` -- rustup toolchain, GCC/Clang, and target components; reads
  `rust-toolchain.toml`
- `jdx/mr-boxington-action@47ce49b32025d93a7a2f4570815afaa2b7092240` (`v1`) -- installs mbx and
  manages CI target caches
- `.github/actions/setup-python` -- uv + Python, reads `.python-version`
- `.github/actions/setup-msvc` -- MSVC `cl.exe` + PATH fix, Windows only
- `.github/actions/setup-gcc` -- pinned GCC/Clang, Ubuntu only, otherwise no-op
- `.github/actions/checkout` -- thin wrapper around `actions/checkout@v7`

All use `inputs` with defaults, not `env:` (disallowed in actions).

### Paths

- `Makefile.toml` defines `ROOT = "${CARGO_MAKE_WORKSPACE_WORKING_DIRECTORY}"` (short alias, comment
  explains 15+ chars), `SCRIPT_DIR = "${ROOT}/scripts"`, `TOOL_DIR = "${ROOT}/tools"`.
- `CARGO_TARGET_DIR` is cargo-native; do not redefine `TARGET_DIR`.
- `build/*.toml` extend files inherit `ROOT/SCRIPT_DIR/TOOL_DIR`; keep file-local `env` only if
  strictly scoped.

### Scripts

- PKGBUILD-style base arrays: single `_common_*_flags`, appended per helper via
  `"${_common_flags[@]}"`.
- Candidate-chain dispatch: `_candidates=("bin:helper" ...)` + loop `command -v` + centralized
  switch -> helper. Extends by adding array entry.
- `_usage` via `export t=$'\t'` + `printf "%s\n" "$(cat <<EOF"` with `Usage: ${_self}` where
  `_self="$(basename "${BASH_SOURCE[0]:-$0}")"` so rename stays in sync.
- `printf` over `echo`, explicit failure on missing required arg, handle `-h|--help|help`.

Example `scripts/`:

```text
scripts/
  _common.sh              # common flags + ROOT/TARGET/BUILD
  _compile_c.sh           # leaf, handles toolchain dispatch
  consumer_compile.sh     # dispatcher: consumer_compile.sh <c|cpp|rust|all>
```

Corresponding `build/*.toml` dispatcher:

```toml
[tasks.ffi-consumer-compile-c]
command = "bash"
args = ["${SCRIPT_DIR}/consumer_compile.sh", "c"]
```

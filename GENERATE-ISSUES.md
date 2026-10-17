# cargo-generate issues (from generating `tm.rs`)

Recorded 2026-10-15 while generating the `tm` CLI from the `cli` sub-template.
Not fixed here. The generated project was patched locally where a bug would
have broken that crate.

Command that reproduced these (cwd = empty `/home/dwarf/Documents/GitHub_Projects/Rust/tm.rs`):

```bash
cargo generate --path /home/dwarf/Documents/GitHub_Projects/Rust/rust_template_cargo_generate \
  --name tm --force cli --init --silent --allow-commands --verbose \
  -d github_user=MrDwarf7 \
  -d use_rs_suffix=true \
  -d tagline='Short commands for tmux sessions' \
  -d short_description='A short-command wrapper around tmux' \
  -d long_description='tm is a small tmux wrapper: list, attach, switch, rename, and kill sessions without remembering tmux flags.' \
  -d keep_bacon=true \
  -d keep_data=false \
  -d keep_scratch=false \
  -d use_trim_paths=false \
  -d vcs_kind=jj \
  -d linker=default
```

cargo-generate 0.25.0. Package name came out `tm`, repo name `tm.rs`. That part is right.

## 1. jj repo symlink is skipped

```text
[Skipping] Symbolic links not supported
`.../rust_template_cargo_generate/.jj/repo/config.toml`
```

`--path` copies the template into a temp dir first. This repo's `.jj/repo` is a
symlink, so the copy warns and skips it. Generation still finished. Any
intentional symlink inside a sub-template would be dropped the same way, with
only that warning.

## 2. `AGENTS.md` is tracked even though it says it is not

`AGENTS.md` says it is listed in `.git/info/exclude` and must never be committed.
`hooks/finish.rhai` runs `jj git init --colocate` and does not write that exclude.
After generate, `.git/info/exclude` is the stock git template (everything
commented out) and `jj status` shows `A AGENTS.md`.

The original `rust_template` `setup.sh` / `setup-agents.py` path is not in this
cargo-generate template, so nothing else patches the exclude either.

## 3. `build/.build.sh` still says `REPLACE_NAME_HERE`

`cli/build/.build.sh` and `workspace/build/.build.sh` are not Liquid. Workflows
and `Makefile.toml` get `PROJECT_NAME = "tm"`, but the script still has:

```bash
export ARTIFACT_NAME="REPLACE_NAME_HERE-$1"
cp "target/$1/release/REPLACE_NAME_HERE" "$ARTIFACT_NAME"
cp "README.md" "LICENSE-APACHE" "LICENSE-MIT" "$ARTIFACT_NAME"
```

A generated project that runs this script looks for a binary named
`REPLACE_NAME_HERE` and for license files that were not generated.

## 4. License files do not match the README or the pack script

Generated tree has one MIT `LICENSE`. `Cargo.toml` points `license-file` at it.
README still links `LICENSE-MIT` and `LICENSE-APACHE` and says "MIT OR Apache-2.0".
`build/.build.sh` copies those two names, so `cp` fails. Same in both
`cli` and `workspace`.

## 5. Stale `.cargo_options.toml` comment

`cli/Cargo.toml` says `See ./ .cargo_options.toml`. That file is not in the
template and is not generated.

## 6. `run_as_project` passes a leading space to cargo

`build/common-tasks.toml`:

```toml
args = ["run", " --bin", "${PROJECT_NAME}", "${@}"]
```

The argument is `--bin` (space included), so `cargo run_as_project` would fail.
The normal `run` task (`["run", "${@}"]`) is fine. Same string is in the
`cli` and `workspace` copies.

## Verified, not bugs

- `--init` does not init VCS itself, but `hooks/finish.rhai` still ran
  `jj git init --colocate` against the destination. Colocated jj came up.
- `--silent` needs every prompted placeholder via `-d`, including `linker` on
  Linux.
- `linker=default` correctly omitted `.cargo/`.
- GitHub Actions `${{ }}` survived Liquid (`{% raw %}`).
- `cliff.toml` kept its Tera body. The `<REPO>` postprocessor was filled in
  (`https://github.com/MrDwarf7/tm.rs`).
- `.genignore` dropped template png/ico/svg. `build.rs` only embeds
  `assets/icon.ico` on a Windows release build, so Linux generate is fine.
  A Windows release build will fail until `assets/generate-assets.sh` is run.

## 7. docs index script needs pyyaml, and nothing installs it

`scripts/update-docs-index.py` in a generated project exits with
`pyyaml is required`. The template does not declare that dependency, and the
post hook does not install it. `uv run --with pyyaml` works. The script then
indexed `docs/CI.md`, which has no frontmatter, as a bare `[CI](CI.md)` line.

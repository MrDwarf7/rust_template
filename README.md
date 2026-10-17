# rust_template (cargo-generate experiment)

Trial version of `rust_template`, published on the `cargo-generate` branch
of the same repository. The existing `main` template stays unchanged while
this subfolder layout is tested before deciding whether to replace it.

Server flavor is **not** in this experiment. That comes after cli +
workspace + ws_crate, from `rpa_lite` / `agent_axum.rs`.

Requires `cargo-generate` 0.24+ (`cargo generate --version`).

## Generate

Test the published branch without changing the default template:

```bash
cargo generate --git https://github.com/MrDwarf7/rust_template \
  --branch cargo-generate cli --name my_app
cargo generate --git https://github.com/MrDwarf7/rust_template \
  --branch cargo-generate workspace --name my_ws
```

To add a member from that branch, run from an existing workspace root:

```bash
cargo generate --git https://github.com/MrDwarf7/rust_template \
  --branch cargo-generate ws_crate --name extra_crate --destination crates
```

The favorites below also select `cargo-generate`, not `main`.

From this directory:

```bash
# prompts for which sub-template if you omit the name
cargo generate --path . --name my_app

# skip the picker
cargo generate --path . --name my_app cli
cargo generate --path . --name my_ws workspace
```

Or use the favorites in [`favorites.toml`](favorites.toml) (merge into
`~/.cargo/cargo-generate.toml`, or pass `--config`):

```bash
cargo generate rt-cli --name my_app
cargo generate rt-workspace --name my_ws
cargo generate rt-crate --name extra --destination crates
```

Add a crate to an **existing** workspace (cwd = workspace root):

```bash
cargo generate --path /path/to/rust_template_cargo_generate ws_crate \
  --name extra_crate \
  --destination crates
```

`--bin` (default) or `--lib` on `ws_crate`. cargo-generate 0.24+ then
walks up to `[workspace]`:

- `members = ["crates/*"]` -- left alone (already covered)
- `members = ["crates/foo"]` -- appends `crates/extra_crate`

`--no-workspace` skips that. Auto-add pretty-prints the root `Cargo.toml`
(key order may change; comments on that table can disappear).

Generated workspaces use `members = ["crates/*"]`, so adding a crate does
not rewrite the root manifest. cargo-generate 0.25 can otherwise rewrite
stabilized `trim-paths` strings into arrays that Cargo rejects. For an
existing explicit-member workspace with `trim-paths`, use `--no-workspace`
and add the member to `Cargo.toml` manually.

## Sub-templates

| folder | what you get |
|---|---|
| `cli` | single-crate app (bin) |
| `workspace` | virtual workspace (`resolver = "3"`, profiles + `[workspace.package/dependencies/lints]` at the root) + `crates/<name>/`; optional extra members |
| `ws_crate` | one member crate to drop into an existing workspace (no profiles: Cargo ignores them in members) |

Workspace extra members: prompt `extra_crates` as `foo, bar, baz` (blank =
just the named crate). Every member `Cargo.toml` is written by
`hooks/workspace/post.rhai` from one template, so they cannot drift.

## Placeholders

Defaults live in each `cargo-generate.toml`; Enter (or `--silent`) takes
them. No Liquid `| default:` pipes or Rhai fallbacks on top.

| placeholder | default | notes |
|---|---|---|
| `github_user` | `MrDwarf7` | |
| `use_rs_suffix` | `true` | repo name `crate.rs` vs `crate-name` |
| `tagline`, `short_description`, `long_description` | per sub-template | |
| `keep_bacon` / `keep_data` / `keep_scratch` | `true` / `false` / `false` | |
| `use_cranelift` | `false` | `cargo-features = ["codegen-backend"]`, `codegen-backend = "cranelift"` in every profile, `rustc-codegen-cranelift` toolchain component |
| `use_trim_paths` | `false` | `trim-paths = "object"` on release (`"none"` on dev). Stable since Rust 1.101, no cargo-feature (nightly cargo from ~2026-10-07; `rustup update nightly` if cargo asks for the `trim-paths` feature) |
| `vcs_kind` | `jj` | `jj` / `git` / `none` |
| `linker` | `default` | **Linux hosts only.** `default` / `lld` / `bfd` / `mold` / `gold` -> `.cargo/config.toml` under `[target.'cfg(target_os = "linux")']` |
| `install_tools` | none ticked | **Only when cargo-make and/or taplo are missing.** Multi-select; ticked tools are `cargo install --locked`ed |
| `extra_crates` | blank | workspace only |

Derived in Rhai (not prompted): `crate_name` (builtin), `project_name_upper`,
`repo_name`, `extra_crate_list`, `is_linux`, `has_cargo_make`, `has_taplo`,
`short_description_toml`, `github_user_toml`.

Descriptions and author text are escaped for TOML strings, including quotes,
backslashes, control characters, and Unicode. The original values remain
unchanged for README text and URLs.

### Linker

`linker = default` writes nothing and keeps rustc's choice (bundled
rust-lld on `x86_64-unknown-linux-gnu`). Anything else writes
`rustflags = ["-C", "link-arg=-fuse-ld=<linker>"]`; `mold` also sets
`linker = "clang"` per the mold README. The `-fuse-ld` arg lands after
rustc's own `-fuse-ld=lld`, so it wins (checked: bfd -> GNU ld, gold ->
GNU gold, mold -> mold). CI's `setup-rust` action exports its own mold
`RUSTFLAGS`, which replaces the config `rustflags` there.

The generated `.gitignore` already has `*config.to*`, so this
`.cargo/config.toml` stays local (a per-machine linker choice). Add
`!.cargo/config.toml` to share it.

### Build tools

`hooks/init.rhai` probes `makers --version` (cargo-make) and
`taplo --version` before prompting. Without `--allow-commands` you approve
each probe; a denied probe (or `--silent` without `--allow-commands`) counts
as installed, so nothing is offered blind. After generation the post hook
points at `Makefile.toml` and `cargo make A`, and lists anything still
missing.

## Hooks

All Rhai lives in `hooks/` at the repo root (a `hooks/` dir inside a
sub-template would be left behind, empty, in the output):

| file | stage | used by |
|---|---|---|
| `hooks/init.rhai` | init | cli, workspace |
| `hooks/pre.rhai` | pre | cli, workspace |
| `hooks/toml.rhai` | pre | cli, workspace, ws_crate (TOML string escaping) |
| `hooks/finish.rhai` | post | cli, workspace (linker config cleanup, tool installs, VCS init, notes) |
| `hooks/workspace/{pre,post}.rhai` | pre/post | workspace |
| `hooks/ws_crate/post.rhai` | post | ws_crate |

Preference order: `cargo-generate.toml` builtins (placeholders,
conditionals, `.genignore`) -> Rhai builtins (`variable::`, `file::`) ->
`system::command` only where the sandbox has no builtin: VCS init, tool
probes/installs, and copying extra workspace crates (`file::` has no read
or copy).

`--allow-commands` skips the per-command approval prompt. A silent
one-crate generate with `vcs_kind=none` runs no commands that matter;
denied probes are treated as "installed".

Template logos/icons are dropped by each sub-template's `.genignore`;
`assets/generate-assets.sh` stays so projects can make their own.

GitHub Actions `${{ }}` is wrapped in `{% raw %}` so Liquid does not
eat it. git-cliff's Tera body is also `{% raw %}`'d; only the `<REPO>`
URL is Liquid.

## Updating an existing project

```bash
cd /path/to/existing_project
python3 /path/to/rust_template_cargo_generate/update-existing.py --dry-run
python3 /path/to/rust_template_cargo_generate/update-existing.py
```

Renders the matching sub-template (detected from `Cargo.toml`, or
`--kind`) with the project's name and VCS, then copies only files the
project is missing. `src/`, `crates/`, `Cargo.toml`, `README.md`, etc. are
never touched. Extra `cargo generate` args go after `--`.

## What this does not do yet

- `server` sub-template (later, from rpa_lite)
- Shipping as the GitHub "Use this template" default
- Precompiled Rhai bytecode: cargo-generate only loads `.rhai` source.

## Generator regression test

Requires Python 3.11+ and cargo-generate. Run from this checkout:

```bash
python3 -B -m unittest discover -s tests -v
```

Generates disposable CLI, workspace, bin-member, and lib-member projects.
Checks exact TOML string round-trips and preserves workspace trim-paths
when adding members. It does not compile or run the generated applications.

## Silent smoke (no prompts)

```bash
cargo generate --path . --name smoke_cli cli --silent --vcs none \
  -d vcs_kind=none \
  -d use_cranelift=true \
  -d use_trim_paths=true \
  -d linker=mold
```

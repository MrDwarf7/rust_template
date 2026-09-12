# rust_template (cargo-generate experiment)

Throwaway sibling of `rust_template`. The original repo is untouched.
Decide later whether the public template is this subfolder layout, or
branches (`cargo generate --branch ...`).

Server flavor is **not** in this experiment. That comes after cli +
workspace + ws_crate, from `rpa_lite` / `agent_axum.rs`.

Requires `cargo-generate` 0.24+ (`cargo generate --version`).

## Generate

From this directory:

```bash
# prompts for which sub-template if you omit the name
cargo generate --path . --name my_app

# skip the picker
cargo generate --path . --name my_app cli
cargo generate --path . --name my_ws workspace
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

`--allow-commands` is only needed when a hook runs a system binary:
`jj`/`git` init, or extra workspace members (`cp` + `cat`). A silent
one-crate generate with `vcs_kind=none` does not need it.

## Sub-templates

| folder | what you get |
|---|---|
| `cli` | current single-crate template (bin) |
| `workspace` | virtual workspace + `crates/<name>/`; optional extra members |
| `ws_crate` | one member crate to drop into an existing workspace |

Workspace extra members: prompt `extra_crates` as `foo, bar, baz` (blank = just the named crate).

## Placeholders

Shared: `github_user`, `use_rs_suffix` (repo name `crate.rs` vs not),
`tagline`, `short_description`, `long_description`, `keep_bacon`,
`keep_data`, `keep_scratch`, `vcs_kind` (`jj` / `git` / `none`).

Derived in Rhai (not prompted): `crate_name`, `project_name_upper`,
`repo_name`, `extra_crate_list`.

GitHub Actions `${{ }}` is wrapped in `{% raw %}` so Liquid does not
eat it. git-cliff's Tera body is also `{% raw %}`'d; only the `<REPO>`
URL is Liquid.

## What this does not do yet

- `server` sub-template (later, from rpa_lite)
- Shipping as the GitHub "Use this template" default
- Precompiled Rhai bytecode: cargo-generate only loads `.rhai` source.
  Hooks stay small; there is no compile-and-ship step that cargo-generate
  will consume.

## Silent smoke (no prompts)

```bash
cargo generate --path . --name smoke_cli cli --silent --vcs none \
  -d github_user=MrDwarf7 \
  -d use_rs_suffix=true \
  -d tagline=tag \
  -d short_description=short \
  -d long_description=long \
  -d keep_bacon=true \
  -d keep_data=false \
  -d keep_scratch=false \
  -d vcs_kind=none
```

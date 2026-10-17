<!-- rumdl-disable MD033 -->
<h1 align="center">rust_template</h1>

<div align="center">

**Rust CLI and workspace templates powered by `cargo-generate`.**

![Rust](https://img.shields.io/badge/language-Rust-000000?style=for-the-badge&logo=rust&logoColor=white)
![cargo-generate](https://img.shields.io/badge/cargo--generate-0.24%2B-f4b183?style=for-the-badge)

</div>
<!-- rumdl-enable MD033 -->

Templates are maintained on the repository's default `main` branch. `cargo-generate` renders
them and runs their hooks.

[Quick start](#quick-start) | [Templates](#templates) | [Prompts and options](#prompt-order-and-choices) | [Toolchain](#toolchain-and-development) | [Update existing](#update-an-existing-project)

## Quick start

Install Rust/Cargo and
[`cargo-generate`](https://cargo-generate.github.io/cargo-generate/installation.html) 0.24 or newer:

```sh
cargo install cargo-generate --locked
```

Or install it with [mise](https://mise.jdx.dev/dev-tools/backends/cargo.html):

```sh
mise use --global cargo:cargo-generate@latest
```

Use a mise-activated shell so `cargo generate` is on `PATH`. For an install
without changing the global mise configuration, use
`mise install cargo:cargo-generate@latest`.

Generate a CLI app or virtual workspace:

```sh
cargo generate --git https://github.com/MrDwarf7/rust_template cli --name my_app
cargo generate --git https://github.com/MrDwarf7/rust_template workspace --name my_workspace
```

From a local checkout, choose the template explicitly:

```sh
cargo generate --path . --name my_app cli
cargo generate --path . --name my_workspace workspace
```

The [`favorites.toml`](favorites.toml) entries `rt-cli`, `rt-workspace`, and
`rt-crate` use the repository's default branch. Merge them into
`~/.cargo/cargo-generate.toml` or pass the file with `--config`.

From a workspace root, add a library member with `wsa`:

```sh
cd my_workspace
cargo make wsa authentication
```

For a first build, use a mise-activated shell in the generated project:

```sh
cd my_app
mise trust && mise install && mise reshim
cargo make b
```

The first build installs the Rust toolchain selected in `rust-toolchain.toml`.
`cargo make A` runs the full local format, check, lint, build, and test sweep.

## Templates

| Template    | Output                                                                                                                                                                                                                                  |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cli`       | One binary crate.                                                                                                                                                                                                                       |
| `workspace` | A virtual workspace (`resolver = "3"`) with its first binary crate under `crates/<name>` and optional extra binary crates copied from the first. Workspace profiles and shared package, dependency, and lint settings live at the root. |
| `ws_crate`  | A library-only workspace member. Its `error` module is private and its public error/result aliases are namespaced for the crate.                                                                                                        |

`cli` and `workspace` are initial-project templates. `ws_crate` is for a
member of an existing workspace; `wsa` is the generated workspace's
`cargo-make` task for adding one.

For `acme-authentication` with prefix `acme`, `src/lib.rs` exports namespaced
aliases while keeping `error` private:

```rust
pub use crate::error::{Error as AuthenticationError, Result as AuthenticationResult};
```

## Prompt order and choices

`cli` and `workspace` ask the common questions in this order. Enter accepts
each default.

| Placeholder      | Default | Meaning                                       |
| ---------------- | ------- | --------------------------------------------- |
| `keep_bacon`     | `true`  | Keep `bacon.toml`.                            |
| `keep_dev_dirs`  | `false` | Keep both `data/` and `scratch/`.             |
| `perf_testing`   | `false` | Include Criterion and performance tooling.    |
| `agent_support`  | `true`  | Include scoped agent instructions and skills. |
| `use_trim_paths` | `true`  | Trim paths in release build artifacts.        |
| `vcs_kind`       | `jj`    | Initialize `jj`, `git`, or neither (`none`).  |

The `workspace` template then asks for `crate_prefix` and `extra_crates`; both
are blank by default. The first crate keeps the project name. A blank
`extra_crates` means the workspace starts with only that crate.

`ws_crate` asks for `perf_testing`, `agent_support`, then `crate_prefix`.
`wsa` supplies those three values from the workspace's `Makefile.toml` and
runs without prompts. It does not infer a prefix from the project name.

### Template values and overrides

Pass a value with `-d key=value` or the matching `CARGO_GENERATE_VALUE_KEY`
environment variable. For example:

```sh
cargo generate --git https://github.com/MrDwarf7/rust_template \
  cli --name my_app -d vcs_kind=none -d agent_support=false
```

The optional `.rs` repository suffix is not prompted and defaults to `false`.
Enable it with `-d use_rs_suffix=true` or:

```sh
CARGO_GENERATE_VALUE_USE_RS_SUFFIX=true cargo generate \
  --git https://github.com/MrDwarf7/rust_template cli --name my_app
```

`tagline`, `short_description`, and `long_description` are derived from the
selected template by `hooks/details.rhai`; they are not normally prompted.
Set `rt_details=true` with `-d rt_details=true` or
`CARGO_GENERATE_VALUE_RT_DETAILS=true` to enable the optional text prompts
after the template's regular questions. `cli` and `workspace` ask for all
three values; `ws_crate` asks only for `short_description` (it does not use
`tagline` or `long_description`). Any supplied text value overrides its
derived value. In non-interactive automation, supply every field prompted by
the chosen template: Rhai prompts are not suppressed by `--silent`, and
missing text without a TTY fails clearly. `rt_details` is off by default.

### Author and GitHub owner

Generated Cargo author metadata uses cargo-generate's native `{{ authors }}`
value, derived from Cargo's user identity. The GitHub owner used in repository
links is a separate value. For `cli` and `workspace`, an explicit
`-d github_user=...` or `CARGO_GENERATE_VALUE_GITHUB_USER=...` wins. Otherwise
the template tries `gh api user --jq .login`, then `git config --get
github.user`, then asks for the owner. It does not use `git user.name` as a
GitHub handle or invent a fallback owner. If no owner is available and no TTY
is present, generation fails with an error.

`--allow-commands` authorizes cargo-generate's hook commands. Without it,
cargo-generate requests approval before commands run. Supplying `github_user`
avoids the GitHub identity probes; supplying `linker` avoids the linker probe.
The optional linker probe checks for `clang` on `PATH`.

### Linker selection

There is no linker question. On Linux, development builds use `mold@3.0.0`
when `clang` is available; otherwise they use the system linker. Release builds
always use the system linker. Override the development profile with
`-d linker=default`, `-d linker=lld`, `-d linker=mold`, or `-d linker=wild`.
`lld` selects the active toolchain's `rust-lld`; `mold` and `wild` select
mbx-managed `mold@3.0.0` and `wild@0.10.0`. mbx fetches and verifies managed
linkers. Non-system selections require `clang` on `PATH`; these profiles are
Linux-only.

The generated `.gitignore` ignores `.cargo/config.toml` for local overrides.
Use the tracked `.mbx.toml` for project-shared linker profiles; plain Cargo
without mise or mbx uses rustc's normal linker. The file does not add competing
`-fuse-ld` flags.

### VCS and silent generation

`vcs_kind` controls template-specific VCS setup: `jj`, `git`, or `none`.
Cargo-generate also has its own `--vcs` option. To disable both layers, pass
`--vcs none -d vcs_kind=none`.

With `--silent`, cargo-generate accepts defaults for its normal prompts.
Supply `github_user` to avoid the GitHub identity lookup and `linker` to avoid
the linker probe. If `rt_details=true`, also provide the prompted text values:
`tagline`, `short_description`, and `long_description` for `cli` and
`workspace`; only `short_description` for `ws_crate`. Rhai prompts are not
suppressed by `--silent`, and missing text without a TTY fails clearly.

## Workspace members

`crate_prefix` is an explicit workspace choice; it is never guessed from the
project name. Workspace crate names are trimmed but keep the user's hyphens and
underscores. If a prefix is set, it is always prepended with `<prefix>-`.
Already-prefixed names get the prefix again. For example, prefix `acme` and
extras `api, db` produce `acme-api` and `acme-db`. Duplicate checks compare
normalized Rust library identifiers, so equivalent hyphen/underscore spellings
are not added twice. Cargo library identifiers use snake case.

To add a member using `wsa`, pass its bare name:

```sh
cargo make wsa authentication
```

In a workspace with prefix `acme`, that creates `crates/acme-authentication`.
`wsa` is a declarative `cargo-make` command/args task in
`build/workspace-tasks.toml`. Run it at a workspace root with one name; if the
name is missing or the current directory is not a workspace root, it prints a
usage message and skips generation. The values `CRATE_PREFIX`, `PERF_TESTING`,
and `AGENT_SUPPORT` are stored in the workspace `Makefile.toml` `[env]` and
forwarded to new members. Edit them there to change later additions.

`wsa` uses the repository's default branch for its template source.
Set `RT_TEMPLATE` to override those cargo-generate arguments, for example:

```sh
RT_TEMPLATE="--path /abs/path/to/rust_template" cargo make wsa auth
```

`RT_TEMPLATE` is split on spaces, so paths containing spaces are unsupported.

For a direct `ws_crate` command, pass the fully prefixed name because
cargo-generate hooks cannot rename the output directory:

```sh
cargo generate --git https://github.com/MrDwarf7/rust_template ws_crate \
  --name acme-authentication --destination crates -d crate_prefix=acme
```

With cargo-generate 0.24 or newer, a new crate is appended to an explicit
`[workspace].members` list. A glob such as `members = ["crates/*"]` already
covers it. The default auto-add rewrites the root `Cargo.toml` and can discard
comments. `--no-workspace` skips that edit, so add the member yourself; with
cargo-generate 0.25, use `--no-workspace` for explicit-member workspaces that
use `trim-paths` and add the member manually.

## Toolchain and development

Generated projects select **nightly** in `rust-toolchain.toml`. The template
uses nightly codegen options for development; supported hosts get Cranelift
automatically for dev builds, while release builds use LLVM. Nightly also
allows the generated rustfmt and compiler options. It may need to download the
nightly toolchain and its Cranelift component on the first build.

`use_trim_paths` defaults to `true`. When enabled, release builds set
`trim-paths = "object"` and dev builds set `trim-paths = "none"`. The selected
nightly is new enough that this no longer needs an unstable Cargo feature flag.

To use stable instead, change `channel` in `rust-toolchain.toml` before the
first build, then remove or replace the nightly-only codegen backend and its
`cargo-features = ["codegen-backend"]` declaration, the
`rustc-codegen-cranelift-preview` component, unstable `.rustfmt.toml` settings,
and any `-Z` flags. Check that the selected stable Cargo supports the
`trim-paths` setting.

The generated `cli` and `workspace` `mise.toml` files request the latest
versions of development tools with a 24-hour minimum release age. This avoids
installing a tool immediately after publication. From the project root, run:

```sh
mise trust && mise install && mise reshim
```

`rust-toolchain.toml` owns the Rust channel. The `mise.toml` installs
`cargo-make`, Taplo, git-cliff, Bacon, cargo-deny, cargo-nextest, mbx,
cargo-watch, cargo-edit, Typst, rumdl, and uv. The workspace config also
installs cargo-generate for `wsa`. Performance tools are conditional; see
[Performance testing](#performance-testing).

Cargo-make recipes call `${CARGO_CMD}`, which defaults to `mbx`; cargo-make
drops mise's Cargo wrapper from `PATH`. With the generated mise environment,
plain `cargo` is routed through mbx. To use Cargo directly in a recipe, run
`CARGO_CMD=cargo cargo make <task>`.

Useful local tasks include:

| Command               | Work                                                         |
| --------------------- | ------------------------------------------------------------ |
| `cargo make b`        | Build the current crate.                                     |
| `cargo make t`        | Run tests.                                                   |
| `cargo make A`        | Format, check, lint, build debug and release, and run tests. |
| `cargo make ci-check` | Run the non-mutating CI check recipe.                        |
| `cargo make ci-test`  | Run the non-mutating CI test recipe.                         |

`cargo make format` (alias `f`) formats Rust with nightly Rustfmt, TOML with
Taplo, and `README.md` with rumdl. `cargo make ci-format` checks the same files
without changing them. Markdown tasks target the README explicitly, so formatting
does not rewrite agent instructions or copied third-party documentation.

CI uses separate format, check, clippy, test, release-build, and documentation
recipes: `ci-format`, `ci-check`, `ci-clippy`, `ci-clippy-pedantic`,
`ci-test`, `ci-build-release`, and `ci-doc`. For a target build, put the target
directly after the recipe, with no extra `--`:

```sh
cargo make ci-build-release --target x86_64-unknown-linux-gnu
```

## Optional project support

### Performance testing

`perf_testing` defaults to `false`. When enabled, each crate gets a Criterion
example under `perf/`; for a binary crate it benchmarks standalone example
work, not the binary's private implementation. Run `cargo bench` to execute
it. Mise also installs `cargo:hotpath` with its `tui`, `cloud`, and `utils`
features and `cargo:samply` for CPU profiling. When performance testing is
off, generated projects omit `perf/`, Criterion, and those tools.

For later `wsa` additions, `PERF_TESTING` is forwarded from the saved setting in
the workspace `Makefile.toml`.

### Agent support and docs

`agent_support` defaults to `true`. Generated project roots and workspace
members receive scoped `AGENTS.md` guidance, a `CLAUDE.md` import, and
`.agents/skills/`. OpenCode and oh-my-pi discover the skills directly. When
agent support is off, these files and the agent-only docs setup guide are
omitted. Hotpath skills require both `agent_support` and `perf_testing`.

The `docs-upkeep` skill creates a page with
`uv run scripts/update-docs-index.py --new "<Title>"`, then updates relevant
docs and the index. Mise includes uv for the script's PEP 723 PyYAML
dependency.

## Update an existing project

Run the updater from the existing project's root. It detects the project name,
VCS, and `cli` or `workspace` kind from the checkout; pass `--kind` to choose
the template explicitly. First preview the files that would be added:

```sh
cd /path/to/existing_project
python3 /path/to/rust_template/update-existing.py --dry-run
python3 /path/to/rust_template/update-existing.py
```

The updater renders through cargo-generate and copies only files that do not
already exist. Existing project files are never overwritten. Extra
generate-time values can be passed after `--`, for example:

```sh
python3 /path/to/rust_template/update-existing.py \
  --kind workspace -- -d github_user=your-github-handle
```

## Test the generator

The regression suite requires Python 3.11 or newer and cargo-generate. From
this checkout, run:

```sh
python3 -B -m unittest discover -s tests -v
```

It generates disposable CLI, workspace, and library-member projects, then
checks TOML round-trips, workspace member generation, performance and agent
support gates, docs-index generation, and Liquid rendering. It does not compile
or run the generated applications. Each generated crate includes an
integration smoke test; from a generated project, run `cargo test` and
`cargo clippy --all-targets` to exercise it.

For a non-interactive smoke generation, provide a GitHub owner and linker
profile so hooks skip identity and linker discovery:

```sh
CARGO_GENERATE_VALUE_GITHUB_USER=YOUR_GITHUB_LOGIN cargo generate \
  --path . --name smoke_cli cli --silent --allow-commands \
  -d vcs_kind=none -d linker=default
```

Replace `YOUR_GITHUB_LOGIN` with the actual owner. Keep `rt_details` disabled
or provide all three description values; Rhai prompts are not silenced by
`--silent`, and missing text without a TTY fails clearly.

Template logos and icons are excluded from generated `cli` and `workspace`
projects by `.genignore`. `assets/generate-assets.sh` remains available for
projects that want to create their own assets.

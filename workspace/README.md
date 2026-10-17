<!-- PROJECT LOGO / BANNER -->
<p align="center">
  <img src="assets/README-header.png" alt="{{ crate_name }}" width="100%">
</p>

<p align="center">
  <img src="assets/icon-128.png" alt="{{ crate_name }} icon" width="64">
</p>

<p align="center">
  <strong>{{ crate_name }}</strong> -- {{ tagline }}
  <br>
  <a href="https://crates.io/crates/{{ crate_name }}"><img src="https://img.shields.io/crates/v/{{ crate_name }}" alt="crates.io"></a>
  <a href="https://github.com/{{ github_user }}/{{ repo_name }}/actions/workflows/build.yml"><img src="https://github.com/{{ github_user }}/{{ repo_name }}/actions/workflows/build.yml/badge.svg" alt="build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="license"></a>
  <a href="https://github.com/{{ github_user }}/{{ repo_name }}/releases"><img src="https://img.shields.io/github/v/release/{{ github_user }}/{{ repo_name }}" alt="release"></a>
</p>

<!-- TAGLINE + DESCRIPTION -->
## {{ crate_name }}

{{ long_description }}

```bash
# Quick example
{{ crate_name }} input.txt -o output.txt
```

## Features

- **Feature 1** -- Description
- **Feature 2** -- Description
- **Feature 3** -- Description
- **Cross-platform** -- Linux, macOS, Windows
- **Zero dependencies** -- Single binary, no runtime

## Screenshots

<!-- Add screenshots/GIFs for TUIs/GUIs -->
<!-- ![Demo](assets/demo.gif) -->

## Installation

### Cargo (Recommended)

```bash
cargo install {{ crate_name }}
```

### One-liner (Linux/macOS)

```bash
curl -fsSL https://github.com/{{ github_user }}/{{ repo_name }}/raw/main/build/install.sh | sh
```

Installs to `/usr/local/bin` (or `~/.local/bin` if not writable). Set
`{{ project_name_upper }}_VERSION=vX.Y.Z` to pin a version.

### System Packages

- **Arch**: `pacman -S {{ crate_name }}`
- **macOS**: `brew install {{ crate_name }}`
- **Fedora**: `dnf copr enable {{ github_user }}/{{ crate_name }} && dnf install {{ crate_name }}`
- **NixOS**: `nix-shell -p {{ crate_name }}`
- **Windows**: `winget install {{ crate_name }}`

### Release Archives

Download from [Releases](<https://github.com/{{ github_user }}/{{ repo_name }}/releases/latest>).

Each archive contains:

```text
{{ crate_name }}-<target>-<tag>.zip
  {{ crate_name }}[.exe]
  README.md
  LICENSE
  THIRD_PARTY_NOTICES.md
```

### Supported Targets

| OS      | Arch          | Triple                      |
| ------- | ------------- | --------------------------- |
| Linux   | x86_64        | `x86_64-unknown-linux-gnu`  |
| Linux   | arm64         | `aarch64-unknown-linux-gnu` |
| macOS   | Intel         | `x86_64-apple-darwin`       |
| macOS   | Apple Silicon | `aarch64-apple-darwin`      |
| Windows | x86_64        | `x86_64-pc-windows-msvc`    |

## Usage

```bash
{{ crate_name }} [OPTIONS] <INPUT>
```

### Examples

```bash
# Basic usage
{{ crate_name }} input.txt

# With output file
{{ crate_name }} input.txt -o output.txt

# Dry run (show what would happen)
{{ crate_name }} --dry-run input.txt

# Verbose logging
RUST_LOG=debug {{ crate_name }} input.txt
```

### Flags

| Flag        | Short | Description                      |
| ----------- | ----- | -------------------------------- |
| `--help`    | `-h`  | Show help                        |
| `--version` | `-V`  | Print version                    |
| `--output`  | `-o`  | Output file path                 |
| `--dry-run` |       | Show actions without executing   |
| `--quiet`   | `-q`  | Suppress non-error output        |
| `--verbose` | `-v`  | Verbose output (repeat for more) |

Logging: `RUST_LOG=debug {{ crate_name }} ...` (default: `info`)

## Dependencies

| Tool    | Minimum Version | Install                                         |
| ------- | --------------- | ----------------------------------------------- |
| ffmpeg  | 4.0+            | `pacman -S ffmpeg` / `brew install ffmpeg`      |
| libpcap | 1.9+            | `pacman -S libpcap` / `apt install libpcap-dev` |

## Configuration

Config file at `~/.config/{{ crate_name }}/config.toml`:

```toml
option = "value"
```

Environment variables:

- `{{ project_name_upper }}_LOG=debug` -- Enable debug logging

## How It Works

1. **Step 1** -- Description
2. **Step 2** -- Description
3. **Step 3** -- Description

## Build

For a first build, use a mise-activated shell and install the tools declared in `mise.toml`:

```bash
mise trust && mise install && mise reshim
cargo make b
cargo make t
```

The first build installs the Rust toolchain selected in `rust-toolchain.toml`. Without mbx, use
`CARGO_CMD=cargo cargo make <task>`.

```bash
# Release build
cargo make br

# Run tests
cargo make t

# Run locally
cargo make r
```

## Comparison

- **Feature 1**: supported by {{ crate_name }} and Competitor A; not supported by Competitor B.
- **Feature 2**: supported by {{ crate_name }} and Competitor B; not supported by Competitor A.
- **Feature 3**: supported by {{ crate_name }}, Competitor A, and Competitor B.

## Links

- [Documentation](https://docs.example.com)
- [Discord](https://discord.gg/XXX)
- [Issues](<https://github.com/{{ github_user }}/{{ repo_name }}/issues>)

## License

MIT License -- see [LICENSE](LICENSE).

<!-- PROJECT LOGO / BANNER -->
<p align="center">
  <img src="assets/README-header.png" alt="{{PROJECT_NAME}}" width="100%">
</p>

<p align="center">
  <img src="assets/icon-128.png" alt="{{PROJECT_NAME}} icon" width="64">
</p>

<p align="center">
  <strong>{{PROJECT_NAME}}</strong> -- {{TAGLINE}}
  <br>
  <a href="https://crates.io/crates/{{PROJECT_NAME}}"><img src="https://img.shields.io/crates/v/{{PROJECT_NAME}}" alt="crates.io"></a>
  <a href="https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/actions/workflows/build.yml"><img src="https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/actions/workflows/build.yml/badge.svg" alt="build"></a>
  <a href="LICENSE-MIT"><img src="https://img.shields.io/badge/license-MIT-blue" alt="license"></a>
  <a href="https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/releases"><img src="https://img.shields.io/github/v/release/{{GITHUB_USER}}/{{REPO_NAME}}" alt="release"></a>
</p>

<!-- TAGLINE + DESCRIPTION -->
## {{PROJECT_NAME}}

{{LONG_DESCRIPTION}}

```bash
# Quick example
{{PROJECT_NAME}} input.txt -o output.txt
```

## Features

- **Feature 1** — Description
- **Feature 2** — Description
- **Feature 3** — Description
- **Cross-platform** — Linux, macOS, Windows
- **Zero dependencies** — Single binary, no runtime

## Screenshots

<!-- Add screenshots/GIFs for TUIs/GUIs -->
<!-- ![Demo](assets/demo.gif) -->

## Installation

### Cargo (Recommended)

```bash
cargo install {{PROJECT_NAME}}
```

### One-liner (Linux/macOS)

```bash
curl -fsSL https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/raw/main/build/install.sh | sh
```

Installs to `/usr/local/bin` (or `~/.local/bin` if not writable). Set `{{PROJECT_NAME_UPPER}}_VERSION=vX.Y.Z` to pin a version.

### System Packages

| OS | Command |
|----|---------|
| Arch | `pacman -S {{PROJECT_NAME}}` |
| macOS | `brew install {{PROJECT_NAME}}` |
| Fedora | `dnf copr enable {{GITHUB_USER}}/{{PROJECT_NAME}} && dnf install {{PROJECT_NAME}}` |
| NixOS | `nix-shell -p {{PROJECT_NAME}}` |
| Windows | `winget install {{PROJECT_NAME}}` |

### Release Archives

Download from [Releases](https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/releases/latest).

Each archive contains:

```
{{PROJECT_NAME}}-<target>-<tag>.zip
  {{PROJECT_NAME}}[.exe]
  README.md
  LICENSE-MIT
  LICENSE-APACHE
  THIRD_PARTY_NOTICES.md
```

### Supported Targets

| OS | Arch | Triple |
|----|------|--------|
| Linux | x86_64 | `x86_64-unknown-linux-gnu` |
| Linux | arm64 | `aarch64-unknown-linux-gnu` |
| macOS | Intel | `x86_64-apple-darwin` |
| macOS | Apple Silicon | `aarch64-apple-darwin` |
| Windows | x86_64 | `x86_64-pc-windows-msvc` |

## Usage

```bash
{{PROJECT_NAME}} [OPTIONS] <INPUT>
```

### Examples

```bash
# Basic usage
{{PROJECT_NAME}} input.txt

# With output file
{{PROJECT_NAME}} input.txt -o output.txt

# Dry run (show what would happen)
{{PROJECT_NAME}} --dry-run input.txt

# Verbose logging
RUST_LOG=debug {{PROJECT_NAME}} input.txt
```

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--help` | `-h` | Show help |
| `--version` | `-V` | Print version |
| `--output` | `-o` | Output file path |
| `--dry-run` | | Show actions without executing |
| `--quiet` | `-q` | Suppress non-error output |
| `--verbose` | `-v` | Verbose output (repeat for more) |

Logging: `RUST_LOG=debug {{PROJECT_NAME}} ...` (default: `info`)

## Dependencies

| Tool | Minimum Version | Install |
|------|-----------------|---------|
| ffmpeg | 4.0+ | `pacman -S ffmpeg` / `brew install ffmpeg` |
| libpcap | 1.9+ | `pacman -S libpcap` / `apt install libpcap-dev` |

## Configuration

Config file at `~/.config/{{PROJECT_NAME}}/config.toml`:

```toml
option = "value"
```

Environment variables:
- `{{PROJECT_NAME_UPPER}}_LOG=debug` — Enable debug logging

## How It Works

1. **Step 1** — Description
2. **Step 2** — Description
3. **Step 3** — Description

## Build

```bash
# Release binary
make build          # or: cargo build --release

# Run tests
make test           # or: cargo test

# Run locally
make run            # or: cargo run -- <args>

# Fetch bundled dependencies (ffmpeg, etc.)
./build/fetch-deps.sh <target> <out-dir>
```

## Comparison

| Feature | {{PROJECT_NAME}} | Competitor A | Competitor B |
|---------|-----------------|--------------|--------------|
| Feature 1 | ✅ | ✅ | ❌ |
| Feature 2 | ✅ | ❌ | ✅ |
| Feature 3 | ✅ | ✅ | ✅ |

## Links

- [Documentation](https://docs.example.com)
- [Changelog](CHANGELOG.md)
- [Discord](https://discord.gg/XXX)
- [Issues](https://github.com/{{GITHUB_USER}}/{{REPO_NAME}}/issues)

## License

MIT OR Apache-2.0 — see [LICENSE-MIT](LICENSE-MIT) and [LICENSE-APACHE](LICENSE-APACHE).
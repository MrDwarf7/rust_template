#!/bin/sh
# {{PROJECT_NAME}} installer
#   curl -fsSL https://github.com/MrDwarf7/{{PROJECT_NAME}}.rs/raw/main/build/install.sh | sh
#
# Environment variables:
#   {{PROJECT_NAME_UPPER}}_VERSION   - version tag to install (default: latest)
#   {{PROJECT_NAME_UPPER}}_INSTALL   - install dir (default: /usr/local/bin or ~/.local/bin)
#   GITHUB_TOKEN                    - avoids API rate limits in CI

set -e

REPO="MrDwarf7/{{PROJECT_NAME}}.rs"
RELEASES_URL="https://github.com/$REPO/releases"
BIN="{{PROJECT_NAME}}"
INSTALL_DIR="${{PROJECT_NAME_UPPER}}_INSTALL:-}"

# ---- helpers ----
has_cmd() { command -v "$1" >/dev/null 2>&1; }

cleanup() { [ -n "${tmpdir:-}" ] && rm -rf "$tmpdir"; }
trap cleanup EXIT

die() { echo "install: $*" >&2; exit 1; }
log() { echo "install: $*"; }

# ---- platform detection ----
detect_os() {
    os=$(uname -s)
    case "$os" in
        Linux)  echo linux ;;
        Darwin) echo macos ;;
        MINGW*|MSYS*|CYGWIN*) echo windows ;;
        *) die "unsupported OS: $os (expected Linux, macOS, or Windows)" ;;
    esac
}

detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)   echo x86_64 ;;
        aarch64|arm64)  echo aarch64 ;;
        *) die "unsupported arch: $arch" ;;
    esac
}

os_to_target() {
    case "$1" in
        linux)   echo "unknown-linux-gnu" ;;
        macos)   echo "apple-darwin" ;;
        windows) echo "pc-windows-msvc" ;;
    esac
}

# ---- version resolution ----
fetch_latest_version() {
    auth_arg=""
    [ -n "${GITHUB_TOKEN:-}" ] && auth_arg="-H \"Authorization: Bearer ***\""

    # Try GitHub API first
    api_url="https://api.github.com/repos/$REPO/releases/latest"
    tag=$(eval curl -fsSL "$auth_arg" "$api_url" 2>/dev/null |
        grep '"tag_name"' |
        sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' 2>/dev/null) || \
        tag=""

    # Fallback: follow release/latest redirect
    if [ -z "$tag" ]; then
        tag=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
            "$RELEASES_URL/latest" 2>/dev/null |
            sed -n 's|.*/tag/||p')
    fi

    [ -n "$tag" ] || die "could not resolve latest release. Install via \`cargo install {{PROJECT_NAME}}\` instead."
    echo "$tag"
}

# ---- main ----
os=$(detect_os)
arch=$(detect_arch)
log "detected ${os}/${arch}"

exe=""
[ "$os" = "windows" ] && exe=".exe"

version="${{PROJECT_NAME_UPPER}}_VERSION:-latest}"
[ "$version" = "latest" ] && version=$(fetch_latest_version)
log "version: $version"

ver=$(echo "$version" | sed 's/^v//')
target="${arch}-$(os_to_target "$os")"

# Artifact name per draft.yml: {{PROJECT_NAME}}-<target>-<tag>.zip
artifact="{{PROJECT_NAME}}-${target}-${version}.zip"
download_url="$RELEASES_URL/download/$version/$artifact"
checksum_url="$download_url.sha256"

# Install dir
if [ -z "$INSTALL_DIR" ]; then
    if [ -w "/usr/local/bin" ]; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="$HOME/.local/bin"
    fi
fi
mkdir -p "$INSTALL_DIR"

# Download
tmpdir=$(mktemp -d)
log "downloading $artifact"
curl -fsSL "$download_url" -o "$tmpdir/$artifact"

# Checksum verification (best-effort)
if has_cmd sha256sum; then
    expected=$(curl -fsSL "$checksum_url" 2>/dev/null | awk '{print $1}') || expected=""
    if [ -n "$expected" ]; then
        actual=$(sha256sum "$tmpdir/$artifact" | awk '{print $1}')
        [ "$expected" = "$actual" ] || die "checksum mismatch for $artifact"
        log "checksum verified"
    fi
elif has_cmd shasum; then
    expected=$(curl -fsSL "$checksum_url" 2>/dev/null | awk '{print $1}') || expected=""
    if [ -n "$expected" ]; then
        actual=$(shasum -a 256 "$tmpdir/$artifact" | awk '{print $1}')
        [ "$expected" = "$actual" ] || die "checksum mismatch for $artifact"
        log "checksum verified"
    fi
fi

# Unzip
has_cmd unzip && unzip -qo "$tmpdir/$artifact" -d "$tmpdir/extracted" || \
    die "unzip is required. Install it with your package manager."

# Install binary
src=$(find "$tmpdir/extracted" -type f -name "${BIN}${exe}" 2>/dev/null | head -1)
[ -n "$src" ] || die "binary '${BIN}${exe}' not found in release archive"

mv "$src" "$INSTALL_DIR/$BIN${exe}"
chmod +x "$INSTALL_DIR/$BIN${exe}"
log "installed to $INSTALL_DIR/$BIN${exe}"

# PATH hint
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
*) echo "  note: add $INSTALL_DIR to your PATH if not already" ;;
esac

echo ""
echo "  {{PROJECT_NAME}} $ver installed. Run \`{{PROJECT_NAME}} --help\` to get started."
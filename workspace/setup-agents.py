#!/usr/bin/env python3
"""
setup-agents.py -- Patch AGENTS.md to match the current repo state.

Called at the end of setup.sh (or standalone). Detects the VCS in use,
reads the project name from Cargo.toml, and updates AGENTS.md so its
hard rules and project description are coherent with the actual repo.

Usage:
    python3 setup-agents.py                  # auto-detect everything
    python3 setup-agents.py --name my_project # override project name
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

AGENTS_FILE = Path("AGENTS.md")


def detect_vcs() -> str:
    """Detect which VCS this repo uses. Returns 'jj', 'git', or 'none'."""
    if Path(".jj").is_dir():
        return "jj"
    if Path(".git").is_dir():
        return "git"
    return "none"


def detect_project_name() -> str | None:
    """Try to read the package name from Cargo.toml."""
    cargo = Path("Cargo.toml")
    if not cargo.is_file():
        return None
    text = cargo.read_text(encoding="utf-8")
    m = re.search(r'^name\s*=\s*"([^"]+)"', text, re.MULTILINE)
    return m.group(1) if m else None


def vcs_rule(vcs: str) -> str:
    """Generate the VCS hard-rule line for the given VCS type."""
    if vcs == "jj":
        return (
            "- VCS: this is a `jj` (colocated git) repo. Use `jj` only. "
            "Never run raw `git` here;\n"
            "  it corrupts the jj graph. Do not commit or push unless asked."
        )
    elif vcs == "git":
        return (
            "- VCS: this is a `git` repo. Do not commit or push unless asked."
        )
    else:
        return (
            "- VCS: no version control detected. Initialize with `jj` or `git` "
            "before committing."
        )


def patch_agents(project_name: str, vcs: str) -> bool:
    """Patch AGENTS.md in place. Returns True if changes were made."""
    if not AGENTS_FILE.is_file():
        print(f"Warning: {AGENTS_FILE} not found, skipping.", file=sys.stderr)
        return False

    text = AGENTS_FILE.read_text(encoding="utf-8")
    original = text

    # 1. Replace project name placeholder in the Project section
    text = re.sub(
        r"`[A-Za-z0-9_]+` is a Rust CLI project scaffolded from `rust_template`\.",
        f"`{project_name}` is a Rust CLI project scaffolded from `rust_template`.",
        text,
    )

    # 2. Replace the VCS hard-rule line
    old_vcs_pattern = (
        r"- VCS:.*?(?=\n- [A-Z])"
    )
    new_rule = vcs_rule(vcs)
    text = re.sub(old_vcs_pattern, new_rule, text, flags=re.DOTALL)

    if text == original:
        print("AGENTS.md already up to date.")
        return False

    AGENTS_FILE.write_text(text, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Patch AGENTS.md to match repo state.")
    parser.add_argument("--name", help="Override project name (default: auto-detect from Cargo.toml)")
    args = parser.parse_args()

    # Resolve project name
    project_name = args.name or detect_project_name()
    if not project_name:
        # Fall back to directory name
        project_name = Path.cwd().name
        # Strip .rs suffix like setup.sh does
        if project_name.endswith(".rs"):
            project_name = project_name[:-3]
        project_name = project_name.replace(".", "_")

    vcs = detect_vcs()

    print(f"Project: {project_name}")
    print(f"VCS:     {vcs}")

    changed = patch_agents(project_name, vcs)
    if changed:
        print(f"Patched {AGENTS_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

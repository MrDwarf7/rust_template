#!/usr/bin/env python3
"""
update-existing.py -- Pull scaffolding from rust_template into an existing project.

Copies files that are MISSING from the target project without overwriting
anything that already exists. Reports exactly what was added, skipped,
and why. Then runs setup-agents.py to fix VCS/project-name in AGENTS.md.

Designed for agents updating older projects: instead of brute-force copying
the entire template and manually fixing names, run this script to pull in
only what's missing, then let setup-agents.py handle the rest.

Usage:
    python3 /path/to/rust_template/update-existing.py
    python3 /path/to/rust_template/update-existing.py --template /path/to/template
    python3 /path/to/rust_template/update-existing.py --dry-run

Do not modify this script to fit a non-standard project layout! If the
project structure differs from the template, fix the PROJECT -- not this
script. If conformance changes are complex, stop and ask the user.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

# Files/dirs that are project-specific and should NEVER be synced from template.
NEVER_SYNC = {
    "src",
    "target",
    "Cargo.toml",
    "Cargo.lock",
    "build.rs",
    "README.md",
    "README.template.md",
    "LICENSE",
    "setup.sh",
    "setup.ps1",
    "setup-agents.py",
    "AGENTS.md",  # handled separately by setup-agents.py
}

# Files that are scaffolding infrastructure and should be synced.
# Everything else is "maybe sync if missing."
SYNC_DIRS = {
    ".github",
    "build",
    "docs",
    "scripts",
    "data",
    "scratch",
}

# Root-level config files to sync if missing.
SYNC_ROOT_FILES = {
    ".gitignore",
    ".gitattributes",
    ".rustfmt.toml",
    ".taplo.toml",
    "bacon.toml",
    "cliff.toml",
    "deny.toml",
    "Makefile.toml",
    "rust-toolchain.toml",
}


def detect_project_name(target: Path) -> str | None:
    """Read package name from target's Cargo.toml."""
    cargo = target / "Cargo.toml"
    if not cargo.is_file():
        return None
    import re
    text = cargo.read_text(encoding="utf-8")
    m = re.search(r'^name\s*=\s*"([^"]+)"', text, re.MULTILINE)
    return m.group(1) if m else None


def collect_template_files(template: Path) -> list[Path]:
    """Collect all files from the template, relative to template root."""
    files = []
    for path in sorted(template.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(template)
        parts = rel.parts

        # Skip .git, target, .jj
        if parts[0] in (".git", ".jj", "target"):
            continue

        # Skip NEVER_SYNC items
        if parts[0] in NEVER_SYNC:
            continue
        if rel.name in NEVER_SYNC:
            continue

        files.append(rel)
    return files


def classify_files(
    template_files: list[Path], template: Path, target: Path
) -> dict[str, list[Path]]:
    """Classify template files as new (to copy) or existing (to skip)."""
    new_files = []
    existing_files = []

    for rel in template_files:
        target_path = target / rel
        if target_path.exists():
            existing_files.append(rel)
        else:
            new_files.append(rel)

    return {"new": new_files, "existing": existing_files}


def copy_new_files(
    new_files: list[Path], template: Path, target: Path, dry_run: bool
) -> int:
    """Copy new files from template to target. Returns count of files copied."""
    count = 0
    for rel in new_files:
        src = template / rel
        dst = target / rel
        if dry_run:
            print(f"  [dry-run] Would copy: {rel}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  [new] {rel}")
        count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Pull scaffolding from rust_template into an existing project."
    )
    parser.add_argument(
        "--template",
        help="Path to rust_template (default: auto-detect from script location)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would be copied without actually copying.",
    )
    args = parser.parse_args()

    # Resolve paths
    target = Path.cwd()
    if args.template:
        template = Path(args.template).resolve()
    else:
        # Default: assume sibling directory or parent's rust_template
        template = Path(__file__).resolve().parent

    if not template.is_dir():
        print(f"Error: template directory not found: {template}", file=sys.stderr)
        return 1

    project_name = detect_project_name(target) or target.name
    print(f"Target:   {target} ({project_name})")
    print(f"Template: {template}")
    if args.dry_run:
        print("Mode:     DRY RUN (no files will be copied)")
    print()

    # Collect and classify
    template_files = collect_template_files(template)
    classified = classify_files(template_files, template, target)

    new_files = classified["new"]
    existing_files = classified["existing"]

    # Report existing (skipped)
    if existing_files:
        print(f"EXISTS ({len(existing_files)} files, skipped):")
        for f in existing_files:
            print(f"  [skip] {f}")
        print()

    # Report new (to copy)
    if new_files:
        print(f"NEW ({len(new_files)} files, will copy):")
        copied = copy_new_files(new_files, template, target, args.dry_run)
        print()
    else:
        print("No new files to copy -- project is up to date.")
        print()
        copied = 0

    # Ensure AGENTS.md exists so setup-agents.py can patch it.
    # AGENTS.md is in NEVER_SYNC (never blindly copied), but we need the
    # template version as a base if the target doesn't have one yet.
    agents_template = template / "AGENTS.md"
    agents_target = target / "AGENTS.md"
    if not agents_target.exists() and agents_template.is_file():
        if args.dry_run:
            print("  [dry-run] Would create: AGENTS.md (from template)")
        else:
            shutil.copy2(agents_template, agents_target)
            print("  [new] AGENTS.md (template base, will be patched below)")

    # Run setup-agents.py to fix AGENTS.md
    setup_agents = template / "setup-agents.py"
    if setup_agents.is_file() and not args.dry_run:
        print("Running setup-agents.py to update AGENTS.md...")
        import subprocess
        r = subprocess.run(
            [sys.executable, str(setup_agents)],
            capture_output=True, text=True, cwd=target,
        )
        if r.stdout:
            print(f"  {r.stdout.strip()}")
        if r.returncode != 0:
            print(f"  Warning: setup-agents.py exited with code {r.returncode}")
            if r.stderr:
                print(f"  {r.stderr.strip()}")
        print()

    # Summary
    print("=" * 50)
    print(f"Summary: {copied} files copied, {len(existing_files)} skipped")
    if not args.dry_run and copied > 0:
        print()
        print("Next steps:")
        print("  1. Review the new files above")
        print("  2. Run scripts/update-docs-index.py if docs/ changed")
        print("  3. Run `cargo make A` to verify the build")
    return 0


if __name__ == "__main__":
    sys.exit(main())

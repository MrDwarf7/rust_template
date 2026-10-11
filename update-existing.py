#!/usr/bin/env python3
"""
update-existing.py -- Pull rust_template scaffolding into an existing project.

Renders the matching sub-template with cargo-generate (so placeholders,
AGENTS.md VCS rules, etc. come out filled in), then copies only the files
the target project is MISSING. Nothing that already exists is overwritten.

Run from the target project's root:

    python3 /path/to/rust_template_cargo_generate/update-existing.py
    python3 .../update-existing.py --dry-run
    python3 .../update-existing.py --kind workspace -- -d github_user=someone

Arguments after `--` go straight to `cargo generate` (e.g. `-d key=value`).

Do not modify this script to fit a non-standard project layout! If the
project structure differs from the template, fix the PROJECT -- not this
script. If conformance changes are complex, stop and ask the user.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Literal

TEMPLATE_ROOT = Path(__file__).resolve().parent

Kind = Literal["cli", "workspace"]
Vcs = Literal["jj", "git", "none"]

# Project-specific paths (relative to the project root): never synced.
NEVER_SYNC = frozenset({
    ".git",
    ".jj",
    "target",
    "src",
    "crates",
    "Cargo.toml",
    "Cargo.lock",
    "build.rs",
    "README.md",
    "LICENSE",
})


def read_manifest(target: Path) -> dict:
    manifest = target / "Cargo.toml"
    if not manifest.is_file():
        return {}
    return tomllib.loads(manifest.read_text(encoding="utf-8"))


def detect_kind(manifest: dict) -> Kind:
    return "workspace" if "workspace" in manifest and "package" not in manifest else "cli"


def detect_name(manifest: dict, target: Path) -> str:
    name = manifest.get("package", {}).get("name")
    if name:
        return name
    return target.name.removesuffix(".rs").replace(".", "_")


def detect_vcs(target: Path) -> Vcs:
    if (target / ".jj").is_dir():
        return "jj"
    if (target / ".git").exists():
        return "git"
    return "none"


def render(kind: Kind, name: str, vcs: Vcs, out_dir: Path, extra: list[str]) -> Path:
    """Expand the sub-template into out_dir/<name> and return that path."""
    cmd = [
        "cargo", "generate",
        "--path", str(TEMPLATE_ROOT), kind,
        "--name", name,
        "--destination", str(out_dir),
        "--silent",
        # VCS init (in the throwaway dir) is the only command the hooks need.
        "--allow-commands",
        "--vcs", "none",
        "-d", f"vcs_kind={vcs}",
        *extra,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"cargo generate failed:\n{result.stdout}{result.stderr}")
    return out_dir / name


def missing_files(rendered: Path, target: Path) -> tuple[list[Path], list[Path]]:
    """Split synced template files into (missing in target, already present)."""
    missing, present = [], []
    for path in sorted(rendered.rglob("*")):
        rel = path.relative_to(rendered)
        if not path.is_file() or rel.parts[0] in NEVER_SYNC:
            continue
        (present if (target / rel).exists() else missing).append(rel)
    return missing, present


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--kind", choices=["cli", "workspace"],
                        help="Sub-template to sync from (default: detect from Cargo.toml)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Report what would be copied without copying")
    parser.add_argument("extra", nargs=argparse.REMAINDER,
                        help="Extra `cargo generate` args, after `--`")
    args = parser.parse_args()
    extra = args.extra[1:] if args.extra[:1] == ["--"] else args.extra

    if shutil.which("cargo-generate") is None:
        sys.exit("cargo-generate not found: cargo install --locked cargo-generate")

    target = Path.cwd()
    manifest = read_manifest(target)
    kind: Kind = args.kind or detect_kind(manifest)
    name = detect_name(manifest, target)
    vcs = detect_vcs(target)

    print(f"Target:   {target} ({name}, {kind}, vcs={vcs})")
    print(f"Template: {TEMPLATE_ROOT}/{kind}")
    if args.dry_run:
        print("Mode:     DRY RUN (no files will be copied)")
    print()

    with tempfile.TemporaryDirectory(prefix="rust_template-") as tmp:
        rendered = render(kind, name, vcs, Path(tmp), extra)
        missing, present = missing_files(rendered, target)

        if present:
            print(f"EXISTS ({len(present)} files, skipped):")
            for rel in present:
                print(f"  [skip] {rel}")
            print()

        if not missing:
            print("No new files to copy -- project is up to date.")
            return 0

        print(f"NEW ({len(missing)} files):")
        for rel in missing:
            if args.dry_run:
                print(f"  [dry-run] would copy {rel}")
                continue
            (target / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(rendered / rel, target / rel)
            print(f"  [new] {rel}")

    print()
    print(f"Summary: {len(missing)} new, {len(present)} skipped")
    if not args.dry_run:
        print("Next steps:")
        print("  1. Review the new files above")
        print("  2. Run scripts/update-docs-index.py if docs/ changed")
        print("  3. Run `cargo make A` to verify the build")
    return 0


if __name__ == "__main__":
    sys.exit(main())

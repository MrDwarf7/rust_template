import json
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[1]
DESCRIPTION = (
    'Quotes: " and backslash: \\; Unicode: café 🧪; controls: '
    + "".join(chr(code) for code in range(32))
    + chr(127)
    + "; end"
)
GITHUB_USER = 'Owner "quoted" \\ path'


@unittest.skipUnless(shutil.which("cargo-generate"), "cargo-generate is required")
class GenerationDescriptionTest(unittest.TestCase):
    def test_descriptions_round_trip_in_every_generation_path(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-description-") as temporary:
            temporary = Path(temporary)
            values_file = temporary / "values.txt"

            def toml_value(value):
                return json.dumps(value, ensure_ascii=False).replace(chr(127), r"\u007f")

            def write_values(**overrides):
                values = {
                    "github_user": GITHUB_USER,
                    "short_description": DESCRIPTION,
                    "vcs_kind": "none",
                    "linker": "default",
                }
                values.update(overrides)
                values_file.write_text(
                    "[values]\n"
                    + "".join(
                        f"{key}={toml_value(value)}\n"
                        for key, value in values.items()
                    ),
                    encoding="utf-8",
                )

            def generate(name, subtemplate, destination, generation_args=(), **options):
                write_values(**options)
                Path(destination).mkdir(parents=True, exist_ok=True)
                result = subprocess.run(
                    [
                        "cargo", "generate", "--path", str(REPOSITORY), subtemplate,
                        "--name", name, "--destination", str(destination),
                        *generation_args,
                        "--silent", "--allow-commands", "--vcs", "none",
                        "--values-file", str(values_file),
                    ],
                    cwd=temporary,
                    capture_output=True,
                    text=True,
                    timeout=120,
                    check=False,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"cargo generate {subtemplate} failed ({result.returncode})\n"
                    f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
                )
                return Path(destination) / name

            def assert_manifest(manifest_path, include_windows_metadata=True):
                with manifest_path.open("rb") as manifest_file:
                    manifest = tomllib.load(manifest_file)
                self.assertEqual(manifest["package"]["description"], DESCRIPTION)
                if include_windows_metadata:
                    metadata = manifest["package"]["metadata"]["winresource"]
                    self.assertEqual(metadata["FileDescription"], DESCRIPTION)
                    self.assertEqual(metadata["LegalCopyright"], f"Copyright (c) {GITHUB_USER}")

            cli = generate("description-cli", "cli", temporary / "cli")
            assert_manifest(cli / "Cargo.toml")

            workspace = generate(
                "description-workspace",
                "workspace",
                temporary / "workspace",
                extra_crates="extra_member",
                use_trim_paths=True,
                use_cranelift=False,
            )
            assert_manifest(workspace / "crates" / "description_workspace" / "Cargo.toml")
            assert_manifest(workspace / "crates" / "extra_member" / "Cargo.toml")

            bin_crate = generate(
                "description-bin",
                "ws_crate",
                workspace / "crates",
                generation_args=("--bin",),
            )
            lib_crate = generate(
                "description-lib",
                "ws_crate",
                workspace / "crates",
                generation_args=("--lib",),
            )
            assert_manifest(bin_crate / "Cargo.toml")
            assert_manifest(lib_crate / "Cargo.toml", include_windows_metadata=False)
            self.assertTrue((bin_crate / "src" / "main.rs").is_file())
            self.assertFalse((bin_crate / "src" / "lib.rs").exists())
            self.assertTrue((lib_crate / "src" / "lib.rs").is_file())
            self.assertFalse((lib_crate / "src" / "main.rs").exists())

            with (workspace / "Cargo.toml").open("rb") as manifest_file:
                workspace_manifest = tomllib.load(manifest_file)
            self.assertEqual(workspace_manifest["profile"]["dev"]["trim-paths"], "none")
            self.assertEqual(workspace_manifest["profile"]["release"]["trim-paths"], "object")


if __name__ == "__main__":
    unittest.main()

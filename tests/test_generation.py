import os
import json
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[1]
DESCRIPTION = (
    'Quotes: " and backslash: \\; Unicode: caf\u00e9 \U0001f9ea; controls: '
    + "".join(chr(code) for code in range(32))
    + chr(127)
    + "; end"
)
GITHUB_USER = 'Owner "quoted" \\ path'


def toml_value(value):
    return json.dumps(value, ensure_ascii=False).replace(chr(127), r"\u007f")


def generate(case, temporary, name, subtemplate, destination, environment=None, **options):
    values = {
        "github_user": GITHUB_USER,
        "short_description": DESCRIPTION,
        "vcs_kind": "none",
        "linker": "default",
    }
    values.update(options)
    values = {key: value for key, value in values.items() if value is not None}
    values_file = temporary / "values.txt"
    values_file.write_text(
        "[values]\n" + "".join(f"{key}={toml_value(value)}\n" for key, value in values.items()),
        encoding="utf-8",
    )
    Path(destination).mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            "cargo", "generate", "--path", str(REPOSITORY), subtemplate,
            "--name", name, "--destination", str(destination),
            "--silent", "--allow-commands", "--vcs", "none",
            "--values-file", str(values_file),
        ],
        cwd=temporary,
        env={**os.environ, **(environment or {})},
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    case.assertEqual(
        result.returncode,
        0,
        f"cargo generate {subtemplate} failed ({result.returncode})\n"
        f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
    )
    return Path(destination) / name


def assert_manifest(case, manifest_path, include_windows_metadata=True):
    with manifest_path.open("rb") as manifest_file:
        manifest = tomllib.load(manifest_file)
    case.assertEqual(manifest["package"]["description"], DESCRIPTION)
    if include_windows_metadata:
        metadata = manifest["package"]["metadata"]["winresource"]
        case.assertEqual(metadata["FileDescription"], DESCRIPTION)
        case.assertEqual(metadata["LegalCopyright"], f"Copyright (c) {GITHUB_USER}")
    else:
        case.assertNotIn("winresource", manifest["package"].get("metadata", {}))


def assert_project_tooling(case, project, includes_generator=False, crate_prefix=None, perf_testing=False):
    with (project / "mise.toml").open("rb") as mise_file:
        mise_config = tomllib.load(mise_file)
    with (project / ".mbx.toml").open("rb") as mbx_file:
        mbx_config = tomllib.load(mbx_file)
    with (project / ".rumdl.toml").open("rb") as rumdl_file:
        rumdl_config = tomllib.load(rumdl_file)
    tools = mise_config["tools"]
    case.assertEqual(mise_config["wrappers"]["cargo"]["command"], "mbx")
    case.assertIn("mr-boxington", tools)
    case.assertIn("cargo:rumdl", tools)
    case.assertEqual(tools["uv"], "latest")
    case.assertNotIn("rust", tools)
    case.assertTrue(
        all(version == "latest" for version in tools.values() if isinstance(version, str))
    )
    case.assertEqual(mise_config["settings"]["minimum_release_age"], "24h")
    case.assertEqual(mbx_config["linker"]["default"], "system")
    case.assertEqual(rumdl_config["MD013"]["line-length"], 100)
    case.assertEqual("cargo:cargo-generate" in tools, includes_generator)
    case.assertEqual("cargo:samply" in tools, perf_testing)
    case.assertEqual("cargo:hotpath" in tools, perf_testing)
    if perf_testing:
        case.assertEqual(tools["cargo:hotpath"]["version"], "latest")
        case.assertEqual(tools["cargo:hotpath"]["features"], ["tui", "cloud", "utils"])
    if crate_prefix is not None:
        case.assertEqual(mise_config["env"]["CRATE_PREFIX"], crate_prefix)


def assert_perf_crate(case, project, enabled):
    with (project / "Cargo.toml").open("rb") as manifest_file:
        manifest = tomllib.load(manifest_file)
    case.assertEqual("criterion" in manifest.get("dev-dependencies", {}), enabled)
    case.assertEqual((project / "perf").is_dir(), enabled)
    case.assertTrue((project / "tests").is_dir())
    case.assertEqual(len(list((project / "tests").glob("*.rs"))), 1)
    return manifest


def assert_agent_files(case, project, enabled, perf_testing=False):
    agents = project / "AGENTS.md"
    claude = project / "CLAUDE.md"
    skills = project / ".agents" / "skills"
    case.assertEqual(agents.is_file(), enabled)
    case.assertEqual(claude.is_file(), enabled)
    case.assertEqual(skills.is_dir(), enabled)

    for name in (
        "hotpath-init",
        "hotpath-cloud",
        "hotpath-init-ci",
        "hotpath-init-ci-forks",
    ):
        skill = skills / name / "SKILL.md"
        case.assertEqual(skill.is_file(), enabled and perf_testing)
        if skill.is_file():
            skill_text = skill.read_text(encoding="utf-8")
            case.assertNotIn("{% raw %}", skill_text)
            case.assertNotIn("{% endraw %}", skill_text)
            if name == "hotpath-init-ci":
                case.assertIn("${{ runner.os }}", skill_text)

    if enabled:
        case.assertEqual(claude.read_text(encoding="utf-8").strip(), "@AGENTS.md")
        agent_text = agents.read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", agent_text):
            case.assertTrue((project / target).is_file(), f"{agents} has a dangling reference: {target}")

    docs_dir = project / "docs"
    docs_index = docs_dir / "INDEX.md"
    if docs_index.is_file():
        index_text = docs_index.read_text(encoding="utf-8")
        case.assertEqual((docs_dir / "00_AGENT_DOCS_SETUP.md").is_file(), enabled)
        case.assertEqual("00_AGENT_DOCS_SETUP.md" in index_text, enabled)
        for target in re.findall(r"\]\(([^)]+\.md)\)", index_text):
            case.assertTrue((docs_dir / target).is_file(), f"{docs_index} has a dangling reference: {target}")


def assert_member_agent_files(case, crate, enabled):
    agents = crate / "AGENTS.md"
    case.assertEqual(agents.is_file(), enabled)
    case.assertEqual((crate / "CLAUDE.md").is_file(), enabled)
    case.assertEqual((crate / ".agents").is_dir(), enabled)
    if enabled:
        case.assertEqual((crate / "CLAUDE.md").read_text(encoding="utf-8").strip(), "@AGENTS.md")
        agent_text = agents.read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", agent_text):
            case.assertTrue((crate / target).is_file(), f"{agents} has a dangling reference: {target}")


def assert_no_liquid(case, project):
    for path in project.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(project).as_posix()
        if relative == "cliff.toml":
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        text = re.sub(r"\$\{\{[^}]*\}\}", "", text)
        case.assertNotRegex(text, r"\{\{|\{%")


def assert_docs_script(case, project):
    script = project / "scripts" / "update-docs-index.py"
    script_text = script.read_text(encoding="utf-8")
    case.assertIn('# dependencies = ["pyyaml"]', script_text)
    if not shutil.which("uv"):
        return
    for arguments in (("--check",), ("--new", "Test Doc"), ()):
        result = subprocess.run(
            ["uv", "run", "scripts/update-docs-index.py", *arguments],
            cwd=project,
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
        case.assertEqual(
            result.returncode,
            0,
            f"docs script failed: {arguments}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
    new_doc = project / "docs" / "01_test-doc.md"
    case.assertTrue(new_doc.is_file())
    doc_text = new_doc.read_text(encoding="utf-8")
    case.assertIn('title: "Test Doc"\n', doc_text)
    case.assertIn('description: "TODO: Add a one-line summary."\n', doc_text)
    case.assertIn("keywords: []\n", doc_text)
    case.assertIn("order: 1\n", doc_text)
    case.assertIn(
        "[Test Doc](01_test-doc.md)",
        (project / "docs" / "INDEX.md").read_text(encoding="utf-8"),
    )


@unittest.skipUnless(shutil.which("cargo-generate"), "cargo-generate is required")
class GenerationDescriptionTest(unittest.TestCase):
    def test_cli_description_round_trip(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-description-") as directory:
            temporary = Path(directory)
            cli = generate(self, temporary, "description-cli", "cli", temporary / "cli")
            assert_manifest(self, cli / "Cargo.toml")
            assert_project_tooling(self, cli)
            self.assertNotIn("criterion", (cli / "Cargo.toml").read_text(encoding="utf-8"))
            self.assertIn(
                "binary_runs_successfully",
                (cli / "tests" / "cli.rs").read_text(encoding="utf-8"),
            )

    def test_names_are_preserved_verbatim(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-names-") as directory:
            temporary = Path(directory)
            cli = generate(self, temporary, "my-app", "cli", temporary / "cli")
            with (cli / "Cargo.toml").open("rb") as manifest_file:
                self.assertEqual(tomllib.load(manifest_file)["package"]["name"], "my-app")
            self.assertIn(
                'env!("CARGO_BIN_EXE_my-app")',
                (cli / "tests" / "cli.rs").read_text(encoding="utf-8"),
            )

            workspace = generate(
                self,
                temporary,
                "acme-core",
                "workspace",
                temporary / "workspace",
                crate_prefix="acme",
                extra_crates="api, acme_db",
            )
            for crate_name in ("acme-core", "acme-api", "acme_db"):
                crate = workspace / "crates" / crate_name
                with (crate / "Cargo.toml").open("rb") as manifest_file:
                    self.assertEqual(tomllib.load(manifest_file)["package"]["name"], crate_name)
                self.assertIn(
                    f'env!("CARGO_BIN_EXE_{crate_name}")',
                    (crate / "tests" / "cli.rs").read_text(encoding="utf-8"),
                )

            underscored = generate(
                self, temporary, "my_ws", "workspace", temporary / "workspace-underscore"
            )
            with (underscored / "crates" / "my_ws" / "Cargo.toml").open("rb") as manifest_file:
                self.assertEqual(tomllib.load(manifest_file)["package"]["name"], "my_ws")

    def test_workspace_and_library_description_round_trip(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-description-") as directory:
            temporary = Path(directory)
            workspace = generate(
                self,
                temporary,
                "description-workspace",
                "workspace",
                temporary / "workspace",
                extra_crates="extra_member",
                crate_prefix="acme",
                use_trim_paths=True,
            )
            assert_project_tooling(self, workspace, includes_generator=True, crate_prefix="acme")
            self.assertNotIn("criterion", (workspace / "Cargo.toml").read_text(encoding="utf-8"))
            assert_manifest(self, workspace / "crates" / "description-workspace" / "Cargo.toml")
            assert_manifest(self, workspace / "crates" / "acme-extra_member" / "Cargo.toml")

            lib_crate = generate(
                self, temporary, "description-lib", "ws_crate", workspace / "crates"
            )
            assert_manifest(self, lib_crate / "Cargo.toml", include_windows_metadata=False)
            self.assertTrue((lib_crate / "src" / "lib.rs").is_file())
            self.assertFalse((lib_crate / "src" / "main.rs").exists())
            self.assertFalse((lib_crate / "build.rs").exists())
            self.assertFalse((lib_crate / "assets").exists())
            lib_source = (lib_crate / "src" / "lib.rs").read_text(encoding="utf-8")
            self.assertIn("mod error;", lib_source)
            self.assertNotIn("pub mod error;", lib_source)
            self.assertNotIn("pub mod prelude;", lib_source)
            self.assertIn("mod prelude;", lib_source)
            self.assertIn(
                "pub use crate::error::{Error as DescriptionLibError, Result as DescriptionLibResult};",
                lib_source,
            )
            self.assertNotIn("pub use crate::error::{Error, Result};", lib_source)
            prelude_source = (lib_crate / "src" / "prelude.rs").read_text(encoding="utf-8")
            self.assertIn("use crate::error::{Error, Result};", prelude_source)
            self.assertNotIn("pub use crate::error", prelude_source)
            self.assertIn(
                "exported_error_and_result_are_usable",
                (lib_crate / "tests" / "public_api.rs").read_text(encoding="utf-8"),
            )

            prefixed_crate = generate(
                self,
                temporary,
                "acme-authentication",
                "ws_crate",
                workspace / "crates",
                crate_prefix="acme",
            )
            assert_manifest(self, prefixed_crate / "Cargo.toml", include_windows_metadata=False)
            prefixed_source = (prefixed_crate / "src" / "lib.rs").read_text(encoding="utf-8")
            self.assertIn(
                "pub use crate::error::{Error as AuthenticationError, Result as AuthenticationResult};",
                prefixed_source,
            )
            self.assertNotIn("pub use crate::error::{Error, Result};", prefixed_source)

            with (workspace / "Cargo.toml").open("rb") as manifest_file:
                manifest = tomllib.load(manifest_file)
            self.assertEqual(manifest["profile"]["dev"]["trim-paths"], "none")
            self.assertEqual(manifest["profile"]["release"]["trim-paths"], "object")


@unittest.skipUnless(shutil.which("cargo-generate"), "cargo-generate is required")
class PerformanceTestingGenerationTest(unittest.TestCase):
    def test_performance_placeholder_across_templates(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-perf-") as directory:
            temporary = Path(directory)
            cli_off = generate(
                self, temporary, "perf-cli-off", "cli", temporary / "cli-off",
                perf_testing=False,
            )
            assert_perf_crate(self, cli_off, enabled=False)
            cli_on = generate(
                self, temporary, "perf-cli-on", "cli", temporary / "cli-on",
                perf_testing=True,
            )
            assert_perf_crate(self, cli_on, enabled=True)
            assert_project_tooling(self, cli_on, perf_testing=True)

            workspace_off = generate(
                self, temporary, "perf-workspace-off", "workspace", temporary / "workspace-off",
                extra_crates="extra_member", perf_testing=False,
            )
            for member in ("perf-workspace-off", "extra_member"):
                assert_perf_crate(self, workspace_off / "crates" / member, enabled=False)
            self.assertNotIn("criterion", (workspace_off / "Cargo.toml").read_text(encoding="utf-8"))
            generate(
                self, temporary, "perf-lib-off", "ws_crate", workspace_off / "crates",
                perf_testing=False,
            )
            assert_perf_crate(self, workspace_off / "crates" / "perf-lib-off", enabled=False)

            workspace_on = generate(
                self, temporary, "perf-workspace-on", "workspace", temporary / "workspace-on",
                extra_crates="extra_member", perf_testing=True,
            )
            assert_project_tooling(self, workspace_on, includes_generator=True, perf_testing=True)
            with (workspace_on / "Cargo.toml").open("rb") as manifest_file:
                manifest = tomllib.load(manifest_file)
            self.assertIn("criterion", manifest["workspace"]["dependencies"])
            for member in ("perf-workspace-on", "extra_member"):
                assert_perf_crate(self, workspace_on / "crates" / member, enabled=True)
            self.assertIn(
                "binary_runs_successfully",
                (workspace_on / "crates" / "extra_member" / "tests" / "cli.rs").read_text(encoding="utf-8"),
            )
            lib_on = generate(
                self, temporary, "perf-lib-on", "ws_crate", workspace_on / "crates",
                perf_testing=True,
            )
            assert_perf_crate(self, lib_on, enabled=True)
            self.assertNotIn(
                "{{", (lib_on / "tests" / "public_api.rs").read_text(encoding="utf-8")
            )


@unittest.skipUnless(shutil.which("cargo-generate"), "cargo-generate is required")
class AgentSupportGenerationTest(unittest.TestCase):
    def test_cli_agent_support_modes(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-agents-") as directory:
            temporary = Path(directory)
            cli_off = generate(
                self, temporary, "agent-cli-off", "cli", temporary / "cli-off",
                agent_support=False, perf_testing=False,
            )
            assert_agent_files(self, cli_off, enabled=False)
            assert_no_liquid(self, cli_off)
            assert_docs_script(self, cli_off)
            assert_agent_files(self, cli_off, enabled=False)

            cli_on = generate(
                self, temporary, "agent-cli-on", "cli", temporary / "cli-on",
                agent_support=True, perf_testing=False,
            )
            assert_agent_files(self, cli_on, enabled=True)
            assert_docs_script(self, cli_on)
            assert_no_liquid(self, cli_on)

            cli_perf = generate(
                self, temporary, "agent-cli-perf", "cli", temporary / "cli-perf",
                agent_support=True, perf_testing=True,
            )
            assert_agent_files(self, cli_perf, enabled=True, perf_testing=True)
            assert_no_liquid(self, cli_perf)

    def test_workspace_and_member_agent_support_modes(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-agents-") as directory:
            temporary = Path(directory)
            workspace_off = generate(
                self, temporary, "agent-workspace-off", "workspace", temporary / "workspace-off",
                extra_crates="extra_member", agent_support=False, perf_testing=False,
            )
            assert_agent_files(self, workspace_off, enabled=False)
            assert_member_agent_files(self, workspace_off / "crates" / "agent-workspace-off", enabled=False)
            assert_member_agent_files(self, workspace_off / "crates" / "extra_member", enabled=False)
            assert_no_liquid(self, workspace_off)
            lib_off = generate(
                self, temporary, "agent-lib-off", "ws_crate", workspace_off / "crates",
                agent_support=False, perf_testing=False,
            )
            assert_member_agent_files(self, lib_off, enabled=False)

            workspace_on = generate(
                self, temporary, "agent-workspace-on", "workspace", temporary / "workspace-on",
                extra_crates="extra_member", agent_support=True, perf_testing=True,
            )
            assert_agent_files(self, workspace_on, enabled=True, perf_testing=True)
            assert_docs_script(self, workspace_on)
            assert_no_liquid(self, workspace_on)
            for member in ("agent-workspace-on", "extra_member"):
                assert_member_agent_files(self, workspace_on / "crates" / member, enabled=True)
            lib_on = generate(
                self, temporary, "agent-lib-on", "ws_crate", workspace_on / "crates",
                agent_support=True, perf_testing=True,
            )
            assert_member_agent_files(self, lib_on, enabled=True)
            assert_no_liquid(self, lib_on)


@unittest.skipUnless(shutil.which("cargo-generate"), "cargo-generate is required")
class OnboardingGenerationTest(unittest.TestCase):
    def test_defaults_and_explicit_opt_outs(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-onboarding-") as directory:
            temporary = Path(directory)
            for kind in ("cli", "workspace"):
                project = generate(self, temporary, f"default-{kind}", kind, temporary)
                self.assertTrue((project / "AGENTS.md").is_file())
                self.assertFalse((project / "data").exists())
                self.assertFalse((project / "scratch").exists())
                with (project / "Cargo.toml").open("rb") as manifest_file:
                    manifest = tomllib.load(manifest_file)
                self.assertEqual(manifest["profile"]["release"]["trim-paths"], "object")
                with (project / ".mbx.toml").open("rb") as mbx_file:
                    linker = tomllib.load(mbx_file)["linker"]
                self.assertEqual(linker["profiles"]["dev"]["default"], "system")
                self.assertEqual(linker["profiles"]["dev"]["x86_64-unknown-linux-gnu"], "system")
                self.assertEqual(linker["profiles"]["dev"]["aarch64-apple-darwin"], "system")
                self.assertEqual(linker["profiles"]["release"]["default"], "system")
                self.assertEqual(linker["profiles"]["release"]["x86_64-unknown-linux-gnu"], "system")
                self.assertEqual(linker["profiles"]["release"]["aarch64-unknown-linux-gnu"], "system")
                self.assertEqual(linker["profiles"]["release"]["x86_64-apple-darwin"], "system")
                self.assertEqual(linker["profiles"]["release"]["aarch64-apple-darwin"], "system")

                opted_out = generate(
                    self, temporary, f"opt-out-{kind}", kind, temporary,
                    agent_support=False, use_trim_paths=False, keep_dev_dirs=True,
                )
                self.assertFalse((opted_out / "AGENTS.md").exists())
                self.assertTrue((opted_out / "data").is_dir())
                self.assertTrue((opted_out / "scratch").is_dir())
                with (opted_out / "Cargo.toml").open("rb") as manifest_file:
                    manifest = tomllib.load(manifest_file)
                self.assertNotIn("trim-paths", manifest["profile"]["release"])

    def test_environment_preferences_and_explicit_metadata(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-preferences-") as directory:
            temporary = Path(directory)
            project = generate(
                self, temporary, "pref-app", "cli", temporary,
                environment={
                    "CARGO_GENERATE_VALUE_USE_RS_SUFFIX": "yes",
                    "CARGO_GENERATE_VALUE_RT_DETAILS": "on",
                },
                tagline="Provided tagline",
                long_description="Provided long description",
                linker="wild",
            )
            readme = (project / "README.md").read_text(encoding="utf-8")
            self.assertIn("Provided tagline", readme)
            self.assertIn("Provided long description", readme)
            self.assertIn("pref_app.rs", readme)
            with (project / ".mbx.toml").open("rb") as mbx_file:
                linker = tomllib.load(mbx_file)["linker"]
            self.assertEqual(linker["profiles"]["dev"]["x86_64-unknown-linux-gnu"], "wild@0.10.0")
            self.assertEqual(linker["profiles"]["release"]["default"], "system")
            self.assertEqual(linker["profiles"]["release"]["x86_64-unknown-linux-gnu"], "system")
            self.assertEqual(linker["profiles"]["dev"]["default"], "system")
            self.assertEqual(linker["profiles"]["dev"]["x86_64-apple-darwin"], "system")


    def test_github_owner_environment_preference(self):
        with tempfile.TemporaryDirectory(prefix="cargo-generate-owner-") as directory:
            temporary = Path(directory)
            project = generate(
                self, temporary, "env-owner-app", "cli", temporary,
                environment={"CARGO_GENERATE_VALUE_GITHUB_USER": "environment-owner"},
                github_user=None,
            )
            readme = (project / "README.md").read_text(encoding="utf-8")
            self.assertIn("https://github.com/environment-owner/env-owner-app/", readme)

if __name__ == "__main__":
    unittest.main()

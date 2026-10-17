// post (workspace): member manifests + extra member crates. Runs before
// hooks/finish.rhai.
//
// Every member's Cargo.toml is written here, from one Rhai template, so the
// first crate and the extras cannot drift. Shared fields come from the root
// [workspace.package] / [workspace.dependencies] / [workspace.lints].
//
// Extra crates copy the rendered first crate. The hook sandbox has no file
// read/copy builtin, so that one step shells out (cp / xcopy).

fn member_manifest(name) {
    let description = variable::get("short_description_toml");
    let github_user = variable::get("github_user_toml");
    let perf_testing = variable::get("perf_testing");
    let perf_manifest = if perf_testing {
        `[dev-dependencies]
criterion.workspace = true

[[bench]]
name    = "example"
path    = "perf/example.rs"
harness = false
`
    } else {
        ""
    };
    `[package]
name              = "${name}"
description       = "${description}"
version.workspace = true
authors.workspace = true
edition.workspace = true
license.workspace = true
build             = "build.rs"
# For running the main server as a watch, call
# cargo watch -q -c -w src/ -x run

[features]
default = [ "macros" ]
macros  = [  ]
# debug   = [  ]

# Windows exe icon + version info (release builds). Assets under assets/icon.ico.
[package.metadata.winresource]
OriginalFilename = "${name}.exe"
FileDescription  = "${description}"
LegalCopyright   = "Copyright (c) ${github_user}"
#CompanyName = "https://github.com/${github_user}"

[target.'cfg(windows)'.build-dependencies]
winresource.workspace = true

# Add deps to [workspace.dependencies] in the root Cargo.toml, then opt in here.
${perf_manifest}

[dependencies]
thiserror.workspace = true

[lints]
workspace = true
`
}

fn member_test(name) {
    `use std::process::Command;

#[test]
fn binary_runs_successfully() {
    let output = Command::new(env!("CARGO_BIN_EXE_${name}"))
        .output()
        .expect("run generated binary");

    assert!(output.status.success());
}
`
}


fn copy_crate(from, to) {
    if variable::get("os-arch").starts_with("windows") {
        system::command("xcopy", ["/E", "/I", "/Q", `crates\\${from}`, `crates\\${to}`]);
    } else {
        system::command("cp", ["-R", `crates/${from}`, `crates/${to}`]);
    }
}

let first = variable::get("project-name");
file::write(`crates/${first}/Cargo.toml`, member_manifest(first));
file::write(`crates/${first}/tests/cli.rs`, member_test(first));

for name in variable::get("extra_crate_list") {
    copy_crate(first, name);
    file::write(`crates/${name}/Cargo.toml`, member_manifest(name));
    file::write(`crates/${name}/tests/cli.rs`, member_test(name));
    print(`Added member crate: crates/${name}`);
}

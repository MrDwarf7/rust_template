// post (cli + workspace): runs in the expansion dir, before the files move
// to the destination. Order matters: VCS init goes last so it never races
// a failed install.

// Linux linker. .cargo/config.toml is rendered by Liquid; it is only
// meaningful when a non-default linker was picked (Linux hosts only).
fn drop_default_linker_config() {
    if variable::get("linker") == "default" && file::exists(".cargo") {
        file::delete(".cargo");
    }
}

// Ticked build tools from the `install_tools` multi-select.
fn install_tools() {
    if !variable::is_set("install_tools") {
        return;
    }
    for tool in variable::get("install_tools") {
        let krate = if tool == "taplo" { "taplo-cli" } else { tool };
        print(`Installing ${tool}: cargo install --locked ${krate} (can take a few minutes)`);
        try {
            system::command("cargo", ["install", "--locked", krate]);
            print(`Installed ${tool}.`);
        } catch (err) {
            print(`Could not install ${tool}: ${err}`);
        }
    }
}

fn init_vcs() {
    let kind = variable::get("vcs_kind");
    let dest = env::destination_directory;
    switch kind {
        "jj" => {
            system::command("jj", ["git", "init", "--colocate", dest]);
            print("Initialized colocated jj repo.");
        }
        "git" => {
            system::command("git", ["init", dest]);
            print("Initialized git repo.");
        }
        _ => print("Skipping VCS init (vcs_kind=none)."),
    }
}

fn still_missing() {
    let ticked = if variable::is_set("install_tools") { variable::get("install_tools") } else { [] };
    let missing = [];
    if !variable::get("has_cargo_make") && !ticked.contains("cargo-make") {
        missing.push("cargo-make (cargo install --locked cargo-make)");
    }
    if !variable::get("has_taplo") && !ticked.contains("taplo") {
        missing.push("taplo (cargo install --locked taplo-cli)");
    }
    missing
}

fn print_build_system_notes() {
    print("");
    print("Build system: cargo-make + taplo drive this project (Makefile.toml, build/*.toml).");
    print("Review Makefile.toml for the top-level aliases (b, br, a, A, r, t, ...).");
    print("Running `cargo make A` formats, checks, lints, builds (debug + release) and tests");
    print("everything; if it passes, your project builds.");
    for tool in still_missing() {
        print(`Not installed: ${tool}`);
    }
}

drop_default_linker_config();
install_tools();
init_vcs();
print_build_system_notes();

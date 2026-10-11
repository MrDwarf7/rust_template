// init: runs before any placeholder is prompted. Sets the facts that the
// conditional sections in each sub-template's cargo-generate.toml key off.
//
// - is_linux: gates the `linker` placeholder. Conditionals cannot read the
//   builtin `os-arch` directly (the hyphen is not a valid Rhai identifier).
// - has_cargo_make / has_taplo: gate the `install_tools` multi-select.
//
// Probing a tool needs system::command. Without --allow-commands the user
// approves each probe. A denied probe, or one that cannot be asked (--silent
// without --allow-commands) counts as present: never offer an install for
// something we could not check.
//
// Probes run inside the *unrendered* template, whose rust-toolchain.toml
// holds Liquid tags and breaks the rustup `cargo` proxy. So cargo-make is
// probed via `makers` (installed alongside it), not `cargo make`.

fn tool_missing(cmd, args) {
    try {
        system::command(cmd, args);
        return false;
    } catch (err) {
        // Only a command that started and failed means "not installed".
        return `${err}`.contains("failed to execute");
    }
}

variable::set("is_linux", variable::get("os-arch").starts_with("linux"));
variable::set("has_cargo_make", !tool_missing("makers", ["--version"]));
variable::set("has_taplo", !tool_missing("taplo", ["--version"]));

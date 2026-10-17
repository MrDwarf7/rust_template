// pre (cli + workspace): derived values for Liquid. Runs after placeholders,
// so values passed with -d / env / [values] are visible here and always win.

fn flag(name) {
    if !variable::is_set(name) {
        return false;
    }
    let value = `${variable::get(name)}`.to_lower();
    ["true", "1", "yes", "on"].contains(value)
}

// stdout of a command, "" when it is missing, fails, or is denied.
// Rhai try/catch is a statement, so return explicitly.
fn probe(cmd, args) {
    try {
        let out = system::command(cmd, args);
        out.trim();
        return out;
    } catch {
        return "";
    }
}

// GitHub user: gh login, then `git config github.user`, then ask.
if !variable::is_set("github_user") {
    let user = probe("gh", ["api", "user", "--jq", ".login"]);
    if user == "" {
        user = probe("git", ["config", "--get", "github.user"]);
    }
    if user == "" {
        try {
            user = variable::prompt("GitHub user/org for URLs?");
        } catch {
            abort("Set github_user with -d github_user=<owner> or CARGO_GENERATE_VALUE_GITHUB_USER when GitHub discovery is unavailable.");
        }
        user.trim();
        if user == "" {
            abort("GitHub user/org cannot be empty.");
        }
    }
    variable::set("github_user", user);
}
let github_user = variable::get("github_user");
github_user.trim();
if github_user == "" {
    abort("GitHub user/org cannot be empty.");
}

let crate_name = variable::get("crate_name");
variable::set("project_name_upper", to_shouty_snake_case(crate_name));
// Opt-in, never asked: CARGO_GENERATE_VALUE_USE_RS_SUFFIX=true or
// `use_rs_suffix = true` under [values] in ~/.cargo/cargo-generate.toml.
variable::set("repo_name", if flag("use_rs_suffix") {
    crate_name + ".rs"
} else {
    variable::get("project-name")
});

// rustc_codegen_cranelift publishes rustup components for these hosts.
let os_arch = variable::get("os-arch");
variable::set("has_cranelift", [
    "linux-x86_64",
    "linux-aarch64",
    "macos-x86_64",
    "macos-aarch64",
    "windows-x86_64",
].contains(os_arch));

// Dev-profile linker for Linux targets in .mbx.toml. mbx links mold / wild
// through clang, so mold is only picked when clang is on PATH. Override with
// -d linker=default|lld|mold|wild.
if !variable::is_set("linker") {
    let has_clang = os_arch.starts_with("linux")
        && probe("clang", ["-print-prog-name=ld"]) != "";
    variable::set("linker", if has_clang { "mold" } else { "default" });
}
let selectors = #{ "default": "system", "lld": "rust-lld", "mold": "mold@3.0.0", "wild": "wild@0.10.0" };
let linker = variable::get("linker");
if !(linker in selectors) {
    abort("linker must be default, lld, mold, or wild.");
}
variable::set("linker_selector", selectors[linker]);

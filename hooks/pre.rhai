// pre (cli + workspace): derived values for Liquid. Not prompted.
let crate_name = variable::get("crate_name");

variable::set("project_name_upper", to_shouty_snake_case(crate_name));
variable::set("repo_name", if variable::get("use_rs_suffix") {
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
// `linker` is only prompted on Linux hosts; Liquid still needs a value.
if !variable::is_set("linker") {
    variable::set("linker", "default");
}

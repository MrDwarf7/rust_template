// pre (cli + workspace): derived values for Liquid. Not prompted.
let crate_name = variable::get("crate_name");

variable::set("project_name_upper", to_shouty_snake_case(crate_name));
variable::set("repo_name", if variable::get("use_rs_suffix") {
    crate_name + ".rs"
} else {
    variable::get("project-name")
});

// `linker` is only prompted on Linux hosts; Liquid still needs a value.
if !variable::is_set("linker") {
    variable::set("linker", "default");
}

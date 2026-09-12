// Derive values used by Liquid after the user placeholders resolve.
// Empty-string answers still get a crate-name fallback.

fn or_default(key, fallback) {
    if !variable::is_set(key) {
        variable::set(key, fallback);
        return ();
    }
    let value = variable::get(key) + "";
    if value == "" {
        variable::set(key, fallback);
    }
}

let crate_name = variable::get("crate_name");
variable::set("project_name_upper", to_shouty_snake_case(crate_name));

let use_rs = variable::get("use_rs_suffix");
if use_rs {
    variable::set("repo_name", crate_name + ".rs");
} else {
    variable::set("repo_name", variable::get("project-name"));
}

or_default("github_user", variable::get("username"));
or_default("tagline", crate_name);
or_default("short_description", crate_name + " -- a Rust CLI");
or_default("long_description", crate_name + " is a Rust CLI scaffolded from rust_template.");

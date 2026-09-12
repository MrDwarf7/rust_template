// Derive Liquid values. extra_crate_list is an array so Cargo.toml can loop.
// Split is done by hand: cargo-generate's Rhai build may not expose String::split/trim.

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

fn push_name(names, raw, first) {
    if raw == "" {
        return names;
    }
    let n = to_snake_case(raw);
    if n != "" && n != first {
        names.push(n);
    }
    names
}

fn parse_extra_crates(extra, first) {
    let names = [];
    let cur = "";
    let i = 0;
    let s = extra + "";
    while i < s.len() {
        let ch = s.sub_string(i, 1);
        if ch == "," {
            names = push_name(names, cur, first);
            cur = "";
        } else if ch != " " && ch != "\t" {
            cur += ch;
        }
        i += 1;
    }
    names = push_name(names, cur, first);
    names
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
or_default("short_description", crate_name + " -- a Rust workspace");
or_default("long_description", crate_name + " is a Rust workspace scaffolded from rust_template.");

let extra = "";
if variable::is_set("extra_crates") {
    extra = variable::get("extra_crates") + "";
}
variable::set("extra_crate_list", parse_extra_crates(extra, crate_name));

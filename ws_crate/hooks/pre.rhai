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
or_default("github_user", variable::get("username"));
or_default("short_description", crate_name + " -- a workspace member crate");

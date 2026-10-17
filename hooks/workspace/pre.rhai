// pre (workspace): normalize extra_crates and prefix extras; first stays unchanged.
// for the members loop in Cargo.toml. Runs after hooks/pre.rhai.
let first = variable::get("crate_name");
// Rhai's String::replace mutates in place and returns (), so never chain it.
let crate_prefix = to_snake_case(variable::get("crate_prefix"));
crate_prefix.replace("_", "-");
variable::set("crate_prefix", crate_prefix);
let first_hyphen = first;
first_hyphen.replace("_", "-");
let extras = [];

for raw in variable::get("extra_crates").split(",") {
    let name = to_snake_case(raw);
    name.replace("_", "-");
    if name != "" {
        let member_name = if crate_prefix != "" && !name.starts_with(crate_prefix + "-") {
            crate_prefix + "-" + name
        } else {
            name
        };
        // acme-core and acme_core share the lib target name; treat as the same crate.
        if member_name != first_hyphen && !extras.contains(member_name) {
            extras.push(member_name);
        }
    }
}

variable::set("extra_crate_list", extras);

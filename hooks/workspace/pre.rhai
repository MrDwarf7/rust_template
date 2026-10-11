// pre (workspace): extra_crates "foo, bar" -> extra_crate_list ["foo", "bar"]
// for the members loop in Cargo.toml. Runs after hooks/pre.rhai.
let first = variable::get("crate_name");
let extras = [];

for raw in variable::get("extra_crates").split(",") {
    let name = to_snake_case(raw);
    if name != "" && name != first && !extras.contains(name) {
        extras.push(name);
    }
}

variable::set("extra_crate_list", extras);

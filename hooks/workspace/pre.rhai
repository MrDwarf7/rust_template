// Keep crate names verbatim; compare snake forms only for duplicate detection.
let first = variable::get("project-name");
let first_snake = to_snake_case(first);
let crate_prefix = variable::get("crate_prefix");
crate_prefix.trim();
let extras = [];

for raw in variable::get("extra_crates").split(",") {
    let name = raw;
    name.trim();
    if name != "" {
        let member_name = if crate_prefix != ""
            && !name.starts_with(crate_prefix + "-")
            && !name.starts_with(crate_prefix + "_") {
            crate_prefix + "-" + name
        } else {
            name
        };
        // Hyphenated and underscored spellings can share a Rust lib target.
        if to_snake_case(member_name) != first_snake && !extras.contains(member_name) {
            extras.push(member_name);
        }
    }
}

variable::set("extra_crate_list", extras);

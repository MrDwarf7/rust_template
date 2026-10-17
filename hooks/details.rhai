// pre (all sub-templates, first): tagline / short_description /
// long_description. Asked only when rt_details is true, e.g.
//   CARGO_GENERATE_VALUE_RT_DETAILS=true cargo generate ...
// or `rt_details = true` under [values] in ~/.cargo/cargo-generate.toml.
// Otherwise defaults are used and edited before release. Values passed with
// -d / env / [values] always win and are never asked.
//
// These cannot be conditional placeholders: cargo-generate evaluates
// conditionals before env / [values] variables are visible to hooks.

fn flag(name) {
    if !variable::is_set(name) {
        return false;
    }
    let value = `${variable::get(name)}`.to_lower();
    ["true", "1", "yes", "on"].contains(value)
}

let kind = if variable::is_set("extra_crates") {
    "workspace"
} else if variable::is_set("crate_prefix") {
    "crate"
} else {
    "CLI"
};
let ask = flag("rt_details");

let items = if kind == "crate" {
    [["short_description", "Short description (Cargo.toml / crates.io)?", `A Rust ${kind}`]]
} else {
    [
        ["tagline", "One-line tagline?", `Rust ${kind}`],
        ["short_description", "Short description (Cargo.toml / crates.io)?", `A Rust ${kind}`],
        ["long_description", "Longer README description?", `A Rust ${kind} scaffolded from rust_template.`],
    ]
};
for item in items {
    if variable::is_set(item[0]) {
        continue;
    }
    let value = item[2];
    if ask {
        try {
            value = variable::prompt(item[1], value);
        } catch {
            abort("Could not prompt for rt_details. Disable rt_details or provide the text values explicitly.");
        }
    }
    variable::set(item[0], value);
}

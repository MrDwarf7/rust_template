// Keep the requested prefix for generated package names; normalize only for
// comparing it to cargo-generate's snake_case crate_name.
let crate_prefix = variable::get("crate_prefix");
crate_prefix.trim();
let prefix_snake = to_snake_case(crate_prefix);
let crate_name = variable::get("crate_name");

if prefix_snake != "" && !crate_name.starts_with(prefix_snake + "_") {
    abort("crate_prefix is set; pass a --name starting with " + crate_prefix + "- or use `cargo make wsa <name>`");
}

let namespace_name = if prefix_snake == "" {
    crate_name
} else {
    crate_name.sub_string(prefix_snake.len() + 1)
};
variable::set("crate_namespace", to_upper_camel_case(namespace_name));

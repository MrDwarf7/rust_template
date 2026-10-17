// crate_name is cargo-generate's snake_case form of --name (acme-auth -> acme_auth),
// so compare the prefix in that form too.
let crate_prefix = to_snake_case(variable::get("crate_prefix"));
let crate_name = variable::get("crate_name");

if crate_prefix != "" && !crate_name.starts_with(crate_prefix + "_") {
    abort("crate_prefix is set; pass a --name starting with " + crate_prefix + "- or use `cargo make wsa <name>`");
}

let namespace_name = if crate_prefix == "" {
    crate_name
} else {
    crate_name.sub_string(crate_prefix.len() + 1)
};
variable::set("crate_namespace", to_upper_camel_case(namespace_name));

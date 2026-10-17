// Derive string contents safe for TOML basic strings. Keep raw values for
// README and URL rendering.
fn toml_string_contents(value) {
    let escaped = "";
    let hex = "0123456789ABCDEF";
    for ch in value.chars() {
        let code = ch.to_int();
        if ch == '"' {
            escaped += `\"`;
        } else if ch == '\\' {
            escaped += `\\`;
        } else if code < 32 || code == 127 {
            escaped += `\u00${hex[code / 16]}${hex[code % 16]}`;
        } else {
            escaped += ch;
        }
    }
    escaped
}

for name in ["short_description", "github_user"] {
    variable::set(name + "_toml", toml_string_contents(variable::get(name)));
}

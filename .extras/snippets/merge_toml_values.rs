// CREDIT: Helix Editor via:
// https://github.com/helix-editor/helix/blob/827deba74c6ac9ea532213f78c2b4e7c8a75850c/helix-loader/src/lib.rs#L168
//
//
/// Merge two TOML documents, merging values from `right` onto `left`
///
/// When an array exists in both `left` and `right`, `right`'s array is
/// used. When a table exists in both `left` and `right`, the merged table
/// consists of all keys in `left`'s table unioned with all keys in `right`
/// with the values of `right` being merged recursively onto values of
/// `left`.
///
/// `merge_toplevel_arrays` controls whether a top-level array in the TOML
/// document is merged instead of overridden. This is useful for TOML
/// documents that use a top-level array of values like the `languages.toml`,
/// where one usually wants to override or add to the array instead of
/// replacing it altogether.
pub fn merge_toml_values(left: toml::Value, right: toml::Value, merge_depth: usize) -> toml::Value {
    use toml::Value;

    fn get_name(v: &Value) -> Option<&str> {
        v.get("name").and_then(Value::as_str)
    }

    match (left, right) {
        (Value::Array(mut left_items), Value::Array(right_items)) => {
            // The top-level arrays should be merged but nested arrays should
            // act as overrides. For the `languages.toml` config, this means
            // that you can specify a sub-set of languages in an overriding
            // `languages.toml` but that nested arrays like Language Server
            // arguments are replaced instead of merged.
            if merge_depth > 0 {
                left_items.reserve(right_items.len());
                for rvalue in right_items {
                    let lvalue = get_name(&rvalue)
                        .and_then(|rname| left_items.iter().position(|v| get_name(v) == Some(rname)))
                        .map(|lpos| left_items.remove(lpos));
                    let mvalue = match lvalue {
                        Some(lvalue) => merge_toml_values(lvalue, rvalue, merge_depth - 1),
                        None => rvalue,
                    };
                    left_items.push(mvalue);
                }
                Value::Array(left_items)
            } else {
                Value::Array(right_items)
            }
        }
        (Value::Table(mut left_map), Value::Table(right_map)) => {
            if merge_depth > 0 {
                for (rname, rvalue) in right_map {
                    match left_map.remove(&rname) {
                        Some(lvalue) => {
                            let merged_value = merge_toml_values(lvalue, rvalue, merge_depth - 1);
                            left_map.insert(rname, merged_value);
                        }
                        None => {
                            left_map.insert(rname, rvalue);
                        }
                    }
                }
                Value::Table(left_map)
            } else {
                Value::Table(right_map)
            }
        }
        // Catch everything else we didn't handle, and use the right value
        (_, value) => value,
    }
}

// Example caller for merging two toml values

use std::str::from_utf8;

/// Default built-in languages.toml.
pub fn default_lang_config() -> toml::Value {
    let default_config = include_bytes!("../../languages.toml");
    toml::from_str(from_utf8(default_config).unwrap()).expect("Could not parse built-in languages.toml to valid toml")
}

/// User configured languages.toml file, merged with the default config.
pub fn user_lang_config() -> Result<toml::Value, toml::de::Error> {
    let config = [crate::config_dir(), crate::find_workspace().0.join(".helix")]
        .into_iter()
        .map(|path| path.join("languages.toml"))
        .filter_map(|file| std::fs::read_to_string(file).map(|config| toml::from_str(&config)).ok())
        .collect::<Result<Vec<_>, _>>()?
        .into_iter()
        .fold(default_lang_config(), |a, b| {
            // combines for example
            // b:
            //   [[language]]
            //   name = "toml"
            //   language-server = { command = "taplo", args = ["lsp", "stdio"] }
            //
            // a:
            //   [[language]]
            //   language-server = { command = "/usr/bin/taplo" }
            //
            // into:
            //   [[language]]
            //   name = "toml"
            //   language-server = { command = "/usr/bin/taplo" }
            //
            // thus it overrides the third depth-level of b with values of a if they exist, but otherwise merges their values
            crate::merge_toml_values(a, b, 3)
        });

    Ok(config)
}

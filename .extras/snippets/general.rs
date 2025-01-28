pub fn time<T>(t: &str, f: impl FnOnce() -> T) -> T {
    eprintln!("{t}: Starting");
    let start = std::time::Instant::now();
    let r = f();
    let elapsed = start.elapsed();
    eprintln!("{t}: Elapsed: {:?}", elapsed);
    r
}

/// Substitute the `var` variable in a string with the given `val` value.
///
/// Variable format: `{{ var }}`
fn substitute<'a: 'b, 'b>(str: &'a str, var: &str, val: &str) -> Cow<'b, str> {
    let format = format!(r"\{{\{{[[:space:]]*{}[[:space:]]*\}}\}}", var);
    Regex::new(&format).unwrap().replace_all(str, val)
}

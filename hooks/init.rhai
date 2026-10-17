// init: sets the fact used to show the Linux-only linker placeholder.
// cargo-generate conditionals cannot reference builtin `os-arch` directly
// because its hyphen is not a valid Rhai identifier.
variable::set("is_linux", variable::get("os-arch").starts_with("linux"));

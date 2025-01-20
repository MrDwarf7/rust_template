/// Will require some changes to get working or additional deps in the template
// #[cfg(feature = "debug")]
// macro_rules! debug {
//     ($($arg:tt)*) => ({
//         use std::fmt::Write as _;
//         let hint = anstyle::Style::new().dimmed();
//
//         let module_path = module_path!();
//         let body = format!($($arg)*);
//         let mut styled = $crate::builder::StyledStr::new();
//         let _ = write!(styled, "{hint}[{module_path:>28}]{body}{hint:#}\n");
//         let color = $crate::output::fmt::Colorizer::new($crate::output::fmt::Stream::Stderr, $crate::ColorChoice::Auto).with_content(styled);
//         let _ = color.print();
//     })
// }
//
// https://github.com/clap-rs/clap/blob/eadcc8f66c128272ea309fed3d53d45b9c700b6f/clap_builder/src/macros.rs#L566
#[cfg(not(feature = "debug"))]
macro_rules! debug {
    ($($arg:tt)*) => {};
}

macro_rules! ok {
    ($expr:expr) => {
        match $expr {
            Ok(val) => val,
            Err(err) => {
                return Err(err);
            }
        }
    };
}

macro_rules! some {
    ($expr:expr) => {
        match $expr {
            Some(val) => val,
            None => {
                return None;
            }
        }
    };
}

/// Allows you to pull the version from your Cargo.toml at compile time as
/// `MAJOR.MINOR.PATCH_PKGVERSION_PRE`
///
/// # Examples
///
/// ```no_run
/// #
/// #
/// #
/// let m = crate_version!();
/// assert_eq!(m, "0.1.0");
///
/// ```
#[cfg(feature = "cargo")]
#[macro_export]
macro_rules! crate_version {
    () => {
        env!("CARGO_PKG_VERSION")
    };
}

/// Allows you to pull the authors for the command from your Cargo.toml at
/// compile time in the form:
/// `"author1 lastname <author1@example.com>:author2 lastname <author2@example.com>"`
///
/// You can replace the colons with a custom separator by supplying a
/// replacement string, so, for example,
/// `crate_authors!(",\n")` would become
/// `"author1 lastname <author1@example.com>,\nauthor2 lastname <author2@example.com>,\nauthor3 lastname <author3@example.com>"`
///
/// # Examples
///
/// ```no_run
/// #
/// #
/// #
/// let m = crate_authors!();
/// assert_eq!(m, "author1 lastname <author1@example.com>:author2 lastname <author2@example.com>"
///
/// ```
#[cfg(feature = "cargo")]
#[macro_export]
macro_rules! crate_authors {
    ($sep:expr) => {{
        static AUTHORS: &str = env!("CARGO_PKG_AUTHORS");
        if AUTHORS.contains(':') {
            static CACHED: std::sync::OnceLock<String> = std::sync::OnceLock::new();
            let s = CACHED.get_or_init(|| AUTHORS.replace(':', $sep));
            let s: &'static str = &*s;
            s
        } else {
            AUTHORS
        }
    }};
    () => {
        env!("CARGO_PKG_AUTHORS")
    };
}

/// Allows you to pull the description from your Cargo.toml at compile time.
///
/// # Examples
///
/// ```no_run
/// #
/// #
/// #
/// let m = crate_description!();
/// assert_eq!(m, "A description of the crate");
///
/// ```
#[cfg(feature = "cargo")]
#[macro_export]
macro_rules! crate_description {
    () => {
        env!("CARGO_PKG_DESCRIPTION")
    };
}

/// Allows you to pull the name from your Cargo.toml at compile time.
///
/// <div class="warning">
///
/// **NOTE:** This macro extracts the name from an environment variable `CARGO_PKG_NAME`.
/// When the crate name is set to something different from the package name,
/// use environment variables `CARGO_CRATE_NAME` or `CARGO_BIN_NAME`.
/// See [the Cargo Book](https://doc.rust-lang.org/cargo/reference/environment-variables.html)
/// for more information.
///
/// </div>
///
/// # Examples
///
/// ```no_run
/// #
/// let m =  crate_name!();
/// assert_eq!(m, "rust_template");
///
/// ```
#[cfg(feature = "cargo")]
#[macro_export]
macro_rules! crate_name {
    () => {
        env!("CARGO_PKG_NAME")
    };
}

/// Allows you to pull the name from your Cargo.toml at compile time.
///
/// <div class="warning">
///
/// **NOTE:** This macro extracts the name from an environment variable `CARGO_PKG_NAME`.
/// When the crate name is set to something different from the package name,
/// use environment variables `CARGO_CRATE_NAME` or `CARGO_BIN_NAME`.
/// See [the Cargo Book](https://doc.rust-lang.org/cargo/reference/environment-variables.html)
/// for more information.
///
/// </div>
///
/// # Examples
///
/// ```no_run
/// #
/// # // Where the name of your crate would be "my_crate"
/// #
/// let m = crate_name!();
/// assert_eq!(m, "my_crate");
///             
/// ```
#[cfg(feature = "cargo")]
#[macro_export]
macro_rules! crate_name {
    () => {
        env!("CARGO_PKG_NAME")
    };
}

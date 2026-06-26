// #[cfg(feature = "macros")]
// mod macros;

mod error;
mod prelude;

pub use crate::error::{Error, Result};

#[allow(clippy::unnecessary_wraps)]
fn main() -> Result<()> {
    println!("Hello, world!");

    Ok(())
}

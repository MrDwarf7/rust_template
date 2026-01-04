mod error;
mod prelude;

pub use crate::error::{Error, Result};

fn main() -> Result<()> {
    println!("Hello, world!");

    Ok(())
}

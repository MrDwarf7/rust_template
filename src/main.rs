mod error;
mod prelude;

pub use self::prelude::{Error, Result, W};

fn main() -> Result<()> {
    println!("Hello, world!");

    Ok(())
}

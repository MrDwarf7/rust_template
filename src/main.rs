mod error;
mod prelude;

pub use self::prelude::{Error, Result, W};

fn main() -> Result<()> {
    println!("Hello, world!");

    Ok(())
}

#[allow(dead_code)]
#[cfg(not(debug_assertions))]
fn current_path() -> Result<std::path::PathBuf> {
    std::env::current_exe()
        .map_err(|e| e.to_string())
        .map_err(Error::Generic)
}

#[allow(dead_code)]
#[cfg(debug_assertions)]
fn current_path() -> Result<std::path::PathBuf> {
    std::env::current_dir()
        .map_err(|e| e.to_string())
        .map_err(Error::Generic)
}

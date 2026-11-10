mod macros;

mod cli;
mod error;
mod prelude;

pub use crate::error::{Error, Result};

#[allow(clippy::unnecessary_wraps)]
fn main() -> Result<()> {
    let cli = cli::Cli::new();
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from(cli.verbosity_level()))
        .init();

    println!("Hello, world!");

    Ok(())
}

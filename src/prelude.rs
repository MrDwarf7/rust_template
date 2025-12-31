// in-crate Error type
pub use crate::error::Error;

// pub use tracing::{debug, error, info, warn};

// in-crate result type
pub type Result<T> = std::result::Result<T, Error>;

// Wrapper struct
#[allow(dead_code)]
pub struct W<T>(pub T);

#[allow(dead_code)]
pub fn time<T>(t: &str, f: impl FnOnce() -> T) -> T {
    eprintln!("{t}: Starting");
    let start = std::time::Instant::now();
    let r = f();
    let elapsed = start.elapsed();
    eprintln!("{t}: Elapsed: {elapsed:?}");
    r
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

// #[derive(Clone)]
// pub struct LevelWrapper<L, E>
// where
//     L: Into<tracing::Level>,
//     E: Into<tracing_subscriber::filter::EnvFilter>,
// {
//     pub level:      L,
//     pub env_filter: E,
// }

// pub type TracingSubscriber = tracing_subscriber::fmt::SubscriberBuilder<
//     tracing_subscriber::fmt::format::DefaultFields,
//     tracing_subscriber::fmt::format::Format<tracing_subscriber::fmt::format::Full>,
//     // tracing_subscriber::EnvFilter,
// >;

// pub fn init_logger() -> TracingSubscriber {
//     tracing_subscriber::fmt()
//         .with_level(true)
//         .with_ansi(true)
//         .with_line_number(true)
//         .with_thread_ids(true)
//     // .with_env_filter(level)
//     // .with_span_events(tracing_subscriber::fmt::format::FmtSpan::CLOSE)
//     // .with_timer(tracing_subscriber::fmt::time::SystemTime)
// }
//
//

// More complex implementation that allows for custom levels and environment filters
// requires the use of the impl From<VerbosityLevel> for LevelWrapper<L, E> functionality in
// `cli.rs` file.

// pub fn init_logger<L, E>(level: LevelWrapper<L, E>) -> TracingSubscriber
// where
//     L: Into<tracing::Level> + Clone,
//     E: Into<tracing_subscriber::filter::EnvFilter>,
// {
//     let max_level: tracing::Level = level.level.clone().into();
//     let env_level: tracing_subscriber::filter::EnvFilter = level.env_filter.into();
//     tracing_subscriber::fmt()
//         .with_level(true)
//         .with_ansi(true)
//         .with_line_number(true)
//         .with_thread_ids(true)
//         .with_max_level(max_level)
//         .with_env_filter(env_level)
//     // .with_span_events(tracing_subscriber::fmt::format::FmtSpan::CLOSE)
//     // .with_timer(tracing_subscriber::fmt::time::SystemTime)
// }

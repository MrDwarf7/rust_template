// in-crate Error type
pub use crate::error::Error;

// pub use tracing::{debug, error, info, warn};

// in-crate result type
pub type Result<T> = std::result::Result<T, Error>;

// Wrapper struct
#[allow(dead_code)]
pub struct W<T>(pub T);

pub fn time<T>(t: &str, f: impl FnOnce() -> T) -> T {
    eprintln!("{t}: Starting");
    let start = std::time::Instant::now();
    let r = f();
    let elapsed = start.elapsed();
    eprintln!("{t}: Elapsed: {:?}", elapsed);
    r
}

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

// in-crate Error type
pub use crate::error::Error;

// in-crate result type
pub type Result<T> = std::result::Result<T, Error>;

// Wrapper struct
pub struct W<T>(pub T);

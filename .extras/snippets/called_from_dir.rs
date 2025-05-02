use std::path::{Path, PathBuf};

/// Returns the current directory based on the build configuration.
///
/// In debug mode, this function returns the current working directory.
/// In release mode, it returns the directory of the executable.
///
/// # Returns
///
/// * `crate::Result<PathBuf>` - Returns the path to the current directory on success, or an `Error` on failure.
///
/// # Example
///
/// ```rust
/// let dir = current_dir().expect("Failed to get current directory");
/// println!("Current directory: {:?}", dir);
/// ```
#[cfg(debug_assertions)]
pub fn current_dir() -> crate::Result<PathBuf> {
    let dir = std::env::current_dir().map_err(Error::Io)?;
    Ok(dir.clone())
}

/// Returns the current directory based on the build configuration.
///
/// In debug mode, this function returns the current working directory.
/// In release mode, it returns the directory of the executable.
///
/// # Returns
///
/// * `crate::Result<PathBuf>` - Returns the path to the current directory on success, or an `Error` on failure.
///
/// # Example
///
/// ```rust
/// let dir = current_dir().expect("Failed to get current directory");
/// println!("Current directory: {:?}", dir);
/// ```
#[cfg(not(debug_assertions))]
pub fn current_dir() -> crate::Result<PathBuf> {
    let dir = std::env::current_exe().map_err(Error::Io)?;
    let dir = dir
        .parent()
        .ok_or(Error::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "No parent directory")))?;

    Ok(dir.to_path_buf())
}

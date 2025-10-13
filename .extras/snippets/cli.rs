use std::path::PathBuf;
use std::str::FromStr;

use clap::{Parser, ValueEnum, command};

use crate::prelude::*;

#[rustfmt::skip]
#[derive(Parser, Debug)]
#[command(
    name = crate::crate_name!(),
    author = crate::crate_authors!(),
    version = crate::crate_version!(),
    about = crate::crate_description!(),
    long_about = "\n\
        Put your long desc. here
    ",
    arg_required_else_help = true
    // Allows for the custom parsing of the version flag
    disable_version_flag = true,
)]
pub struct Cli {
    /// The directory to act as the root of the crawler.
    #[arg(index = 1, help = "First index help text", value_hint = clap::ValueHint::FilePath)]
    pub first_param: PathBuf,

    /// The input extension to crawl for.
    #[arg(index = 2, help = "Second index help text", value_hint = clap::ValueHint::Other)]
    pub second_param: String,

    /// The output extension to convert to. This is subject to Pandoc's supported formats.
    #[arg(index = 3, help = "Third index help text", value_hint = clap::ValueHint::Other)]
    pub third_param: String,

    /// Optional verbosity level of the logger.
    /// You may provide this as either a string or a number.
    ///
    /// The least verbose as 0 (Error -> Error Only)
    /// Most verbose as 4 (Trace -> Trace Everything)
    /// If not provided, the default value is "INFO".
    #[arg(value_enum, name = "level_verbosity", short = 'l', long = "level_verbosity", help = "The verbosity level of the logger.", required = false, default_value = "INFO", value_hint = clap::ValueHint::Other)]
    pub level_verbosity: Option<VerbosityLevel>,

    /// Other version flag
    #[arg(short = 'v', short_alias = 'V', long = "version", help = "Prints version information")]
    pub version: bool,
}

impl Cli {
    pub fn new() -> Self {
        let s = Self::parse();
        if s.version {
            println!("{} {}", crate::crate_name!(), crate::crate_version!());
            std::process::exit(0);
        }
        s
    }

    #[inline]
    pub fn verbosity_level(&self) -> VerbosityLevel {
        self.level_verbosity.unwrap_or(VerbosityLevel::Info)
    }
}

/// The verbosity level of the logger.
///
/// The least verbose as 0 (Error -> Error Only)
/// Most verbose as 4 (Trace -> Trace Everything).
#[derive(Debug, ValueEnum, Clone, Copy, PartialEq, Eq)]
#[clap(name = "VerbosityLevel", rename_all = "upper")]
pub enum VerbosityLevel {
    #[value(name = "ERROR", alias = "error", alias = "Error", alias = "0")]
    Error,
    #[value(name = "WARN", alias = "warn", alias = "Warn", alias = "1")]
    Warn,
    #[value(name = "INFO", alias = "info", alias = "Info", alias = "2")]
    Info,
    #[value(name = "DEBUG", alias = "debug", alias = "Debug", alias = "3")]
    Debug,
    #[value(name = "TRACE", alias = "trace", alias = "Trace", alias = "4")]
    Trace,
}

impl From<VerbosityLevel> for tracing_subscriber::filter::EnvFilter {
    #[inline]
    fn from(level: VerbosityLevel) -> Self {
        match level {
            VerbosityLevel::Error => tracing_subscriber::filter::EnvFilter::new("ERROR"),
            VerbosityLevel::Warn => tracing_subscriber::filter::EnvFilter::new("WARN"),
            VerbosityLevel::Info => tracing_subscriber::filter::EnvFilter::new("INFO"),
            VerbosityLevel::Debug => tracing_subscriber::filter::EnvFilter::new("DEBUG"),
            VerbosityLevel::Trace => tracing_subscriber::filter::EnvFilter::new("TRACE"),
        }
    }
}

impl From<VerbosityLevel> for LevelWrapper<tracing::Level, tracing_subscriber::filter::EnvFilter> {
    #[inline]
    fn from(level: VerbosityLevel) -> Self {
        let env_filter: tracing_subscriber::filter::EnvFilter = level.into();
        let level: tracing::Level = level.into();
        LevelWrapper { level, env_filter }
    }
}

impl From<VerbosityLevel> for tracing::Level {
    #[inline]
    fn from(value: VerbosityLevel) -> Self {
        match value {
            VerbosityLevel::Error => tracing::Level::ERROR,
            VerbosityLevel::Warn => tracing::Level::WARN,
            VerbosityLevel::Info => tracing::Level::INFO,
            VerbosityLevel::Debug => tracing::Level::DEBUG,
            VerbosityLevel::Trace => tracing::Level::TRACE,
        }
    }
}

impl From<u8> for VerbosityLevel {
    #[inline]
    fn from(level: u8) -> Self {
        match level {
            0 => VerbosityLevel::Error,
            1 => VerbosityLevel::Warn,
            2 => VerbosityLevel::Info,
            3 => VerbosityLevel::Debug,
            4 => VerbosityLevel::Trace,
            _ => VerbosityLevel::Info,
        }
    }
}

impl FromStr for VerbosityLevel {
    type Err = Error;

    #[inline]
    fn from_str(s: &str) -> Result<Self> {
        match s.to_uppercase().as_str() {
            "ERROR" => Ok(VerbosityLevel::Error),
            "WARN" => Ok(VerbosityLevel::Warn),
            "INFO" => Ok(VerbosityLevel::Info),
            "DEBUG" => Ok(VerbosityLevel::Debug),
            "TRACE" => Ok(VerbosityLevel::Trace),
            _ => Err(Error::Generic(format!("Verbosity level: {} is not supported.", s))),
        }
    }
}

pub fn get_styles() -> clap::builder::Styles {
    clap::builder::Styles::styled()
        .usage(
            anstyle::Style::new()
                .bold()
                .underline()
                .fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::Yellow))), // When a command is inc. This is the tag collor for 'Usage:'
        )
        .header(
            anstyle::Style::new()
                .bold()
                .underline()
                .fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::Blue))), // Main headers in the help menu (e.g. Arguments, Options)
        )
        .literal(
            anstyle::Style::new().fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::BrightWhite))), // Strings for args etc { -t, --total }
        )
        .invalid(
            anstyle::Style::new()
                .bold()
                .fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::Red))),
        )
        .error(
            anstyle::Style::new()
                .bold()
                .fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::Red)))
                .effects(anstyle::Effects::ITALIC),
        )
        .valid(
            anstyle::Style::new()
                .bold()
                .fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::Cyan))),
        )
        .placeholder(anstyle::Style::new().fg_color(Some(anstyle::Color::Ansi(anstyle::AnsiColor::White))))
}

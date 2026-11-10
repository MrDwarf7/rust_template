use std::process::Command;

#[test]
fn binary_runs_successfully() {
    let output = Command::new(env!("CARGO_BIN_EXE_{{ project-name }}"))
        .args(["input.txt", "second", "third"])
        .output()
        .expect("run generated binary");

    assert!(output.status.success());
}

#[test]
fn help_and_custom_version_flags_work() {
    let version = format!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
    for (flag, expected) in [
        ("--help", "Arguments:"),
        ("--version", version.as_str()),
        ("-v", version.as_str()),
        ("-V", version.as_str()),
    ] {
        let output = Command::new(env!("CARGO_BIN_EXE_{{ project-name }}"))
            .arg(flag)
            .args(if flag == "--help" {
                vec![]
            } else {
                vec!["input.txt", "second", "third"]
            })
            .output()
            .expect("run generated binary");

        assert!(output.status.success(), "{flag}: {output:?}");
        assert!(String::from_utf8_lossy(&output.stdout).contains(expected));
    }

    for flag in ["--version", "-v", "-V"] {
        let output = Command::new(env!("CARGO_BIN_EXE_{{ project-name }}"))
            .arg(flag)
            .output()
            .expect("run generated binary");

        assert_eq!(output.status.code(), Some(2), "{flag}: {output:?}");
    }
}

#[test]
fn verbosity_accepts_names_and_numbers_and_rejects_invalid_values() {
    for level in [
        "ERROR", "warn", "Info", "DEBUG", "trace", "0", "1", "2", "3", "4", "invalid",
    ] {
        let output = Command::new(env!("CARGO_BIN_EXE_{{ project-name }}"))
            .args(["input.txt", "second", "third", "-l", level])
            .output()
            .expect("run generated binary");

        assert_eq!(output.status.success(), level != "invalid", "{level}: {output:?}");
    }
}

#[test]
fn missing_positionals_show_usage() {
    let output = Command::new(env!("CARGO_BIN_EXE_{{ project-name }}"))
        .output()
        .expect("run generated binary");

    assert_eq!(output.status.code(), Some(2));
    assert!(String::from_utf8_lossy(&output.stderr).contains("Usage:"));
}

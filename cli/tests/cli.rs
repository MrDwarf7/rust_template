use std::process::Command;

#[test]
fn binary_runs_successfully() {
    let output = Command::new(env!("CARGO_BIN_EXE_{{ crate_name }}"))
        .output()
        .expect("run generated binary");

    assert!(output.status.success());
}

use {{ crate_name | replace: "-", "_" }}::{
    {{ crate_namespace }}Error, {{ crate_namespace }}Result,
};

#[test]
fn exported_error_and_result_are_usable() {
    let error = {{ crate_namespace }}Error::Generic("example".to_owned());
    let result: {{ crate_namespace }}Result<()> = Err(error);

    assert!(result.is_err());
}

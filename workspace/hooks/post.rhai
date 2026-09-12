// Post: expansion dir, before copy to destination.
// Extra member crates use `cp` (system::command) only when extra_crates is non-empty.

fn is_asset_script(name) {
    name == "generate-assets.sh"
        || name == "assets/generate-assets.sh"
        || name.contains("/generate-assets.sh")
}

fn delete_dir_assets(dir) {
    if !file::exists(dir) {
        return ();
    }
    let entries = file::listdir(dir);
    for entry in entries {
        if !is_asset_script(entry) {
            file::delete(entry);
        }
    }
}

fn delete_template_assets() {
    let crate_name = variable::get("crate_name");
    delete_dir_assets("crates/" + crate_name + "/assets");
    // Literal unexpanded path, in case listdir runs before rename.
    delete_dir_assets("crates/{{crate_name}}/assets");
}

fn rewrite_copied_manifest(src_name, dest_name) {
    // system::command inherits stdout, so we cannot cat-and-replace in Rhai.
    // In-place sed does not need the file contents back.
    let abs = env::working_directory + "/crates/" + dest_name + "/Cargo.toml";
    let exe_from = "s/\"" + src_name + ".exe\"/\"" + dest_name + ".exe\"/g";
    let name_from = "s/\"" + src_name + "\"/\"" + dest_name + "\"/g";
    let sed_out = system::command("sed", ["-i", "-e", exe_from, "-e", name_from, abs]);
}

fn expand_extra_crates() {
    if !variable::is_set("extra_crate_list") {
        return ();
    }
    let extras = variable::get("extra_crate_list");
    if extras.len() == 0 {
        return ();
    }
    let wd = env::working_directory;
    let first = variable::get("crate_name");
    let src = wd + "/crates/" + first;
    for name in extras {
        let dest = wd + "/crates/" + name;
        let cp_out = system::command("cp", ["-a", src, dest]);
        rewrite_copied_manifest(first, name);
        print("Added extra member crate: crates/" + name);
    }
}

fn init_vcs() {
    let kind = variable::get("vcs_kind");
    if kind == "none" {
        print("Skipping VCS init (vcs_kind=none).");
        return ();
    }
    let dest = env::destination_directory;
    if kind == "jj" {
        let cmd_out = system::command("jj", ["git", "init", "--colocate", dest]);
        print("Initialized colocated jj at destination.");
        return ();
    }
    if kind == "git" {
        let cmd_out = system::command("git", ["init", dest]);
        print("Initialized git at destination.");
        return ();
    }
}

delete_template_assets();
expand_extra_crates();
init_vcs();

// Post: expansion dir, before copy to destination.
// Asset wipe is file:: only (no python/bash). VCS init needs system::command.

fn is_asset_script(name) {
    name == "generate-assets.sh"
        || name == "assets/generate-assets.sh"
        || name.contains("/generate-assets.sh")
}

fn delete_template_assets() {
    if !file::exists("assets") {
        return ();
    }
    let entries = file::listdir("assets");
    for entry in entries {
        if !is_asset_script(entry) {
            file::delete(entry);
        }
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
init_vcs();

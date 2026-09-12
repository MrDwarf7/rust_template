// Add-one-crate. cargo-generate 0.24+ walks up to [workspace] and:
// - no-ops when members already covers the path (crates/* glob)
// - appends the relative path when members is an explicit list
// Run from the workspace root:
//   cargo generate --path <this-repo> ws_crate -n new_crate --destination crates

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

delete_template_assets();

print("ws_crate generated at " + env::destination_directory);
print("If the parent workspace members list is explicit paths, cargo-generate 0.24+ appends this crate.");
print("If members is a glob (crates/*), nothing is patched -- already covered.");
print("Pass --no-workspace to skip that auto-add.");

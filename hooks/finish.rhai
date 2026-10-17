// post (cli + workspace): runs in the expansion dir, before the files move
// to the destination. VCS init happens after rendering is complete.


fn init_vcs() {
    let kind = variable::get("vcs_kind");
    let dest = env::destination_directory;
    switch kind {
        "jj" => {
            system::command("jj", ["git", "init", "--colocate", dest]);
            print("Initialized colocated jj repo.");
        }
        "git" => {
            system::command("git", ["init", dest]);
            print("Initialized git repo.");
        }
        _ => print("Skipping VCS init (vcs_kind=none)."),
    }
}


fn print_build_system_notes() {
    print("");
    print("Build system: cargo-make + taplo drive this project (Makefile.toml, build/*.toml).");
    print("Review Makefile.toml for the top-level aliases (b, br, a, A, r, t, ...).");
    print("Running `cargo make A` formats, checks, lints, builds (debug + release) and tests");
    print("everything; if it passes, your project builds.");
    print("mise.toml requests latest tools with a 24h release cooldown.");
    print("Run `mise trust && mise install && mise reshim` before using them.");
}
init_vcs();
print_build_system_notes();


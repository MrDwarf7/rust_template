fn first_author() -> String {
    let authors = crate_authors!();
    let authors = authors.split(":").collect::<Vec<&str>>();
    let author = authors[0].split(" ").collect::<Vec<&str>>();
    author[0].to_string()
}

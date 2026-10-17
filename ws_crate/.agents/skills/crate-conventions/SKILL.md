---
name: crate-conventions
description: Follow the library crate's internal error and exported alias conventions.
---

# Crate conventions

Keep `Error` and `Result` internal. Export only namespaced aliases such as `<NS>Error` and
`<NS>Result` from `src/lib.rs`.

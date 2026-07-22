<!-- PROJECT LOGO / BANNER -->
<p align="center">
  <img src="assets/README-header.png" alt="rust_template" width="100%">
</p>

<p align="center">
  <img src="assets/icon-128.png" alt="rust_template icon" width="64">
</p>

<p align="center">
  <strong>rust_template</strong> -- Rust project template
  <br>
  <a href="https://crates.io/crates/rust_template"><img src="https://img.shields.io/crates/v/rust_template" alt="crates.io"></a>
  <a href="https://github.com/MrDwarf7/rust_template/actions/workflows/build.yml"><img src="https://github.com/MrDwarf7/rust_template/actions/workflows/build.yml/badge.svg" alt="build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="license"></a>
  <a href="https://github.com/MrDwarf7/rust_template/releases"><img src="https://img.shields.io/github/v/release/MrDwarf7/rust_template" alt="release"></a>
</p>

<!-- TAGLINE + DESCRIPTION -->
## rust_template

Baseline Cargo CLI template for MrDwarf7 projects. Clone, rename via setup scripts, ship with shared CI, assets, and Windows icon embedding.

```bash
# After setup.sh
cargo run -- --help
```

## Assets

Brand kit lives under `assets/`:

| File | Use |
|------|-----|
| `logo.svg` | Vector monogram |
| `icon.ico` | Windows exe (via `build.rs` + winresource, release only) |
| `icon-*.png` | Raster sizes |
| `README-header.png` | README banner |
| `social-banner.png` | Open Graph / social |

Regenerate:

```bash
./assets/generate-assets.sh -l R -n rust_template -t "Rust project template" -a "#00D9A5"
```

## License

See [LICENSE](LICENSE).

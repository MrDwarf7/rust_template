#!/bin/bash
set -euo pipefail

export ARTIFACT_NAME="csv_parser_rs-$1"

# Build for the target
cargo build --release --locked --target "$1"

mkdir -p "$ARTIFACT_NAME"
# Create the artifact
cp "target/$1/release/csv_parser_rs" "$ARTIFACT_NAME"
cp "README.md" "LICENSE-APACHE" "LICENSE-MIT" "$ARTIFACT_NAME"

# Zip the artifact
if ! command -v zip &>/dev/null; then
    sudo apt-get update && sudo apt-get install -yq zip
fi
# Zips the items without including the folder itself in the resulting archive
cd $ARTIFACT_NAME
zip -r "../$ARTIFACT_NAME.zip" *
cd ..


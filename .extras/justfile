# Justfile for Rust Project Automation
# Set the shell to powershell
# Define a variable for the cargo command to allow easy modification if needed
# Variable for helper text (Mind the indentations and use of double quotes)
#
# %s/\v\{\{\s(runner_command)\s(.+)\}/\{\{ variable_name_for_runner \}\} /g
# Can be used to replace the runner_command with the actual command to run

set windows-shell := ["pwsh.exe","--noprofile", "-NoLogo", "-Command"]

runner_command := "cargo"

# ---------------------------------------------------------------------------------
# Default Recipe: build
# Description: If no recipe is specified, default to 'build'.
# Usage: just

# ---------------------------------------------------------------------------------
default: simple

# ---------------------------------------------------------------------------------
# Recipe: help
# Description: Display available commands.
# Usage: just help

helper_text := """
\r\n\t📋 Available Commands:
➖ help             -    Display this help message
➖ build            -    Build the project in debug mode
➖ run              -    Run the project in debug mode
➖ build-release    -    Build the project in release mode
➖ run-release      -    Run the project in release mode
➖ test             -    Run tests for the project
➖ test-all         -    Run all tests in the workspace
➖ test-no-harness  -    Run tests without capturing stdout
➖ lint             -    Run linting for the project
➖ doc              -    Generate documentation for the project
➖ doc-open         -    Generate documentation and open it in the browser
➖ doc-test         -    Generate documentation and run tests
➖ simple           -    Run simple commands
➖ full             -    Run full commands
➖ clean            -    Clean the project
\r\n\t➕ Aliases:
➖ h                -     Display this help message
➖ b                -     Build the project in debug mode
➖ r                -     Run the project in debug mode
➖ br               -     Build the project in release mode
➖ rr               -     Run the project in release mode
➖ t                -     Run tests for the project
➖ ta               -     Run all tests in the workspace
➖ tnh              -     Run tests without capturing stdout
➖ l                -     Run linting for the project
➖ d                -     Generate documentation for the project
➖ do               -     Generate documentation and open it in the browser
➖ dt               -     Generate documentation and run tests
➖ s                -     Run simple commands
➖ f                -     Run full commands
➖ cl               -     Clean the project
"""

# ---------------------------------------------------------------------------------
help:
    @echo "{{ helper_text }}"

alias h := help

# ---------------------------------------------------------------------------------
# Recipe: build
# Description: Build the project in debug mode.
# Usage: just build

# ---------------------------------------------------------------------------------
build:
    @echo "🔨 Building the project in debug mode..."
    {{ runner_command }} build --workspace --all-features

alias b := build

# ---------------------------------------------------------------------------------
# Recipe: run
# Description: Run the project in debug mode.
# Usage: just run

# ---------------------------------------------------------------------------------
run:
    @echo "🚀 Running the project in debug mode..."
    {{ runner_command }} run

alias r := run

# ---------------------------------------------------------------------------------
# Recipe: build-release
# Description: Build the project in release mode.
# Usage: just build-release

# ---------------------------------------------------------------------------------
build-release:
    @echo "🔨 Building the project in release mode..."
    {{ runner_command }} build --release --workspace --all-features

alias br := build-release

# ---------------------------------------------------------------------------------
# Recipe: run-release
# Description: Run the project in release mode.
# Usage: just run-release

# ---------------------------------------------------------------------------------
run-release:
    @echo "🚀 Running the project in release mode..."
    {{ runner_command }} run --release --workspace --all-features

alias rr := run-release

build-all:
    @echo "🔨 Building all..."
    @just build
    @just build-release

alias ba := build-all

# ---------------------------------------------------------------------------------
# Recipe: test
# Description: Run tests for the project.
# Usage: just test

# ---------------------------------------------------------------------------------
test:
    @echo "🧪 Running tests..."
    {{ runner_command }} test --all-targets --all-features

alias t := test

# ---------------------------------------------------------------------------------
# Recipe: test-all
# Description: Run all tests in the workspace (if using a workspace).
# Usage: just test-all

# ---------------------------------------------------------------------------------
test-all:
    @echo "🧪 Running all tests in the workspace..."
    {{ runner_command }} test --all --all-targets --all-features

alias ta := test-all

# ---------------------------------------------------------------------------------
# Recipe: test-no-harness
# Description: Run tests without capturing stdout (useful for debugging).
# Usage: just test-no-harness

# ---------------------------------------------------------------------------------
test-no-harness:
    @echo "🧪 Running tests without capturing stdout..."
    {{ runner_command }} test --all-features -- --nocapture

alias tnh := test-no-harness

# ---------------------------------------------------------------------------------
# Recipe: lint
# Description: Run linting for the project.
# Usage: just lint

# ---------------------------------------------------------------------------------
lint:
    @echo "🔍 Running linting..."
    {{ runner_command }} clippy --fix --allow-dirty --workspace --all-features

alias l := lint

# ---------------------------------------------------------------------------------
# Recipe: doc
# Description: Generate documentation for the project.
# Usage: just doc

# ---------------------------------------------------------------------------------
doc:
    @echo "📚 Generating documentation..."
    {{ runner_command }} doc

alias d := doc

# ---------------------------------------------------------------------------------
# Recipe: doc-open
# Description: Generate documentation and open it in the default browser.
# Usage: just doc-open

# ---------------------------------------------------------------------------------
doc-open:
    @echo "📚 Generating documentation and opening it in the browser..."
    {{ runner_command }} doc --open

alias do := doc-open

doc-test:
    @echo "📚 Generating documentation and running tests..."
    {{ runner_command }} test --doc

alias dt := doc-test

simple:
    @echo "🚀 Running simple..."
    @just build
    @just lint
    @just test

alias s := simple

full:
    @echo "🚀 Running full..."
    @just build
    @just build-release
    @just lint
    @just test-all
    @just doc

alias f := full

clean:
    @echo "🧹 Cleaning the project..."
    {{ runner_command }} clean

alias cl := clean

reset:
    @echo "🧹 Resetting the project..."
    @just clean
    @build-all
    @just doc
    @just lint

alias rst := reset

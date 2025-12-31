#!/bin/env bash

set -euo pipefail

# Current directory is the project root
ROOT="$(pwd)"
FOLDER_NAME="$(basename "$ROOT")"
PROJECT_NAME="${FOLDER_NAME//./_}"

# Configurable list of optional folders to ask about removing
FOLDERS_TO_ASK=("data" "scratch")

GITHUB_FILE_PUBLISH=".github/_publish.yml"
GITHUB_FILE_CONFIG=".github/workflows/config.yml"

GITHUB_FILE_WORKFLOWS=(
  ".github/workflows/01-bug.yml"
  ".github/workflows/02-feature-request.yml"
  ".github/workflows/03-docs-problem.yml"
  ".github/workflows/04-build-problem.yml"
)

# Portable sed -i replacement
replace_in_file() {
  local file="$1"
  local pattern="$2"
  local replacement="$3"

  if [[ ! -f "$file" ]]; then
    printf "Warning: %s not found, skipping.\n" "$file"
    return
  fi

  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s|$pattern|$replacement|g" "$file"
  else
    sed -i "s|$pattern|$replacement|g" "$file"
  fi
}

# Simple yes/no prompt (returns 0 for yes, 1 for no)
ask_yes_no() {
  local prompt="$1"
  while true; do
    read -p "$prompt [y/n]: " answer
    case "$answer" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) printf "Please answer y or n.\n" ;;
    esac
  done
}

remove_vcs_dirs() {
  printf "Removing any existing .git or .jj directories...\n"
  rm -rf .git .jj
}

remove_target() {
  printf "Removing target/ directory...\n"
  rm -rf target
}

maybe_remove_bacon() {
  if [[ -f "bacon.toml" ]]; then
    if ask_yes_no "Do you want to remove bacon.toml?"; then
      rm -f bacon.toml
      printf "Removed bacon.toml\n"
    else
      printf "Kept bacon.toml\n"
    fi
  fi
}

update_makefile_toml() {
  if [[ -f "Makefile.toml" ]]; then
    printf "Updating Makefile.toml (using FOLDER_NAME: %s)\n" "$FOLDER_NAME"
    replace_in_file "Makefile.toml" 'env\.PROJECT_NAME = "rust_template"' "env.PROJECT_NAME = \"$FOLDER_NAME\""
  fi
}

update_cargo_toml() {
  if [[ -f "Cargo.toml" ]]; then
    printf "Updating Cargo.toml (using PROJECT_NAME: %s)\n" "$PROJECT_NAME"
    replace_in_file "Cargo.toml" 'name[[:space:]]*=[[:space:]]*"rust_template"' "name = \"$PROJECT_NAME\""
  fi
}

maybe_remove_optional_folders() {
  for folder in "${FOLDERS_TO_ASK[@]}"; do
    if [[ -d "$folder" ]]; then
      if ask_yes_no "Do you want to remove the $folder/ folder?"; then
        rm -rf "$folder"
        printf "Removed %s/\n" "$folder"
      else
        printf "Kept %s/" "$folder"
      fi
    fi
  done
}

update_github_publish() {
  local file="$GITHUB_FILE_PUBLISH"
  if [[ -f "$file" ]]; then
    printf "Updating %s (PROJECT_NAME → %s)\n" "$file" "$PROJECT_NAME"
    replace_in_file "$file" "PROJECT_NAME: rust_template" "PROJECT_NAME: $PROJECT_NAME"
  fi
}

update_issue_template_workflows() {
  local files=("${GITHUB_FILE_WORKFLOWS[@]}")
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      printf "Updating %s (PROJECT_NAME → %s)\n" "$file" "$PROJECT_NAME"
      replace_in_file "$file" "PROJECT_NAME: rust_template" "PROJECT_NAME: $PROJECT_NAME"
    fi
  done
}

update_config_yml() {
  local file="$GITHUB_FILE_CONFIG"
  if [[ -f "$file" ]]; then
    printf "Updating %s (repo URL → %s)\n" "$file" "$FOLDER_NAME"
    replace_in_file "$file" \
      "url: https://github.com/MrDwarf7/REPO_NAME/discussions" \
      "url: https://github.com/MrDwarf7/$FOLDER_NAME/discussions"
  fi
}

setup_repository() {
  printf "\n"
  if ask_yes_no "Have you already set up the GitHub repository (remote exists)?"; then
    # Remote exists → offer jj colocation option if available
    if command -v jj >/dev/null 2>&1; then
      printf "jj command found.\n"
      if ask_yes_no "Do you want to initialize with jj (recommended for existing remote)?"; then
        printf "Choose initialization method:\n"
        printf "  1) jj git init\n"
        printf "  2) jj git init --colocate  (shares .git directory with Git tools)\n"
        while true; do
          read -p "Enter choice (1 or 2): " choice
          case "$choice" in
          1)
            jj git init
            break
            ;;
          2)
            jj git init --colocate
            break
            ;;
          *) printf "Invalid choice, please enter 1 or 2.\n" ;;
          esac
        done
        return
      fi
    else
      printf "jj not available.\n"
    fi
    # Fallback to plain git init
    git init
    printf "Initialized empty Git repository.\n"
  else
    # No remote yet → default to plain git init (user can add remote later)
    printf "No existing remote. Initializing a fresh Git repository.\n"
    git init
    printf "Initialized empty Git repository. You can create the GitHub repo later and add it as remote.\n"
  fi
}

main() {
  printf "Starting project template setup for folder: %s\n" "$FOLDER_NAME"
  printf "Derived PROJECT_NAME (for Cargo/binary): %s\n" "$PROJECT_NAME"
  printf "\n"

  remove_vcs_dirs
  remove_target
  maybe_remove_bacon
  update_makefile_toml
  update_cargo_toml
  maybe_remove_optional_folders
  update_github_publish
  update_issue_template_workflows
  update_config_yml
  setup_repository

  printf "\n"
  printf "Setup complete!\n"
}

main "$@"

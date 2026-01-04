#!/bin/env bash

set -euo pipefail

# Current directory is the project root
ROOT="$(pwd)"
FOLDER_NAME="$(basename "$ROOT")"
PROJECT_NAME="${FOLDER_NAME//./_}"

# Configurable list of optional folders to ask about removing
FOLDERS_TO_ASK=("data" "scratch")

GITHUB_ISSUE_TEMPLATE_DIR=".github/ISSUE_TEMPLATE"
GITHUB_WORKFLOWS_DIR=".github/workflows"

GITHUB_FILE_PUBLISH=".github/_publish.yml"
GITHUB_FILE_CONFIG=".github/ISSUE_TEMPLATE/config.yml"

GITHUB_FILES=(
  "$GITHUB_WORKFLOWS_DIR/build.yml"
  "$GITHUB_WORKFLOWS_DIR/docs.yml"
  "$GITHUB_WORKFLOWS_DIR/draft.yml"
  "$GITHUB_WORKFLOWS_DIR/format.yml"
  "$GITHUB_WORKFLOWS_DIR/test.yml"

  "$GITHUB_ISSUE_TEMPLATE_DIR/01-bug.yml"
  "$GITHUB_ISSUE_TEMPLATE_DIR/02-feature-request.yml"
  "$GITHUB_ISSUE_TEMPLATE_DIR/03-docs-problem.yml"
  "$GITHUB_ISSUE_TEMPLATE_DIR/04-build-problem.yml"

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
  printf "\n"
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
    printf "Updating Makefile.toml (using FOLDER_NAME: %s)\n" "$PROJECT_NAME"
    replace_in_file "Makefile.toml" 'env\.PROJECT_NAME = "rust_template"' "env.PROJECT_NAME = \"$PROJECT_NAME\""
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
        printf "Kept %s/ and added to .gitignore\n" "$folder"
        printf "%s\n" "$folder" >>./.gitignore
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
  local files=("${GITHUB_FILES[@]}")
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

setup_using_jj() {
  cmd_bin="jj"

  printf "%s command found.\n" "$cmd_bin"

  if ask_yes_no "Do you want to initialize with $cmd_bin (recommended for existing remote)?"; then
    printf "Choose initialization method:\n"
    printf "\t 1) %s git init\n" "$cmd_bin"
    printf "\t 2) %s git init --colocate  (shares .git directory with Git tools)\n" "$cmd_bin"

    while true; do
      read -p "Enter choice (1 or 2): " choice
      case "$choice" in
      1)
        $cmd_bin git init
        break
        ;;
      2)
        $cmd_bin git init --colocate
        break
        ;;
      *) printf "Invalid choice, please enter 1 or 2.\n" ;;
      esac
    done

    return
  fi
  printf "User opted not to use %s for initialization.\n" "$cmd_bin"

  return
}

setup_repository() {
  printf "\n"
  declare cmd_bin "git"

  # Exclude .extras/ from VCS
  printf ".extras/\n" >>.gitignore

  if command -v jj >/dev/null 2>&1; then
    cmd_bin="jj"
  fi

  if [ "$cmd_bin" == "jj" ]; then # S2
    setup_using_jj
    $cmd_bin file untrack ./.extras/
  else
    printf "Falling back to plain git init.\n"
    $cmd_bin init
  fi

  return
}

maybe_remove_setup_script() {
  if ask_yes_no "Do you want to remove the setup script (setup.sh)?"; then
    rm -- "$0"
    printf "Removed setup script.\n"
  else
    printf "Kept setup script.\n"
  fi
}

main() {
  printf "Starting project template setup for folder: %s\n" "$FOLDER_NAME"
  printf "Derived PROJECT_NAME (for Cargo/binary): %s\n" "$PROJECT_NAME"
  printf "\n"

  # Remove the other operating system's setup script
  rm -rf setup.ps1

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

  maybe_remove_setup_script
}

main "$@"

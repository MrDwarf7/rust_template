#!/usr/bin/env bash

set -euo pipefail

# Current directory is the project root
ROOT="$(pwd)"
FOLDER_NAME="$(basename "$ROOT")"

# Strip .rs suffix first for package/binary name, keep full folder name for GitHub repo
REPO_NAME="${FOLDER_NAME}"                    # very_cool.rs (GitHub repo)
PROJECT_NAME="${REPO_NAME%.rs}"                # very_cool (Cargo package, binary)
PROJECT_NAME="${PROJECT_NAME//./_}"            # dots → underscores if any remain

GITHUB_USER="mrdwarf7"

# -y flag: answer yes to all prompts
AUTO_YES=false

# Configurable list of optional folders to ask about removing
FOLDERS_TO_ASK=("data" "scratch")

GITHUB_ISSUE_TEMPLATE_DIR=".github/ISSUE_TEMPLATE"
GITHUB_WORKFLOWS_DIR=".github/workflows"

GITHUB_FILE_PUBLISH=".github/_publish.yml"
GITHUB_FILE_CONFIG=".github/ISSUE_TEMPLATE/config.yml"

GITHUB_FILES=(
  "$GITHUB_WORKFLOWS_DIR/build.yml"
  "$GITHUB_WORKFLOWS_DIR/draft.yml"
  "$GITHUB_WORKFLOWS_DIR/format.yml"
  "$GITHUB_WORKFLOWS_DIR/test.yml"
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

# Process README template: copy to README.md and replace placeholders
process_readme_template() {
  local template="README.template.md"
  local output="README.md"
  
  if [[ ! -f "$template" ]]; then
    printf "Warning: %s not found, skipping README processing.\n" "$template"
    return
  fi
  
  printf "Processing README template...\n"
  cp "$template" "$output"
  
  PROJECT_NAME_UPPER=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  # REPO_NAME already has .rs (e.g., very_cool.rs) - use for GitHub URLs
  # REPO_NAME_CLEAN = without .rs for display
  REPO_NAME_CLEAN="${REPO_NAME%.rs}"
  
  replace_in_file "$output" '{{PROJECT_NAME}}' "$PROJECT_NAME"
  replace_in_file "$output" '{{PROJECT_NAME_UPPER}}' "$PROJECT_NAME_UPPER"
  replace_in_file "$output" '{{GITHUB_USER}}' "$GITHUB_USER"
  replace_in_file "$output" '{{REPO_NAME}}' "$REPO_NAME"  # full with .rs for GitHub URLs
  replace_in_file "$output" '{{SHORT_DESCRIPTION}}' "A brief one-line description"
  replace_in_file "$output" '{{LONG_DESCRIPTION}}' "A longer 2-3 sentence description of what this project does and who it's for."
  replace_in_file "$output" '{{TAGLINE}}' "A compelling tagline"
  
  printf "Generated %s from template\n" "$output"
  
  # Clean up template file
  if [[ "$AUTO_YES" == true ]]; then
    rm -f "$template"
    printf "Removed %s (auto-yes mode)\n" "$template"
  else
    if ask_yes_no "Remove template file %s?" "$template"; then
      rm -f "$template"
      printf "Removed %s\n" "$template"
    else
      # Add to .gitignore if not already there
      if ! grep -q "^README\.template\.md$" .gitignore 2>/dev/null; then
        printf "README.template.md\n" >> .gitignore
        printf "Kept %s and added to .gitignore\n" "$template"
      fi
    fi
  fi
}
# Respects AUTO_YES: if true, automatically answers yes
ask_yes_no() {
  if [[ "$AUTO_YES" == true ]]; then
    return 0
  fi

  printf "\n"
  local prompt="$1"
  while true; do
    read -p "$prompt [Y/n]: " answer
    case "$answer" in
        [Yy]*|"") return 0 ;;
        [Nn]*) return 1 ;;
        *) printf "Please answer y or n.\n" ;;
    esac
  done
}
    # Prompt for a choice from a numbered list.
    # Respects AUTO_YES: if true, picks default_choice (first arg after prompt).
    ask_choice() {
      local prompt="$1"
      local default_choice="$2"
      shift 2

      if [[ "$AUTO_YES" == true ]]; then
        CHOICE_RESULT="$default_choice"
        return
      fi

      while true; do
        read -p "$prompt" choice
        case "$choice" in
        "")
          CHOICE_RESULT="$default_choice"
          return
          ;;
        "$default_choice")
          CHOICE_RESULT="$default_choice"
          return
          ;;
        *)
          # Validate against remaining args
          for valid in "$@"; do
            if [[ "$choice" == "$valid" ]]; then
              CHOICE_RESULT="$choice"
              return
            fi
          done
          printf "Invalid choice.\n"
          ;;
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

remove_cargo_lock() {
  if [[ -f "Cargo.lock" ]]; then
    printf "Removing Cargo.lock...\n"
    rm -f Cargo.lock
  fi
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
    printf "Updating Makefile.toml (using PROJECT_NAME: %s)\n" "$PROJECT_NAME"
    replace_in_file "Makefile.toml" 'env\.PROJECT_NAME = "rust_template"' "env.PROJECT_NAME = \"$PROJECT_NAME\""
    replace_in_file "Makefile.toml" 'env\.REPO_NAME = "rust_template\.rs"' "env.REPO_NAME = \"$REPO_NAME\""
    replace_in_file "Makefile.toml" 'env\.GITHUB_USER = "mrdwarf7"' "env.GITHUB_USER = \"$GITHUB_USER\""
    replace_in_file "Makefile.toml" 'env\.GITHUB_URL = "https://github.com/mrdwarf7/rust_template\.rs"' "env.GITHUB_URL = \"https://github.com/$GITHUB_USER/$REPO_NAME\""
  fi
}

update_cargo_toml() {
  if [[ -f "Cargo.toml" ]]; then
    printf "Updating Cargo.toml (using PROJECT_NAME: %s)\n" "$PROJECT_NAME"
    replace_in_file "Cargo.toml" 'name[[:space:]]*=[[:space:]]*"rust_template"' "name = \"$PROJECT_NAME\""
  fi
}

update_cliff_toml() {
  if [[ -f "cliff.toml" ]]; then
    printf "Updating cliff.toml (using REPO_NAME: %s)\n" "$REPO_NAME"
    # Replace the repo name in the git-cliff postprocessor URL - use REPO_NAME (with .rs)
    replace_in_file "cliff.toml" \
      'mrdwarf7/rust_template' \
      "$GITHUB_USER/$REPO_NAME"
  else
    printf "cliff.toml not found, skipping.\n"
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
    printf "Updating %s (PROJECT_NAME -> %s)\n" "$file" "$PROJECT_NAME"
    # Only replace PROJECT_NAME in the env: section at the top of the file
    awk -v new="$PROJECT_NAME" '
      /^env:/ { in_env=1; print; next }
      in_env && /^[[:space:]]/ {
        sub(/PROJECT_NAME: rust_template/, "PROJECT_NAME: " new)
        print
        next
      }
      in_env && !/^[[:space:]]/ { in_env=0 }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

update_docs_yml() {
  local file=".github/workflows/docs.yml"
  if [[ -f "$file" ]]; then
    printf "Updating %s (PROJECT_NAME -> %s)\n" "$file" "$PROJECT_NAME"
    awk -v new="$PROJECT_NAME" '
      /^env:/ { in_env=1; print; next }
      in_env && /^[[:space:]]/ {
        sub(/PROJECT_NAME: rust_template/, "PROJECT_NAME: " new)
        print
        next
      }
      in_env && !/^[[:space:]]/ { in_env=0 }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

update_issue_template_workflows() {
  local files=("${GITHUB_FILES[@]}")
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      printf "Updating %s (PROJECT_NAME -> %s)\n" "$file" "$PROJECT_NAME"
      # Only replace PROJECT_NAME in the env: section at the top of the file
      awk -v new="$PROJECT_NAME" '
        /^env:/ { in_env=1; print; next }
        in_env && /^[[:space:]]/ {
          sub(/PROJECT_NAME: rust_template/, "PROJECT_NAME: " new)
          print
          next
        }
        in_env && !/^[[:space:]]/ { in_env=0 }
        { print }
      ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
  done
}

update_config_yml() {
  local file="$GITHUB_FILE_CONFIG"
  if [[ -f "$file" ]]; then
    printf "Updating %s (repo URL -> %s)\n" "$file" "$FOLDER_NAME"
    replace_in_file "$file" \
      "url: https://github.com/MrDwarf7/REPO_NAME/discussions" \
      "url: https://github.com/MrDwarf7/$FOLDER_NAME/discussions"
  fi
}

update_install_sh() {
  local file="build/install.sh"
  if [[ -f "$file" ]]; then
    printf "Updating %s (placeholders -> %s)\n" "$file" "$PROJECT_NAME"
    PROJECT_NAME_UPPER=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    replace_in_file "$file" \
      '{{PROJECT_NAME}}' \
      "$PROJECT_NAME"
    replace_in_file "$file" \
      '{{PROJECT_NAME_UPPER}}' \
      "$PROJECT_NAME_UPPER"
    replace_in_file "$file" \
      'REPO="MrDwarf7/{{PROJECT_NAME}}.rs"' \
      "REPO=\"MrDwarf7/$REPO_NAME\""
  fi
}

update_release_tasks() {
  local file="build/release-tasks.toml"
  if [[ -f "$file" ]]; then
    printf "Updating %s (GITHUB_USER -> %s, REPO_NAME -> %s)\n" "$file" "$GITHUB_USER" "$REPO_NAME"
    replace_in_file "$file" \
      '\${GITHUB_USER}' \
      "$GITHUB_USER"
    replace_in_file "$file" \
      '\${REPO_NAME}' \
      "$REPO_NAME"
  fi
}

setup_using_jj() {
  local cmd_bin="jj"
  
  # Check if jj is installed
  if ! command -v jj >/dev/null 2>&1; then
    printf "%s not found, skipping jj initialization.\n" "$cmd_bin"
    return 1
  fi
  
  printf "%s command found.\n" "$cmd_bin"

  if ask_yes_no "Do you want to initialize with $cmd_bin (recommended for existing remote)?"; then
      printf "Choose initialization method:\n"
      printf "\t 1) %s git init\n" "$cmd_bin"
      printf "\t 2) %s git init --colocate  (shares .git directory with Git tools)\n" "$cmd_bin"

      ask_choice "Enter choice (1 or 2) [2]: " "2" "1" "2"
    case "$CHOICE_RESULT" in
    1)
      $cmd_bin git init
      ;;
    2)
      $cmd_bin git init --colocate
      ;;
    esac

    return 0  # initialized with jj
  fi

  printf "User opted not to use %s for initialization.\n" "$cmd_bin"
  return 1  # declined
}

setup_repository() {
  printf "\n"

  # Exclude .extras/ from VCS
  printf ".extras/\n" >>.gitignore

  if command -v jj >/dev/null 2>&1; then
    if setup_using_jj; then
      # Only untrack .extras/ if it's tracked by jj (not just in .gitignore)
      if jj file list .extras/ >/dev/null 2>&1; then
        jj file untrack ./.extras/ 2>/dev/null || true
      fi
      return
    fi
    # User declined jj -> fall through to git init
    printf "Falling back to plain git init.\n"
  fi

  git init
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

usage() {
  printf "Usage: %s [-y]\n" "$0"
  printf "  -y  Answer yes to all prompts automatically\n"
}

parse_args() {
  while getopts "yh" opt; do
    case "$opt" in
    y) AUTO_YES=true ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
    esac
  done
}

main() {
  parse_args "$@"

  printf "Starting project template setup for folder: %s\n" "$FOLDER_NAME"
  printf "Derived PROJECT_NAME (for Cargo/binary): %s\n" "$PROJECT_NAME"
  if [[ "$AUTO_YES" == true ]]; then
    printf "Auto-yes mode: all prompts will be answered with 'y'.\n"
  fi
  printf "\n"

  # Remove the other operating system's setup script
  rm -rf setup.ps1

  remove_vcs_dirs
  remove_target
  remove_cargo_lock
  maybe_remove_bacon
  update_makefile_toml
  update_cargo_toml
  update_cliff_toml
  maybe_remove_optional_folders
  update_github_publish
  update_docs_yml
  update_issue_template_workflows
  update_config_yml
  update_install_sh
  update_release_tasks
  process_readme_template
  setup_repository

  printf "\n"
  printf "Setup complete!\n"

  maybe_remove_setup_script
}

main "$@"

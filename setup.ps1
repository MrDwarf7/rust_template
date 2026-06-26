<# 
PowerShell version of the project template setup script.
Run this in the root of your new project folder.

Usage: .\setup.ps1 [-y]
  -y  Answer yes to all prompts automatically
#>

param(
  [switch]$y
)

$ErrorActionPreference = "Stop"

# Current directory is the project root
$ROOT = Get-Location
$FOLDER_NAME = Split-Path -Leaf $ROOT
# Strip .rs suffix first, then dots to underscores for PROJECT_NAME (cargo package, binary, makefile)
$PROJECT_NAME = $FOLDER_NAME -replace '\.rs$', ''
$PROJECT_NAME = $PROJECT_NAME -replace '\.', '_'
# Repo name for GitHub URLs (keep .rs for cliff.toml, install.sh REPO)
$REPO_NAME = $FOLDER_NAME
# Repo name without .rs for README links
$REPO_NAME_CLEAN = $REPO_NAME -replace '\.rs$', ''

# -y flag: answer yes to all prompts
$AUTO_YES = $y.IsPresent
$GITHUB_USER = "mrdwarf7"

# Configurable list of optional folders to ask about removing
$FOLDERS_TO_ASK = @("data", "scratch")

$GITHUB_ISSUE_TEMPLATE_DIR = ".github/ISSUE_TEMPLATE"
$GITHUB_WORKFLOWS_DIR = ".github/workflows"

$GITHUB_FILE_PUBLISH = ".github/_publish.yml"
$GITHUB_FILE_CONFIG = ".github/ISSUE_TEMPLATE/config.yml"

$GITHUB_FILES = @(
  "$GITHUB_WORKFLOWS_DIR/build.yml"
  "$GITHUB_WORKFLOWS_DIR/draft.yml"
  "$GITHUB_WORKFLOWS_DIR/format.yml"
  "$GITHUB_WORKFLOWS_DIR/test.yml"
)

function Replace-InFile {
    param(
        [string]$File,
        [string]$Pattern,
        [string]$Replacement
    )

    if (-not (Test-Path $File)) {
        Write-Host "Warning: $File not found, skipping."
        return
    }

    (Get-Content $File -Raw) -replace $Pattern, $Replacement | Set-Content $File
}

# Process README template: copy to README.md and replace placeholders
function Process-ReadmeTemplate {
    $template = "README.template.md"
    $output = "README.md"
    
    if (-not (Test-Path $template)) {
        Write-Host "Warning: $template not found, skipping README processing."
        return
    }
    
    Write-Host "Processing README template..."
    Copy-Item $template $output -Force
    
    $PROJECT_NAME_UPPER = $PROJECT_NAME.ToUpper().Replace('-', '_')
    # REPO_NAME already has .rs (e.g., very_cool.rs) - use for GitHub URLs
    # REPO_NAME_CLEAN = without .rs for display
    $REPO_NAME_CLEAN = $REPO_NAME -replace '\.rs$', ''
    
    Replace-InFile $output '{{PROJECT_NAME}}' $PROJECT_NAME
    Replace-InFile $output '{{PROJECT_NAME_UPPER}}' $PROJECT_NAME_UPPER
    Replace-InFile $output '{{GITHUB_USER}}' $GITHUB_USER
    Replace-InFile $output '{{REPO_NAME}}' $REPO_NAME  # full with .rs for GitHub URLs
    Replace-InFile $output '{{SHORT_DESCRIPTION}}' "A brief one-line description"
    Replace-InFile $output '{{LONG_DESCRIPTION}}' "A longer 2-3 sentence description of what this project does and who it's for."
    Replace-InFile $output '{{TAGLINE}}' "A compelling tagline"
    
    Write-Host "Generated $output from template"
    
    # Clean up template file
    if ($AUTO_YES) {
        Remove-Item $template -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $template (auto-yes mode)"
    } else {
        if (Ask-YesNo "Remove template file $template?") {
            Remove-Item $template -Force -ErrorAction SilentlyContinue
            Write-Host "Removed $template"
        } else {
            # Add to .gitignore if not already there
            if (-not (Select-String -Path .gitignore -Pattern "^README\.template\.md$" -Quiet)) {
                Add-Content -Path .gitignore -Value "README.template.md"
                Write-Host "Kept $template and added to .gitignore"
            }
        }
    }
}

function Ask-YesNo {
    param([string]$Prompt)

    if ($AUTO_YES) {
        return $true
    }

    Write-Host ""
    while ($true) {
        $answer = Read-Host "$Prompt [Y/n]"
        if ($answer -match '^[Yy]') { return $true }
        if ($answer -match '^[Nn]') { return $false }
        if ($answer -eq "") { return $true }  # default to yes on enter
        Write-Host "Please answer y or n."
    }
}

function Remove-VcsDirs {
    Write-Host "Removing any existing .git or .jj directories..."
    Remove-Item -Path .git, .jj -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-CargoLock {
    if (Test-Path "Cargo.lock") {
        Write-Host "Removing Cargo.lock..."
        Remove-Item "Cargo.lock" -Force
    }
}

function Maybe-RemoveBacon {
    if (Test-Path "bacon.toml") {
        if (Ask-YesNo "Do you want to remove bacon.toml?") {
            Remove-Item "bacon.toml" -Force
            Write-Host "Removed bacon.toml"
        } else {
            Write-Host "Kept bacon.toml"
        }
    }
}

function Update-MakefileToml {
    if (Test-Path "Makefile.toml") {
        Write-Host "Updating Makefile.toml (using PROJECT_NAME: $PROJECT_NAME)"
        Replace-InFile "Makefile.toml" 'env\.PROJECT_NAME = "rust_template"' "env.PROJECT_NAME = `"$PROJECT_NAME`""
        Replace-InFile "Makefile.toml" 'env\.REPO_NAME = "rust_template\.rs"' "env.REPO_NAME = `"$REPO_NAME`""
        Replace-InFile "Makefile.toml" 'env\.GITHUB_USER = "mrdwarf7"' "env.GITHUB_USER = `"$GITHUB_USER`""
        Replace-InFile "Makefile.toml" 'env\.GITHUB_URL = "https://github.com/mrdwarf7/rust_template\.rs"' "env.GITHUB_URL = `"https://github.com/$GITHUB_USER/$REPO_NAME`""
    }
}

function Update-CargoToml {
    if (Test-Path "Cargo.toml") {
        Write-Host "Updating Cargo.toml (using PROJECT_NAME: $PROJECT_NAME)"
        Replace-InFile "Cargo.toml" 'name\s*=\s*"rust_template"' "name = `"$PROJECT_NAME`""
    }
}

function Update-CliffToml {
    if (Test-Path "cliff.toml") {
        Write-Host "Updating cliff.toml (using REPO_NAME: $REPO_NAME)"
        # Replace the repo name in the git-cliff postprocessor URL - use REPO_NAME (with .rs)
        Replace-InFile "cliff.toml" 'mrdwarf7/rust_template' "$GITHUB_USER/$REPO_NAME"
    } else {
        Write-Host "cliff.toml not found, skipping."
    }
}

function Maybe-RemoveOptionalFolders {
    foreach ($folder in $FOLDERS_TO_ASK) {
        if (Test-Path $folder -PathType Container) {
            if (Ask-YesNo "Do you want to remove the $folder/ folder?") {
                Remove-Item $folder -Recurse -Force
                Write-Host "Removed $folder/"
            } else {
                Write-Host "Kept $folder/ and added to .gitignore"
                Add-Content -Path ./.gitignore -Value "/$folder/"
            }
        }
    }
}

function Update-GithubPublish {
    $file = $GITHUB_FILE_PUBLISH
    if (Test-Path $file) {
        Write-Host "Updating $file (PROJECT_NAME -> $PROJECT_NAME)"
        # Only replace PROJECT_NAME in the env: section at the top of the file
        $content = Get-Content $file -Raw
        $lines = $content -split '\r?\n'
        $in_env = $false
        $new_lines = @()
        foreach ($line in $lines) {
            if ($line -match '^env:') {
                $in_env = $true
                $new_lines += $line
            } elseif ($in_env -and $line -match '^\s') {
                $new_lines += $line -replace 'PROJECT_NAME: rust_template', "PROJECT_NAME: $PROJECT_NAME"
            } elseif ($in_env -and $line -notmatch '^\s') {
                $in_env = $false
                $new_lines += $line
            } else {
                $new_lines += $line
            }
        }
        $new_lines -join "`n" | Set-Content $file
    }
}

function Update-DocsYml {
    $file = ".github/workflows/docs.yml"
    if (Test-Path $file) {
        Write-Host "Updating $file (PROJECT_NAME -> $PROJECT_NAME)"
        $content = Get-Content $file -Raw
        $lines = $content -split '\r?\n'
        $in_env = $false
        $new_lines = @()
        foreach ($line in $lines) {
            if ($line -match '^env:') {
                $in_env = $true
                $new_lines += $line
            } elseif ($in_env -and $line -match '^\s') {
                $new_lines += $line -replace 'PROJECT_NAME: rust_template', "PROJECT_NAME: $PROJECT_NAME"
            } elseif ($in_env -and $line -notmatch '^\s') {
                $in_env = $false
                $new_lines += $line
            } else {
                $new_lines += $line
            }
        }
        $new_lines -join "`n" | Set-Content $file
    }
}

function Update-IssueTemplateWorkflows {
    foreach ($file in $GITHUB_FILES) {
        if (Test-Path $file) {
            Write-Host "Updating $file (PROJECT_NAME -> $PROJECT_NAME)"
            $content = Get-Content $file -Raw
            $lines = $content -split '\r?\n'
            $in_env = $false
            $new_lines = @()
            foreach ($line in $lines) {
                if ($line -match '^env:') {
                    $in_env = $true
                    $new_lines += $line
                } elseif ($in_env -and $line -match '^\s') {
                    $new_lines += $line -replace 'PROJECT_NAME: rust_template', "PROJECT_NAME: $PROJECT_NAME"
                } elseif ($in_env -and $line -notmatch '^\s') {
                    $in_env = $false
                    $new_lines += $line
                } else {
                    $new_lines += $line
                }
            }
            $new_lines -join "`n" | Set-Content $file
        }
    }
}

function Update-ConfigYml {
    $file = $GITHUB_FILE_CONFIG
    if (Test-Path $file) {
        Write-Host "Updating $file (repo URL -> $FOLDER_NAME)"
        Replace-InFile $file "url: https://github.com/MrDwarf7/REPO_NAME/discussions" "url: https://github.com/MrDwarf7/$FOLDER_NAME/discussions"
    }
}

function Update-InstallSh {
    $file = "build/install.sh"
    if (Test-Path $file) {
        Write-Host "Updating $file (placeholders -> $PROJECT_NAME)"
        $PROJECT_NAME_UPPER = $PROJECT_NAME.ToUpper().Replace('-', '_')
        Replace-InFile $file '{{PROJECT_NAME}}' $PROJECT_NAME
        Replace-InFile $file '{{PROJECT_NAME_UPPER}}' $PROJECT_NAME_UPPER
        Replace-InFile $file 'REPO="MrDwarf7/{{PROJECT_NAME}}.rs"' "REPO=`"MrDwarf7/$REPO_NAME`""
    }
}

function Update-ReleaseTasks {
    $file = "build/release-tasks.toml"
    if (Test-Path $file) {
        Write-Host "Updating $file (GITHUB_USER -> $GITHUB_USER, REPO_NAME -> $REPO_NAME)"
        Replace-InFile $file '\${GITHUB_USER}' $GITHUB_USER
        Replace-InFile $file '\${REPO_NAME}' $REPO_NAME
    }
}

function Process-ReadmeTemplate {
    $template = "README.template.md"
    $output = "README.md"
    
    if (-not (Test-Path $template)) {
        Write-Host "Warning: $template not found, skipping README processing."
        return
    }
    
    Write-Host "Processing README template..."
    Copy-Item $template $output -Force
    
    $PROJECT_NAME_UPPER = $PROJECT_NAME.ToUpper().Replace('-', '_')
    # REPO_NAME already has .rs (e.g., very_cool.rs) - use for GitHub URLs
    # REPO_NAME_CLEAN = without .rs for display
    $REPO_NAME_CLEAN = $REPO_NAME -replace '\.rs$', ''
    
    Replace-InFile $output '{{PROJECT_NAME}}' $PROJECT_NAME
    Replace-InFile $output '{{PROJECT_NAME_UPPER}}' $PROJECT_NAME_UPPER
    Replace-InFile $output '{{GITHUB_USER}}' $GITHUB_USER
    Replace-InFile $output '{{REPO_NAME}}' $REPO_NAME  # full with .rs for GitHub URLs
    Replace-InFile $output '{{SHORT_DESCRIPTION}}' "A brief one-line description"
    Replace-InFile $output '{{LONG_DESCRIPTION}}' "A longer 2-3 sentence description of what this project does and who it's for."
    Replace-InFile $output '{{TAGLINE}}' "A compelling tagline"
    
    Write-Host "Generated $output from template"
    
    # Clean up template file
    if ($AUTO_YES) {
        Remove-Item $template -Force -ErrorAction SilentlyContinue
        Write-Host "Removed $template (auto-yes mode)"
    } else {
        if (Ask-YesNo "Remove template file $template?") {
            Remove-Item $template -Force -ErrorAction SilentlyContinue
            Write-Host "Removed $template"
        } else {
            # Add to .gitignore if not already there
            if (-not (Select-String -Path .gitignore -Pattern "^README\.template\.md$" -Quiet)) {
                Add-Content -Path .gitignore -Value "README.template.md"
                Write-Host "Kept $template and added to .gitignore"
            }
        }
    }
}

function Setup-UsingJJ {
    $cmd_bin = "jj"

    Write-Host "jj command found."
    if (Ask-YesNo "Do you want to initialize with jj (recommended for existing remote)?") {
      Write-Host "Choose initialization method:"
      Write-Host "`t 1) jj git init"
      Write-Host "`t 2) jj git init --colocate  (shares .git directory with Git tools)"

      while ($true) {
        if ($AUTO_YES) {
          $choice = "2"
        } else {
          $choice = Read-Host "Enter choice (1 or 2) [2]"
        }
        if ($choice -eq "1") {
          jj git init
          return $true
        } elseif ($choice -eq "2" -or $choice -eq "") {
          jj git init --colocate
          return $true
        } else {
          Write-Host "Invalid choice, please enter 1 or 2."
        }
      }
    }

    Write-Host "User opted not to use jj for initialization."
    return $false
}

function Setup-Repository {
    Write-Host ""

    Add-Content -Path ./.gitignore -Value \"./.extras/\"

    if (Get-Command jj -ErrorAction SilentlyContinue) {
      if (Setup-UsingJJ) {
        # Only untrack .extras/ if it exists in the working copy
        if (Test-Path .extras -PathType Container -and (jj file list .extras/ -q 2>$null)) {
          Invoke-Expression "jj file untrack .extras"
        }
        return
      }
      # User declined jj -> fall through to git init
      Write-Host "Falling back to plain git init."
    }

    git init
    Write-Host "Initialized empty Git repository. You can create the GitHub repo later and add it as remote."
    return
}

function Maybe-RemoveSetupScript {
    if (Test-Path "setup.ps1") {
      if (Ask-YesNo "Do you want to remove setup.ps1?") {
        Remove-Item "setup.ps1" -Force
        Write-Host "Removed setup.ps1"
      } else {
        Write-Host "Kept setup.ps1"
      }
    }
    return
}

function Main {
    Write-Host "Starting project template setup for folder: $FOLDER_NAME"
    Write-Host "Derived PROJECT_NAME (for Cargo/binary): $PROJECT_NAME"
    if ($AUTO_YES) {
      Write-Host "Auto-yes mode: all prompts will be answered with 'y'."
    }
    Write-Host ""

    # Remove the other operating system's setup script
    Remove-Item -Path setup.sh -Force -ErrorAction SilentlyContinue

    Remove-VcsDirs
    Remove-Target
    Maybe-RemoveBacon
    Update-MakefileToml
    Update-CargoToml
    Update-CliffToml
    Maybe-RemoveOptionalFolders
    Update-GithubPublish
    Update-DocsYml
    Update-IssueTemplateWorkflows
    Update-ConfigYml
    Update-InstallSh
    Update-ReleaseTasks
    Process-ReadmeTemplate
      Setup-Repository

    Write-Host ""
    Write-Host "Setup complete!"
    Maybe-RemoveSetupScript
}

Main

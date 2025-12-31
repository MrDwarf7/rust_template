<# 
PowerShell version of the project template setup script.
Run this in the root of your new project folder.
#>

$ErrorActionPreference = "Stop"

# Current directory is the project root
$ROOT = Get-Location
$FOLDER_NAME = Split-Path -Leaf $ROOT
$PROJECT_NAME = $FOLDER_NAME -replace '\.', '_'

# Configurable list of optional folders to ask about removing
$FOLDERS_TO_ASK = @("data", "scratch")

$GITHUB_FILE_PUBLISH = ".github/_publish.yml"
$GITHUB_FILE_CONFIG = ".github/workflows/config.yml"

$GITHUB_FILE_WORKFLOWS = @(
    ".github/workflows/01-bug.yml"
    ".github/workflows/02-feature-request.yml"
    ".github/workflows/03-docs-problem.yml"
    ".github/workflows/04-build-problem.yml"
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

function Ask-YesNo {
    param([string]$Prompt)

    while ($true) {
        $answer = Read-Host "$Prompt [y/n]"
        if ($answer -match '^[Yy]') { return $true }
        if ($answer -match '^[Nn]') { return $false }
        Write-Host "Please answer y or n."
    }
}

function Remove-VcsDirs {
    Write-Host "Removing any existing .git or .jj directories..."
    Remove-Item -Path .git, .jj -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-Target {
    Write-Host "Removing target/ directory..."
    Remove-Item -Path target -Recurse -Force -ErrorAction SilentlyContinue
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
        Write-Host "Updating Makefile.toml (using FOLDER_NAME: $FOLDER_NAME)"
        Replace-InFile "Makefile.toml" 'env\.PROJECT_NAME = "rust_template"' "env.PROJECT_NAME = `"$FOLDER_NAME`""
    }
}

function Update-CargoToml {
    if (Test-Path "Cargo.toml") {
        Write-Host "Updating Cargo.toml (using PROJECT_NAME: $PROJECT_NAME)"
        Replace-InFile "Cargo.toml" 'name\s*=\s*"rust_template"' "name = `"$PROJECT_NAME`""
    }
}

function Maybe-RemoveOptionalFolders {
    foreach ($folder in $FOLDERS_TO_ASK) {
        if (Test-Path $folder -PathType Container) {
            if (Ask-YesNo "Do you want to remove the $folder/ folder?") {
                Remove-Item $folder -Recurse -Force
                Write-Host "Removed $folder/"
            } else {
                Write-Host "Kept $folder/"
            }
        }
    }
}

function Update-GithubPublish {
    $file = $GITHUB_FILE_PUBLISH
    if (Test-Path $file) {
        Write-Host "Updating $file (PROJECT_NAME → $PROJECT_NAME)"
        Replace-InFile $file "PROJECT_NAME: rust_template" "PROJECT_NAME: $PROJECT_NAME"
    }
}

function Update-IssueTemplateWorkflows {
    foreach ($file in $GITHUB_FILE_WORKFLOWS) {
        if (Test-Path $file) {
            Write-Host "Updating $file (PROJECT_NAME → $PROJECT_NAME)"
            Replace-InFile $file "PROJECT_NAME: rust_template" "PROJECT_NAME: $PROJECT_NAME"
        }
    }
}

function Update-ConfigYml {
    $file = $GITHUB_FILE_CONFIG
    if (Test-Path $file) {
        Write-Host "Updating $file (repo URL → $FOLDER_NAME)"
        Replace-InFile $file "url: https://github.com/MrDwarf7/REPO_NAME/discussions" "url: https://github.com/MrDwarf7/$FOLDER_NAME/discussions"
    }
}

function Setup-Repository {
    Write-Host ""

    if (Ask-YesNo "Have you already set up the GitHub repository (remote exists)?") {
        # Remote exists → offer jj colocation option if available
        if (Get-Command jj -ErrorAction SilentlyContinue) {
            Write-Host "jj command found."
            if (Ask-YesNo "Do you want to initialize with jj (recommended for existing remote)?") {
                Write-Host "Choose initialization method:"
                Write-Host "  1) jj git init"
                Write-Host "  2) jj git init --colocate  (shares .git directory with Git tools)"

                while ($true) {
                    $choice = Read-Host "Enter choice (1 or 2)"
                    if ($choice -eq "1") {
                        jj git init
                        break
                    }
                    elseif ($choice -eq "2") {
                        jj git init --colocate
                        break
                    }
                    else {
                        Write-Host "Invalid choice, please enter 1 or 2."
                    }
                }
                return
            }
        }
        else {
            Write-Host "jj not available."
        }

        # Fallback to plain git init
        git init
        Write-Host "Initialized empty Git repository."
    }
    else {
        # No remote yet → default to plain git init
        Write-Host "No existing remote. Initializing a fresh Git repository."
        git init
        Write-Host "Initialized empty Git repository. You can create the GitHub repo later and add it as remote."
    }
}

function Main {
    Write-Host "Starting project template setup for folder: $FOLDER_NAME"
    Write-Host "Derived PROJECT_NAME (for Cargo/binary): $PROJECT_NAME"
    Write-Host ""

    Remove-VcsDirs
    Remove-Target
    Maybe-RemoveBacon
    Update-MakefileToml
    Update-CargoToml
    Maybe-RemoveOptionalFolders
    Update-GithubPublish
    Update-IssueTemplateWorkflows
    Update-ConfigYml
    Setup-Repository

    Write-Host ""
    Write-Host "Setup complete!"
}

Main

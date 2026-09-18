<#
  Cross-device Claude Code setup for a fresh Windows PC.
  Run in PowerShell:  irm https://raw.githubusercontent.com/Bifrost41g/claude-code-bootstrap/main/bootstrap.ps1 | iex

  What this does:
    1. Installs base programs via winget (Git, Node.js LTS, VS Code, GitHub CLI, Windows Terminal)
    2. Installs the Claude Code CLI natively if missing
    3. Checks out the private claude-code-config repo into ~/.claude (settings, CLAUDE.md,
       hooks/, commands/, keybindings, the curated agents/ and setup/ - never touches
       sessions/cache/credentials)
    4. Installs the Impeccable design skill (installer-managed, so not in the repo)
    5. Prints next steps (claude login, gh auth login, project folder setup)

  Safe to re-run - every step is idempotent.
#>

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-CommandExists($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# 1. Base programs via winget
# ---------------------------------------------------------------------------
Write-Step "Installing base programs via winget"

if (-not (Test-CommandExists winget)) {
    Write-Warning "winget not found - skipping automatic program installation. Install App Installer from the Microsoft Store, then re-run this script."
}
else {
    $packages = @(
        "Git.Git",
        "OpenJS.NodeJS.LTS",
        "Microsoft.VisualStudioCode",
        "GitHub.cli",
        "Microsoft.WindowsTerminal"
    )
    foreach ($pkg in $packages) {
        Write-Host "  - $pkg"
        try {
            winget install --id $pkg -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
        }
        catch {
            Write-Warning "  Could not install $pkg automatically ($($_.Exception.Message)). Install it manually if needed."
        }
    }
    # Refresh PATH for this process so git/node are usable without restarting the shell
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ---------------------------------------------------------------------------
# 2. Claude Code CLI
# ---------------------------------------------------------------------------
Write-Step "Checking Claude Code CLI"

if (Test-CommandExists claude) {
    Write-Host "  Already installed: $(claude --version)"
}
else {
    Write-Host "  Installing Claude Code..."
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
}

# ---------------------------------------------------------------------------
# 3. Private config repo -> ~/.claude
# ---------------------------------------------------------------------------
Write-Step "Syncing Claude Code config from private repo"

$claudeHome = "$env:USERPROFILE\.claude"
$configRepoUrl = "https://github.com/Bifrost41g/claude-code-config.git"

if (-not (Test-Path $claudeHome)) {
    New-Item -ItemType Directory -Path $claudeHome | Out-Null
}

# Back up anything Claude Code itself may have already created for these
# specific tracked files, so a checkout never silently discards local content.
$trackedTopLevel = @("settings.json", "CLAUDE.md", "keybindings.json")
foreach ($f in $trackedTopLevel) {
    $full = Join-Path $claudeHome $f
    if ((Test-Path $full) -and -not (Test-Path (Join-Path $claudeHome ".git"))) {
        Copy-Item $full "$full.pre-sync-backup" -Force
        Write-Host "  Backed up existing $f -> $f.pre-sync-backup"
    }
}

Push-Location $claudeHome
try {
    if (-not (Test-Path ".git")) {
        git init -q
        git remote add origin $configRepoUrl
    }
    git fetch --quiet origin
    git checkout -B main origin/main --force
    Write-Host "  ~/.claude now tracks $configRepoUrl (settings.json, CLAUDE.md, hooks/, commands/, keybindings.json)"
}
finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# 4. Installer-managed skills
#
# Subagents are NOT installed here - the curated set ships inside the config
# repo from step 3. Only tools with their own installer belong in this step,
# because a file that an installer owns must not also be tracked by git.
# ---------------------------------------------------------------------------
Write-Step "Installing the Impeccable design skill"

if (Test-CommandExists npx) {
    try {
        npx -y impeccable@latest install --scope=global --providers=claude-code --yes
        Write-Host "  Installed (skill, its agents, and its hooks in settings.local.json)"
    }
    catch {
        Write-Warning "  Could not install Impeccable ($($_.Exception.Message)). Run manually later: npx -y impeccable@latest install --scope=global --providers=claude-code --yes"
    }
}
else {
    Write-Warning "  npx not found - install Node.js, then run: npx -y impeccable@latest install --scope=global --providers=claude-code --yes"
}

# ---------------------------------------------------------------------------
# 5. Next steps
# ---------------------------------------------------------------------------
Write-Step "Done - remaining manual steps"
Write-Host @"

  1. Restart this terminal (so newly installed programs are on PATH).
  2. Run: claude login
     -> also activates the official skills/plugins auto-sync for this account.
  3. Run: gh auth login
     -> needed for git operations against your private repos.
  4. Run: & "`$env:USERPROFILE\.claude\setup\projects.ps1"
     -> creates the project folder structure and clones the project repos.
        Needs step 3 first; safe to re-run.

  Everything that is deliberately NOT in the config repo - and how to restore
  it - is documented in ~\.claude\setup\README.md

  Cross-device config sync is now active: Claude Code will ask you at the
  start of a session if there are changes to pull, and after a turn if
  there are local changes worth pushing.
"@

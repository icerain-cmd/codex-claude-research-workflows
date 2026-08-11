[CmdletBinding()]
param(
    [string]$InstallRoot = $(if ($env:CODEX_CLAUDE_WORKFLOWS_HOME) { $env:CODEX_CLAUDE_WORKFLOWS_HOME } else { Join-Path $HOME "codex-claude-research-tools" }),
    [switch]$SkipSkillLinks,
    [switch]$SkipPythonDeps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message"
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Command $($Arguments -join ' ')"
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required but was not found on PATH."
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonExe = "py"
    $PythonPrefix = @("-3")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonExe = "python"
    $PythonPrefix = @()
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $PythonExe = "python3"
    $PythonPrefix = @()
} else {
    throw "Python 3.9 or newer is required."
}

function Invoke-Python {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $AllArguments = @($script:PythonPrefix) + $Arguments
    Invoke-Native -Command $script:PythonExe -Arguments $AllArguments
}

Invoke-Python -Arguments @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)")

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$BookRepo = Join-Path $InstallRoot "book-to-skill"
$TranslateRepo = Join-Path $InstallRoot "translate-book"

function Sync-Repo {
    param(
        [string]$Url,
        [string]$Path,
        [string]$Branch
    )

    if (Test-Path (Join-Path $Path ".git")) {
        Write-Step "Updating $(Split-Path $Path -Leaf)"
        Invoke-Native -Command "git" -Arguments @("-C", $Path, "fetch", "origin", $Branch)
        Invoke-Native -Command "git" -Arguments @("-C", $Path, "checkout", $Branch)
        Invoke-Native -Command "git" -Arguments @("-C", $Path, "pull", "--ff-only", "origin", $Branch)
    } elseif (Test-Path $Path) {
        throw "$Path exists but is not a Git repository. Move it or choose another -InstallRoot."
    } else {
        Write-Step "Cloning $(Split-Path $Path -Leaf)"
        Invoke-Native -Command "git" -Arguments @("clone", "--branch", $Branch, "--single-branch", $Url, $Path)
    }
}

Sync-Repo -Url "https://github.com/icerain-cmd/book-to-skill.git" -Path $BookRepo -Branch "master"
Sync-Repo -Url "https://github.com/icerain-cmd/translate-book.git" -Path $TranslateRepo -Branch "main"

if (-not $SkipPythonDeps) {
    Write-Step "Installing Research-to-Skill and common document dependencies"
    Invoke-Python -Arguments @("-m", "pip", "--version")
    Invoke-Python -Arguments @("-m", "pip", "install", "-e", "$BookRepo[pdf,docx]")

    Write-Step "Installing scholarly translation Python helpers"
    Invoke-Python -Arguments @("-m", "pip", "install", "pypandoc", "beautifulsoup4")
} else {
    Write-Warning "Python dependency installation skipped."
}

function Ensure-SkillLink {
    param(
        [string]$Target,
        [string]$Source
    )

    $Parent = Split-Path $Target -Parent
    New-Item -ItemType Directory -Force -Path $Parent | Out-Null

    if (Test-Path $Target) {
        Write-Warning "Skill path already exists; leaving it unchanged: $Target"
        return
    }

    try {
        New-Item -ItemType Junction -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "OK: junction $Target -> $Source"
        return
    } catch {
        Write-Warning "Junction creation failed for $Target; trying a symbolic link. This can happen when the source is on a network/shared drive."
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "OK: symbolic link $Target -> $Source"
        return
    } catch {
        Write-Warning "Could not create a skill link at $Target. The component checkout is still installed at $Source."
        Write-Warning "Fallback: run 'npx skills add icerain-cmd/translate-book -a codex -g' and/or 'npx skills add icerain-cmd/translate-book -a claude-code -g'."
    }
}

if (-not $SkipSkillLinks) {
    Write-Step "Linking the maintained translate-book fork into agent skill directories"
    Ensure-SkillLink -Target (Join-Path $HOME ".agents\skills\translate-book") -Source $TranslateRepo
    Ensure-SkillLink -Target (Join-Path $HOME ".claude\skills\translate-book") -Source $TranslateRepo
} else {
    Write-Warning "Agent skill links skipped."
}

Write-Step "Checking external tools"
foreach ($Command in @("pandoc", "ebook-convert")) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "OK: $Command"
    } else {
        Write-Warning "$Command not found. It is required for full PDF/DOCX/EPUB translation conversion."
    }
}

if (Get-Command research-to-skill -ErrorAction SilentlyContinue) {
    Invoke-Native -Command "research-to-skill" -Arguments @("--help")
    Write-Host "OK: research-to-skill CLI is available on PATH."
} else {
    Write-Warning "research-to-skill was installed but is not visible on PATH in this shell. Check your Python Scripts directory."
}

Write-Host "`nInstallation root:"
Write-Host "  $InstallRoot"
Write-Host "`nComponents:"
Write-Host "  $BookRepo"
Write-Host "  $TranslateRepo"
Write-Host "`nNext:"
Write-Host "  .\doctor.ps1 -InstallRoot `"$InstallRoot`""

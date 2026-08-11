[CmdletBinding()]
param(
    [string]$InstallRoot = $(if ($env:CODEX_CLAUDE_WORKFLOWS_HOME) { $env:CODEX_CLAUDE_WORKFLOWS_HOME } else { Join-Path $HOME "codex-claude-research-tools" })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$Failures = 0
$Warnings = 0

function Pass([string]$Message) { Write-Host "PASS  $Message" }
function Warn([string]$Message) { $script:Warnings++; Write-Host "WARN  $Message" }
function Fail([string]$Message) { $script:Failures++; Write-Host "FAIL  $Message" }

Write-Host "Codex · Claude Code Research Workflows doctor"
Write-Host "Install root: $InstallRoot`n"

if (Get-Command git -ErrorAction SilentlyContinue) { Pass "git" } else { Fail "git is required but not found" }

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
    $PythonExe = $null
    $PythonPrefix = @()
    Fail "Python 3 not found"
}

function Invoke-PythonCheck {
    param([string[]]$Arguments)
    if (-not $script:PythonExe) { return $false }
    $AllArguments = @($script:PythonPrefix) + $Arguments
    & $script:PythonExe @AllArguments *> $null
    return ($LASTEXITCODE -eq 0)
}

if ($PythonExe) {
    if (Invoke-PythonCheck -Arguments @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)")) {
        $VersionArgs = @($PythonPrefix) + @("--version")
        $Version = (& $PythonExe @VersionArgs 2>&1 | Out-String).Trim()
        Pass "Python: $Version"
    } else {
        Fail "Python 3.9 or newer is required"
    }
}

foreach ($Repo in @("book-to-skill", "translate-book")) {
    $RepoPath = Join-Path $InstallRoot $Repo
    if (Test-Path (Join-Path $RepoPath ".git")) {
        $Branch = (& git -C $RepoPath branch --show-current 2>$null | Out-String).Trim()
        $Head = (& git -C $RepoPath rev-parse --short HEAD 2>$null | Out-String).Trim()
        if (-not $Branch) { $Branch = "detached" }
        Pass "$Repo repository: branch=$Branch head=$Head"
    } else {
        Fail "$Repo repository missing at $RepoPath"
    }
}

if (Get-Command research-to-skill -ErrorAction SilentlyContinue) {
    & research-to-skill --help *> $null
    if ($LASTEXITCODE -eq 0) { Pass "research-to-skill CLI" } else { Fail "research-to-skill exists but --help failed" }
} else {
    Fail "research-to-skill CLI not found on PATH"
}

if ($PythonExe) {
    foreach ($Module in @("pypandoc", "bs4")) {
        if (Invoke-PythonCheck -Arguments @("-c", "import $Module")) { Pass "Python module: $Module" } else { Warn "Python module missing: $Module" }
    }
}

foreach ($Command in @("pandoc", "ebook-convert", "codex", "claude")) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) { Pass $Command } else { Warn "$Command not found" }
}

foreach ($SkillPath in @(
    (Join-Path $HOME ".agents\skills\translate-book"),
    (Join-Path $HOME ".claude\skills\translate-book")
)) {
    if (Test-Path $SkillPath) { Pass "skill path: $SkillPath" } else { Warn "skill path missing: $SkillPath" }
}

Write-Host "`nSummary: $Failures failure(s), $Warnings warning(s)"
if ($Failures -gt 0) { exit 1 }
exit 0

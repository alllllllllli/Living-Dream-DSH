# ============================================================
# Living Dream DSH - Headless Setup Script (Inno Setup helper)
# Called by Inno Setup installer during installation.
# ============================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir,
    [switch]$Offline,
    [switch]$CreateDshShortcut,
    [string]$DepSource = ""
)

$ErrorActionPreference = "Continue"
$script:logFile = "$env:TEMP\dsh-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:dshExe = $null

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] $msg"
    Write-Host $line
    $line | Out-File $script:logFile -Append -Encoding UTF8
}

function Test-Command($cmd) {
    try { Get-Command $cmd -ErrorAction Stop; return $true }
    catch { return $false }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Find-Dep($pattern) {
    if ($DepSource) {
        Get-ChildItem $DepSource -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    }
}

Write-Log "=== Living Dream DSH Setup v2.9.0 ==="
Write-Log "InstallDir: $InstallDir"
Write-Log "Mode: $(if ($Offline) { 'OFFLINE' } else { 'Online' })"
Write-Log ""

# ── Step 1: Node.js ────────────────────────────────────────
Write-Log "[1/9] Checking Node.js..."
if (Test-Command "node") {
    Write-Log "  Node.js $(node --version 2>&1) ✓"
} elseif ($Offline) {
    $nodeMsi = Find-Dep "node-*.msi"
    if ($nodeMsi) {
        Write-Log "  Installing $($nodeMsi.Name) from deps/..."
        & cmd /c "msiexec /i `"$($nodeMsi.FullName)`" /qn /norestart >nul 2>&1"
        Refresh-Path
        if (Test-Command "node") { Write-Log "  Node.js installed ✓" } else { Write-Log "  ✗ Node.js install failed" }
    } else { Write-Log "  ✗ No node-*.msi in deps/"; exit 1 }
} else {
    Write-Log "  Installing Node.js via winget..."
    & cmd /c "winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements >nul 2>&1"
    Refresh-Path
    if (Test-Command "node") { Write-Log "  Node.js installed ✓" } else { Write-Log "  ✗ Failed to install Node.js"; exit 1 }
}

# ── Step 2: Python ─────────────────────────────────────────
Write-Log "[2/9] Checking Python..."
if (Test-Command "python") {
    Write-Log "  $(python --version 2>&1) ✓"
} elseif ($Offline) {
    $pyExe = Find-Dep "python-*.exe"
    if ($pyExe) {
        Write-Log "  Installing $($pyExe.Name) from deps/ (silent)..."
        & cmd /c "`"$($pyExe.FullName)`" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 >nul 2>&1"
        Refresh-Path
        if (Test-Command "python") { Write-Log "  Python installed ✓" } else { Write-Log "  ✗ Python install failed" }
    } else { Write-Log "  ✗ No python-*.exe in deps/"; exit 1 }
} else {
    Write-Log "  Installing Python via winget..."
    & cmd /c "winget install Python.Python.3.13 --accept-package-agreements --accept-source-agreements >nul 2>&1"
    Refresh-Path
    if (Test-Command "python") { Write-Log "  Python installed ✓" } else { Write-Log "  ✗ Failed to install Python"; exit 1 }
}

# ── Step 3: pnpm ───────────────────────────────────────────
Write-Log "[3/9] Checking pnpm..."
if (Test-Command "pnpm") {
    Write-Log "  pnpm v$(pnpm --version 2>&1) ✓"
} else {
    Write-Log "  Installing pnpm..."
    & cmd /c "npm install -g pnpm >nul 2>&1"
    if (Test-Command "pnpm") { Write-Log "  pnpm installed ✓" } else { Write-Log "  ✗ Failed to install pnpm"; exit 1 }
}

# ── Step 4: Git ────────────────────────────────────────────
Write-Log "[4/9] Checking Git..."
if (Test-Command "git") {
    Write-Log "  $(git --version 2>&1) ✓"
} elseif ($Offline) {
    $gitExe = Find-Dep "Git-*.exe"
    if ($gitExe) {
        Write-Log "  Installing $($gitExe.Name) from deps/ (silent)..."
        & cmd /c "`"$($gitExe.FullName)`" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS >nul 2>&1"
        Refresh-Path
        if (Test-Command "git") { Write-Log "  Git installed ✓" } else { Write-Log "  ⚠ Git may need PATH refresh" }
    } else { Write-Log "  ✗ No Git-*.exe in deps/"; exit 1 }
} else {
    Write-Log "  Installing Git via winget..."
    & cmd /c "winget install Git.Git --accept-package-agreements --accept-source-agreements >nul 2>&1"
    Refresh-Path
    if (Test-Command "git") { Write-Log "  Git installed ✓" } else { Write-Log "  ✗ Failed to install Git"; exit 1 }
}

# ── Step 5: Clone repo (online) / Verify files (offline) ───
$repoDir = $InstallDir
Write-Log "[5/9] Preparing repository..."
if ($Offline) {
    # Offline: files already extracted by Inno Setup
    $testFile = Join-Path $repoDir "README.md"
    if (Test-Path $testFile) {
        Write-Log "  Repository files in place ✓"
    } else {
        Write-Log "  ✗ Repository files not found at $repoDir"
        exit 1
    }
} else {
    # Online: files already extracted by Inno Setup
    Write-Log "  Repository files in place ✓"
}

# ── Step 6: Config structure ───────────────────────────────
Write-Log "[6/9] Setting up config..."
$dshHome = "$env:USERPROFILE\.dsh"
$profileDir = "$dshHome\profiles\web"
$pluginDir = "$dshHome\profiles\plugins"

@($dshHome, $profileDir, $pluginDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Log "  Created $_"
    }
}

# Copy config files (don't overwrite existing)
$copyMap = @(
    @{src="configs\cordis.patch.yml.template"; dst="$profileDir\cordis.patch.yml"},
    @{src="configs\settings.yaml.template";     dst="$dshHome\settings.yaml"},
    @{src="configs\AGENTS.md";                  dst="$dshHome\AGENTS.md"},
    @{src="scripts\secrets.ps1";                dst="$dshHome\secrets.ps1"}
)
foreach ($m in $copyMap) {
    $src = Join-Path $repoDir $m.src
    $dst = $m.dst
    if (Test-Path $dst) {
        Write-Log "  Skip $(Split-Path $dst -Leaf) (exists)"
    } else {
        Copy-Item $src $dst -Force
        Write-Log "  Copied -> $dst"
    }
}

# Replace MCP paths in cordis.patch.yml
$patchFile = "$profileDir\cordis.patch.yml"
if (Test-Path $patchFile) {
    $mcpDirFwd = (Join-Path $repoDir "scripts\mcp") -replace '\\', '/'
    $content = Get-Content $patchFile -Raw -Encoding UTF8
    $content = $content -replace 'scripts/mcp/', "$mcpDirFwd/"
    Set-Content $patchFile $content -Encoding UTF8
    Write-Log "  MCP paths updated"
}

# .credentials.yaml
$credDst = "$dshHome\.credentials.yaml"
if (-not (Test-Path $credDst)) {
    Copy-Item (Join-Path $repoDir "configs\.credentials.yaml.template") $credDst
    Write-Log "  Created .credentials.yaml (needs API keys)"
}

# package.json
$pkgDst = "$profileDir\package.json"
$pkgCreated = $false
if (-not (Test-Path $pkgDst)) {
    Copy-Item (Join-Path $repoDir "configs\package.json.template") $pkgDst
    $pkgCreated = $true
    Write-Log "  Created package.json"
} else {
    Write-Log "  Skip package.json (exists)"
}

# ── Step 7: Plugin dependencies ────────────────────────────
Write-Log "[7/9] Installing plugins..."
if ($pkgCreated) {
    # Copy dsh-paste-input plugin to profiles/plugins/
    $pluginSrc = Join-Path $repoDir "plugins\dsh-paste-input"
    $pluginDst = "$pluginDir\dsh-paste-input"
    if ((Test-Path $pluginSrc) -and -not (Test-Path $pluginDst)) {
        Copy-Item $pluginSrc $pluginDst -Recurse -Force
        Write-Log "  Copied dsh-paste-input plugin"
    }
    Push-Location $profileDir
    & cmd /c "pnpm install --no-frozen-lockfile >nul 2>&1"
    $pnpmExit = $LASTEXITCODE
    Pop-Location
    if ($pnpmExit -ne 0) {
        Write-Log "  ✗ pnpm install failed (exit $pnpmExit)"
    } else {
        Write-Log "  Plugin dependencies installed ✓"
    }
} else {
    Write-Log "  Skipped pnpm install (package.json pre-existing)"
}

# Python MCP deps
Write-Log "  Installing Python MCP deps..."
& cmd /c "pip install mcp markitdown zstandard >nul 2>&1"
Write-Log "  Python deps done ✓"

# proxy.js dep (http-proxy)
if (-not (Test-Path "$repoDir\node_modules\http-proxy")) {
    Push-Location $repoDir
    & cmd /c "npm install >nul 2>&1"
    Pop-Location
}
Write-Log "  http-proxy done ✓"

# ── Step 8: Detect DSH Desktop ─────────────────────────────
Write-Log "[8/9] Detecting DSH Desktop..."
$exeNames = @("DeepSeekHarness.exe", "DeepSeek Harness 桌面版.exe")
$searchRoots = @(
    "$env:DSH_DESKTOP_PATH",
    "$env:ProgramFiles",
    "$env:LOCALAPPDATA\Programs",
    "D:\Tools",
    "C:\Tools",
    "$env:LOCALAPPDATA"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$script:dshExe = $null
foreach ($root in $searchRoots) {
    foreach ($exeName in $exeNames) {
        $hit = Get-ChildItem -Path $root -Filter $exeName -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { $script:dshExe = $hit.FullName; break }
    }
    if ($script:dshExe) { break }
}
if ($script:dshExe) {
    Write-Log "  Found: $script:dshExe"
    # Write path to file for Inno Setup to read
    $dshExePathFile = Join-Path $repoDir "scripts\detected-dsh-path.txt"
    Set-Content $dshExePathFile $script:dshExe -Encoding ASCII
} else {
    Write-Log "  DSH Desktop not detected (may not be installed yet)"
}

# ── Step 8.5: Create start-dsh.bat ─────────────────────────
$startScript = Join-Path $repoDir "scripts\start-dsh.bat"
if (-not (Test-Path $startScript)) {
    if ($script:dshExe) {
        @"
@echo off
setlocal enabledelayedexpansion
set "DSH_EXE=$($script:dshExe)"
echo [DSH] Starting: !DSH_EXE!
start "" "!DSH_EXE!"
echo [DSH] Access DSH at: http://127.0.0.1:3080
"@ | Set-Content $startScript -Encoding ASCII
    } else {
        $tpl = Join-Path $repoDir "scripts\start-dsh.bat.template"
        if (Test-Path $tpl) { Copy-Item $tpl $startScript }
    }
}

# ── Step 9: Desktop shortcut ───────────────────────────────
Write-Log "[9/9] Creating desktop shortcuts..."
$desktopDir = [Environment]::GetFolderPath('Desktop')

# Living Dream DSH shortcut (always create)
$dshShortcutPath = Join-Path $desktopDir "Living Dream DSH.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($dshShortcutPath)
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/c `"$startScript`""
$shortcut.WorkingDirectory = $repoDir
$shortcut.Description = "Living Dream DSH Launcher"
$shortcut.Save()
Write-Log "  Living Dream DSH desktop shortcut created ✓"

# DeepSeek Harness desktop shortcut (if requested and detected)
if ($CreateDshShortcut -and $script:dshExe) {
    $dshDesktopShortcut = Join-Path $desktopDir "DeepSeek Harness.lnk"
    $shortcut2 = $shell.CreateShortcut($dshDesktopShortcut)
    $shortcut2.TargetPath = $script:dshExe
    $shortcut2.WorkingDirectory = Split-Path $script:dshExe -Parent
    $shortcut2.Description = "DeepSeek Harness Desktop"
    $shortcut2.Save()
    Write-Log "  DeepSeek Harness desktop shortcut created ✓"
}

Write-Log ""
Write-Log "=== Setup Complete ==="
Write-Log "Log saved to: $script:logFile"
Write-Log "DSH_EXE_PATH=$($script:dshExe)"

# Return status for Inno Setup
if ($script:dshExe) {
    Write-Output "DSH_FOUND=$($script:dshExe)"
} else {
    Write-Output "DSH_NOT_FOUND"
}
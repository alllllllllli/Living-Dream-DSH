# ============================================================
# Living Dream DSH - GUI Installer (MPC-HC style)
# ============================================================
# Double-click install.bat to run
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"
$script:DEBUG_LOG = "$env:TEMP\dsh-gui-debug.log"
"$(Get-Date -Format 'HH:mm:ss') Script started" | Out-File $script:DEBUG_LOG -Encoding UTF8

try {

Add-Type -AssemblyName System.Windows.Forms
"$(Get-Date -Format 'HH:mm:ss') WinForms loaded" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
Add-Type -AssemblyName System.Drawing
"$(Get-Date -Format 'HH:mm:ss') Drawing loaded" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8

# ── Constants ──────────────────────────────────────────────
$script:REPO_URL = "https://github.com/alllllllllli/Living-Dream-DSH.git"
$script:DEFAULT_DIR = "$env:USERPROFILE\Living-Dream-DSH"
$script:installDir = $script:DEFAULT_DIR
$script:currentPage = 0
$script:dshExe = $null
$script:pkgCreated = $false
$script:logFile = "$env:TEMP\dsh-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ── Offline detection ─────────────────────────────────────
# Check script dir first, then parent (for SFX layout where
# install.bat is inside Living-Dream-DSH/ but deps/ is at root)
$script:DEPS_DIR = Join-Path $PSScriptRoot "deps"
$script:BUNDLED_REPO = Join-Path $PSScriptRoot "Living-Dream-DSH"
if (-not ((Test-Path $script:DEPS_DIR) -and (Test-Path $script:BUNDLED_REPO))) {
    $parent = Split-Path $PSScriptRoot -Parent
    if ($parent) {
        $script:DEPS_DIR = Join-Path $parent "deps"
        $script:BUNDLED_REPO = Join-Path $parent "Living-Dream-DSH"
    }
}
$script:OFFLINE = (Test-Path $script:DEPS_DIR) -and (Test-Path $script:BUNDLED_REPO)

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    "[$ts] $msg" | Out-File $script:logFile -Append -Encoding UTF8
}

# ── Colors / Fonts ─────────────────────────────────────────
$bgWhite   = [System.Drawing.Color]::FromArgb(255, 255, 255)
$bgDark    = [System.Drawing.Color]::FromArgb(240, 240, 240)
$accent    = [System.Drawing.Color]::FromArgb(0, 120, 215)
$fgGray    = [System.Drawing.Color]::FromArgb(100, 100, 100)
$fgBlack   = [System.Drawing.Color]::FromArgb(30, 30, 30)
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontBody  = New-Object System.Drawing.Font("Segoe UI", 10)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 9)
$fontBold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontLog   = New-Object System.Drawing.Font("Consolas", 9)

# ── Main Form ──────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "Living Dream DSH Setup"
$form.Size = New-Object System.Drawing.Size(620, 560)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $bgWhite
$form.Font = $fontBody
$form.TopMost = $true
$form.Add_Shown({ $form.Activate(); $form.BringToFront() })

# Top banner area
$banner = New-Object System.Windows.Forms.Panel
$banner.Location = New-Object System.Drawing.Point(0, 0)
$banner.Size = New-Object System.Drawing.Size(620, 80)
$banner.BackColor = $accent
$form.Controls.Add($banner)

$lblBannerTitle = New-Object System.Windows.Forms.Label
$lblBannerTitle.Text = "Living Dream DSH"
$lblBannerTitle.ForeColor = [System.Drawing.Color]::White
$lblBannerTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblBannerTitle.Location = New-Object System.Drawing.Point(20, 12)
$lblBannerTitle.AutoSize = $true
$banner.Controls.Add($lblBannerTitle)

$lblBannerSub = New-Object System.Windows.Forms.Label
$lblBannerSub.Text = if ($script:OFFLINE) { "Offline Installer - No Internet Required" } else { "DeepSeek Harness Ultimate Config Framework" }
$lblBannerSub.ForeColor = [System.Drawing.Color]::FromArgb(200, 220, 255)
$lblBannerSub.Font = $fontSmall
$lblBannerSub.Location = New-Object System.Drawing.Point(22, 50)
$lblBannerSub.AutoSize = $true
$banner.Controls.Add($lblBannerSub)

# Page container
$pagePanel = New-Object System.Windows.Forms.Panel
$pagePanel.Location = New-Object System.Drawing.Point(0, 80)
$pagePanel.Size = New-Object System.Drawing.Size(620, 380)
$pagePanel.BackColor = $bgWhite
$form.Controls.Add($pagePanel)

# Bottom bar
$bottomBar = New-Object System.Windows.Forms.Panel
$bottomBar.Location = New-Object System.Drawing.Point(0, 460)
$bottomBar.Size = New-Object System.Drawing.Size(620, 80)
$bottomBar.BackColor = $bgDark
$form.Controls.Add($bottomBar)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(90, 32)
$btnCancel.Location = New-Object System.Drawing.Point(515, 24)
$btnCancel.FlatStyle = "Flat"
$btnCancel.BackColor = $bgDark
$bottomBar.Controls.Add($btnCancel)

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = "< Back"
$btnBack.Size = New-Object System.Drawing.Size(90, 32)
$btnBack.Location = New-Object System.Drawing.Point(320, 24)
$btnBack.FlatStyle = "Flat"
$btnBack.BackColor = $bgDark
$btnBack.Enabled = $false
$bottomBar.Controls.Add($btnBack)

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Size = New-Object System.Drawing.Size(90, 32)
$btnNext.Location = New-Object System.Drawing.Point(415, 24)
$btnNext.FlatStyle = "Flat"
$btnNext.BackColor = $accent
$btnNext.ForeColor = [System.Drawing.Color]::White
$bottomBar.Controls.Add($btnNext)

# ── Page 0: Welcome ────────────────────────────────────────
$pageWelcome = New-Object System.Windows.Forms.Panel
$pageWelcome.Dock = "Fill"

$lblWelcome = New-Object System.Windows.Forms.Label
$lblWelcome.Text = "Welcome to the Living Dream DSH Setup"
$lblWelcome.Font = $fontTitle
$lblWelcome.Location = New-Object System.Drawing.Point(20, 20)
$lblWelcome.AutoSize = $true
$pageWelcome.Controls.Add($lblWelcome)

$txtWelcome = New-Object System.Windows.Forms.Label
if ($script:OFFLINE) {
    $txtWelcome.Text = @"
This is the offline installer. All dependencies are bundled -
no internet connection is required.

What will be installed:
  • Node.js, Python, Git (if not already present)
  • Living Dream DSH config framework
  • 8+ MCP servers + plugins
  • Desktop shortcut

Click Next to continue.
"@
} else {
    $txtWelcome.Text = @"
This will install Living Dream DSH - the ultimate DeepSeek Harness desktop configuration framework.

Features:
  • 8+ MCP servers (history, vision, memory, browser, OCR, etc.)
  • Free model access via AMD Radeon Cloud
  • Mobile remote access via Tailscale + proxy
  • One-click launcher & desktop shortcut

Click Next to continue.
"@
}
$txtWelcome.Font = $fontBody
$txtWelcome.Location = New-Object System.Drawing.Point(20, 70)
$txtWelcome.Size = New-Object System.Drawing.Size(540, 250)
$txtWelcome.ForeColor = $fgBlack
$pageWelcome.Controls.Add($txtWelcome)

# ── Page 1: License ────────────────────────────────────────
$pageLicense = New-Object System.Windows.Forms.Panel
$pageLicense.Dock = "Fill"

$lblLicense = New-Object System.Windows.Forms.Label
$lblLicense.Text = "License Agreement"
$lblLicense.Font = $fontTitle
$lblLicense.Location = New-Object System.Drawing.Point(20, 20)
$lblLicense.AutoSize = $true
$pageLicense.Controls.Add($lblLicense)

$txtLicense = New-Object System.Windows.Forms.TextBox
$txtLicense.Multiline = $true
$txtLicense.ReadOnly = $true
$txtLicense.ScrollBars = "Vertical"
$txtLicense.Location = New-Object System.Drawing.Point(20, 60)
$txtLicense.Size = New-Object System.Drawing.Size(540, 220)
$txtLicense.Font = $fontSmall

$licenseText = @"
MIT License

Copyright (c) 2025 alllllllllli

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
$txtLicense.Text = $licenseText
$pageLicense.Controls.Add($txtLicense)

$lblLicenseAgree = New-Object System.Windows.Forms.Label
$lblLicenseAgree.Text = "Do you accept the terms of the license agreement?"
$lblLicenseAgree.Font = $fontBody
$lblLicenseAgree.Location = New-Object System.Drawing.Point(20, 295)
$lblLicenseAgree.AutoSize = $true
$pageLicense.Controls.Add($lblLicenseAgree)

$chkLicense = New-Object System.Windows.Forms.CheckBox
$chkLicense.Text = "I accept the agreement"
$chkLicense.Font = $fontBold
$chkLicense.Location = New-Object System.Drawing.Point(20, 318)
$chkLicense.AutoSize = $true
$pageLicense.Controls.Add($chkLicense)

# ── Page 2: Choose Install Location ────────────────────────
$pageLocation = New-Object System.Windows.Forms.Panel
$pageLocation.Dock = "Fill"

$lblLocation = New-Object System.Windows.Forms.Label
$lblLocation.Text = "Choose Install Location"
$lblLocation.Font = $fontTitle
$lblLocation.Location = New-Object System.Drawing.Point(20, 20)
$lblLocation.AutoSize = $true
$pageLocation.Controls.Add($lblLocation)

$txtLocationDesc = New-Object System.Windows.Forms.Label
$txtLocationDesc.Text = "Choose the folder in which to install Living Dream DSH."
$txtLocationDesc.Font = $fontBody
$txtLocationDesc.Location = New-Object System.Drawing.Point(20, 60)
$txtLocationDesc.AutoSize = $true
$pageLocation.Controls.Add($txtLocationDesc)

$txtLocation = New-Object System.Windows.Forms.TextBox
$txtLocation.Text = $script:DEFAULT_DIR
$txtLocation.Font = $fontBody
$txtLocation.Location = New-Object System.Drawing.Point(20, 100)
$txtLocation.Size = New-Object System.Drawing.Size(440, 28)
$pageLocation.Controls.Add($txtLocation)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(470, 99)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 28)
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.BackColor = $bgDark
$pageLocation.Controls.Add($btnBrowse)

$lblLocationNote = New-Object System.Windows.Forms.Label
$lblLocationNote.Text = @"
Note: The repository will be cloned to this directory.
Config files go to %USERPROFILE%\.dsh\ (managed automatically).

Space required: ~5 MB (config only; dependencies installed separately)
"@
$lblLocationNote.Font = $fontSmall
$lblLocationNote.ForeColor = $fgGray
$lblLocationNote.Location = New-Object System.Drawing.Point(20, 145)
$lblLocationNote.Size = New-Object System.Drawing.Size(540, 100)
$pageLocation.Controls.Add($lblLocationNote)

# ── Page 3: Installing (progress) ──────────────────────────
$pageInstalling = New-Object System.Windows.Forms.Panel
$pageInstalling.Dock = "Fill"

$lblInstalling = New-Object System.Windows.Forms.Label
$lblInstalling.Text = "Installing"
$lblInstalling.Font = $fontTitle
$lblInstalling.Location = New-Object System.Drawing.Point(20, 20)
$lblInstalling.AutoSize = $true
$pageInstalling.Controls.Add($lblInstalling)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 60)
$progressBar.Size = New-Object System.Drawing.Size(540, 24)
$progressBar.Style = "Continuous"
$pageInstalling.Controls.Add($progressBar)

$txtProgress = New-Object System.Windows.Forms.Label
$txtProgress.Text = "Preparing..."
$txtProgress.Font = $fontBody
$txtProgress.Location = New-Object System.Drawing.Point(20, 92)
$txtProgress.AutoSize = $true
$pageInstalling.Controls.Add($txtProgress)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.Location = New-Object System.Drawing.Point(20, 120)
$txtLog.Size = New-Object System.Drawing.Size(540, 210)
$txtLog.Font = $fontLog
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
$pageInstalling.Controls.Add($txtLog)

# ── Page 4: Finish ─────────────────────────────────────────
$pageFinish = New-Object System.Windows.Forms.Panel
$pageFinish.Dock = "Fill"

$lblFinish = New-Object System.Windows.Forms.Label
$lblFinish.Text = "Completing the Living Dream DSH Setup"
$lblFinish.Font = $fontTitle
$lblFinish.Location = New-Object System.Drawing.Point(20, 20)
$lblFinish.AutoSize = $true
$pageFinish.Controls.Add($lblFinish)

$txtFinish = New-Object System.Windows.Forms.Label
$txtFinish.Text = "Living Dream DSH has been installed on your computer."
$txtFinish.Font = $fontBody
$txtFinish.Location = New-Object System.Drawing.Point(20, 65)
$txtFinish.AutoSize = $true
$pageFinish.Controls.Add($txtFinish)

$txtApiHint = New-Object System.Windows.Forms.Label
$txtApiHint.Text = @'
⚠️  You need to fill in your API keys before using DSH:

  1. Open DSH Settings → API Keys section
  2. Fill in your DeepSeek API Key (required)
     Get one at: https://platform.deepseek.com/
  3. Optionally fill in Zhipu API Key (for image recognition)
     Get one at: https://open.bigmodel.cn/

  Config file: %USERPROFILE%\.dsh\.credentials.yaml
'@
$txtApiHint.Font = $fontBody
$txtApiHint.ForeColor = [System.Drawing.Color]::FromArgb(180, 90, 0)
$txtApiHint.Location = New-Object System.Drawing.Point(20, 100)
$txtApiHint.Size = New-Object System.Drawing.Size(540, 150)

$chkLaunch = New-Object System.Windows.Forms.CheckBox
$chkLaunch.Text = "Launch Living Dream DSH"
$chkLaunch.Font = $fontBold
$chkLaunch.Location = New-Object System.Drawing.Point(20, 270)
$chkLaunch.AutoSize = $true
$chkLaunch.Checked = $true
$pageFinish.Controls.Add($chkLaunch)

$pageFinish.Controls.Add($txtApiHint)

$txtFinishDetails = New-Object System.Windows.Forms.Label
$txtFinishDetails.Font = $fontSmall
$txtFinishDetails.ForeColor = $fgGray
$txtFinishDetails.Location = New-Object System.Drawing.Point(20, 300)
$txtFinishDetails.Size = New-Object System.Drawing.Size(540, 30)
$pageFinish.Controls.Add($txtFinishDetails)

# ── Helpers ────────────────────────────────────────────────
$pages = @($pageWelcome, $pageLicense, $pageLocation, $pageInstalling, $pageFinish)

function Show-Page($idx) {
    $pagePanel.Controls.Clear()
    $pagePanel.Controls.Add($pages[$idx])
    $script:currentPage = $idx
    $btnBack.Enabled = ($idx -gt 0)

    switch ($idx) {
        0 { $btnNext.Text = "Next >"; $btnNext.Enabled = $true }
        1 { $btnNext.Text = "Next >"; $btnNext.Enabled = $chkLicense.Checked }
        2 { $btnNext.Text = "Install"; $btnNext.Enabled = $true }
        3 {
            $btnNext.Text = "Next >"
            $btnNext.Enabled = $false
            $btnBack.Enabled = $false
            $btnCancel.Enabled = $false
            Start-Install
        }
        4 {
            $btnNext.Text = "Finish"
            $btnNext.Enabled = $true
            $btnBack.Enabled = $false
            $txtFinishDetails.Text = "Installed to: $($script:installDir)`nLog: $($script:logFile)"
        }
    }
}

function Append-Log($msg) {
    $txtLog.AppendText("$msg`r`n")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    Write-Log $msg
}

function Test-Command($cmd) {
    try { Get-Command $cmd -ErrorAction Stop; return $true }
    catch { return $false }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Find-Dep($pattern) {
    $found = Get-ChildItem $script:DEPS_DIR -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    return $found
}

# ── Install Logic ──────────────────────────────────────────
function Start-Install {
    $script:installDir = $txtLocation.Text
    $steps = 8
    $step = 0

    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Checking dependencies..."
    Append-Log "=== Living Dream DSH Installer ==="
    Append-Log "Mode: $(if ($script:OFFLINE) { 'OFFLINE (bundled deps)' } else { 'Online' })"
    Append-Log "Install directory: $($script:installDir)"
    Append-Log ""

    # ── Helper: refresh PATH after silent install ──

    # Node.js
    Append-Log "[1/$steps] Checking Node.js..."
    if (Test-Command "node") {
        $v = node --version 2>&1
        Append-Log "  Node.js $v ✓"
    } elseif ($script:OFFLINE) {
        $nodeMsi = Find-Dep "node-*.msi"
        if ($nodeMsi) {
            Append-Log "  Installing $($nodeMsi.Name) from deps/..."
            & cmd /c "msiexec /i `"$($nodeMsi.FullName)`" /qn /norestart >nul 2>&1"
            Refresh-Path
            if (Test-Command "node") { Append-Log "  Node.js installed ✓" } else { Append-Log "  ✗ Node.js install failed (may need PATH refresh)" }
        } else {
            Append-Log "  ✗ No node-*.msi in deps/"; return
        }
    } else {
        Append-Log "  Installing Node.js via winget..."
        & cmd /c "winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Failed to install Node.js"; return }
        Refresh-Path
        Append-Log "  Node.js installed ✓"
    }

    # Python
    Append-Log "[2/$steps] Checking Python..."
    if (Test-Command "python") {
        $v = python --version 2>&1
        Append-Log "  $v ✓"
    } elseif ($script:OFFLINE) {
        $pyExe = Find-Dep "python-*.exe"
        if ($pyExe) {
            Append-Log "  Installing $($pyExe.Name) from deps/ (silent, ~1 min)..."
            & cmd /c "`"$($pyExe.FullName)`" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 >nul 2>&1"
            Refresh-Path
            if (Test-Command "python") { Append-Log "  Python installed ✓" } else { Append-Log "  ✗ Python install failed" }
        } else {
            Append-Log "  ✗ No python-*.exe in deps/"; return
        }
    } else {
        Append-Log "  Installing Python via winget..."
        & cmd /c "winget install Python.Python.3.13 --accept-package-agreements --accept-source-agreements >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Failed to install Python"; return }
        Refresh-Path
        Append-Log "  Python installed ✓"
    }

    # pnpm
    Append-Log "[3/$steps] Checking pnpm..."
    if (Test-Command "pnpm") {
        $v = pnpm --version 2>&1
        Append-Log "  pnpm v$v ✓"
    } else {
        Append-Log "  Installing pnpm..."
        & cmd /c "npm install -g pnpm >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Failed to install pnpm"; return }
        Append-Log "  pnpm installed ✓"
    }

    # Git
    Append-Log "[4/$steps] Checking Git..."
    if (Test-Command "git") {
        $v = git --version 2>&1
        Append-Log "  $v ✓"
    } elseif ($script:OFFLINE) {
        $gitExe = Find-Dep "Git-*.exe"
        if ($gitExe) {
            Append-Log "  Installing $($gitExe.Name) from deps/ (silent)..."
            & cmd /c "`"$($gitExe.FullName)`" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`" >nul 2>&1"
            Refresh-Path
            if (Test-Command "git") { Append-Log "  Git installed ✓" } else { Append-Log "  ⚠ Git install may need PATH refresh" }
        } else {
            Append-Log "  ✗ No Git-*.exe in deps/"; return
        }
    } else {
        Append-Log "  Installing Git via winget..."
        & cmd /c "winget install Git.Git --accept-package-agreements --accept-source-agreements >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Failed to install Git"; return }
        Refresh-Path
        Append-Log "  Git installed ✓"
    }

    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = if ($script:OFFLINE) { "Copying config files..." } else { "Cloning repository..." }
    Append-Log ""
    Append-Log "[5/$steps] $(if ($script:OFFLINE) { 'Copying bundled repo...' } else { 'Cloning repository...' })"

    $repoDir = $script:installDir
    if ($script:OFFLINE) {
        # Offline: copy bundled repo
        if (Test-Path $script:BUNDLED_REPO) {
            Append-Log "  Copying from bundled repo..."
            # Create exclude list for xcopy
            $excludeFile = Join-Path $env:TEMP "dsh-exclude.txt"
            ".git`ndeps`nnode_modules`n__pycache__" | Out-File $excludeFile -Encoding ASCII
            & cmd /c "xcopy `"$($script:BUNDLED_REPO)`" `"$repoDir`" /E /I /Y /Q /EXCLUDE:`"$excludeFile`" >nul 2>&1"
            Remove-Item $excludeFile -Force -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -eq 0) { Append-Log "  Copied ✓" } else { Append-Log "  ✗ Copy failed"; return }
        } else {
            Append-Log "  ✗ Bundled repo not found at $($script:BUNDLED_REPO)"; return
        }
    } elseif (Test-Path "$repoDir\.git") {
        Append-Log "  Repository exists, updating..."
        Push-Location $repoDir
        & cmd /c "git pull --quiet >nul 2>&1"
        Pop-Location
        Append-Log "  Updated ✓"
    } else {
        & cmd /c "git clone --quiet $script:REPO_URL `"$repoDir`" >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Clone failed - check network"; return }
        Append-Log "  Cloned ✓"
    }

    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Creating config structure..."
    Append-Log ""
    Append-Log "[6/$steps] Setting up config..."

    $dshHome = "$env:USERPROFILE\.dsh"
    $profileDir = "$dshHome\profiles\web"
    @($dshHome, $profileDir, "$profileDir\..\plugins") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Append-Log "  Created $_"
        }
    }

    # Copy config files (don't overwrite)
    $copyMap = @(
        @{src="configs\cordis.patch.yml.template"; dst="$profileDir\cordis.patch.yml"}
        @{src="configs\settings.yaml.template"; dst="$dshHome\settings.yaml"}
        @{src="configs\AGENTS.md"; dst="$dshHome\AGENTS.md"}
        @{src="scripts\secrets.ps1"; dst="$dshHome\secrets.ps1"}
    )
    foreach ($item in $copyMap) {
        $src = Join-Path $repoDir $item.src
        $dst = $item.dst
        if (Test-Path $dst) {
            Append-Log "  Skip $(Split-Path $dst -Leaf) (exists)"
        } else {
            Copy-Item $src $dst -Force
            Append-Log "  Copied -> $dst"
        }
    }

    # Replace MCP paths
    $patchFile = "$profileDir\cordis.patch.yml"
    if (Test-Path $patchFile) {
        $mcpDirFwd = (Join-Path $repoDir "scripts\mcp") -replace '\\', '/'
        $content = Get-Content $patchFile -Raw -Encoding UTF8
        $content = $content -replace 'scripts/mcp/', "$mcpDirFwd/"
        Set-Content $patchFile $content -Encoding UTF8
        Append-Log "  MCP paths updated"
    }

    # credentials.yaml
    $credDst = "$dshHome\.credentials.yaml"
    if (-not (Test-Path $credDst)) {
        Copy-Item (Join-Path $repoDir "configs\.credentials.yaml.template") $credDst
        Append-Log "  Created .credentials.yaml (needs API keys)"
    }

    # package.json
    $pkgDst = "$profileDir\package.json"
    if (-not (Test-Path $pkgDst)) {
        Copy-Item (Join-Path $repoDir "configs\package.json.template") $pkgDst
        $script:pkgCreated = $true
        Append-Log "  Created package.json"
    } else {
        Append-Log "  Skip package.json (exists)"
    }

    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing plugin dependencies..."
    Append-Log ""
    Append-Log "[7/$steps] Installing plugins..."

    if ($script:pkgCreated) {
        # Copy dsh-paste-input plugin
        $pluginSrc = Join-Path $repoDir "plugins\dsh-paste-input"
        $pluginDst = "$profileDir\..\plugins\dsh-paste-input"
        if ((Test-Path $pluginSrc) -and -not (Test-Path $pluginDst)) {
            New-Item -ItemType Directory -Path (Split-Path $pluginDst) -Force | Out-Null
            Copy-Item $pluginSrc $pluginDst -Recurse -Force
            Append-Log "  Copied dsh-paste-input plugin"
        }
        Push-Location $profileDir
        & cmd /c "pnpm install --no-frozen-lockfile >nul 2>&1"
        $pnpmExit = $LASTEXITCODE
        Pop-Location
        if ($pnpmExit -ne 0) {
            Append-Log "  ✗ pnpm install failed (exit $pnpmExit)"
        } else {
            Append-Log "  Plugin dependencies installed ✓"
        }
    } else {
        Append-Log "  Skipped pnpm install (package.json pre-existing)"
    }

    # Python MCP deps
    Append-Log "  Installing Python MCP deps..."
    & cmd /c "pip install mcp markitdown zstandard >nul 2>&1"
    Append-Log "  Python deps done ✓"

    # proxy.js dep
    if (-not (Test-Path "$repoDir\node_modules\http-proxy")) {
        Push-Location $repoDir
        & cmd /c "npm install >nul 2>&1"
        Pop-Location
    }
    Append-Log "  http-proxy done ✓"

    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Creating shortcuts..."
    Append-Log ""
    Append-Log "[8/$steps] Creating desktop shortcut..."

    # Detect DSH Desktop
    $candidates = @(
        "$env:DSH_DESKTOP_PATH\DeepSeekHarness.exe"
        "$env:ProgramFiles\DeepSeekHarness-Desktop\DeepSeekHarness.exe"
        "$env:ProgramFiles\DeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
        "$env:LOCALAPPDATA\DeepSeekHarness-Desktop\DeepSeekHarness.exe"
        "D:\Tools\DeepSeekHarness-Desktop\DeepSeekHarness.exe"
        "D:\Tools\DeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { $script:dshExe = $c; break }
    }

    $startScript = Join-Path $repoDir "scripts\start-dsh.bat"
    if (-not (Test-Path $startScript)) {
        if ($script:dshExe) {
            $bat = @"
@echo off
setlocal enabledelayedexpansion
set "DSH_EXE=$($script:dshExe)"
echo [DSH] Starting: !DSH_EXE!
start "" "!DSH_EXE!"
echo [DSH] Access DSH at: http://127.0.0.1:3080
"@
            Set-Content $startScript $bat -Encoding ASCII
        } else {
            $tpl = Join-Path $repoDir "scripts\start-dsh.bat.template"
            if (Test-Path $tpl) { Copy-Item $tpl $startScript }
        }
    }

    $shortcutPath = "$env:USERPROFILE\Desktop\Living Dream DSH.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "cmd.exe"
    $shortcut.Arguments = "/c `"$startScript`""
    $shortcut.WorkingDirectory = $repoDir
    $shortcut.Description = "Living Dream DSH Launcher"
    $shortcut.Save()
    Append-Log "  Desktop shortcut created ✓"

    $progressBar.Value = 100
    $txtProgress.Text = "Installation complete!"
    Append-Log ""
    Append-Log "=== Installation Complete ==="

    $btnNext.Enabled = $true
    $btnCancel.Enabled = $true
    Show-Page 4
}

# ── Event Handlers ─────────────────────────────────────────
$btnNext.Add_Click({
    switch ($script:currentPage) {
        0 { Show-Page 1 }
        1 {
            if (-not $chkLicense.Checked) {
                [System.Windows.Forms.MessageBox]::Show("Please accept the license agreement to continue.", "License", "OK", "Warning")
                return
            }
            Show-Page 2
        }
        2 {
            $script:installDir = $txtLocation.Text
            if (-not (Test-Path $txtLocation.Text)) {
                $r = [System.Windows.Forms.MessageBox]::Show("Directory does not exist. Create it?", "Create Directory", "YesNo", "Question")
                if ($r -eq "No") { return }
            }
            Show-Page 3
        }
        4 {
            # Finish
            if ($chkLaunch.Checked -and $script:dshExe) {
                Start-Process $script:dshExe
            } elseif ($chkLaunch.Checked) {
                $startScript = Join-Path $script:installDir "scripts\start-dsh.bat"
                if (Test-Path $startScript) { Start-Process "cmd.exe" -ArgumentList "/c `"$startScript`"" }
            }
            $form.Close()
        }
    }
})

$btnBack.Add_Click({
    if ($script:currentPage -gt 0) { Show-Page ($script:currentPage - 1) }
})

$btnCancel.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to cancel the installation?", "Cancel", "YesNo", "Question")
    if ($r -eq "Yes") { $form.Close() }
})

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select installation folder"
    $dlg.SelectedPath = $txtLocation.Text
    if ($dlg.ShowDialog() -eq "OK") { $txtLocation.Text = $dlg.SelectedPath }
})

$chkLicense.Add_CheckedChanged({ $btnNext.Enabled = $chkLicense.Checked })

# ── Launch ─────────────────────────────────────────────────
"$(Get-Date -Format 'HH:mm:ss') About to Show-Page 0" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
Show-Page 0
"$(Get-Date -Format 'HH:mm:ss') About to Application.Run, form.Handle=$($form.Handle)" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
[System.Windows.Forms.Application]::Run($form)
"$(Get-Date -Format 'HH:mm:ss') Application.Run returned" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8

} catch {
    "$(Get-Date -Format 'HH:mm:ss') FATAL: $_" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
    "$(Get-Date -Format 'HH:mm:ss') STACK: $($_.ScriptStackTrace)" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
}

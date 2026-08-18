# ============================================================
# Living Dream DSH - Offline GUI Installer (MPC-HC style)
# ============================================================
# Bundled in SFX with deps/ (Node, Python, Git) + repo copy
# Auto-detects $PSScriptRoot as extraction directory
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"
$script:DEBUG_LOG = "$env:TEMP\dsh-gui-offline-debug.log"
"$(Get-Date -Format 'HH:mm:ss') Offline installer started from $PSScriptRoot" | Out-File $script:DEBUG_LOG -Encoding UTF8

try {

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Paths (relative to extraction root) ───────────────────
$script:BASE_DIR   = $PSScriptRoot
$script:DEPS_DIR   = Join-Path $script:BASE_DIR "deps"
$script:BUNDLED_REPO = Join-Path $script:BASE_DIR "Living-Dream-DSH"

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
$form.Text = "Living Dream DSH Offline Setup"
$form.Size = New-Object System.Drawing.Size(620, 560)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $bgWhite
$form.Font = $fontBody
$form.TopMost = $true
$form.Add_Shown({ $form.Activate(); $form.BringToFront() })

# Top banner
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
$lblBannerSub.Text = "Offline Installer - No Internet Required"
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
$lblWelcome.Text = "Welcome to Living Dream DSH Setup"
$lblWelcome.Font = $fontTitle
$lblWelcome.Location = New-Object System.Drawing.Point(20, 20)
$lblWelcome.AutoSize = $true
$pageWelcome.Controls.Add($lblWelcome)

$txtWelcome = New-Object System.Windows.Forms.Label
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
$txtLicense.Text = @"
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
$txtLocation.Text = "$env:USERPROFILE\Living-Dream-DSH"
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
Note: Config files go to %USERPROFILE%\.dsh\ (managed automatically).
All dependencies are installed from bundled offline packages.
"@
$lblLocationNote.Font = $fontSmall
$lblLocationNote.ForeColor = $fgGray
$lblLocationNote.Location = New-Object System.Drawing.Point(20, 145)
$lblLocationNote.Size = New-Object System.Drawing.Size(540, 60)
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
$txtLog.Size = New-Object System.Drawing.Size(540, 240)
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
$pageFinish.Controls.Add($txtApiHint)

$chkLaunch = New-Object System.Windows.Forms.CheckBox
$chkLaunch.Text = "Launch Living Dream DSH"
$chkLaunch.Font = $fontBold
$chkLaunch.Location = New-Object System.Drawing.Point(20, 270)
$chkLaunch.AutoSize = $true
$chkLaunch.Checked = $true
$pageFinish.Controls.Add($chkLaunch)

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
    $btnBack.Enabled = ($idx -gt 0 -and $idx -lt 3)

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
            $txtFinishDetails.Text = "Installed to: $($script:installDir)`nLog: $($script:DEBUG_LOG)"
        }
    }
}

function Append-Log($msg) {
    $txtLog.AppendText("$msg`r`n")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    "$(Get-Date -Format 'HH:mm:ss') $msg" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
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

# ── Install Logic (offline) ────────────────────────────────
function Start-Install {
    $script:installDir = $txtLocation.Text
    $steps = 8
    $step = 0

    Append-Log "=== Living Dream DSH Offline Installer ==="
    Append-Log "Install directory: $($script:installDir)"
    Append-Log "Dependencies: $($script:DEPS_DIR)"
    Append-Log ""

    # ── 1. Node.js ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing Node.js..."
    Append-Log "[$step/$steps] Checking Node.js..."
    if (Test-Command "node") {
        $v = node --version 2>&1
        Append-Log "  Node.js $v already installed ✓"
    } else {
        $nodeMsi = Find-Dep "node-*.msi"
        if ($nodeMsi) {
            Append-Log "  Installing $($nodeMsi.Name)..."
            & cmd /c "msiexec /i `"$($nodeMsi.FullName)`" /qn /norestart >nul 2>&1"
            if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Node.js MSI install failed"; return }
            Refresh-Path
            Append-Log "  Node.js installed ✓"
        } else {
            Append-Log "  ✗ No Node.js installer found in deps/"
            Append-Log "  Please install Node.js 22+ manually: https://nodejs.org/"
            return
        }
    }

    # ── 2. Python ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing Python..."
    Append-Log ""
    Append-Log "[$step/$steps] Checking Python..."
    if (Test-Command "python") {
        $v = python --version 2>&1
        Append-Log "  $v already installed ✓"
    } else {
        $pyExe = Find-Dep "python-*.exe"
        if ($pyExe) {
            Append-Log "  Installing $($pyExe.Name) (silent, may take a minute)..."
            & cmd /c "`"$($pyExe.FullName)`" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 >nul 2>&1"
            if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ Python install failed"; return }
            Refresh-Path
            Append-Log "  Python installed ✓"
        } else {
            Append-Log "  ✗ No Python installer found in deps/"
            Append-Log "  Please install Python 3.10+ manually: https://python.org/"
            return
        }
    }

    # ── 3. Git ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing Git..."
    Append-Log ""
    Append-Log "[$step/$steps] Checking Git..."
    if (Test-Command "git") {
        $v = git --version 2>&1
        Append-Log "  $v already installed ✓"
    } else {
        $gitExe = Find-Dep "Git-*.exe"
        if ($gitExe) {
            Append-Log "  Installing $($gitExe.Name) (silent)..."
            & cmd /c "`"$($gitExe.FullName)`" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh" >nul 2>&1"
            Refresh-Path
            if (Test-Command "git") {
                Append-Log "  Git installed ✓"
            } else {
                Append-Log "  ⚠ Git install may need PATH refresh (restart installer if needed)"
            }
        } else {
            Append-Log "  ✗ No Git installer found in deps/"
            Append-Log "  Please install Git manually: https://git-scm.com/"
            return
        }
    }

    # ── 4. pnpm ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing pnpm..."
    Append-Log ""
    Append-Log "[$step/$steps] Checking pnpm..."
    if (Test-Command "pnpm") {
        $v = pnpm --version 2>&1
        Append-Log "  pnpm v$v already installed ✓"
    } else {
        Append-Log "  Installing pnpm via npm..."
        & cmd /c "npm install -g pnpm >nul 2>&1"
        if ($LASTEXITCODE -ne 0) { Append-Log "  ✗ pnpm install failed"; return }
        Append-Log "  pnpm installed ✓"
    }

    # ── 5. Copy repo ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Copying config files..."
    Append-Log ""
    Append-Log "[$step/$steps] Copying Living Dream DSH..."

    $repoDir = $script:installDir
    if (Test-Path "$repoDir\.git") {
        Append-Log "  Directory exists with .git, skipping copy"
    } elseif (Test-Path $script:BUNDLED_REPO) {
        if (Test-Path $repoDir) {
            Append-Log "  Target exists, updating..."
        }
        # Copy bundled repo (exclude .git, deps, offline files)
        & cmd /c "xcopy `"$($script:BUNDLED_REPO)`" `"$repoDir`" /E /I /Y /Q /EXCLUDE:`"$($script:BASE_DIR)\exclude-list.txt`" >nul 2>&1"
        Append-Log "  Copied to $repoDir ✓"
    } else {
        Append-Log "  ✗ Bundled repo not found at $($script:BUNDLED_REPO)"
        return
    }

    # ── 6. Config setup ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Creating config structure..."
    Append-Log ""
    Append-Log "[$step/$steps] Setting up config..."

    $dshHome = "$env:USERPROFILE\.dsh"
    $profileDir = "$dshHome\profiles\web"
    @($dshHome, $profileDir, "$profileDir\..\plugins") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Append-Log "  Created $_"
        }
    }

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

    $credDst = "$dshHome\.credentials.yaml"
    if (-not (Test-Path $credDst)) {
        Copy-Item (Join-Path $repoDir "configs\.credentials.yaml.template") $credDst
        Append-Log "  Created .credentials.yaml (needs API keys)"
    }

    $pkgDst = "$profileDir\package.json"
    $script:pkgCreated = $false
    if (-not (Test-Path $pkgDst)) {
        Copy-Item (Join-Path $repoDir "configs\package.json.template") $pkgDst
        $script:pkgCreated = $true
        Append-Log "  Created package.json"
    } else {
        Append-Log "  Skip package.json (exists)"
    }

    # ── 7. Plugin deps ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Installing plugin dependencies..."
    Append-Log ""
    Append-Log "[$step/$steps] Installing plugins..."

    if ($script:pkgCreated) {
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
            Append-Log "  ⚠ pnpm install failed (exit $pnpmExit) - may need manual fix"
        } else {
            Append-Log "  Plugin dependencies installed ✓"
        }
    } else {
        Append-Log "  Skipped pnpm install (package.json pre-existing)"
    }

    # Python MCP deps
    Append-Log "  Installing Python MCP deps..."
    & cmd /c "pip install mcp markitdown zstandard >nul 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Append-Log "  ⚠ pip install failed (offline: may need manual install)"
    } else {
        Append-Log "  Python MCP deps installed ✓"
    }

    # proxy.js dep
    if (-not (Test-Path "$repoDir\node_modules\http-proxy")) {
        Push-Location $repoDir
        & cmd /c "npm install >nul 2>&1"
        Pop-Location
    }
    Append-Log "  http-proxy done ✓"

    # ── 8. Shortcut ──
    $step++; $progressBar.Value = [Math]::Min(100, [int]($step / $steps * 100))
    $txtProgress.Text = "Creating shortcuts..."
    Append-Log ""
    Append-Log "[$step/$steps] Creating desktop shortcut..."

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
                [System.Windows.Forms.MessageBox]::Show("Please accept the license agreement.", "License", "OK", "Warning")
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
    if ($script:currentPage -gt 0 -and $script:currentPage -lt 3) {
        Show-Page ($script:currentPage - 1)
    }
})

$btnCancel.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to cancel?", "Cancel", "YesNo", "Question")
    if ($r -eq "Yes") { $form.Close() }
})

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select installation folder"
    $dlg.SelectedPath = $txtLocation.Text
    if ($dlg.ShowDialog() -eq "OK") { $txtLocation.Text = $dlg.SelectedPath }
})

$chkLicense.Add_CheckedChanged({ $btnNext.Enabled = $chkLicense.Checked })

# ── Pre-flight check ───────────────────────────────────────
if (-not (Test-Path $script:DEPS_DIR)) {
    [System.Windows.Forms.MessageBox]::Show(
        "deps/ folder not found at:`n$($script:DEPS_DIR)`n`nThis offline installer must be extracted before running.",
        "Error", "OK", "Error")
    exit 1
}

if (-not (Test-Path $script:BUNDLED_REPO)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Living-Dream-DSH/ folder not found at:`n$($script:BUNDLED_REPO)`n`nThis offline installer must be extracted before running.",
        "Error", "OK", "Error")
    exit 1
}

# ── Launch ─────────────────────────────────────────────────
Show-Page 0
[System.Windows.Forms.Application]::Run($form)

} catch {
    "$(Get-Date -Format 'HH:mm:ss') FATAL: $_" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
    "$(Get-Date -Format 'HH:mm:ss') STACK: $($_.ScriptStackTrace)" | Out-File $script:DEBUG_LOG -Append -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Installation failed:`n$_`n`nLog: $script:DEBUG_LOG", "Error", "OK", "Error")
}

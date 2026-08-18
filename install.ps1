# ============================================================
# Living Dream DSH - One-Click Installer
# ============================================================
# Double-click install.bat to run this script
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

# Color output
function Write-Step($msg) { Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-OK($msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[-] $msg" -ForegroundColor Red }

# Banner
Write-Host @"

 ============================================================
   Living Dream DSH - One-Click Installer
   https://github.com/alllllllllli/Living-Dream-DSH
 ============================================================
"@ -ForegroundColor Cyan

# ============================================================
# 1. Check & Install Dependencies
# ============================================================
Write-Step "Checking dependencies..."

# Function to check if command exists
function Test-Command($cmd) {
    try { Get-Command $cmd -ErrorAction Stop; return $true }
    catch { return $false }
}

# Node.js
if (Test-Command "node") {
    $nodeVer = node --version
    Write-OK "Node.js $nodeVer"
} else {
    Write-Warn "Node.js not found, installing..."
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to install Node.js"
        Write-Host "Please install manually: https://nodejs.org/"
        Read-Host "Press Enter to exit"
        exit 1
    }
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-OK "Node.js installed"
}

# Python
if (Test-Command "python") {
    $pyVer = python --version
    Write-OK "$pyVer"
} else {
    Write-Warn "Python not found, installing..."
    winget install Python.Python.3.13 --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to install Python"
        Write-Host "Please install manually: https://python.org/"
        Read-Host "Press Enter to exit"
        exit 1
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-OK "Python installed"
}

# pnpm
if (Test-Command "pnpm") {
    $pnpmVer = pnpm --version
    Write-OK "pnpm v$pnpmVer"
} else {
    Write-Warn "pnpm not found, installing..."
    npm install -g pnpm
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to install pnpm"
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-OK "pnpm installed"
}

# Git
if (Test-Command "git") {
    $gitVer = git --version
    Write-OK "$gitVer"
} else {
    Write-Warn "Git not found, installing..."
    winget install Git.Git --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to install Git"
        Write-Host "Please install manually: https://git-scm.com/"
        Read-Host "Press Enter to exit"
        exit 1
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-OK "Git installed"
}

# ============================================================
# 2. Clone Repository
# ============================================================
Write-Step "Getting config files..."

$repoDir = "$env:USERPROFILE\Living-Dream-DSH"
if (Test-Path "$repoDir\.git") {
    Write-OK "Repository exists, updating..."
    Push-Location $repoDir
    git pull --quiet
    Pop-Location
} else {
    Write-Host "    Cloning repository to $repoDir ..."
    git clone --quiet https://github.com/alllllllllli/Living-Dream-DSH.git $repoDir
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Clone failed, check network connection"
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-OK "Clone complete"
}

# ============================================================
# 3. Create DSH Directory Structure
# ============================================================
Write-Step "Creating DSH directory structure..."

$dshHome = "$env:USERPROFILE\.dsh"
$profileDir = "$dshHome\profiles\web"

@($dshHome, $profileDir, "$dshHome\uploads") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-OK "Created $_"
    }
}

# ============================================================
# 4. Copy Config Files
# ============================================================
Write-Step "Copying config files..."

$copyMap = @(
    @{src="configs\cordis.patch.yml.template"; dst="$profileDir\cordis.patch.yml"},
    @{src="configs\settings.yaml.template"; dst="$dshHome\settings.yaml"},
    @{src="configs\AGENTS.md"; dst="$dshHome\AGENTS.md"},
    @{src="scripts\secrets.ps1"; dst="$dshHome\secrets.ps1"}
)

foreach ($item in $copyMap) {
    $src = Join-Path $repoDir $item.src
    $dst = $item.dst
    if (Test-Path $dst) {
        Write-Warn "Skip $($item.dst) (already exists)"
    } else {
        Copy-Item $src $dst -Force
        Write-OK "Copied -> $dst"
    }
}

# Replace relative script paths in cordis.patch.yml with absolute paths
$patchFile = "$profileDir\cordis.patch.yml"
if (Test-Path $patchFile) {
    $mcpDir = Join-Path $repoDir "scripts\mcp"
    # Normalize to forward slashes for YAML
    $mcpDirFwd = $mcpDir -replace '\\', '/'
    $content = Get-Content $patchFile -Raw -Encoding UTF8
    $content = $content -replace 'scripts/mcp/', "$mcpDirFwd/"
    Set-Content $patchFile $content -Encoding UTF8
    Write-OK "MCP paths updated in cordis.patch.yml"
}

# memory-mcp engine location: prompt if not in the default spot
if (-not (Test-Path "$HOME\memory-mcp\store_engine.py")) {
    Write-Warn "dsh-memory needs the memory-mcp engine. Set MEMORY_MCP_DIR in cordis.patch.yml (dsh-memory env) to the directory containing store_engine.py, or clone memory-mcp to ~\memory-mcp."
}

# credentials.yaml (don't overwrite)
$credSrc = Join-Path $repoDir "configs\.credentials.yaml.template"
$credDst = "$dshHome\.credentials.yaml"
if (-not (Test-Path $credDst)) {
    Copy-Item $credSrc $credDst
    Write-OK "Created $credDst (needs API Keys)"
} else {
    Write-Warn "Skip .credentials.yaml (already exists)"
}

# package.json (merge instead of overwrite)
$pkgSrc = Join-Path $repoDir "configs\package.json.template"
$pkgDst = "$profileDir\package.json"
$pkgCreated = $false
if (-not (Test-Path $pkgDst)) {
    Copy-Item $pkgSrc $pkgDst
    $pkgCreated = $true
    Write-OK "Created $pkgDst"
} else {
    Write-Warn "Skip package.json (already exists, manual merge needed)"
}

# ============================================================
# 5. Configure API Keys
# ============================================================
Write-Step "Configuring API Keys..."

$credFile = "$dshHome\.credentials.yaml"
$credContent = Get-Content $credFile -Raw

Write-Host @"

    Please fill in your API Keys (leave empty to skip):
    
    1. DeepSeek API Key (Required)
       Get: https://platform.deepseek.com/
    
    2. Zhipu API Key (Image recognition)
       Get: https://open.bigmodel.cn/

"@ -ForegroundColor Gray

# 掩码输入, 不回显明文; Read-Host -AsSecureString 在 PS5.1 下可用
function Read-Secret($prompt) {
    Write-Host $prompt -NoNewline -ForegroundColor Gray
    $sec = Read-Host -AsSecureString
    if (-not $sec) { return "" }
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$dsKey = Read-Secret "DeepSeek API Key (leave empty to skip): "
if ($dsKey) {
    $credContent = $credContent.Replace("your-deepseek-api-key", $dsKey)
    Write-OK "DeepSeek API Key set"
}

$zhipuKey = Read-Secret "Zhipu API Key (leave empty to skip): "
if ($zhipuKey) {
    $credContent = $credContent.Replace("your-zhipu-api-key", $zhipuKey)
    Write-OK "Zhipu API Key set"
}

Set-Content $credFile $credContent -Encoding UTF8

# ============================================================
# 5b. DPAPI-encrypt keys to secrets.json
# ============================================================
Add-Type -AssemblyName System.Security
$secretsObj = [ordered]@{}
$toEncrypt = @{
    "DEEPSEEK_API_KEY" = $dsKey
    "VISION_API_KEY"   = $zhipuKey
}
foreach ($entry in $toEncrypt.GetEnumerator()) {
    if ($entry.Value) {
        $plain = [System.Text.Encoding]::UTF8.GetBytes($entry.Value)
        $blob  = [Security.Cryptography.ProtectedData]::Protect($plain, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
        $secretsObj[$entry.Key] = [Convert]::ToBase64String($blob)
    }
}
if ($secretsObj.Count -gt 0) {
    $secretsFile = "$dshHome\secrets.json"
    $secretsObj | ConvertTo-Json | Set-Content $secretsFile -Encoding UTF8
    Write-OK "DPAPI-encrypted secrets saved to $secretsFile ($($secretsObj.Count) keys)"
}

# ============================================================
# 6. Install Plugin Dependencies
# ============================================================
Write-Step "Installing plugin dependencies..."

# 只有我们新建了 package.json 才跑 pnpm install:
# 老用户已有的 package.json 没把 bundle 列入 dependencies, 跑 install 会清空 bundle
if ($pkgCreated) {
    # dsh-paste-input 是 file: 依赖 (未发布 npm), 先确保源码就位
    # package.json.template 的 file:../plugins/ 相对于 profiles/web/ 解析为 profiles/plugins/
    $pluginSrc = Join-Path $repoDir "plugins\dsh-paste-input"
    $pluginDst = "$profileDir\..\plugins\dsh-paste-input"
    if ((Test-Path $pluginSrc) -and -not (Test-Path $pluginDst)) {
        New-Item -ItemType Directory -Path (Split-Path $pluginDst) -Force | Out-Null
        Copy-Item $pluginSrc $pluginDst -Recurse -Force
        Write-OK "Copied dsh-paste-input plugin to $pluginDst"
    }
    Push-Location $profileDir
    pnpm install --no-frozen-lockfile
    if ($LASTEXITCODE -ne 0) {
        Write-Err "pnpm install failed (exit code $LASTEXITCODE). DSH may fail to start - check the error above."
    } else {
        Write-OK "Plugin dependencies installed"
    }
    Pop-Location
} else {
    Write-Warn "package.json already existed, skipped pnpm install to avoid clearing your bundles"
}

# Install Python MCP dependencies
Write-Step "Installing Python MCP dependencies..."
& cmd /c "pip install mcp markitdown zstandard >nul 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Warn "pip install failed (exit code $LASTEXITCODE), you may need to install manually"
} else {
    Write-OK "Python MCP dependencies installed"
}

# Install proxy.js dependency (http-proxy declared in repo-root package.json, so `node scripts/proxy.js` resolves it)
Write-Step "Installing phone-remote proxy dependency..."
if (Test-Path "$repoDir\node_modules\http-proxy") {
    Write-OK "http-proxy already installed"
} else {
    Push-Location $repoDir
    npm install 2>&1 | Out-Null
    $proxyExit = $LASTEXITCODE
    Pop-Location
    if ($proxyExit -eq 0) {
        Write-OK "http-proxy installed"
    } else {
        Write-Warn "npm install failed (exit code $proxyExit). Run manually: npm install (in $repoDir)"
    }
}

# ============================================================
# 7. Create Desktop Shortcut
# ============================================================
Write-Step "Creating desktop shortcut..."

# Auto-detect DSH Desktop install path
$dshExe = $null
$candidates = @(
    "$env:DSH_DESKTOP_PATH\DeepSeekHarness.exe",
    "$env:ProgramFiles\DeepSeekHarness-Desktop\DeepSeekHarness.exe",
    "$env:ProgramFiles\DeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe",
    "$env:LOCALAPPDATA\DeepSeekHarness-Desktop\DeepSeekHarness.exe",
    "D:\Tools\DeepSeekHarness-Desktop\DeepSeekHarness.exe",
    "D:\Tools\DeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
)
foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) {
        $dshExe = $c
        break
    }
}

$startScript = Join-Path $repoDir "scripts\start-dsh.bat"
$startTemplate = Join-Path $repoDir "scripts\start-dsh.bat.template"

if (-not (Test-Path $startScript)) {
    if ($dshExe) {
        # Generate bat with detected path (skip auto-detect, go straight to :found)
        $bat = @"
@echo off
setlocal enabledelayedexpansion
set "DSH_EXE=$dshExe"
echo [DSH] Starting: !DSH_EXE!
start "" "!DSH_EXE!"
echo [DSH] Access DSH at: http://127.0.0.1:3080
"@
        Set-Content $startScript $bat -Encoding ASCII
        Write-OK "Generated start-dsh.bat (detected: $dshExe)"
    } else {
        # Fall back to template (auto-detect at runtime)
        Copy-Item $startTemplate $startScript
        Write-Warn "DSH Desktop not detected — start-dsh.bat uses auto-detect (may need manual edit)"
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
Write-OK "Desktop shortcut created"

# ============================================================
# 8. Done
# ============================================================
Write-Host @"

 ============================================================
   Installation Complete!
 ============================================================

   Config files:
     DSH Home:    $dshHome
     Profile:     $profileDir
     Repository:  $repoDir

   Next steps:
     1. Double-click "Living Dream DSH" shortcut on desktop
     2. Or start DSH Desktop manually

   To edit config:
     notepad $credFile
     notepad $profileDir\cordis.patch.yml

   Documentation:
     $repoDir\README.md

 ============================================================
"@ -ForegroundColor Green

Read-Host "Press Enter to exit"

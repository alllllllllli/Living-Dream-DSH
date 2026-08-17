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

# ============================================================
# 7. Create Desktop Shortcut
# ============================================================
Write-Step "Creating desktop shortcut..."

$startScript = Join-Path $repoDir "scripts\start-dsh.bat"
$startTemplate = Join-Path $repoDir "scripts\start-dsh.bat.template"

if (-not (Test-Path $startScript)) {
    Copy-Item $startTemplate $startScript
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

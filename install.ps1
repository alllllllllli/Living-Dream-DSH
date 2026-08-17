# ============================================================
# DSH Ultra Config - 一键安装程序
# 双击运行或在 PowerShell 中执行：.\install.ps1
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

# 颜色输出
function Write-Step($msg) { Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-OK($msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[-] $msg" -ForegroundColor Red }

# Banner
Write-Host @"

 ============================================================
   DSH Ultra Config - 一键安装程序
   https://github.com/alllllllllli/dsh-ultra-config
 ============================================================
"@ -ForegroundColor Cyan

# ============================================================
# 1. 环境检查
# ============================================================
Write-Step "检查系统环境..."

# Node.js
$nodeVer = node --version 2>$null
if (-not $nodeVer) {
    Write-Err "未找到 Node.js，请先安装：https://nodejs.org/"
    Read-Host "按回车退出"
    exit 1
}
Write-OK "Node.js $nodeVer"

# Python
$pyVer = python --version 2>$null
if (-not $pyVer) {
    Write-Err "未找到 Python，请先安装：https://python.org/"
    Read-Host "按回车退出"
    exit 1
}
Write-OK "$pyVer"

# pnpm
$pnpmVer = pnpm --version 2>$null
if (-not $pnpmVer) {
    Write-Warn "未找到 pnpm，正在安装..."
    npm install -g pnpm
}
Write-OK "pnpm v$(pnpm --version)"

# DSH 桌面版
$dshExe = "D:\ToolsDeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
if (Test-Path $dshExe) {
    Write-OK "DSH 桌面版已安装"
} else {
    Write-Warn "未检测到 DSH 桌面版（$dshExe）"
    Write-Warn "请确保已安装 DSH 桌面版，配置文件将复制到 ~/.dsh"
}

# ============================================================
# 2. 克隆仓库
# ============================================================
Write-Step "获取配置文件..."

$repoDir = "$env:USERPROFILE\dsh-ultra-config"
if (Test-Path "$repoDir\.git") {
    Write-OK "仓库已存在，更新中..."
    Push-Location $repoDir
    git pull --quiet
    Pop-Location
} else {
    Write-Host "    克隆仓库到 $repoDir ..."
    git clone --quiet https://github.com/alllllllllli/dsh-ultra-config.git $repoDir
    if ($LASTEXITCODE -ne 0) {
        Write-Err "克隆失败，请检查网络连接"
        Read-Host "按回车退出"
        exit 1
    }
    Write-OK "克隆完成"
}

# ============================================================
# 3. 创建 DSH 目录结构
# ============================================================
Write-Step "创建 DSH 目录结构..."

$dshHome = "$env:USERPROFILE\.dsh"
$profileDir = "$dshHome\profiles\web"

@($dshHome, $profileDir, "$dshHome\uploads") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-OK "创建 $_"
    }
}

# ============================================================
# 4. 复制配置文件
# ============================================================
Write-Step "复制配置文件..."

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
        Write-Warn "跳过 $($item.dst)（已存在）"
    } else {
        Copy-Item $src $dst -Force
        Write-OK "复制 -> $dst"
    }
}

# credentials.yaml（不覆盖）
$credSrc = Join-Path $repoDir "configs\.credentials.yaml.template"
$credDst = "$dshHome\.credentials.yaml"
if (-not (Test-Path $credDst)) {
    Copy-Item $credSrc $credDst
    Write-OK "创建 $credDst（需填入 API Key）"
} else {
    Write-Warn "跳过 .credentials.yaml（已存在）"
}

# package.json（合并而非覆盖）
$pkgSrc = Join-Path $repoDir "configs\package.json.template"
$pkgDst = "$profileDir\package.json"
if (-not (Test-Path $pkgDst)) {
    Copy-Item $pkgSrc $pkgDst
    Write-OK "创建 $pkgDst"
} else {
    Write-Warn "跳过 package.json（已存在，如需更新请手动合并）"
}

# ============================================================
# 5. 配置 API Key
# ============================================================
Write-Step "配置 API Key..."

$credFile = "$dshHome\.credentials.yaml"
$credContent = Get-Content $credFile -Raw

Write-Host @"

    请填入你的 API Key（留空跳过，稍后手动编辑）：
    
    1. DeepSeek API Key（必填）
       获取：https://platform.deepseek.com/
    
    2. CNB API Key（免费模型）
       获取：https://cnb.cool/
    
    3. 智谱 API Key（发图识别）
       获取：https://open.bigmodel.cn/

"@ -ForegroundColor Gray

$dsKey = Read-Host "DeepSeek API Key（留空跳过）"
if ($dsKey) {
    $credContent = $credContent -replace "your-deepseek-api-key", $dsKey
    Write-OK "已设置 DeepSeek API Key"
}

$cnbKey = Read-Host "CNB API Key（留空跳过）"
if ($cnbKey) {
    $credContent = $credContent -replace "your-cnb-api-key", $cnbKey
    Write-OK "已设置 CNB API Key"
}

$zhipuKey = Read-Host "智谱 API Key（留空跳过）"
if ($zhipuKey) {
    $credContent = $credContent -replace "your-zhipu-api-key", $zhipuKey
    Write-OK "已设置智谱 API Key"
}

Set-Content $credFile $credContent -Encoding UTF8

# ============================================================
# 6. 安装插件依赖
# ============================================================
Write-Step "安装插件依赖..."

Push-Location $profileDir
if (Test-Path "package.json") {
    pnpm install --no-frozen-lockfile 2>&1 | Out-Null
    Write-OK "插件依赖安装完成"
} else {
    Write-Warn "未找到 package.json，跳过"
}
Pop-Location

# ============================================================
# 7. 创建桌面快捷方式
# ============================================================
Write-Step "创建桌面快捷方式..."

$startScript = Join-Path $repoDir "scripts\start-dsh.bat"
$startTemplate = Join-Path $repoDir "scripts\start-dsh.bat.template"

if (-not (Test-Path $startScript)) {
    Copy-Item $startTemplate $startScript
}

$shortcutPath = "$env:USERPROFILE\Desktop\DSH Ultra.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/c `"$startScript`""
$shortcut.WorkingDirectory = $repoDir
$shortcut.IconLocation = "$dshExe,0"
$shortcut.Description = "DSH Ultra Config 启动器"
$shortcut.Save()
Write-OK "桌面快捷方式已创建"

# ============================================================
# 8. 完成
# ============================================================
Write-Host @"

 ============================================================
   安装完成！
 ============================================================

   配置文件位置：
     DSH Home:    $dshHome
     Profile:     $profileDir
     仓库:        $repoDir

   下一步：
     1. 双击桌面 "DSH Ultra" 快捷方式启动
     2. 或手动启动 DSH 桌面版

   如需修改配置：
     notepad $credFile
     notepad $profileDir\cordis.patch.yml

   文档：
     $repoDir\README.md

 ============================================================
"@ -ForegroundColor Green

Read-Host "按回车退出"

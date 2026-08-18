# Called by Inno Setup [Run] postinstall checkbox
# Reads detected-dsh-path.txt and creates desktop shortcut
param([string]$AppDir)
$pathFile = Join-Path $AppDir "scripts\detected-dsh-path.txt"
if (Test-Path $pathFile) {
    $exePath = Get-Content $pathFile -Raw
    $exePath = $exePath.Trim()
    if ($exePath -and (Test-Path $exePath)) {
        $wsh = New-Object -ComObject WScript.Shell
        $desktop = [Environment]::GetFolderPath('Desktop')
        $s = $wsh.CreateShortcut((Join-Path $desktop "DeepSeek Harness.lnk"))
        $s.TargetPath = $exePath
        $s.WorkingDirectory = Split-Path $exePath -Parent
        $s.Description = "DeepSeek Harness Desktop"
        $s.Save()
    }
}
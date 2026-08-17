"""dsh-ocr MCP server — Windows offline screen OCR.

Tools:
  ocr_screen      — capture full screen and OCR all text
  ocr_region      — capture a screen region and OCR text
  ocr_screen_text — capture full screen, return plain text only (no coordinates)

Requires: Windows 10+ (uses Windows.Media.Ocr via PowerShell).
"""

import json
import subprocess
import sys
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-ocr")

# PowerShell script that captures screen, runs OCR, and returns JSON
_OCR_SCRIPT = r'''
param(
    [int]$X = 0, [int]$Y = 0,
    [int]$W = 0, [int]$H = 0,
    [switch]$TextOnly
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Capture screen
$bounds = if ($W -gt 0 -and $H -gt 0) {
    [System.Drawing.Rectangle]::new($X, $Y, $W, $H)
} else {
    [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
}

$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$g.Dispose()

# Save to temp file
$tmpFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.png'
$bmp.Save($tmpFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# OCR using Windows.Media.Ocr
[Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType=WindowsRuntime] | Out-Null

$stream = [System.IO.WindowsRuntime.StreamExtensions]::AsRandomAccessStream(
    [System.IO.File]::OpenRead($tmpFile)
)
$decoder = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream).GetAwaiter().GetResult()
$bitmap = $decoder.GetSoftwareBitmapAsync([Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8, [Windows.Graphics.Imaging.BitmapAlphaMode]::Premultiplied).GetAwaiter().GetResult()

$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
$result = $engine.RecognizeAsync($bitmap).GetAwaiter().GetResult()

Remove-Item $tmpFile -ErrorAction SilentlyContinue

if ($TextOnly) {
    ($result.Lines | ForEach-Object { $_.Text }) -join "`n"
} else {
    $lines = @()
    foreach ($line in $result.Lines) {
        $rect = $line.Words[0].BoundingRect
        $lines += @{
            text = $line.Text
            x = [int]$rect.X + $bounds.X
            y = [int]$rect.Y + $bounds.Y
            w = [int]$rect.Width
            h = [int]$rect.Height
        }
    }
    $lines | ConvertTo-Json -Compress
}
'''


def _run_ocr(x: int = 0, y: int = 0, w: int = 0, h: int = 0, text_only: bool = False) -> str:
    """Run OCR via PowerShell and return result."""
    cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", _OCR_SCRIPT]
    if x or y or w or h:
        cmd.extend(["-X", str(x), "-Y", str(y), "-W", str(w), "-H", str(h)])
    if text_only:
        cmd.append("-TextOnly")

    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if r.returncode != 0:
            return json.dumps({"error": r.stderr.strip() or "OCR failed"})
        return r.stdout.strip()
    except subprocess.TimeoutExpired:
        return json.dumps({"error": "OCR timed out (30s)"})
    except Exception as e:
        return json.dumps({"error": str(e)})


@mcp.tool()
def ocr_screen() -> str:
    """Capture the full screen and OCR all text with coordinates.

    Returns:
        JSON array of {text, x, y, w, h} per line.
    """
    return _run_ocr()


@mcp.tool()
def ocr_region(x: int, y: int, width: int, height: int) -> str:
    """Capture a screen region and OCR text with coordinates.

    Args:
        x: Left edge of region (pixels).
        y: Top edge of region (pixels).
        width: Width of region (pixels).
        height: Height of region (pixels).

    Returns:
        JSON array of {text, x, y, w, h} per line.
    """
    return _run_ocr(x=x, y=y, w=width, h=height)


@mcp.tool()
def ocr_screen_text() -> str:
    """Capture the full screen and return OCR text only (no coordinates).

    Returns:
        Plain text, one line per recognized text line.
    """
    return _run_ocr(text_only=True)


if __name__ == "__main__":
    mcp.run(transport="stdio")

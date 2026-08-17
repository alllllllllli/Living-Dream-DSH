# DPAPI secret decryptor for DSH config !!js expressions.
# Reads a named value from secrets.json (DPAPI-encrypted, bound to this Windows
# account) and prints the plaintext to stdout. No secrets live in this file.
param(
  [Parameter(Mandatory = $true)][string][ValidateNotNullOrEmpty()] $Name
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security
$path = Join-Path $PSScriptRoot 'secrets.json'
$raw = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$blob = $raw.$Name
if ([string]::IsNullOrWhiteSpace($blob)) { throw "secret '$Name' not found in secrets.json" }
$bytes = [Convert]::FromBase64String($blob)
$clear = [Security.Cryptography.ProtectedData]::Unprotect($bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Text.Encoding]::UTF8.GetString($clear)

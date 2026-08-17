@echo off
:: ============================================================
:: DSH Ultra Config - 双击安装
:: ============================================================
chcp 65001 >nul 2>&1
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "install.ps1"

@echo off
:: ============================================================
:: Living Dream DSH - One-Click Install
:: ============================================================
chcp 65001 >nul 2>&1
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "install-gui.ps1"

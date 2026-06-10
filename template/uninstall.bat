@echo off
chcp 65001 > nul
where pwsh.exe >nul 2>&1
if %errorlevel% == 0 (
    pwsh.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1"
)
pause

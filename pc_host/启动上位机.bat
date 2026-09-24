@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0distance_monitor.ps1"
if errorlevel 1 (
  echo.
  echo 上位机启动失败，请截图本窗口中的错误信息。
  pause
)

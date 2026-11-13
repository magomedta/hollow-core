@echo off
setlocal
title Hollow Core - Subterranean Survival
cd /d "%~dp0"
echo ====================================================
echo Starting Hollow Core (Godot 4 Forward+ Vulkan)...
echo Working Directory: %CD%
echo ====================================================

set "GODOT_BIN=C:\Users\magom\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%GODOT_BIN%" (
    echo [ERROR] Godot executable not found at: "%GODOT_BIN%"
    pause
    exit /b 1
)

"%GODOT_BIN%" --path .

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Game closed or crashed with exit code %ERRORLEVEL%.
    pause
)

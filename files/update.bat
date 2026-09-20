@echo off
rem Mise a jour de la base (Windows). Usage : update.bat [check|force]
setlocal
set "ARGS="
if /I "%~1"=="check" set "ARGS=-Check"
if /I "%~1"=="force" set "ARGS=-Force"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0resources\[standalone]\updater\tools\update.ps1" %ARGS%
echo.
pause

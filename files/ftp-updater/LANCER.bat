@echo off
title Mise a jour Best Dev
cd /d "%~dp0"

if not exist node_modules (
  echo Premiere utilisation : installation des composants...
  call npm install --silent
  if errorlevel 1 (
    echo.
    echo L'installation a echoue. Verifiez que Node.js est installe : https://nodejs.org
    pause
    exit /b 1
  )
)

start "" http://127.0.0.1:7788
node server.mjs
pause

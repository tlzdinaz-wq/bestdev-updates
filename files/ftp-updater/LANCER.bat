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

echo.
echo  1 - Sur cette machine uniquement   (recommande)
echo  2 - Ouvert a l'exterieur, joignable a l'IP du serveur
echo.
set /p mode=Votre choix [1] :
if "%mode%"=="2" (
  echo.
  echo Lancement ouvert. L'adresse et la cle d'acces s'affichent ci-dessous.
  node server.mjs --public
) else (
  start "" http://127.0.0.1:7788
  node server.mjs
)
pause

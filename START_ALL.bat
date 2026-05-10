@echo off
title FurSpeak AI Full Launcher

cd /d D:\GeminiCLI\FurSpeak-AI_Android_Build

echo Starting Backend...
start cmd /k START_BACKEND.bat

timeout /t 5 >nul

echo Starting Flutter...
start cmd /k START_FLUTTER.bat

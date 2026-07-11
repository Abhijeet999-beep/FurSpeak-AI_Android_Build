@echo off
title FurSpeak AI Full Launcher

cd /d "%~dp0"

echo ======================================
echo   FurSpeak AI - Full Stack Launcher
echo ======================================
echo.

echo [1/2] Starting Backend server...
start "FurSpeak Backend" cmd /k START_BACKEND.bat

echo Waiting for backend to initialize...
timeout /t 8 >nul

echo [2/2] Starting Flutter app...
start "FurSpeak Flutter" cmd /k START_FLUTTER.bat

:: Dynamically resolve port from .env file for display
for /f "tokens=*" %%i in ('backend\venv\Scripts\python.exe -c "import os; from dotenv import load_dotenv; from urllib.parse import urlparse; load_dotenv(); print(urlparse(os.getenv('API_BASE_URL', 'http://localhost:8000')).port or 8000)"') do set PORT=%%i

if "%PORT%"=="" set PORT=8000

echo.
echo ======================================
echo   Both services launched!
echo   Backend:  http://localhost:%PORT%
echo   Swagger:  http://localhost:%PORT%/docs
echo ======================================
echo.

pause

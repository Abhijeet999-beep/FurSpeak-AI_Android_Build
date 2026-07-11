@echo off
title FurSpeak AI Flutter Runner

cd /d "%~dp0"

set PATH=C:\src\flutter\bin;%PATH%

echo ======================================
echo   FurSpeak AI - Flutter App
echo ======================================
echo.
echo Checking connected devices...
echo.

flutter devices

echo.
echo ======================================
echo   Launching FurSpeak AI on emulator
echo ======================================
echo.

:: Dynamically resolve port from .env file for port forwarding
for /f "tokens=*" %%i in ('backend\venv\Scripts\python.exe -c "import os; from dotenv import load_dotenv; from urllib.parse import urlparse; load_dotenv(); print(urlparse(os.getenv('API_BASE_URL', 'http://localhost:8000')).port or 8000)"') do set PORT=%%i

if "%PORT%"=="" set PORT=8000

echo Setting up USB port forwarding for physical devices on port %PORT%...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:%PORT% tcp:%PORT%
echo.

flutter run

pause

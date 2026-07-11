@echo off
title FurSpeak AI Backend

cd /d "%~dp0"

echo ======================================
echo   FurSpeak AI - Backend Server
echo ======================================
echo.

if not exist backend\venv\Scripts\activate.bat (
    echo [ERROR] Virtual environment not found at backend\venv
    echo Run: C:\Python314\python.exe -m venv backend\venv
    echo Then: backend\venv\Scripts\pip.exe install -r backend\requirements.txt
    pause
    exit /b 1
)

call backend\venv\Scripts\activate

set PYTHONUNBUFFERED=1
set ENVIRONMENT=development

:: Dynamically resolve host and port from .env file
for /f "tokens=*" %%i in ('backend\venv\Scripts\python.exe -c "import os; from dotenv import load_dotenv; from urllib.parse import urlparse; load_dotenv(); print(urlparse(os.getenv('API_BASE_URL', 'http://localhost:8000')).port or 8000)"') do set PORT=%%i

if "%PORT%"=="" set PORT=8000

echo [OK] Virtual environment activated
echo [OK] Starting uvicorn on http://0.0.0.0:%PORT%
echo.

uvicorn backend.main:app --host 0.0.0.0 --port %PORT% --reload

pause

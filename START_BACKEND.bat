@echo off
title FurSpeak AI Backend

cd /d D:\GeminiCLI\FurSpeak-AI_Android_Build

echo ======================================
echo Starting FurSpeak AI Backend...
echo ======================================

call .venv\Scripts\activate

set PYTHONUNBUFFERED=1
set ENVIRONMENT=development

uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload

pause

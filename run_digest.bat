@echo off
REM Double-click this to run the digest. Keeps the window open after.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_digest.ps1"
echo.
echo === Done. Open digest.html in this folder. ===
pause

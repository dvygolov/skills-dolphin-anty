@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-dolphin-ocli.ps1" %*
exit /b %ERRORLEVEL%

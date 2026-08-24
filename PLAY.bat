@echo off
pushd "%~dp0"
where love.exe >nul 2>nul
if %errorlevel%==0 (
    love.exe .
) else (
    "C:\Program Files\LOVE\love.exe" .
)
popd

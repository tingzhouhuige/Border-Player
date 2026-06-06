@echo off
setlocal
set "PATH=C:\src\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

echo ========================================
echo  Building Border Player + Desktop Lyric
echo ========================================
echo.

echo [1/2] Building main project...
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: Main project build failed!
    exit /b 1
)
echo      Main project: OK
echo.

echo [2/2] Building desktop_lyric...
cd /d "%~dp0desktop_lyric"
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: desktop_lyric build failed!
    exit /b 1
)
echo      Desktop lyric: OK
echo.

echo ========================================
echo  Build complete!
echo  Main:  build\windows\x64\runner\Release\border_player.exe
echo  Lyric: desktop_lyric\build\windows\x64\runner\Release\desktop_lyric.exe
echo ========================================

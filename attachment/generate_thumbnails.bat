@echo off
REM 本文件必须为UTF-8编码，不可ANSI
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM 视频缩略图生成 - 批处理启动器
REM ============================================
set "FFMPEG_DIR=Q:\ENVlibrary\ffmpegN"
set "THUMB_FOLDER=.thumbnails"
set "THUMB_EXT=webp"


set "FFMPEG_PATH=%FFMPEG_DIR%\ffmpeg.exe"
if "%FFMPEG_DIR%"=="" set "FFMPEG_PATH=ffmpeg"

if not exist "%FFMPEG_PATH%" set /p FFMPEG_PATH=拖入FFmpeg.exe	
set /p VAULT_ROOT=拖入Obsidian仓库或视频文件夹	

REM 获取当前脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%generate_thumbnails.ps1"

REM 检查必要文件
if not exist "%VAULT_ROOT%" (
    echo [错误] 仓库目录不存在: %VAULT_ROOT%
    pause
    exit /b 1
)

if not exist "%PS_SCRIPT%" (
    echo [错误] 找不到 PowerShell 脚本: %PS_SCRIPT%
    pause
    exit /b 1
)

REM 检查 ffmpeg 可用性
if not "%FFMPEG_PATH%"=="ffmpeg" (
    if not exist "%FFMPEG_PATH%" (
        echo [错误] 找不到 ffmpeg.exe: %FFMPEG_PATH%
        pause
        exit /b 1
    )
) else (
    where ffmpeg >nul 2>nul
    if errorlevel 1 (
        echo [错误] 系统中找不到 ffmpeg，请安装或设置 FFMPEG_DIR
        pause
        exit /b 1
    )
)

echo [信息] 仓库路径: %VAULT_ROOT%
echo [信息] ffmpeg 路径: %FFMPEG_PATH%
echo [信息] 正在生成缩略图，请稍候...

REM 调用 PowerShell 脚本，绕过执行策略
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -VaultRoot "%VAULT_ROOT%" -FFmpegPath "%FFMPEG_PATH%" -ThumbFolderName "%THUMB_FOLDER%" -ThumbExt "%THUMB_EXT%"
echo.
echo [信息] 缩略图生成完毕
pause
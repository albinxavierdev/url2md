@echo off
REM Setup script for URL to Markdown Converter on Windows
REM This script helps set up the converter for first-time use

echo ========================================
echo   URL to Markdown Converter Setup
echo ========================================
echo.

REM Check if Go is installed
go version >nul 2>&1
if errorlevel 1 (
    echo Warning: Go is not installed or not in PATH
    echo You can download Go from: https://golang.org/dl/
    echo.
) else (
    echo ✓ Go is installed
    go version
    echo.
)

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo Warning: Git is not installed or not in PATH
    echo You can download Git from: https://git-scm.com/download/win
    echo.
) else (
    echo ✓ Git is installed
    git --version
    echo.
)

REM Check for curl or PowerShell
curl --version >nul 2>&1
if errorlevel 1 (
    echo Warning: curl is not installed
    powershell -Command "Get-Command Invoke-WebRequest" >nul 2>&1
    if errorlevel 1 (
        echo Error: Neither curl nor PowerShell Invoke-WebRequest is available
        echo Please install curl from: https://curl.se/windows/
        echo Or ensure PowerShell is available
        pause
        exit /b 1
    ) else (
        echo ✓ PowerShell Invoke-WebRequest is available
    )
) else (
    echo ✓ curl is installed
    curl --version | findstr curl
)
echo.

REM Check if html2markdown.exe exists
if not exist "html2markdown.exe" (
    echo html2markdown.exe not found. Attempting to build...
    
    if exist "go.mod" (
        echo Building html2markdown.exe...
        go build -o html2markdown.exe .\cli
        
        if exist "html2markdown.exe" (
            echo ✓ Successfully built html2markdown.exe
        ) else (
            echo ✗ Failed to build html2markdown.exe
            echo Please ensure Go is properly installed and try again
            pause
            exit /b 1
        )
    ) else (
        echo Error: go.mod not found. Make sure you're in the correct directory.
        echo This script should be run from the html-to-markdown project directory.
        pause
        exit /b 1
    )
) else (
    echo ✓ html2markdown.exe found
)
echo.

REM Test the converter
echo Testing the converter...
url2md.bat --help >nul 2>&1
if errorlevel 1 (
    echo ✗ Error: url2md.bat failed to run
    echo Please check the installation
    pause
    exit /b 1
) else (
    echo ✓ url2md.bat is working correctly
)
echo.

REM Create example directories
if not exist "markdown" mkdir markdown
if not exist "media" mkdir media
echo ✓ Created output directories

echo.
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo You can now use the converter:
echo.
echo   Basic usage:
echo     url2md.bat https://example.com/article
echo.
echo   Batch processing:
echo     batch-convert.bat example-urls.txt
echo.
echo   Get help:
echo     url2md.bat --help
echo.
echo Happy converting! 🎉
echo.
pause
@echo off
REM Batch URL to Markdown Converter for Windows
REM Process multiple URLs from a text file

setlocal EnableDelayedExpansion

REM Default settings
set "URLS_FILE=urls.txt"
set "OUTPUT_DIR=batch-converted"
set "DELAY=1"
set "CSS_SELECTOR="
set "NO_MEDIA="
set "MEDIA_TYPES="

REM Parse arguments
:parse_args
if "%~1"=="" goto check_setup
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-o" (
    set "OUTPUT_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--output" (
    set "OUTPUT_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-s" (
    set "CSS_SELECTOR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--selector" (
    set "CSS_SELECTOR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-d" (
    set "DELAY=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--delay" (
    set "DELAY=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--no-media" (
    set "NO_MEDIA=--no-media"
    shift
    goto parse_args
)
if /i "%~1"=="--no-images" (
    set "NO_MEDIA=--no-media"
    shift
    goto parse_args
)
if /i "%~1"=="--media-types" (
    set "MEDIA_TYPES=--media-types %~2"
    shift
    shift
    goto parse_args
)
if not defined URLS_FILE_SET (
    set "URLS_FILE=%~1"
    set "URLS_FILE_SET=1"
    shift
    goto parse_args
)
shift
goto parse_args

:show_help
echo Usage: %~nx0 [OPTIONS] [URLS_FILE]
echo.
echo Batch convert multiple URLs to Markdown format.
echo.
echo ARGUMENTS:
echo     URLS_FILE    File containing URLs (one per line) - default: urls.txt
echo.
echo OPTIONS:
echo     -h, --help          Show this help
echo     -o, --output DIR    Output directory (default: batch-converted)
echo     -s, --selector CSS  CSS selector for content extraction
echo     -d, --delay SECS    Delay between requests in seconds (default: 1)
echo     --no-media          Skip media downloads
echo     --media-types TYPE  Comma-separated media types: images,videos,audio,documents,fonts
echo.
echo EXAMPLE:
echo     %~nx0 urls.txt -o articles -s ".content" -d 2
echo.
goto :eof

:check_setup
REM Check for URLs file
if not exist "%URLS_FILE%" (
    echo Error: URLs file not found: %URLS_FILE%
    echo Create a file with one URL per line.
    exit /b 1
)

REM Check for url2md.bat script
if not exist "url2md.bat" (
    echo Error: url2md.bat script not found
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Count URLs
set "TOTAL_URLS=0"
for /f %%i in ('type "%URLS_FILE%" ^| find /c /v ""') do set "TOTAL_URLS=%%i"
echo Batch processing %TOTAL_URLS% URLs...
echo.

REM Process URLs
set "SUCCESS_COUNT=0"
set "FAILED_COUNT=0"
set "CURRENT=0"

for /f "usebackq tokens=* delims=" %%u in ("%URLS_FILE%") do (
    set "url=%%u"
    
    REM Skip empty lines and comments
    if not "!url!"=="" (
        echo !url! | findstr /r "^#" >nul
        if errorlevel 1 (
            set /a CURRENT+=1
            echo [!CURRENT!/%TOTAL_URLS%] Processing: !url!
            
            REM Build command
            set "cmd=url2md.bat"
            if defined CSS_SELECTOR set "cmd=!cmd! -s "!CSS_SELECTOR!""
            if defined NO_MEDIA set "cmd=!cmd! !NO_MEDIA!"
            if defined MEDIA_TYPES set "cmd=!cmd! !MEDIA_TYPES!"
            set "cmd=!cmd! -o "!OUTPUT_DIR!" "!url!""
            
            REM Execute conversion
            !cmd! >nul 2>&1
            if errorlevel 1 (
                set /a FAILED_COUNT+=1
                echo Error: Failed
                echo !url! >> "!OUTPUT_DIR!\failed-urls.txt"
            ) else (
                set /a SUCCESS_COUNT+=1
                echo Success: Converted
            )
            
            echo.
            
            REM Respectful delay
            if !CURRENT! LSS %TOTAL_URLS% (
                timeout /t %DELAY% /nobreak >nul
            )
        )
    )
)

REM Summary
echo === BATCH CONVERSION COMPLETE ===
echo Successful: !SUCCESS_COUNT!
echo Failed: !FAILED_COUNT!
echo Output directory: %OUTPUT_DIR%

if !FAILED_COUNT! GTR 0 (
    echo Failed URLs saved to: %OUTPUT_DIR%\failed-urls.txt
)

goto :eof
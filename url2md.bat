@echo off
REM URL to Markdown Converter for Windows
REM A batch script to convert web pages to clean Markdown format

setlocal EnableDelayedExpansion

REM Configuration
set "MEDIA_DIR=media"
set "OUTPUT_DIR=markdown"
set "USER_AGENT=Mozilla/5.0 (compatible; URL2MD-Converter)"

REM Media file extensions
set "IMAGE_EXTENSIONS=jpg jpeg png gif webp svg bmp ico tiff tif"
set "VIDEO_EXTENSIONS=mp4 webm ogg avi mov wmv flv mkv m4v"
set "AUDIO_EXTENSIONS=mp3 wav ogg flac aac m4a wma opus"
set "DOCUMENT_EXTENSIONS=pdf doc docx ppt pptx xls xlsx zip rar 7z tar gz"
set "FONT_EXTENSIONS=woff woff2 ttf otf eot"

REM Initialize variables
set "URL="
set "OUTPUT_FILE="
set "CSS_SELECTOR="
set "DOMAIN_OVERRIDE="
set "SKIP_MEDIA="
set "KEEP_HTML="
set "MEDIA_TYPES_FILTER="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto check_args
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
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
    set "DOMAIN_OVERRIDE=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--domain" (
    set "DOMAIN_OVERRIDE=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-m" (
    set "MEDIA_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--media" (
    set "MEDIA_DIR=%~2"
    shift
    shift
    goto parse_args
)
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
if /i "%~1"=="--no-media" (
    set "SKIP_MEDIA=true"
    shift
    goto parse_args
)
if /i "%~1"=="--no-images" (
    set "SKIP_MEDIA=true"
    shift
    goto parse_args
)
if /i "%~1"=="--media-types" (
    set "MEDIA_TYPES_FILTER=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--keep-html" (
    set "KEEP_HTML=true"
    shift
    goto parse_args
)
if "%~1"=="" goto check_args
if not defined URL (
    set "URL=%~1"
    shift
    goto parse_args
)
if not defined OUTPUT_FILE (
    set "OUTPUT_FILE=%~1"
    shift
    goto parse_args
)
shift
goto parse_args

:show_help
echo Usage: %~nx0 [OPTIONS] ^<URL^> [OUTPUT_FILE]
echo.
echo Convert web pages to clean Markdown format with local media downloads.
echo.
echo ARGUMENTS:
echo     URL          The web page URL to convert
echo     OUTPUT_FILE  Optional output file path (default: auto-generated from URL)
echo.
echo OPTIONS:
echo     -h, --help          Show this help message
echo     -s, --selector CSS  Use specific CSS selector to extract content
echo     -d, --domain DOMAIN Override domain for relative URL resolution
echo     -m, --media DIR     Directory to save media files (default: media)
echo     -o, --output DIR    Output directory (default: markdown)
echo     --no-media          Skip downloading media files
echo     --media-types TYPE  Comma-separated media types to download: images,videos,audio,documents,fonts (default: all)
echo     --keep-html         Keep HTML file for debugging
echo.
echo EXAMPLES:
echo     %~nx0 https://example.com/article
echo     %~nx0 https://blog.com/post -s ".content" -o articles
echo     %~nx0 https://site.com/page.html my-article.md
echo     %~nx0 https://tutorial.com/page --media-types images,videos -m assets
echo.
goto :eof

:check_args
if not defined URL (
    echo Error: URL is required
    echo Use --help for usage information.
    exit /b 1
)

REM Check for required dependencies
if not exist "html2markdown.exe" (
    echo Error: html2markdown.exe binary not found in current directory
    echo Please ensure the html2markdown.exe binary is available.
    exit /b 1
)

REM Check for curl (preferred) or powershell for downloads
curl --version >nul 2>&1
if errorlevel 1 (
    powershell -Command "Get-Command Invoke-WebRequest" >nul 2>&1
    if errorlevel 1 (
        echo Error: Neither curl nor PowerShell Invoke-WebRequest is available
        echo Please install curl or ensure PowerShell is available.
        exit /b 1
    )
    set "DOWNLOAD_METHOD=powershell"
) else (
    set "DOWNLOAD_METHOD=curl"
)

echo URL to Markdown Converter
echo.

REM Generate output filename if not provided
if not defined OUTPUT_FILE (
    set "TEMP_NAME=!URL!"
    set "TEMP_NAME=!TEMP_NAME:https://=!"
    set "TEMP_NAME=!TEMP_NAME:http://=!"
    set "TEMP_NAME=!TEMP_NAME:/=_!"
    set "TEMP_NAME=!TEMP_NAME:\=_!"
    set "TEMP_NAME=!TEMP_NAME::=_!"
    set "TEMP_NAME=!TEMP_NAME:?=_!"
    set "TEMP_NAME=!TEMP_NAME:&=_!"
    set "OUTPUT_FILE=!OUTPUT_DIR!\!TEMP_NAME!.md"
)

REM Create output directories
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!"
if not exist "!MEDIA_DIR!" mkdir "!MEDIA_DIR!"

REM Create temporary files
set "TEMP_HTML=%TEMP%\url2md_html_%RANDOM%.html"
set "TEMP_MD=%TEMP%\url2md_md_%RANDOM%.md"

echo Converting: !URL!

REM Download HTML content
echo Fetching HTML content...
if "!DOWNLOAD_METHOD!"=="curl" (
    curl -s -L --max-time 30 --retry 3 --user-agent "!USER_AGENT!" "!URL!" -o "!TEMP_HTML!"
) else (
    powershell -Command "try { Invoke-WebRequest -Uri '!URL!' -OutFile '!TEMP_HTML!' -UserAgent '!USER_AGENT!' -TimeoutSec 30 } catch { exit 1 }"
)

if not exist "!TEMP_HTML!" (
    echo Error: Failed to fetch HTML from: !URL!
    goto cleanup
)

REM Convert to Markdown
echo Converting to Markdown...
set "HTML2MD_CMD=html2markdown.exe"
if defined DOMAIN_OVERRIDE set "HTML2MD_CMD=!HTML2MD_CMD! -domain=!DOMAIN_OVERRIDE!"
if defined CSS_SELECTOR set "HTML2MD_CMD=!HTML2MD_CMD! -sel=!CSS_SELECTOR!"

!HTML2MD_CMD! < "!TEMP_HTML!" > "!TEMP_MD!" 2>nul

if not exist "!TEMP_MD!" (
    echo Error: Failed to convert HTML to Markdown
    goto cleanup
)

REM Check if conversion produced content
for %%F in ("!TEMP_MD!") do set "FILE_SIZE=%%~zF"
if !FILE_SIZE! LEQ 0 (
    echo Error: Conversion produced empty result
    goto cleanup
)

REM Process media files using PowerShell script
if not "!SKIP_MEDIA!"=="true" (
    if exist "Process-Media.ps1" (
        echo Processing media files...
        set "PS_CMD=powershell -ExecutionPolicy Bypass -File Process-Media.ps1 -MarkdownFile '!OUTPUT_FILE!' -BaseUrl '!URL!' -MediaDir '!MEDIA_DIR!'"
        if defined MEDIA_TYPES_FILTER set "PS_CMD=!PS_CMD! -MediaTypes '!MEDIA_TYPES_FILTER!'"
        !PS_CMD!
    ) else (
        echo Warning: Process-Media.ps1 not found, skipping advanced media processing
    )
)

REM Write final content to output file
copy "!TEMP_MD!" "!OUTPUT_FILE!" >nul

REM Clean up temporary files
if not "!KEEP_HTML!"=="true" (
    if exist "!TEMP_HTML!" del "!TEMP_HTML!"
) else (
    set "HTML_FILE=!OUTPUT_FILE:.md=.html!"
    copy "!TEMP_HTML!" "!HTML_FILE!" >nul
    echo HTML file saved: !HTML_FILE!
)
if exist "!TEMP_MD!" del "!TEMP_MD!"

REM Show results
for %%F in ("!OUTPUT_FILE!") do set "FINAL_SIZE=%%~zF"
echo.
echo Conversion complete!
echo Output: !OUTPUT_FILE! (!FINAL_SIZE! bytes)

if exist "!MEDIA_DIR!" (
    for /f %%i in ('dir /b /s "!MEDIA_DIR!" 2^>nul ^| find /c /v ""') do set "MEDIA_COUNT=%%i"
    if !MEDIA_COUNT! GTR 0 (
        echo Media: !MEDIA_COUNT! files in !MEDIA_DIR!/
    )
)

echo.
echo Done!
goto :eof

:cleanup
if exist "!TEMP_HTML!" del "!TEMP_HTML!"
if exist "!TEMP_MD!" del "!TEMP_MD!"
exit /b 1
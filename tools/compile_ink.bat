@echo off
REM compile_ink.bat -- compile Ink sources in main/story into JSON.
REM Usage:
REM   tools\compile_ink.bat             -- compile active .ink files
REM   tools\compile_ink.bat chapter_01  -- compile only chapter_01.ink
REM
REM Notes:
REM - Run from the project root (where game.project lives).
REM - Files ending with _old.ink are treated as archive sources and are
REM   skipped during bulk compilation. They can still be compiled explicitly.

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "STORY_DIR=%PROJECT_ROOT%\main\story"
set "INKLECATE=%SCRIPT_DIR%inklecate.exe"

if not exist "%INKLECATE%" (
    echo [ERROR] inklecate.exe not found in %SCRIPT_DIR%
    exit /b 1
)

set OK=0
set FAIL=0

if "%~1"=="" (
    for %%F in ("%STORY_DIR%\*.ink") do (
        set "NAME=%%~nF"
        if /I not "!NAME:~-4!"=="_old" (
            call :compile "%%F"
        ) else (
            echo - skip archive %%~nxF
        )
    )
) else (
    call :compile "%STORY_DIR%\%~1.ink"
)

echo.
echo Done: !OK! OK, !FAIL! errors
exit /b !FAIL!

:compile
set "INK=%~1"
if not exist "%INK%" (
    echo [ERROR] File not found: %INK%
    set /a FAIL+=1
    goto :eof
)

set "NAME=%~n1"
set "JSON=%STORY_DIR%\%NAME%.json"
echo - %NAME%.ink
"%INKLECATE%" -o "%JSON%" "%INK%"
if errorlevel 1 (
    echo   [ERROR] compile failed
    set /a FAIL+=1
) else (
    echo   [OK] - %NAME%.json
    set /a OK+=1
)
goto :eof

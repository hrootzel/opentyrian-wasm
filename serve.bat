@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PORT=%~1"
set "DIR=%~2"

if "%PORT%"=="" set "PORT=8080"

if "%DIR%"=="" (
  call :ResolveServeDir
)

if not exist "%DIR%" (
  echo Directory not found: %DIR%
  exit /b 1
)

for %%I in ("%DIR%") do set "FULLDIR=%%~fI"
set "IS_BUILD=1"
if /I "%DIR%"=="." set "IS_BUILD=0"

echo OpenTyrian WASM
echo ==============
if "%IS_BUILD%"=="1" (
  echo Serving build output: %FULLDIR%
  echo Game:     http://localhost:%PORT%/opentyrian.html
) else (
  echo Dev mode ^(no build output found^)
  echo Note: Build first with .\build-wasm.ps1
)
echo.
echo Press Ctrl+C to stop

python -m http.server %PORT% -d "%FULLDIR%"
if errorlevel 1 (
  py -3 -m http.server %PORT% -d "%FULLDIR%"
)
exit /b %errorlevel%

:ResolveServeDir
set "DIR=."
for %%D in ("build\wasm\bin" "build\wasm") do (
  if exist "%%~D\opentyrian.html" (
    set "DIR=%%~D"
    goto :eof
  )
)
goto :eof

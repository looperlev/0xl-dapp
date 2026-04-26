@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "ROOT=%CD%"

where node >nul 2>&1
if errorlevel 1 (
  echo [run-dev] Node.js is not in PATH. Install LTS from https://nodejs.org/ then re-run.
  exit /b 1
)
where npm >nul 2>&1
if errorlevel 1 (
  echo [run-dev] npm not found. Reinstall Node.js ^(npm is included^).
  exit /b 1
)

rem --- project-local pnpm: no global install, no Corepack writes under Program Files ---
set "PP_ROOT=%ROOT%\local-pnpm"
set "PP_PKG=%PP_ROOT%\node_modules\pnpm\package.json"
if not exist "%PP_PKG%" (
  echo [run-dev] Preparing project-local pnpm in local-pnpm\ ^(one-time, uses npm in this folder^) ...
  if not exist "%PP_ROOT%" mkdir "%PP_ROOT%"
  pushd "%PP_ROOT%" || exit /b 1
  if not exist "package.json" (
    rem Folder must not start with "." or npm init -y can write an invalid "name" in package.json
    call npm init -y
  )
  rem Match packageManager in package.json for reproducible lock/patches
  call npm install pnpm@10.4.1 --no-fund --no-audit
  if errorlevel 1 (
    popd
    echo [run-dev] Could not install local pnpm. Check your network and try again.
    exit /b 1
  )
  popd
)

if exist "%PP_ROOT%\node_modules\pnpm\bin\pnpm.cjs" (
  set "PP_CMD=%PP_ROOT%\node_modules\pnpm\bin\pnpm.cjs"
) else if exist "%PP_ROOT%\node_modules\pnpm\dist\pnpm.cjs" (
  set "PP_CMD=%PP_ROOT%\node_modules\pnpm\dist\pnpm.cjs"
) else (
  echo [run-dev] Local pnpm package looks broken. Delete folder "%PP_ROOT%" and re-run.
  exit /b 1
)

if not exist "node_modules\" (
  echo [run-dev] Installing app dependencies ^(pnpm install^) ...
  call node "%PP_CMD%" install
  if errorlevel 1 exit /b 1
)

if not exist ".env" if exist ".env.example" (
  echo [run-dev] No .env file. Copy .env.example to .env and set values, or some features will fail.
  echo.
)

echo [run-dev] Starting dev server ^(Ctrl+C to stop^) ...
echo.
set "DAPP_PORT=3000"
if exist ".env" for /f "usebackq tokens=1* delims==" %%A in (".env") do (
  if /I "%%A"=="PORT" set "DAPP_PORT=%%B"
)
set "DAPP_PORT=%DAPP_PORT: =%"
echo  In your browser, open:  http://localhost:%DAPP_PORT%/
echo  run-dev only starts Node — it will not open a window by itself.
echo.
call node "%PP_CMD%" dev
set "EXIT=%ERRORLEVEL%"
if not "%EXIT%"=="0" echo.
if not "%EXIT%"=="0" echo [run-dev] Exited with error %EXIT%.
pause
exit /b %EXIT%

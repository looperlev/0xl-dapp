@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "DB_URL=mysql://oxlev:oxlev_dev_password@127.0.0.1:3306/oxlev"

where docker >nul 2>&1
if errorlevel 1 (
  echo [setup-mysql] Docker not found. Install Docker Desktop, start it, then re-run.
  echo              https://www.docker.com/products/docker-desktop/
  exit /b 1
)

echo [setup-mysql] Starting MySQL 8 in Docker (port 3306) ...
call docker compose up -d --wait
if not errorlevel 1 goto :dbup

rem Older Compose: no --wait
call docker compose up -d
if errorlevel 1 exit /b 1
echo [setup-mysql] Waiting for MySQL ^(up to 60s^) ...
set /a N=0
:waitloop
docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -prootdevonly 1>nul 2>&1
if not errorlevel 1 goto :dbup
set /a N+=1
if !N! geq 30 (
  echo [setup-mysql] MySQL did not become ready. See: docker compose logs mysql
  exit /b 1
)
timeout /t 2 /nobreak >nul
goto :waitloop

:dbup
if not exist "node_modules\drizzle-kit\bin.cjs" if not exist "node_modules\.bin\drizzle-kit.cmd" (
  echo [setup-mysql] Install dependencies first: run-dev.bat  OR  pnpm install
  echo [setup-mysql] Then run: set DATABASE_URL=%DB_URL% ^&^& pnpm db:migrate
  exit /b 1
)

set "DATABASE_URL=%DB_URL%"
echo [setup-mysql] Applying Drizzle migrations ...
if exist "node_modules\drizzle-kit\bin.cjs" (
  call node "node_modules\drizzle-kit\bin.cjs" migrate
) else (
  call "node_modules\.bin\drizzle-kit.cmd" migrate
)
if errorlevel 1 (
  echo [setup-mysql] migrate failed. Check MySQL: docker compose ps
  exit /b 1
)

echo.
if not exist ".env" if exist ".env.example" copy /y .env.example .env 1>nul
if exist ".env" (
  findstr "oxlev_dev_password" .env 1>nul 2>&1
  if not errorlevel 1 (
    echo [setup-mysql] .env already has the local Docker MySQL connection string
  ) else (
    findstr "DATABASE_URL=" .env 1>nul 2>&1
    if not errorlevel 1 (
      echo [setup-mysql] Edit your existing DATABASE_URL in .env to:
      echo   %DB_URL%
    ) else (
      echo.>>.env
      echo # Local MySQL (Docker) — from setup-mysql.bat>>.env
      echo DATABASE_URL=%DB_URL%>>.env
      echo [setup-mysql] Appended DATABASE_URL to .env
    )
  )
) else (
  echo [setup-mysql] No .env — create one from .env.example and set:
  echo   DATABASE_URL=%DB_URL%
)

echo.
echo [setup-mysql] Done. MySQL: oxlev / table users ready. Start app: run-dev.bat
exit /b 0

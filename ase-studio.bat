@echo off
rem The ase-studio command on Windows. install.ps1 puts this file on the PATH.
setlocal

if not defined ASE_STUDIO_IMAGE set "ASE_STUDIO_IMAGE=ghcr.io/mohammad-mallaee/ase-studio-docker:latest"
if not defined ASE_STUDIO_DATA set "ASE_STUDIO_DATA=%USERPROFILE%\ASE-Projects"
set "ASE_STUDIO_URL=http://127.0.0.1:8765"
set "ASE_STUDIO_CONTAINER=ase-studio"
set "ASE_STUDIO_INSTALL_DIR=%LOCALAPPDATA%\Programs\ase-studio\"

if "%~1"=="" goto start
if /i "%~1"=="start" goto start
if /i "%~1"=="stop" goto stop
if /i "%~1"=="update" goto update
if /i "%~1"=="uninstall" goto uninstall
if /i "%~1"=="help" goto help
echo Unknown command: %~1
echo.
call :show_help
exit /b 2

:help
call :show_help
exit /b 0

:start
call :require_docker
if errorlevel 1 exit /b 1

rem Closing the terminal can leave the container running, so reuse it if it is there.
docker container inspect %ASE_STUDIO_CONTAINER% >nul 2>&1
if not errorlevel 1 (
  echo ASE Studio is already running. Opening it in your browser.
  start "" "%ASE_STUDIO_URL%"
  exit /b 0
)

if not exist "%ASE_STUDIO_DATA%" mkdir "%ASE_STUDIO_DATA%"

rem Tell the student about a newer release without downloading it. Any failure, such
rem as being offline or running a local image, just skips the notice.
powershell -NoProfile -Command "try { $i = $env:ASE_STUDIO_IMAGE; if ($i -notmatch '^ghcr\.io/(.+):([^:]+)$') { exit }; $r = $Matches[1]; $t = $Matches[2]; $l = docker image inspect $i --format '{{json .RepoDigests}}' 2>$null; if (-not $l) { exit }; [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; $k = (Invoke-RestMethod -TimeoutSec 3 ('https://ghcr.io/token?scope=repository:' + $r + ':pull')).token; $h = @{ Authorization = 'Bearer ' + $k; Accept = 'application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json' }; $d = [string](Invoke-WebRequest -UseBasicParsing -Method Head -TimeoutSec 3 -Headers $h ('https://ghcr.io/v2/' + $r + '/manifests/' + $t)).Headers['Docker-Content-Digest']; if ($d -and -not ([string]$l).Contains($d)) { Write-Host ''; Write-Host 'A new version of ASE Studio is available. You can keep using this one.'; Write-Host 'To get it, stop ASE Studio and run: ase-studio update'; Write-Host '' } } catch { }"

rem Open the browser once the server answers, while docker run holds this window.
start "" /b powershell -NoProfile -Command "for ($i = 0; $i -lt 60; $i++) { try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 '%ASE_STUDIO_URL%' | Out-Null; Start-Process '%ASE_STUDIO_URL%'; break } catch { Start-Sleep -Seconds 1 } }"

echo Your projects are saved in %ASE_STUDIO_DATA%. Press Ctrl+C to stop ASE Studio.
docker run --rm --init --name %ASE_STUDIO_CONTAINER% -p 127.0.0.1:8765:8765 -v "%ASE_STUDIO_DATA%:/data" "%ASE_STUDIO_IMAGE%"
exit /b %errorlevel%

:stop
call :require_docker
if errorlevel 1 exit /b 1
docker container inspect %ASE_STUDIO_CONTAINER% >nul 2>&1
if errorlevel 1 (
  echo ASE Studio isn't running.
  exit /b 0
)
docker stop %ASE_STUDIO_CONTAINER% >nul
echo ASE Studio has stopped.
exit /b 0

:update
call :require_docker
if errorlevel 1 exit /b 1
docker pull "%ASE_STUDIO_IMAGE%"
if errorlevel 1 exit /b 1
docker container inspect %ASE_STUDIO_CONTAINER% >nul 2>&1
if errorlevel 1 (
  echo ASE Studio is up to date.
) else (
  echo Download complete. To use it, run: ase-studio stop, then: ase-studio
)
exit /b 0

:uninstall
docker info >nul 2>&1
if errorlevel 1 (
  echo Docker isn't running, so the ASE Studio image was left in place.
) else (
  docker rm -f %ASE_STUDIO_CONTAINER% >nul 2>&1
  docker rmi "%ASE_STUDIO_IMAGE%" >nul 2>&1
)
if /i not "%~dp0"=="%ASE_STUDIO_INSTALL_DIR%" (
  echo This copy of the command wasn't installed by install.ps1, so it was left in place.
  exit /b 0
)
powershell -NoProfile -Command "$d = $env:ASE_STUDIO_INSTALL_DIR.TrimEnd('\'); $p = (Get-Item HKCU:\Environment).GetValue('Path', '', 'DoNotExpandEnvironmentNames'); [Environment]::SetEnvironmentVariable('Path', (($p -split ';' | Where-Object { $_ -and $_ -ne $d }) -join ';'), 'User')"
echo ASE Studio has been uninstalled. Your projects are still in %ASE_STUDIO_DATA%.
rem A running batch file can only delete itself as the very last thing it does.
(goto) 2>nul & del "%~f0" & rmdir "%~dp0"

:require_docker
docker info >nul 2>&1
if errorlevel 1 (
  echo Docker isn't running. Start Docker Desktop, wait until it is ready, then try again.
  exit /b 1
)
exit /b 0

:show_help
echo Usage: ase-studio [command]
echo.
echo   start      Start ASE Studio and open it in your browser, the default
echo   stop       Stop ASE Studio
echo   update     Download the newest tested version
echo   uninstall  Remove ASE Studio but keep your projects
echo   help       Show this message
exit /b 0

@echo off
rem Double-click on Windows: starts the container and opens ASE Studio in a browser.
setlocal

if not defined ASE_STUDIO_IMAGE set "ASE_STUDIO_IMAGE=ghcr.io/mohammad-mallaee/ase-studio-docker:latest"
if not defined ASE_STUDIO_DATA set "ASE_STUDIO_DATA=%USERPROFILE%\ASE-Studio"
set "ASE_STUDIO_URL=http://127.0.0.1:8765"

docker info >nul 2>&1
if errorlevel 1 (
  echo Docker isn't running. Start Docker Desktop, wait until it is ready, then try again.
  pause
  exit /b 1
)

rem Closing this window can leave the container running, so reuse it if it is there.
docker container inspect ase-studio >nul 2>&1
if not errorlevel 1 (
  echo ASE Studio is already running. Opening it in your browser.
  start "" "%ASE_STUDIO_URL%"
  pause
  exit /b 0
)

if not exist "%ASE_STUDIO_DATA%" mkdir "%ASE_STUDIO_DATA%"

rem Tell the student about a newer release without downloading it. Any failure, such
rem as being offline or running a local image, just skips the notice.
powershell -NoProfile -Command "try { $i = $env:ASE_STUDIO_IMAGE; if ($i -notmatch '^ghcr\.io/(.+):([^:]+)$') { exit }; $r = $Matches[1]; $t = $Matches[2]; $l = docker image inspect $i --format '{{json .RepoDigests}}' 2>$null; if (-not $l) { exit }; [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; $k = (Invoke-RestMethod -TimeoutSec 3 ('https://ghcr.io/token?scope=repository:' + $r + ':pull')).token; $h = @{ Authorization = 'Bearer ' + $k; Accept = 'application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json' }; $d = [string](Invoke-WebRequest -UseBasicParsing -Method Head -TimeoutSec 3 -Headers $h ('https://ghcr.io/v2/' + $r + '/manifests/' + $t)).Headers['Docker-Content-Digest']; if ($d -and -not ([string]$l).Contains($d)) { Write-Host ''; Write-Host 'A new version of ASE Studio is available. You can keep using this one.'; Write-Host 'To update, stop ASE Studio, run this command, and start it again:'; Write-Host ('  docker pull ' + $i); Write-Host '' } } catch { }"

rem Open the browser once the server answers, while docker run holds this window.
start "" /b powershell -NoProfile -Command "for ($i = 0; $i -lt 60; $i++) { try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 '%ASE_STUDIO_URL%' | Out-Null; Start-Process '%ASE_STUDIO_URL%'; break } catch { Start-Sleep -Seconds 1 } }"

echo Your projects are saved in %ASE_STUDIO_DATA%. Press Ctrl+C to stop ASE Studio.
docker run --rm --init --name ase-studio -p 127.0.0.1:8765:8765 -v "%ASE_STUDIO_DATA%:/data" "%ASE_STUDIO_IMAGE%"

pause

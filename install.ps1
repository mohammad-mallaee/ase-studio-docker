# Installs the ase-studio command on Windows, without needing admin rights.
# Running it again replaces the command with the newest version.
# Meant to run through "irm ... | iex", so it must not call exit: that would close
# the student's terminal.
$ErrorActionPreference = 'Stop'

$launcherUrl = if ($env:ASE_STUDIO_LAUNCHER_URL) { $env:ASE_STUDIO_LAUNCHER_URL } else {
  'https://raw.githubusercontent.com/mohammad-mallaee/ase-studio-docker/main/ase-studio.bat'
}
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\ase-studio'
$target = Join-Path $installDir 'ase-studio.bat'

New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Older PowerShell versions may not use TLS 1.2 by themselves, which GitHub requires.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download next to the target first, so a failed download can't break an earlier install.
$download = "$target.download"
Invoke-WebRequest -UseBasicParsing -Uri $launcherUrl -OutFile $download
Move-Item -Force -Path $download -Destination $target

# Read the raw value from the registry so entries like %USERPROFILE% stay unexpanded.
$userPath = (Get-Item 'HKCU:\Environment').GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$entries = @($userPath -split ';' | Where-Object { $_ })
if ($entries -notcontains $installDir) {
  [Environment]::SetEnvironmentVariable('Path', (($entries + $installDir) -join ';'), 'User')
}

# Make the command work in this terminal too, without opening a new one.
if (($env:Path -split ';') -notcontains $installDir) {
  $env:Path = "$env:Path;$installDir"
}

Write-Host 'ASE Studio is installed.'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Host 'You also need Docker: https://www.docker.com/products/docker-desktop/'
}
Write-Host 'To start it, run: ase-studio'

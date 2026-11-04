#!/usr/bin/env bash
# Runs on your own machine: starts the container and opens ASE Studio in a browser.
set -euo pipefail

image="${ASE_STUDIO_IMAGE:-ghcr.io/mohammad-mallaee/ase-studio-docker:latest}"
data_dir="${ASE_STUDIO_DATA:-$HOME/ASE-Studio}"
url="http://127.0.0.1:8765"

if ! docker info >/dev/null 2>&1; then
  echo "Docker isn't running. Start Docker Desktop or OrbStack, then try again." >&2
  exit 1
fi

mkdir -p "$data_dir"

# docker run alone would keep using the copy already downloaded, so get updates
# here. Stay usable offline, or with an image that only exists locally.
if ! docker pull "$image"; then
  echo "Couldn't check for updates, so using the copy already on this machine." >&2
fi

# Open the browser once the server answers, while docker run holds the terminal.
(
  for _ in $(seq 1 60); do
    if curl -fs -o /dev/null "$url"; then
      if command -v open >/dev/null 2>&1; then open "$url"; else xdg-open "$url" || true; fi
      exit 0
    fi
    sleep 1
  done
) &

echo "Your projects are saved in $data_dir. Press Ctrl+C to stop ASE Studio."
docker run --rm --init --name ase-studio \
  -p 127.0.0.1:8765:8765 \
  -v "$data_dir:/data" \
  "$image"

#!/usr/bin/env bash
# Runs inside the container: keeps student files in /data and starts the backend.
set -euo pipefail

mkdir -p /data/projects /data/submissions

# Settings live next to the projects so they survive the container being removed.
if [[ ! -e /data/settings.json ]]; then
  printf '{\n  "PROGRAMS_DIRECTORY": "/data/projects",\n  "SUBMISSION_DIRECTORY": "/data/submissions"\n}\n' \
    > /data/settings.json
fi
ln -sf /data/settings.json .ase-studio-env.json

# backend.py only listens on 127.0.0.1, which a published Docker port can't reach.
# socat bridges the gap without patching ASE Studio. The backend has no login, so
# the run script publishes this port on the host's loopback address only.
socat TCP-LISTEN:8765,fork,reuseaddr TCP:127.0.0.1:8766 &

echo "ASE Studio is starting. Open http://127.0.0.1:8765 in your browser."
exec python3 ase_studio/backend.py 8766

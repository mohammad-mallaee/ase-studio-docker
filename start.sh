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
# socat bridges the gap from the container's own address, so both can use the same
# port. It starts once the backend answers, so nothing connects to it too early. The
# backend has no login, so the run script publishes this port on the host's loopback
# address only.
port=8765
container_address="$(hostname -i | awk '{ print $1 }')"
(
  until (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; do
    sleep 0.2
  done
  exec socat "TCP-LISTEN:$port,bind=$container_address,fork,reuseaddr" "TCP:127.0.0.1:$port"
) &

echo "ASE Studio is starting."
exec python3 ase_studio/backend.py "$port"

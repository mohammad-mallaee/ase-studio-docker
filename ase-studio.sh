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

# Tell the student about a newer release without downloading it. Any failure, such
# as being offline or running a local image, just skips the notice.
check_for_new_version() {
  local reference repo tag installed token published
  case "$image" in
    ghcr.io/*:*) ;;
    *) return 0 ;;
  esac
  reference="${image#ghcr.io/}"
  repo="${reference%:*}"
  tag="${reference##*:}"
  installed="$(docker image inspect "$image" --format '{{json .RepoDigests}}' 2>/dev/null)" || return 0
  token="$(curl -fsS --max-time 3 "https://ghcr.io/token?scope=repository:$repo:pull" 2>/dev/null \
    | sed -E 's/.*"token":"([^"]+)".*/\1/')" || return 0
  published="$(curl -fsSI --max-time 3 -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://ghcr.io/v2/$repo/manifests/$tag" 2>/dev/null \
    | tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2 }')" || return 0
  if [[ -n "$published" && "$installed" != *"$published"* ]]; then
    echo
    echo "A new version of ASE Studio is available. You can keep using this one."
    echo "To update, stop ASE Studio, run this command, and start it again:"
    echo "  docker pull $image"
    echo
  fi
}
check_for_new_version || true

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

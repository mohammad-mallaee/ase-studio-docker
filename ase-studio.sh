#!/usr/bin/env bash
# The ase-studio command on Mac and Linux. install.sh puts this file on the PATH.
set -euo pipefail

image="${ASE_STUDIO_IMAGE:-ghcr.io/mohammad-mallaee/ase-studio-docker:latest}"
data_dir="${ASE_STUDIO_DATA:-$HOME/ASE-Studio}"
url="http://127.0.0.1:8765"
container="ase-studio"
installed_command="$HOME/.local/bin/ase-studio"

show_help() {
  echo "Usage: ase-studio [command]"
  echo
  echo "  start      Start ASE Studio and open it in your browser (the default)"
  echo "  stop       Stop ASE Studio"
  echo "  update     Download the newest tested version"
  echo "  uninstall  Remove ASE Studio but keep your projects"
  echo "  help       Show this message"
}

require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker isn't running. Start Docker Desktop or OrbStack, then try again." >&2
    exit 1
  fi
}

is_running() {
  docker container inspect "$container" >/dev/null 2>&1
}

open_browser() {
  if command -v open >/dev/null 2>&1; then open "$url"; else xdg-open "$url" || true; fi
}

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
    echo "To get it, stop ASE Studio and run: ase-studio update"
    echo
  fi
}

start_studio() {
  require_docker

  # Closing the terminal can leave the container running, so reuse it if it is there.
  if is_running; then
    echo "ASE Studio is already running. Opening it in your browser."
    open_browser
    return 0
  fi

  mkdir -p "$data_dir"
  check_for_new_version || true

  # Open the browser once the server answers, while docker run holds the terminal.
  (
    for _ in $(seq 1 60); do
      if curl -fs -o /dev/null "$url"; then
        open_browser
        exit 0
      fi
      sleep 1
    done
  ) &

  echo "Your projects are saved in $data_dir. Press Ctrl+C to stop ASE Studio."
  docker run --rm --init --name "$container" \
    -p 127.0.0.1:8765:8765 \
    -v "$data_dir:/data" \
    "$image"
}

stop_studio() {
  require_docker
  if is_running; then
    docker stop "$container" >/dev/null
    echo "ASE Studio has stopped."
  else
    echo "ASE Studio isn't running."
  fi
}

update_studio() {
  require_docker
  docker pull "$image"
  if is_running; then
    echo "Download complete. To use it, run: ase-studio stop, then: ase-studio"
  else
    echo "ASE Studio is up to date."
  fi
}

uninstall_studio() {
  if docker info >/dev/null 2>&1; then
    docker rm -f "$container" >/dev/null 2>&1 || true
    docker rmi "$image" >/dev/null 2>&1 || true
  else
    echo "Docker isn't running, so the ASE Studio image was left in place."
  fi
  rm -f "$installed_command"
  echo "ASE Studio has been uninstalled. Your projects are still in $data_dir."
}

case "${1:-start}" in
  start) start_studio ;;
  stop) stop_studio ;;
  update) update_studio ;;
  uninstall) uninstall_studio ;;
  help | -h | --help) show_help ;;
  *)
    echo "Unknown command: $1" >&2
    echo >&2
    show_help >&2
    exit 2
    ;;
esac

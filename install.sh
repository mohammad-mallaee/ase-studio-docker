#!/usr/bin/env bash
# Installs the ase-studio command on Mac and Linux, without needing admin rights.
# Running it again replaces the command with the newest version.
set -euo pipefail

launcher_url="${ASE_STUDIO_LAUNCHER_URL:-https://raw.githubusercontent.com/mohammad-mallaee/ase-studio-docker/main/ase-studio.sh}"
bin_dir="$HOME/.local/bin"
target="$bin_dir/ase-studio"

already_installed=false
if [[ -e "$target" ]]; then
  already_installed=true
fi

mkdir -p "$bin_dir"

# Download next to the target first, so a failed download can't break an earlier install.
download="$(mktemp "$bin_dir/.ase-studio.XXXXXX")"
trap 'rm -f "$download"' EXIT
curl -fsSL -o "$download" "$launcher_url"
chmod +x "$download"
mv -f "$download" "$target"
trap - EXIT

shell_config() {
  case "$(basename "${SHELL:-}")" in
    zsh) echo "$HOME/.zshrc" ;;
    bash)
      if [[ "$(uname -s)" == "Darwin" ]]; then echo "$HOME/.bash_profile"; else echo "$HOME/.bashrc"; fi
      ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

needs_new_terminal=false
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *)
    config="$(shell_config)"
    if [[ "$config" == */config.fish ]]; then
      path_line='fish_add_path $HOME/.local/bin'
      mkdir -p "$(dirname "$config")"
    else
      path_line='export PATH="$HOME/.local/bin:$PATH"'
    fi
    if ! grep -qsF "$path_line" "$config"; then
      printf '\n# Added by the ASE Studio installer\n%s\n' "$path_line" >> "$config"
    fi
    needs_new_terminal=true
    ;;
esac

if [[ "$already_installed" == true ]]; then
  echo "ASE Studio is already installed."
  exit 0
fi

echo "ASE Studio is installed."
if ! command -v docker >/dev/null 2>&1; then
  echo "You also need Docker: https://www.docker.com/products/docker-desktop/"
fi
if [[ "$needs_new_terminal" == true ]]; then
  echo "Open a new terminal, then run: ase-studio"
else
  echo "To start it, run: ase-studio"
fi

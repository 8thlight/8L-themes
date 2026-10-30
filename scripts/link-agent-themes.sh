#!/usr/bin/env bash
# Link presets without changing the user's active theme or other settings.
set -euo pipefail

repository="$(cd "$(dirname "$0")/.." && pwd)"
action="${1:?Expected link or unlink}"
application="${2:?Expected claude, claude-powerline, or codex-cli}"

case "$application" in
  claude)
    target_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/themes"
    extension=json
    ;;
  claude-powerline)
    target_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/powerline/themes"
    extension=json
    ;;
  codex-cli)
    target_dir="${CODEX_HOME:-$HOME/.codex}/themes"
    extension=tmTheme
    ;;
  *) echo "Unknown application: $application" >&2; exit 1 ;;
esac

case "$action" in
  link)
    # Preflight the entire set before creating any links.
    for source in "$repository/extras/$application/"*."$extension"; do
      target="$target_dir/$(basename "$source")"
      if [[ -e "$target" && ! -L "$target" ]]; then
        echo "Refusing to replace non-symlink: $target" >&2
        exit 1
      fi
      if [[ -L "$target" && -d "$target" ]]; then
        echo "Refusing to replace directory symlink: $target" >&2
        exit 1
      fi
    done
    mkdir -p "$target_dir"
    for source in "$repository/extras/$application/"*."$extension"; do
      target="$target_dir/$(basename "$source")"
      ln -sfn "$source" "$target"
      echo "Linked $target -> $source"
    done
    ;;
  unlink)
    for source in "$repository/extras/$application/"*."$extension"; do
      target="$target_dir/$(basename "$source")"
      if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        rm "$target"
        echo "Removed $target"
      fi
    done
    ;;
  *) echo "Unknown action: $action" >&2; exit 1 ;;
esac

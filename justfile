default:
    @just --list

# Symlink all available application themes.
link: link-kitty link-nvim link-jetbrains link-claude link-claude-powerline link-codex-cli

# Install Claude Code interface themes. Select one with /theme.
link-claude:
    bash scripts/link-agent-themes.sh link claude

# Install Powerline presets. Use --config to select one in Claude's statusLine command.
link-claude-powerline:
    bash scripts/link-agent-themes.sh link claude-powerline

# Install Codex CLI syntax themes. Select one with /theme.
link-codex-cli:
    bash scripts/link-agent-themes.sh link codex-cli

# Print a Codex app theme for Settings > Appearance > Import (pipe to pbcopy on macOS).
codex-app-theme variant="Charcoal":
    #!/usr/bin/env bash
    set -euo pipefail
    variant={{quote(variant)}}
    case "$variant" in
      Black|Charcoal|Dark-Gray|Mid-Gray|Light-Gray|Lighter-Gray|Lightest-Gray|White) ;;
      *) echo "Unknown 8th Light variant: $variant" >&2; exit 1 ;;
    esac
    cat "extras/codex-app/8th-Light-$variant.codex-theme"

# Regenerate all agent themes from the Neovim palette and variants.
generate-agent-themes:
    python3 scripts/generate-agent-themes.py

# Symlink every Kitty theme into Kitty's user themes directory.
link-kitty:
    #!/usr/bin/env bash
    set -euo pipefail

    target_dir="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/themes"
    mkdir -p "$target_dir"

    for theme in extras/kitty/*.conf; do
      target="$target_dir/$(basename "$theme")"

      if [[ -e "$target" && ! -L "$target" ]]; then
        echo "Refusing to replace non-symlink: $target" >&2
        exit 1
      fi

      ln -sfn "$PWD/$theme" "$target"
      echo "Linked $target -> $PWD/$theme"
    done

# Install the Neovim themes as a native runtime package.
link-nvim:
    #!/usr/bin/env bash
    set -euo pipefail

    source="$PWD"
    target_dir="${NVIM_DATA_DIRECTORY:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim}/site/pack/8th-light/start"
    target="$target_dir/8th-light.nvim"
    mkdir -p "$target_dir"

    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "Refusing to replace non-symlink: $target" >&2
      exit 1
    fi

    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"

# Build the resource-only JetBrains theme plugin. Set PLUGIN_VERSION to stamp a version and name the JAR after it.
_build-jetbrains:
    #!/usr/bin/env bash
    set -euo pipefail

    version="${PLUGIN_VERSION:-}"
    if [[ -n "$version" && ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "PLUGIN_VERSION must look like 1.2.3, got: $version" >&2
      exit 1
    fi

    output_dir="$PWD/build/jetbrains"
    jar_path="$output_dir/8th-light-themes${version:+-$version}.jar"
    temporary_jar="$jar_path.tmp"
    stage="$(mktemp -d)"

    mkdir -p "$output_dir"
    rm -f "$temporary_jar"
    trap 'rm -f "$temporary_jar"; rm -rf "$stage"' EXIT

    cp -R extras/jetbrains/. "$stage"
    if [[ -n "$version" ]]; then
      awk -v version="$version" '{ print } /<name>/ { print "  <version>" version "</version>" }' \
        extras/jetbrains/META-INF/plugin.xml > "$stage/META-INF/plugin.xml"
    fi

    (
      cd "$stage"
      zip -q -r "$temporary_jar" META-INF images schemes themes
    )

    mv "$temporary_jar" "$jar_path"
    echo "Built $jar_path"

# Build and install the theme plugin into all detected JetBrains configurations.
link-jetbrains: _build-jetbrains
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob

    source="$PWD/build/jetbrains/8th-light-themes.jar"
    configs=()
    if [[ -n "${JETBRAINS_CONFIG_DIRECTORY:-}" ]]; then
      configs+=("$JETBRAINS_CONFIG_DIRECTORY")
    else
      roots=(
        "$HOME/Library/Application Support/JetBrains"
        "${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains"
      )

      for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue
        for config in "$root"/*; do
          [[ -d "$config/options" ]] || continue
          configs+=("$config")
        done
      done
    fi

    if (( ${#configs[@]} == 0 )); then
      echo "No JetBrains IDE configuration directories found." >&2
      exit 1
    fi

    for config in "${configs[@]}"; do
      target_dir="$config/plugins/8th-light-themes/lib"
      target="$target_dir/8th-light-themes.jar"
      mkdir -p "$target_dir"

      if [[ -e "$target" && ! -L "$target" ]]; then
        echo "Refusing to replace non-symlink: $target" >&2
        exit 1
      fi

      ln -sfn "$source" "$target"
      echo "Linked $target -> $source"
    done

# Remove all of this repository's application theme symlinks.
unlink: unlink-kitty unlink-nvim unlink-jetbrains unlink-claude unlink-claude-powerline unlink-codex-cli

# Remove only this checkout's Claude theme links.
unlink-claude:
    bash scripts/link-agent-themes.sh unlink claude

# Remove only this checkout's Claude Powerline preset links.
unlink-claude-powerline:
    bash scripts/link-agent-themes.sh unlink claude-powerline

# Remove only this checkout's Codex CLI theme links.
unlink-codex-cli:
    bash scripts/link-agent-themes.sh unlink codex-cli

# Remove this repository's theme symlinks from Kitty's user themes directory.
unlink-kitty:
    #!/usr/bin/env bash
    set -euo pipefail

    target_dir="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/themes"

    for target in "$target_dir"/*.conf; do
      [[ -L "$target" ]] || continue

      source="$(readlink "$target")"
      if [[ "$source" == "$PWD/extras/kitty/"* ]]; then
        rm "$target"
        echo "Removed $target"
      fi
    done

# Remove this repository's Neovim runtime package symlink.
unlink-nvim:
    #!/usr/bin/env bash
    set -euo pipefail

    source="$PWD"
    target="${NVIM_DATA_DIRECTORY:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim}/site/pack/8th-light/start/8th-light.nvim"

    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
      rm "$target"
      echo "Removed $target"
    fi

# Remove this repository's theme plugin from all detected JetBrains configurations.
unlink-jetbrains:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob

    configs=()
    if [[ -n "${JETBRAINS_CONFIG_DIRECTORY:-}" ]]; then
      configs+=("$JETBRAINS_CONFIG_DIRECTORY")
    else
      roots=(
        "$HOME/Library/Application Support/JetBrains"
        "${XDG_CONFIG_HOME:-$HOME/.config}/JetBrains"
      )

      for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue
        for config in "$root"/*; do
          [[ -d "$config/options" ]] || continue
          configs+=("$config")
        done
      done
    fi

    for config in "${configs[@]}"; do
      source="$PWD/build/jetbrains/8th-light-themes.jar"
      plugin_dir="$config/plugins/8th-light-themes"
      target="$plugin_dir/lib/8th-light-themes.jar"

      if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        rm "$target"
        rmdir "$plugin_dir/lib" "$plugin_dir" 2>/dev/null || true
        echo "Removed $target"
      fi
    done

# Validate theme files: syntax, variant coverage, references, and palette values.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob

    failures=0
    fail() {
      echo "FAIL: $*" >&2
      failures=$((failures + 1))
    }

    variants=(Black Charcoal Dark-Gray Mid-Gray Light-Gray Lighter-Gray Lightest-Gray White)

    echo "Checking XML syntax"
    xmllint --noout --nonet extras/jetbrains/META-INF/plugin.xml extras/jetbrains/META-INF/pluginIcon.svg extras/jetbrains/schemes/*.xml extras/codex-cli/*.tmTheme docs/*.svg || fail "XML is not well-formed"

    echo "Checking JSON syntax"
    for file in extras/jetbrains/themes/*.json extras/claude/*.json extras/claude-powerline/*.json extras/codex-app/*.json; do
      jq empty "$file" || fail "$file is not valid JSON"
    done

    echo "Checking Lua syntax"
    luac -p colors/*.lua lua/eighth_light/init.lua || fail "Lua does not parse"

    echo "Checking variant coverage"
    for variant in "${variants[@]}"; do
      lower="$(tr '[:upper:]' '[:lower:]' <<<"$variant")"
      for file in \
        "extras/kitty/8th-Light-$variant.conf" \
        "colors/8th-Light-$variant.lua" \
        "extras/jetbrains/schemes/8th-Light-$variant.xml" \
        "extras/jetbrains/themes/8th-Light-$variant.theme.json" \
        "extras/claude/8th-Light-$variant.json" \
        "extras/claude-powerline/8th-Light-$variant.json" \
        "extras/codex-cli/8th-Light-$variant.tmTheme" \
        "extras/codex-app/8th-Light-$variant.json" \
        "extras/codex-app/8th-Light-$variant.codex-theme" \
        "screenshots/kitty/8th-light-$lower.png" \
        "screenshots/nvim/8th-light-$lower.png" \
        "screenshots/jetbrains/8th-light-$lower.png"; do
        [[ -f "$file" ]] || fail "missing $file"
      done
      grep -q "schemes/8th-Light-$variant\"" extras/jetbrains/META-INF/plugin.xml || fail "plugin.xml does not register scheme $variant"
      grep -q "themes/8th-Light-$variant.theme.json\"" extras/jetbrains/META-INF/plugin.xml || fail "plugin.xml does not register theme $variant"
    done

    echo "Checking JetBrains references"
    for file in extras/jetbrains/themes/*.json; do
      scheme="$(jq -r '.editorScheme' "$file")"
      [[ -f "extras/jetbrains$scheme" ]] || fail "$file points at missing scheme $scheme"
      image="$(jq -r '.emptyFrameBackground.image // empty' "$file")"
      [[ -z "$image" || -f "extras/jetbrains/$image" ]] || fail "$file points at missing image $image"
    done

    echo "Checking the JetBrains plugin icon"
    grep -q '<svg[^>]*width="40"[^>]*height="40"' extras/jetbrains/META-INF/pluginIcon.svg || fail "pluginIcon.svg must be 40x40"

    echo "Checking Kitty keys match across variants"
    kitty_keys() {
      grep -vE '^[[:space:]]*(#|$)' "$1" | awk '{print $1}' | sort
    }
    reference="$(kitty_keys extras/kitty/8th-Light-Black.conf)"
    for file in extras/kitty/*.conf; do
      [[ "$(kitty_keys "$file")" == "$reference" ]] || fail "$file defines different keys than 8th-Light-Black.conf"
    done

    echo "Checking README palette against the Neovim palette"
    readme_hexes="$(grep -oE '^\| .* \| `#[0-9A-Fa-f]{6}` \|' README.md | grep -oE '#[0-9A-Fa-f]{6}' | tr '[:lower:]' '[:upper:]' | sort -u)"
    lua_hexes="$(sed -n '/^local palette = {/,/^}/p' lua/eighth_light/init.lua | grep -oE '#[0-9A-Fa-f]{6}' | tr '[:lower:]' '[:upper:]' | sort -u)"
    [[ "$readme_hexes" == "$lua_hexes" ]] || fail "README palette and Neovim palette differ: $(diff <(echo "$readme_hexes") <(echo "$lua_hexes") | tr '\n' ' ')"

    echo "Checking agent theme generation, formats, contrast, and install helpers"
    python3 scripts/generate-agent-themes.py --check || fail "agent themes are stale"
    python3 scripts/check-agent-themes.py || fail "agent theme validation failed"

    if (( failures > 0 )); then
      echo "$failures check(s) failed." >&2
      exit 1
    fi
    echo "All checks passed."

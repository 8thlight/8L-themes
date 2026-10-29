# 8th Light themes

Application themes built from the 8th Light brand color palette and the colors used on the 8thlight.com website. Hex values are cross-checked against their RGB values.

![Palette](docs/palette.svg)

## Screenshots

Screenshots were taken with Cousine Nerd Font Mono. The themes do not set a font.

<details>
<summary><strong>JetBrains IDEs</strong></summary>

|  |  |  |  |
| --- | --- | --- | --- |
| <a href="screenshots/jetbrains/8th-light-black.png"><img src="screenshots/jetbrains/8th-light-black.png" alt="8th Light Black in RustRover" width="200"></a><br>Black | <a href="screenshots/jetbrains/8th-light-charcoal.png"><img src="screenshots/jetbrains/8th-light-charcoal.png" alt="8th Light Charcoal in RustRover" width="200"></a><br>Charcoal | <a href="screenshots/jetbrains/8th-light-dark-gray.png"><img src="screenshots/jetbrains/8th-light-dark-gray.png" alt="8th Light Dark Gray in RustRover" width="200"></a><br>Dark Gray | <a href="screenshots/jetbrains/8th-light-mid-gray.png"><img src="screenshots/jetbrains/8th-light-mid-gray.png" alt="8th Light Mid Gray in RustRover" width="200"></a><br>Mid Gray |
| <a href="screenshots/jetbrains/8th-light-light-gray.png"><img src="screenshots/jetbrains/8th-light-light-gray.png" alt="8th Light Light Gray in RustRover" width="200"></a><br>Light Gray | <a href="screenshots/jetbrains/8th-light-lighter-gray.png"><img src="screenshots/jetbrains/8th-light-lighter-gray.png" alt="8th Light Lighter Gray in RustRover" width="200"></a><br>Lighter Gray | <a href="screenshots/jetbrains/8th-light-lightest-gray.png"><img src="screenshots/jetbrains/8th-light-lightest-gray.png" alt="8th Light Lightest Gray in RustRover" width="200"></a><br>Lightest Gray | <a href="screenshots/jetbrains/8th-light-white.png"><img src="screenshots/jetbrains/8th-light-white.png" alt="8th Light White in RustRover" width="200"></a><br>White |

</details>

<details>
<summary><strong>Kitty</strong></summary>

|  |  |  |  |
| --- | --- | --- | --- |
| <a href="screenshots/kitty/8th-light-black.png"><img src="screenshots/kitty/8th-light-black.png" alt="8th Light Black in Kitty" width="200"></a><br>Black | <a href="screenshots/kitty/8th-light-charcoal.png"><img src="screenshots/kitty/8th-light-charcoal.png" alt="8th Light Charcoal in Kitty" width="200"></a><br>Charcoal | <a href="screenshots/kitty/8th-light-dark-gray.png"><img src="screenshots/kitty/8th-light-dark-gray.png" alt="8th Light Dark Gray in Kitty" width="200"></a><br>Dark Gray | <a href="screenshots/kitty/8th-light-mid-gray.png"><img src="screenshots/kitty/8th-light-mid-gray.png" alt="8th Light Mid Gray in Kitty" width="200"></a><br>Mid Gray |
| <a href="screenshots/kitty/8th-light-light-gray.png"><img src="screenshots/kitty/8th-light-light-gray.png" alt="8th Light Light Gray in Kitty" width="200"></a><br>Light Gray | <a href="screenshots/kitty/8th-light-lighter-gray.png"><img src="screenshots/kitty/8th-light-lighter-gray.png" alt="8th Light Lighter Gray in Kitty" width="200"></a><br>Lighter Gray | <a href="screenshots/kitty/8th-light-lightest-gray.png"><img src="screenshots/kitty/8th-light-lightest-gray.png" alt="8th Light Lightest Gray in Kitty" width="200"></a><br>Lightest Gray | <a href="screenshots/kitty/8th-light-white.png"><img src="screenshots/kitty/8th-light-white.png" alt="8th Light White in Kitty" width="200"></a><br>White |

</details>

<details>
<summary><strong>Neovim and Neovide</strong></summary>

|  |  |  |  |
| --- | --- | --- | --- |
| <a href="screenshots/nvim/8th-light-black.png"><img src="screenshots/nvim/8th-light-black.png" alt="8th Light Black in Neovim" width="200"></a><br>Black | <a href="screenshots/nvim/8th-light-charcoal.png"><img src="screenshots/nvim/8th-light-charcoal.png" alt="8th Light Charcoal in Neovim" width="200"></a><br>Charcoal | <a href="screenshots/nvim/8th-light-dark-gray.png"><img src="screenshots/nvim/8th-light-dark-gray.png" alt="8th Light Dark Gray in Neovim" width="200"></a><br>Dark Gray | <a href="screenshots/nvim/8th-light-mid-gray.png"><img src="screenshots/nvim/8th-light-mid-gray.png" alt="8th Light Mid Gray in Neovim" width="200"></a><br>Mid Gray |
| <a href="screenshots/nvim/8th-light-light-gray.png"><img src="screenshots/nvim/8th-light-light-gray.png" alt="8th Light Light Gray in Neovim" width="200"></a><br>Light Gray | <a href="screenshots/nvim/8th-light-lighter-gray.png"><img src="screenshots/nvim/8th-light-lighter-gray.png" alt="8th Light Lighter Gray in Neovim" width="200"></a><br>Lighter Gray | <a href="screenshots/nvim/8th-light-lightest-gray.png"><img src="screenshots/nvim/8th-light-lightest-gray.png" alt="8th Light Lightest Gray in Neovim" width="200"></a><br>Lightest Gray | <a href="screenshots/nvim/8th-light-white.png"><img src="screenshots/nvim/8th-light-white.png" alt="8th Light White in Neovim" width="200"></a><br>White |

</details>

## Setup

Keep the repository in a stable location because the installation commands
create symlinks back to this checkout.

Common requirements:

- macOS or Linux with Bash
- Any combination of Kitty, Neovim/Neovide, or a JetBrains IDE

### With Nix

Install [Nix](https://nixos.org/download/) with flakes enabled. The development
shell supplies `just` and `zip`.

With [direnv](https://direnv.net/) and its Nix integration, clone the repository,
enter it, and approve the environment once:

```sh
cd 8L-themes
direnv allow
just link
```

Without direnv, run the installer directly through the development shell:

```sh
nix develop -c just link
```

`just link` installs all three integrations and therefore expects all three
target applications to be present. Otherwise, use `just link-kitty`, `just
link-nvim`, or `just link-jetbrains` individually. Run `just --list` to see all
available helper commands.

### Without Nix

No task runner is required. Enter the cloned repository, then install only the
integrations you use.

For Kitty, link the theme files into its user theme directory:

```sh
cd 8L-themes
kitty_themes="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/themes"
mkdir -p "$kitty_themes"
ln -s "$PWD"/themes/kitty/*.conf "$kitty_themes/"
```

For Neovim and Neovide, link the theme runtime into Neovim's native package
directory:

```sh
nvim_packages="${NVIM_DATA_DIRECTORY:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim}/site/pack/8th-light/start"
mkdir -p "$nvim_packages"
ln -s "$PWD/themes/nvim" "$nvim_packages/8th-light.nvim"
```

For JetBrains IDEs, install `zip`, build the plugin JAR, and install it through
**Settings | Plugins | gear menu | Install Plugin from Disk**:

```sh
repository="$PWD"
mkdir -p "$repository/build/jetbrains"
(
  cd themes/jetbrains
  zip -q -FS -r "$repository/build/jetbrains/8th-light-themes.jar" \
    META-INF images schemes themes
)
```

Select `build/jetbrains/8th-light-themes.jar` in the file picker, then restart
the IDE.

The direct `ln` commands intentionally fail when a destination already exists
rather than replacing it. Kitty and Neovim updates flow through their symlinks.
After pulling JetBrains changes, rebuild and reinstall the JAR.

When using the Nix helpers, run `just link` after pulling an update and `just
unlink` before moving or deleting the checkout. The helpers refuse to replace
regular files and remove only symlinks managed by this checkout. The remaining
application sections use these helpers for brevity; the manual commands above
install the same files.

## Kitty

Kitty theme files live in [`themes/kitty/`](themes/kitty/).

### Install

Symlink every theme into Kitty's themes directory:

```sh
just link-kitty
```

Then include the variant you want in `~/.config/kitty/kitty.conf`, for example:

```conf
include themes/8th-Light-Charcoal.conf
```

Reload Kitty's configuration with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd>.

Running `just link-kitty` again adds new themes and refreshes existing
theme symlinks. It refuses to overwrite a regular file with the same name.

Remove the symlinks managed by this repository with:

```sh
just unlink-kitty
```

This leaves regular files and symlinks pointing elsewhere untouched.

### Variants

Available Kitty variants:

- `8th-Light-Black`
- `8th-Light-Charcoal`
- `8th-Light-Dark-Gray`
- `8th-Light-Mid-Gray`
- `8th-Light-Light-Gray`
- `8th-Light-Lighter-Gray`
- `8th-Light-Lightest-Gray`
- `8th-Light-White`

## Neovim and Neovide

The Neovim runtime in [`themes/nvim/`](themes/nvim/) provides the same eight
neutral-background variants as Kitty. Install it with:

```sh
just link-nvim
```

This links the runtime package into Neovim's standard user data directory. Set
the theme in `init.lua`, for example:

```lua
vim.cmd.colorscheme("8th-Light-Charcoal")
```

The colorscheme sets Neovim UI, syntax, Tree-sitter, diagnostics, diffs, Git
signs, embedded terminal colors, and Neovide's background and cursor-effect
colors. Run `just link` or `just unlink` to manage every application collection
at once.

## JetBrains IDEs

The resource-only plugin in [`themes/jetbrains/`](themes/jetbrains/) provides
complete UI themes and matching editor schemes for the same eight variants in
RustRover, IntelliJ IDEA, WebStorm, PyCharm, and other JetBrains IDEs. The UI
themes cover application controls, tabs, tool windows, menus, and branded
background artwork. The editor schemes cover shared editor colors,
language-default syntax, console and diff output, diagnostics, and Rust
semantic highlighting.

The plugin targets JetBrains Platform 2025.1 (`since-build 251`) and newer.

Fonts and behavioral preferences such as folding, formatting, and title-bar
paths remain IDE settings and are deliberately not changed by a theme.

The empty editor uses a fixed-size, bottom-centered 8th Light lockup on a
transparent canvas. It is naturally clipped in narrow panes and revealed in
wide panes without painting behind ordinary editors, tool windows, or IDE
chrome. Dark and light themes use white and charcoal lockups respectively.

Install them into every detected JetBrains configuration with:

```sh
just link-jetbrains
```

This builds a plugin JAR and links it into each detected IDE configuration.
Restart the IDE, then select a complete theme under **Settings | Appearance &
Behavior | Appearance**. Each UI theme selects its matching editor scheme; the
schemes can also be chosen independently under **Settings | Editor | Color
Scheme**.

Set `JETBRAINS_CONFIG_DIRECTORY` to install into one specific configuration
directory instead of every detected IDE. `just unlink-jetbrains` removes only
the plugin symlinks managed by this repository. Restart affected IDEs after
linking or unlinking.

By default, the installer detects IDE configuration directories under
`~/Library/Application Support/JetBrains` on macOS and either
`$XDG_CONFIG_HOME/JetBrains` or `~/.config/JetBrains` on Linux. The other
installers honor `KITTY_CONFIG_DIRECTORY`, `NVIM_DATA_DIRECTORY`,
`XDG_CONFIG_HOME`, and `XDG_DATA_HOME` where applicable.

## Palette

The neutral base is used for the terminal background, foreground, borders, and
tabs. The 8thlight.com website's spectrum names determine the ANSI mapping: dark blue is
ANSI blue, PMS 285 blue is ANSI cyan, purple is ANSI magenta, and violet is
bright magenta. The website's blue-255 is used for bright blue.

| Role | Hex | RGB |
| --- | --- | --- |
| True black | `#000000` | `0, 0, 0` |
| Charcoal | `#141414` | `20, 20, 20` |
| Dark gray | `#3C3C3C` | `60, 60, 60` |
| Mid gray | `#808080` | `128, 128, 128` |
| Website gray 350 | `#A6A6A6` | `166, 166, 166` |
| Light gray | `#DEDEDE` | `222, 222, 222` |
| Lighter gray | `#EBEBEB` | `235, 235, 235` |
| Lightest gray | `#F4F4F4` | `244, 244, 244` |
| White | `#FFFFFF` | `255, 255, 255` |
| Red (PMS 1788) | `#F32735` | `243, 39, 53` |
| Orange (PMS 151) | `#FF8300` | `255, 131, 0` |
| Yellow (PMS 109) | `#FFD100` | `255, 209, 0` |
| Green (PMS 375) | `#93D500` | `147, 213, 0` |
| Blue (PMS 285) / website cyan | `#0071CE` | `0, 113, 206` |
| Dark blue (PMS 301) / website blue | `#004987` | `0, 73, 135` |
| Purple (PMS 248) / website indigo | `#A81B8D` | `168, 27, 141` |
| Website violet | `#5938FF` | `89, 56, 255` |
| Website blue-255 | `#0000FF` | `0, 0, 255` |


## Development

```sh
nix develop -c just check
```

The check validates XML, JSON, and Lua syntax, confirms every variant exists in each application and in the screenshots, verifies the JetBrains theme references, compares Kitty keys across variants, and matches the README palette against the Neovim palette.

## License

Copyright © 2026 8th Light, LLC. Licensed under the MIT License. See [LICENSE](LICENSE).

8th Light® and the 8th Light logo are trademarks of 8th Light, LLC and are not covered by the MIT License.

<a href="https://8thlight.com"><img src="docs/8th-light-logo.svg" alt="8th Light" width="64"></a>

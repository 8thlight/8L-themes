{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.eighth-light-themes;
  packages = import ./packages.nix {inherit pkgs;};

  toggle = description:
    lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      inherit description;
    };

  # Link each theme file individually so the module does not own the whole
  # directory and leaves other themes in place.
  themeFiles = {
    directory,
    extension,
    destination,
  }:
    lib.mapAttrs' (name: _: lib.nameValuePair "${destination}/${name}" {source = directory + "/${name}";})
    (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix extension name) (builtins.readDir directory));
in {
  options.programs.eighth-light-themes = {
    enable = lib.mkEnableOption "the 8th Light themes";
    kitty.enable = toggle "Install the Kitty themes into the Kitty themes directory. Include one from kitty.conf to use it.";
    neovim.enable = toggle "Add the Neovim and Neovide colorschemes as a plugin of `programs.neovim`.";
    claude.enable = toggle "Install the Claude Code themes. Select one with /theme.";
    claudePowerline.enable = toggle "Install the Claude Powerline presets. Select one with --config.";
    codexCli.enable = toggle "Install the Codex CLI syntax themes. Select one with /theme.";
    jetbrains.enable = toggle "Place the JetBrains plugin JAR in the user data directory. JetBrains IDEs have no declarative plugin location, so install it once with Install Plugin from Disk.";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.kitty.enable {
      xdg.configFile = themeFiles {
        directory = ../extras/kitty;
        extension = ".conf";
        destination = "kitty/themes";
      };
    })
    (lib.mkIf cfg.neovim.enable {
      programs.neovim.plugins = [packages.neovim-plugin];
    })
    (lib.mkIf cfg.claude.enable {
      home.file = themeFiles {
        directory = ../extras/claude;
        extension = ".json";
        destination = ".claude/themes";
      };
    })
    (lib.mkIf cfg.claudePowerline.enable {
      home.file = themeFiles {
        directory = ../extras/claude-powerline;
        extension = ".json";
        destination = ".claude/powerline/themes";
      };
    })
    (lib.mkIf cfg.codexCli.enable {
      home.file = themeFiles {
        directory = ../extras/codex-cli;
        extension = ".tmTheme";
        destination = ".codex/themes";
      };
    })
    (lib.mkIf cfg.jetbrains.enable {
      xdg.dataFile."eighth-light-themes/8th-light-themes.jar".source = packages.jetbrains-plugin;
    })
  ]);
}

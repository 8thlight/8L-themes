{pkgs}: let
  lib = pkgs.lib;
  source = paths:
    lib.fileset.toSource {
      root = ../.;
      fileset = lib.fileset.unions paths;
    };
in {
  neovim-plugin = pkgs.vimUtils.buildVimPlugin {
    pname = "eighth-light-themes";
    version = "git";
    src = source [../colors ../lua];
  };

  jetbrains-plugin =
    pkgs.runCommand "8th-light-themes.jar" {
      nativeBuildInputs = [pkgs.zip];
      src = source [../extras/jetbrains];
    } ''
      cp -R $src/extras/jetbrains stage
      chmod -R u+w stage
      cd stage
      zip -q -X -r "$out" META-INF images schemes themes
    '';
}

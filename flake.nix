{
  description = "Ambxst by Axenide";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixgl,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    nixGL = nixgl.packages.${system}.nixGLDefault;

    wrapWithNixGL = pkg:
      pkgs.symlinkJoin {
        name = "${pkg.pname or pkg.name}-nixGL";
        paths = [pkg];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          for bin in $out/bin/*; do
            if [ -x "$bin" ]; then
              mv "$bin" "$bin.orig"
              makeWrapper ${nixGL}/bin/nixGL "$bin" --add-flags "$bin.orig"
            fi
          done
        '';
      };

    # Entorno con todos los binarios
    env = pkgs.buildEnv {
      name = "ambxst-env";
      paths = with pkgs; [
        (wrapWithNixGL quickshell)
        (wrapWithNixGL gpu-screen-recorder)
        (wrapWithNixGL mpvpaper)
        wl-clipboard
        cliphist
        nixGL
        mesa
        libglvnd
        egl-wayland
        wayland
        qt6.qtbase
        qt6.qtsvg
        qt6.qttools
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtwebengine
        kdePackages.breeze-icons
        hicolor-icon-theme
        fuzzel
        wtype
        imagemagick
        matugen
        ffmpeg
      ];
    };

    # Wrapper que lanza la shell desde el flake
    launcher = pkgs.writeShellScriptBin "ambxst" ''
      set -e
      cd ${self}
      exec ${nixGL}/bin/nixGL ${pkgs.quickshell}/bin/qs -p ${self}/shell.qml
    '';
  in {
    # Combina entorno + launcher
    packages.${system}.default = pkgs.buildEnv {
      name = "ambxst";
      paths = [env launcher];
    };
  };
}

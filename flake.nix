{
  description = "Ambxst by Axenide";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixgl }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.${system}.default = pkgs.symlinkJoin {
      name = "qs-env";
      paths = with pkgs; [
        # Core
        quickshell
        wl-clipboard
        cliphist
        nixgl.packages.${system}.nixGLDefault

        # OpenGL / Wayland stack
        mesa
        libglvnd
        egl-wayland
        wayland

        # Qt6 deps comunes
        qt6.qtbase
        qt6.qtsvg
        qt6.qttools
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtwebengine

        # Iconos y temas
        kdePackages.breeze-icons
        hicolor-icon-theme

        # Extras
        mpvpaper
        fuzzel
        wtype
        imagemagick
        matugen
        ffmpeg
      ];
    };
  };
}

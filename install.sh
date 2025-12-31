#!/usr/bin/env sh
set -e

FLAKE_URI="${1:-github:Axenide/Ambxst}"

echo "🚀 Ambxst Installer (Fixed: PAM Headers & Conflicts)"

# === 1. Nix Setup & Cleanup ===
# We start by cleaning up potential conflicts to ensure a smooth install.
if command -v nix >/dev/null 2>&1; then
  echo "🧹 checking for conflicts..."
  # If ddcutil is installed standalone, remove it (Ambxst provides it)
  if nix profile list | grep -q "ddcutil"; then
    echo "   Removing standalone ddcutil to avoid conflicts..."
    nix profile remove ddcutil 2>/dev/null || true
  fi
  # If Ambxst is already installed, remove it to force a clean reinstall
  # (This fixes the 'Existing package' conflict error you saw)
  if nix profile list | grep -q "Ambxst"; then
    echo "   Removing existing Ambxst to ensure clean update..."
    nix profile remove Ambxst 2>/dev/null || true
  fi
fi

# Standard Nix install check
if [ ! -f /etc/NIXOS ]; then
  if ! command -v nix >/dev/null 2>&1; then
    echo "📥 Installing Nix..."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  # Config setup
  mkdir -p ~/.config/nix ~/.config/nixpkgs
  grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null ||
    echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
  grep -q "allowUnfree" ~/.config/nixpkgs/config.nix 2>/dev/null ||
    echo "{ allowUnfree = true; }" >~/.config/nixpkgs/config.nix
fi

# === 2. Shared Assets (Fonts/Icons) ===
echo "🔤 Configuring Fonts & Icons..."
mkdir -p ~/.config/fontconfig/conf.d ~/.config/environment.d
cat >~/.config/fontconfig/conf.d/10-nix-fonts.conf <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>~/.nix-profile/share/fonts</dir>
  <dir>/nix/var/nix/profiles/default/share/fonts</dir>
</fontconfig>
EOF
cat >~/.config/environment.d/nix-data-dirs.conf <<EOF
XDG_DATA_DIRS=$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
EOF
fc-cache -fv >/dev/null 2>&1 || true

# === 3. Dependencies ===
echo "📦 Checking dependencies..."
# We skip ddcutil here because Ambxst seems to bundle it, causing conflicts if we install it separately.
for pkg in power-profiles-daemon networkmanager; do
  if ! command -v "$pkg" >/dev/null 2>&1 && ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
    # map commands to package names if needed
    nix profile install "nixpkgs#$pkg"
  fi
done

# === 4. Compile Ambxst Auth (FIXED) ===
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

if [ ! -f "$INSTALL_DIR/ambxst-auth" ]; then
  echo "🔨 Preparing to compile ambxst-auth..."

  # Install build dependencies via Nix into the profile temporarily
  echo "   Installing build dependencies (gcc, pam)..."
  nix profile install nixpkgs#gcc nixpkgs#linux-pam

  TEMP_DIR="$(mktemp -d)"
  git clone --depth 1 https://github.com/Axenide/Ambxst.git "$TEMP_DIR"

  echo "   Compiling with Nix headers..."
  # We explicitly point GCC to the Nix profile include path to find pam_appl.h
  gcc -o "$INSTALL_DIR/ambxst-auth" "$TEMP_DIR/modules/lockscreen/auth.c" \
    -I"$HOME/.nix-profile/include" \
    -L"$HOME/.nix-profile/lib" \
    -lpam -Wall -Wextra -O2

  if [ $? -eq 0 ]; then
    chmod +x "$INSTALL_DIR/ambxst-auth"
    echo "✔ ambxst-auth compiled successfully."
  else
    echo "❌ Compilation failed."
  fi
  rm -rf "$TEMP_DIR"
else
  echo "✔ ambxst-auth already exists"
fi

# === 5. Install Ambxst ===
echo "✨ Installing Ambxst..."
# We forced removal earlier, so we just use 'install' now.
# using --impure to fix the nixGL/currentTime error.
nix profile install "$FLAKE_URI" --impure

echo ""
echo "🎉 Installation Complete!"
echo "⚠  Add 'exec-once = ambxst' to your Hyprland config."

#!/usr/bin/env bash
set -e

FLAKE_URI="${1:-github:Axenide/Ambxst}"

echo "🚀 Initiating Ambxst installation..."

# This script is ONLY for non-NixOS
if [ -f /etc/NIXOS ]; then
  echo "🟦 NixOS detected: Skipping system package handling"
else
  echo "🟢 Non-NixOS system detected"

  # === Install system tools via Nix profiles (not flakes) ===

  echo "📦 Ensuring ddcutil is available (Nix profile)..."
  if ! command -v ddcutil >/dev/null 2>&1; then
    nix profile install nixpkgs#ddcutil
    echo "✅ ddcutil installed via Nix profile"
  else
    echo "✅ ddcutil already available"
  fi

  echo "📦 Ensuring powerprofilesctl is available (Nix profile)..."
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    nix profile install nixpkgs#power-profiles-daemon
    echo "✅ power-profiles-daemon client installed via Nix profile"
  else
    echo "✅ power-profiles-daemon client already available"
  fi

  echo "📦 Ensuring nmcli/nmtui are available (Nix profile)..."
  if ! command -v nmcli >/dev/null 2>&1; then
    nix profile install nixpkgs#networkmanager
    echo "✅ NetworkManager tools installed via Nix profile"
  else
    echo "✅ NetworkManager tools already available"
  fi

  # === Warn user about daemons ===

  echo "🔍 Checking for NetworkManager daemon..."
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet NetworkManager; then
      echo "✅ NetworkManager daemon is running"
    else
      echo "⚠️ NetworkManager daemon is NOT running"
      echo "   Please enable/start it manually:"
      echo "   sudo systemctl enable --now NetworkManager"
    fi
  fi

  echo "🔍 Checking for power-profiles-daemon daemon..."
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet power-profiles-daemon; then
      echo "✅ power-profiles-daemon is running"
    else
      echo "⚠️ power-profiles-daemon is NOT running"
      echo "   If your distro supports it, enable it manually:"
      echo "   sudo systemctl enable --now power-profiles-daemon"
    fi
  fi

  echo "🔍 Remember: ddcutil requires correct i2c group + udev rules:"
  echo "   sudo groupadd -f i2c"
  echo "   sudo gpasswd -a \$USER i2c"
  echo "   sudo tee /etc/udev/rules.d/60-ddcutil.rules >/dev/null <<EOF"
  echo "KERNEL==\"i2c-[0-9]*\", GROUP=\"i2c\""
  echo "EOF"
fi

# === Install Nix if missing ===
if ! command -v nix >/dev/null 2>&1; then
  echo "📥 Installing Nix..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "✅ Nix already installed"
fi

# === Enable allowUnfree ===
echo "🔑 Enable unfree packages in Nix..."
mkdir -p ~/.config/nixpkgs

if [ ! -f ~/.config/nixpkgs/config.nix ]; then
  cat >~/.config/nixpkgs/config.nix <<'EOF'
{
  allowUnfree = true;
}
EOF
  echo "✅ ~/.config/nixpkgs/config.nix created"
else
  echo "ℹ️ config.nix already exists; confirm allowUnfree = true"
fi

# === Ambxst installation ===
if [ -f /etc/NIXOS ]; then
  echo "🟦 NixOS detected: Installing Ambxst via flake"
  echo "⚠️ Add the module in your NixOS config:"
  echo ""
  echo "  { inputs.ambxst.url = \"github:Axenide/Ambxst\";"
  echo "    imports = [ inputs.ambxst.nixosModules.default ];"
  echo "  }"
  echo ""
  nix profile add "$FLAKE_URI" --impure
else
  echo "📦 Non-NixOS: Building ambxst-auth locally..."

  # Clone if remote
  if [[ "$FLAKE_URI" == github:* ]]; then
    TEMP_DIR=$(mktemp -d)
    echo "📥 Cloning Ambxst repository..."
    git clone --depth 1 https://github.com/Axenide/Ambxst.git "$TEMP_DIR"
    AUTH_SRC="$TEMP_DIR/modules/lockscreen"
  else
    AUTH_SRC="$FLAKE_URI/modules/lockscreen"
  fi

  echo "🔨 Compiling ambxst-auth..."
  cd "$AUTH_SRC"
  gcc -o ambxst-auth auth.c -lpam -Wall -Wextra -O2

  mkdir -p ~/.local/bin
  cp ambxst-auth ~/.local/bin/
  chmod +x ~/.local/bin/ambxst-auth

  echo "✅ ambxst-auth installed to ~/.local/bin/"

  if [[ "$FLAKE_URI" == github:* ]]; then
    rm -rf "$TEMP_DIR"
  fi

  echo "📦 Installing Ambxst environment..."
  nix profile add "$FLAKE_URI" --impure
fi

echo "🎉 Ambxst installed successfully!"
echo "👉 Run 'ambxst' to start."

# Ambxst
A reimplementation of Ax-Shell in Quickshell.

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Axenide/Ambxst/main/install.sh | bash
```

### NixOS

Add to your `configuration.nix`:

```nix
{
  inputs.ambxst.url = "github:Axenide/Ambxst";
  
  imports = [ inputs.ambxst.nixosModules.default ];
}
```

This automatically configures NetworkManager if not already enabled.

Then install Ambxst:

```bash
nix profile add github:Axenide/Ambxst --impure
```

### Non-NixOS Systems

The `install.sh` script will:
1. Install system dependencies (ddcutil, NetworkManager, power-profiles-daemon)
2. Install Nix if not present
3. Build `ambxst-auth` locally to `~/.local/bin/`
4. Install Ambxst environment via Nix flake

The lockscreen works out-of-the-box since PAM handles authentication through its own privileged helpers (`unix_chkpwd`).

## Secure Lockscreen

Ambxst uses Wayland Session Lock protocol for a truly secure lockscreen that persists even if the shell process crashes. See [SECURE_LOCKSCREEN.md](modules/lockscreen/SECURE_LOCKSCREEN.md) for details.

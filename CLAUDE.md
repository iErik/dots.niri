# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a declarative dotfiles repository for the **Niri Wayland window manager**, managed via NixOS Home Manager and Nix Flakes.

## Architecture

### Files

- **`flake.nix`** — Entry point. Exports a Home Manager module (`dots`) using nixpkgs unstable.
- **`nix/default.nix`** — Home Manager module (`dots.nvim`) that installs Neovim and deploys the dotfiles. On activation it clones `git@github.com:iErik/dots.niri.git` to `~/Dots/Niri.dots`, pulls on subsequent activations, sets permissions, and symlinks to `~/.config/niri`.
- **`config.kdl`** — Niri window manager configuration (KDL format). Defines environment variables, monitor layouts, input settings, keybindings, and startup applications.

### Deployment Flow

The flake is consumed by an external NixOS configuration. Enabling the module causes Home Manager to:
1. Install Neovim
2. Clone/pull the dotfiles repo via SSH
3. Symlink the config into `~/.config/niri`

There are no build, test, or lint commands — this is a pure configuration repository.

## Key Configuration Details

### Monitors (`config.kdl`)
- DP-2: 2560×1080@60Hz (primary, startup focus)
- DP-3: 2560×1080@60Hz (rotated 270°)
- HDMI-A-1: 1920×1080@60Hz
- HDMI-A-2: 4096×2160@30Hz

### Keybindings (Mod = Super)
- `Mod+Return` → kitty terminal
- `Mod+D` → rofi launcher
- `Mod+hjkl` / arrow keys → focus/move windows
- `Mod+1–9` / `Mod+Shift+1–9` → switch/move workspaces
- `W` tabbed, `V` float, `C` center, `F` maximize, `M` expand

### Applying Changes
To apply Niri config changes without a full rebuild, reload Niri in-place. For Nix module changes, rebuild via the external NixOS/Home Manager configuration that consumes this flake.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A rofi-based application launcher for openSUSE with smart focus-or-open behavior (focuses existing windows instead of opening duplicates) and frequency-based sorting (most-used apps appear first).

## Dependencies

- rofi, xdotool, wmctrl, python3
- Install via: `sudo zypper install -y rofi xdotool wmctrl`

## Commands

```bash
# Install everything (dependencies, config, launcher)
./install.sh

# Run the launcher directly
~/rofi-focus-or-open.sh

# Force rebuild app cache
rm ~/.cache/rofi/apps_cache.txt
```

## Architecture

**Main script** (`rofi-focus-or-open.sh`):
- Scans `.desktop` files from `/usr/share/applications`, `~/.local/share/applications`, and flatpak exports
- Caches app info (name, exec command, binary, WM_CLASS) in `~/.cache/rofi/apps_cache.txt`
- Auto-refreshes cache in background every 10 minutes
- Uses embedded Python to sort apps by frequency and display via rofi
- Window matching: tries WM_CLASS first, then binary name via wmctrl (strips `-stable`, `-beta`, `-dev`, `-nightly` suffixes for browser compatibility)
- Launches via `gtk-launch` if available, otherwise `nohup bash -c`

**Data files**:
- `~/.cache/rofi/apps_cache.txt` - Pipe-delimited: `name|exec_cmd|binary|wm_class|desktop_file`
- `~/.local/share/rofi/app_frequency.json` - JSON dict of app launch counts

**Rofi config** (`config.rasi`): Uses Arc-Dark theme with custom styling.

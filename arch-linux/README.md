# Rofi Focus-or-Open for Arch Linux + Sway

A rofi-based application launcher optimized for Sway (Wayland compositor) on Arch Linux. Focuses existing windows or launches new instances, with special support for Chrome PWAs (Progressive Web Apps).

## Features

- **Smart App Caching**: Caches `.desktop` files from standard locations with automatic refresh when apps are installed/removed
- **Frequency-Based Sorting**: Most-used apps appear at the top
- **Chrome PWA Support**: Properly detects and focuses Chrome web apps (e.g., YouTube Music, Google Keep)
- **Prioritized Window Matching**: Standalone apps are prioritized over browser tabs with matching titles
- **Window Focus-or-Launch**: Focuses existing window if found, otherwise launches the app

## Dependencies

```bash
sudo pacman -S rofi jq python3
```

Also requires:
- **Sway** window manager (uses `swaymsg` for window management)
- **bash** (default shell)

## Installation

1. Copy the launcher script:
```bash
cp rofi-focus-or-open.sh ~/
chmod +x ~/rofi-focus-or-open.sh
```

2. Copy the rofi theme config:
```bash
mkdir -p ~/.config/rofi
cp config.rasi ~/.config/rofi/
```

3. Add a keybinding in your Sway config (`~/.config/sway/config`):
```
bindsym $mod+d exec ~/rofi-focus-or-open.sh
```

4. Reload Sway:
```bash
swaymsg reload
```

## File Locations

| File | Purpose |
|------|---------|
| `~/rofi-focus-or-open.sh` | Main launcher script |
| `~/.config/rofi/config.rasi` | Rofi appearance/theme |
| `~/.local/share/rofi/app_frequency.json` | Usage frequency data (auto-created) |
| `~/.cache/rofi/apps_cache.txt` | App cache (auto-created) |

## How It Works

1. **Cache Building**: Scans `.desktop` files from:
   - `/usr/share/applications`
   - `~/.local/share/applications`
   - `/var/lib/flatpak/exports/share/applications`

2. **Window Matching Priority**:
   1. Chrome PWA exact match (by app-id)
   2. StartupWMClass match
   3. Binary name match (skipped for Chrome PWAs)
   4. Window title match (standalone apps prioritized over browser tabs)

3. **Cache Refresh**: Automatically rebuilds when:
   - Cache file is missing
   - Source directories have been modified (new apps installed)
   - Cache is older than 10 minutes (background refresh)

## Theme

The included `config.rasi` provides a dark theme with:
- Semi-transparent background (`#2b303bee`)
- Blue accent color (`#5e81ac`)
- Ubuntu font
- Rounded corners
- Mode switcher (Apps, Windows, Run)

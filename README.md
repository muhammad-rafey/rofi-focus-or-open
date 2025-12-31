# Rofi Focus-or-Open Launcher

A rofi-based application launcher for **openSUSE** with smart focus-or-open behavior and frequency-based sorting.

## Features

- **Focus or Open**: If an app is already running, focuses the existing window instead of opening a new instance (similar to GNOME/macOS behavior)
- **Frequency Sorting**: Apps you use more often appear higher in the list (like macOS Spotlight)
- **App Name Search**: Searches by application name from .desktop files, not window titles
- **Fast Startup**: Uses caching for instant rofi popup
- **Auto Cache Refresh**: App cache refreshes in background every 10 minutes

## Requirements

- openSUSE (tested on Tumbleweed)
- KDE Plasma (or any desktop environment)
- Dependencies: `rofi`, `xdotool`, `wmctrl`, `python3`

## Installation

### Quick Install

```bash
cd ~/Documents/rofi-setup
./install.sh
```

### Manual Install

1. Install dependencies:
   ```bash
   sudo zypper install -y rofi xdotool wmctrl
   ```

2. Copy the launcher script:
   ```bash
   cp rofi-focus-or-open.sh ~/rofi-focus-or-open.sh
   chmod +x ~/rofi-focus-or-open.sh
   ```

3. Copy rofi config (optional, for styling):
   ```bash
   mkdir -p ~/.config/rofi
   cp config.rasi ~/.config/rofi/
   ```

4. Create required directories:
   ```bash
   mkdir -p ~/.local/share/rofi ~/.cache/rofi
   echo '{}' > ~/.local/share/rofi/app_frequency.json
   ```

## Setting Up Keyboard Shortcut

### KDE Plasma

1. Open **System Settings** → **Shortcuts** → **Custom Shortcuts**
2. Click **Edit** → **New** → **Global Shortcut** → **Command/URL**
3. Name it "Rofi Launcher"
4. In the **Trigger** tab, set your preferred shortcut (e.g., `Meta+Space` or `Alt+Space`)
5. In the **Action** tab, enter:
   ```
   /home/YOUR_USERNAME/rofi-focus-or-open.sh
   ```
6. Click **Apply**

### GNOME

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ name 'Rofi Launcher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ command '/home/YOUR_USERNAME/rofi-focus-or-open.sh'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ binding '<Super>space'
```

## Files

| File | Description |
|------|-------------|
| `rofi-focus-or-open.sh` | Main launcher script |
| `config.rasi` | Rofi styling configuration |
| `install.sh` | Automated installer script |

## Data Files (created automatically)

| Location | Description |
|----------|-------------|
| `~/.cache/rofi/apps_cache.txt` | Cached list of applications |
| `~/.local/share/rofi/app_frequency.json` | App usage frequency data |

## Refresh App Cache

If you install new applications and want to see them immediately:

```bash
rm ~/.cache/rofi/apps_cache.txt
```

The cache will be rebuilt on next launch.

## How It Works

1. On first run, scans all `.desktop` files and caches app info
2. Shows rofi with apps sorted by usage frequency
3. When you select an app:
   - Checks if a window with matching WM_CLASS or binary name exists
   - If found → focuses the existing window
   - If not found → launches a new instance
4. Updates usage frequency for sorting

## License

MIT License - Feel free to modify and share!

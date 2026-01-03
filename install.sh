#!/bin/bash

# Rofi Focus-or-Open Installer for openSUSE
# Installs rofi with focus-or-open behavior and frequency sorting

set -e

echo "=== Rofi Focus-or-Open Installer ==="
echo ""

# Install dependencies
echo "[1/5] Installing dependencies..."
sudo zypper install -y rofi xdotool wmctrl

# Create directories
echo "[2/5] Creating directories..."
mkdir -p ~/.config/rofi
mkdir -p ~/.local/share/rofi
mkdir -p ~/.cache/rofi

# Copy config
echo "[3/5] Installing rofi config..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/config.rasi" ~/.config/rofi/

# Copy launcher script
echo "[4/5] Installing launcher script..."
cp "$SCRIPT_DIR/rofi-focus-or-open.sh" ~/rofi-focus-or-open.sh
chmod +x ~/rofi-focus-or-open.sh

# Initialize frequency file (only if it doesn't exist, to preserve usage history)
[[ -f ~/.local/share/rofi/app_frequency.json ]] || echo '{}' > ~/.local/share/rofi/app_frequency.json

# Build app cache
echo "[5/5] Building app cache..."
for dir in /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*.desktop; do
        [[ -f "$f" ]] || continue
        grep -q "^NoDisplay=true" "$f" 2>/dev/null && continue
        name=$(grep -m1 "^Name=" "$f" | cut -d= -f2-)
        exec_cmd=$(grep -m1 "^Exec=" "$f" | cut -d= -f2- | sed 's/%[fFuUdDnNickvm]//g')
        wm_class=$(grep -m1 "^StartupWMClass=" "$f" | cut -d= -f2-)
        binary=$(basename "$(echo "$exec_cmd" | awk '{print $1}')" 2>/dev/null)
        [[ -n "$name" && -n "$exec_cmd" ]] && echo "${name}|${exec_cmd}|${binary}|${wm_class}|${f}"
    done
done | sort -u -t'|' -k1,1 > ~/.cache/rofi/apps_cache.txt

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Launcher script: ~/rofi-focus-or-open.sh"
echo "Config file:     ~/.config/rofi/config.rasi"
echo "Apps cached:     $(wc -l < ~/.cache/rofi/apps_cache.txt) apps"
echo ""
echo "Next step: Bind a keyboard shortcut to:"
echo "  /home/$USER/rofi-focus-or-open.sh"
echo ""
echo "For KDE: System Settings → Shortcuts → Custom Shortcuts"
echo "         Add new Global Shortcut → Command/URL"

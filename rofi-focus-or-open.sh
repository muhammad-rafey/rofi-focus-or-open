#!/bin/bash

# Rofi Focus-or-Open Launcher (Optimized with caching)

FREQ_FILE="$HOME/.local/share/rofi/app_frequency.json"
CACHE_FILE="$HOME/.cache/rofi/apps_cache.txt"

# Ensure dirs and files exist
[[ -d "$HOME/.local/share/rofi" ]] || mkdir -p "$HOME/.local/share/rofi"
[[ -d "$HOME/.cache/rofi" ]] || mkdir -p "$HOME/.cache/rofi"
[[ -f "$FREQ_FILE" ]] || echo '{}' > "$FREQ_FILE"

# Build cache function (runs in background for updates)
build_cache() {
    {
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
        done
    } | sort -u -t'|' -k1,1 > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# Build cache if missing; refresh in background if older than 10 min
if [[ ! -f "$CACHE_FILE" ]]; then
    build_cache
elif [[ -n $(find "$CACHE_FILE" -mmin +10 2>/dev/null) ]]; then
    build_cache &
fi

# Show rofi with frequency-sorted apps
selected=$(python3 -c "
import json, os
freq_file = os.path.expanduser('$FREQ_FILE')
cache_file = os.path.expanduser('$CACHE_FILE')
try:
    with open(freq_file) as f: freq = json.load(f)
except: freq = {}
try:
    with open(cache_file) as f: apps = [l.strip() for l in f if l.strip()]
except: apps = []
apps.sort(key=lambda x: (-freq.get(x.split('|')[0], 0), x.split('|')[0].lower()))
for a in apps: print(a.split('|')[0])
" | rofi -dmenu -i -p "" -matching prefix -theme-str 'window {width: 40%;}' -theme-str 'listview {lines: 15;}')

[[ -z "$selected" ]] && exit 0

# Get app info
app_info=$(grep "^${selected}|" "$CACHE_FILE" | head -1)
[[ -z "$app_info" ]] && app_info=$(grep -i "^${selected}" "$CACHE_FILE" | head -1)
[[ -z "$app_info" ]] && exit 1

IFS='|' read -r name exec_cmd binary wm_class desktop_file <<< "$app_info"

# Update frequency in background
python3 -c "
import json
try:
    with open('$FREQ_FILE') as f: d = json.load(f)
except: d = {}
d['$name'] = d.get('$name', 0) + 1
with open('$FREQ_FILE', 'w') as f: json.dump(d, f)
" &

# Find existing window
window_id=""
if [[ -n "$wm_class" ]]; then
    window_id=$(wmctrl -lx 2>/dev/null | grep -i "$wm_class" | head -1 | awk '{print $1}')
fi
if [[ -z "$window_id" && -n "$binary" ]]; then
    # Strip common suffixes (-stable, -beta, -dev, -nightly) for better matching
    binary_base=$(echo "$binary" | sed 's/-\(stable\|beta\|dev\|nightly\)$//')
    window_id=$(wmctrl -lx 2>/dev/null | awk -v b="$binary_base" 'tolower($3)~tolower(b){print $1;exit}')
fi

# Focus or launch
if [[ -n "$window_id" ]]; then
    wmctrl -i -a "$window_id"
else
    if command -v gtk-launch &>/dev/null && [[ -n "$desktop_file" ]]; then
        gtk-launch "$(basename "$desktop_file")" &>/dev/null &
    else
        nohup bash -c "$exec_cmd" &>/dev/null &
    fi
fi

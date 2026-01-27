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
                # Extract Chrome PWA app-id to build correct Sway app_id
                chrome_app_id=""
                if [[ "$exec_cmd" == *"--app-id="* ]]; then
                    chrome_app_id=$(echo "$exec_cmd" | grep -oP '(?<=--app-id=)[^ ]+')
                fi
                [[ -n "$name" && -n "$exec_cmd" ]] && echo "${name}|${exec_cmd}|${binary}|${wm_class}|${f}|${chrome_app_id}"
            done
        done
    } | sort -u -t'|' -k1,1 > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# Check if cache is stale (source directories modified after cache)
is_cache_stale() {
    [[ ! -f "$CACHE_FILE" ]] && return 0
    for dir in /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications; do
        if [[ -d "$dir" ]] && [[ "$dir" -nt "$CACHE_FILE" ]]; then
            return 0
        fi
    done
    return 1
}

# Build cache if missing, stale, or older than 10 min
if [[ ! -f "$CACHE_FILE" ]]; then
    build_cache
elif is_cache_stale; then
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
" | rofi -dmenu -i -p "" -matching fuzzy -theme-str 'window {width: 40%;}' -theme-str 'listview {lines: 15;}')

[[ -z "$selected" ]] && exit 0

# Get app info
app_info=$(grep "^${selected}|" "$CACHE_FILE" | head -1)
[[ -z "$app_info" ]] && app_info=$(grep -i "^${selected}" "$CACHE_FILE" | head -1)
[[ -z "$app_info" ]] && exit 1

IFS='|' read -r name exec_cmd binary wm_class desktop_file chrome_app_id <<< "$app_info"

# Update frequency in background
python3 -c "
import json
try:
    with open('$FREQ_FILE') as f: d = json.load(f)
except: d = {}
d['$name'] = d.get('$name', 0) + 1
with open('$FREQ_FILE', 'w') as f: json.dump(d, f)
" &

# Find Chrome PWA window by app-id (exact match pattern)
find_chrome_pwa_window() {
    local app_id="$1"
    swaymsg -t get_tree 2>/dev/null | jq -r --arg id "$app_id" '
        recurse(.nodes[]?, .floating_nodes[]?) |
        select(.app_id? // "" | startswith("chrome-" + $id)) |
        .id
    ' | head -1
}

# Find existing window using swaymsg (Wayland/Sway)
find_sway_window() {
    local search="$1"
    swaymsg -t get_tree 2>/dev/null | jq -r --arg s "$search" '
        recurse(.nodes[]?, .floating_nodes[]?) |
        select(.app_id? or .window_properties?.class?) |
        select(
            (.app_id? // "" | ascii_downcase | contains($s | ascii_downcase)) or
            (.window_properties?.class? // "" | ascii_downcase | contains($s | ascii_downcase)) or
            (.name? // "" | ascii_downcase | contains($s | ascii_downcase))
        ) |
        .id
    ' | head -1
}

# Find window by title, prioritizing standalone apps over browser tabs
find_sway_window_by_title_prioritized() {
    local search="$1"
    swaymsg -t get_tree 2>/dev/null | jq -r --arg s "$search" '
        [
            recurse(.nodes[]?, .floating_nodes[]?) |
            select(.name? // "" | ascii_downcase | contains($s | ascii_downcase)) |
            {id: .id, app_id: (.app_id // ""), is_browser: ((.app_id // "") == "google-chrome" or (.app_id // "") == "chromium" or (.app_id // "") == "firefox")}
        ] |
        sort_by(.is_browser) |
        .[0].id // empty
    '
}

con_id=""
# First: try Chrome PWA exact match (highest priority for web apps)
if [[ -n "$chrome_app_id" ]]; then
    con_id=$(find_chrome_pwa_window "$chrome_app_id")
fi

# Second: try wm_class (specific to app)
if [[ -z "$con_id" && -n "$wm_class" ]]; then
    con_id=$(find_sway_window "$wm_class")
fi

# Third: try binary name (skip for Chrome PWAs - their binary would match the browser)
if [[ -z "$con_id" && -n "$binary" && -z "$chrome_app_id" ]]; then
    binary_base=$(echo "$binary" | sed 's/-\(stable\|beta\|dev\|nightly\)$//')
    con_id=$(find_sway_window "$binary_base")
fi

# Fourth: try app name in window title (prioritize standalone apps over browser tabs)
if [[ -z "$con_id" ]]; then
    con_id=$(find_sway_window_by_title_prioritized "$name")
fi

# Focus or launch
if [[ -n "$con_id" ]]; then
    swaymsg "[con_id=$con_id] focus"
else
    if command -v gtk-launch &>/dev/null && [[ -n "$desktop_file" ]]; then
        gtk-launch "$(basename "$desktop_file")" &>/dev/null &
    else
        nohup bash -c "$exec_cmd" &>/dev/null &
    fi
fi

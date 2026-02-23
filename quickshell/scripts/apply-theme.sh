#!/bin/bash

THEME="$HOME/.config/quickshell/Theme.qml"

get() {
    grep "readonly property.*$1" "$THEME" | grep -oP '(?<=: )["\047]?\K[^"\047;/]+' | head -1 | tr -d '"'
}

WALLPAPER=$(get "wallpaper")
FONT=$(get "fontFamily")
COL_BG=$(get "colBg")
COL_FG=$(get "colFg")
COL_BLUE=$(get "colBlue")
COL_CYAN=$(get "colCyan")
COL_MUTED=$(get "colMuted")

echo "Applying theme..."
echo "  Wallpaper : $WALLPAPER"
echo "  Font      : $FONT"
echo "  Accent    : $COL_BLUE"

# hyprpaper
cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
preload = $WALLPAPER
wallpaper = ,$WALLPAPER
splash = false
EOF

if pgrep -x hyprpaper > /dev/null; then
    hyprctl hyprpaper wallpaper ",$WALLPAPER" 2>/dev/null
fi

# fish
fish -c "
    set -U fish_color_command       '$COL_BLUE'
    set -U fish_color_param         '$COL_FG'
    set -U fish_color_autosuggestion '$COL_MUTED'
    set -U fish_color_error         '#f7768e'
    set -U fish_color_operator      '$COL_CYAN'
    set -U pure_color_primary       '$COL_BLUE'
    set -U pure_color_success       '$COL_CYAN'
    set -U pure_color_mute          '$COL_MUTED'
" 2>/dev/null


echo "Done!"
pid=$(pgrep -x quickshell)
kill "$pid"

sleep 0.5
nohup quickshell -d >/dev/null 2>&1 &
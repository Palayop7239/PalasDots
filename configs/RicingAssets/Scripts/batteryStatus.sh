#!/bin/bash

# battery.sh - outputs a nerd font battery icon + percentage for hyprlock
# Usage: bash battery.sh        -> "󰁾 58%"
#        bash battery.sh icon   -> "󰁾"
#        bash battery.sh pct    -> "58%"

PCT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "0")
STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")

if [[ "$STATUS" == "Full" ]]; then
    ICON="󰁹"
elif [[ "$STATUS" == "Charging" ]]; then
    if   [[ $PCT -lt 10 ]]; then ICON="󰢟"
    elif [[ $PCT -lt 20 ]]; then ICON="󰢜"
    elif [[ $PCT -lt 30 ]]; then ICON="󰂆"
    elif [[ $PCT -lt 40 ]]; then ICON="󰂇"
    elif [[ $PCT -lt 50 ]]; then ICON="󰂈"
    elif [[ $PCT -lt 60 ]]; then ICON="󰢝"
    elif [[ $PCT -lt 70 ]]; then ICON="󰂉"
    elif [[ $PCT -lt 80 ]]; then ICON="󰢞"
    elif [[ $PCT -lt 90 ]]; then ICON="󰂊"
    elif [[ $PCT -lt 100 ]]; then ICON="󰂋"
    else ICON="󰂅"
    fi
else
    # Discharging
    if   [[ $PCT -lt 10 ]]; then ICON="󰂎"
    elif [[ $PCT -lt 20 ]]; then ICON="󰁺"
    elif [[ $PCT -lt 30 ]]; then ICON="󰁻"
    elif [[ $PCT -lt 40 ]]; then ICON="󰁼"
    elif [[ $PCT -lt 50 ]]; then ICON="󰁽"
    elif [[ $PCT -lt 60 ]]; then ICON="󰁾"
    elif [[ $PCT -lt 70 ]]; then ICON="󰁿"
    elif [[ $PCT -lt 80 ]]; then ICON="󰂀"
    elif [[ $PCT -lt 90 ]]; then ICON="󰂁"
    else ICON="󰂂"
    fi
fi

case "$1" in
    icon) echo "$ICON" ;;
    pct)  echo "${PCT}%" ;;
    *)    echo "$ICON ${PCT}%" ;;
esac
#!/bin/bash
# Current waypaper wallpaper, read straight from its config (no python startup).
#   wallpaper.sh          print the wallpaper path (used by hypr/lock.sh)
#   wallpaper.sh --set    draw it with swaybg (niri startup, instead of the slower `waypaper --restore`)

config=~/.config/waypaper/config.ini
setting() { sed -n "s/^$1 = //p" "$config"; }

wallpaper=$(setting wallpaper)
wallpaper=${wallpaper/#\~/$HOME}

if [[ $1 != --set ]]; then
    echo "$wallpaper"
    exit
fi

[[ -f $wallpaper ]] || exit 1
exec swaybg -i "$wallpaper" -m "$(setting fill)" -c "$(setting color)"

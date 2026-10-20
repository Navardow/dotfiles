#!/bin/bash
# Lock the screen with hyprlock over the current waypaper wallpaper (swaylock if hyprlock is missing).
# -f: return once the lock is up instead of when it's unlocked (for swayidle).

wallpaper=$(~/.config/waypaper/wallpaper.sh)

if ! command -v hyprlock > /dev/null; then
    [[ -f $wallpaper ]] && exec swaylock --image "$wallpaper" "$@"
    exec swaylock "$@"
fi

pidof hyprlock > /dev/null && exit

# hyprlock.conf sources this; "screenshot" blurs the current screen if there's no wallpaper file
mkdir -p ~/.cache
[[ -f $wallpaper ]] || wallpaper=screenshot
echo "\$wallpaper = $wallpaper" > ~/.cache/hyprlock-wallpaper.conf

if [[ $1 == -f ]]; then
    hyprlock &
    disown
    sleep 1
else
    exec hyprlock
fi

#!/usr/bin/env bash

declare -a packages
packages=("niri" "alacritty" "fuzzel" "mako" "nvim" "swaybg" "swaylock" "waybar")

for package in "${packages[@]}"; do
    echo "Installing ${package}..."
    sudo pacman -S ${package} --noconfirm

    if [[ $? -eq 0 ]]; then
        echo "Succeeded"
    else
        echo "Failed"
    fi


done



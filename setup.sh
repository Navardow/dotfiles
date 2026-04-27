#!/usr/bin/env bash

#tmp gets wiped on reboot
log_file="/tmp/setup_log.txt"
LY_TTY=2
DOTFILES="$HOME/.dotfiles"

sudo pacman -Syu --noconfirm
if [[ $? -ne 0 ]]; then
    echo "system update failed"
    exit 1
fi

declare -a packages
packages=("niri" "alacritty" "fuzzel" "mako" "swaybg" "swaylock" "waybar" "interception-caps2esc")

for package in "${packages[@]}"; do
    echo "Installing ${package}..."
    sudo pacman -S --noconfirm ${package} 2>> log_file

    if [[ $? -eq 0 ]]; then
        echo "${package} installation Succeeded"
    else
        echo "${package} installation Failed"
    fi
done

#install bob
if sudo pacman -S --noconfirm bob 2>> log_file \
    && bob install nightly 2>> log_file \
    && bob use nightly 2>> log_file ; then
    echo "neovim nightly installation successfull."
else
    echo "neovim nightly installation failed. neovim might not work as intended; install manually."
fi

#stow
stow -D config -d "${DOTFILES}" -t "$HOME/.config"
stow -D home -d "${DOTFILES}" -t "$HOME"

if stow config -d "${DOTFILES}" -t "$HOME/.config" 2>> log_file; then
    echo "$HOME/.config symlinks created"
fi
if stow home -d "${DOTFILES}" -t "$HOME" 2>> log_file; then
    echo "$HOME symlinks created"
fi

#ly
if sudo pacman -S --noconfirm ly 2>> log_file; then
    echo "ly installation successfull."

    for svc in ly sddm gdm lightdm lxdm; do
        if systemctl list-unit-files | grep -q "^${svc}"; then
            echo " disabling ${svc}"
            sudo systemctl disable "${svc}" 2>> log_file
            sudo systemctl stop "${svc}" 2>> log_file
        fi
    done

    sudo systemctl mask "getty@tty${LY_TTY}" 2>> log_file

    if sudo systemctl enable "ly@tty${LY_TTY}" 2>> log_file \
        && sudo systemctl start "ly@tty${LY_TTY}" 2>> log_file ; then
        sudo cp -b ${HOME}/.dotfiles/system/etc/ly/config.ini /etc/ly/ 2>> log_file
        echo "lytty services enabled successfully."
    else
        sudo systemctl enable getty@tty2 2>> log_file  \
            && sudo systemctl start getty@tty2 2>> log_file
        echo "ly services could was not enabled."
    fi
else
    echo "ly installation failed"
fi

if sudo mkdir -p /etc/interception/udevmon.d/ 2>> log_file \
    && sudo cp -b $HOME/.dotfiles/system/etc/interception/udevmon.d/udevmon.yaml /etc/interception/udevmon.d/ 2>> log_file; then
    if sudo systemctl enable --now udevmon; then
        echo "caps2esc setup successfull"
    fi
else
    echo "caps2esc sutup not successfull"
fi

#!/usr/bin/env bash
# Set up a fresh Arch install with these dotfiles. Run as your normal user; it uses sudo where needed.
# Keep the package lists below in sync with what the configs use.

DOTFILES="$HOME/.dotfiles"
LY_TTY=2
#tmp gets wiped on reboot
log_file="/tmp/setup_log.txt"

if [[ $EUID -eq 0 ]]; then
    echo "run this as your normal user, not root"
    exit 1
fi

packages=(
    # niri session and what it starts / binds
    niri waybar mako fuzzel alacritty swayidle swaybg brightnessctl
    # lock screen (hypr/lock.sh); swaylock is the fallback
    hyprlock swaylock
    # wifi/bluetooth are waybar modules; nm-connection-editor backs "Edit connections" in the wifi picker
    networkmanager nm-connection-editor bluez blueman
    # audio: volume keys, waybar volume icon + popup (scripts/volume-popup.py), mixer on right-click
    pipewire pipewire-pulse wireplumber libpulse pavucontrol
    python python-gobject gtk3 gtk-layer-shell
    # apps with their own niri workspace (window rules in config/niri/config.kdl)
    firefox discord
    # spotify: the app, and playerctl for the waybar mpris module + popup (scripts/spotify-popup.py)
    spotify-launcher playerctl
    # waybar stats and network module clicks
    htop lm_sensors networkmanager-dmenu
    # fonts: bar text, Material Symbols Rounded for every waybar/popup icon, and the default
    # monospace font (alacritty and fuzzel don't set one)
    ttf-ubuntu-nerd ttf-material-symbols-variable noto-fonts
    # GTK settings (config/gtk-3.0, gtk-4.0): Papirus-Dark icons (tray app icons), Adwaita Sans font
    papirus-icon-theme adwaita-fonts
    # secret storage for app logins (spotify, discord, browsers); ly's PAM config creates and
    # unlocks an encrypted "login" keyring with your password, so it must be installed before first login
    gnome-keyring
    # desktop portals, as niri's niri-portals.conf expects: gnome (screen sharing, screenshots),
    # gtk (file pickers, notifications); gnome-keyring above backs the Secret portal
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    # shell, tools, dotfile linking (git talks to github over ssh, see home/.gitconfig);
    # jq for the claude code hook (home/.claude/hooks/block-shell-writes.sh)
    tmux git openssh stow bob jq
    # neovim (config/nvim): plugin builds (telescope-fzf-native, blink.cmp, treesitter) and search
    base-devel rust ripgrep fd tree-sitter-cli
    # neovim LSPs and formatters (config/nvim/lua/lsp, plugins/conform.lua)
    clang lua-language-server marksman vscode-css-languageserver stylua prettier ruff nodejs npm
    # caps lock -> escape
    interception-caps2esc
)
aur_packages=(
    waypaper
    # mako notification font
    cozette-otb
    # neovim: typescript LSP and prettier daemon
    vtsls prettierd
)
# used by the neovim config but not packaged anywhere; printed at the end
manual_installs=(
    "basedpyright (python LSP): sudo pacman -S python-pipx && pipx install basedpyright"
    "kotlin-lsp (kotlin LSP): https://github.com/Kotlin/kotlin-lsp/releases"
)

# install_each <install command...> -- <packages...>
install_each() {
    local installer=() pkg
    while [[ $1 != -- ]]; do
        installer+=("$1")
        shift
    done
    shift
    for pkg in "$@"; do
        echo "Installing ${pkg}..."
        if "${installer[@]}" "$pkg" 2>> "$log_file"; then
            echo "${pkg} installation Succeeded"
        else
            echo "${pkg} installation Failed"
        fi
    done
}

if ! sudo pacman -Syu --noconfirm; then
    echo "system update failed"
    exit 1
fi

install_each sudo pacman -S --needed --noconfirm -- "${packages[@]}"

#aur
if ! command -v yay > /dev/null; then
    echo "Installing yay..."
    yay_dir="$(mktemp -d)"
    sudo pacman -S --needed --noconfirm base-devel git 2>> "$log_file" \
        && git clone https://aur.archlinux.org/yay-bin.git "$yay_dir" 2>> "$log_file" \
        && (cd "$yay_dir" && makepkg -si --noconfirm) 2>> "$log_file"
    rm -rf "$yay_dir"
fi
if command -v yay > /dev/null; then
    install_each yay -S --needed --noconfirm -- "${aur_packages[@]}"
else
    echo "yay installation failed; install manually: ${aur_packages[*]}"
fi

#wifi and bluetooth daemons (the waybar network/bluetooth modules and their clicks need them)
if sudo systemctl enable --now NetworkManager bluetooth 2>> "$log_file"; then
    echo "NetworkManager and bluetooth enabled"
else
    echo "enabling NetworkManager/bluetooth failed, see $log_file"
fi

#blueman-applet stays running for pairing prompts, but bluetooth lives in a waybar module, so hide its tray icon
# (ShowConnected depends on StatusIcon, so it has to go too)
gsettings set org.blueman.general plugin-list "['!StatusIcon', '!ShowConnected']" 2>> "$log_file"

#neovim nightly through bob
if bob install nightly 2>> "$log_file" && bob use nightly 2>> "$log_file"; then
    echo "neovim nightly installation successful."
else
    echo "neovim nightly installation failed. neovim might not work as intended; install manually."
fi

#nvim config is a git submodule; fetch it before stowing so config/nvim isn't empty.
#(runs before home/.gitconfig is linked, so github is still reached over https, no ssh key needed)
#only on a fresh clone: on a re-run this would move config/nvim back to the recorded commit
if [[ -e $DOTFILES/config/nvim/.git ]]; then
    echo "nvim config submodule already present"
elif git -C "$DOTFILES" submodule update --init --recursive 2>> "$log_file"; then
    echo "nvim config submodule fetched"
else
    echo "nvim config submodule failed; run: git -C $DOTFILES submodule update --init"
fi

#waypaper rewrites its config.ini whenever you pick a wallpaper; keep those per-machine changes out of git.
#(skip-worktree is local to each clone, so it has to be set here rather than committed)
git -C "$DOTFILES" update-index --skip-worktree config/waypaper/config.ini 2>> "$log_file"

#stow (-R restows, so this also picks up config dirs added since the last run).
#gtk dirs are created first so only settings.ini gets linked; otherwise stow links the whole dir
#and whatever GTK apps write there (bookmarks etc.) would land in the repo.
#same for ~/.claude: only the config files should be linked, not sessions/credentials
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.claude/hooks"
if stow -R config -d "$DOTFILES" -t "$HOME/.config" 2>> "$log_file"; then
    echo "$HOME/.config symlinks created"
else
    echo "$HOME/.config symlinks failed; a real file is probably in the way, see $log_file"
fi
if stow -R home -d "$DOTFILES" -t "$HOME" 2>> "$log_file"; then
    echo "$HOME symlinks created"
else
    echo "$HOME symlinks failed; a real file is probably in the way, see $log_file"
fi

#ly (other display managers are only disabled, not stopped, so a running session isn't killed)
if sudo pacman -S --needed --noconfirm ly 2>> "$log_file"; then
    echo "ly installation successful."

    for svc in sddm gdm lightdm lxdm ly; do
        if systemctl is-enabled --quiet "$svc" 2> /dev/null; then
            echo " disabling ${svc}"
            sudo systemctl disable "$svc" 2>> "$log_file"
        fi
    done

    sudo cp -b "$DOTFILES/system/etc/ly/config.ini" /etc/ly/ 2>> "$log_file"

    # on a re-run (or a machine where ly already runs on another tty) don't enable a second ly
    enabled_ly=$(compgen -G "/etc/systemd/system/*.wants/ly@tty*.service")
    if [[ -n $enabled_ly ]]; then
        echo "ly already enabled ($(basename "$enabled_ly" .service)); leaving it as is."
    else
        sudo systemctl mask "getty@tty${LY_TTY}" 2>> "$log_file"
        if sudo systemctl enable "ly@tty${LY_TTY}" 2>> "$log_file"; then
            echo "ly enabled on tty${LY_TTY}; it starts after a reboot."
        else
            sudo systemctl unmask "getty@tty${LY_TTY}" 2>> "$log_file"
            sudo systemctl enable "getty@tty${LY_TTY}" 2>> "$log_file"
            echo "ly could not be enabled; tty${LY_TTY} left as a normal login."
        fi
    fi
else
    echo "ly installation failed"
fi

#caps2esc
if sudo mkdir -p /etc/interception/udevmon.d/ 2>> "$log_file" \
    && sudo cp -b "$DOTFILES/system/etc/interception/udevmon.d/udevmon.yaml" /etc/interception/udevmon.d/ 2>> "$log_file" \
    && sudo systemctl enable --now udevmon 2>> "$log_file"; then
    echo "caps2esc setup successful"
else
    echo "caps2esc setup not successful"
fi

echo "Install these by hand:"
printf '  %s\n' "${manual_installs[@]}"
echo "Done. Errors (if any) are in $log_file. Reboot to start ly."

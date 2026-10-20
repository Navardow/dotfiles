# dotfiles

## Overview

_Dotfiles for my computers (pc and laptop, or any other computers I may acquire in the future)._
_Configuration subjected to frequent updates and changes, Documentation may not accurately reflect configuration files._

checkout: https://www.vardowill.com/projects/dotfiles

Arch Linux + [niri](https://github.com/YaLTeR/niri) (scrolling Wayland compositor), themed black/white
throughout: black backgrounds, white text, `#1a1a1a` boxes with a 1px `#3a3a3a` outline and 10px corners,
and [Material Symbols Rounded](https://fonts.google.com/icons) for every bar icon.

## Install

```sh
git clone --recurse-submodules git@github.com:NavardoW/dotfiles.git ~/.dotfiles
~/.dotfiles/setup.sh
```

Run `setup.sh` as your normal user (it uses sudo where needed), then reboot. It:

- installs every package the configs use (official repos, then AUR packages through `yay`, installing
  `yay` first if needed); already-installed packages are skipped, so it's safe to re-run
- fetches the `config/nvim` submodule
- links `config/` into `~/.config` and `home/` into `~` with [GNU stow](https://www.gnu.org/software/stow/)
- enables NetworkManager and bluetooth, hides blueman's tray icon (bluetooth is a waybar module)
- sets up ly as the login manager and caps lock → escape (`system/etc/`)
- prints the few tools that aren't packaged anywhere (basedpyright, kotlin-lsp) to install by hand

The clone must live at `~/.dotfiles`; a few configs reference that path.

## Layout

| Path | What |
| --- | --- |
| `config/` | stowed into `~/.config` |
| `home/` | stowed into `~` (`.bashrc`, `.gitconfig`, `.tmux.conf`, `.clang-format`, `.claude/`) |
| `system/etc/` | copied into `/etc` by `setup.sh` (ly, caps2esc) |
| `setup.sh` | package list and system setup; kept in sync with the configs |

## What's in it

| | |
| --- | --- |
| **niri** | named workspaces per monitor; Firefox, Discord (fullscreen), Spotify and terminals open on their own workspace; floating waypaper and monitor windows |
| **waybar** | workspaces · clock (calendar on hover) + Spotify · tray box (app icons, notifications, bluetooth, wifi, volume) · stats box (cpu, memory, temperature) · battery |
| **popups** | volume slider and Spotify player (album art, seek bar, controls) dropping down from the bar (`config/waybar/scripts/`) |
| **notifications** | mako, with a notification center in the bar (history list, do-not-disturb) |
| **launchers / menus** | fuzzel for apps, wifi (networkmanager-dmenu), bluetooth and the notification list |
| **lock screen** | hyprlock over the current wallpaper; the password box only appears while typing (swaylock as a fallback) |
| **wallpaper** | waypaper + swaybg, restored at login straight through swaybg |
| **other** | alacritty, tmux, mako, GTK settings (Adwaita, Papirus-Dark icons), neovim (submodule, via bob) |
| **claude code** | global rules (`CLAUDE.md`) and `settings.json`. In every mode: never commits or stages (`git add`/`commit`/`stage`/`rm`/`mv` denied) and file edits (`Edit`/`Write`) ask first. Manual mode (the default): read-only commands (`ls`, `cat`, `grep`, `git status`/`diff`/`log`, ...) run without asking, everything else asks, and a hook (`hooks/block-shell-writes.sh`) also asks before commands that write files or hide other commands (`>`, `sed -i`, `tee`, `$(...)`, ...). Auto mode: the hook is skipped, so shell commands follow auto mode's normal rules |

### Bar clicks

| Module | Left | Right | Middle / scroll |
| --- | --- | --- | --- |
| clock | toggle date | month/year calendar | reset / page calendar |
| spotify | player popup | next track | play-pause / change track |
| notifications | history list | do not disturb | clear |
| bluetooth | device manager | blueman menu | |
| wifi | wifi picker | up/down speed | |
| volume | volume popup | pavucontrol | mute / volume |
| cpu, memory | htop | detailed view | |
| temperature | sensors | | |
| battery | time remaining | | |

### Keys

| Key | Action |
| --- | --- |
| `Mod+T` | terminal (alacritty) |
| `Mod+D` | app launcher (fuzzel) |
| `Mod+P` | wallpaper picker (waypaper) |
| `Super+Alt+L` | lock screen |

## Per-machine notes

- waypaper rewrites `config/waypaper/config.ini` every time you pick a wallpaper, so `setup.sh` marks it
  `skip-worktree` to keep that out of git. This is stored in each clone, not in the repo, so on a clone
  where `setup.sh` hasn't run, set it by hand: `git update-index --skip-worktree config/waypaper/config.ini`.
  To commit a real change to the file: `git update-index --no-skip-worktree config/waypaper/config.ini`,
  `git add -p` just that change, commit, then set `--skip-worktree` again.
- Spotify is launched with `--disable-gpu-compositing` (`config/spotify-launcher.conf`). Workaround for
  blank window on Wayland + NVIDIA; may not be needed on other setups.
- The temperature module reads the AMD `k10temp` sensor and falls back to Intel `coretemp` (first path
  that exists wins).
- Only `settings.json`, `CLAUDE.md` and the hook are linked into `~/.claude`; the rest of it (sessions,
  credentials) stays out of the repo, which is why `setup.sh` creates `~/.claude/hooks` before stowing.
  Claude Code can replace `~/.claude/settings.json` with a real file when it saves settings (e.g. `/config`);
  if `ls -l ~/.claude/settings.json` no longer points into `~/.dotfiles`, move it back over
  `home/.claude/settings.json` and re-run `stow -R home -d ~/.dotfiles -t ~`.
- The Claude Code hook needs `jq` (installed by `setup.sh`). Without it the hook can't read the command
  and lets everything through silently, so in manual mode shell writes (`>`, `sed -i`, `tee`, ...) stop
  asking; the `deny`/`ask` rules in `settings.json` still apply.
- If a safe, read-only command keeps prompting in Claude Code, add it to `permissions.allow` in
  `home/.claude/settings.json`. Leave out commands that can write or run other commands (`find`, `sed`,
  `awk`, `sort`, `env`, `xargs`); those should keep asking.
- After pulling on another machine, re-run `setup.sh`. It's safe to re-run and picks up new packages, new
  config folders (stow) and the settings above.

#!/bin/bash
# Toggle the floating monitor window for a waybar stats module: sysmon.sh cpu|mem|temp

case $1 in
    cpu)  cmd=(htop -s PERCENT_CPU) ;;
    mem)  cmd=(htop -s PERCENT_MEM) ;;
    temp) cmd=(watch -n 1 sensors) ;;
    *)    exit 1 ;;
esac
args=(alacritty --class "sysmon-$1" -e "${cmd[@]}")

# exact full-command match, so nothing else that mentions it gets killed
pkill -xf -- "${args[*]}" && exit
niri msg action spawn -- "${args[@]}"

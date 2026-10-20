#!/bin/bash
# Restart waybar. Spawned through niri so it isn't tied to the shell running this script.

pkill -x waybar
while pgrep -x waybar >/dev/null; do sleep 0.1; done

niri msg action spawn -- waybar

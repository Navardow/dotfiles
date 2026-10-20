#!/usr/bin/env python3
# Show blueman-applet's tray menu (its tray icon is disabled) as a fuzzel list and run the pick.
# Items with a submenu, like "Reconnect to…", open a second list.

import re
import subprocess

from gi.repository import Gio

# Exit would stop the applet (and pairing prompts with it)
SKIP = {"Exit", "Help"}

applet = Gio.DBusProxy.new_for_bus_sync(
    Gio.BusType.SESSION, Gio.DBusProxyFlags.NONE, None,
    "org.blueman.Applet", "/org/blueman/Applet", "org.blueman.Applet", None)


def label(item):
    # strip pango markup and mnemonic underscores: "<b>Turn Bluetooth _On</b>" -> "Turn Bluetooth On"
    return re.sub(r"<[^>]+>", "", item.get("text", "")).replace("_", "")


def pick(items, prompt):
    items = [i for i in items if i.get("sensitive") and label(i) and label(i) not in SKIP]
    choice = subprocess.run(["fuzzel", "--dmenu", "--index", "--prompt", prompt],
                            input="\n".join(label(i) for i in items), text=True,
                            capture_output=True).stdout.strip()
    return items[int(choice)] if choice.lstrip("-").isdigit() and int(choice) >= 0 else None


item = pick(applet.GetMenu(), "Bluetooth: ")
if item:
    path = [item["id"]]
    if item.get("submenu"):
        sub = pick(item["submenu"], f"{label(item)} ")
        path = [item["id"], sub["id"]] if sub else None
    if path:
        applet.ActivateMenuItem("(ai)", path)

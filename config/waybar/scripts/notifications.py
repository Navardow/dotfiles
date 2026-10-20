#!/usr/bin/env python3
# Notification center for waybar, on top of mako's history.
#   notifications.py status   waybar custom module output (json)
#   notifications.py list     show notifications in fuzzel and mark them read
#   notifications.py clear    hide everything shown so far
#   notifications.py dnd      toggle do-not-disturb

import json
import os
import subprocess
import sys

# mako has no way to clear its history, so we remember the newest read/cleared id ourselves.
# mako restarts ids at 1, so the marker is tied to mako's pid.
STATE = f"{os.environ.get('XDG_RUNTIME_DIR', '/tmp')}/notification-center.json"
WAYBAR_SIGNAL = 9
# Material Symbols Rounded ligatures (filled, weight 500), 12pt (16px) like the tray icons
BELL = "<span font='Material Symbols Rounded 12 @FILL=1,wght=500'>notifications</span>"
BELL_OFF = "<span font='Material Symbols Rounded 12 @FILL=1,wght=500'>notifications_off</span>"
DND = "do-not-disturb"


def makoctl(*args):
    return subprocess.run(["makoctl", *args], capture_output=True, text=True).stdout


def mako_pid():
    return subprocess.run(["pgrep", "-x", "mako"], capture_output=True, text=True).stdout.strip()


def load_state():
    try:
        with open(STATE) as f:
            state = json.load(f)
        if state["pid"] == mako_pid():
            return state
    except (OSError, ValueError, KeyError):
        pass
    return {"pid": mako_pid(), "seen": 0, "cleared": 0}


def save_state(state):
    with open(STATE, "w") as f:
        json.dump(state, f)
    subprocess.run(["pkill", f"-RTMIN+{WAYBAR_SIGNAL}", "-x", "waybar"])


def notifications(state):
    # on screen + expired, newest first, minus anything cleared
    shown = json.loads(makoctl("list", "-j") or "[]") + json.loads(makoctl("history", "-j") or "[]")
    return sorted((n for n in shown if n["id"] > state["cleared"]), key=lambda n: -n["id"])


def one_line(n):
    text = f"{n['app_name']} · {n['summary']}"
    if n["body"]:
        text += f" — {n['body']}"
    return " ".join(text.split())


def status(state):
    items = notifications(state)
    unread = sum(n["id"] > state["seen"] for n in items)
    if DND in makoctl("mode").split():
        out = {"text": BELL_OFF, "tooltip": "Do not disturb", "class": "dnd"}
    else:
        out = {"text": f"{BELL} {unread}" if unread else BELL,
               "tooltip": f"{unread} unread · {len(items)} total", "class": "unread" if unread else ""}
    print(json.dumps(out, ensure_ascii=False))


def show_list(state):
    items = notifications(state)
    if items:
        state["seen"] = max(state["seen"], items[0]["id"])
        save_state(state)
    lines = [one_line(n) for n in items] or ["No notifications"]
    subprocess.run(["fuzzel", "--dmenu", "--prompt", "Notifications: ", "--width", "60"],
                   input="\n".join(lines), text=True, capture_output=True)


def clear(state):
    items = notifications(state)
    if items:
        state["seen"] = state["cleared"] = items[0]["id"]
    save_state(state)


if __name__ == "__main__":
    state = load_state()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        status(state)
    elif cmd == "list":
        show_list(state)
    elif cmd == "clear":
        clear(state)
    elif cmd == "dnd":
        makoctl("mode", "-t", DND)
        save_state(state)

# Shared base for the waybar dropdowns (volume-popup.py, spotify-popup.py): a card under the bar
# that fades in/out, stays open while hovered, and is toggled with `<script> toggle` (SIGUSR1).

import os
import re
import signal
import subprocess
import sys

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import GLib, GLibUnix, Gdk, Gtk, GtkLayerShell as Layer  # noqa: E402

CSS = b"""
window { background: transparent; }
.card { background: #000000; color: #ffffff; border-radius: 10px;
        padding: 8px 14px; opacity: 0; transition: opacity 250ms ease; }
.card.visible { opacity: 1; }
* { outline: none; }
.dim { color: #aaaaaa; }
button { background: none; border: none; box-shadow: none; padding: 0; }
trough { min-height: 6px; border-radius: 5px; background-color: #000000; border: 1px solid #2a2a2a; }
highlight { border-radius: 5px; background-color: #ffffff; border: none; }
slider { min-width: 12px; min-height: 12px; border-radius: 6px; background: #ffffff;
         border: none; box-shadow: none; }
"""


def icon(name, size=13.5):
    # Material Symbols Rounded ligature, same style as the bar icons
    return f"<span font='Material Symbols Rounded {size} @FILL=1,wght=500'>{name}</span>"


class Popup:
    def __init__(self, margin_right=None, orientation=Gtk.Orientation.HORIZONTAL):
        """margin_right: distance from the right screen edge; None centers the card under the bar."""
        self.win = Gtk.Window()
        self.win.set_visual(self.win.get_screen().get_rgba_visual())
        Layer.init_for_window(self.win)
        Layer.set_layer(self.win, Layer.Layer.OVERLAY)
        Layer.set_anchor(self.win, Layer.Edge.TOP, True)
        Layer.set_margin(self.win, Layer.Edge.TOP, 6)
        if margin_right is not None:
            Layer.set_anchor(self.win, Layer.Edge.RIGHT, True)
            Layer.set_margin(self.win, Layer.Edge.RIGHT, margin_right)

        self.card = Gtk.Box(orientation=orientation, spacing=10)
        self.card.get_style_context().add_class("card")
        self.win.add(self.card)

        # hovering keeps it open; leaving closes it shortly after
        self.hovered = False
        self.hide_timer = None
        self.win.connect("enter-notify-event", lambda *_: self.set_hover(True))
        self.win.connect("leave-notify-event", self.on_leave)

    def on_leave(self, _w, event):
        if event.detail != Gdk.NotifyType.INFERIOR:
            self.set_hover(False)

    def set_hover(self, hovered):
        self.hovered = hovered
        self.schedule_hide(None if hovered else 400)

    def schedule_hide(self, ms):
        if self.hide_timer:
            GLib.source_remove(self.hide_timer)
        self.hide_timer = GLib.timeout_add(ms, self.hide) if ms else None

    def visible(self):
        return self.card.get_style_context().has_class("visible")

    def show(self, hide_after):
        self.win.show_all()
        GLib.idle_add(self.card.get_style_context().add_class, "visible")
        if not self.hovered:
            self.schedule_hide(hide_after)

    def hide(self):
        self.hide_timer = None
        self.card.get_style_context().remove_class("visible")
        GLib.timeout_add(250, self.unmap_if_hidden)  # after the fade-out
        return False

    def unmap_if_hidden(self):
        if not self.visible():
            self.win.hide()
        return False

    def toggle(self):
        if self.visible():
            self.hide()
        else:
            self.show(2500)  # closes again if the mouse never reaches it
        return True

    def cleanup(self):
        pass


def daemon_pids():
    # the daemon's command line ends in the script name; `toggle` invocations don't
    script = re.escape(os.path.basename(sys.argv[0]))
    out = subprocess.run(["pgrep", "-f", rf"{script}$"], capture_output=True, text=True).stdout
    return [int(pid) for pid in out.split() if int(pid) != os.getpid()]


def run(popup_class):
    """Entry point: `toggle` signals the running daemon, otherwise start one (once)."""
    if sys.argv[1:] == ["toggle"]:
        for pid in daemon_pids():
            os.kill(pid, signal.SIGUSR1)
        sys.exit()
    if daemon_pids():
        sys.exit(f"{os.path.basename(sys.argv[0])} is already running")

    css = Gtk.CssProvider()
    css.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, 600)
    popup = popup_class()
    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, popup.toggle)
    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, Gtk.main_quit)
    Gtk.main()
    popup.cleanup()

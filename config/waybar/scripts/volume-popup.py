#!/usr/bin/env python3
# Volume dropdown for waybar. Run once at startup; `volume-popup.py toggle` opens/closes it.
# Volume changes show it briefly as an OSD.

import re
import subprocess

from popup import GLib, Gtk, Popup, icon, run

SINK = "@DEFAULT_AUDIO_SINK@"
MARGIN_RIGHT = 120  # distance from the right screen edge, roughly under the bar icon


def get_volume():
    out = subprocess.run(["wpctl", "get-volume", SINK], capture_output=True, text=True).stdout
    m = re.search(r"Volume: ([\d.]+)", out)
    return (round(float(m.group(1)) * 100) if m else 0), "[MUTED]" in out


def volume_icon(vol, muted):
    # same icons as waybar's pulseaudio module
    return icon("volume_off" if muted or vol == 0 else "volume_mute" if vol < 34
                else "volume_down" if vol < 67 else "volume_up")


class VolumePopup(Popup):
    def __init__(self):
        super().__init__(margin_right=MARGIN_RIGHT)
        self.icon = Gtk.Label()
        mute = Gtk.Button(child=self.icon)
        mute.connect("clicked", lambda _: subprocess.Popen(["wpctl", "set-mute", SINK, "toggle"]))
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale.set_draw_value(False)
        self.scale.set_size_request(180, -1)
        self.scale_handler = self.scale.connect("value-changed", self.on_scale)
        self.label = Gtk.Label(width_chars=4, xalign=1)
        for w in (mute, self.scale, self.label):
            self.card.pack_start(w, False, False, 0)

        self.vol = self.muted = None
        self.update()
        self.watch()

    def watch(self):
        self.sub = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE,
                                    stderr=subprocess.DEVNULL, text=True)
        GLib.io_add_watch(self.sub.stdout, GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP, self.on_event)

    def on_event(self, source, cond):
        if cond & GLib.IO_HUP:  # pipewire restarted; resubscribe
            GLib.timeout_add(1000, self.watch)
            return False
        line = source.readline()
        if ("on sink" in line or "on server" in line) and self.update():
            self.show(1500)
        return True

    def update(self):
        vol, muted = get_volume()
        if (vol, muted) == (self.vol, self.muted):
            return False
        self.vol, self.muted = vol, muted
        self.icon.set_markup(volume_icon(vol, muted))
        self.label.set_text(f"{vol}%")
        with self.scale.handler_block(self.scale_handler):
            self.scale.set_value(min(vol, 100))
        return True

    def on_scale(self, scale):
        subprocess.Popen(["wpctl", "set-volume", SINK, f"{scale.get_value() / 100:.2f}"])

    def cleanup(self):
        self.sub.terminate()


if __name__ == "__main__":
    run(VolumePopup)

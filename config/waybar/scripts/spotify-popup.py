#!/usr/bin/env python3
# Spotify dropdown for waybar: album art, title/artist, seek bar and prev / play-pause / next.
# Run once at startup; `spotify-popup.py toggle` opens/closes it (waybar mpris on-click).

import threading
import urllib.request

import gi

gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Pango", "1.0")
gi.require_version("Playerctl", "2.0")
from gi.repository import GdkPixbuf, Pango, Playerctl  # noqa: E402

from popup import GLib, Gtk, Popup, icon, run  # noqa: E402

PLAYER = "spotify"
ART_SIZE = 64


def fmt_time(us):
    s = int(us // 1_000_000)
    return f"{s // 60}:{s % 60:02d}"


def metadata(player, key):
    value = player.props.metadata.lookup_value(key, None) if player else None
    return value.unpack() if value is not None else None


class SpotifyPopup(Popup):
    def __init__(self):
        # no margin: centered under the bar, below the clock and the mpris module
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.card.set_size_request(320, -1)

        self.art = Gtk.Image()
        self.title = Gtk.Label(xalign=0, max_width_chars=26, ellipsize=Pango.EllipsizeMode.END)
        self.artist = Gtk.Label(xalign=0, max_width_chars=26, ellipsize=Pango.EllipsizeMode.END)
        self.artist.get_style_context().add_class("dim")
        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2, valign=Gtk.Align.CENTER)
        text.pack_start(self.title, False, False, 0)
        text.pack_start(self.artist, False, False, 0)
        top = Gtk.Box(spacing=12)
        top.pack_start(self.art, False, False, 0)
        top.pack_start(text, True, True, 0)

        self.position = Gtk.Label(width_chars=5, xalign=0)
        self.length = Gtk.Label(width_chars=5, xalign=1)
        for label in (self.position, self.length):
            label.get_style_context().add_class("dim")
        self.seek = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 1, 1)
        self.seek.set_draw_value(False)
        # change-value only fires for user drags/clicks, not for tick()'s set_value
        self.seek.connect("change-value", self.on_seek)
        seek_row = Gtk.Box(spacing=8)
        seek_row.pack_start(self.position, False, False, 0)
        seek_row.pack_start(self.seek, True, True, 0)
        seek_row.pack_start(self.length, False, False, 0)

        self.play = Gtk.Label()
        controls = Gtk.Box(spacing=28, halign=Gtk.Align.CENTER)
        for name, action in (("skip_previous", "previous"), (None, "play_pause"), ("skip_next", "next")):
            label = self.play if name is None else Gtk.Label()
            if name:
                label.set_markup(icon(name, 16))
            button = Gtk.Button(child=label)
            button.connect("clicked", lambda _, a=action: self.player and getattr(self.player, a)())
            controls.pack_start(button, False, False, 0)

        for w in (top, seek_row, controls):
            self.card.pack_start(w, False, False, 0)

        self.player = None
        self.handlers = []
        self.art_url = None
        self.manager = Playerctl.PlayerManager()
        self.manager.connect("name-appeared", lambda *_: self.attach())
        self.manager.connect("name-vanished", lambda *_: self.attach())
        self.attach()
        GLib.timeout_add(1000, self.tick)

    def attach(self):
        """(Re)connect to Spotify's current player. Spotify's player object can go stale (it then
        reports no title, e.g. after toggling "show video"), so this also runs on every open."""
        for handler in self.handlers:
            self.player.disconnect(handler)
        self.handlers = []
        name = next((n for n in self.manager.props.player_names if n.name == PLAYER), None)
        self.player = Playerctl.Player.new_from_name(name) if name else None
        if self.player:
            self.handlers = [self.player.connect(signal, lambda *_: self.refresh())
                             for signal in ("metadata", "playback-status")]
        self.refresh()

    def refresh(self):
        p = self.player
        if p:
            self.title.set_text(p.get_title() or "Nothing playing")
            self.artist.set_text(p.get_artist() or "")
        else:
            self.title.set_text("Spotify isn't running")
            self.artist.set_text("")
        length = metadata(p, "mpris:length") or 0
        self.seek.set_range(0, max(length / 1_000_000, 1))
        self.length.set_text(fmt_time(length))
        playing = p is not None and p.props.playback_status == Playerctl.PlaybackStatus.PLAYING
        self.play.set_markup(icon("pause" if playing else "play_arrow", 18))
        self.load_art(metadata(p, "mpris:artUrl"))
        self.tick()

    def tick(self):
        position = 0
        if self.player:
            try:
                position = self.player.get_position()
            except GLib.Error:
                pass
        self.seek.set_value(position / 1_000_000)
        self.position.set_text(fmt_time(position))
        return True

    def on_seek(self, _scale, _scroll, value):
        if self.player:
            self.player.set_position(int(value * 1_000_000))
        return False

    def load_art(self, url):
        if url == self.art_url:
            return
        self.art_url = url
        self.art.clear()  # don't keep the previous track's art if this one fails to load
        if not url:
            return

        def fetch():
            try:
                data = urllib.request.urlopen(url, timeout=5).read()
            except (OSError, ValueError):
                return
            GLib.idle_add(self.set_art, url, data)

        threading.Thread(target=fetch, daemon=True).start()

    def set_art(self, url, data):
        if url != self.art_url:  # the track changed while downloading
            return False
        try:
            loader = GdkPixbuf.PixbufLoader()
            loader.write(data)
            loader.close()
            pixbuf = loader.get_pixbuf().scale_simple(ART_SIZE, ART_SIZE, GdkPixbuf.InterpType.BILINEAR)
            self.art.set_from_pixbuf(pixbuf)
        except GLib.Error:
            self.art.clear()
        return False

    def show(self, hide_after):
        self.attach()  # also updates the position, so nothing stale flashes up
        super().show(hide_after)


if __name__ == "__main__":
    run(SpotifyPopup)

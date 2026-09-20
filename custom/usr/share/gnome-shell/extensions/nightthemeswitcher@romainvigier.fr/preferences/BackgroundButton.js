// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Adw from "gi://Adw";
import Gdk from "gi://Gdk";
import GdkPixbuf from "gi://GdkPixbuf";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import GObject from "gi://GObject";
import Gtk from "gi://Gtk";

import { gettext as _ } from "resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js";

Gio._promisify(Gtk.FileDialog.prototype, "open", "open_finish");

export class BackgroundButton extends Gtk.Button {
  #uri;

  static {
    GObject.registerClass(
      {
        GTypeName: "BackgroundButton",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/BackgroundButton.ui",
        InternalChildren: ["file_dialog", "thumbnail"],
        Properties: {
          uri: GObject.ParamSpec.string("uri", "URI", "URI to the background file", GObject.ParamFlags.READWRITE, null),
          thumbWidth: GObject.ParamSpec.int(
            "thumb-width",
            "Thumbnail width",
            "Width of the displayed thumbnail",
            GObject.ParamFlags.READWRITE,
            0,
            600,
            180,
          ),
          thumbHeight: GObject.ParamSpec.int(
            "thumb-height",
            "Thumbnail height",
            "Height of the displayed thumbnail",
            GObject.ParamFlags.READWRITE,
            0,
            600,
            180,
          ),
        },
      },
      this,
    );
  }

  constructor({ ...params } = {}) {
    super(params);
    this.#setupSize();
    this.#setupDropTarget();
    this.#setupFileDialog();
  }

  get uri() {
    return this.#uri || null;
  }

  set uri(uri) {
    if (uri === this.#uri) return;
    this.#uri = uri;
    this.notify("uri");
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
      this.#updateThumbnail();
      return GLib.SOURCE_REMOVE;
    });
  }

  #setupSize() {
    const display = Gdk.Display.get_default();
    const monitor = display.get_monitors().get_item(0);
    if (monitor.width_mm === 0 || monitor.height_mm === 0) return;
    if (monitor.width_mm > monitor.height_mm) this.thumbHeight *= monitor.height_mm / monitor.width_mm;
    else this.thumbWidth *= monitor.width_mm / monitor.height_mm;
  }

  #setupDropTarget() {
    const dropTarget = Gtk.DropTarget.new(Gio.File.$gtype, Gdk.DragAction.COPY);
    dropTarget.connect("drop", (_target, file, _x, _y) => {
      const contentType = Gio.content_type_guess(file.get_basename(), null)[0];
      if (this.#isContentTypeSupported(contentType)) {
        this.uri = file.get_uri();
        return true;
      } else {
        if (this.root instanceof Adw.PreferencesWindow) {
          this.root.add_toast(
            new Adw.Toast({
              title: _("This image format is not supported."),
              timeout: 10,
            }),
          );
        }
        return false;
      }
    });
    this.add_controller(dropTarget);
  }

  #setupFileDialog() {
    const filter = new Gtk.FileFilter();
    filter.set_name(_("Image files"));
    this.#getSupportedContentTypes().forEach((type) => filter.add_mime_type(type));
    this._file_dialog.filters = Gio.ListStore.new(Gtk.FileFilter);
    this._file_dialog.filters.append(filter);
  }

  #getSupportedContentTypes() {
    return GdkPixbuf.Pixbuf.get_formats()
      .flatMap((format) => format.get_mime_types())
      .concat("application/xml");
  }

  #isContentTypeSupported(contentType) {
    for (const supportedContentType of this.#getSupportedContentTypes()) {
      if (Gio.content_type_equals(contentType, supportedContentType)) return true;
    }
    return false;
  }

  vfunc_mnemonic_activate() {
    this.#setURIFromFileDialog();
  }

  onClicked(_button) {
    this.#setURIFromFileDialog();
  }

  async #setURIFromFileDialog() {
    try {
      const file = await this._file_dialog.open(this.get_root(), null);
      this.uri = file.get_uri();
    } catch {}
  }

  #updateThumbnail() {
    this._thumbnail.paintable = null;

    if (!this.uri) return;

    const file = Gio.File.new_for_uri(this.uri);
    const contentType = Gio.content_type_guess(file.get_basename(), null)[0];

    if (!this.#isContentTypeSupported(contentType)) return;

    let path;
    if (Gio.content_type_equals(contentType, "application/xml")) {
      const decoder = new TextDecoder("utf-8");
      const contents = decoder.decode(file.load_contents(null)[1]);
      try {
        path = contents.match(/<file>(.+)<\/file>/m)[1];
        if (!this.#isContentTypeSupported(Gio.content_type_guess(path, null)[0])) throw new Error();
      } catch (e) {
        console.error(`No suitable background file found in ${file.get_path()}.\n${e}`);
        return;
      }
    } else {
      path = file.get_path();
    }

    const pixbuf = GdkPixbuf.Pixbuf.new_from_file(path);
    const scale =
      pixbuf.width / pixbuf.height > this.thumbWidth / this.thumbHeight
        ? this.thumbHeight / pixbuf.height
        : this.thumbWidth / pixbuf.width;
    const thumbPixbuf = GdkPixbuf.Pixbuf.new(
      pixbuf.colorspace,
      pixbuf.has_alpha,
      pixbuf.bits_per_sample,
      this.thumbWidth,
      this.thumbHeight,
    );
    pixbuf.scale(
      thumbPixbuf,
      0,
      0,
      this.thumbWidth,
      this.thumbHeight,
      -(pixbuf.width * scale - this.thumbWidth) / 2,
      -(pixbuf.height * scale - this.thumbHeight) / 2,
      scale,
      scale,
      GdkPixbuf.InterpType.TILES,
    );

    this._thumbnail.paintable = Gdk.Texture.new_for_pixbuf(thumbPixbuf);
  }
}

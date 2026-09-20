// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Adw from "gi://Adw";
import Gio from "gi://Gio";
import GObject from "gi://GObject";

export class BackgroundsPage extends Adw.PreferencesPage {
  static {
    GObject.registerClass(
      {
        GTypeName: "BackgroundsPage",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/BackgroundsPage.ui",
        InternalChildren: ["day_button", "night_button"],
      },
      this,
    );
  }

  constructor({ ...params } = {}) {
    super(params);
    const settings = new Gio.Settings({ schema: "org.gnome.desktop.background" });

    settings.bind("picture-uri", this._day_button, "uri", Gio.SettingsBindFlags.DEFAULT);
    settings.bind("picture-uri-dark", this._night_button, "uri", Gio.SettingsBindFlags.DEFAULT);
  }
}

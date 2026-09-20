// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Adw from "gi://Adw";
import Gio from "gi://Gio";
import GObject from "gi://GObject";

export class CommandsPage extends Adw.PreferencesPage {
  static {
    GObject.registerClass(
      {
        GTypeName: "CommandsPage",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/CommandsPage.ui",
        InternalChildren: ["enabled_switch", "sunrise_entry", "sunset_entry"],
      },
      this,
    );
  }

  constructor({ settings, ...params } = {}) {
    super(params);

    settings.bind("enabled", this._enabled_switch, "active", Gio.SettingsBindFlags.DEFAULT);
    settings.bind("sunrise", this._sunrise_entry, "text", Gio.SettingsBindFlags.DEFAULT);
    settings.bind("sunset", this._sunset_entry, "text", Gio.SettingsBindFlags.DEFAULT);
  }
}

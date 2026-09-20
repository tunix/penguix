// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Adw from "gi://Adw";
import Gio from "gi://Gio";
import GObject from "gi://GObject";

export class SchedulePage extends Adw.PreferencesPage {
  static {
    GObject.registerClass(
      {
        GTypeName: "SchedulePage",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/SchedulePage.ui",
        InternalChildren: [
          "manual_schedule_switch",
          "keyboard_shortcut_button",
          "schedule_sunrise_time_chooser",
          "schedule_sunset_time_chooser",
          "schedule_offset_spin_button",
          "fullscreen_transition_switch",
        ],
      },
      this,
    );
  }

  constructor({ settings, ...params } = {}) {
    super(params);

    settings.bind("manual-schedule", this._manual_schedule_switch, "active", Gio.SettingsBindFlags.DEFAULT);

    settings.bind("sunrise", this._schedule_sunrise_time_chooser, "time", Gio.SettingsBindFlags.DEFAULT);
    settings.bind("sunset", this._schedule_sunset_time_chooser, "time", Gio.SettingsBindFlags.DEFAULT);

    settings.bind("offset", this._schedule_offset_spin_button, "value", Gio.SettingsBindFlags.DEFAULT);

    settings.bind("fullscreen-transition", this._fullscreen_transition_switch, "active", Gio.SettingsBindFlags.DEFAULT);

    settings.connect("changed::nightthemeswitcher-ondemand-keybinding", () => {
      this._keyboard_shortcut_button.keybinding = settings.get_strv("nightthemeswitcher-ondemand-keybinding")[0];
    });
    this._keyboard_shortcut_button.connect("notify::keybinding", () => {
      settings.set_strv("nightthemeswitcher-ondemand-keybinding", [this._keyboard_shortcut_button.keybinding]);
    });
    this._keyboard_shortcut_button.keybinding = settings.get_strv("nightthemeswitcher-ondemand-keybinding")[0];
  }
}

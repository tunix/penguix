// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import GDesktopEnums from "gi://GDesktopEnums";
import Gio from "gi://Gio";
import GObject from "gi://GObject";
import Gtk from "gi://Gtk";

export class TimeChooser extends Gtk.Widget {
  #clockFormat;
  #interfaceSettings;

  static {
    GObject.registerClass(
      {
        GTypeName: "TimeChooser",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/TimeChooser.ui",
        InternalChildren: [
          "clock_format_stack",
          "hours_12",
          "minutes_12",
          "hours_24",
          "minutes_24",
          "am_toggle_button",
          "pm_toggle_button",
        ],
        Properties: {
          time: GObject.ParamSpec.double(
            "time",
            "Time",
            "The time of the chooser",
            GObject.ParamFlags.READWRITE,
            0,
            24,
            0,
          ),
        },
      },
      this,
    );
  }

  constructor({ ...params } = {}) {
    super(params);
    this.#interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
    this.#interfaceSettings.connect("changed::clock-format", this.#onClockFormatChanged.bind(this));
    this.#onClockFormatChanged();
  }

  #onClockFormatChanged(_settings) {
    this.#clockFormat = this.#interfaceSettings.get_enum("clock-format");
    this.#syncClockFormatStack();
  }

  #syncClockFormatStack() {
    this._clock_format_stack.set_visible_child_name(
      this.#clockFormat === GDesktopEnums.ClockFormat["12H"] ? "12h" : "24h",
    );
  }

  #convertTimeTo24hFormat(time) {
    const hours = Math.trunc(time);
    const minutes = Math.round((time - hours) * 60);
    return { hours, minutes };
  }

  #convertTimeTo12hFormat(time) {
    const { hours: hours24, minutes } = this.#convertTimeTo24hFormat(time);
    const hours = hours24 === 0 ? 12 : hours24 % 12;
    const isPm = hours24 >= 12;
    return { hours, minutes, isPm };
  }

  #convert24hFormatToTime({ hours, minutes }) {
    return hours + minutes / 60;
  }

  #convert12hFormatToTime({ hours, minutes, isPm }) {
    let hours24 = hours + Number(isPm) * 12;
    if (hours === 12) hours24 = isPm ? 12 : 0;
    return this.#convert24hFormatToTime({ hours: hours24, minutes });
  }

  onTimeChanged(_chooser) {
    const time = this.time;

    const clock12 = this.#convertTimeTo12hFormat(time);
    this._hours_12.value = clock12.hours;
    this._minutes_12.value = clock12.minutes;
    this._am_toggle_button.active = !clock12.isPm;
    this._pm_toggle_button.active = clock12.isPm;

    const clock24 = this.#convertTimeTo24hFormat(time);
    this._hours_24.value = clock24.hours;
    this._minutes_24.value = clock24.minutes;
  }

  onValueChanged(_widget) {
    this.time =
      this.#clockFormat === GDesktopEnums.ClockFormat["12H"]
        ? this.#convert12hFormatToTime({
            hours: this._hours_12.value,
            minutes: this._minutes_12.value,
            isPm: this._pm_toggle_button.active,
          })
        : this.#convert24hFormatToTime({ hours: this._hours_24.value, minutes: this._minutes_24.value });
  }

  onOutputChanged(spin) {
    spin.text = spin.value.toString().padStart(2, "0");
    return true;
  }
}

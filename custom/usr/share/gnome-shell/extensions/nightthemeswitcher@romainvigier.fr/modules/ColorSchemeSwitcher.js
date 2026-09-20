// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Gio from "gi://Gio";

import * as debug from "../debug.js";

import { Time } from "../enums/Time.js";

import { Switcher } from "./Switcher.js";

/**
 * The Color Scheme Switcher changes the system color scheme according to the time.
 */
export class ColorSchemeSwitcher extends Switcher {
  #settings;
  #interfaceSettings;
  #timer;

  #settingsConnections = [];

  /**
   * @param {object} params Params object.
   * @param {import("./Timer.js").Timer} params.timer Timer to listen to.
   */
  constructor({ timer }) {
    const settings = NTS.getSettings(`${NTS.metadata["settings-schema"]}.color-scheme`);
    super({
      name: "Color Scheme",
      timer,
      settings,
      callback: (time) => this.#onTimeChanged(time),
    });
    this.#timer = timer;
    this.#settings = settings;
    this.#interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
  }

  enable() {
    super.enable();
    this.#connectSettings();
  }

  disable() {
    super.disable();
    this.#disconnectSettings();
  }

  #connectSettings() {
    debug.message("Connecting Color Scheme Switcher to settings...");
    this.#settingsConnections.push({
      settings: this.#settings,
      id: this.#settings.connect("changed::day", this.#onColorSchemeChanged.bind(this)),
    });
    this.#settingsConnections.push({
      settings: this.#settings,
      id: this.#settings.connect("changed::night", this.#onColorSchemeChanged.bind(this)),
    });
    this.#settingsConnections.push({
      settings: this.#interfaceSettings,
      id: this.#interfaceSettings.connect("changed::color-scheme", this.#onSystemColorSchemeChanged.bind(this)),
    });
  }

  #disconnectSettings() {
    this.#settingsConnections.forEach(({ settings, id }) => settings.disconnect(id));
    this.#settingsConnections = [];
    debug.message("Disconnected Color Scheme Switcher from settings.");
  }

  #onTimeChanged(time) {
    const colorScheme = time === Time.NIGHT ? this.#settings.get_string("night") : this.#settings.get_string("day");
    this.#interfaceSettings.set_string("color-scheme", colorScheme);
  }

  #onColorSchemeChanged(_settings, time) {
    const colorScheme = this.#settings.get_string(time);
    debug.message(`${time} color scheme changed to ${colorScheme}.`);
    if (time === this.#timer.time) this.#interfaceSettings.set_string("color-scheme", colorScheme);
  }

  #onSystemColorSchemeChanged() {
    const colorScheme = this.#interfaceSettings.get_string("color-scheme");
    debug.message(`System color scheme changed to ${colorScheme}.`);
    this.#timer.syncTimeToColorScheme(colorScheme);
  }
}

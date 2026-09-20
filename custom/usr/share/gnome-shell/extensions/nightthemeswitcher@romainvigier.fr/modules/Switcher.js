// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import * as debug from "../debug.js";

/**
 * Function called when the time changes.
 * @callback TimeChangedCallback
 * @param {import("../enums/Time.js").Time} time New time.
 */

/**
 * The Switcher runs a callback function when the time changes.
 *
 */
export class Switcher {
  #name;
  #timer;
  #settings;
  #callback;
  #disableable;

  #statusConnection = null;
  #timerConnection = null;

  /**
   * @param {object} params Params object.
   * @param {string} params.name Name of the switcher.
   * @param {import("./Timer.js").Timer} params.timer Timer to listen to.
   * @param {import("gi://Gio").default.Settings} params.settings Settings.
   * @param {TimeChangedCallback} params.callback Callback function.
   * @param {boolean} params.disableable If the switcher can be disabled using an `enabled` key in the settings.
   */
  constructor({ name, timer, settings, callback, disableable = false }) {
    this.#name = name;
    this.#timer = timer;
    this.#settings = settings;
    this.#callback = callback;
    this.#disableable = disableable;
  }

  enable() {
    debug.message(`Enabling ${this.#name} switcher...`);
    if (this.#disableable) this.#watchStatus();
    if (!this.#disableable || this.#settings.get_boolean("enabled")) {
      this.#connectTimer();
      this.#onTimeChanged();
    }
    debug.message(`${this.#name} switcher enabled.`);
  }

  disable() {
    debug.message(`Disabling ${this.#name} switcher...`);
    this.#disconnectTimer();
    if (this.#disableable) this.#unwatchStatus();
    debug.message(`${this.#name} switcher disabled.`);
  }

  #watchStatus() {
    debug.message(`Watching ${this.#name} switching status...`);
    this.#statusConnection = this.#settings.connect("changed::enabled", this.#onStatusChanged.bind(this));
  }

  #unwatchStatus() {
    if (this.#statusConnection) {
      this.#settings.disconnect(this.#statusConnection);
      this.#statusConnection = null;
    }
    debug.message(`Stopped watching ${this.#name} switching status.`);
  }

  #connectTimer() {
    debug.message(`Connecting ${this.#name} switcher to Timer...`);
    this.#timerConnection = this.#timer.connect("notify::time", this.#onTimeChanged.bind(this));
  }

  #disconnectTimer() {
    if (this.#timerConnection) {
      this.#timer.disconnect(this.#timerConnection);
      this.#timerConnection = null;
    }
    debug.message(`Disconnected ${this.#name} switcher from Timer.`);
  }

  #onStatusChanged() {
    debug.message(
      `${this.#name} switching has been ${this.#settings.get_boolean("enabled") ? "enabled" : "disabled"}.`,
    );
    this.disable();
    this.enable();
  }

  #onTimeChanged() {
    this.#callback(this.#timer.time);
  }
}

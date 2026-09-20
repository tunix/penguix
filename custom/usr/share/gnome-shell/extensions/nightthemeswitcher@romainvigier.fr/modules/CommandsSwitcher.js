// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import GLib from "gi://GLib";

import * as debug from "../debug.js";

import { Time } from "../enums/Time.js";

import { Switcher } from "./Switcher.js";

/**
 * The Commands Switcher spawns commands according to the time.
 */
export class CommandsSwitcher extends Switcher {
  #settings;

  /**
   * @param {object} params Params object.
   * @param {import("./Timer.js").Timer} params.timer Timer to listen to.
   */
  constructor({ timer }) {
    const settings = NTS.getSettings(`${NTS.metadata["settings-schema"]}.commands`);
    super({
      name: "Command",
      timer,
      settings,
      callback: (time) => this.#onTimeChanged(time),
      disableable: true,
    });
    this.#settings = settings;
  }

  #onTimeChanged(time) {
    if (time === Time.UNKNOWN) return;
    const command = this.#settings.get_string(time === Time.DAY ? "sunrise" : "sunset");
    if (!command) return;
    GLib.spawn_async(null, ["sh", "-c", command], null, GLib.SpawnFlags.SEARCH_PATH, null);
    debug.message(`Spawned ${time} command.`);
  }
}

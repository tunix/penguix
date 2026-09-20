// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

"use strict";

import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";

import * as debug from "./debug.js";

import { ColorSchemeSwitcher } from "./modules/ColorSchemeSwitcher.js";
import { CommandsSwitcher } from "./modules/CommandsSwitcher.js";
import { Timer } from "./modules/Timer.js";

export default class NightThemeSwitcher extends Extension {
  #modules = [];

  enable() {
    globalThis.NTS = this;

    debug.message("Enabling extension...");

    const timer = new Timer();

    [timer, new ColorSchemeSwitcher({ timer }), new CommandsSwitcher({ timer })].forEach((module) =>
      this.#modules.push(module),
    );

    this.#modules.forEach((module) => module.enable());

    debug.message("Extension enabled.");
  }

  disable() {
    // Extension won't be disabled in `unlock-dialog` session mode. This is
    // to enable the color scheme switch while the lock screen is displayed,
    // as the background image and the shell theme are visible in this mode.
    debug.message("Disabling extension...");

    this.#modules.forEach((module) => module.disable());
    this.#modules = [];

    debug.message("Extension disabled.");

    delete globalThis.NTS;
  }
}

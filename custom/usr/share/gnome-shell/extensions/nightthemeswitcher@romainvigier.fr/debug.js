// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/**
 * Print a message in debug builds.
 * @param {string} msg Message to print.
 */
export function message(msg) {
  if (NTS.metadata["build-type"] === "debug") console.log(`[${NTS.metadata.name}] ${msg}`);
}

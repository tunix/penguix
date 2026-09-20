// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Adw from "gi://Adw";
import GObject from "gi://GObject";

export class ContributePage extends Adw.PreferencesPage {
  static {
    GObject.registerClass(
      {
        GTypeName: "ContributePage",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/ContributePage.ui",
      },
      this,
    );
  }
}

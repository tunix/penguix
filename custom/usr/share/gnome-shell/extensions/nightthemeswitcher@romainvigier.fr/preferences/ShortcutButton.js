// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Gdk from "gi://Gdk";
import GObject from "gi://GObject";
import Gtk from "gi://Gtk";

export class ShortcutButton extends Gtk.Stack {
  static {
    GObject.registerClass(
      {
        GTypeName: "ShortcutButton",
        Template: "resource:///org/gnome/Shell/Extensions/nightthemeswitcher/preferences/ui/ShortcutButton.ui",
        InternalChildren: ["choose_button", "change_button", "clear_button", "dialog"],
        Properties: {
          keybinding: GObject.ParamSpec.string(
            "keybinding",
            "Keybinding",
            "Key sequence",
            GObject.ParamFlags.READWRITE,
            null,
          ),
        },
      },
      this,
    );
  }

  vfunc_mnemonic_activate() {
    this.activate();
  }

  activate() {
    if (this.keybinding) return this._change_button.activate();
    else return this._choose_button.activate();
  }

  openDialog() {
    this._dialog.transient_for = this.get_root();
    this._dialog.present();
  }

  onKeybindingChanged(button) {
    button.visible_child_name = button.keybinding ? "edit" : "choose";
  }

  onChooseButtonClicked(_button) {
    this.openDialog();
  }

  onChangeButtonClicked(_button) {
    this.openDialog();
  }

  onClearButtonClicked(_button) {
    this.keybinding = "";
  }

  onKeyPressed(_widget, keyval, keycode, state) {
    let mask = state & Gtk.accelerator_get_default_mod_mask();
    mask &= ~Gdk.ModifierType.LOCK_MASK;

    if (mask === 0 && keyval === Gdk.KEY_Escape) {
      this._dialog.close();
      return Gdk.EVENT_STOP;
    }

    if (!isBindingValid({ mask, keycode, keyval }) || !isAccelValid({ mask, keyval })) return Gdk.EVENT_STOP;

    this.keybinding = Gtk.accelerator_name_with_keycode(null, keyval, keycode, mask);
    this._dialog.close();
    return Gdk.EVENT_STOP;
  }
}

/**
 * Check if the given keyval is forbidden.
 * @param {number} keyval The keyval number.
 * @returns {boolean} `true` if the keyval is forbidden.
 */
function isKeyvalForbidden(keyval) {
  const forbiddenKeyvals = [
    Gdk.KEY_Home,
    Gdk.KEY_Left,
    Gdk.KEY_Up,
    Gdk.KEY_Right,
    Gdk.KEY_Down,
    Gdk.KEY_Page_Up,
    Gdk.KEY_Page_Down,
    Gdk.KEY_End,
    Gdk.KEY_Tab,
    Gdk.KEY_KP_Enter,
    Gdk.KEY_Return,
    Gdk.KEY_Mode_switch,
  ];
  return forbiddenKeyvals.includes(keyval);
}

/**
 * Check if the given key combo is a valid binding
 * @param {{mask: number, keycode: number, keyval:number}} combo An object
 * representing the key combo.
 * @returns {boolean} `true` if the key combo is a valid binding.
 */
function isBindingValid({ mask, keycode, keyval }) {
  if ((mask === 0 || mask === Gdk.ModifierType.SHIFT_MASK) && keycode !== 0) {
    if (
      (keyval >= Gdk.KEY_a && keyval <= Gdk.KEY_z) ||
      (keyval >= Gdk.KEY_A && keyval <= Gdk.KEY_Z) ||
      (keyval >= Gdk.KEY_0 && keyval <= Gdk.KEY_9) ||
      (keyval >= Gdk.KEY_kana_fullstop && keyval <= Gdk.KEY_semivoicedsound) ||
      (keyval >= Gdk.KEY_Arabic_comma && keyval <= Gdk.KEY_Arabic_sukun) ||
      (keyval >= Gdk.KEY_Serbian_dje && keyval <= Gdk.KEY_Cyrillic_HARDSIGN) ||
      (keyval >= Gdk.KEY_Greek_ALPHAaccent && keyval <= Gdk.KEY_Greek_omega) ||
      (keyval >= Gdk.KEY_hebrew_doublelowline && keyval <= Gdk.KEY_hebrew_taf) ||
      (keyval >= Gdk.KEY_Thai_kokai && keyval <= Gdk.KEY_Thai_lekkao) ||
      (keyval >= Gdk.KEY_Hangul_Kiyeog && keyval <= Gdk.KEY_Hangul_J_YeorinHieuh) ||
      (keyval === Gdk.KEY_space && mask === 0) ||
      isKeyvalForbidden(keyval)
    )
      return false;
  }
  return true;
}

/**
 * Check if the given key combo is a valid accelerator.
 * @param {{mask: number, keyval:number}} combo An object representing the key
 * combo.
 * @returns {boolean} `true` if the key combo is a valid accelerator.
 */
function isAccelValid({ mask, keyval }) {
  return Gtk.accelerator_valid(keyval, mask) || (keyval === Gdk.KEY_Tab && mask !== 0);
}

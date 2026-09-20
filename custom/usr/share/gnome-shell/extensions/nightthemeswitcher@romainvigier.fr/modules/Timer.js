// SPDX-FileCopyrightText: Night Theme Switcher Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

import Geoclue from "gi://Geoclue";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import GObject from "gi://GObject";
import Meta from "gi://Meta";
import Shell from "gi://Shell";

import { gettext as _ } from "resource:///org/gnome/shell/extensions/extension.js";
import { layoutManager, messageTray, wm } from "resource:///org/gnome/shell/ui/main.js";
import * as MessageTray from "resource:///org/gnome/shell/ui/messageTray.js";

import * as debug from "../debug.js";

import { ColorScheme } from "../enums/ColorScheme.js";
import { Time } from "../enums/Time.js";

/**
 * The Timer is responsible for signaling any time change to the other modules.
 *
 * They can connect to its 'time' property and query it for the current time.
 *
 * It will try to use the current location as a time source but will fall back
 * to a manual schedule if the location services are disabled or if the user
 * forced the manual schedule in the preferences.
 */
export class Timer extends GObject.Object {
  #settings;
  #colorSchemeSettings;
  #interfaceSettings;
  #locationSettings;
  /** @type {Time | undefined} */
  #time;

  #cancellable = null;
  #previousKeybinding = null;
  #timeTimeoutId = null;
  #geoclue = null;
  #geoclueLocationConnectionId = null;
  #suntimesTimeoutId = null;
  #manuallySetTime = false;

  #settingsConnections = [];

  static {
    GObject.registerClass(
      {
        Properties: {
          time: GObject.ParamSpec.string("time", "Time", "Time", GObject.ParamFlags.READWRITE, Time.UNKNOWN),
        },
      },
      this,
    );
  }

  constructor() {
    super();
    this.#settings = NTS.getSettings(`${NTS.metadata["settings-schema"]}.time`);
    this.#colorSchemeSettings = NTS.getSettings(`${NTS.metadata["settings-schema"]}.color-scheme`);
    this.#interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
    this.#locationSettings = new Gio.Settings({ schema: "org.gnome.system.location" });
  }

  enable() {
    debug.message("Enabling Timer...");
    this.#cancellable = new Gio.Cancellable();
    this.#connectSettings();
    this.#trackTime();
    if (this.#settings.get_boolean("manual-schedule")) {
      debug.message("Using the manual schedule.");
    } else {
      debug.message("Using location.");
      this.#trackLocation();
      this.#trackSuntimes();
    }
    this.#addKeybinding();
    this.#changeTime(this.#computeTime());
    debug.message("Timer enabled.");
  }

  disable() {
    debug.message("Disabling Timer...");
    this.#removeKeybinding();
    this.#untrackSuntimes();
    this.#untrackLocation();
    this.#untrackTime();
    this.#disconnectSettings();
    this.#cancellable.cancel();
    debug.message("Timer disabled.");
  }

  /**
   * @param {ColorScheme} colorScheme Color scheme to sync the time to.
   */
  syncTimeToColorScheme(colorScheme) {
    this.#changeTime(this.#colorSchemeToTime(colorScheme), true);
  }

  get time() {
    return this.#time || Time.UNKNOWN;
  }

  #changeTime(time, manual = false) {
    if (time === this.#time) {
      if (!manual && this.#manuallySetTime) this.#manuallySetTime = false;
      return;
    }

    if (!manual && time !== this.#time && this.#manuallySetTime) return;

    this.#time = time;
    this.#manuallySetTime = manual;

    debug.message(manual ? `Time manually set to ${time}.` : `Time changed to ${time}.`);

    const isMonitorFullscreen = layoutManager.monitors.some((monitor) => monitor.inFullscreen);
    if (this.#settings.get_boolean("fullscreen-transition") || !isMonitorFullscreen) {
      try {
        layoutManager.screenTransition.run();
      } catch {}
    }

    this.notify("time");
  }

  #connectSettings() {
    debug.message("Connecting Timer to settings...");
    this.#settingsConnections.push({
      settings: this.#locationSettings,
      id: this.#locationSettings.connect("changed::enabled", this.#onLocationStateChanged.bind(this)),
    });
    this.#settingsConnections.push({
      settings: this.#settings,
      id: this.#settings.connect("changed::manual-schedule", this.#onManualScheduleStateChanged.bind(this)),
    });
    this.#settingsConnections.push({
      settings: this.#settings,
      id: this.#settings.connect(
        "changed::nightthemeswitcher-ondemand-keybinding",
        this.#onOndemandKeybindingChanged.bind(this),
      ),
    });
    // Only listen to the offset setting when not using a manual schedule
    if (!this.#settings.get_boolean("manual-schedule")) {
      this.#settingsConnections.push({
        settings: this.#settings,
        id: this.#settings.connect("changed::offset", this.#onOffsetChanged.bind(this)),
      });
    }
  }

  #disconnectSettings() {
    this.#settingsConnections.forEach(({ settings, id }) => settings.disconnect(id));
    this.#settingsConnections = [];
    debug.message("Disconnected Timer from settings.");
  }

  #trackTime() {
    debug.message("Watching for time change...");
    this.#timeTimeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
      this.#changeTime(this.#computeTime());
      return GLib.SOURCE_CONTINUE;
    });
  }

  #untrackTime() {
    if (this.#timeTimeoutId) {
      GLib.Source.remove(this.#timeTimeoutId);
      this.#timeTimeoutId = null;
    }
    debug.message("Stopped watching for time change.");
  }

  #trackLocation() {
    debug.message("Connecting to GeoClue...");
    Geoclue.Simple.new(
      "org.gnome.Shell",
      Geoclue.AccuracyLevel.CITY,
      this.#cancellable,
      this.#onGeoclueReady.bind(this),
    );
  }

  #untrackLocation() {
    debug.message("Disconnecting from GeoClue...");
    if (this.#geoclue && this.#geoclueLocationConnectionId) {
      this.#geoclue.disconnect(this.#geoclueLocationConnectionId);
      this.#geoclueLocationConnectionId = null;
      this.#geoclue = null;
    }
    debug.message("Disconnected from GeoClue.");
  }

  #trackSuntimes() {
    debug.message("Regularly updating sun times...");
    this.#suntimesTimeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 3600, () => {
      this.#updateSuntimes();
      return GLib.SOURCE_CONTINUE;
    });
  }

  #untrackSuntimes() {
    if (this.#suntimesTimeoutId) {
      GLib.Source.remove(this.#suntimesTimeoutId);
      this.#suntimesTimeoutId = null;
    }
    debug.message("Stopped regularly updating sun times.");
  }

  #addKeybinding() {
    this.#previousKeybinding = this.#settings.get_strv("nightthemeswitcher-ondemand-keybinding")[0];
    if (!this.#settings.get_strv("nightthemeswitcher-ondemand-keybinding")[0]) return;
    debug.message("Adding keybinding...");
    wm.addKeybinding(
      "nightthemeswitcher-ondemand-keybinding",
      this.#settings,
      Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
      Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
      () => {
        const time = this.time === Time.NIGHT ? Time.DAY : Time.NIGHT;
        this.#changeTime(time, true);
      },
    );
    debug.message("Added keybinding.");
  }

  #removeKeybinding() {
    if (this.#previousKeybinding) {
      debug.message("Removing keybinding...");
      wm.removeKeybinding("nightthemeswitcher-ondemand-keybinding");
      debug.message("Removed keybinding.");
    }
  }

  #colorSchemeToTime(colorScheme) {
    return colorScheme === this.#colorSchemeSettings.get_string("night") ? Time.NIGHT : Time.DAY;
  }

  #onLocationStateChanged() {
    this.disable();
    this.enable();
  }

  #onManualScheduleStateChanged() {
    this.disable();
    this.enable();
  }

  #onOffsetChanged() {
    this.#updateSuntimes();
  }

  #onOndemandKeybindingChanged() {
    this.#removeKeybinding();
    this.#addKeybinding();
  }

  #onGeoclueReady(_geoclue, result) {
    try {
      this.#geoclue = Geoclue.Simple.new_finish(result);
      this.#geoclueLocationConnectionId = this.#geoclue.connect("notify::location", this.#onLocationChanged.bind(this));
      debug.message("Connected to GeoClue.");
      this.#onLocationChanged();
    } catch (e) {
      const [latitude, longitude] = this.#settings.get_value("location").deepUnpack();
      if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) {
        console.error(
          `[${NTS.metadata.name}] Unable to retrieve the location, using the last known location instead.\n${e}`,
        );
        this.#updateSuntimes();
      } else {
        console.error(
          `[${NTS.metadata.name}] Unable to retrieve the location, using the manual schedule times instead.\n${e}`,
        );

        const source = new MessageTray.Source({
          title: NTS.metadata.name,
          icon: Gio.icon_new_for_string(
            GLib.build_filenamev([NTS.metadata.path, "icons", "nightthemeswitcher-symbolic.svg"]),
          ),
        });
        messageTray.add(source);

        const notification = new MessageTray.Notification({
          source,
          title: _("Unknown Location"),
          body: _("A manual schedule will be used to switch the dark mode."),
          "icon-name": "location-services-disabled-symbolic",
        });
        notification.addAction(_("Edit Manual Schedule"), () => NTS.openPreferences());

        notification.connect("activated", () => NTS.openPreferences());

        source.addNotification(notification);

        this.#settings.set_boolean("manual-schedule", true);
      }
    }
  }

  #onLocationChanged(_geoclue, _location) {
    debug.message("Location has changed.");
    const { latitude, longitude } = this.#geoclue.get_location();
    this.#settings.set_value("location", new GLib.Variant("(dd)", [latitude, longitude]));
    debug.message(`Current location: (${latitude};${longitude})`);
    this.#updateSuntimes();
  }

  #computeTime() {
    const sunrise = this.#settings.get_double("sunrise");
    const sunset = this.#settings.get_double("sunset");
    const datetime = GLib.DateTime.new_now_local();
    const hour = datetime.get_hour() + datetime.get_minute() / 60 + datetime.get_second() / 3600;

    // Regular schedule
    if (sunrise < sunset) return hour >= sunrise && hour < sunset ? Time.DAY : Time.NIGHT;
    // Sunset happens on the day after
    else if (sunrise > sunset) return hour >= sunrise || hour < sunset ? Time.DAY : Time.NIGHT;
    // Sunset and Sunrise times are identical; preserve current theme
    else return this.#time || this.#colorSchemeToTime(this.#interfaceSettings.get_string("color-scheme"));
  }

  #updateSuntimes() {
    const [latitude, longitude] = this.#settings.get_value("location").deepUnpack();

    if (latitude < -90 && latitude > 90 && longitude < -180 && longitude > 180) return;

    debug.message("Updating sun times...");

    const rad = (degrees) => (degrees * Math.PI) / 180;
    const deg = (radians) => (radians * 180) / Math.PI;

    // Calculations from https://www.esrl.noaa.gov/gmd/grad/solcalc/calcdetails.html
    const dtNow = GLib.DateTime.new_now_local();
    const dtZero = GLib.DateTime.new_utc(1900, 1, 1, 0, 0, 0);

    const timeSpan = dtNow.difference(dtZero);

    const date = timeSpan / 1000 / 1000 / 60 / 60 / 24 + 2;
    const tzOffset = dtNow.get_utc_offset() / 1000 / 1000 / 60 / 60;

    const julianDay = date + 2415018.5 - tzOffset / 24;
    const julianCentury = (julianDay - 2451545) / 36525;
    const geomMeanLongSun = (280.46646 + julianCentury * (36000.76983 + julianCentury * 0.0003032)) % 360;
    const geomMeanAnomSun = 357.52911 + julianCentury * (35999.05029 - 0.0001537 * julianCentury);
    const eccentEarthOrbit = 0.016708634 - julianCentury * (0.000042037 + 0.0000001267 * julianCentury);
    const sunEqOfCtr =
      Math.sin(rad(geomMeanAnomSun)) * (1.914602 - julianCentury * (0.004817 + 0.000014 * julianCentury)) +
      Math.sin(rad(2 * geomMeanAnomSun)) * (0.019993 - 0.000101 * julianCentury) +
      Math.sin(rad(3 * geomMeanAnomSun)) * 0.000289;
    const sunTrueLong = geomMeanLongSun + sunEqOfCtr;
    const sunAppLong = sunTrueLong - 0.00569 - 0.00478 * Math.sin(rad(125.04 - 1934.136 * julianCentury));
    const meanObliqEcliptic =
      23 + (26 + (21.448 - julianCentury * (46.815 + julianCentury * (0.00059 - julianCentury * 0.001813))) / 60) / 60;
    const obliqCorr = meanObliqEcliptic + 0.00256 * Math.cos(rad(125.04 - 1934.136 * julianCentury));
    const sunDeclin = deg(Math.asin(Math.sin(rad(obliqCorr)) * Math.sin(rad(sunAppLong))));
    const varY = Math.tan(rad(obliqCorr / 2)) * Math.tan(rad(obliqCorr / 2));
    const eqOfTime =
      4 *
      deg(
        varY * Math.sin(2 * rad(geomMeanLongSun)) -
          2 * eccentEarthOrbit * Math.sin(rad(geomMeanAnomSun)) +
          4 * eccentEarthOrbit * varY * Math.sin(rad(geomMeanAnomSun)) * Math.cos(2 * rad(geomMeanLongSun)) -
          0.5 * varY * varY * Math.sin(4 * rad(geomMeanLongSun)) -
          1.25 * eccentEarthOrbit * eccentEarthOrbit * Math.sin(2 * rad(geomMeanAnomSun)),
      );
    const haSunrise = deg(
      Math.acos(
        Math.cos(rad(90.833)) / (Math.cos(rad(latitude)) * Math.cos(rad(sunDeclin))) -
          Math.tan(rad(latitude)) * Math.tan(rad(sunDeclin)),
      ),
    );
    const solarNoon = (720 - 4 * longitude - eqOfTime + tzOffset * 60) / 1440;

    const timeSunrise = solarNoon - (haSunrise * 4) / 1440;
    const timeSunset = solarNoon + (haSunrise * 4) / 1440;

    const modulo = (n, m) => ((n % m) + m) % m;

    const offset = this.#settings.get_double("offset");
    const sunrise = modulo(timeSunrise * 24 + offset, 24);
    const sunset = modulo(timeSunset * 24 - offset, 24);

    this.#settings.set_double("sunrise", sunrise);
    this.#settings.set_double("sunset", sunset);

    debug.message(`New sun times: (sunrise: ${sunrise}; sunset: ${sunset})`);
  }
}

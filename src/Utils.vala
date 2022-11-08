// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Marvin Beckers <beckersmarvin@gmail.com>
 */

namespace Utils {
    public static string gen_hostname (string pretty_hostname) {
        string hostname = "";
        bool met_alpha = false;
        bool whitespace_before = false;

        foreach (char c in pretty_hostname.to_ascii ().to_utf8 ()) {
            if (c.isalpha ()) {
                hostname += c.to_string ();
                met_alpha = true;
                whitespace_before = false;
            } else if (c.isdigit () && met_alpha) {
                hostname += c.to_string ();
                whitespace_before = false;
            } else if (c.isspace () && !whitespace_before) {
                hostname += "-";
                whitespace_before = true;
            }
        }

        return hostname;
    }

    [DBus (name = "org.freedesktop.hostname1")]
    interface HostnameInterface : Object {
        public abstract string pretty_hostname { owned get; }
        public abstract string static_hostname { owned get; }

        public abstract void set_pretty_hostname (string hostname, bool interactive) throws GLib.Error;
        public abstract void set_static_hostname (string hostname, bool interactive) throws GLib.Error;
    }

    private static HostnameInterface? hostname_interface_instance;
    private static void get_hostname_interface_instance () {
        if (hostname_interface_instance == null) {
            try {
                hostname_interface_instance = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.hostname1",
                    "/org/freedesktop/hostname1"
                );
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }

    public static string get_hostname () {
        get_hostname_interface_instance ();

        string hostname = hostname_interface_instance.pretty_hostname;

        if (hostname.length == 0) {
            hostname = hostname_interface_instance.static_hostname;
        }

        return hostname;
    }

    public static bool set_hostname (string hostname) {
        string? primary_text = null;
        string secondary_text = _("Initial Setup could not set your hostname.");
        string? error_message = null;

        try {
            var permission = new Polkit.Permission.sync ("org.freedesktop.hostname1.set-static-hostname", new Polkit.UnixProcess (Posix.getpid ()));

            if (permission != null && permission.allowed) {
                get_hostname_interface_instance ();
                hostname_interface_instance.set_pretty_hostname (hostname, false);
                hostname_interface_instance.set_static_hostname (gen_hostname (hostname), false);
            } else {
                primary_text = _("No Permission to set hostname '%s'").printf (hostname);
            }
        } catch (GLib.Error e) {
            primary_text = _("Unable to set Hostname '%s'").printf (hostname);
            error_message = e.message;
        }

        if (primary_text != null) {
            var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                primary_text,
                secondary_text,
                "dialog-error",
                Gtk.ButtonsType.CLOSE
            );

            if (error_message != null) {
                error_dialog.show_error_details (error_message);
            }


            error_dialog.run ();
            error_dialog.destroy ();

            return false;
        }

        return true;
    }
}

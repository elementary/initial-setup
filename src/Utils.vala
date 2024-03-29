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
            } else if ((c.isdigit () || c == '-') && met_alpha) {
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
        public abstract string hostname { owned get; }
        public abstract string pretty_hostname { owned get; }
        public abstract string static_hostname { owned get; }

        public abstract async void set_pretty_hostname (string hostname, bool interactive) throws GLib.Error;
        public abstract async void set_static_hostname (string hostname, bool interactive) throws GLib.Error;

        [DBus (visible = false)]
        public string get_either_hostname () {
            if (pretty_hostname.length > 0) {
                return pretty_hostname;
            } else {
                return static_hostname;
            }
        }

        public static async HostnameInterface? get_default () throws GLib.Error {
            return yield Bus.get_proxy (
                BusType.SYSTEM,
                "org.freedesktop.hostname1",
                "/org/freedesktop/hostname1"
            );
        }
    }
}

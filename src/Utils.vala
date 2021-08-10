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
    private static Act.UserManager? usermanager = null;

    public static unowned Act.UserManager? get_usermanager () {
        if (usermanager != null && usermanager.is_loaded) {
            return usermanager;
        }

        usermanager = Act.UserManager.get_default ();
        return usermanager;
    }

    private static Polkit.Permission? permission = null;

    public static Polkit.Permission? get_permission () {
        if (permission != null)
            return permission;
        try {
            permission = new Polkit.Permission.sync ("org.freedesktop.accounts.user-administration", new Polkit.UnixProcess (Posix.getpid ()));
            return permission;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }

    public static Act.User? create_new_user (string fullname, string username, string password) {
        var permission = get_permission ();

        string? primary_text = null;
        string? error_message = null;
        string secondary_text = _("Initial Setup could not create your user. Without it, you will not be able to log in and may need to reinstall the OS.");

        if (permission != null && permission.allowed) {
            try {
                var user_manager = get_usermanager ();
                if (user_manager != null) {
                    var created_user = user_manager.create_user (username, fullname, Act.UserAccountType.ADMINISTRATOR);
                    created_user.set_password (password, "");

                    return created_user;
                }
            } catch (Error e) {
                primary_text = _("Creating User '%s' Failed").printf (username);
                error_message = e.message;
            }
        } else {
            primary_text = _("No Permission to Create User '%s'").printf (username);
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
        }

        return null;
    }

    public static bool is_taken_username (string username) {
        foreach (unowned Act.User user in get_usermanager ().list_users ()) {
            if (user.get_user_name () == username) {
                return true;
            }
        }
        return false;
    }

    public static bool is_valid_username (string username) {
        try {
            if (new Regex ("^[a-z]+[a-z0-9]*$").match (username)) {
                return true;
            }
            return false;
        } catch (Error e) {
            critical (e.message);
            return false;
        }
    }

    public static string gen_username (string fullname) {
        string username = "";
        bool met_alpha = false;

        foreach (char c in fullname.to_ascii ().to_utf8 ()) {
            if (c.isalpha ()) {
                username += c.to_string ().down ();
                met_alpha = true;
            } else if (c.isdigit () && met_alpha) {
                username += c.to_string ();
            }
        }

        return username;
    }

    public static string gen_hostname (string pretty_hostname) {
        string hostname = "";
        bool met_alpha = false;
        bool whitespace_before = false;

        foreach (char c in pretty_hostname.to_ascii ().to_utf8 ()) {
            if (c.isalpha ()) {
                hostname += c.to_string ().down ();
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
        try {
            get_hostname_interface_instance ();
            hostname_interface_instance.set_pretty_hostname (hostname, false);
            hostname_interface_instance.set_static_hostname (gen_hostname (hostname), false);
        } catch (GLib.Error e) {
            string primary_text = _("Setting Hostname '%s' Failed").printf (hostname);
            string secondary_text = _("Initial Setup could not set your hostname.");
            string error_message = e.message;

            var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                primary_text,
                secondary_text,
                "dialog-error",
                Gtk.ButtonsType.CLOSE
            );

            error_dialog.show_error_details (error_message);

            error_dialog.run ();
            error_dialog.destroy ();

            return false;
        }

        return true;
    }
}

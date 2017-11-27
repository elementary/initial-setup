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
    private static string os_pretty_name;
    private static string get_pretty_name () {
        if (os_pretty_name == null) {
            os_pretty_name = _("Operating System");
            const string ETC_OS_RELEASE = "/etc/os-release";

            try {
                var data_stream = new DataInputStream (File.new_for_path (ETC_OS_RELEASE).read ());

                string line;
                while ((line = data_stream.read_line (null)) != null) {
                    var osrel_component = line.split ("=", 2);
                    if (osrel_component.length == 2 && osrel_component[0] == "PRETTY_NAME") {
                        os_pretty_name = osrel_component[1].replace ("\"", "");
                        break;
                    }
                }
            } catch (Error e) {
                warning ("Couldn't read os-release file: %s", e.message);
            }
        }
        return os_pretty_name;
    }

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
            permission = new Polkit.Permission.sync ("io.elementary.initial-setup", new Polkit.UnixProcess (Posix.getpid ()));
            return permission;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }

    public static void create_new_user (string fullname, string username, string password) {
        if (get_permission ().allowed) {
            try {
                var user_manager = get_usermanager ();
                var created_user = user_manager.create_user (username, fullname, Act.UserAccountType.ADMINISTRATOR);

                user_manager.user_added.connect ((user) => {
                    if (user == created_user) {
                        created_user.set_password (password, "");
                    }
                });
            } catch (Error e) {
                critical ("Creation of user '%s' failed".printf (username));
            }
        }
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
            if (new Regex("^[a-z]+[a-z0-9]*$").match (username)) {
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
}

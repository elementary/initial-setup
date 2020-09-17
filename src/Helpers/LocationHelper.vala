// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Pantheon Developers (http://launchpad.net/switchboard-plug-datetime)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class LocationHelper : GLib.Object {
    [DBus (name = "org.freedesktop.timedate1")]
    public interface DateTime1 : Object {
        public abstract string Timezone {public owned get;}
        public abstract bool LocalRTC {public get;}
        public abstract bool CanNTP {public get;}
        public abstract bool NTP {public get;}

        //usec_utc expects number of microseconds since 1 Jan 1970 UTC
        public abstract void set_time (int64 usec_utc, bool relative, bool user_interaction) throws GLib.Error;
        public abstract void set_timezone (string timezone, bool user_interaction) throws GLib.Error;
        public abstract void SetLocalRTC (bool local_rtc, bool fix_system, bool user_interaction) throws GLib.Error; //vala-lint=naming-convention
        public abstract void SetNTP (bool use_ntp, bool user_interaction) throws GLib.Error; //vala-lint=naming-convention
    }

    private static List<string> lines;
    private static LocationHelper? helper = null;

    public static LocationHelper get_default () {
        if (helper == null)
            helper = new LocationHelper ();
        return helper;
    }
    private LocationHelper () {
        var file = File.new_for_path ("/usr/share/zoneinfo/zone.tab");
        if (!file.query_exists ()) {
            critical ("/usr/share/zoneinfo/zone.tab doesn't exist !");
            return;
        }

        lines = new List<string> ();
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            while ((line = dis.read_line (null)) != null) {
                if (line.has_prefix ("#")) {
                    continue;
                }

                lines.append (line);
            }
        } catch (Error e) {
            critical (e.message);
        }
#if GENERATE
        generate_translation_template ();
#endif
    }

    public HashTable<string, string> get_timezones_from_continent (string continent) {
        var timezones = new HashTable<string, string> (str_hash, str_equal);
        foreach (var line in lines) {
            var items = line.split ("\t", 4);
            string value = items[2];
            if (value.has_prefix (continent) == false)
                continue;

            string tz_name_field;
            // Take the original English string if there is something wrong with the translation
            if (_(items[2]) == null || _(items[2]) == "") {
                tz_name_field = items[2];
            } else {
                tz_name_field = _(items[2]);
            }

            string city = tz_name_field.split ("/", 2)[1];
            if (city != null && city != "") {
                string key = format_city (city);
                if (items[3] != null && items[3] != "") {
                    if (items[3] != "mainland" && items[3] != "most locations" && _(items[3]) != key) {
                        key = "%s - %s".printf (key, format_city (_(items[3])));
                    }
                }

                timezones.set (key, value);
            }
        }

        return timezones;
    }

    public HashTable<string, string> get_locations () {
        var locations = new HashTable<string, string> (str_hash, str_equal);
        foreach (var line in lines) {
            var items = line.split ("\t", 4);
            string key = items[1];
            string value = items[2];
            locations.set (key, value);
        }

        return locations;
    }

    public static string format_city (string city) {
        return city.replace ("_", " ").replace ("/", ", ");
    }

#if GENERATE
    public void generate_translation_template () {
        var file = GLib.File.new_for_path (GLib.Environment.get_home_dir () + "/Translations.vala");
        try {
            var dos = new GLib.DataOutputStream (file.create (GLib.FileCreateFlags.REPLACE_DESTINATION));
            dos.put_string ("#if 0\n");
            foreach (var line in lines) {
                var items = line.split ("\t", 4);
                string key = items[2];
                string comment = items[3];
                dos.put_string ("///Translators: Secondary \"/\" and all \"_\" will be replaced by \", \" and \" \".\n");
                dos.put_string ("_(\""+ key + "\");\n");
                if (comment != null && comment != "") {
                    dos.put_string ("///Translators: Comment for Timezone %s\n".printf (key));
                    dos.put_string ("_(\""+ comment + "\");\n");
                }
            }
            dos.put_string ("#endif\n");
        } catch (Error e) {
            critical (e.message);
        }
    }
#endif
}

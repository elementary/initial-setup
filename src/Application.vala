/*-
 * Copyright 2016-2022 elementary, Inc. (https://elementary.io)
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
 */

public class Installer.App : Gtk.Application {
    construct {
        application_id = "io.elementary.installer";
        flags = ApplicationFlags.FLAGS_NONE;
        Intl.setlocale (LocaleCategory.ALL, "");
    }

    public override void startup () {
        base.startup ();

        Granite.init ();
    }

    public override void activate () {
        var window = new MainWindow () {
            default_height = 600,
            default_width = 850,
            deletable = false,
            icon_name = application_id,
            title = _("Create a User")
        };
        window.present ();
        add_window (window);
    }
}

public static int main (string[] args) {
    var application = new Installer.App ();
    return application.run (args);
}

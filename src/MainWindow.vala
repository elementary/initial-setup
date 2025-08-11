/*-
 * Copyright 2016-2020 elementary, Inc. (https://elementary.io)
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

public class Installer.MainWindow : Gtk.Window, PantheonWayland.ExtendedBehavior {
    private Adw.NavigationView navigationview;

    private AccountView account_view;
    private LanguageView language_view;
    private KeyboardLayoutView keyboard_layout_view;
    private NetworkView network_view;
    private uint orca_timeout_id = 0;

    construct {
        language_view = new LanguageView ();

        navigationview = new Adw.NavigationView ();
        navigationview.add (language_view);

        child = navigationview;
        titlebar = new Gtk.Label ("") { visible = false };

        language_view.next_step.connect (() => {
            // Don't prompt for screen reader if we're able to navigate without it
            if (orca_timeout_id != 0) {
                Source.remove (orca_timeout_id);
            }

            load_keyboard_view ();
        });

        var mediakeys_settings = new Settings ("org.gnome.settings-daemon.plugins.media-keys");
        var a11y_settings = new Settings ("org.gnome.desktop.a11y.applications");

        orca_timeout_id = Timeout.add_seconds (10, () => {
            orca_timeout_id = 0;

            if (a11y_settings.get_boolean ("screen-reader-enabled")) {
                return Source.REMOVE;
            }

            var shortcut_string = Granite.accel_to_string (
                mediakeys_settings.get_strv ("screenreader")[0]
            );

            // Espeak can't read ⌘
            shortcut_string = shortcut_string.replace ("⌘", "Super");

            var orca_prompt = "Screen reader can be turned on with the keyboard shorcut %s".printf (shortcut_string);

            try {
                Process.spawn_command_line_async ("espeak '%s'".printf (orca_prompt));
            } catch (SpawnError e) {
                critical ("Couldn't read Orca prompt: %s", e.message);
            }

            return Source.REMOVE;
        });

        child.realize.connect (() => {
            connect_to_shell ();
            if (display is Gdk.Wayland.Display) {
                make_centered ();
            } else {
                make_centered_x11 ();
            }
        });
    }

    private void make_centered_x11 () {
        var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var xdisplay = ((Gdk.X11.Display) display).get_xdisplay ();

            var window = ((Gdk.X11.Surface) get_surface ()).get_xid ();

            var prop = xdisplay.intern_atom ("_MUTTER_HINTS", false);

            var value = "centered=1";

            xdisplay.change_property (window, prop, X.XA_STRING, 8, 0, (uchar[]) value, value.length);
        }
    }

    /*
     * We need to load all the view after the language has being chosen and set.
     */
    private void load_keyboard_view () {
        keyboard_layout_view = new KeyboardLayoutView ();

        navigationview.push (keyboard_layout_view);

        keyboard_layout_view.next_step.connect (() => load_network_view ());
    }

    private void load_network_view () {
        if (!NetworkMonitor.get_default ().get_network_available ()) {
            network_view = new NetworkView ();

            navigationview.push (network_view);

            network_view.next_step.connect (load_account_view);
        } else {
            load_account_view ();
        }
    }

    private void load_account_view () {
        account_view = new AccountView ();

        navigationview.push (account_view);
    }
}

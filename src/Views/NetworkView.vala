/*
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
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
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class Installer.NetworkView : AbstractInstallerView {
    private NetworkMonitor network_monitor;
    private Gtk.Button skip_button;

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-system-network") {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Connect Network"));

        var details_label = new Gtk.Label (_("An Internet connection is required to receive updates, install new apps, and connect to online services")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        details_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var wireless_row = new ListRow (
            ///Translators: for RTL languages, the UI is flipped
            _("Choose a nearby wireless network from the network indicator in the top right."),
            "network-wireless-symbolic",
            "blue"
        );

        var wired_row = new ListRow (
            _("Connect a network cable"),
            "network-wired-symbolic",
            "orange"
        );

        var choice_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        choice_box.append (details_label);
        choice_box.append (wireless_row);
        choice_box.append (wired_row);

        title_area.append (image);
        title_area.append (title_label);

        content_area.append (choice_box);

        var back_button = new Gtk.Button.with_label (_("Back")) {
            width_request = 86
        };

        skip_button = new Gtk.Button.with_label (_("Skip"));
        skip_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.append (back_button);
        action_area.append (skip_button);

        back_button.clicked.connect (() => ((Adw.Leaflet) get_parent ()).navigate (Adw.NavigationDirection.BACK));
        skip_button.clicked.connect (() => (next_step ()));

        network_monitor = NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (update);
    }

    private void update () {
        if (network_monitor.get_network_available ()) {
            network_monitor.network_changed.disconnect (update);
            skip_button.label = _("Next");
            next_step ();
        }
    }

    private class ListRow : Gtk.Box {
        public ListRow (string description, string icon_name, string color) {
            var image = new Gtk.Image.from_icon_name (icon_name) {
                valign = Gtk.Align.START
            };
            image.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

            unowned var image_context = image.get_style_context ();
            image_context.add_class (Granite.STYLE_CLASS_ACCENT);
            image_context.add_class (color);

            var description_label = new Gtk.Label (description) {
                hexpand = true,
                max_width_chars = 1, // Make Gtk wrap, but not expand the window
                use_markup = true,
                wrap = true,
                xalign = 0
            };

            spacing = 12;
            append (image);
            append (description_label);
        }
    }
}

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
        var image = new Gtk.Image.from_icon_name ("network-wireless", Gtk.IconSize.DIALOG) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Connect Network")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var details_label = new Gtk.Label (_("An Internet connection is required to receive updates, install new apps, and connect to online services")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        details_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var wireless_image = new Gtk.Image.from_icon_name ("network-wireless-signal-excellent-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        unowned var wireless_image_context = wireless_image.get_style_context ();
        wireless_image_context.add_class (Granite.STYLE_CLASS_ACCENT);
        wireless_image_context.add_class ("blue");

        ///Translators: for RTL languages, the UI is flipped
        var wireless_label = new Gtk.Label (_("Choose a nearby wireless network from the network indicator in the top right.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var wired_image = new Gtk.Image.from_icon_name ("network-wired-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        unowned var wired_image_context = wired_image.get_style_context ();
        wired_image_context.add_class (Granite.STYLE_CLASS_ACCENT);
        wired_image_context.add_class ("orange");


        var wired_label = new Gtk.Label (_("Connect a network cable")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var choice_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 32,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        choice_grid.attach (details_label, 0, 0, 2);
        choice_grid.attach (wireless_image, 0, 1);
        choice_grid.attach (wireless_label, 1, 1);
        choice_grid.attach (wired_image, 0, 2);
        choice_grid.attach (wired_label, 1, 2);

        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (choice_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        skip_button = new Gtk.Button.with_label (_("Skip"));
        skip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (skip_button);

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (Hdy.NavigationDirection.BACK));
        skip_button.clicked.connect (() => (next_step ()));

        network_monitor = NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (update);

        show_all ();
    }

    private void update () {
        if (network_monitor.get_network_available ()) {
            network_monitor.network_changed.disconnect (update);
            skip_button.label = _("Next");
            next_step ();
        }
    }
}

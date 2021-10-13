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
    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-system-network", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Configure network")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Granite.HeaderLabel (_("Manage network devices and connectivity"));

        var network_info = new Gtk.Label (_("It looks like your device is not connected to any network. To use your device to its full potential, we recommend that you set up a network connection.")) {
            // Wrap without expanding the view
            max_width_chars = 0,
            margin_bottom = 18,
            wrap = true,
            xalign = 0
        };
        network_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var settings_link = new Gtk.LinkButton.with_label ("settings://network", _("Manage network devices…"));

        var form_grid = new Gtk.Grid () {
            row_spacing = 3,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        form_grid.attach (description_label, 0, 0);
        form_grid.attach (network_info, 0, 1);
        form_grid.attach (settings_link, 0, 2);

        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (form_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (Hdy.NavigationDirection.BACK));

        next_button.clicked.connect (() => {
            next_step ();
        });

        show_all ();
    }
}

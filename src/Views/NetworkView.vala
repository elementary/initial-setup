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
    private Gtk.Image image;
    private Gtk.Button next_button;
    private Granite.HeaderLabel description_label;
    private Gtk.Label network_info;

    construct {
        image = new Gtk.Image.from_icon_name ("network-offline", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Configure network")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        description_label = new Granite.HeaderLabel ("");

        network_info = new Gtk.Label ("") {
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

        var skip_button = new Gtk.Button.with_label (_("Skip"));

        next_button = new Gtk.Button.with_label (_("Next")) {
            sensitive = false
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (skip_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (Hdy.NavigationDirection.BACK));

        skip_button.clicked.connect (() => (next_step ()));

        next_button.clicked.connect (() => (next_step ()));

        NetworkMonitor.get_default ().network_changed.connect (update);

        update ();

        show_all ();
    }

    private void update () {
        if (NetworkMonitor.get_default ().get_network_available ()) {
            image.icon_name = "preferences-system-network";
            description_label.label = _("Network Available");
            network_info.label = _("Network is setup.");
            next_button.sensitive = true;
        } else {
            image.icon_name = "network-offline";
            description_label.label = _("Network Not Available");
            network_info.label = _("It looks like your device is not connected to any network. To use your device to its full potential, we recommend that you set up a network connection.");
            next_button.sensitive = false;
        }
    }
}

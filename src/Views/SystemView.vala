/*-
 * Copyright 2021 elementary, Inc. (https://elementary.io)
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

public class Installer.SystemView : AbstractInstallerView {
    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-system", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("System preferenes")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var hostname_label = new Granite.HeaderLabel (_("Device name"));

        var hostname_entry = new Gtk.Entry () {
            hexpand = true,
            text = GLib.Environment.get_host_name ()
        };

        var hostname_info = new Gtk.Label (_("Visible to other devices when sharing, e.g. with Bluetooth or over the network.")) {
            max_width_chars = 60,
            margin_bottom = 18,
            wrap = true,
            xalign = 0
        };
        hostname_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var form_grid = new Gtk.Grid () {
            row_spacing = 3,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        form_grid.attach (hostname_label, 0, 0, 1, 1);
        form_grid.attach (hostname_entry, 0, 1, 1, 1);
        form_grid.attach (hostname_info, 0, 2, 1, 1);

        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (form_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        next_button.clicked.connect (() => {
            Utils.set_hostname (hostname_entry.text);

            next_step ();
        });

        show_all ();
    }
}

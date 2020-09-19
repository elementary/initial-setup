/*-
 * Copyright 2020 elementary, Inc. (https://elementary.io)
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
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class Installer.SoftwareView : AbstractInstallerView {
    construct {
        var image = new Gtk.Image.from_icon_name ("system-software-update", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Software"));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.valign = Gtk.Align.START;

        var form_grid = new Gtk.Grid ();
        form_grid.row_spacing = 3;
        form_grid.valign = Gtk.Align.CENTER;
        form_grid.vexpand = true;

        var additional_media_formats_name_label = new Gtk.Label (_("Install additional media formats"));
        additional_media_formats_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        additional_media_formats_name_label.halign = Gtk.Align.START;
        additional_media_formats_name_label.hexpand = true;

        var additional_media_formats_description_label = new Gtk.Label (_("This software is subject to license terms included with its documentation. Some is propietary."));
        additional_media_formats_description_label.wrap = true;
        additional_media_formats_description_label.xalign = 0;

        var additional_media_formats_switch = new Gtk.Switch ();
        additional_media_formats_switch.valign = Gtk.Align.CENTER;

        unowned Configuration configuration = Configuration.get_default ();
        configuration.bind_property ("install_additional_media_formats", additional_media_formats_switch, "active", BindingFlags.BIDIRECTIONAL);

        form_grid.attach (additional_media_formats_name_label, 0, 0);
        form_grid.attach (additional_media_formats_description_label, 0, 1);
        form_grid.attach (additional_media_formats_switch, 1, 0, 1, 2);

        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (form_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = true;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);
        next_button.clicked.connect (on_next_button_clicked);

        show_all ();
    }

    private void on_next_button_clicked () {
        unowned Configuration configuration = Configuration.get_default ();
        var additional_packages_to_install = new List<string> ();
        if (configuration.install_additional_media_formats) {
            additional_packages_to_install.append ("gstreamer1.0-libav");
            additional_packages_to_install.append ("gstreamer1.0-plugins-bad");
            additional_packages_to_install.append ("gstreamer1.0-plugins-ugly");
        }

        next_step ();
    }
}

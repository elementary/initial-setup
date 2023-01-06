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

public class Installer.ProgressView : AbstractInstallerView {
    public Gtk.ProgressBar progressbar;
    public Gtk.Label progressbar_label;

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);

        progressbar_label = new Gtk.Label (null);
        progressbar_label.xalign = 0;
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        progressbar = new Gtk.ProgressBar ();
        progressbar.hexpand = true;

        var progress_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 12,
            row_spacing = 12,
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        progress_grid.attach (logo_stack, 0, 0, 2, 1);
        progress_grid.attach (progressbar_label, 0, 1, 1, 1);
        progress_grid.attach (progressbar, 0, 2, 2, 1);

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.add (progress_grid);

        get_style_context ().add_class ("progress-view");

        show_all ();
    }
}

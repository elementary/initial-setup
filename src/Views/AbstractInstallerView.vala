/*-
 * Copyright 2017-2021 elementary, Inc. (https://elementary.io)
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
 */

public abstract class AbstractInstallerView : Gtk.Box {
    public signal void next_step ();

    protected Gtk.Grid content_area;
    protected Gtk.Box action_area;

    construct {
        content_area = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 12,
            row_spacing = 12,
            hexpand = true,
            vexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = Gtk.Align.END,
            homogeneous = true
        };

        orientation = Gtk.Orientation.VERTICAL;
        margin_top = 12;
        margin_end = 12;
        margin_bottom = 12;
        margin_start = 12;
        spacing = 24;
        append (content_area);
        append (action_area);
    }
}

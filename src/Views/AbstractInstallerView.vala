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

    protected Gtk.Box title_area;
    protected Gtk.Box content_area;
    protected Gtk.Box action_area;

    construct {
        title_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER
        };
        title_area.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true,
            hexpand = true,
            vexpand = true,
        };
        box.append (title_area);
        box.append (content_area);

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
        append (box);
        append (action_area);
    }
}

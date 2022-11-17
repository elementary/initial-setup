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
    protected Gtk.FlowBoxChild content_area;
    protected Gtk.Box action_area;

    construct {
        title_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            width_request = 300, // Prevent layout flipping in language view
        };
        title_area.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var title_child = new Gtk.FlowBoxChild () {
            can_focus = false,
            valign = Gtk.Align.CENTER
        };
        title_child.add (title_area);

        content_area = new Gtk.FlowBoxChild () {
            can_focus = false,
            vexpand = true
        };

        var flowbox = new Gtk.FlowBox () {
            max_children_per_line = 2,
            min_children_per_line = 1,
            selection_mode = Gtk.SelectionMode.NONE,
            vexpand = true,
            column_spacing = 12,
            row_spacing = 12
        };
        flowbox.add (title_child);
        flowbox.add (content_area);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (title_area);
        size_group.add_widget (content_area);

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
        add (flowbox);
        add (action_area);
    }
}

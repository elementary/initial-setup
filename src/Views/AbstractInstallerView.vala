/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017-2024 elementary, Inc. (https://elementary.io)
 */

public abstract class AbstractInstallerView : Adw.NavigationPage {
    public signal void next_step ();

    protected Gtk.Box title_area;
    protected Gtk.Box content_area;
    protected Gtk.Box action_area;

    construct {
        title_area = new Gtk.Box (VERTICAL, 12) {
            valign = CENTER
        };
        title_area.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        content_area = new Gtk.Box (VERTICAL, 12);

        var box = new Gtk.Box (HORIZONTAL, 12) {
            homogeneous = true,
            hexpand = true,
            vexpand = true,
        };
        box.append (title_area);
        box.append (content_area);

        action_area = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            homogeneous = true
        };

        var main_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        main_box.append (box);
        main_box.append (action_area);

        child = main_box;
    }
}

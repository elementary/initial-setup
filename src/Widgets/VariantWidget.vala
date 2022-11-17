/*-
 * Copyright 2017-2020 elementary, Inc. (https://elementary.io)
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

public class VariantWidget : Gtk.Frame {
    public Gtk.ListBox main_listbox { public get; private set; }
    public Gtk.ListBox variant_listbox { public get; private set; }

    public signal void going_to_main ();

    private Gtk.Button back_button;
    private Gtk.Box variant_box;
    private Gtk.Label variant_title;
    private Adw.Leaflet leaflet;

    construct {
        main_listbox = new Gtk.ListBox ();

        var main_scrolled = new Gtk.ScrolledWindow () {
            child = main_listbox,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        variant_listbox = new Gtk.ListBox () {
            activate_on_single_click = false
        };

        var variant_scrolled = new Gtk.ScrolledWindow () {
            child = variant_listbox,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true
        };

        back_button = new Gtk.Button () {
            halign = Gtk.Align.START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        variant_title = new Gtk.Label (null);
        variant_title.ellipsize = Pango.EllipsizeMode.END;
        variant_title.max_width_chars = 20;
        variant_title.use_markup = true;

        var header_box = new Gtk.CenterBox () {
            hexpand = true
        };
        header_box.set_start_widget (back_button);
        header_box.set_center_widget (variant_title);

        variant_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        variant_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        variant_box.append (header_box);
        variant_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        variant_box.append (variant_scrolled);

        leaflet = new Adw.Leaflet () {
            can_navigate_back = true,
            can_unfold = false
        };
        leaflet.append (main_scrolled);
        leaflet.append (variant_box);

        child = leaflet;
        vexpand = true;

        back_button.clicked.connect (() => {
            going_to_main ();
            leaflet.navigate (Adw.NavigationDirection.BACK);
        });
    }

    public void show_variants (string back_button_label, string variant_title_label) {
        back_button.label = back_button_label;
        variant_title.label = variant_title_label;
        leaflet.visible_child = variant_box;
    }

    public void clear_variants () {
        // variant_listbox.get_children ().foreach ((child) => {
        //     child.destroy ();
        // });
    }
}

public class MainRow : Gtk.ListBoxRow {
    public GLib.Object handler { get; construct; }
    public string label { get; construct; }
    public bool has_variants { get; construct; }
}

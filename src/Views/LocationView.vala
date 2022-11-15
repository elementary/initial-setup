/*-
 * Copyright 2022 elementary. Inc. (https://elementary.io)
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

public class LocationView : AbstractInstallerView {
    private VariantWidget location_variant_widget;

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-system-time", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Select Time Zone")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        location_variant_widget = new VariantWidget ();

        var helper = LocationHelper.get_default ();

        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (location_variant_widget, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = false;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

        location_variant_widget.variant_listbox.row_activated.connect (() => {
            next_button.activate ();
        });

        location_variant_widget.variant_listbox.row_selected.connect (() => {
            unowned Gtk.ListBoxRow row = location_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                var layout = ((LayoutRow) row).layout;
                unowned Configuration configuration = Configuration.get_default ();
                GLib.Variant? layout_variant = null;
                string second_variant = layout.name;

                unowned Gtk.ListBoxRow vrow = location_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    unowned InitialSetup.LocationVariant variant = ((VariantRow) vrow).variant;
                    configuration.timezone = variant.original_name;
                    if (variant != null) {
                        layout_variant = variant.to_gsd_variant ();
                    }
                }

                if (layout_variant == null) {
                    layout_variant = layout.to_gsd_variant ();
                }
            }
        });

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (Hdy.NavigationDirection.BACK));

        next_button.clicked.connect (() => {
            next_step ();
        });

        location_variant_widget.main_listbox.row_activated.connect ((row) => {
            unowned InitialSetup.LocationLayout layout = ((LayoutRow) row).layout;
            if (!layout.has_variants ()) {
                return;
            }

            location_variant_widget.variant_listbox.bind_model (layout.get_variants (), (variant) => {
                return new VariantRow (variant as InitialSetup.LocationVariant);
            });
            location_variant_widget.variant_listbox.select_row (location_variant_widget.variant_listbox.get_row_at_index (0));

            location_variant_widget.show_variants (_("Continent"), "<b>%s</b>".printf (layout.display_name));
        });

        location_variant_widget.main_listbox.row_selected.connect ((row) => {
            next_button.sensitive = true;
        });

        location_variant_widget.main_listbox.bind_model (InitialSetup.LocationLayout.get_all (), (layout) => {
            return new LayoutRow (layout as InitialSetup.LocationLayout);
        });

        show_all ();
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public unowned InitialSetup.LocationLayout layout;

        public LayoutRow (InitialSetup.LocationLayout layout) {
            this.layout = layout;

            string layout_description = layout.display_name;
            if (layout.has_variants ()) {
                layout_description = _("%s…").printf (layout_description);
            }

            var label = new Gtk.Label (layout_description) {
                ellipsize = Pango.EllipsizeMode.END,
                margin = 6,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            add (label);
            show_all ();
        }
    }

    private class VariantRow : Gtk.ListBoxRow {
        public unowned InitialSetup.LocationVariant variant;

        public VariantRow (InitialSetup.LocationVariant variant) {
            this.variant = variant;

            var label = new Gtk.Label (variant.display_name) {
                ellipsize = Pango.EllipsizeMode.END,
                margin = 6,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            add (label);
            show_all ();
        }
    }
}

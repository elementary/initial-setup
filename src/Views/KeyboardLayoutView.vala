/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
 */

public class KeyboardLayoutView : AbstractInstallerView {
    private VariantWidget input_variant_widget;

    construct {
        var image = new Gtk.Image.from_icon_name ("input-keyboard") {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        title = _("Select Keyboard Layout");

        var title_label = new Gtk.Label (title);

        input_variant_widget = new VariantWidget ();

        title_label.mnemonic_widget = input_variant_widget.main_listbox;

        var keyboard_test_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("Type to test your layout"),
            secondary_icon_activatable = true,
            secondary_icon_name = "input-keyboard-symbolic",
            secondary_icon_tooltip_text = _("Show keyboard layout")
        };

        var stack_box = new Gtk.Box (VERTICAL, 12);
        stack_box.append (input_variant_widget);
        stack_box.append (keyboard_test_entry);

        title_area.append (image);
        title_area.append (title_label);

        content_area.append (stack_box);

        var back_button = new Gtk.Button.with_label (_("Back")) {
            width_request = 86
        };

        var next_button = new Gtk.Button.with_label (_("Select")) {
            sensitive = false
        };
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.append (back_button);
        action_area.append (next_button);

        input_variant_widget.variant_listbox.row_activated.connect (() => {
            next_button.activate ();
        });

        input_variant_widget.variant_listbox.row_selected.connect (() => {
            unowned var row = input_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                var layout = ((LayoutRow) row).layout;
                unowned var configuration = Configuration.get_default ();
                configuration.keyboard_layout = layout;
                GLib.Variant? layout_variant = null;

                unowned var vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    unowned InitialSetup.KeyboardVariant variant = ((VariantRow) vrow).variant;
                    configuration.keyboard_variant = variant;
                    if (variant != null) {
                        layout_variant = variant.to_gsd_variant ();
                    }
                } else if (!layout.has_variants ()) {
                    configuration.keyboard_variant = null;
                }

                if (layout_variant == null) {
                    layout_variant = layout.to_gsd_variant ();
                }

                var settings = new Settings ("org.gnome.desktop.input-sources");
                settings.set_value ("sources", layout_variant);
                settings.set_uint ("current", 0);
            }
        });

        back_button.clicked.connect (() => ((Adw.NavigationView) get_parent ()).pop ());

        next_button.clicked.connect (() => {
            unowned var vrow = input_variant_widget.variant_listbox.get_selected_row ();
            if (vrow == null) {
                unowned var row = input_variant_widget.main_listbox.get_selected_row ();
                if (row != null) {
                    row.activate ();
                    return;
                } else {
                    warning ("next_button enabled when no keyboard selected");
                    next_button.sensitive = false;
                    return;
                }
            }

            next_step ();
        });

        input_variant_widget.main_listbox.row_activated.connect ((row) => {
            unowned InitialSetup.KeyboardLayout layout = ((LayoutRow) row).layout;
            if (!layout.has_variants ()) {
                return;
            }

            input_variant_widget.variant_listbox.bind_model (layout.get_variants (), (variant) => { return new VariantRow (variant as InitialSetup.KeyboardVariant); });
            input_variant_widget.variant_listbox.select_row (input_variant_widget.variant_listbox.get_row_at_index (0));

            input_variant_widget.show_variants (_("Input Language"), "<b>%s</b>".printf (layout.display_name));
        });

        input_variant_widget.main_listbox.row_selected.connect ((row) => {
            next_button.sensitive = true;
        });

        keyboard_test_entry.icon_release.connect (() => {
            var layout_string = "us";
            unowned Configuration config = Configuration.get_default ();
            if (config.keyboard_layout != null) {
                layout_string = config.keyboard_layout.name;
                if (config.keyboard_variant != null) {
                    layout_string += "\t" + config.keyboard_variant.name;
                }
            }

            string command = "gkbd-keyboard-display --layout=%s".printf (layout_string);
            try {
                AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE).launch (null, null);
            } catch (Error e) {
                warning ("Error launching keyboard layout display: %s", e.message);
            }
        });

        input_variant_widget.main_listbox.bind_model (InitialSetup.KeyboardLayout.get_all (), (layout) => {
            return new LayoutRow (layout as InitialSetup.KeyboardLayout);
        });


        Idle.add_once (() => {
            unowned string? country = Configuration.get_default ().country;
            if (country != null) {
                var default_layout = country.down ();

                var child = input_variant_widget.main_listbox.get_first_child ();
                while (child != null) {
                    if (child is LayoutRow) {
                        unowned var row = (LayoutRow) child;
                        if (row.layout.name == default_layout) {
                            input_variant_widget.main_listbox.select_row (row);
                            row.grab_focus ();
                            break;
                        }
                    }

                    child = child.get_next_sibling ();
                }
            }
        });
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public unowned InitialSetup.KeyboardLayout layout;
        public LayoutRow (InitialSetup.KeyboardLayout layout) {
            this.layout = layout;

            string layout_description = layout.display_name;
            if (layout.has_variants ()) {
                layout_description = _("%s…").printf (layout_description);
            }

            var label = new Gtk.Label (layout_description) {
                ellipsize = END,
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6,
                xalign = 0
            };
            label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            child = label;
        }
    }

    private class VariantRow : Gtk.ListBoxRow {
        public unowned InitialSetup.KeyboardVariant variant;
        public VariantRow (InitialSetup.KeyboardVariant variant) {
            this.variant = variant;

            var label = new Gtk.Label (variant.display_name) {
                ellipsize = Pango.EllipsizeMode.END,
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6,
                xalign = 0
            };
            label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            child = label;
        }
    }
}

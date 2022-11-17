/*-
 * Copyright 2016-2021 elementary, Inc. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.LanguageView : AbstractInstallerView {
    private Gtk.Button next_button;
    private Gtk.Label select_label;
    private Gtk.Stack select_stack;
    private int select_number = 0;
    private static Gee.LinkedList<string> preferred_langs;
    private uint lang_timeout = 0U;
    private VariantWidget lang_variant_widget;

    public LanguageView () {
        lang_timeout = GLib.Timeout.add_seconds (3, timeout);
    }

    ~LanguageView () {
        if (lang_timeout > 0U) {
            GLib.Source.remove (lang_timeout);
        }
    }

    static construct {
        preferred_langs = new Gee.LinkedList<string> ();
        preferred_langs.add_all_array (Build.PREFERRED_LANG_LIST.split (";"));
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale", Gtk.IconSize.DIALOG) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        select_label = new Gtk.Label (null) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.START,
            wrap = true
        };

        select_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        select_stack.add (select_label);

        select_stack.notify["transition-running"].connect (() => {
            if (!select_stack.transition_running) {
                select_stack.get_children ().foreach ((child) => {
                    if (child != select_stack.get_visible_child ()) {
                        child.destroy ();
                    }
                });
            }
        });

        lang_variant_widget = new VariantWidget ();
        lang_variant_widget.variant_listbox.set_sort_func ((Gtk.ListBoxSortFunc) CountryRow.compare);

        lang_variant_widget.variant_listbox.row_activated.connect (() => {
            next_button.activate ();
        });

        lang_variant_widget.main_listbox.set_sort_func ((Gtk.ListBoxSortFunc) LangRow.compare);

        lang_variant_widget.main_listbox.set_header_func ((row, before) => {
            row.set_header (null);
            if (!((LangRow)row).preferred_row) {
                if (before != null && ((LangRow)before).preferred_row) {
                    var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                        margin = 3,
                        margin_end = 6,
                        margin_start = 6
                    };
                    separator.show_all ();

                    row.set_header (separator);
                }
            }
        });

        foreach (var lang_entry in LocaleHelper.get_lang_entries ().entries) {
            if (lang_entry.key in preferred_langs) {
                var pref_langrow = new LangRow (lang_entry.value);
                pref_langrow.preferred_row = true;
                lang_variant_widget.main_listbox.add (pref_langrow);
            }

            var langrow = new LangRow (lang_entry.value);
            lang_variant_widget.main_listbox.add (langrow);
        }

        next_button = new Gtk.Button.with_label (_("Select")) {
            width_request = 86,
            sensitive = false
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (next_button);

        lang_variant_widget.main_listbox.row_selected.connect (row_selected);
        lang_variant_widget.main_listbox.select_row (lang_variant_widget.main_listbox.get_row_at_index (0));
        lang_variant_widget.main_listbox.row_activated.connect (row_activated);

        next_button.clicked.connect (on_next_button_clicked);
        next_button.button_press_event.connect ((event) => {
            if (event.button == Gdk.BUTTON_SECONDARY) {
                on_next_button_secondary_clicked ();
            }

            return base.button_press_event (event);
        });

        destroy.connect (() => {
            // We need to disconnect the signal otherwise it's called several time when destroying the window…
            lang_variant_widget.main_listbox.row_selected.disconnect (row_selected);
        });

        title_area.add (image);
        title_area.add (select_stack);

        content_area.add (lang_variant_widget);

        timeout ();
    }

    private void row_selected (Gtk.ListBoxRow? row) {
        unowned LocaleHelper.LangEntry lang_entry = ((LangRow) row).lang_entry;
        unowned string lang_code = lang_entry.get_code ();

        foreach (unowned var child in lang_variant_widget.main_listbox.get_children ()) {
            if (child is LangRow) {
                unowned var lang_row = (LangRow) child;
                if (lang_row.lang_entry.get_code () == lang_code) {
                    lang_row.selected = true;
                } else {
                    lang_row.selected = false;
                }
            }
        }

        next_button.sensitive = true;
    }

    private void variant_row_selected (Gtk.ListBoxRow? row) {
        unowned LocaleHelper.CountryEntry country_entry = ((CountryRow) row).country_entry;
        foreach (unowned var child in lang_variant_widget.variant_listbox.get_children ()) {
            if (child is CountryRow) {
                unowned var country_row = (CountryRow) child;
                if (country_row.country_entry.alpha_2 == country_entry.alpha_2) {
                    country_row.selected = true;
                } else {
                    country_row.selected = false;
                }
            }
        }

        next_button.label = LocaleHelper.lang_gettext (N_("Select"), country_entry.get_full_code ());
        next_button.sensitive = true;
    }

    private void row_activated (Gtk.ListBoxRow row) {
            var lang_entry = ((LangRow) row).lang_entry;
            unowned var countries = lang_entry.countries;
            if (countries.length == 0) {
                next_button.sensitive = true;
                return;
            }

            unowned var lang_code = lang_entry.get_code ();
            string? main_country = LocaleHelper.get_main_country (lang_code);

            lang_variant_widget.variant_listbox.row_selected.disconnect (variant_row_selected);
            lang_variant_widget.clear_variants ();
            lang_variant_widget.variant_listbox.row_selected.connect (variant_row_selected);
            foreach (unowned var country in countries) {
                var country_row = new CountryRow (country);
                lang_variant_widget.variant_listbox.add (country_row);
                if (country.get_code () == main_country) {
                    lang_variant_widget.variant_listbox.select_row (country_row);
                }
            }

            if (main_country == null || lang_variant_widget.variant_listbox.get_selected_row () == null) {
                lang_variant_widget.variant_listbox.select_row (lang_variant_widget.variant_listbox.get_row_at_index (0));
            }

            lang_variant_widget.variant_listbox.show_all ();
            Environment.set_variable ("LANGUAGE", lang_code, true);
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            lang_variant_widget.show_variants (_("Languages"), "<b>%s</b>".printf (lang_entry.name));
    }

    private void on_next_button_clicked () {
        string? lang = null;
        unowned var row = lang_variant_widget.main_listbox.get_selected_row ();
        if (row != null) {
            unowned var configuration = Configuration.get_default ();

            var lang_entry = ((LangRow) row).lang_entry;
            lang = lang_entry.get_code ();

            if (lang_entry.countries.length > 0) {
                row = lang_variant_widget.variant_listbox.get_selected_row ();
                if (row != null) {
                    unowned var country = ((CountryRow) row).country_entry;
                    configuration.country = country.get_code ();
                    lang = country.get_full_code ();
                } else {
                    unowned var country = lang_entry.countries[0].get_code ();
                    lang += "_%s".printf (country);
                    configuration.country = country;
                }
            }

            Environment.set_variable ("LANGUAGE", lang, true);
            configuration.lang = lang;
        }

        next_step ();
    }

    private void on_next_button_secondary_clicked () {
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");

        string primary_label = _("Use the right mouse button for primary click?");
        string secondary_label = _("The right mouse button was used where a primary click was expected. You can choose to always use the right mouse button for primary click.");
        string suggested_action_label = _("Right-Click as Primary");
        string cancel_action_label = _("Left-Click as Primary");

        if (mouse_settings.get_boolean ("left-handed")) {
            primary_label = _("Use the left mouse button for primary click?");
            secondary_label = _("The left mouse button was used where a primary click was expected. You can choose to always use the left mouse button for primary click.");
            suggested_action_label = _("Left-Click as Primary");
            cancel_action_label = _("Right-Click as Primary");
        }

        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
            primary_label,
            secondary_label,
            "input-mouse",
            Gtk.ButtonsType.NONE
        ) {
            transient_for = (Gtk.Window) get_toplevel ()
        };
        var cancel_action_button = dialog.add_button (cancel_action_label, Gtk.ResponseType.CANCEL);

        var suggested_action_button = dialog.add_button (suggested_action_label, Gtk.ResponseType.ACCEPT);
        suggested_action_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        suggested_action_button.button_press_event.connect ((event) => {
            if (event.button == Gdk.BUTTON_SECONDARY) {
                suggested_action_button.activate ();
            }

            return base.button_press_event (event);
        });

        cancel_action_button.button_press_event.connect ((event) => {
            if (event.button == Gdk.BUTTON_SECONDARY) {
                cancel_action_button.activate ();
            }

            return base.button_press_event (event);
        });

        var result = dialog.run ();
        dialog.destroy ();

        if (!mouse_settings.get_boolean ("left-handed") && result == Gtk.ResponseType.ACCEPT) {
            mouse_settings.set_boolean ("left-handed", true);
            Configuration.get_default ().left_handed = true;
        } else if (mouse_settings.get_boolean ("left-handed") && result == Gtk.ResponseType.ACCEPT) {
            mouse_settings.set_boolean ("left-handed", false);
            Configuration.get_default ().left_handed = false;
        }

        next_step ();
    }

    private bool timeout () {
        var row = lang_variant_widget.main_listbox.get_row_at_index (select_number);
        if (row == null) {
            select_number = 0;
            row = lang_variant_widget.main_listbox.get_row_at_index (select_number);

            if (row == null) {
                lang_timeout = 0;
                return Source.REMOVE;
            }
        }

        unowned var label_text = LocaleHelper.lang_gettext (N_("Select a Language"), ((LangRow) row).lang_entry.get_code ());
        select_label = new Gtk.Label (label_text);
        select_label.show_all ();
        select_stack.add (select_label);
        select_stack.set_visible_child (select_label);

        select_number++;
        return GLib.Source.CONTINUE;
    }

    public class LangRow : Gtk.ListBoxRow {
        private Gtk.Image image;
        public LocaleHelper.LangEntry lang_entry;
        public bool preferred_row { get; set; default = false; }

        private bool _selected;
        public bool selected {
            get {
                return _selected;
            }
            set {
                if (value) {
                    image.icon_name = "selection-checked";
                    image.tooltip_text = _("Currently active language");
                } else {
                    image.tooltip_text = "";
                    image.clear ();
                }
                _selected = value;
            }
        }

        public LangRow (LocaleHelper.LangEntry lang_entry) {
            this.lang_entry = lang_entry;

            image = new Gtk.Image () {
                halign = Gtk.Align.END,
                hexpand = true,
                icon_size = Gtk.IconSize.BUTTON
            };

            var label = new Gtk.Label (lang_entry.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var grid = new Gtk.Grid () {
                column_spacing = 6,
                margin = 6
            };
            grid.add (label);
            grid.add (image);

            add (grid);
        }

        public static int compare (LangRow langrow1, LangRow langrow2) {
            if (langrow1.preferred_row && langrow2.preferred_row == false) {
                return -1;
            } else if (langrow2.preferred_row && langrow1.preferred_row == false) {
                return 1;
            } else if (langrow1.preferred_row && langrow2.preferred_row) {
                return preferred_langs.index_of (langrow1.lang_entry.get_code ()) - preferred_langs.index_of (langrow2.lang_entry.get_code ());
            }

            return langrow1.lang_entry.name.collate (langrow2.lang_entry.name);
        }
    }

    public class CountryRow : Gtk.ListBoxRow {
        public LocaleHelper.CountryEntry country_entry;
        private Gtk.Image image;

        private bool _selected;
        public bool selected {
            get {
                return _selected;
            }
            set {
                if (value) {
                    image.icon_name = "selection-checked";
                    image.tooltip_text = _("Currently active language");
                } else {
                    image.tooltip_text = "";
                    image.clear ();
                }
                _selected = value;
            }
        }

        public CountryRow (LocaleHelper.CountryEntry country_entry) {
            this.country_entry = country_entry;

            image = new Gtk.Image () {
                halign = Gtk.Align.END,
                hexpand = true,
                icon_size = Gtk.IconSize.BUTTON
            };

            var label = new Gtk.Label (country_entry.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var grid = new Gtk.Grid () {
                column_spacing = 6,
                margin = 6
            };
            grid.add (label);
            grid.add (image);

            add (grid);
        }


        public static int compare (CountryRow countryrow1, CountryRow countryrow2) {
            return countryrow1.country_entry.name.collate (countryrow2.country_entry.name);
        }
    }
}

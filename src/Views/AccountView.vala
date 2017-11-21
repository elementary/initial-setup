/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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

public class Installer.AccountView : AbstractInstallerView {
    private ErrorRevealer pw_error_revealer;
    private ErrorRevealer username_error_revealer;
    private Gtk.Entry confirm_entry;
    private Gtk.Entry username_entry;
    private Gtk.Entry pw_entry;
    private Gtk.Label confirm_label;
    private Gtk.LevelBar pw_levelbar;

    construct {
        var image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Create an Account"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var realname_label = new Granite.HeaderLabel (_("Full Name"));

        var realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;

        var username_label = new Granite.HeaderLabel (_("Username"));

        username_entry = new Gtk.Entry ();
        username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-information-symbolic");
        username_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Can only contain lower case letters, numbers and no spaces"));

        username_error_revealer = new ErrorRevealer (".");
        username_error_revealer.style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        var pw_label = new Granite.HeaderLabel (_("Choose a Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.style_context.add_class (Gtk.STYLE_CLASS_WARNING);

        pw_entry = new Gtk.Entry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        confirm_label = new Granite.HeaderLabel (_("Confirm Password"));
        confirm_label.sensitive = false;

        confirm_entry = new Gtk.Entry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        var form_grid = new Gtk.Grid ();
        form_grid.row_spacing = 3;
        form_grid.valign = Gtk.Align.CENTER;
        form_grid.vexpand = true;
        form_grid.attach (realname_label, 0, 0, 1, 1);
        form_grid.attach (realname_entry, 0, 1, 1, 1);
        form_grid.attach (new ErrorRevealer ("."), 0, 2, 1, 1);
        form_grid.attach (username_label, 0, 3, 1, 1);
        form_grid.attach (username_entry, 0, 4, 1, 1);
        form_grid.attach (username_error_revealer, 0, 5, 1, 1);
        form_grid.attach (pw_label, 0, 6, 1, 1);
        form_grid.attach (pw_entry, 0, 7, 2, 1);
        form_grid.attach (pw_levelbar, 0, 8, 1, 1);
        form_grid.attach (pw_error_revealer, 0, 9 , 1, 1);
        form_grid.attach (confirm_label, 0, 10, 1, 1);
        form_grid.attach (confirm_entry, 0, 11, 1, 1);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (form_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var finish_button = new Gtk.Button.with_label (_("Finish Setup"));
        finish_button.sensitive = false;
        finish_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (finish_button);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        realname_entry.changed.connect (() => {
            var username = Utils.gen_username (realname_entry.text);
            username_entry.text = username;
        });

        username_entry.changed.connect (check_username);
        pw_entry.changed.connect (check_password);
        confirm_entry.changed.connect (check_password);

        show_all ();
    }

    private void check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;
            confirm_label.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;
            confirm_label.sensitive = true;

            var pwquality = new PasswordQuality.Settings ();
            void* error;
            var quality = pwquality.check (pw_entry.text, null, null, out error);

            if (quality >= 0) {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                pw_error_revealer.reveal_child = false;

                pw_levelbar.value = quality;
            } else {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                pw_error_revealer.reveal_child = true;
                pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                pw_levelbar.value = 0;
            }
        }

        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                confirm_entry.tooltip_text = _("Passwords do not match");
            } else {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                confirm_entry.tooltip_text = null;
            }
        } else {
            confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
        }
    }

    private void check_username () {
        string username_entry_text = username_entry.text;

        if (username_entry_text == "") {
            username_error_revealer.reveal_child = false;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-information-symbolic");
        } else if (Utils.is_valid_username (username_entry_text)) {
            username_error_revealer.reveal_child = false;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
        } else {
            username_error_revealer.label = _("Username is not valid");
            username_error_revealer.reveal_child = true;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
        }
    }

    private class ErrorRevealer : Gtk.Revealer {
        private Gtk.Label label_widget;

        public Gtk.StyleContext? style_context {
            get {
                return label_widget.get_style_context ();
            }
        }

        public string label {
            get {
                if (label_widget != null) {
                    return label_widget.label;
                } else {
                    return "";
                }
            }
            set {
                label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
            }
        }

        public ErrorRevealer (string label) {
            Object (label: label);
        }

        construct {
            label_widget = new Gtk.Label (label);
            label_widget.halign = Gtk.Align.END;
            label_widget.justify = Gtk.Justification.RIGHT;
            label_widget.max_width_chars = 55;
            label_widget.use_markup = true;
            label_widget.wrap = true;
            label_widget.xalign = 1;

            transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            add (label_widget);
        }
    }
}

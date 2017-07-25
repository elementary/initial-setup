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

public class InitialSetup.AccountView : Gtk.Grid {
    private Gtk.Entry confirm_entry;
    private Gtk.Entry pw_entry;
    private Gtk.Label confirm_label;
    private Gtk.LevelBar pw_levelbar;

    public AccountView () {
        Object (
            column_spacing: 12,
            row_spacing: 12
        );
    }

    construct {
        var realname_label = new Gtk.Label (_("Full name:"));
        realname_label.halign = Gtk.Align.END;

        var realname_entry = new Gtk.Entry ();

        var username_label = new Gtk.Label (_("Username:"));
        username_label.halign = Gtk.Align.END;

        var username_entry = new Gtk.Entry ();

        var pw_label = new Gtk.Label (_("Choose a password:"));
        pw_label.halign = Gtk.Align.END;

        pw_entry = new Gtk.Entry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        confirm_label = new Gtk.Label (_("Confirm password:"));
        confirm_label.halign = Gtk.Align.END;
        confirm_label.sensitive = false;

        confirm_entry = new Gtk.Entry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        attach (realname_label, 0, 0, 1, 1);
        attach (realname_entry, 1, 0, 1, 1);
        attach (username_label, 0, 1, 1, 1);
        attach (username_entry, 1, 1, 1, 1);
        attach (pw_label, 0, 2, 1, 1);
        attach (pw_entry, 1, 2, 1, 1);
        attach (pw_levelbar, 1, 3, 1, 1);
        attach (confirm_label, 0, 4, 1, 1);
        attach (confirm_entry, 1, 4, 1, 1);

        pw_entry.changed.connect (check_password);
        confirm_entry.changed.connect (check_password);
    }

    private void check_password () {
        var pwquality = new PasswordQuality.Settings ();
        void* error;
        var quality = pwquality.check (pw_entry.text, null, null, out error);

        if (quality >= 0) {
            confirm_entry.sensitive = true;
            confirm_label.sensitive = true;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
            pw_entry.tooltip_text = null;

            pw_levelbar.value = quality;
        } else {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;
            confirm_label.sensitive = false;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
            pw_entry.tooltip_text = ((PasswordQuality.Error) quality).to_string (error);

            pw_levelbar.value = 0;
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
}

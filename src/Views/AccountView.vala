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
    private Act.UserManager _user_manager = null;
    private Act.UserManager user_manager {
        get {
            if (_user_manager != null && _user_manager.is_loaded) {
                return _user_manager;
            }

            _user_manager = Act.UserManager.get_default ();
            return _user_manager;
        }
    }

    private Polkit.Permission? _permission = null;
    private Polkit.Permission? permission {
        get {
            if (_permission != null) {
                return _permission;
            }

            try {
                _permission = new Polkit.Permission.sync ("org.freedesktop.accounts.user-administration", new Polkit.UnixProcess (Posix.getpid ()));
            } catch (Error e) {
                critical (e.message);
            }

            return _permission;
        }
    }

    private Act.User? created_user = null;
    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private ErrorRevealer username_error_revealer;
    private Gtk.Button finish_button;
    private Gtk.Entry realname_entry;
    private Granite.ValidatedEntry confirm_entry;
    private Granite.ValidatedEntry username_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;
    private Granite.ValidatedEntry hostname_entry;

    construct {
        var avatar = new Adw.Avatar (104, null, true) {
            margin_top = 12,
            margin_bottom = 12,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Create an Account"));
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.valign = Gtk.Align.START;

        var realname_label = new Granite.HeaderLabel (_("Full Name"));

        realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;

        var username_label = new Granite.HeaderLabel (_("Username"));

        username_entry = new Granite.ValidatedEntry ();

        username_error_revealer = new ErrorRevealer (".");
        username_error_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_ERROR);

        var pw_label = new Granite.HeaderLabel (_("Choose a Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 30.0);
        pw_levelbar.add_offset_value ("middle", 50.0);
        pw_levelbar.add_offset_value ("high", 80.0);
        pw_levelbar.add_offset_value ("full", 100.0);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new Granite.ValidatedEntry () {
            sensitive = false,
            visibility = false
        };

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_ERROR);

        var hostname_label = new Granite.HeaderLabel (_("Device name")) {
            margin_top = 16
        };

        hostname_entry = new Granite.ValidatedEntry () {
            activates_default = true,
            hexpand = true
        };

        hostname_entry.map.connect (() => {
            hostname_entry.text = Utils.get_hostname ();
        });

        var hostname_info = new Gtk.Label (_("Visible to other devices when sharing, e.g. with Bluetooth or over the network.")) {
            // Wrap without expanding the view
            max_width_chars = 0,
            margin_bottom = 18,
            wrap = true,
            xalign = 0
        };
        hostname_info.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

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
        form_grid.attach (confirm_entry_revealer, 0, 12, 1, 1);
        form_grid.attach (hostname_label, 0, 13, 1, 1);
        form_grid.attach (hostname_entry, 0, 14, 1, 1);
        form_grid.attach (hostname_info, 0, 15, 1, 1);

        content_area.attach (avatar, 0, 0);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (form_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        finish_button = new Gtk.Button.with_label (_("Finish Setup")) {
            receives_default = true,
            sensitive = false
        };
        finish_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.append (back_button);
        action_area.append (finish_button);

        back_button.clicked.connect (() => ((Adw.Leaflet) get_parent ()).navigate (Adw.NavigationDirection.BACK));

        realname_entry.changed.connect (() => {
            var username = gen_username (realname_entry.text);
            username_entry.text = username;
        });

        username_entry.changed.connect (() => {
            username_entry.is_valid = check_username ();
            update_finish_button ();
        });

        pw_entry.changed.connect (() => {
            pw_entry.is_valid = check_password ();
            confirm_entry.is_valid = confirm_password ();
            update_finish_button ();
        });

        confirm_entry.changed.connect (() => {
            confirm_entry.is_valid = confirm_password ();
            update_finish_button ();
        });

        hostname_entry.changed.connect (() => {
            hostname_entry.is_valid = check_hostname ();
            update_finish_button ();
        });

        finish_button.clicked.connect (create_new_user);

        realname_entry.bind_property ("text", avatar, "text");
        realname_entry.grab_focus ();
    }

    private bool check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;

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
            return true;
        }

        return false;
    }

    private bool confirm_password () {
        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
    }

    private bool check_username () {
        string username_entry_text = username_entry.text;
        bool username_is_valid = is_valid_username (username_entry_text);
        bool username_is_taken = is_taken_username (username_entry_text);

        if (username_entry_text == "") {
            username_error_revealer.reveal_child = false;
        } else if (username_is_valid && !username_is_taken) {
            username_error_revealer.reveal_child = false;
            return true;
        } else {
            if (username_is_taken) {
                username_error_revealer.label = _("The chosen username is already taken");
            } else if (!username_is_valid) {
                username_error_revealer.label = _("A username must only contain lowercase letters and numbers, without spaces");
            }

            username_error_revealer.reveal_child = true;
        }

        return false;
    }

    private bool check_hostname () {
        return Utils.gen_hostname (hostname_entry.text).length > 0;
    }

    private void update_finish_button () {
        if (username_entry.is_valid && pw_entry.is_valid && confirm_entry.is_valid && hostname_entry.is_valid) {
            finish_button.sensitive = true;
            finish_button.receives_default = true;
        } else {
            finish_button.sensitive = false;
        }
    }

    private void create_new_user () {
        string? primary_text = null;
        string? error_message = null;

        if (permission != null && permission.allowed) {
            try {
                created_user = user_manager.create_user (username_entry.text, realname_entry.text, Act.UserAccountType.ADMINISTRATOR);
                set_settings.begin ((obj, res) => {
                    set_settings.end (res);

                    Application.get_default ().quit ();
                });
            } catch (Error e) {
                if (created_user != null) {
                    try {
                        user_manager.delete_user (created_user, true);
                    } catch (Error e) {
                        critical ("Unable to clean up failed user: %s", e.message);
                    }
                }

                primary_text = _("Creating an account for “%s” failed").printf (username_entry.text);
                error_message = e.message;
            }
        } else {
            primary_text = _("Couldn't get permission to create an account for “%s”").printf (username_entry.text);
        }

        if (primary_text != null) {
            var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                primary_text,
                _("Initial Setup could not create this account. Without it, you will not be able to log in and may need to reinstall the OS."),
                "system-users",
                Gtk.ButtonsType.CLOSE
            ) {
                badge_icon = new ThemedIcon ("dialog-error"),
                modal = true,
                transient_for = (Gtk.Window) get_root ()
            };

            if (error_message != null) {
                error_dialog.show_error_details (error_message);
            }

            error_dialog.present ();
            error_dialog.response.connect (error_dialog.destroy);
        }
    }

    private async void set_settings () {
        created_user.set_password (pw_entry.text, "");
        yield set_accounts_service_settings ();
        yield set_locale ();
        set_hostname (hostname_entry.text);
    }

    public bool set_hostname (string hostname) {
        string? primary_text = null;
        string? error_message = null;

        try {
            var permission = new Polkit.Permission.sync ("org.freedesktop.hostname1.set-static-hostname", new Polkit.UnixProcess (Posix.getpid ()));

            if (permission != null && permission.allowed) {
                Utils.get_hostname_interface_instance ();
                Utils.hostname_interface_instance.set_pretty_hostname (hostname, false);
                Utils.hostname_interface_instance.set_static_hostname (Utils.gen_hostname (hostname), false);
            } else {
                primary_text = _("Couldn't get permission to name this device “%s”").printf (hostname);
            }
        } catch (GLib.Error e) {
            primary_text = _("Unable to name this device “%s”").printf (hostname);
            error_message = e.message;
        }

        if (primary_text != null) {
            var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                primary_text,
                _("Initial Setup could not set your hostname."),
                "dialog-error",
                Gtk.ButtonsType.CLOSE
            ) {
                modal = true,
                transient_for = (Gtk.Window) get_root ()
            };

            if (error_message != null) {
                error_dialog.show_error_details (error_message);
            }

            error_dialog.present ();
            error_dialog.response.connect (error_dialog.destroy);

            return false;
        }

        return true;
    }

    private async void set_locale () {
        string lang = Configuration.get_default ().lang;
        string? locale = null;
        bool success = yield LocaleHelper.language2locale (lang, out locale);

        if (!success || locale == null || locale == "") {
            warning ("Falling back to setting unconverted language as user's locale, may result in incorrect language");
            created_user.set_language (lang);
        } else {
            created_user.set_language (locale);
        }
    }

    private async void set_accounts_service_settings () {
        AccountsService accounts_service = null;

        try {
            var act_service = yield GLib.Bus.get_proxy<FDO.Accounts> (GLib.BusType.SYSTEM,
                                                                      "org.freedesktop.Accounts",
                                                                      "/org/freedesktop/Accounts");
            var user_path = act_service.find_user_by_name (created_user.user_name);

            accounts_service = yield GLib.Bus.get_proxy (GLib.BusType.SYSTEM,
                                                        "org.freedesktop.Accounts",
                                                        user_path,
                                                        GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (Error e) {
            warning ("Unable to get AccountsService proxy, settings on new user may be incorrect: %s", e.message);
        }

        if (accounts_service != null) {
            var layouts = Configuration.get_default ().keyboard_layout.to_accountsservice_array ();
            if (Configuration.get_default ().keyboard_variant != null) {
                layouts = Configuration.get_default ().keyboard_variant.to_accountsservice_array ();
            }

            accounts_service.keyboard_layouts = layouts;
            accounts_service.left_handed = Configuration.get_default ().left_handed;
        }
    }

    private bool is_taken_username (string username) {
        foreach (unowned Act.User user in user_manager.list_users ()) {
            if (user.get_user_name () == username) {
                return true;
            }
        }
        return false;
    }

    private bool is_valid_username (string username) {
        try {
            if (new Regex ("^[a-z]+[a-z0-9]*$").match (username)) {
                return true;
            }
            return false;
        } catch (Error e) {
            critical (e.message);
            return false;
        }
    }

    private string gen_username (string fullname) {
        string username = "";
        bool met_alpha = false;

        foreach (char c in fullname.to_ascii ().to_utf8 ()) {
            if (c.isalpha ()) {
                username += c.to_string ().down ();
                met_alpha = true;
            } else if (c.isdigit () && met_alpha) {
                username += c.to_string ();
            }
        }

        return username;
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }

        construct {
            activates_default = true;
        }
    }

    private class ErrorRevealer : Gtk.Box {
        public bool reveal_child { get; set; }
        public Gtk.Label label_widget;

        public string label {
            set {
                label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
            }
        }

        public ErrorRevealer (string label) {
            label_widget = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (label));
            label_widget.halign = Gtk.Align.END;
            label_widget.justify = Gtk.Justification.RIGHT;
            label_widget.max_width_chars = 55;
            label_widget.use_markup = true;
            label_widget.wrap = true;
            label_widget.xalign = 1;

            var revealer = new Gtk.Revealer () {
                child = label_widget,
                transition_type = Gtk.RevealerTransitionType.CROSSFADE
            };

            append (revealer);

            bind_property ("reveal-child", revealer, "reveal-child");
        }
    }
}

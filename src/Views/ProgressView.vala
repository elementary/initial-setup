/*-
 * Copyright 2023 elementary, Inc. (https://elementary.io)
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
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class Installer.ProgressView : AbstractInstallerView {
    public Gtk.ProgressBar progressbar;
    public Gtk.Label progressbar_label;

    private Act.User? created_user = null;

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

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);

        progressbar_label = new Gtk.Label (null);
        progressbar_label.xalign = 0;
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        progressbar = new Gtk.ProgressBar ();
        progressbar.hexpand = true;

        var progress_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 12,
            row_spacing = 12,
            expand = true,
            hexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        progress_grid.attach (logo_stack, 0, 0, 2, 1);
        progress_grid.attach (progressbar_label, 0, 1, 1, 1);
        progress_grid.attach (progressbar, 0, 2, 2, 1);

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.add (progress_grid);

        get_style_context ().add_class ("progress-view");

        show_all ();
    }

    public void start_setup () {
        string? primary_text = null;
        string? error_message = null;

        unowned var configuration = Configuration.get_default ();
        var realname = configuration.realname;
        var username = configuration.username;

        if (permission != null && permission.allowed) {
            try {
                progressbar_label.label = _("Create account");
                created_user = user_manager.create_user (username, realname, Act.UserAccountType.ADMINISTRATOR);
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

                primary_text = _("Creating an account for “%s” failed").printf (username);
                error_message = e.message;
            }
        } else {
            primary_text = _("Couldn't get permission to create an account for “%s”").printf (username);
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
                transient_for = (Gtk.Window) get_toplevel ()
            };

            if (error_message != null) {
                error_dialog.show_error_details (error_message);
            }

            error_dialog.present ();
            error_dialog.response.connect (error_dialog.destroy);
        }
    }

    private async void set_settings () {
        progressbar_label.label = _("Set password");
        created_user.set_password (Configuration.get_default ().password, "");
        yield set_accounts_service_settings ();
        yield set_locale ();
        set_hostname (Configuration.get_default ().hostname);
        install_software ();
    }

    public bool set_hostname (string hostname) {
        progressbar_label.label = _("Set hostname");
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
                transient_for = (Gtk.Window) get_toplevel ()
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
        progressbar_label.label = _("Set locale");
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
        progressbar_label.label = _("Set account settings");
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

    private string? architecture () {
        try {
            string standard_output;
            int exit_status;
            Process.spawn_command_line_sync ("/usr/bin/uname -p",
                                                out standard_output,
                                                null,
                                                out exit_status);

            if (exit_status == 0) {
                return standard_output.strip ();
            }
        } catch (SpawnError e) {
            warning (e.message);
        }

        return null;
    }

    private void install_software () {
        var arch = architecture ();
        if (arch == null) {
            return;
        }

        const string REMOTE = "freedesktop";
        string _ref = "runtime/org.freedesktop.Platform.ffmpeg-full/%s/22.08".printf (arch);

        var install_additional_media_formats = Configuration.get_default ().install_additional_media_formats;

        if (!install_additional_media_formats) {
            return;
        }

        progressbar_label.label = _("Install Software");

        try {
            var system_installation = new Flatpak.Installation.system ();

            Flatpak.Transaction transaction;
            transaction = new Flatpak.Transaction.for_installation (system_installation);
            transaction.add_default_dependency_sources ();
            transaction.add_install (REMOTE, _ref, null);
            transaction.run ();
        } catch (Error e) {
            warning ("Unable to install additional software: %s", e.message);
        }
    }
}

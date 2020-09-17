/*-
 * Copyright 2016-2020 elementary, Inc. (https://elementary.io)
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

public class Installer.MainWindow : Hdy.Window {
    private Gtk.Stack stack;

    private AccountView account_view;
    private LanguageView language_view;
    private LocationView location_view;
    private KeyboardLayoutView keyboard_layout_view;

    public MainWindow () {
        Object (
            deletable: false,
            height_request: 700,
            icon_name: "system-os-installer",
            resizable: false,
            title: _("Create a User"),
            width_request: 950
        );
    }

    construct {
        language_view = new LanguageView ();

        stack = new Gtk.Stack () {
            margin_bottom = 12,
            margin_top = 12,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add (language_view);

        add (stack);

        language_view.next_step.connect (() => load_keyboard_view ());
    }

    /*
     * We need to load all the view after the language has being chosen and set.
     * We need to rebuild the view everytime the next button is clicked to reflect language changes.
     */

    private void load_keyboard_view () {
        if (keyboard_layout_view != null) {
            keyboard_layout_view.destroy ();
        }

        keyboard_layout_view = new KeyboardLayoutView ();
        keyboard_layout_view.previous_view = language_view;
        stack.add (keyboard_layout_view);
        stack.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => load_location_view ());
    }

    private void load_location_view () {
        if (location_view != null) {
            location_view.destroy ();
        }

        location_view = new LocationView ();
        location_view.previous_view = keyboard_layout_view;
        stack.add (location_view);
        stack.visible_child = location_view;

        location_view.next_step.connect (() => load_account_view ());
    }

    private void load_account_view () {
        if (account_view != null) {
            account_view.destroy ();
        }

        account_view = new AccountView ();
        account_view.previous_view = location_view;
        stack.add (account_view);
        stack.visible_child = account_view;

        account_view.next_step.connect (on_finish);
    }

    private void on_finish () {
        if (account_view.created != null) {
            account_view.created.set_language (Configuration.get_default ().lang);

            set_clock_format_for_user (account_view.created);

            set_timezone ();

            set_keyboard_layout.begin ((obj, res) => {
                set_keyboard_layout.end (res);
                destroy ();
            });
        } else {
            destroy ();
        }

    }

    private void set_timezone () {
        try {
            LocationHelper.DateTime1 datetime1 = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.timedate1", "/org/freedesktop/timedate1");
            unowned Configuration configuration = Configuration.get_default ();
            datetime1.set_timezone (configuration.timezone, true);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void set_clock_format_for_user (Act.User user) {
        unowned Configuration configuration = Configuration.get_default ();

        var countrycode = LocationHelper.get_default ().get_countrycode_from_timezone (Configuration.get_default ().timezone);
        if (countrycode != null) {
            var 12h_format_countries_list = Build.12H_FORMAT_COUNTRIES_LIST.split (";");            
            if (countrycode in 12h_format_countries_list) {
                configuration.clock_format = "12h";
            }
        }

        Utils.set_clock_format_for_user (configuration.clock_format, user);
    }

    private async void set_keyboard_layout () {
        AccountsService accounts_service = null;

        try {
            var act_service = yield GLib.Bus.get_proxy<FDO.Accounts> (GLib.BusType.SYSTEM,
                                                                      "org.freedesktop.Accounts",
                                                                      "/org/freedesktop/Accounts");
            var user_path = act_service.find_user_by_name (account_view.created.user_name);

            accounts_service = yield GLib.Bus.get_proxy (GLib.BusType.SYSTEM,
                                                        "org.freedesktop.Accounts",
                                                        user_path,
                                                        GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
        } catch (Error e) {
            warning ("Unable to get AccountsService proxy, keyboard layout on new user may be incorrect: %s", e.message);
        }

        if (accounts_service != null) {
            var layout = AccountsService.KeyboardLayout ();
            layout.backend = "xkb";
            layout.name = Configuration.get_default ().keyboard_layout;
            if (Configuration.get_default ().keyboard_variant != null) {
                layout.name += "+" + Configuration.get_default ().keyboard_variant;
            }

            accounts_service.keyboard_layouts = { layout };
        }
    }
}

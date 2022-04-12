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
    private Hdy.Deck deck;

    private AccountView account_view;
    private LanguageView language_view;
    private LocationView location_view;
    private KeyboardLayoutView keyboard_layout_view;
    private NetworkView network_view;

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

        deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (language_view);

        add (deck);

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

        if (account_view != null) {
            account_view.destroy ();
        }

        keyboard_layout_view = new KeyboardLayoutView ();

        deck.add (keyboard_layout_view);
        deck.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => load_network_view ());
    }

    private void load_network_view () {
        if (network_view != null) {
            network_view.destroy ();
        }

        if (!NetworkMonitor.get_default ().get_network_available ()) {
            network_view = new NetworkView ();

            deck.add (network_view);
            deck.visible_child = network_view;

            network_view.next_step.connect (load_location_view);
        } else {
            load_location_view ();
        }
    }

    private void load_location_view () {
        if (location_view != null) {
            location_view.destroy ();
        }

        location_view = new LocationView ();
        deck.add (location_view);
        deck.visible_child = location_view;

        location_view.next_step.connect (() => load_account_view ());
    }

    private void load_account_view () {
        if (account_view != null) {
            account_view.destroy ();
        }

        account_view = new AccountView ();
        deck.add (account_view);
        deck.visible_child = account_view;
    }

    private async void set_timezone () {
        try {
            LocationHelper.DateTime1 datetime1 = yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.timedate1", "/org/freedesktop/timedate1");
            unowned Configuration configuration = Configuration.get_default ();
            datetime1.set_timezone (configuration.timezone, true);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private async void set_clock_format () {
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
            warning ("Unable to get AccountsService proxy, clock format on new user may be incorrect: %s", e.message);
        }

        if (accounts_service != null) {
            accounts_service.clock_format = Configuration.get_default ().clock_format;
        }
    }

    private async void set_settings () {
        yield set_accounts_service_settings ();
        yield set_timezone ();
        yield set_clock_format ();
    }
}

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

            network_view.next_step.connect (load_account_view);
        } else {
            load_account_view ();
        }
    }

    private void load_account_view () {
        if (account_view != null) {
            account_view.destroy ();
        }

        account_view = new AccountView ();

        deck.add (account_view);
        deck.visible_child = account_view;

        account_view.next_step.connect (on_finish);
    }

    private void on_finish () {
        if (account_view.created != null) {
            set_settings.begin ((obj, res) => {
                set_settings.end (res);
                destroy ();
            });
        } else {
            destroy ();
        }

    }

    private async void set_settings () {
        yield set_accounts_service_settings ();
        yield set_locale ();
    }

    private async void set_locale () {
        string lang = Configuration.get_default ().lang;
        string? locale = null;
        bool success = yield LocaleHelper.language2locale (lang, out locale);

        if (!success || locale == null || locale == "") {
            warning ("Falling back to setting unconverted language as user's locale, may result in incorrect language");
            account_view.created.set_language (lang);
        } else {
            account_view.created.set_language (locale);
        }
    }

    private async void set_accounts_service_settings () {
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
}

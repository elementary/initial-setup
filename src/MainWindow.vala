// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2017 elementary LLC. (https://elementary.io)
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

public class Installer.MainWindow : Gtk.Window {
    private Gtk.Stack stack;

    private AccountView account_view;
    private LanguageView language_view;
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

        stack = new Gtk.Stack ();
        stack.margin_bottom = 12;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (language_view);

        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class ("default-decoration");
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Label (null));

        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);
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

        keyboard_layout_view.next_step.connect (() => load_account_view ());
    }

    private void load_account_view () {
        if (account_view != null) {
            account_view.destroy ();
        }

        account_view = new AccountView ();
        account_view.previous_view = keyboard_layout_view;
        stack.add (account_view);
        stack.visible_child = account_view;

        account_view.next_step.connect (on_finish);
    }

    private void on_finish () {
        if (account_view.created != null) {
            set_keyboard_and_locale.begin ((obj, res) => {
                set_keyboard_and_locale.end (res);
                destroy ();
            });
        } else {
            destroy ();
        }

    }

    private async void set_keyboard_and_locale () {
        yield set_keyboard_layout ();

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

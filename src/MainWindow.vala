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

public class Installer.MainWindow : Gtk.Window {
    private Adw.Leaflet leaflet;

    private AccountView account_view;
    private LanguageView language_view;
    private KeyboardLayoutView keyboard_layout_view;
    private NetworkView network_view;

    construct {
        language_view = new LanguageView ();

        leaflet = new Adw.Leaflet () {
            can_navigate_back = true,
            can_unfold = false
        };
        leaflet.append (language_view);

        child = leaflet;

        var titlebar = new Gtk.Label ("") {
            visible = false
        };
        set_titlebar (titlebar);

        language_view.next_step.connect (() => load_keyboard_view ());

        leaflet.notify["visible-child"].connect (() => {
            remove_forward_children ();
        });

        leaflet.notify["child-transition-running"].connect (() => {
            remove_forward_children ();
        });
    }

    private void remove_forward_children () {
        if (!leaflet.child_transition_running) {
            while (leaflet.get_adjacent_child (Adw.NavigationDirection.FORWARD) != null) {
                leaflet.remove (leaflet.get_adjacent_child (Adw.NavigationDirection.FORWARD));
            }
        }
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

        leaflet.append (keyboard_layout_view);
        leaflet.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => load_network_view ());
    }

    private void load_network_view () {
        if (network_view != null) {
            network_view.destroy ();
        }

        if (!NetworkMonitor.get_default ().get_network_available ()) {
            network_view = new NetworkView ();

            leaflet.append (network_view);
            leaflet.visible_child = network_view;

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

        leaflet.append (account_view);
        leaflet.visible_child = account_view;
    }
}

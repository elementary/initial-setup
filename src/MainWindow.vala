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
    private SoftwareView software_view;
    private ProgressView progress_view;

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

        account_view.next_step.connect (load_software_view);
    }

    private void load_software_view () {
        if (software_view != null) {
            software_view.destroy ();
        }

        software_view = new SoftwareView ();

        deck.add (software_view);
        deck.visible_child = software_view;

        software_view.next_step.connect (on_finish);
    }

    private void on_finish () {
        progress_view = new ProgressView ();
        deck.add (progress_view);
        deck.visible_child = progress_view;

        //  if (account_view.created_user != null) {
        //      unowned Configuration configuration = Configuration.get_default ();
        //      progress_view.progressbar_label.label = _("Setting language");
        //      account_view.created_user.set_language (configuration.lang);

        //      progress_view.progressbar_label.label = _("Setting keyboard layout");
        //      set_keyboard_and_locale.begin ((obj, res) => {
        //          set_keyboard_and_locale.end (res);

        //          install_additional_packages.begin ((obj, res) => {
        //              install_additional_packages.end (res);
        //              destroy ();
        //          });
        //      });
        //  } else {
        //      destroy ();
        //  }
    }

    private async void install_additional_packages () {
        unowned Configuration configuration = Configuration.get_default ();

        string[] additional_packages_to_install = {};
        if (configuration.install_additional_media_formats) {
            additional_packages_to_install += "gstreamer1.0-libav";
            additional_packages_to_install += "gstreamer1.0-plugins-bad";
            additional_packages_to_install += "gstreamer1.0-plugins-ugly";
        }

        additional_packages_to_install += null;

        if (additional_packages_to_install.length > 0) {
            var client = new Pk.Client ();
            var transaction_flags = Pk.Bitfield.from_enums (Pk.Filter.NEWEST, Pk.Filter.ARCH);

            yield client.refresh_cache_async (true, null, (progress, status) => {
                progress_view.progressbar.fraction = progress.percentage;
            });

            progress_view.progressbar_label.label = _("Refreshing the package cache");
            var results = yield client.resolve_async (transaction_flags, additional_packages_to_install, null, (progress, status) => {});
            var package_array = results.get_package_array ();

            string[] packages_ids = {};
            package_array.foreach ((package) => {
                packages_ids += package.package_id;
            });

            packages_ids += null;

            progress_view.progressbar_label.label = _("Installing additional packages");
            yield client.install_packages_async (transaction_flags, packages_ids, null, (progress, status) => {
                progress_view.progressbar.fraction = progress.percentage;
            });
        }
    }
}

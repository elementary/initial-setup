/*-
 * Copyright 2019 elementary, Inc (https://elementary.io)
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

public class InitialSetup.LocationLayout : GLib.Object {
    public string name { get; construct; }
    public string original_name { get; construct; }
    public string display_name {
        get {
            return name;
        }
    }

    private GLib.ListStore variants_store;

    public LocationLayout (string name, string original_name) {
        Object (name: name, original_name: original_name);
    }

    construct {
        variants_store = new GLib.ListStore (typeof (LocationVariant));
        variants_store.append (new LocationVariant (this, null, null));
    }

    public void add_variant (string name, string original_name) {
        var variant = new LocationVariant (this, name, original_name);
        variants_store.insert_sorted (variant, (GLib.CompareDataFunc<GLib.Object>) LocationVariant.compare);
    }

    public bool has_variants () {
        return variants_store.get_n_items () > 1;
    }

    public unowned GLib.ListStore get_variants () {
        return variants_store;
    }

    public GLib.Variant to_gsd_variant () {
        return new GLib.Variant ("(ss)", "xkb", name);
    }

    public static int compare (LocationLayout a, LocationLayout b) {
        return a.display_name.collate (b.display_name);
    }

    public static GLib.ListStore get_all () {
        var layout_store = new GLib.ListStore (typeof (LocationLayout));

        var continents = new List<string> ();
        continents.append ("Africa");
        continents.append ("America");
        continents.append ("Antarctica");
        continents.append ("Asia");
        continents.append ("Atlantic");
        continents.append ("Australia");
        continents.append ("Europe");
        continents.append ("Indian");
        continents.append ("Pacific");

        continents.foreach ((continent) => {
            var layout = new LocationLayout (_(continent), continent);
            layout_store.insert_sorted (layout, (GLib.CompareDataFunc<GLib.Object>) LocationLayout.compare);

            var timezones = LocationHelper.get_default ().get_timezones_from_continent (continent);
            timezones.foreach ((city, timezone) => {
                layout.add_variant (_(city), timezone);
            });
        });

        return layout_store;
    }
}

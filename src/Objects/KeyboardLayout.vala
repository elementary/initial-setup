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

public class InitialSetup.KeyboardLayout : GLib.Object {
    public string name { get; construct; }
    public string original_name { get; construct; }
    public string display_name {
        get {
            return dgettext ("xkeyboard-config", original_name);
        }
    }

    private GLib.ListStore variants_store;

    public KeyboardLayout (string name, string original_name) {
        Object (name: name, original_name: original_name);
    }

    construct {
        variants_store = new GLib.ListStore (typeof (KeyboardVariant));
        variants_store.append (new KeyboardVariant (this, null, null));
    }

    public void add_variant (string name, string original_name) {
        var variant = new KeyboardVariant (this, name, original_name);
        variants_store.insert_sorted (variant, (GLib.CompareDataFunc<GLib.Object>) KeyboardVariant.compare);
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

    public static int compare (KeyboardLayout a, KeyboardLayout b) {
        return a.display_name.collate (b.display_name);
    }

    public static GLib.ListStore get_all () {
        var layout_store = new GLib.ListStore (typeof (KeyboardLayout));
        unowned Xml.Doc* doc = Xml.Parser.read_file ("/usr/share/X11/xkb/rules/base.xml");

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        unowned Xml.XPath.Object* res = cntx.eval_expression ("/xkbConfigRegistry/layoutList/layout");
        if (res == null) {
            delete doc;
            critical ("Unable to parse 'base.xml'");
            return layout_store;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            critical ("No layouts found in 'base.xml'");
            return layout_store;
        }

        for (int i = 0; i < res->nodesetval->length (); i++) {
            unowned Xml.Node* layout_node = res->nodesetval->item (i);
            unowned Xml.Node* config_node = get_xml_node_by_name (layout_node, "configItem");
            unowned Xml.Node* variant_node = get_xml_node_by_name (layout_node, "variantList");
            unowned Xml.Node* description_node = get_xml_node_by_name (config_node, "description");
            unowned Xml.Node* name_node = get_xml_node_by_name (config_node, "name");
            if (name_node == null || description_node == null) {
                continue;
            }

        
            var layout = new KeyboardLayout (name_node->children->content, description_node->children->content);
            layout_store.insert_sorted (layout, (GLib.CompareDataFunc<GLib.Object>) KeyboardLayout.compare);

            if (variant_node != null) {
                for (unowned Xml.Node* variant_iter = variant_node->children; variant_iter != null; variant_iter = variant_iter->next) {
                    if (variant_iter->name == "variant") {
                        unowned Xml.Node* variant_config_node = get_xml_node_by_name (variant_iter, "configItem");
                        if (variant_config_node != null) {
                            unowned Xml.Node* variant_description_node = get_xml_node_by_name (variant_config_node, "description");
                            unowned Xml.Node* variant_name_node = get_xml_node_by_name (variant_config_node, "name");
                            if (variant_description_node != null && variant_name_node != null) {
                                layout.add_variant (variant_name_node->children->content, variant_description_node->children->content);
                            }
                        }
                    }
                }
            }
        }

        delete res;
        delete doc;
        return layout_store;
    }

    private static unowned Xml.Node* get_xml_node_by_name (Xml.Node* root, string name) {
        for (unowned Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                if (iter->name == name) {
                    return iter;
                }
            }
        }

        return null;
    }
}

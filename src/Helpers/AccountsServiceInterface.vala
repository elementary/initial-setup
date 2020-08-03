[DBus (name = "io.elementary.pantheon.AccountsService")]
interface Installer.AccountsService : Object {
    public struct Layout {
        public string backend;
        public string name;
    }

    public abstract Layout[] keyboard_layouts { owned get; set; }
    public abstract uint active_keyboard_layout { get; set; }
}

[DBus (name = "org.freedesktop.Accounts")]
interface Installer.FDO.Accounts : Object {
    public abstract string find_user_by_name (string username) throws GLib.Error;
}
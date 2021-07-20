[DBus (name = "io.elementary.SettingsDaemon.AccountsService")]
interface Installer.AccountsService : Object {
    public struct KeyboardLayout {
        public string backend;
        public string name;
    }

    public abstract KeyboardLayout[] keyboard_layouts { owned get; set; }
    public abstract uint active_keyboard_layout { get; set; }
    public abstract string clock_format { owned get; set; }
}

[DBus (name = "org.freedesktop.Accounts")]
interface Installer.FDO.Accounts : Object {
    public abstract string find_user_by_name (string username) throws GLib.Error;
}

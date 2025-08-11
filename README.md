# Initial Setup

[![Translation status](https://weblate.elementary.io/widgets/installer/-/initial-setup/svg-badge.svg)](https://l10n.elementary.io/projects/installer/initial-setup/?utm_source=widget)

An initial setup app to create new users

![Screenshot](data/screenshot-user.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* desktop-file-utils
* gettext
* libgranite-7-dev >= 7.4.0
* libaccountsservice-dev
* libgnomekbd-dev
* libgtk-4-dev >=4.14
* libadwaita-1-dev >= 1.4
* libjson-glib-dev
* libpwquality-dev
* libxkbregistry-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `io.elementary.initial-setup`

    sudo ninja install
    io.elementary.initial-setup

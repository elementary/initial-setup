# Initial Setup

[![Translation status](https://weblate.elementary.io/widgets/installer/-/initial-setup/svg-badge.svg)](https://l10n.elementary.io/projects/installer/initial-setup/?utm_source=widget)

An initial setup app to create new users

![screenshot@2x](https://user-images.githubusercontent.com/35162705/66404764-b4785880-ea06-11e9-8ebc-2eccce5bb92f.png)

## Building, Testing, and Installation

You'll need the following dependencies:
* desktop-file-utils
* gettext
* granite >= 0.5
* libaccountsservice-dev
* libgnomekbd-dev
* libgtk-3-dev
* libhandy-1-dev
* libjson-glib-dev
* libpwquality-dev
* libxml2-dev
* libxml2-utils
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `io.elementary.initial-setup`

    sudo ninja install
    io.elementary.initial-setup

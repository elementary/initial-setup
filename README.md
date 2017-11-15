# Initial Setup
An onboarding app for new installations

## Building, Testing, and Installation

You'll need the following dependencies:
* desktop-file-utils
* gettext
* libgnomekbd-dev
* libgtk-3-dev
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

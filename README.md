# Initial Setup
An onboarding app for new installations

## Building, Testing, and Installation

You'll need the following dependencies:
* libgtk-3-dev
* meson
* valac


Run `meson build` to configure the build environment and then change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.initial-setup`

    sudo ninja install
    io.elementary.initial-setup

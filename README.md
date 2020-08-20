# Spotlight
Spotlight for TwisterOS: OSX style app finder.

![Spotlight Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:

```
$ sudo apt install meson ninja-build libgee-0.8-dev libgnome-menu-3-dev cdbs valac libvala-*-dev libglib2.0-dev libwnck-3-dev libgtk-3-dev python3 python3-wheel python3-setuptools
```

Run `meson build` to configure the build environment:

    meson --prefix=/usr/local -Dbuildtype=release build
    
This command creates a `build` directory. For all following commands, change to
the build directory before running them.

To build spotlight, use `ninja`:

    ninja

To install, use `ninja install`

    ninja install

To use, add a keyboard shortcut to `spotlight`

    Open `xfce4-keyboard-settings` and go to Application Shortcuts. Click Add and enter `spotlight` in the Command field. Now click OK and choose your keyboard shortcut.

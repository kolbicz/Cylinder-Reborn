# Cylinder

![](https://github.com/rweichler/cylinder/blob/cb8f000dfb1045b9b7cb872ba9b8c843f7f73ebc/code.png)

## Download

## Latest version: 1.2.1

This fork combines upstream 1.2.0 with iPad rotation and icon-editing recovery,
CFPreferences-based settings, isolated jailbreak-root logs, and PreferenceLoader staging fixes.

Add the repo `https://kolbicz.github.io/repo/` in Sileo or Zebra to get updates
automatically, or download an explicitly named `rootless` or `roothide` package from the
[Releases page](https://github.com/kolbicz/Cylinder-Reborn/releases/latest).
Both variants require iOS 15 or later; select the package for your jailbreak environment.

Since 1.2.1 this fork is packaged as `cz.kolbi.cylinder`. It replaces
`com.ryannair05.cylinder`, so installing it removes the original package; your settings
and scripts carry over.

## what???

This is a jailbreak tweak that lets you animate your icons when you swipe pages on the SpringBoard.

Differences to Barrel:

1. Combining multiple effects
2. Effects are written in [Lua](http://lua.org/about.html)

With Lua, the effects can be modified and created using just
a text editor (scripts are stored in /Library/Cylinder). No knowledge of C or
Objective-C is necessary. A noob-friendly tutorial can be found [here](https://github.com/rweichler/cylinder/wiki/Installing-and-modifying-Lua-scripts).

Custom scripts can be submitted to [/r/cylinder](http://reddit.com/r/cylinder).

If you want to make your own effects, check out [any of the 53 scripts that are bundled with Cylinder](https://github.com/ryannair05/Cylinder-Reborn/tree/master/scripts).
If you need more in-depth documentation you can check out [EXAMPLE.lua](https://github.com/ryannair05/Cylinder-Reborn/blob/master/scripts/EXAMPLE.lua) as well.
Once you've made your own effect, make a folder with
your name in /Library/Cylinder on your phone (like
/Library/Cylinder/rweichler), drop your scripts in,
and it should appear in settings (no respring required).

Targets iOS and iPadOS 15 and later. Device testing is needed for each jailbreak and OS version.

# How to build/install this

This is for people that would like to contribute to the core (C / Objective-C) framework.
If you would like to create your own scripts, no extra setup is necessary. Just install Cylinder Reborn
on Cydia or Sileo and follow the instructions above.

## Dependencies

* macOS with Xcode
* [Theos](https://theos.dev/docs/installation)
* A suitable iPhoneOS SDK in `$THEOS/sdks`; local validation used 15.6 for rootless and 16.5 for roothide.
* Roothide packages require roothide Theos.

Lua is included as a git submodule and built with the tweak, so it does not need to be installed separately.
Rootless script loading uses libroot; native roothide builds use the roothide path APIs.
Logs and effect error reports stay inside the jailbreak root. Preferences use CFPreferences so the
jailbreak's preference redirection can apply to both SpringBoard and Settings.

## Setup

Clone the repository with its Lua submodule and cd into it

```
git clone --recursive https://github.com/kolbicz/Cylinder-Reborn.git
cd Cylinder-Reborn
```

If you already cloned it without `--recursive`, run `git submodule update --init`.

## Building

For a rootless .deb (iOS 15 and later):

```
make package
```

For a roothide .deb, use roothide Theos:

```
make package THEOS=/path/to/roothide-theos THEOS_PACKAGE_SCHEME=roothide
```

Packages are written to `packages/`. To build and install on your device over SSH, run this:

```
make do THEOS_DEVICE_IP=iphone_wifi_ip_here
```

Your device needs OpenSSH installed for the installation to work.

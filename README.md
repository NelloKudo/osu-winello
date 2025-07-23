# osu-winello
osu! stable installer for Linux with patched wine-osu and other features.

![ezgif com-video-to-gif(1)](https://user-images.githubusercontent.com/98063377/224407211-70fa648c-b96f-442b-b5f5-eaf28a84670a.gif)

# Index

- [Installation](#installation)
	- [Prerequisites](#prerequisites)
 		- [Drivers](#drivers)		 
		- [PipeWire](#pipewire)
	- [Installing osu!](#installing-osu)
- [Features](#features)
- [Customization](#customization)
- [Optimizations](#optimizations)
- [Troubleshooting](#troubleshooting)
- [Flags](#flags)
- [Steam Deck Support](#steam-deck-support)
- [Credits](#credits)

# Installation

## Prerequisites 

The only requirements, besides **64-bit graphics drivers**, are `git`, `zenity`, `wget`, `unzip` and `xdg-desktop-portal-gtk` (for in-game links).

You can easily install them like this:

**Ubuntu/Debian:** `sudo apt install -y git wget unzip zenity xdg-desktop-portal-gtk`

**Arch Linux:** `sudo pacman -Syu --needed  --noconfirm git wget unzip zenity xdg-desktop-portal-gtk`

**Fedora:** `sudo dnf install -y git wget unzip zenity xdg-desktop-portal-gtk`

**openSUSE:** `sudo zypper install -y git wget unzip zenity xdg-desktop-portal-gtk`

## Drivers:

As obvious as this might sound, installing drivers the **right** way is needed to have a great experience overall
and avoid poor performance or other problems. 

Keep in mind that osu! needs **64-bit graphics drivers** in order to run as it should, so
if you're having performance problems, it's probably related to this.

This is usually something like `nvidia-utils` or `nvidia-driver` for NVIDIA, and `libgl1-mesa-dri` for AMD/Intel.

You may find more helpful instructions for your distro here (only 64-bit is required):
- [Installing Drivers](https://github.com/lutris/docs/blob/master/InstallingDrivers.md)

If you're still confused, try installing Steam with your package manager. That will install the necessary drivers for your distro.

## PipeWire:

`PipeWire` **isn't really a dependency but is highly recommended, especially with this script.**

Check if it's already on your system with:

```
export LANG=C
pactl info | grep "Server Name"
```

If it shows `Server Name: PulseAudio (on Pipewire)` , then you're good to go. 

Otherwise, make sure to install it following the instructions at here: 
- [Installing PipeWire](https://github.com/NelloKudo/osu-winello/wiki/Installing-PipeWire)

## Installing osu!:
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
./osu-winello.sh
```

You can now launch osu! with:
```
osu-wine
```
### ⚠ **!! \o/ !!** ⚠ :
- You might need to relaunch your terminal to launch the game.
- Use **-40/35ms** global offset to make up for Wine quirks (or -25 if you're using audio compatibility mode). These values work for most setups, but your mileage may vary. Keep an eye on the hit meter!

# Features:
- Comes with **updatable patched** [wine-osu](https://github.com/NelloKudo/WineBuilder/releases) binaries with the latest osu! patches for low-latency audio, better performance, alt-tab behavior, crashes fixes and more.
- Uses [yawl](https://github.com/whrvt/yawl) to run wine-osu in Steam's runtime, providing great performance on every system without needing to download dependencies.
- Provides [osu-handler](https://aur.archlinux.org/packages/osu-handler) for importing maps and skins, Discord RPC with [rpc-bridge](https://github.com/EnderIce2/rpc-bridge) and support for native file managers!
- Supports the latest [tosu](https://github.com/KotRikD/tosu) and legacy [gosumemory](https://github.com/l3lackShark/gosumemory) for streaming etc. with automatic install! (Check [flags](#flags)!)
- Installs osu! on either default or custom path (using the zenity GUI), also working for already existing osu! installations from Windows!
- Skips the pain of downloading Wineprefix thanks to [my fork](https://gitlab.com/NelloKudo/osu-winello-prefix) of [osu-wineprefix](https://gitlab.com/osu-wine/osu-wineprefix)
- Support for Windows fonts pre-installed in Wine (JP fonts, special characters etc.)

For a clearer overview of everything the script does, DeepWiki did a great job summarizing it. Check it out:
- [deepwiki/osu-winello](https://deepwiki.com/NelloKudo/osu-winello)

# Customization

Winello allows you to set launch arguments or custom environment variables using `.cfg` files located in:

```
~/.local/share/osuconfig/configs
```

An `example.cfg` file is provided, containing all supported environment variables along with usage instructions.

### Example  
To add `mangohud` to the launch arguments, edit the configuration file:

```sh
nano ~/.local/share/osuconfig/configs/example.cfg
# or simply: osu-wine --edit-config
```

There, uncomment the existing `# PRE_LAUNCH_ARGS=""` line (remove the #), or add a new one, like so:

```sh
PRE_LAUNCH_ARGS="mangohud"
```

If you want to always run on a custom server, just edit `POST_LAUNCH_ARGS` in a similar fashion. An example is shown in the same file.

# Optimizations

Due to the vast variety of distributions and setups, follow the guide below to optimize your osu! performance:
- [Optimizing: osu! performance](https://github.com/NelloKudo/osu-winello/wiki/Optimizing:-osu!-performance) 

# Troubleshooting

Please refer to [osu-winello's wiki](https://github.com/NelloKudo/osu-winello/wiki) for troubleshooting of any type. 

If that doesn't help, either:
- Join [ThePooN's Discord](https://discord.gg/bc4qaYjqyT) and ask in #osu-linux, they'll know how to help! <3
- Write me on Discord (marshnello)

# Flags:
**Installation script:** 
```
./osu-winello.sh: Installs the game
./osu-winello.sh --no-deps: Installs the game but skips installing dependencies
./osu-winello.sh uninstall: Uninstalls the game
./osu-winello.sh fix-yawl: Tries to fix yawl issues (partial downloads, corruption etc.)
```

**Game script:**

```
osu-wine: Runs osu!
osu-wine --help: Show this help
osu-wine --info: Troubleshooting and more info
osu-wine --edit-config: Open your configuration file to edit launch arguments and other customizations
osu-wine --winecfg : Runs winecfg on the osu! Wineprefix
osu-wine --winetricks: Install packages on osu! Wineprefix
osu-wine --regedit: Opens regedit on osu! Wineprefix
osu-wine --wine <args>: Runs wine + your arguments as if it was normal wine
osu-wine --kill: Kills osu! and related processes in osu! Wineprefix
osu-wine --kill9: Kills osu! but with wineserver -k9
osu-wine --update: Updates wine-osu to the latest version
osu-wine --fixprefix: Reinstalls the osu! Wineprefix from system
osu-wine --fixfolders: Reconfigure osu-handler and native file integration (run this if osu!direct/.osz/.osk/opening folders from ingame is broken)
osu-wine --fix-yawl: Reinstalls files related to yawl and the Steam Runtime in case something went wrong
osu-wine --fixrpc: Reinstalls rpc-bridge if needed!
osu-wine --remove: Uninstalls osu! and the script
osu-wine --changedir: Changes directory of the install according to the user
osu-wine --devserver <address>: Runs osu with an alternative server (e.g. --devserver akatsuki.gg)
osu-wine --runinprefix <file>: Launches a custom executable within osu!'s Wineprefix
osu-wine --osuhandler <beatmap, skin..>: Launches osu-handler-wine with the specified file/link
osu-wine --gosumemory: Installs and runs gosumemory without any needed config!
osu-wine --tosu: Installs and runs tosu without any needed config!
osu-wine --disable-memory-reader: Turn off gosumemory and tosu
```

NOTE: Any command can be prefixed by the letter 'n' to avoid updating when running it.

e.g. `osu-wine n --fixprefix` will run `--fixprefix` without overwriting any of your files from the osu-winello git repo

# Steam Deck Support

Since osu! runs on Wine in the Steam Linux Runtime (same as Proton), you should be able to play on Steam Deck as well!

It is recommended to not manually install PipeWire on the Steam Deck as it is already installed by default and attempting to do so may cause audio issues.

# Credits

Special thanks to:

- [whrvt aka spectator](https://github.com/whrvt/wine-osu-patches) for his help with Wine, Proton and related, never failed to solve any issue :')
- [ThePooN's Discord](https://discord.gg/bc4qaYjqyT) for supporting Winello since its early stages!
- [gonX's wine-osu](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
- [Integrating native file manager by Maot](https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2)
- [KatouMegumi's guide](https://wiki.archlinux.org/title/User:Katoumegumi#osu!_(stable)_on_Arch_Linux)
- [hwsnemo's wine-osu](https://software.opensuse.org//download.html?project=home%3Ahwsnemo%3Apackaged-wine-osu&package=wine-osu)
- [diamondburned's osu-wine](https://gitlab.com/osu-wine/osu-wine)
- [openglfreak's packages](https://github.com/openglfreak)
- [EnderIce2's rpc-bridge](https://github.com/EnderIce2/rpc-bridge)
- Last but not least, every contributor. Thanks for making Winello even better!

And that's all. Have fun playing osu!

## Check the guide above for troubleshooting or extra tools!


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
- [Troubleshooting](#troubleshooting)
- [Flags](#flags)
- [Steam Deck Support](#steam-deck-support)
- [Credits](#credits)

# Installation

## Prerequisites 

The only real requirement is actually `git`, as the script will install the rest itself.
You can easily get it like this:

**Ubuntu/Debian:** `sudo apt install -y git`

**Arch Linux:** `sudo pacman -Sy --needed  --noconfirm git`

**Fedora:** `sudo dnf install -y git`

**openSUSE:** `sudo zypper install -y git`

**Gentoo:** `sudo emerge --noreplace dev-vcs/git`

## Drivers:

As obvious as this might sound, installing drivers the **right** way is needed to have a great experience overall
and avoid poor performance or other problems. 

Keep in mind that osu! needs **lib32 drivers** in order to run as it should, so
if you're having performance problems, it's probably related to this.

Please make sure to follow the instructions below:
- [Installing Drivers](https://github.com/lutris/docs/blob/master/InstallingDrivers.md)

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
git clone https://github.com/NelloKudo/osu-winello.git --branch=winello-legacy
cd osu-winello
chmod +x ./osu-winello.sh
./osu-winello.sh

## OR

## If you wanna install without dependencies
./osu-winello.sh --no-deps

## If you want a clean install without tweaks (advanced)  (--no-deps also works here)
./osu-winello.sh --basic
```

You can now launch osu! with:
```
osu-wine
```
### ⚠ **!! \o/ !!** ⚠ :
- You might need to relaunch your terminal to launch the game.
- Use **-40/35ms** offset to make up for Wine quirks (or -25 if you're using audio compatibility mode)

# Features:
- Comes with **updatable patched** [wine-osu](https://gist.github.com/NelloKudo/b6f6d48807548bd3cacd3018a1cadef5) binaries with the latest community patches for low-latency and crashes.
- Automatic install of dependencies on most distros (apt, pacman, dnf, zypper..)
- Provides [osu-handler](https://aur.archlinux.org/packages/osu-handler) for importing maps and skins, Discord RPC with [winestreamproxy](https://github.com/openglfreak/winestreamproxy) and support for native file managers!
- Supports [gosumemory](https://github.com/l3lackShark/gosumemory) for streaming etc. with automatic install! (Check [flags](#flags)!)
- Installs osu! on either default or custom path (using GUI), also working for already existing osu! installations from Windows!
- Skips the pain of downloading prefix stuff thanks to [my fork](https://gitlab.com/NelloKudo/osu-winello-prefix) of [osu-wineprefix](https://gitlab.com/osu-wine/osu-wineprefix)
- Support for installing Windows fonts (fix for Japanese and special characters)
- Support for old distros (binaries built on GLIBC 2.27)
- Support for Lutris

# Troubleshooting

Please refer to [osu-winello's wiki](https://github.com/NelloKudo/osu-winello/wiki) for troubleshooting of any type. 

If that doesn't help, either:
- Write me on Discord (marshnello)
- Join [ThePooN's Discord](https://discord.gg/bc4qaYjqyT), you might learn even more there hehe

# Flags:
**Installation script:** 
```
./osu-winello.sh: Installs the game
./osu-winello.sh --no-deps: Installs the game but skips installing dependencies
./osu-winello.sh --basic: Installs the game with only dotnet40 and w/o tweaks
./osu-winello.sh uninstall: Uninstalls the game
```

**Game script:**
```
osu-wine: Runs osu!
osu-wine --winecfg : Runs winecfg on the osu! Wineprefix
osu-wine --winetricks: Install packages on osu! Wineprefix
osu-wine --regedit: Opens regedit on osu! Wineprefix
osu-wine --kill: Kills osu! and related processes in osu! Wineprefix
osu-wine --kill9: Kills osu! but with wineserver -k9
osu-wine --update: Updates wine-osu to latest version
osu-wine --w10fonts: Installs Windows 10 fonts from GitHub for osu! (Needed for JP characters etc.)
osu-wine --fixprefix: Reinstalls the osu! Wineprefix from system
osu-wine --info: Troubleshooting and more info
osu-wine --remove: Uninstalls osu! and the script
osu-wine --lutris: Copies wine-osu to lutris and shows instructions to add osu! there
osu-wine --changedir: Changes directory of the install according to the user
osu-wine --devserver <server>: Runs osu on the specified devserver
osu-wine --fixfolders: Reinstalls registry keys for native file manager in case they break
osu-wine --fixsteamdeck: Reinstalls game dependencies after SteamOS updates
osu-wine --gosumemory: Installs and runs gosumemory without any needed config!
```

# Steam Deck Support

Since osu! runs on Wine, you can play that on Steam Deck as well!

It is recommended to not manually install PipeWire on the Steam Deck as it is already installed by default and attempting to do so may cause audio issues.

Before using the script, make sure to:
- Set a password using the `passwd` command
- Disable read-only filesystem with `sudo steamos-readonly disable`

If you need help with pacman or just want reliable info, check these two links: [Link 1](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C) -- [Link 2](https://www.reddit.com/r/SteamDeck/comments/t8al0i/install_arch_packages_on_your_steam_deck/)

The script will handle the rest itself, but you might need to reinstall dependencies after every Deck update (read more [here](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)); you can simply do that with:

```osu-wine --fixsteamdeck``` 


# Credits

Special thanks to:

- [ThePooN's Discord](https://discord.gg/bc4qaYjqyT)
- [gonX's wine-osu](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
- [Integrating native file manager by Maot](https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2)
- [KatouMegumi's guide](https://wiki.archlinux.org/title/User:Katoumegumi#osu!_(stable)_on_Arch_Linux)
- [hwsnemo's wine-osu](https://software.opensuse.org//download.html?project=home%3Ahwsnemo%3Apackaged-wine-osu&package=wine-osu)
- [diamondburned's osu-wine](https://gitlab.com/osu-wine/osu-wine)
- [openglfreak's packages](https://github.com/openglfreak)

And that's all. Have fun playing osu!

## Check the guide above for troubleshooting or extra tools!


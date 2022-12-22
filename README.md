# osu-winello
osu! stable installer for Linux with patched wine-osu and other features.

![2022-04-14_18-56](https://user-images.githubusercontent.com/98063377/163437506-cfb2dec3-653d-4819-8fd8-fd17d2c7f20c.jpg)

# Index

- [Installation](#installation)
	- [Prerequisites](#prerequisites)
		- [PipeWire](#pipewire)
	- [Installing osu!](#installing-osu)
- [Features](#features)
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

## PipeWire:

`PipeWire` **isn't really a dependency but is highly recommended, especially with this script.**

You can install it like this:

### Debian (Ubuntu, Linux Mint, Pop!_OS etc..):

```
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream
sudo apt update
sudo apt install -y pipewire libspa-0.2-bluetooth pipewire-audio-client-libraries
sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream
sudo apt update 
sudo apt install -y wireplumber
systemctl --user daemon-reload
systemctl --user --now disable pulseaudio.service pulseaudio.socket
systemctl --user mask pulseaudio
systemctl --user --now enable pipewire pipewire-pulse
```

### Arch Linux (Manjaro, Endeavour OS, etc.):
  
**Remove PulseAudio:** `sudo pacman -Rdd pulseaudio`
 
And then:
  
```  
sudo pacman -Sy --needed --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber
systemctl --user enable --now pipewire.service pipewire.socket pipewire-media-session.service pipewire-pulse.service pipewire-pulse.socket
``` 

Manjaro users can instead use their distro's package: `sudo pacman -S --needed --noconfirm manjaro-pipewire`
 
### Fedora:
 
**Fedora's latest versions already ship with Pipewire ; you might want to check with this:**
  
```   
sudo dnf install pulseaudio-utils
pactl info
``` 

Rebooting your system is recommended e.e


## Installing osu!:
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
./osu-winello.sh

## OR

./osu-winello.sh --basic #if you want a clean install without tweaks (advanced)
```

You can now launch osu! with:
```osu-wine```

**WARNING: you might need to close and relaunch your terminal to use the command.**

__General recommendations__: use -40/35ms offset to make up for Wine (or -25 if you're using audio compatibility mode)

# Features:

- installs every needed wine dependency by itself (for distros using apt, pacman and dnf)
- comes with utilities like osu-handler, Discord RPC (winestreamproxy) and native support for Linux file managers!
- uses patched [wine-osu](https://gist.github.com/NelloKudo/b6f6d48807548bd3cacd3018a1cadef5) binaries with the latest community patches, you can read more [here](https://gist.github.com/NelloKudo/b6f6d48807548bd3cacd3018a1cadef5) and support updates according to the repo!
- installs osu! on either default or custom path (using GUI) 
- integrates with both already existing osu! installations from Windows or with [diamondburned's osu-wine](https://gitlab.com/osu-wine/osu-wine)
- skips the pain of downloading prefix stuff thanks to [my fork](https://gitlab.com/NelloKudo/osu-winello-prefix) of [osu-wineprefix](https://gitlab.com/osu-wine/osu-wineprefix)
- support for installing Windows fonts (fix for Japanese and special characters)
- support for old distros too! (binaries built on GLIBC 2.27)
- lutris support

This script is based on the [guide](https://osu.ppy.sh/community/forums/topics/1248084?n=1) I've written on the osu! website: more troubleshooting on the game itself can be found there e.e

# Flags:
**Installation script:** 
```
./osu-winello.sh # Installs the game
./osu-winello.sh --basic # Installs the game with only dotnet40 and w/o tweaks
./osu-winello.sh uninstall # Uninstalls the game
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
osu-wine --w10fonts: Installs Windows 10 fonts from either GitHub or ISO (Needed for JP characters etc.)
osu-wine --fixprefix: Reinstalls the osu! Wineprefix from system
osu-wine --info: Troubleshooting and more info
osu-wine --remove: Uninstalls osu! and the script
osu-wine --lutris: Copies wine-osu to lutris and shows instructions to add osu! there
osu-wine --changedir: Changes directory of the install according to the user
osu-wine --devserver <server>: Runs osu on the specified devserver
osu-wine --fixfolders: Reinstalls registry keys for native file manager in case they break
osu-wine --fixsteamdeck: Reinstalls game dependencies after SteamOS updates
```

# Steam Deck Support

Since osu! runs on Wine, you can play that on Steam Deck as well!

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


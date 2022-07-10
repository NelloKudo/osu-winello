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
systemctl --user --now enable pipewire-media-session.service pipewire pipewire-pulse
```

### Arch Linux (Manjaro, Endeavour OS, etc.):
  
**Remove PulseAudio:** `sudo pacman -Rdd pulseaudio`
 
And then:
  
```  
sudo pacman -Sy --needed --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber
``` 
 
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
- uses patched wine-osu with the latest community patches (audio, fsync etc. by gonX/oglfreak)
- works on most recent distros (script checks for glibc (2.31) itself)
- installs osu! on either default or custom path (using GUI) 
- integrates with both already existing osu! installations from Windows or with [diamondburned's osu-wine](https://gitlab.com/osu-wine/osu-wine)
- skips the pain of downloading prefix stuff thanks to https://gitlab.com/osu-wine/osu-wineprefix
- support for installing Windows fonts (fix for Japanese and special characters)
- updates wine-osu's version according to the repo

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
osu-wine --lutris: Copies wine-osu to lutris (only the Wine version)
osu-wine --devserver <server>: Runs osu on the specified devserver
```

# Credits

Special thanks to:

- [ThePooN's Discord](https://discord.gg/bc4qaYjqyT)
- [gonX's wine-osu](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
- [Integrating native file manager by Maot](https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2)
- [KatouMegumi's guide](https://wiki.archlinux.org/title/User:Katoumegumi#osu!_(stable)_on_Arch_Linux)
- [hwsnemo's wine-osu](https://software.opensuse.org//download.html?project=home%3Ahwsnemo%3Apackaged-wine-osu&package=wine-osu)
- [diamondburned's osu-wine](https://gitlab.com/osu-wine/osu-wine)
- [ttf-win10 on AUR](https://aur.archlinux.org/packages/ttf-win10)

And that's all. Have fun playing osu!

## Check the guide above for troubleshooting or extra tools!


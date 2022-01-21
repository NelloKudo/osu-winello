# osu-winello
osu! installer for Linux with pre-packaged Wineprefix and patched wine-osu.

![HJuwGZG_840x480](https://user-images.githubusercontent.com/98063377/150559685-50bbfeb2-aecf-495f-86f6-cbd3f89f3b81.jpg)

# Installation

## Prerequisites

This package is based on the [guide](https://osu.ppy.sh/community/forums/topics/1248084?n=1) I've written on the osu! website: check the prerequisites listed there.
It also depends on Pipewire: instructions for most distros are there as well.
Go to: [osu! guide](https://osu.ppy.sh/community/forums/topics/1248084?n=1)

## Instructions:
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
sudo ./osu-winello.sh
```

You can now launch osu! with:
```osu-wine```

## Flags:
**Installation script:** 
```
sudo ./osu-winello.sh # Installs the game
sudo ./osu-winello.sh uninstall # Uninstalls the game
sudo ./osu-winello.sh update" # Updates wine-osu version
sudo ./osu-winello.sh help # Shows the previous commands
```

**Game script:**
```
osu-wine: Runs osu!
osu-wine --winecfg : Runs winecfg on the osu! Wineprefix  
osu-wine --winetricks: Install packages on osu! Wineprefix
osu-wine --update: Updates wine-osu to latest version"
```

And that's all. Have fun playing osu!

## Check the guide above for troubleshooting or extra tools!


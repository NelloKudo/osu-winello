# osu-winello
osu! stable installer for steam deck with patched wine-osu and other features.

## Installing osu!:
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
./osu-winello.sh
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
- lutris support

This script is based on the [guide](https://osu.ppy.sh/community/forums/topics/1248084?n=1) I've written on the osu! website: more troubleshooting on the game itself can be found there e.e

# Flags:
**Installation script:** 
```
./osu-winello.sh # Installs the game
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
```

And that's all. Have fun playing osu!

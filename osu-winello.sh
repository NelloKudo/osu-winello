#!/usr/bin/env bash

#   =======================================
#   Welcome to Winello!
#   The whole script is divided in different
#   functions to make it easier to read.
#   Feel free to contribute!
#   =======================================

# The URL for this git repo
WINELLOGIT="https://github.com/NelloKudo/osu-winello.git"

# The directory osu-winello.sh is in
SCRDIR="$(realpath "$(dirname "$0")")"

# Wine-osu current versions for update
MAJOR=10
MINOR=3
PATCH=5
WINEVERSION=$MAJOR.$MINOR.$PATCH
LASTWINEVERSION=0

# Wine-osu mirror
WINELINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-staging-$MAJOR.$MINOR-$PATCH-yawl-test/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

# Other versions for external downloads
DISCRPCBRIDGEVERSION=1.2
GOSUMEMORYVERSION=1.3.9
TOSUVERSION=4.3.1
YAWLVERSION=0.5.5

# Other download links
PREFIXLINK="https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.tar.xz" # Default WINEPREFIX
OSUMIMELINK="https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz"                       # osu-mime (file associations)
YAWLLINK="https://github.com/whrvt/yawl/releases/download/v${YAWLVERSION}/yawl"                     # yawl (Wine launcher for Steam Runtime)

OSUDOWNLOADURL="https://m1.ppy.sh/r/osu!install.exe"

DISCRPCLINK="https://github.com/EnderIce2/rpc-bridge/releases/download/v${DISCRPCBRIDGEVERSION}/bridge.zip"
GOSUMEMORYLINK="https://github.com/l3lackShark/gosumemory/releases/download/${GOSUMEMORYVERSION}/gosumemory_windows_amd64.zip"
TOSULINK="https://github.com/tosuapp/tosu/releases/download/v${TOSUVERSION}/tosu-windows-v${TOSUVERSION}.zip"

# Exported global variables

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export BINDIR="${BINDIR:-$HOME/.local/bin}"

export WINEPREFIX="${WINEPREFIX:-"$XDG_DATA_HOME/wineprefixes/osu-wineprefix"}"
export WINE_PATH="${WINE_PATH:-"$XDG_DATA_HOME/osuconfig/wine-osu"}"

export WINEDLLOVERRIDES="winemenubuilder.exe=;" # Blocks wine from creating .desktop files

export WINENTSYNC="0" # Don't use these for setup-related stuff to be safe
export WINEFSYNC="0"
export WINEESYNC="0"

# Other shell local variables
YAWL_INSTALL_PATH="${YAWL_INSTALL_PATH:-"$XDG_DATA_HOME/osuconfig/yawl"}"
YAWL_PATH="${YAWL_INSTALL_PATH}-winello"

#   =====================================
#   =====================================
#           INSTALLER FUNCTIONS
#   =====================================
#   =====================================

# Simple echo function (but with cool text e.e)
Info() {
    echo -e '\033[1;34m'"Winello:\033[0m $*"
}

Warning() {
    echo -e '\033[0;33m'"Winello (WARNING):\033[0m $*"
}

# Function to quit the install but not revert it in some cases
Quit() {
    echo -e '\033[1;31m'"Winello:\033[0m $*"
    exit 1
}

# Function to revert the install in case of any type of fail
Revert() {
    echo -e '\033[1;31m'"Reverting install...:\033[0m"
    rm -f "$XDG_DATA_HOME/icons/osu-wine.png"
    rm -f "$XDG_DATA_HOME/applications/osu-wine.desktop"
    rm -f "$BINDIR/osu-wine"
    rm -rf "$XDG_DATA_HOME/osuconfig"
    rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"
    rm -f "/tmp/osu-mime.tar.xz"
    rm -rf "/tmp/osu-mime"
    rm -f "$XDG_DATA_HOME/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop"
    rm -f "/tmp/winestreamproxy-2.0.3-amd64.tar.xz"
    rm -rf "/tmp/winestreamproxy"
    echo -e '\033[1;31m'"Reverting done, try again with ./osu-winello.sh\033[0m"
}

# Error function pointing at Revert(), but with an appropriate message
InstallError() {
    echo -e '\033[1;31m'"Script failed:\033[0m $*"
    Revert
    exit 1
}

# Error function for other features besides install
Error() {
    echo -e '\033[1;31m'"Script failed:\033[0m $*"
    exit 1
}

# Function looking for basic stuff needed for installation
InitialSetup() {
    # Better to not run the script as root, right?
    if [ "$USER" = "root" ]; then InstallError "Please run the script without root"; fi

    # Checking for previous versions of osu-wine (mine or DiamondBurned's)
    if [ -e /usr/bin/osu-wine ]; then Quit "Please uninstall old osu-wine (/usr/bin/osu-wine) before installing!"; fi
    if [ -e "$BINDIR/osu-wine" ]; then Quit "Please uninstall Winello (osu-wine --remove) before installing!"; fi

    Info "Welcome to the script! Follow it to install osu! 8)"

    # Setting root perms. to either 'sudo' or 'doas'
    root_var="sudo"
    if command -v doas >/dev/null 2>&1; then
        doascheck=$(doas id -u)
        if [ "$doascheck" = "0" ]; then
            root_var="doas"
        fi
    fi

    # Checking if $BINDIR is in PATH:
    mkdir -p "$BINDIR"
    pathcheck=$(echo "$PATH" | grep -q "$BINDIR" && echo "y")

    # If $BINDIR is not in PATH:
    if [ "$pathcheck" != "y" ]; then

        if grep -q "bash" "$SHELL"; then
            touch -a "$HOME/.bashrc"
            echo "export PATH=$BINDIR:$PATH" >>"$HOME/.bashrc"
        fi

        if grep -q "zsh" "$SHELL"; then
            touch -a "$HOME/.zshrc"
            echo "export PATH=$BINDIR:$PATH" >>"$HOME/.zshrc"
        fi

        if grep -q "fish" "$SHELL"; then
            mkdir -p "$HOME/.config/fish" && touch -a "$HOME/.config/fish/config.fish"
            fish_add_path "$BINDIR/"
        fi
    fi

    # Well, we do need internet ig...
    Info "Checking for internet connection.."
    ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && ! ping -c 1 google.com >/dev/null 2>&1 && InstallError "Please connect to internet before continuing xd. Run the script again"

    # Looking for dependencies..
    deps=(wget zenity unzip)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            InstallError "Please install $dep before continuing!"
        fi
    done
}

# Function to install script files, yawl and Wine-osu
InstallWine() {
    # Installing game launcher and related...
    Info "Installing game script:"
    cp "${SCRDIR}/osu-wine" "$BINDIR/osu-wine" && chmod +x "$BINDIR/osu-wine"

    Info "Installing icons:"
    mkdir -p "$XDG_DATA_HOME/icons"
    cp "${SCRDIR}/stuff/osu-wine.png" "$XDG_DATA_HOME/icons/osu-wine.png" && chmod 644 "$XDG_DATA_HOME/icons/osu-wine.png"

    Info "Installing .desktop:"
    mkdir -p "$XDG_DATA_HOME/applications"
    echo "[Desktop Entry]
Name=osu!
Comment=osu! - Rhythm is just a *click* away!
Type=Application
Exec=$BINDIR/osu-wine %U
Icon=$XDG_DATA_HOME/icons/osu-wine.png
Terminal=false
Categories=Wine;Game;" | tee "$XDG_DATA_HOME/applications/osu-wine.desktop" >/dev/null
    chmod +x "$XDG_DATA_HOME/applications/osu-wine.desktop"

    if [ -d "$XDG_DATA_HOME/osuconfig" ]; then
        Info "Skipping osuconfig.."
    else
        mkdir "$XDG_DATA_HOME/osuconfig"
    fi

    Info "Installing Wine-osu:"
    # Downloading Wine..
    wget -O "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" "$WINELINK" && chk="$?"
    if [ ! "$chk" = 0 ]; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" "$WINELINK" || InstallError "Download failed, check your connection"
    fi

    # This will extract Wine-osu and set last version to the one downloaded
    tar -xf "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
    LASTWINEVERSION="$WINEVERSION"
    rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

    Info "Installing yawl-winello:"
    # Downloading yawl and creating a wrapper for osu-winello!
    wget -O "/tmp/yawl" "$YAWLLINK" && chk="$?"
    if [ ! "$chk" = 0 ]; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/yawl" "$YAWLLINK" || InstallError "Download failed, check your connection"
    fi
    mv "/tmp/yawl" "$XDG_DATA_HOME/osuconfig"
    chmod +x "$YAWL_INSTALL_PATH"

    # Install and verify yawl ASAP, the wrapper mode does not download/install the runtime if no arguments are passed
    YAWL_VERBS="make_wrapper=winello;exec=$WINE_PATH/bin/wine;wineserver=$WINE_PATH/bin/wineserver" "$YAWL_INSTALL_PATH"

    YAWL_VERBS="verify" "$YAWL_PATH" "--version" || InstallError "There was an error setting up yawl!"

    # The update function works under this folder: it compares variables from files stored in osuconfig
    # with latest values from GitHub and check whether to update or not
    Info "Installing script copy for updates.."
    mkdir -p "$XDG_DATA_HOME/osuconfig/update"

    { git clone . "$XDG_DATA_HOME/osuconfig/update" || git clone "${WINELLOGIT}" "$XDG_DATA_HOME/osuconfig/update"; } ||
        InstallError "Git failed, check your connection.."

    git -C "$XDG_DATA_HOME/osuconfig/update" remote set-url origin "${WINELLOGIT}"

    echo "$LASTWINEVERSION" >>"$XDG_DATA_HOME/osuconfig/wineverupdate"
}

# Function configuring folders to install the game
ConfigurePath() {
    Info "Configuring osu! folder:"
    Info "Where do you want to install the game?: 
          1 - Default path ($XDG_DATA_HOME/osu-wine)
          2 - Custom path"
    read -r -p "$(Info "Choose your option: ")" installpath

    if [ "$installpath" = 1 ] || [ "$installpath" = 2 ]; then
        case "$installpath" in
        '1')
            mkdir -p "$XDG_DATA_HOME/osu-wine"
            GAMEDIR="$XDG_DATA_HOME/osu-wine"

            if [ -d "$GAMEDIR/OSU" ]; then
                OSUPATH="$GAMEDIR/OSU"
                echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
            else
                mkdir -p "$GAMEDIR/osu!"
                OSUPATH="$GAMEDIR/osu!"
                echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
            fi
            ;;

        '2')
            Info "Choose your directory: "
            GAMEDIR="$(zenity --file-selection --directory)"

            if [ -e "$GAMEDIR/osu!.exe" ]; then
                OSUPATH="$GAMEDIR"
                echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
            else
                mkdir -p "$GAMEDIR/osu!"
                OSUPATH="$GAMEDIR/osu!"
                echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
            fi
            ;;
        esac
    else
        Info "No option chosen, installing to default.. ($XDG_DATA_HOME/osu-wine)"

        mkdir -p "$XDG_DATA_HOME/osu-wine"
        GAMEDIR="$XDG_DATA_HOME/osu-wine"

        if [ -d "$GAMEDIR/OSU" ]; then
            OSUPATH="$GAMEDIR/OSU"
            echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
        else
            mkdir -p "$GAMEDIR/osu!"
            OSUPATH="$GAMEDIR/osu!"
            echo "$OSUPATH" >"$XDG_DATA_HOME/osuconfig/osupath"
        fi
    fi
}

# Here comes the real Winello 8)
# What the script will install, in order, is:
# - osu!mime and osu!handler to properly import skins and maps
# - Wineprefix
# - Regedit keys to integrate native file manager with Wine
# - rpc-bridge for Discord RPC (flatpak users, google "flatpak discord rpc")
FullInstall() {
    Info "Configuring osu-mime and osu-handler:"

    # Installing osu-mime from https://aur.archlinux.org/packages/osu-mime
    wget -O "/tmp/osu-mime.tar.gz" "${OSUMIMELINK}" && chk="$?"

    if [ ! "$chk" = 0 ]; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/osu-mime.tar.gz" "${OSUMIMELINK}" || InstallError "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
    fi

    tar -xf "/tmp/osu-mime.tar.gz" -C "/tmp"
    mkdir -p "$XDG_DATA_HOME/mime/packages"
    cp "/tmp/osu-mime/osu-file-extensions.xml" "$XDG_DATA_HOME/mime/packages/osuwinello-file-extensions.xml"
    update-mime-database "$XDG_DATA_HOME/mime"
    rm -f "/tmp/osu-mime.tar.gz"
    rm -rf "/tmp/osu-mime"

    # Installing osu-handler from https://github.com/openglfreak/osu-handler-wine / https://aur.archlinux.org/packages/osu-handler
    # Binary was compiled from source on Ubuntu 18.04
    cp "${SCRDIR}/stuff/osu-handler-wine" "$XDG_DATA_HOME/osuconfig/osu-handler-wine"

    chmod +x "$XDG_DATA_HOME/osuconfig/osu-handler-wine"

    # Creating entries for those two
    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=application/x-osu-skin-archive;application/x-osu-replay;application/x-osu-beatmap-archive;
Exec=$BINDIR/osu-wine --osuhandler %f
NoDisplay=true
StartupNotify=true
Icon=$XDG_DATA_HOME/icons/osu-wine.png" | tee "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop"
    chmod +x "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop" >/dev/null

    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=x-scheme-handler/osu;
Exec=$BINDIR/osu-wine --osuhandler %u
NoDisplay=true
StartupNotify=true
Icon=$XDG_DATA_HOME/icons/osu-wine.png" | tee "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop"
    chmod +x "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop" >/dev/null
    update-desktop-database "$XDG_DATA_HOME/applications"

    # Time to install my prepackaged Wineprefix, which works in most cases
    # The script is still bundled with osu-wine --fixprefix, which should do the job for me as well

    Info "Configuring Wineprefix:"

    # Variable to check if download finished properly
    failprefix="false"

    mkdir -p "$XDG_DATA_HOME/wineprefixes"
    if [ -d "$XDG_DATA_HOME/wineprefixes/osu-wineprefix" ]; then

        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (y/N)")" prefchoice

        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
            rm -rf "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
        fi
    fi

    # So if there's no prefix (or the user wants to reinstall):
    if [ ! -d "$XDG_DATA_HOME/wineprefixes/osu-wineprefix" ]; then

        # Downloading prefix in temporary ~/.winellotmp folder
        # to make up for this issue: https://github.com/NelloKudo/osu-winello/issues/36
        mkdir -p "$HOME/.winellotmp"
        wget -O "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" "${PREFIXLINK}" && chk="$?"

        # If download failed:
        if [ ! "$chk" = 0 ]; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" "${PREFIXLINK}" || failprefix="true"
        fi

        # Checking whether to create prefix manually or install it from repos
        if [ "$failprefix" = "true" ]; then
            WINE="$YAWL_PATH" winetricks -q dotnet20 dotnet48 gdiplus_winxp win2k3
        else
            tar -xf "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" -C "$XDG_DATA_HOME/wineprefixes"
            mv "$XDG_DATA_HOME/wineprefixes/osu-umu" "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
        fi

        # Cleaning..
        rm -rf "$HOME/.winellotmp"

        # Time to debloat the prefix a bit and make necessary symlinks (drag and drop, long name maps/paths..)
        rm -rf "$WINEPREFIX/dosdevices"
        rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
        mkdir -p "$WINEPREFIX/dosdevices"
        ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
        ln -s / "$WINEPREFIX/dosdevices/z:"
        ln -s "$OSUPATH" "$WINEPREFIX/dosdevices/d:"

        # Setup osu-handler for file integrations
        osuHandlerSetup

        # Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        # This only involves regedit keys.
        folderFixSetup

        # Installing dxvk-osu into Wineprefix
        InstallDxvk
    fi

    # Set up the discord rpc bridge
    discordRpc

    # Well...
    Info "Downloading osu!"
    if [ ! -s "$OSUPATH/osu!.exe" ]; then
        wget -O "$OSUPATH/osu!.exe" "${OSUDOWNLOADURL}" && chk="$?"

        if [ ! "$chk" = 0 ]; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$OSUPATH/osu!.exe" "${OSUDOWNLOADURL}" || InstallError "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
        fi
    fi

    local temp_winepath
    {
        temp_winepath="$("$YAWL_PATH" winepath -w "$OSUPATH/")" &&
            echo -n "$temp_winepath" >"$XDG_DATA_HOME/osuconfig/.osu-path-winepath" &&
            echo -n "$temp_winepath\osu!.exe" >"$XDG_DATA_HOME/osuconfig/.osu-exe-winepath"
    } ||
        InstallError "Couldn't get the osu! path from winepath... Check $OSUPATH/osu!.exe ?"

    Info "Installation is completed! Run 'osu-wine' to play osu!"
    Warning "If 'osu-wine' doesn't work, just close and relaunch your terminal."
    exit 0
}

#   =====================================
#   =====================================
#          POST-INSTALL FUNCTIONS
#   =====================================
#   =====================================

# Remember whether the user wants to overwrite their local files
askConfirmTimeout() {
    [ -z "${1:-}" ] && Info "Missing an argument for ${FUNCNAME[0]}!?" && exit 1

    local rememberfile="${XDG_DATA_HOME}/osuconfig/rememberupdatechoice"
    touch "${rememberfile}"

    local lastchoice
    lastchoice="$(grep "${1}" "${rememberfile}" | grep -Eo '(y|n)' | tail -n 1)"

    if [ -n "$lastchoice" ] && [ "$lastchoice" = "n" ]; then
        Info "Won't update ${1}, using saved choice from ${rememberfile}"
        Info "Remove this file if you've changed your mind."
        return 1
    elif [ -n "$lastchoice" ] && [ "$lastchoice" = "y" ]; then
        Info "Will update ${1}, using saved choice from ${rememberfile}"
        Info "Remove this file if you've changed your mind."
        return 0
    fi

    local _timeout=${2:-7} # use a 7 second timeout unless manually specified
    echo -n "$(Info "Choose: (Y/n) [${_timeout}s] ")"

    read -t "$_timeout" -r prefchoice

    if [[ "$prefchoice" =~ ^(n|N)(o|O)?$ ]]; then
        Info "Okay, won't update ${1}, saving this choice to ${rememberfile}."
        echo "${1} n" >>"${rememberfile}"
        return 1
    fi
    Info "Will update ${1}, saving this choice to ${rememberfile}."
    echo "${1} y" >>"${rememberfile}"
    echo ""
    return 0
}

# A helper for updating the osu-wine launcher itself
launcherUpdate() {
    local launcher="${1}"
    local update_source="$XDG_DATA_HOME/osuconfig/update/osu-wine"
    local backup_path="$XDG_DATA_HOME/osuconfig/osu-wine.bak"

    if [ ! -f "$update_source" ]; then
        Warning "Update source not found: $update_source"
        return 1
    fi

    if ! cp -f "$launcher" "$backup_path"; then
        Warning "Failed to create backup at $backup_path"
        return 1
    fi

    if ! cp -f "$update_source" "$launcher"; then
        Warning "Failed to apply update to $launcher"
        Warning "Attempting to restore from backup..."

        if ! cp -f "$backup_path" "$launcher"; then
            Warning "Failed to restore backup - system may be in inconsistent state"
            Warning "Manual restoration required from: $backup_path"
            return 1
        fi
        return 1
    fi

    if ! chmod --reference="$backup_path" "$launcher" 2>/dev/null; then
        chmod +x "$launcher" 2>/dev/null || {
            Warning "Failed to set executable permissions on $launcher"
            return 1
        }
    fi

    return 0
}

# will be removed when auto-updates are implemented in yawl
updateYawl() {
    local INSTALLED_YAWL_VERSION="0"
    INSTALLED_YAWL_VERSION="$(env "YAWL_VERBS=version" "$YAWL_PATH" 2>/dev/null)"
    if [ "$INSTALLED_YAWL_VERSION" != "$YAWLVERSION" ]; then
        Info "Updating yawl-winello:"
        wget -O "/tmp/yawl" "$YAWLLINK" && chk="$?"
        if [ ! "$chk" = 0 ]; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/yawl" "$YAWLLINK" || Error "Download failed, check your connection"
        fi
        mv "/tmp/yawl" "$XDG_DATA_HOME/osuconfig"
        chmod +x "$YAWL_INSTALL_PATH"

        # Also re-set-up yawl here, this will be required anyways when updating from umu-based osu-wine versions
        YAWL_VERBS="make_wrapper=winello;exec=$WINE_PATH/bin/wine;wineserver=$WINE_PATH/bin/wineserver" "$YAWL_INSTALL_PATH"
        YAWL_VERBS="verify" "$YAWL_PATH" "--version" || Error "There was an error setting up yawl!"
    fi
}

# This function reads files located in $XDG_DATA_HOME/osuconfig
# to see whether a new wine-osu version has been released.
Update() {
    local launcher_path="${1:-}"
    [ ! -r "$YAWL_PATH" ] && rm -f "${XDG_DATA_HOME}/osuconfig/rememberupdatechoice"

    updateYawl

    # Reading the last version installed
    [ -r "$XDG_DATA_HOME/osuconfig/wineverupdate" ] && LASTWINEVERSION=$(</"$XDG_DATA_HOME/osuconfig/wineverupdate")

    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
        # Downloading Wine..
        wget -O "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" "$WINELINK" && chk="$?"
        if [ ! "$chk" = 0 ]; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" "$WINELINK" || Error "Download failed, check your connection"
        fi

        # This will extract Wine-osu and set last version to the one downloaded
        Info "Updating Wine-osu"...
        rm -rf "$XDG_DATA_HOME/osuconfig/wine-osu"
        tar -xf "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
        rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

        LASTWINEVERSION="$WINEVERSION"
        rm -f "$XDG_DATA_HOME/osuconfig/wineverupdate"
        echo "$LASTWINEVERSION" >>"$XDG_DATA_HOME/osuconfig/wineverupdate"
        Info "Update is completed!"
    else
        Info "Your Wine-osu is already up-to-date!"
    fi

    [ ! -x "${launcher_path}" ] && return

    if [ ! -w "${launcher_path}" ]; then
        Warning "Note: ${launcher_path} is not writable - updating the osu-wine launcher will not be possible"
        Warning "Try running the update with appropriate permissions if you want to update the launcher,"
        Warning "   or move it to a place like $BINDIR and then run it from there."
        return
    fi

    Info "Do you want to update the 'osu-wine' launcher as well?"
    Info "This is recommended, as there may be important fixes and updates."
    Warning "This will remove any customizations you might have made to ${launcher_path},"
    Warning "   but a backup will be left in $XDG_DATA_HOME/osuconfig/osu-wine.bak ."

    # use a really long timeout so the user can read everything and decide
    askConfirmTimeout "the 'osu-wine' launcher" 60 && selfupdate=y
    if [ -n "${selfupdate}" ]; then
        if launcherUpdate "${launcher_path}"; then
            Info "Launcher update successful!"
            Info "Backup saved to: $XDG_DATA_HOME/osuconfig/osu-wine.bak"
        else
            Error "Launcher update failed"
        fi
    else
        Info "Your osu-wine launcher will be left alone."
    fi
}

# Well, simple function to install the game (also implement in osu-wine --remove)
Uninstall() {
    Info "Uninstalling icons:"
    rm -f "$XDG_DATA_HOME/icons/osu-wine.png"

    Info "Uninstalling .desktop:"
    rm -f "$XDG_DATA_HOME/applications/osu-wine.desktop"

    Info "Uninstalling game script, utilities & folderfix:"
    rm -f "$BINDIR/osu-wine"
    rm -f "$BINDIR/folderfixosu"
    rm -f "$BINDIR/folderfixosu.vbs"
    rm -f "$XDG_DATA_HOME/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop"

    Info "Uninstalling wine-osu:"
    rm -rf "$XDG_DATA_HOME/osuconfig/wine-osu"

    Info "Uninstalling yawl and the steam runtime:"
    rm -rf "$XDG_DATA_HOME/yawl"

    read -r -p "$(Info "Do you want to uninstall Wineprefix? (y/N)")" wineprch

    if [ "$wineprch" = 'y' ] || [ "$wineprch" = 'Y' ]; then
        rm -rf "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
    else
        Info "Skipping.."
    fi

    read -r -p "$(Info "Do you want to uninstall game files? (y/N)")" choice

    if [ "$choice" = 'y' ] || [ "$choice" = 'Y' ]; then
        read -r -p "$(Info "Are you sure? This will delete your files! (y/N)")" choice2

        if [ "$choice2" = 'y' ] || [ "$choice2" = 'Y' ]; then
            Info "Uninstalling game:"
            if [ -e "$XDG_DATA_HOME/osuconfig/osupath" ]; then
                OSUUNINSTALLPATH=$(<"$XDG_DATA_HOME/osuconfig/osupath")
                rm -rf "$OSUUNINSTALLPATH"
                rm -rf "$XDG_DATA_HOME/osuconfig"
            else
                rm -rf "$XDG_DATA_HOME/osuconfig"
            fi
        else
            rm -rf "$XDG_DATA_HOME/osuconfig"
            Info "Exiting.."
        fi
    else
        rm -rf "$XDG_DATA_HOME/osuconfig"
    fi

    Info "Uninstallation completed!"
}

# Simple function that downloads Gosumemory!
Gosumemory() {
    if [ ! -d "$XDG_DATA_HOME/osuconfig/gosumemory" ]; then
        Info "Installing gosumemory.."
        mkdir -p "$XDG_DATA_HOME/osuconfig/gosumemory"
        wget -O "/tmp/gosumemory.zip" "${GOSUMEMORYLINK}" || Error "Download failed, check your connection.."
        unzip -d "$XDG_DATA_HOME/osuconfig/gosumemory" -q "/tmp/gosumemory.zip"
        rm "/tmp/gosumemory.zip"
    fi
}

tosu() {
    if [ ! -d "$XDG_DATA_HOME/osuconfig/tosu" ]; then
        Info "Installing tosu.."
        mkdir -p "$XDG_DATA_HOME/osuconfig/tosu"
        wget -O "/tmp/tosu.zip" "${TOSULINK}" || Error "Download failed, check your connection.."
        unzip -d "$XDG_DATA_HOME/osuconfig/tosu" -q "/tmp/tosu.zip"
        rm "/tmp/tosu.zip"
    fi
}

# Installs rpc-bridge for Discord RPC (https://github.com/EnderIce2/rpc-bridge)
discordRpc() {
    Info "Configuring rpc-bridge (Discord RPC)"
    if [ -f "${WINEPREFIX}/drive_c/windows/bridge.exe" ]; then
        Info "rpc-bridge (Discord RPC) is already installed, do you want to reinstall it?"
        askConfirmTimeout "rpc-bridge (Discord RPC)" || return 1
    fi

    # try uninstalling the service first
    "$YAWL_PATH" reg delete 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rpc-bridge' /f &>/dev/null
    local chk

    wget -O "/tmp/bridge.zip" "${DISCRPCLINK}" && chk="$?"

    if [ ! "$chk" = 0 ]; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/bridge.zip" "${DISCRPCLINK}" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
    fi

    mkdir -p /tmp/rpc-bridge
    unzip -d /tmp/rpc-bridge -q "/tmp/bridge.zip"
    "$YAWL_PATH" /tmp/rpc-bridge/bridge.exe --install
    rm -f "/tmp/bridge.zip"
    rm -rf "/tmp/rpc-bridge"
}

folderFixSetup() {
    # Applying fix for opening folders in the native file browser...
    local VBS_PATH="$XDG_DATA_HOME/osuconfig/folderfixosu.vbs"
    local FALLBACK_PATH="$XDG_DATA_HOME/osuconfig/folderfixosu"
    cp "${SCRDIR}/stuff/folderfixosu.vbs" "${VBS_PATH}"
    cp "${SCRDIR}/stuff/folderfixosu" "${FALLBACK_PATH}"

    local VBS_WINPATH
    local chk
    VBS_WINPATH="$(WINEDEBUG=-all "$YAWL_PATH" winepath.exe -w "${VBS_PATH}" 2>/dev/null)" || chk=1

    "$YAWL_PATH" reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f
    "$YAWL_PATH" reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
    if [ -z "${chk:-}" ]; then
        "$YAWL_PATH" reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "wscript.exe \"${VBS_WINPATH//\\/\\\\}\" \"%1\""
    else
        "$YAWL_PATH" reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "${FALLBACK_PATH} xdg-open \"%1\""
    fi
}

osuHandlerSetup() {
    # Fix to importing maps/skins/osu links after Stable update 20250122.1: https://osu.ppy.sh/home/changelog/stable40/20250122.1
    local REG_FILE="$XDG_DATA_HOME/osuconfig/osu-handler.reg"
    cp "${SCRDIR}/stuff/osu-handler.reg" "${REG_FILE}"

    # Adding the osu-handler.reg file to registry
    "$YAWL_PATH" regedit /s "${REG_FILE}"
}

InstallDxvk() {
    # Installing patched dxvk-osu binaries, read more in stuff/dxvk-osu.
    # Copying dlls from stuff/dxvk-osu into Wineprefix
    Info "Installing dxvk-osu in Wineprefix.."
    cp "${SCRDIR}"/stuff/dxvk-osu/x64/*.dll "$WINEPREFIX/drive_c/windows/system32"
    cp "${SCRDIR}"/stuff/dxvk-osu/x32/*.dll "$WINEPREFIX/drive_c/windows/syswow64"

    # Setting DllOverrides for those to Native
    for dll in dxgi d3d8 d3d9 d3d10core d3d11; do
        "$YAWL_PATH" reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "$dll" /d native /f
    done
}

FixUmu() {
    if [ ! -f "$BINDIR/osu-wine" ]; then
        Info "Looks like you haven't installed osu-winello yet, so you should run ./osu-winello.sh first."
        return
    fi
    Info "Looks like you're updating from the umu-launcher based osu-wine, so we'll try to run a full update now..."
    Info "Please answer 'yes' when asked to update the 'osu-wine' launcher"

    local parentscript
    parentscript="$(realpath /proc/$PPID/exe)" || parentscript="$(readlink /proc/$PPID/exe)"
    [[ ! "${parentscript}" =~ .*osu-wine ]] && Error "Please re-download and re-install osu-winello."

    Update "${parentscript}"
    Info "Done!"
}

FixYawl() {
    if [ ! -f "$BINDIR/osu-wine" ]; then
        Info "Looks like you haven't installed osu-winello yet, so you should run ./osu-winello.sh first."
        return
    elif [ ! -f "$YAWL_PATH" ]; then
        Info "yawl not found, you should run ./osu-winello.sh first."
        return
    fi

    Info "Fixing yawl..."
    YAWL_VERBS="reinstall" "$YAWL_PATH" true && chk="$?"
    if [ "${chk}" != 0 ]; then
        Info "That didn't seem to work... try again?"
    else
        Info "yawl should be good to go now."
    fi
}

# Help!
Help() {
    Info "To install the game, run ./osu-winello.sh
          To uninstall the game, run ./osu-winello.sh uninstall
          To retry installing yawl-related files, run ./osu-winello.sh fixyawl
          You can read more at README.md or https://github.com/NelloKudo/osu-winello"
}

#   =====================================
#   =====================================
#            MAIN SCRIPT
#   =====================================
#   =====================================

case "$1" in
'')
    InitialSetup
    InstallWine
    ConfigurePath
    FullInstall
    ;;

'uninstall')
    Uninstall
    ;;

'gosumemory')
    Gosumemory
    ;;

'tosu')
    tosu
    ;;

'discordrpc')
    discordRpc
    ;;

'fixfolders')
    folderFixSetup
    ;;

'osuhandler')
    osuHandlerSetup
    ;;

'installdxvk')
    InstallDxvk
    ;;

'update')
    Update "${2:-}" # second argument is the path to the osu-wine launcher, expected to be called by `osu-wine --update`
    ;;

# "umu" kept for backwards compatibility when updating from umu-launcher based osu-wine
*umu*)
    FixUmu
    ;;

*yawl*)
    FixYawl
    ;;

*help* | '-h')
    Help
    ;;

*)
    Info "Unknown argument, see ./osu-winello.sh help or ./osu-winello.sh -h"
    ;;
esac

# Congrats for reading it all! Have fun playing osu!
# (and if you wanna improve the script, PRs are always open :3)

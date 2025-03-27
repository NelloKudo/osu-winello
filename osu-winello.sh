#!/usr/bin/env bash

#   =======================================
#   Welcome to Winello!
#   The whole script is divided in different
#   functions to make it easier to read.
#   Feel free to contribute!
#   =======================================

# Wine-osu current versions for update
MAJOR=10
MINOR=4
PATCH=1
WINEVERSION=$MAJOR.$MINOR-$PATCH
LASTWINEVERSION=0

# Wine-osu mirror
WINELINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-staging-${WINEVERSION}/wine-osu-winello-fonts-wow64-${WINEVERSION}-x86_64.tar.xz"

# Other versions for external downloads
DISCRPCBRIDGEVERSION=1.2
GOSUMEMORYVERSION=1.3.9
TOSUVERSION=4.3.1
YAWLVERSION=0.6.2

# Other download links
WINETRICKSLINK="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"                 # Winetricks for --fixprefix
PREFIXLINK="https://github.com/NelloKudo/osu-winello/releases/download/winello-bins/osu-winello-prefix.tar.xz" # Default WINEPREFIX
OSUMIMELINK="https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz"                                  # osu-mime (file associations)
YAWLLINK="https://github.com/whrvt/yawl/releases/download/v${YAWLVERSION}/yawl"                                # yawl (Wine launcher for Steam Runtime)

OSUDOWNLOADURL="https://m1.ppy.sh/r/osu!install.exe"

DISCRPCLINK="https://github.com/EnderIce2/rpc-bridge/releases/download/v${DISCRPCBRIDGEVERSION}/bridge.zip"
GOSUMEMORYLINK="https://github.com/l3lackShark/gosumemory/releases/download/${GOSUMEMORYVERSION}/gosumemory_windows_amd64.zip"
TOSULINK="https://github.com/tosuapp/tosu/releases/download/v${TOSUVERSION}/tosu-windows-v${TOSUVERSION}.zip"

# The URL for our git repo
WINELLOGIT="https://github.com/NelloKudo/osu-winello.git"

# The directory osu-winello.sh is in
SCRDIR="$(realpath "$(dirname "$0")")"
# The full path to osu-winello.sh
SCRPATH="$(realpath "$0")"

# Exported global variables

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export BINDIR="${BINDIR:-$HOME/.local/bin}"

OSUPATH="${OSUPATH:-}" # Could either be exported from the osu-wine launcher, from the osuconfig/osupath, or empty at first install (will set up in installOrChangeDir)
[ -r "$XDG_DATA_HOME/osuconfig/osupath" ] && OSUPATH=$(</"$XDG_DATA_HOME/osuconfig/osupath") &&
    PRESSURE_VESSEL_FILESYSTEMS_RW="$(realpath "$OSUPATH"):$(realpath "$OSUPATH"/Songs):/mnt:/media:/run/media" && export PRESSURE_VESSEL_FILESYSTEMS_RW

# Don't rely on this! We should get the launcher path from `osu-wine --update`, this is a "hack" to support updating from umu
if [ -z "${LAUNCHERPATH}" ]; then
    LAUNCHERPATH="$(realpath /proc/$PPID/exe)" || LAUNCHERPATH="$(readlink /proc/$PPID/exe)"
    [[ ! "${LAUNCHERPATH}" =~ .*osu.* ]] && LAUNCHERPATH=
fi
[ -z "${LAUNCHERPATH}" ] && LAUNCHERPATH="$BINDIR/osu-wine" # If we STILL couldn't find it, just use the default directory

export WINEDLLOVERRIDES="winemenubuilder.exe=;" # Blocks wine from creating .desktop files
export WINEDEBUG="-wineboot,${WINEDEBUG:-}"     # Don't show "failed to start winemenubuilder"

export WINENTSYNC="${WINENTSYNC:-0}" # Don't use these for setup-related stuff to be safe
export WINEFSYNC="${WINEFSYNC:-0}"   # (still, don't override launcher settings, because if wineserver is running with different settings, it will fail to start)
export WINEESYNC="${WINEESYNC:-0}"

# Other shell local variables
WINETRICKS="${WINETRICKS:-"$XDG_DATA_HOME/osuconfig/winetricks"}"
YAWL_INSTALL_PATH="${YAWL_INSTALL_PATH:-"$XDG_DATA_HOME/osuconfig/yawl"}"
export WINE="${WINE:-"${YAWL_INSTALL_PATH}-winello"}"
export WINESERVER="${WINESERVER:-"${WINE}server"}"
export WINEPREFIX="${WINEPREFIX:-"$XDG_DATA_HOME/wineprefixes/osu-wineprefix"}"
export WINE_INSTALL_PATH="${WINE_INSTALL_PATH:-"$XDG_DATA_HOME/osuconfig/wine-osu"}"

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
    exit 1
}

# Error function pointing at Revert(), but with an appropriate message
InstallError() {
    echo -e '\033[1;31m'"Script failed:\033[0m $*"
    Revert
}

# Error function for other features besides install
Error() {
    echo -e '\033[1;31m'"Script failed:\033[0m $*"
    return 0 # don't exit, handle errors ourselves, propagate result to launcher if needed
}

# Shorthand for a lot of functions succeeding
okay="eval Info Done! && return 0"

wgetcommand="wget -q --show-progress"
_wget() {
    local url="$1"
    local output="$2"
    $wgetcommand "$url" -O "$output" && return 0
    { [ $? = 2 ] && wgetcommand="wget"; } || wgetcommand="wget --no-check-certificate"
    $wgetcommand "$url" -O "$output" && return 0
    return 1
}

DownloadFile() {
    local url="$1"
    local output="$2"
    Info "Downloading $1 to $2..."
    {
        if command -v wget >/dev/null 2>&1; then
            _wget "$url" "$output"
        elif command -v curl >/dev/null 2>&1; then
            curl -sSL "$url" -o "$output"
        fi
    } || { Error "Failed to download $url. Check your connection." && return 1; }
    return 0
}

# Function looking for basic stuff needed for installation
InitialSetup() {
    # Better to not run the script as root, right?
    if [ "$USER" = "root" ]; then InstallError "Please run the script without root"; fi

    # Checking for previous versions of osu-wine (mine or DiamondBurned's)
    if [ -e /usr/bin/osu-wine ]; then Quit "Please uninstall old osu-wine (/usr/bin/osu-wine) before installing!"; fi
    if [ -e "$BINDIR/osu-wine" ]; then Quit "Please uninstall Winello (osu-wine --remove) before installing!"; fi

    Info "Welcome to the script! Follow it to install osu! 8)"

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
            fish -c fish_add_path "$BINDIR/"
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

# Helper to wait for wineserver to close before continuing to a next step, reduces the chance of flakiness
# Don't return failure, it's probably harmless, unrelated, or unreliable to use as a success indicator (besides specific cases)
waitWine() {
    {
        "$WINESERVER" -w
        "$WINE" "${@:-"--version"}"
    }
    return 0
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
    DownloadFile "$WINELINK" "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" || InstallError "Couldn't download wine-osu."

    # This will extract Wine-osu and set last version to the one downloaded
    tar -xf "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
    LASTWINEVERSION="$WINEVERSION"
    rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

    # Install and verify yawl ASAP, the wrapper mode does not download/install the runtime if no arguments are passed
    installYawl || Revert

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
InitialOsuInstall() {
    local installpath=1
    Info "Where do you want to install the game?: 
          1 - Default path ($XDG_DATA_HOME/osu-wine)
          2 - Custom path"
    read -r -p "$(Info "Choose your option: ")" installpath

    case "$installpath" in
    '2')
        installOrChangeDir || return 1
        ;;
    *)
        Info "Installing to default.. ($XDG_DATA_HOME/osu-wine)"
        installOrChangeDir "$XDG_DATA_HOME/osu-wine" || return 1
        ;;
    esac
    $okay
}

# Here comes the real Winello 8)
# What the script will install, in order, is:
# - osu!mime and osu!handler to properly import skins and maps
# - Wineprefix
# - Regedit keys to integrate native file manager with Wine
# - rpc-bridge for Discord RPC (flatpak users, google "flatpak discord rpc")
FullInstall() {
    # Time to install my prepackaged Wineprefix, which works in most cases
    # The script is still bundled with osu-wine --fixprefix, which should do the job for me as well

    mkdir -p "$XDG_DATA_HOME/osuconfig/configs" # make the configs directory and copy the example if it doesnt exist
    [ ! -r "$XDG_DATA_HOME/osuconfig/configs/example.cfg" ] && cp "${SCRDIR}/stuff/example.cfg" "$XDG_DATA_HOME/osuconfig/configs/example.cfg"

    Info "Configuring Wineprefix:"

    # Variable to check if download finished properly
    local failprefix="false"
    mkdir -p "$XDG_DATA_HOME/wineprefixes"
    if [ -r "$XDG_DATA_HOME/wineprefixes/osu-wineprefix/system.reg" ]; then
        Info "Wineprefix already exists; do you want to reinstall it?"
        Warning "HIGHLY RECOMMENDED UNLESS YOU KNOW WHAT YOU'RE DOING!"
        read -r -p "$(Info "Choose (y/N): ")" prefchoice
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
            rm -rf "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
        fi
    fi

    # So if there's no prefix (or the user wants to reinstall):
    if [ ! -r "$XDG_DATA_HOME/wineprefixes/osu-wineprefix/system.reg" ]; then
        # Downloading prefix in temporary ~/.winellotmp folder
        # to make up for this issue: https://github.com/NelloKudo/osu-winello/issues/36
        mkdir -p "$HOME/.winellotmp"
        DownloadFile "${PREFIXLINK}" "$HOME/.winellotmp/osu-winello-prefix.tar.xz" || Revert

        # Checking whether to create prefix manually or install it from repos
        if [ "$failprefix" = "true" ]; then
            reconfigurePrefix nowinepath fresh || Revert
        else
            tar -xf "$HOME/.winellotmp/osu-winello-prefix.tar.xz" -C "$XDG_DATA_HOME/wineprefixes"
            mv "$XDG_DATA_HOME/wineprefixes/osu-prefix" "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
            reconfigurePrefix nowinepath || Revert
        fi
        # Cleaning..
        rm -rf "$HOME/.winellotmp"
    fi

    # Now set up desktop files and such, no matter whether its a new or old prefix
    osuHandlerSetup || Revert

    Info "Configure and install osu!"
    InitialOsuInstall || Revert

    Info "Installation is completed! Run 'osu-wine' to play osu!"
    Warning "If 'osu-wine' doesn't work, just close and relaunch your terminal."
    exit 0
}

#   =====================================
#   =====================================
#          POST-INSTALL FUNCTIONS
#   =====================================
#   =====================================

longPathsFix() {
    Info "Applying fix for long song names (e.g. because of deeply nested osu! folder)..."

    rm -rf "$WINEPREFIX/dosdevices"
    rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
    mkdir -p "$WINEPREFIX/dosdevices"
    ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
    ln -s / "$WINEPREFIX/dosdevices/z:"
    ln -s "$OSUPATH" "$WINEPREFIX/dosdevices/d:" 2>/dev/null # it's fine if this fails on a fresh install
    waitWine wineboot -u
    return 0
}

saveOsuWinepath() {
    local osupath="${OSUPATH}"
    if [ -z "${osupath}" ]; then
        { [ -r "$XDG_DATA_HOME/osuconfig/osupath" ] && osupath=$(<"$XDG_DATA_HOME/osuconfig/osupath"); } || {
            Error "Can't find the osu! path!" && return 1
        }
    fi

    Info "Saving a copy of the osu! path..."

    local temp_winepath
    temp_winepath="$(PRESSURE_VESSEL_FILESYSTEMS_RW="$(realpath "$osupath"):$(realpath "$osupath"/Songs):/mnt:/media:/run/media" waitWine winepath -w "$osupath")"
    [ -z "${temp_winepath}" ] && Error "Couldn't get the osu! path from winepath... Check $osupath/osu!.exe ?" && return 1

    echo -n "$temp_winepath" >"$XDG_DATA_HOME/osuconfig/.osu-path-winepath"
    echo -n "$temp_winepath\osu!.exe" >"$XDG_DATA_HOME/osuconfig/.osu-exe-winepath"
    $okay
}

deleteFolder() {
    local folder="${1}"
    Info "Do you want to remove the previous install at ${folder}?"
    read -r -p "$(Info "Choose your option (y/N): ")" dirchoice

    if [ "$dirchoice" = 'y' ] || [ "$dirchoice" = 'Y' ]; then
        read -r -p "$(Info "Are you sure? This will delete your osu! files! (y/N)")" dirchoice2
        if [ "$dirchoice2" = 'y' ] || [ "$dirchoice2" = 'Y' ]; then
            rm -rf "${folder}" || { Error "Couldn't remove folder!" && return 1; }
            return 0
        fi
    fi
    Info "Skipping.."
    return 0
}

# Handle `osu-wine --changedir` and installation setup
installOrChangeDir() {
    local newdir="${1:-}"
    local lastdir="${OSUPATH:-}"
    if [ -z "${newdir}" ]; then
        Info "Please choose your osu! directory:"
        newdir="$(zenity --file-selection --directory)"
        [ ! -d "$newdir" ] && { Error "No folder selected, please make sure zenity is installed.." && return 1; }
    fi

    [ ! -s "$newdir/osu!.exe" ] && newdir="$newdir/osu!" # Make it a subdirectory unless osu!.exe is already there
    if [ -s "$newdir/osu!.exe" ] || [ "$newdir" = "$lastdir" ]; then
        Info "The osu! installation already exists..."
    else
        mkdir -p "$newdir"
        DownloadFile "${OSUDOWNLOADURL}" "$newdir/osu!.exe" || return 1

        [ -n "${lastdir}" ] && { deleteFolder "$lastdir" || return 1; }
    fi

    echo "${newdir}" >"$XDG_DATA_HOME/osuconfig/osupath" # Save it for later
    export OSUPATH="${newdir}"

    longPathsFix || return 1
    saveOsuWinepath || return 1
    Info "osu! installed to '$newdir'!"
    return 0
}

reconfigurePrefix() {
    local freshprefix=''
    local nowinepath=''
    while [[ $# -gt 0 ]]; do
        case "${1}" in
        'nowinepath')
            nowinepath=1
            ;;
        'fresh')
            freshprefix=1
            ;;
        *) ;;
        esac
        shift
    done

    installWinetricks

    [ -n "${freshprefix}" ] && {
        Info "Checking for internet connection.." # The bundled prefix install already checks for internet, so no point checking again
        ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && { Error "Please connect to internet before continuing xd. Run the script again" && return 1; }

        [ -d "${WINEPREFIX:?}" ] && rm -rf "${WINEPREFIX}"

        Info "Downloading and installing a new prefix with winetricks. This might take a while, so go make a coffee or something."
        "$WINESERVER" -k
        PATH="${SCRDIR}/stuff:${PATH}" WINEDEBUG="fixme-winediag,${WINEDEBUG:-}" WINENTSYNC=0 WINEESYNC=0 WINEFSYNC=0 \
            "$WINETRICKS" -q nocrashdialog autostart_winedbg=disabled dotnet48 dotnet20 gdiplus_winxp meiryo win10 ||
            { Error "winetricks failed catastrophically!" && return 1; }

        InstallDxvk || return 1
    }

    longPathsFix || return 1
    folderFixSetup || return 1
    discordRpc || return 1

    # save the osu winepath with the new folder, unless its a first-time install (need to install osu first)
    [ -z "${nowinepath}" ] && { saveOsuWinepath || return 1; }

    $okay
}

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
    $okay
}

installYawl() {
    Info "Installing yawl..."
    DownloadFile "$YAWLLINK" "/tmp/yawl" || return 1
    mv "/tmp/yawl" "$XDG_DATA_HOME/osuconfig"
    chmod +x "$YAWL_INSTALL_PATH"

    # Also setup yawl here, this will be required anyways when updating from umu-based osu-wine versions
    YAWL_VERBS="make_wrapper=winello;exec=$WINE_INSTALL_PATH/bin/wine;wineserver=$WINE_INSTALL_PATH/bin/wineserver" "$YAWL_INSTALL_PATH"
    YAWL_VERBS="update;verify;exec=/bin/true" "$YAWL_INSTALL_PATH" || { Error "There was an error setting up yawl!" && return 1; }
    $okay
}

# This function reads files located in $XDG_DATA_HOME/osuconfig
# to see whether a new wine-osu version has been released.
Update() {
    local launcher_path="${1:-"${LAUNCHERPATH}"}"
    if [ ! -x "$WINE" ]; then
        rm -f "${XDG_DATA_HOME}/osuconfig/rememberupdatechoice"
        installYawl || Info "Continuing, but things might be broken..."
    else
        local INSTALLED_YAWL_VERSION
        INSTALLED_YAWL_VERSION="$(env "YAWL_VERBS=version" "$WINE" 2>/dev/null)"
        if [[ "$INSTALLED_YAWL_VERSION" =~ 0\.5\.* ]]; then
            installYawl || Info "Continuing, but things might be broken..."
        else
            Info "Checking for yawl updates..."
            YAWL_VERBS="update" "$WINE" "--version"
        fi
    fi

    # Reading the last version installed
    [ -r "$XDG_DATA_HOME/osuconfig/wineverupdate" ] && LASTWINEVERSION=$(</"$XDG_DATA_HOME/osuconfig/wineverupdate")

    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
        # Downloading Wine..
        DownloadFile "$WINELINK" "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" || return 1

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

    mkdir -p "$XDG_DATA_HOME/osuconfig/configs" # make the configs directory and copy the example if it doesnt exist
    [ ! -r "$XDG_DATA_HOME/osuconfig/configs/example.cfg" ] && cp "${SCRDIR}/stuff/example.cfg" "$XDG_DATA_HOME/osuconfig/configs/example.cfg"

    # Will be required when updating from umu-launcher
    [ ! -r "$XDG_DATA_HOME/osuconfig/.osu-path-winepath" ] && { saveOsuWinepath || return 1; }

    [ -n "$NOLAUNCHERUPDATE" ] && Info "Your osu-wine launcher will be left alone." && $okay

    [ ! -x "${launcher_path}" ] && { Error "Can't find the path to the osu-wine launcher to update it. Please reinstall osu-winello." && return 1; }

    if [ ! -w "${launcher_path}" ]; then
        Warning "Note: ${launcher_path} is not writable - updating the osu-wine launcher will not be possible"
        Warning "Try running the update with appropriate permissions if you want to update the launcher,"
        Warning "   or move it to a place like $BINDIR and then run it from there."
        return 0
    fi

    Info "Updating the launcher (${launcher_path})..."
    if launcherUpdate "${launcher_path}"; then
        Info "Launcher update successful!"
        Info "Backup saved to: $XDG_DATA_HOME/osuconfig/osu-wine.bak"
    else
        Error "Launcher update failed" && return 1
    fi
    $okay
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
    return 0
}

SetupReader() {
    local READER_NAME="${1}"
    Info "Setting up $READER_NAME wrapper..."
    # get all the required paths first
    local READER_PATH
    local OSU_WINEDIR
    local OSU_WINEEXE
    READER_PATH="$(WINEDEBUG=-all "$WINE" winepath -w "$XDG_DATA_HOME/osuconfig/$READER_NAME/$READER_NAME.exe" 2>/dev/null)" || { Error "Didn't find $READER_NAME in the expected location..." && return 1; }
    { [ -r "$XDG_DATA_HOME/osuconfig/.osu-path-winepath" ] && read -r OSU_WINEDIR <<<"$(cat "$XDG_DATA_HOME/osuconfig/.osu-path-winepath")" &&
        [ -r "$XDG_DATA_HOME/osuconfig/.osu-exe-winepath" ] && read -r OSU_WINEEXE <<<"$(cat "$XDG_DATA_HOME/osuconfig/.osu-exe-winepath")"; } ||
        { Error "You need to fully install osu-winello before trying to set up $READER_NAME.\n\t(Missing $XDG_DATA_HOME/osuconfig/.osu-path-winepath or .osu-exe-winepath .)" && return 1; }

    # launcher batch file to open tosu/gosumemory together with osu in the container, and tries to stop hung gosumemory/tosu process when osu! exits (why does that happen!?)
    cat >"$OSUPATH/launch_with_memory.bat" <<EOF
@echo off
set NODE_SKIP_PLATFORM_CHECK=1
cd /d "$OSU_WINEDIR"
start "" "$OSU_WINEEXE" %*
start /b "" "$READER_PATH"

:loop
tasklist | find "osu!.exe" >nul
if ERRORLEVEL 1 (
    taskkill /F /IM $READER_NAME.exe
    taskkill /F /IM ${READER_NAME}_overlay.exe
    wineboot -e -f
    exit
)
ping -n 5 127.0.0.1 >nul
goto loop
EOF

    Info "$READER_NAME wrapper enabled. Launch osu! normally to use it!"
    return 0
}

# Simple function that downloads Gosumemory!
Gosumemory() {
    if [ ! -d "$XDG_DATA_HOME/osuconfig/gosumemory" ]; then
        Info "Downloading gosumemory.."
        mkdir -p "$XDG_DATA_HOME/osuconfig/gosumemory"
        DownloadFile "${GOSUMEMORYLINK}" "/tmp/gosumemory.zip" || return 1
        unzip -d "$XDG_DATA_HOME/osuconfig/gosumemory" -q "/tmp/gosumemory.zip"
        rm "/tmp/gosumemory.zip"
    fi
    SetupReader "gosumemory" || return 1
    $okay
}

tosu() {
    if [ ! -d "$XDG_DATA_HOME/osuconfig/tosu" ]; then
        Info "Downloading tosu.."
        mkdir -p "$XDG_DATA_HOME/osuconfig/tosu"
        DownloadFile "${TOSULINK}" "/tmp/tosu.zip" || return 1
        unzip -d "$XDG_DATA_HOME/osuconfig/tosu" -q "/tmp/tosu.zip"
        rm "/tmp/tosu.zip"
    fi
    SetupReader "tosu" || return 1
    $okay
}

# Installs rpc-bridge for Discord RPC (https://github.com/EnderIce2/rpc-bridge)
discordRpc() {
    Info "Setting up Discord RPC integration..."
    if [ -f "${WINEPREFIX}/drive_c/windows/bridge.exe" ]; then
        Info "rpc-bridge (Discord RPC) is already installed, do you want to reinstall it?"
        askConfirmTimeout "rpc-bridge (Discord RPC)" || return 0
    fi

    # try uninstalling the service first
    waitWine reg delete 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\rpc-bridge' /f &>/dev/null
    local chk

    DownloadFile "${DISCRPCLINK}" "/tmp/bridge.zip" || return 1

    mkdir -p /tmp/rpc-bridge
    unzip -d /tmp/rpc-bridge -q "/tmp/bridge.zip"
    waitWine /tmp/rpc-bridge/bridge.exe --install
    rm -f "/tmp/bridge.zip"
    rm -rf "/tmp/rpc-bridge"
    $okay
}

folderFixSetup() {
    # Integrating native file explorer (inspired by) Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
    # This only involves regedit keys.
    Info "Setting up native file explorer integration..."

    local VBS_PATH="$XDG_DATA_HOME/osuconfig/folderfixosu.vbs"
    local FALLBACK_PATH="$XDG_DATA_HOME/osuconfig/folderfixosu"
    cp "${SCRDIR}/stuff/folderfixosu.vbs" "${VBS_PATH}"
    cp "${SCRDIR}/stuff/folderfixosu" "${FALLBACK_PATH}"

    local VBS_WINPATH
    local fallback
    VBS_WINPATH="$(WINEDEBUG=-all waitWine winepath.exe -w "${VBS_PATH}" 2>/dev/null)" || fallback="1"
    [ -z "$VBS_WINPATH" ] && fallback="1"

    waitWine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f
    waitWine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
    if [ -z "${fallback:-}" ]; then
        waitWine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "wscript.exe \"${VBS_WINPATH//\\/\\\\}\" \"%1\""
    else
        waitWine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "${FALLBACK_PATH} xdg-open \"%1\""
    fi
    $okay
}

osuHandlerSetup() {
    Info "Configuring osu-mime and osu-handler..."

    # Installing osu-mime from https://aur.archlinux.org/packages/osu-mime
    DownloadFile "${OSUMIMELINK}" "/tmp/osu-mime.tar.gz" || return 1

    tar -xf "/tmp/osu-mime.tar.gz" -C "/tmp"
    mkdir -p "$XDG_DATA_HOME/mime/packages"
    cp "/tmp/osu-mime/osu-file-extensions.xml" "$XDG_DATA_HOME/mime/packages/osuwinello-file-extensions.xml"
    update-mime-database "$XDG_DATA_HOME/mime"
    rm -f "/tmp/osu-mime.tar.gz"
    rm -rf "/tmp/osu-mime"

    # Installing osu-handler from https://github.com/openglfreak/osu-handler-wine / https://aur.archlinux.org/packages/osu-handler
    # Binary was compiled from source on Ubuntu 18.04
    chmod +x "$XDG_DATA_HOME/osuconfig/update/stuff/osu-handler-wine"

    # Creating entries for those two
    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=application/x-osu-skin-archive;application/x-osu-replay;application/x-osu-beatmap-archive;
Exec=$BINDIR/osu-wine --osuhandler %f
NoDisplay=true
StartupNotify=true
Icon=$XDG_DATA_HOME/icons/osu-wine.png" | tee "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop" >/dev/null
    chmod +x "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop" >/dev/null

    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=x-scheme-handler/osu;
Exec=$BINDIR/osu-wine --osuhandler %u
NoDisplay=true
StartupNotify=true
Icon=$XDG_DATA_HOME/icons/osu-wine.png" | tee "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop" >/dev/null
    chmod +x "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop" >/dev/null
    update-desktop-database "$XDG_DATA_HOME/applications"

    # Fix to importing maps/skins/osu links after Stable update 20250122.1: https://osu.ppy.sh/home/changelog/stable40/20250122.1
    Info "Setting up file (.osz/.osk) and url associations..."

    # Adding the osu-handler.reg file to registry
    waitWine regedit /s "$XDG_DATA_HOME/osuconfig/update/stuff/osu-handler.reg"
    $okay
}

# Open files/links with osu-handler-wine
osuHandlerHandle() {
    local ARG="${*:-}"
    local OSUHANDLERPATH="$XDG_DATA_HOME/osuconfig/update/stuff/osu-handler-wine"
    [ ! -x "$OSUHANDLERPATH" ] && chmod +x "$OSUHANDLERPATH"

    case "$ARG" in
    osu://*)
        echo "Trying to load link ($ARG).." >&2
        exec "$OSUHANDLERPATH" 'C:\\windows\\system32\\start.exe' "$ARG"
        ;;
    *.osr | *.osz | *.osk | *.osz2)
        echo "Trying to load file ($ARG).." >&2
        local EXT="${ARG##*.}"
        exec "$OSUHANDLERPATH" 'C:\\windows\\system32\\start.exe' "/ProgIDOpen" "osustable.File.$EXT" "$ARG"
        ;;
    esac
    # If we reached here, it must means osu-handler failed/none of the cases matched
    Error "Unsupported osu! file ($ARG) !" >&2
    Error "Try running \"bash $SCRPATH fixosuhandler\" !" >&2
    return 1
}

InstallDxvk() {
    # Installing patched dxvk-osu binaries, read more in stuff/dxvk-osu.
    Info "Installing DXVK for improved osu! compatibility mode performance..."
    cp "${SCRDIR}"/stuff/dxvk-osu/x64/*.dll "$WINEPREFIX/drive_c/windows/system32"
    cp "${SCRDIR}"/stuff/dxvk-osu/x32/*.dll "$WINEPREFIX/drive_c/windows/syswow64"

    # Setting DllOverrides for those to Native
    for dll in dxgi d3d8 d3d9 d3d10core d3d11; do
        waitWine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "$dll" /d native /f
    done
    $okay
}

installWinetricks() {
    if [ ! -x "$WINETRICKS" ]; then
        Info "Installing winetricks..."
        DownloadFile "$WINETRICKSLINK" "/tmp/winetricks" || return 1
        mv "/tmp/winetricks" "$XDG_DATA_HOME/osuconfig"
        chmod +x "$WINETRICKS"
        $okay
    fi
    return 0
}

FixUmu() {
    if [ ! -f "$BINDIR/osu-wine" ] || [ -z "${LAUNCHERPATH}" ]; then
        Error "Looks like you haven't installed osu-winello yet, so you should run ./osu-winello.sh first." && return 1
    fi
    Info "Looks like you're updating from the umu-launcher based osu-wine, so we'll try to run a full update now..."
    Info "Please answer 'yes' when asked to update the 'osu-wine' launcher"

    Update "${LAUNCHERPATH}" || { Error "Updating failed... Please do a fresh install of osu-winello." && return 1; }
    $okay
}

FixYawl() {
    if [ ! -f "$BINDIR/osu-wine" ]; then
        Error "Looks like you haven't installed osu-winello yet, so you should run ./osu-winello.sh first." && return 1
    elif [ ! -f "$WINE" ]; then
        Error "yawl not found, you should run ./osu-winello.sh first." && return 1
    fi

    Info "Fixing yawl..."
    YAWL_VERBS="update;reinstall" "$WINE" "--version" && chk="$?"
    if [ "${chk}" != 0 ]; then
        Error "That didn't seem to work... try again?" && return 1
    else
        Info "yawl should be good to go now."
    fi
    $okay
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
    {
        InitialSetup &&
            InstallWine &&
            FullInstall
    } || exit 1
    ;;

'uninstall')
    Uninstall || exit 1
    ;;

'gosumemory')
    Gosumemory || exit 1
    ;;

'tosu')
    tosu || exit 1
    ;;

'discordrpc')
    discordRpc || exit 1
    ;;

'fixfolders')
    folderFixSetup || exit 1
    ;;

'fixprefix')
    reconfigurePrefix fresh || exit 1
    ;;

# Also catch "fixosuhandler"
*osu*handler)
    osuHandlerSetup || exit 1
    ;;

'handle')
    # Should be called by the osu-handler desktop files (or osu-wine for backwards compatibility)
    osuHandlerHandle "${@:2}" || exit 1
    ;;

'installdxvk')
    InstallDxvk || exit 1
    ;;

'installwinetricks')
    installWinetricks || exit 1
    ;;

'changedir')
    installOrChangeDir || exit 1
    ;;

update*)
    Update "${2:-}" || exit 1 # second argument is the path to the osu-wine launcher, expected to be called by `osu-wine --update`
    ;;

# "umu" kept for backwards compatibility when updating from umu-launcher based osu-wine
*umu*)
    FixUmu || exit 1
    ;;

*yawl*)
    FixYawl || exit 1
    ;;

*help* | '-h')
    Help
    ;;

*)
    Info "Unknown argument(s): ${*}"
    Help
    ;;
esac

# Congrats for reading it all! Have fun playing osu!
# (and if you wanna improve the script, PRs are always open :3)

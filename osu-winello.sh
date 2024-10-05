#!/usr/bin/env bash

#   =======================================
#   Welcome to Winello!
#   The whole script is divided in different
#   functions to make it easier to read.
#   Feel free to contribute!
#   =======================================

# Proton-osu current versions for update
PROTONVERSION=9.6.0
LASTPROTONVERSION=0 

# Proton-osu mirrors
PROTONLINK="https://github.com/whrvt/umubuilder/releases/download/proton-osu-9-6/proton-osu-9-6.tar.xz"


#   =====================================
#   =====================================
#           INSTALLER FUNCTIONS
#   =====================================
#   =====================================


# Simple echo function (but with cool text e.e)
function Info(){
    echo -e '\033[1;34m'"Winello:\033[0m $*";
}

# Function to quit the install but not revert it in some cases
function Quit(){
    echo -e '\033[1;31m'"Winello:\033[0m $*"; exit 1;
}

# Function to revert the install in case of any type of fail
function Revert(){
    echo -e '\033[1;31m'"Reverting install...:\033[0m"
    rm -f "$HOME/.local/share/icons/osu-wine.png"
    rm -f "$HOME/.local/share/applications/osu-wine.desktop"
    rm -f "$HOME/.local/bin/osu-wine"
    rm -rf "$HOME/.local/share/osuconfig"
    rm -f "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz"
    rm -f "/tmp/osu-mime.tar.xz"
    rm -rf "/tmp/osu-mime"
    rm -f "$HOME/.local/share/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    rm -f "/tmp/winestreamproxy-2.0.3-amd64.tar.xz"
    rm -rf "/tmp/winestreamproxy"
    echo -e '\033[1;31m'"Reverting done, try again with ./osu-winello.sh\033[0m"
}


# Error function pointing at Revert(), but with an appropriate message
function Error(){
    echo -e '\033[1;31m'"Script failed:\033[0m $*"; Revert ; exit 1;
}


# Function looking for basic stuff needed for installation
function InitialSetup(){

    # Better to not run the script as root, right?
    if [ "$USER" = "root" ] ; then Error "Please run the script without root" ; fi

    # Checking for previous versions of osu-wine (mine or DiamondBurned's)
    if [ -e /usr/bin/osu-wine ] ; then Quit "Please uninstall old osu-wine (/usr/bin/osu-wine) before installing!"; fi
    if [ -e "$HOME/.local/bin/osu-wine" ] ; then Quit "Please uninstall Winello (osu-wine --remove) before installing!" ; fi

    Info "Welcome to the script! Follow it to install osu! 8)"

    # Setting root perms. to either 'sudo' or 'doas'
    root_var="sudo"
    if command -v doas >/dev/null 2>&1 ; then
        doascheck=$(doas id -u)
        if [ "$doascheck" = "0" ] ; then 
            root_var="doas"
        fi
    fi

    # Checking if ~/.local/bin is in PATH:
    mkdir -p "/home/$USER/.local/bin"
    pathcheck=$(echo "$PATH" | grep -q "/home/$USER/.local/bin" && echo "y")

    # If ~/.local/bin is not in PATH:
    if [ "$pathcheck" != "y" ] ; then
        
        if grep -q "bash" "$SHELL" ; then
            touch -a "/home/$USER/.bashrc"
            echo "export PATH=/home/$USER/.local/bin:$PATH" >> "/home/$USER/.bashrc"
        fi

        if grep -q "zsh" "$SHELL" ; then
            touch -a "/home/$USER/.zshrc"
            echo "export PATH=/home/$USER/.local/bin:$PATH" >> "/home/$USER/.zshrc"
        fi

        if grep -q "fish" "$SHELL" ; then
            mkdir -p "/home/$USER/.config/fish" && touch -a "/home/$USER/.config/fish/config.fish"
            fish_add_path ~/.local/bin/
        fi
    fi

    # Well, we do need internet ig...
    Info "Checking for internet connection.."
    ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && ! ping -c 1 google.com >/dev/null 2>&1 && Error "Please connect to internet before continuing xd. Run the script again"

    # Looking for dependencies..
    deps=(wget zenity)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1 ; then
            Error "Please install $dep before continuing!"
        fi
    done

    # Ubuntu/Debian Hotfix: Install Steam as it is apparently needed from drivers to work with Proton
    if $root_var apt update; then
        Info "Ubuntu/Debian-based distro detected.."
        Info "Please insert your password to install dependencies!"
        $root_var dpkg --add-architecture i386
        $root_var apt install libgl1-mesa-dri libgl1-mesa-dri:i386 steam -y || Error "Dependencies install failed, check apt or your connection.."
    fi
}

# Function to install script files, umu-launcher and Proton-osu
function InstallProton(){
    
    Info "Installing game script:"
    cp ./osu-wine "$HOME/.local/bin/osu-wine" && chmod +x "$HOME/.local/bin/osu-wine"

    Info "Installing icons:"
    mkdir -p "$HOME/.local/share/icons"    
    cp "./stuff/osu-wine.png" "$HOME/.local/share/icons/osu-wine.png" && chmod 644 "$HOME/.local/share/icons/osu-wine.png"

    Info "Installing .desktop:"
    mkdir -p "$HOME/.local/share/applications"
    echo "[Desktop Entry]
Name=osu!
Comment=osu! - Rhythm is just a *click* away!
Type=Application
Exec=/home/$USER/.local/bin/osu-wine %U
Icon=/home/$USER/.local/share/icons/osu-wine.png
Terminal=false
Categories=Wine;Game;" | tee "$HOME/.local/share/applications/osu-wine.desktop" >/dev/null
    chmod +x "$HOME/.local/share/applications/osu-wine.desktop"

    if [ -d "$HOME/.local/share/osuconfig" ]; then
        Info "Skipping osuconfig.."
    else
        mkdir "$HOME/.local/share/osuconfig"
    fi

    Info "Installing Proton-osu:"
    # Downloading Proton..
    wget -O "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" "$PROTONLINK" && chk="$?"
    if [ ! "$chk" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" "$PROTONLINK" || Error "Download failed, check your connection" 
    fi

    # This will extract Proton-osu and set last version to the one downloaded
    tar -xf "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/osuconfig"
    LASTPROTONVERSION="$PROTONVERSION"
    rm -f "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz"

    # The update function works under this folder: it compares variables from files stored in osuconfig 
    # with latest values from GitHub and check whether to update or not
    Info "Installing script copy for updates.."
    mkdir -p "$HOME/.local/share/osuconfig/update"
    git clone https://github.com/NelloKudo/osu-winello.git "$HOME/.local/share/osuconfig/update" || Error "Git failed, check your connection.."
    echo "$LASTPROTONVERSION" >> "$HOME/.local/share/osuconfig/protonverupdate"

    ## Setting up umu-launcher from the Proton package
    Info "Setting up umu-launcher.."
    UMU_RUN="$HOME/.local/share/osuconfig/proton-osu/umu-run"
    export GAMEID="osu-wine-umu"
}

# Function configuring folders to install the game
function ConfigurePath(){
    
    Info "Configuring osu! folder:"
    Info "Where do you want to install the game?: 
          1 - Default path (~/.local/share/osu-wine)
          2 - Custom path"
    read -r -p "$(Info "Choose your option: ")" installpath
    
    if [ "$installpath" = 1 ] || [ "$installpath" = 2 ] ; then  
    
        case "$installpath" in
        
        '1')  
            
            mkdir -p "$HOME/.local/share/osu-wine"
            GAMEDIR="$HOME/.local/share/osu-wine"
            
            if [ -d "$GAMEDIR/OSU" ]; then
                OSUPATH="$GAMEDIR/OSU"
                echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
            else
                mkdir -p "$GAMEDIR/osu!"
                OSUPATH="$GAMEDIR/osu!"
                echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
            fi
        ;;
        
        '2')
        
            Info "Choose your directory: "
            GAMEDIR="$(zenity --file-selection --directory)"
        
            if [ -e "$GAMEDIR/osu!.exe" ]; then
                OSUPATH="$GAMEDIR"
                echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" 
            else
                mkdir -p "$GAMEDIR/osu!"
                OSUPATH="$GAMEDIR/osu!"
                echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
            fi
        ;;
     
        esac

    else
    
        Info "No option chosen, installing to default.. (~/.local/share/osu-wine)"

        mkdir -p "$HOME/.local/share/osu-wine"
        GAMEDIR="$HOME/.local/share/osu-wine"
        
        if [ -d "$GAMEDIR/OSU" ]; then
            OSUPATH="$GAMEDIR/OSU"
            echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
        else
            mkdir -p "$GAMEDIR/osu!"
            OSUPATH="$GAMEDIR/osu!"
            echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
        fi

    fi
}

# Here comes the real Winello 8)
# What the script will install, in order, is:
# - osu!mime and osu!handler to properly import skins and maps
# - Wineprefix
# - Regedit keys to integrate native file manager with Wine
# - Winestreamproxy for Discord RPC (flatpak users, google "flatpak discord rpc")

function FullInstall(){

    Info "Configuring osu-mime and osu-handler:"

    # Installing osu-mime from https://aur.archlinux.org/packages/osu-mime
    wget -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" && chk="$?"
    
    if [ ! "$chk" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
    fi
    
    tar -xf "/tmp/osu-mime.tar.gz" -C "/tmp"
    mkdir -p "$HOME/.local/share/mime/packages"
    cp "/tmp/osu-mime/osu-file-extensions.xml" "$HOME/.local/share/mime/packages/osuwinello-file-extensions.xml"
    update-mime-database "$HOME/.local/share/mime"
    rm -f "/tmp/osu-mime.tar.gz"
    rm -rf "/tmp/osu-mime"
    
    # Installing osu-handler from https://github.com/openglfreak/osu-handler-wine / https://aur.archlinux.org/packages/osu-handler
    # Binary was compiled from source on Ubuntu 18.04
    wget -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/NelloKudo/osu-winello/raw/main/stuff/osu-handler-wine" && chk="$?"
    
    if [ ! "$chk" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/NelloKudo/osu-winello/raw/main/stuff/osu-handler-wine" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
    fi
    
    chmod +x "$HOME/.local/share/osuconfig/osu-handler-wine"

    # Creating entries for those two
    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=application/x-osu-skin-archive;application/x-osu-replay;application/x-osu-beatmap-archive;
Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %f
NoDisplay=true
StartupNotify=true
Icon=/home/$USER/.local/share/icons/osu-wine.png" | tee "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop" >/dev/null

    echo "[Desktop Entry]
Type=Application
Name=osu!
MimeType=x-scheme-handler/osu;
Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %u
NoDisplay=true
StartupNotify=true
Icon=/home/$USER/.local/share/icons/osu-wine.png" | tee "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osuwinello-url-handler.desktop" >/dev/null
    update-desktop-database "$HOME/.local/share/applications"


    # Time to install my prepackaged Wineprefix, which works in most cases
    # The script is still bundled with osu-wine --fixprefix, which should do the job for me as well

    PREFIXLINK="https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix-umu.tar.xz"
    export PROTONPATH="$HOME/.local/share/osuconfig/proton-osu"

    Info "Configuring Wineprefix:"

    # Variable to check if download finished properly
    failprefix="false"

    mkdir -p "$HOME/.local/share/wineprefixes"
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
            
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
            rm -rf "$HOME/.local/share/wineprefixes/osu-wineprefix"
        fi
    fi

    # So if there's no prefix (or the user wants to reinstall):
    if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then

        # Downloading prefix in temporary ~/.winellotmp folder
        # to make up for this issue: https://github.com/NelloKudo/osu-winello/issues/36
        mkdir -p "$HOME/.winellotmp"
        wget -O "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.tar.xz" && chk="$?" 
    
        # If download failed:
        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.tar.xz" || failprefix="true"
        fi     

        # Checking whether to create prefix manually or install it from repos
        if [ "$failprefix" = "true" ]; then
            WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$UMU_RUN" winetricks dotnet20 dotnet48 gdiplus_winxp win2k3
        else
            tar -xf "$HOME/.winellotmp/osu-winello-prefix-umu.tar.xz" -C "$HOME/.local/share/wineprefixes"
            mv "$HOME/.local/share/wineprefixes/osu-umu" "$HOME/.local/share/wineprefixes/osu-wineprefix" 
        fi 

        # Cleaning..
        rm -rf "$HOME/.winellotmp"

        # We're now gonna refer to this as Wineprefix
        export WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix"

        # Time to debloat the prefix a bit and make necessary symlinks (example: drag and drop)
        rm -rf "$WINEPREFIX/dosdevices"
        rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
        mkdir -p "$WINEPREFIX/dosdevices"
        ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
	    ln -s / "$WINEPREFIX/dosdevices/z:"

        # Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        # This only involves regedit keys.

        cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu"
        "$UMU_RUN" reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        "$UMU_RUN" reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        "$UMU_RUN" reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""

    fi

    # Installing Winestreamproxy for Discord RPC (https://github.com/openglfreak/winestreamproxy)

    if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix/drive_c/winestreamproxy" ] ; then
        Info "Configuring Winestreamproxy (Discord RPC)"
        wget -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" && chk="$?"
    
        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" 
        fi  

        mkdir -p "/tmp/winestreamproxy"
        tar -xf "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" -C "/tmp/winestreamproxy"
        
        # Make sure to kill wineserver when installing it or otherwise it will most likely fail to install.
        WINESERVER_PATH="$PROTONPATH/files/bin/wineserver"
        WINE_PATH="$PROTONPATH/files/bin/wine"
        $WINESERVER_PATH -k && WINE=$WINE_PATH bash "/tmp/winestreamproxy/install.sh"
        
        rm -f "/tmp/winestreamproxy-2.0.3-amd64.tar.gz"
        rm -rf "/tmp/winestreamproxy"
    
    fi

    # Well...
    Info "Downloading osu!"
    if [ -s "$OSUPATH/osu!.exe" ]; then
      
        Info "Installation is completed! Run 'osu-wine' to play osu!"
        Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
        exit 0

    else
        wget -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" && chk="$?"

        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" 
        fi  

        Info "Installation is completed! Run 'osu-wine' to play osu!"
        Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
        exit 0

    fi
}


#   =====================================
#   =====================================
#          POST-INSTALL FUNCTIONS
#   =====================================
#   =====================================


# This function reads files located in ~/.local/share/osuconfig
# to see whether a new wine-osu version has been released.
function Update(){

    # Checking for old installs with Wine
    if [ -d "$HOME/.local/share/osuconfig/wine-osu" ]; then
        Quit "wine-osu detected and already up-to-date; please reinstall Winello if you want to use proton-osu!"
    fi

    # Reading the last version installed
    LASTPROTONVERSION=$(</"$HOME/.local/share/osuconfig/protoneverupdate")

    if [ "$LASTPROTONVERSION" \!= "$PROTONVERSION" ]; then
        wget -O "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" "$PROTONLINK" && chk="$?"

        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" "$PROTONLINK" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
        fi
        Info "Updating Proton-osu"...

        rm -rf "$HOME/.local/share/osuconfig/proton-osu"
        tar -xf "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/osuconfig"
        rm -f "/tmp/proton-osu-${PROTONVERSION}-x86_64.pkg.tar.xz"
        LASTPROTONVERSION="$PROTONVERSION"
        rm -f "$HOME/.local/share/osuconfig/protoneverupdate"
        echo "$LASTPROTONVERSION" >> "$HOME/.local/share/osuconfig/protoneverupdate"
        Info "Update is completed!"

    else
        Info "Your Proton-osu is already up-to-date!"
    fi
}


# Well, simple function to install the game (also implement in osu-wine --remove)
function Uninstall(){

    Info "Uninstalling icons:"
    rm -f "$HOME/.local/share/icons/osu-wine.png"
    
    Info "Uninstalling .desktop:"
    rm -f "$HOME/.local/share/applications/osu-wine.desktop"
    
    Info "Uninstalling game script, utilities & folderfix:"
    rm -f "$HOME/.local/bin/osu-wine"
    rm -f "$HOME/.local/bin/folderfixosu"
    rm -f "$HOME/.local/share/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$HOME/.local/share/applications/osuwinello-url-handler.desktop"

    Info "Uninstalling proton-osu:"
    rm -rf "$HOME/.local/share/osuconfig/proton-osu"
    
    read -r -p "$(Info "Do you want to uninstall Wineprefix? (y/n)")" wineprch

    if [ "$wineprch" = 'y' ] || [ "$wineprch" = 'Y' ]; then
        rm -rf "$HOME/.local/share/wineprefixes/osu-wineprefix"
    else
        Info "Skipping.." ; fi

    read -r -p "$(Info "Do you want to uninstall game files? (y/n)")" choice
    
    if [ "$choice" = 'y' ] || [ "$choice" = 'Y' ]; then
        read -r -p "$(Info "Are you sure? This will delete your files! (y/n)")" choice2
        
        if [ "$choice2" = 'y' ] || [ "$choice2" = 'Y' ]; then
		    
            Info "Uninstalling game:"
            if [ -e "$HOME/.local/share/osuconfig/osupath" ]; then
                OSUUNINSTALLPATH=$(<"$HOME/.local/share/osuconfig/osupath")
		        rm -rf "$OSUUNINSTALLPATH"
                rm -rf "$HOME/.local/share/osuconfig"
            else
                rm -rf "$HOME/.local/share/osuconfig"
            fi

        else
            rm -rf "$HOME/.local/share/osuconfig"
            Info "Exiting.."
        fi
    
    else
        rm -rf "$HOME/.local/share/osuconfig"
    fi
    
    Info "Uninstallation completed!"
}


# Simple function that downloads Gosumemory!
function Gosumemory(){
    GOSUMEMORY_LINK="https://github.com/l3lackShark/gosumemory/releases/download/1.3.9/gosumemory_windows_amd64.zip"

    if [ ! -d "$HOME/.local/share/osuconfig/gosumemory" ]; then
        Info "Installing gosumemory.."
        mkdir -p "$HOME/.local/share/osuconfig/gosumemory"
        wget -O "/tmp/gosumemory.zip" "$GOSUMEMORY_LINK" || Error "Download failed, check your connection.."
        unzip -d "$HOME/.local/share/osuconfig/gosumemory" -q "/tmp/gosumemory.zip"
        rm "/tmp/gosumemory.zip"
    fi
}

function tosu(){
    TOSU_LINK="https://github.com/KotRikD/tosu/releases/download/v3.3.1/tosu-windows-v3.3.1.zip"
    
    if [ ! -d "$HOME/.local/share/osuconfig/tosu" ]; then
        Info "Installing tosu.."
        mkdir -p "$HOME/.local/share/osuconfig/tosu"
        wget -O "/tmp/tosu.zip" "$TOSU_LINK" || Error "Download failed, check your connection.."
        unzip -d "$HOME/.local/share/osuconfig/tosu" -q "/tmp/tosu.zip"
        rm "/tmp/tosu.zip"
    fi
}   

# Help!
function Help(){
    Info "To install the game, run ./osu-winello.sh
          To uninstall the game, run ./osu-winello.sh uninstall
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
    InstallProton
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
    
    'update')
    Update
    ;;

    'help')
    Help
    ;;

    '-h')
    Help
    ;;

    *)
    Info "Unknown argument, see ./osu-winello.sh help or ./osu-winello.sh -h"
    ;;
esac

# Congrats for reading it all! Have fun playing osu!
# (and if you wanna improve the script, PRs are always open :3)

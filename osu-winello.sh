#!/usr/bin/env bash

#   =======================================
#   Welcome to Winello!
#   The whole script is divided in different
#   functions; this first part is related to
#   variables I can easily update (ex. Wine ver)
#   =======================================
#   

# Wine-osu current versions for update
WINEVERSION=7.16.0
LASTWINEVERSION=0 

# Current version of GLIBC on the user's system (needed to check if wine-osu builds are compatible or not)
CURRENTGLIBC="$(ldd --version | tac | tail -n1 | awk '{print $(NF)}')"
MINGLIBC=2.27

# Wine-osu mirrors
WINELINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-stable-7.16/wine-osu-7.16-x86_64.tar.xz"
WINEBACKUPLINK="https://www.dropbox.com/s/p7stmsx0zd2rn7o/wine-osu-7.16-x86_64.tar.xz?dl=0"

# Checking for --no-deps flag:
USEDEPS="true"
for arg in "$@" ; do
    if [ "$arg" == "--no-deps" ]; then
        USEDEPS="false"
    fi
done

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
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"
    rm -f "/tmp/osu-mime.tar.xz"
    rm -rf "/tmp/osu-mime"
    rm -f "$HOME/.local/share/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    rm -rf "/tmp/tempfonts"
    rm -f "/tmp/winestreamproxy-2.0.3-amd64.tar.xz"
    rm -rf "/tmp/winestreamproxy"
    echo -e '\033[1;31m'"Reverting done, try again with ./osu-winello.sh\033[0m"

    if [ "$osid" == "debian" ]; then
      "$root_var" mv /etc/apt/sources.list.bak /etc/apt/sources.list ; fi
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
            echo "export PATH=/home/$USER/.local/bin:$PATH" >> "/home/$USER/.config/fish/config.fish"
        fi
    fi

    # Well, we do need internet ig...
    Info "Checking for internet connection.."
    ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && (! ping -c google.com && Error "Please connect to internet before continuing xd. Run the script again")

}


# Function to install all needed dependencies on various distros
# Supported ones, for the time being, are: Ubuntu (and der.), Debian, Arch Linux (and der.),
# SteamOS, Fedora, Nobara, Gentoo and openSUSE.
function Dependencies(){

    # Checking for --no-deps flag
    if [ "$USEDEPS" == "false" ]; then
        Info "--no-deps found, skipping dependencies.."
        return
    fi

    # Reading the OS ID from /etc/os-release
    osid=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"') 

    # Checking for Debian/Ubuntu:
    if command -v apt >/dev/null 2>&1 ; then
        if ! ( command -v dnf >/dev/null 2>&1 || command -v emerge >/dev/null 2>&1 ) ; then
        
            Info "Debian/Ubuntu detected, installing dependencies..."
            Info "Please enter your password when asked"
            Info "------------------------------------"
                    
            if [ "$osid" == "debian" ] ; then
            
                Info "Installing needed packages for dependencies.."
                "$root_var" apt update && "$root_var" apt install -y software-properties-common

                nonfreestatus="true"
                "$root_var" dpkg --add-architecture i386
                "$root_var" apt install -y steam || nonfreestatus="false"

                if [ "$nonfreestatus" == "false" ]; then

                    Info "Looks like non-free repositories are not enabled on your system"
                    Info "Those are needed in order to install libraries to play osu! properly."
                    read -r -p "$(Info "Do you want to enable non-free repositories? (Y/N): ")" nonfreechoice
                
                    if [ "$nonfreechoice" == 'Y' ] || [ "$nonfreechoice" == 'y' ]; then
                
                        # Now checking for all lines supposed to be there, according to https://wiki.debian.org/Steam:
                        # Remember that Steam is necessary for apt to pull libGL and other libraries. 
                        if grep "deb http://deb.debian.org/debian/ bullseye main contrib" /etc/apt/sources.list || grep "deb http://deb.debian.org/debian bullseye main contrib" /etc/apt/sources.list || grep "deb http://deb.debian.org/debian/ bullseye main" /etc/apt/sources.list; then 
                    
                            grepline=$(echo "$(grep -n -o '[0-9]*'"deb http://deb.debian.org/debian bullseye main contrib" /etc/apt/sources.list)" | cut -c1-3)
                    
                            if [ "$grepline" == "" ]; then grepline=$(echo "$(grep -n -o '[0-9]*'"deb http://deb.debian.org/debian/ bullseye main contrib" /etc/apt/sources.list)" | cut -c1-3) ; fi
                            if [ "$grepline" == "" ]; then grepline=$(echo "$(grep -n -o '[0-9]*'"deb http://deb.debian.org/debian/ bullseye main" /etc/apt/sources.list)" | cut -c1-3) ; fi		
                                
                            linenumber=$(echo "$grepline" | grep -o '[0-9]*')
                    
                            # Additional check to make sure sed doesn't really replace everything if non-free is already found for some reason
                            if ! grep "deb http://deb.debian.org/debian/ bullseye main contrib non-free" /etc/apt/sources.list || ! grep "deb http://deb.debian.org/debian bullseye main contrib non-free" /etc/apt/sources.list || ! grep "deb http://deb.debian.org/debian/ bullseye main non-free" /etc/apt/sources.list ; then
                                "$root_var" sh -c "sed -i.bak '${linenumber}s/$/ non-free/' /etc/apt/sources.list" && Info "non-free added successfully."
                            fi
                
                        else

                            "$root_var" sh -c 'echo "deb http://deb.debian.org/debian bullseye main non-free" >> /etc/apt/sources.list'

                        fi
    
                    else

                        Error "non-free repositories are needed for the script to work properly. Closing the script.."  
                    fi

                fi

            Info "Installing packages and wine-staging dependencies.."
            
            "$root_var" mkdir -pm755 /etc/apt/keyrings
            "$root_var" wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
            "$root_var" wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources
            "$root_var" apt update
            "$root_var" apt install -y --install-recommends winehq-staging || Error "Some libraries didn't install for some reason, check apt or your connection"
            "$root_var" apt install -y git curl steam build-essential zstd p7zip-full zenity || Error "Some libraries didn't install for some reason, check apt or your connection"
            
            else
            
                Info "Installing packages and wine-staging dependencies.."

                "$root_var" apt update && "$root_var" apt upgrade -y
                "$root_var" dpkg --add-architecture i386
                wget -nc https://dl.winehq.org/wine-builds/winehq.key
                "$root_var" apt-key add winehq.key
                "$root_var" apt-add-repository -y 'https://dl.winehq.org/wine-builds/ubuntu/'
                "$root_var" apt update
                "$root_var" apt install -y --install-recommends winehq-staging || Error "Some libraries didn't install for some reason, check apt or your connection" 
                "$root_var" apt install -y git curl steam build-essential zstd p7zip-full zenity || Error "Some libraries didn't install for some reason, check apt or your connection"
            
                Info "Dependencies done, skipping.."
        
            fi
        fi
    fi

    # Checking for Gentoo
    if command -v emerge >/dev/null 2>&1 ; then

        Info "Gentoo detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"

        "$root_var" mkdir -p /etc/portage/sets
        Info "Creating @osu-winello package set.."
        printf "dev-vcs/git\napp-arch/zstd\napp-arch/p7zip\nnet-misc/wget\ngnome-extra/zenity\nvirtual/wine\napp-emulation/winetricks\n" | "$root_var" tee /etc/portage/sets/osu-winello
        Info "Adding required USE flags.."
        printf "media-libs/libsdl2 haptic\n" | "$root_var" tee /etc/portage/package.use/osu-winello

        if ! grep -q '@osu-winello' /var/lib/portage/world_sets; then
            if ! emerge --info | grep -q 'ABI_X86="64 32"' && ! emerge --info | grep -q 'ABI_X86="32 64"'; then
                Info "Error: Unsupported configuration."
                Info "Enable abi_x86_32 globally *or* manually emerge the @osu-winello set."
                Info
                Info 'To enable it globally, set ABI_X86="64 32" in /etc/portage/make.conf and run "emerge --newuse @world".'
                Error "Cannot continue, there *will* be circular dependencies to resolve!"
            fi
        fi

        "$root_var" emerge --noreplace @osu-winello || Error "Some libraries didn't install for some reason, check portage or your connection"
        Info "Dependencies done, skipping.."
    fi

    # Checking for Arch Linux
    if command -v pacman >/dev/null 2>&1 ; then

        Info "Arch Linux/SteamOS detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"

        if [ "$osid" != "steamos" ] ; then

            if ! grep -q -E '^\[multilib\]' '/etc/pacman.conf'; then
                Info "Enabling multilib.."
                printf "\n# Multilib repo enabled by osu-winello\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | "$root_var" tee -a /etc/pacman.conf
            fi

            Info "Installing packages and wine-staging dependencies.."
            if command -v wine >/dev/null 2>&1 ; then
                Info "Wine (possibly) already found, removing it to replace with staging.."
                "$root_var" pacman -Rdd --noconfirm wine || Info "Looks like staging is already installed"
            fi
            
            "$root_var" pacman -Sy --noconfirm --needed git base-devel p7zip wget zenity wine-staging winetricks giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba dosbox || Error "Some libraries didn't install for some reason, check pacman or your connection"
            Info "Dependencies done, skipping.." 

        else

            deck_fs_check=$("$root_var" [ -w /usr ] && echo "rw" || echo "ro")
            if [ "$deck_fs_check" = "ro" ]; then
                Error "The Steam Deck's file system is in read-only mode, preventing further action. To continue, you must disable read-only mode. More information can be found on GitHub: https://github.com/NelloKudo/osu-winello#steam-deck-support"
            else
                "$root_var" pacman --needed -Sy libxcomposite lib32-libxcomposite gnutls lib32-gnutls wine winetricks || Error "Check your connection"

            fi
        fi
    fi

    # Checking for Fedora / Nobara
    if command -v dnf >/dev/null 2>&1 ; then
    
        Info "Fedora/Nobara detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"
        Info "Installing packages and wine-staging dependencies.."

        "$root_var" dnf install -y git zstd p7zip p7zip-plugins wget zenity || Error "Some libraries didn't install for some reason, check dnf or your connection"

        osid=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        
        if [ "$osid" != "nobara" ] ; then

            "$root_var" dnf install -y winetricks || Error "Some libraries didn't install for some reason, check dnf or your connection"
            "$root_var" dnf install -y wine || Error "Some libraries didn't install for some reason, check dnf or your connection"

        fi

        Info "Dependencies done, skipping.."
    
    fi

    # Checking for openSUSE
    if command -v zypper >/dev/null 2>&1 ; then

        Info "openSUSE detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"
        Info "Installing packages and wine-staging dependencies.."

        "$root_var" zypper install -y git zstd 7zip wget zenity || Error "Some libraries didn't install for some reason, check zypper or your connection"
        "$root_var" zypper install -y winetricks || Error "Some libraries didn't install for some reason, check zypper or your connection"
        "$root_var" zypper install -y wine || Error "Some libraries didn't install for some reason, check zypper or your connection"

        Info "Dependencies done, skipping.."
    
    fi
}


# Function to install script files and Wine 
function InstallWine(){
    
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
    Categories=Wine;Game;" | tee "$HOME/.local/share/applications/osu-wine.desktop"
    chmod +x "$HOME/.local/share/applications/osu-wine.desktop"

    Info "Installing wine-osu:"

    # If the distro's GLIBC is older than 2.27 (how is that possible)
    if [ "$CURRENTGLIBC" \< "$MINGLIBC" ]; then
        
        Info "Seems like your distro is too old and well, not supported by this wine build.."
        Info "Do you want to use your system's Wine and continue the install? (assuming you have that)"
        read -r -p "$(Info "Choose your option (Y/N):")" winechoice

        if [ "$winechoice" = 'y' ] || [ "$winechoice" = 'Y' ]; then
            mkdir -p "$HOME/.local/share/osuconfig/wine-osu"
            ln -sf "/usr/bin/wine" "$HOME/.local/share/osuconfig/wine-osu/bin/wine" 
        else
            Error "Exiting.."
        fi
    
    else

        # Checking if GitHub download works
        if ! wget --spider "$WINELINK" 2>/dev/null; then
            Info "Wine download link seems to be down; using backup.."
            WINELINK="$WINEBACKUPLINK"
        fi
        
        # Downloading Wine..
        wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" && chk="$?"
        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" || Error "Download failed, check your connection" 
        fi

        # This will extract wine-osu and set last version to the one downloaded
        tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/"
        LASTWINEVERSION="$WINEVERSION"
    
        if [ -d "$HOME/.local/share/osuconfig" ]; then
            Info "Skipping osuconfig.."
        else
            mkdir "$HOME/.local/share/osuconfig"
        fi
        
        mv "$HOME/.local/share/wine-osu" "$HOME/.local/share/osuconfig"
        rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"

        # The update function works under this folder: it compares variables from files stored in osuconfig 
        # with latest values from GitHub and check whether to update or not
        Info "Installing script copy for updates.."
        mkdir -p "$HOME/.local/share/osuconfig/update"
        git clone https://github.com/NelloKudo/osu-winello.git "$HOME/.local/share/osuconfig/update" || Error "Git failed, check your connection.."
        echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"
    
    fi

    # Installing Winetricks from upstream to make sure Wineprefix installs properly
    wget -O "$HOME/.local/share/osuconfig/winetricks" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && chk="$?"
    if [ ! "$chk" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "$HOME/.local/share/osuconfig/winetricks" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
    fi

    chmod +x "$HOME/.local/share/osuconfig/winetricks"
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


# Installer for --basic (no tweaks, just a barebones prefix to run the game)
function BasicInstall(){

    Info "Configuring Wineprefix:"
    mkdir -p "$HOME/.local/share/wineprefixes"
    
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
          
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then

            rm -rf "$HOME/.local/share/wineprefixes/osu-wineprefix"
            Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
            export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
	        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet40 
       
        else

            Info "Skipping..." 
        fi

    else
        
        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet40
        
    fi

    Info "Downloading osu!"
    if [ -s "$OSUPATH/osu!.exe" ]; then
      
        Info "Installation is completed! Run 'osu-wine' to play osu!"
        Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
        exit 0
    
    else
      
        wget -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" && chk="$?"
    
        if [ ! "$chk" = 0 ] ; then
          
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe"    
        
        fi
    
      Info "Installation is completed! Run 'osu-wine' to play osu!"
      Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
      exit 0

    fi
}


# Time to look for Lutris (and Flatpak Lutris, too)
function LutrisCheck(){
    
    if [ -d "$HOME/.local/share/lutris" ]; then
        
        Info "Lutris was found, do you want to copy wine-osu there? (y/n)"
        read -r -p "$(Info "Choose your option: ")" lutrischoice
            
            if [ "$lutrischoice" = 'y' ] || [ "$lutrischoice" = 'Y' ]; then
                mkdir -p "$HOME/.local/share/lutris/runners/wine"

                # Checking for Classic Lutris
                if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
                    Info "wine-osu is already installed in Lutris, skipping..."
                else
                    cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine" 
                fi

                # Checking for Flatpak Lutris too
                if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris" ]; then
                    mkdir -p "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
                    
                    if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
                        Info "wine-osu is already installed in Flatpak Lutris, skipping..."
                    else
                        cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine" ; fi
                    fi

            else
                Info "Skipping.."
            fi
    fi

    # Then if Flatpak Lutris is installed, but there's no Wine in it, that either means
    # the user refused (and will likely refuse again) or repo Lutris isn't installed, so checking again:
    if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris" ] && [ ! -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
        
        Info "Flatpak Lutris was found, do you want to copy wine-osu there? (y/n)"
        read -r -p "$(Info "Choose your option: ")" lutrischoice2
        
        if [ "$lutrischoice2" = 'y' ] || [ "$lutrischoice2" = 'Y' ]; then
        
            mkdir -p "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
            if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
                Info "wine-osu is already installed in Flatpak Lutris, skipping..."
            else
                cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
            fi
        
        else
            Info "Skipping"..
        fi

    else
        Info "Skipping.."
    fi
}


# Here comes the real Winello 8)
# What the script will install, in order, is:
# - osu!mime and osu!handler to properly import skins and maps
# - Wineprefix
# - Windows 10 Fonts, for missing special and JP characters
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
    chmod +x "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"

    echo "[Desktop Entry]
    Type=Application
    Name=osu!
    MimeType=x-scheme-handler/osu;
    Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %u
    NoDisplay=true
    StartupNotify=true
    Icon=/home/$USER/.local/share/icons/osu-wine.png" | tee "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    update-desktop-database "$HOME/.local/share/applications"




    # Time to install my prepackaged Wineprefix, which works in most cases
    # The script is still bundled with osu-wine --fixprefix, which should do the job for me as well

    Info "Configuring Wineprefix:"

    # Let's use our wine-osu for everything to prevent errors
    export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
    
    mkdir -p "$HOME/.local/share/wineprefixes"
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
            
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
            rm -rf "$HOME/.local/share/wineprefixes/osu-wineprefix"
        else
            Info "Skipping.."
        fi
    fi

    # So if there's no prefix (or the user wants to reinstall):
    if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then

        # Checking if the prefix was downloaded in a previous attempt
        if [ ! -s "/tmp/WINE.win32.7z" ] ; then
            wget -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" && chk="$?" 
        
            # If download failed:
            if [ ! "$chk" = 0 ] ; then
                Info "wget failed; trying with --no-check-certificate.."
                wget --no-check-certificate -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" && chk="$?"
            
                # If it failed again (lol):
                if [ ! "$chk" = 0 ] || [ ! -s "/tmp/WINE.win32.7z" ] ; then
                    Info "The downloaded hasn't finished properly, creating the prefix manually.."
                    manualprefix="true"
                fi
            fi
        fi

        # Variable to check if extraction finished properly
        fail7z="false"

        # Checking whether to create prefix manually or install it from repos
        if [ "$manualprefix" = "true" ]; then
            WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet48 gdiplus_winxp comctl32 win2k3 || Error "Winetricks failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" 
        
        else
            7z x -y -o/tmp/osu-wineprefix "/tmp/WINE.win32.7z" || fail7z="true"
            
            # Checking whether 7z extraction failed
            if [ "$fail7z" == "false" ]; then
                cp -r "/tmp/osu-wineprefix/.osuwine/" "$HOME/.local/share/wineprefixes/osu-wineprefix"
                rm -rf "/tmp/osu-wineprefix/"

            else
                Info "7z extraction failed; trying with tar.gz package.."
                
                # Cleaning old downloads
                rm "/tmp/WINE.win32.7z"
                rm -rf "/tmp/osu-wineprefix"

                wget -O "/tmp/WINE.win32.tar.gz" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.tar.gz" && chk="$?"
                if [ ! "$chk" = 0 ] ; then
                    Info "wget failed; trying with --no-check-certificate.."
                    wget --no-check-certificate -O "/tmp/WINE.win32.tar.gz" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.tar.gz" && chk="$?"
            
                    # If it failed again (lol):
                    if [ ! "$chk" = 0 ] || [ ! -s "/tmp/WINE.win32.tar.gz" ] ; then
                        Info "The downloaded hasn't finished properly, creating the prefix manually.."
                        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet48 gdiplus_winxp comctl32 win2k3 || Error "Winetricks failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" 
                    fi
                fi

                # If prefix hasn't been created yet, then it didn't install manually.
                # We can finally extract the new one, then..?
                if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
                    tar -xf "/tmp/WINE.win32.tar.gz" -C "/tmp" || Error "Extraction failed, try again or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
                    cp -r "/tmp/osu-wineprefix/.osuwine/" "$HOME/.local/share/wineprefixes/osu-wineprefix"

                    # Cleaning..
                    rm -rf "/tmp/osu-wineprefix/"
                fi
            fi
        fi 

        # We're now gonna refer to this as Wineprefix
        export WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix"

        # Time to debloat the prefix a bit and make necessary symlinks (example: drag and drop)
        rm -rf "$WINEPREFIX/dosdevices"
        rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
        mkdir -p "$WINEPREFIX/dosdevices"
        ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
	    ln -s / "$WINEPREFIX/dosdevices/z:"



        # Now installing W10 fonts from https://github.com/YourRandomGuy/ttf-ms-win10
        # You could also install them from AUR or whatever, the script only installs them in-game.

        Info "Installing fonts..."
        mkdir -p "/tmp/tempfonts"
        git clone "https://github.com/YourRandomGuy/ttf-ms-win10.git" "/tmp/tempfonts" || Error "Git failed, check your connection or open an issue at here: https://github.com/NelloKudo/osu-winello/issues"
        mkdir -p "$HOME/.local/share/osuconfig/W10Fonts"
        cp /tmp/tempfonts/*{.ttf,.ttc} "$HOME/.local/share/osuconfig/W10Fonts"

        # Linking fonts to Wine
        rm -rf "$HOME/.local/share/osuconfig/wine-osu/share/wine/fonts"
        ln -s "$HOME/.local/share/osuconfig/W10Fonts" "$HOME/.local/share/osuconfig/wine-osu/share/wine/fonts"
        rm -rf "/tmp/tempfonts"

        # Lutris Wine fonts
        if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
            rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu/share/wine/fonts"
            ln -s "$HOME/.local/share/osuconfig/W10Fonts" "$HOME/.local/share/lutris/runners/wine/wine-osu/share/wine/fonts"
        fi

        # Flatpak Lutris Wine fonts
        if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
            rm -rf "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu/share/wine/fonts"
            ln -s "$HOME/.local/share/osuconfig/W10Fonts" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu/share/wine/fonts" 
        fi
        


        # Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        # This only involves regedit keys.

        (cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu") || (Info "Seems like the file wasn't found for some reason lol. Copying it from backup.." && cp "$HOME/.local/share/osuconfig/update/fixfolderosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu")
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""

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
        (WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wineserver -k && WINE="$HOME/.local/share/osuconfig/wine-osu/bin/wine" WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" bash "/tmp/winestreamproxy/install.sh") || Info "Installing Winestreamproxy failed, try to install it yourself later"
        
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

    if [ ! "$CURRENTGLIBC" \< "$MINGLIBC" ]; then
        
        # Reading the last version installed
        LASTWINEVERSION=$(</"$HOME/.local/share/osuconfig/wineverupdate")
    
        if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
            wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" && chk="$?"
    
            if [ ! "$chk" = 0 ] ; then
                Info "wget failed; trying with --no-check-certificate.."
                wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"
            fi

            # Now updating..
            Info "Updating wine-osu"...

            tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/"
            rm -rf "$HOME/.local/share/osuconfig/wine-osu"
            mv "$HOME/.local/share/wine-osu" "$HOME/.local/share/osuconfig/"
            rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"
            LASTWINEVERSION="$WINEVERSION"
            rm -f "$HOME/.local/share/osuconfig/wineverupdate"
            echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"

            # Checking updates for Lutris too..
            if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
                read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
                
                if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
                    rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu"
                    cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
                else
                    Info "Skipping...."
                fi
            fi

            if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ] ; then
                read -r -p "$(Info "Do you want to update wine-osu in Flatpak Lutris too? (y/n)")" lutrupdate2
                
                if [ "$lutrupdate2" = 'y' ] || [ "$lutrupdate2" = 'Y' ]; then
                    rm -rf "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu"
                    cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu"
                else
                    Info "Skipping...."
                fi
            fi
    
        Info "Update is completed!"
    
      else
        Info "Your wine-osu is already up-to-date!"
      
      fi

    else
      Info "Try updating your system.."
    
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

    Info "Uninstalling wine-osu:"
    rm -rf "$HOME/.local/share/osuconfig/wine-osu"
    
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


# Just a function to download W10 fonts again in case someone needs to
function W10Fonts(){

    Info "Which way do you want to install fonts?
    1: GitHub (Faster, Small Download, Classic JP and KR fonts)
    2: Iso (5GBs, includes ALL fonts from W10 isos)"

    read -r -p "$(Info "Choose your option: ")" fontsch
    
    if [ "$fontsch" = 1 ] || [ "$fontsch" = 2 ] ; then  
    case "$installpath" in

    '1')
        if [ -d "$HOME/.local/share/fonts/W10Fonts" ] ; then
            Info "Fonts already found, skipping.."
    
        else
            # W10fonts by https://github.com/YourRandomGuy/ttf-mswin10
            Info "Installing Windows fonts... (read below)"
            mkdir -p "/tmp/tempfonts"
            git clone "https://github.com/YourRandomGuy/ttf-ms-win10.git" "/tmp/tempfonts" || Error "Git failed, check your connection or open an issue at here: https://github.com/NelloKudo/osu-winello/issues"
            mkdir -p "$HOME/.local/share/fonts/W10Fonts"
            cp /tmp/tempfonts/*{.ttf,.ttc} "$HOME/.local/share/fonts/W10Fonts"
            rm -rf "/tmp/tempfonts"
            fc-cache -f "$HOME/.local/share/fonts/W10Fonts"

        Info "Finished installing fonts.."
        fi
    ;;

    '2')

    # W10fonts by ttf-win10 on AUR (https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=ttf-win10)
    # If the package will be updated (and I won't have modified it yet) you can just edit the next 4 variables according to the link above
   
   pkgver=19043.928.210409
    _minor=1212.21h1
    _type="release_svc_refresh"
    sha256sumiso="026607e7aa7ff80441045d8830556bf8899062ca9b3c543702f112dd6ffe6078"
    _file="${pkgver}-${_minor}_${_type}_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"

    if [ -e "$HOME/${_file}" ]; then
        Info "Iso already exists; skipping download..."
    else
        wget -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" && chk="$?" 
    
        if [ ! "$chk" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" || Error "Download keeps failing, check the code at line ~1000 or your connection"
        fi
    fi
    
    Info "Running checksum.."
    if [ "$sha256sumiso" = "$(sha256sum "$HOME/${_file}" | cut -d' ' -f1)" ] && echo OK ; then
    
        Info "Checksum passes; extracting fonts.."
        mkdir -p "$HOME/.local/share/fonts"
        mkdir -p "$HOME/.local/share/fonts/Microsoft"
        mkdir -p "$HOME/.local/share/licenses"
        7z e "$HOME/${_file}" sources/install.wim
        7z e install.wim Windows/Fonts/* -o"$HOME/.local/share/fonts/Microsoft"
        7z x install.wim Windows/System32/Licenses/neutral/"*"/"*"/license.rtf -o"$HOME/.local/share/licenses" -y
        fc-cache -f "$HOME/.local/share/fonts/Microsoft/"
        rm -f "$HOME/${_file}"
        rm -f ./install.wim
    
    else

        Info "Checksum doesn't pass, your download may be corrupted: cleaning"
        Info "Try again later with osu-wine --w10fonts"
        rm -f "$HOME/${_file}" ; fi
    ;;

    esac

    else
    Info "Unknown argument, using github.."
    
    if [ -d "$HOME/.local/share/fonts/W10Fonts" ] ; then
        Info "Fonts already found, skipping.." ;  
    
    else

        # W10fonts by https://github.com/YourRandomGuy/ttf-mswin10
        Info "Installing Windows fonts... (read below)"
        mkdir -p "/tmp/tempfonts"
        git clone "https://github.com/YourRandomGuy/ttf-ms-win10.git" "/tmp/tempfonts" || Error "Git failed, check your connection or open an issue at here: https://github.com/NelloKudo/osu-winello/issues"
        mkdir -p "$HOME/.local/share/fonts/W10Fonts"
        cp /tmp/tempfonts/*{.ttf,.ttc} "$HOME/.local/share/fonts/W10Fonts"
        rm -rf "/tmp/tempfonts"
        fc-cache -f "$HOME/.local/share/fonts/W10Fonts"

        Info "Finished installing fonts.."
    fi
    
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
    Dependencies
    InstallWine
    ConfigurePath
    LutrisCheck
    FullInstall
    ;;

    '--basic')
    InitialSetup
    Dependencies
    InstallWine
    ConfigurePath
    BasicInstall
    ;;

    'uninstall')
    Uninstall
    ;;

    'w10fonts')
    W10Fonts
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

    '--no-deps')
    ./osu-winello.sh "$2" --no-deps
    ;;

    *)
    Info "Unknown argument, see ./osu-winello.sh help or ./osu-winello.sh -h"
    ;;
esac

# Congrats for reading it all! Have fun playing osu!
# (and if you wanna improve the script, PRs are always open :3)
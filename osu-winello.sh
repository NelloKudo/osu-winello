#!/bin/bash
set -e

#Variables
WINEVERSION=7.0
LASTWINEVERSION=0 #example: changes when installing/updating
CURRENTGLIBC="$(ldd --version | tac | tail -n1 | awk '{print $(NF)}')"
MINGLIBC=2.32
GDRIVEID=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc #Google Drive ID for wine-osu

#W10fonts by ttf-win10 on AUR (https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=ttf-win10)
#If the package will be updated (and I won't have modified it yet) you can just edit the next 4 variables according to the link above
pkgver=19043.928.210409
_minor=1212.21h1
_type="release_svc_refresh"
sha256sumiso="026607e7aa7ff80441045d8830556bf8899062ca9b3c543702f112dd6ffe6078"
_file="${pkgver}-${_minor}_${_type}_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"

Info()
{ 
    echo -e '\033[1;34m'"Winello:\033[0m $*";
}

Error()
{  
    echo -e '\033[1;31m'"Error:\033[0m $*"; exit 1;
}

function install()
{
    if [ -e /usr/bin/osu-wine ] ; then Error "Please uninstall old osu-wine (/usr/bin/osu-wine) before installing!" ; fi #Checking DiamondBurned's osu-wine
    if [ -e "$HOME/.local/bin/osu-wine" ] ; then Error "Please uninstall osu-wine before installing!" ; fi

    #/.local/bin check
    if [ ! -d "$HOME/.local/bin" ] ; then
        mkdir -p "$HOME/.local/bin"
        if (grep -q "bash" "$SHELL" || [[ -f "$HOME/.bashrc" ]]) && ! grep -q "PATH="$HOME/.local/bin/:$PATH"" "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin/:$PATH"' >> "$HOME/.bashrc"
            source "$HOME/.bashrc"
        fi

        if (grep -q "zsh" "$SHELL" || [[ -f "$HOME/.zshrc" ]]) && ! grep -q "PATH="$HOME/.local/bin/:$PATH"" "$HOME/.zshrc"; then
            echo 'export PATH="$HOME/.local/bin/:$PATH"' >> "$HOME/.zshrc"
            source "$HOME/.zshrc"
        fi

        if [[ -f "$HOME/.config/fish/config.fish" ]] && ! grep -q "PATH="$HOME/.local/bin/:$PATH"" "$HOME/.config/fish/config.fish"; then
            echo 'export PATH="$HOME/.local/bin/:$PATH"' >> "$HOME/.config/fish/config.fish" 
            source "$HOME/.config/fish/config.fish"
        fi
    fi

    Info "Installing game script:"
    cp ./osu-wine "$HOME/.local/bin/osu-wine" && chmod 755 "$HOME/.local/bin/osu-wine"

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
    Categories=Wine;Game;" >> "$HOME/.local/share/applications/osu-wine.desktop"
    chmod +x "$HOME/.local/share/applications/osu-wine.desktop"
    
    Info "Installing wine-osu:"
    if [ "$CURRENTGLIBC" \< "$MINGLIBC" ]; then
    Info "1 - Ubuntu and derivatives (Linux Mint, Pop_OS, Zorin OS etc.)
          2 - openSUSE Tumbleweed
          3 - openSUSE Leap 15.3
          4 - exit"
    read -r -p "$(Info "Choose your distro: ")" distro
    case "$distro" in 
        '1')
        echo 'deb http://download.opensuse.org/repositories/home:/hwsnemo:/packaged-wine-osu/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:hwsnemo:packaged-wine-osu.list
        curl -fsSL https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_hwsnemo_packaged-wine-osu.gpg > /dev/null
        sudo apt update
        sudo apt install wine-osu
        if [ -d "$HOME/.local/share/osuconfig" ]; then
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        fi
        ;;
        '2')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Tumbleweed/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu
        if [ -d "$HOME/.local/share/osuconfig" ]; then
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        fi
        ;;
        '3')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Leap_15.3/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu
        if [ -d "$HOME/.local/share/osuconfig" ]; then
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        fi
        ;; 
	    '4')
	    exit 0
	    ;;
    esac
    else
    wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" "https://docs.google.com/uc?export=download&id=${GDRIVEID}" && wgetcheck1="$?"
    
    if [ ! "$wgetcheck1" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" "https://docs.google.com/uc?export=download&id=${GDRIVEID}" && wgetcheckdrive="$?" 
    
    if [ ! "$wgetcheckdrive" = 0 ] ; then
    Info "Google Drive download failed; cleaning install..."
    rm -f "$HOME/.local/share/icons/osu-wine.png"
    rm -f "$HOME/.local/share/applications/osu-wine.desktop"
    rm -f "$HOME/.local/bin/osu-wine"
    Info "Try running again ./osu-winello.sh"
    exit 0 
    fi    
    fi

    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C "$HOME/.local/share/"
    LASTWINEVERSION="$WINEVERSION"
    
    if [ -d "$HOME/.local/share/osuconfig" ]; then
    Info "Skipping osuconfig.."
    else
    mkdir "$HOME/.local/share/osuconfig"
    fi
    
    mv "$HOME/.local/share/opt/wine-osu" "$HOME/.local/share/osuconfig"
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    rm -rf "$HOME/.local/share/opt"
    Info "Installing script copy for updates.."
    mkdir -p "$HOME/.local/share/osuconfig/update"
    git clone https://github.com/NelloKudo/osu-winello.git "$HOME/.local/share/osuconfig/update"
    echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"
    fi
    
    #LutrisCheck
    if [ -d "$HOME/.local/share/lutris" ]; then
    Info "Lutris was found, do you want to copy wine-osu there? (y/n)"
    read -r -p "$(Info "Choose your option: ")" lutrischoice
        if [ "$lutrischoice" = 'y' ] || [ "$lutrischoice" = 'Y' ]; then
            if [ -d "$HOME/.local/share/lutris/runners/wine" ]; then
                if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
                Info "wine-osu is already installed in Lutris, skipping..."
                else
                cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine" ; fi
            else
            mkdir "$HOME/.local/share/lutris/runners/wine"
            cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine" ; fi
        else
        Info "Skipping.."; fi
    fi

    Info "Configuring osu! folder:"
    Info "Where do you want to install the game?: 
          1 - Default path (~/.local/share/osu-wine)
          2 - Custom path"
    read -r -p "$(Info "Choose your option: ")" installpath
    if [ "$installpath" = 1 ] || [ "$installpath" = 2 ] ; then  
    case "$installpath" in
        '1')
        if [ -d "$HOME/.local/share/osu-wine" ]; then
        Info "osu-wine folder already exists: skipping.."
        else
        mkdir "$HOME/.local/share/osu-wine"
        fi
        GAMEDIR="$HOME/.local/share/osu-wine"
        if [ -d "$GAMEDIR/OSU" ] || [ -d "$GAMEDIR/osu!" ]; then
        Info "osu! folder already exists: skipping.."
        if [ -d "$GAMEDIR/OSU" ]; then
        OSUPATH="$GAMEDIR/OSU"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        if [ -d "$GAMEDIR/osu!" ]; then
        OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        else
        mkdir "$GAMEDIR/osu!"
        export OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
        fi
        ;;
        '2')
        Info "Choose your directory: "
        GAMEDIR="$(zenity --file-selection --directory)"
        if [ -d "$GAMEDIR/osu!" ] || [ -e "$GAMEDIR/osu!.exe" ]; then
        Info "osu! folder/game already exists: skipping.."
        if [ -d "$GAMEDIR/osu!" ]; then
        OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        if [ -e "$GAMEDIR/osu!.exe" ]; then
        OSUPATH="$GAMEDIR"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        else
        mkdir "$GAMEDIR/osu!"
        OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
        fi
        ;;
    esac
    else
    Info "No option chosen, installing to default.. (~/.local/share/osu-wine)"
    if [ -d "$HOME/.local/share/osu-wine" ]; then
        Info "osu-wine folder already exists: skipping.."
        else
        mkdir "$HOME/.local/share/osu-wine"
        fi
        GAMEDIR="$HOME/.local/share/osu-wine"
        if [ -d "$GAMEDIR/OSU" ] || [ -d "$GAMEDIR/osu!" ]; then
        Info "osu! folder already exists: skipping.."
        if [ -d "$GAMEDIR/OSU" ]; then
        OSUPATH="$GAMEDIR/OSU"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        if [ -d "$GAMEDIR/osu!" ]; then
        OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath" ; fi
        else
        mkdir "$GAMEDIR/osu!"
        export OSUPATH="$GAMEDIR/osu!"
        echo "$OSUPATH" > "$HOME/.local/share/osuconfig/osupath"
        fi
    fi

    #W10fonts by ttf-win10 on AUR (https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=ttf-win10)
    Info "Skipping to Windows fonts... (read below)"
    Info "WARNING: Download is ~5gb, you can also install them later with osu-wine --w10fonts"
    read -r -p "$(Info "Do you want to install Windows fonts in your system? - Needed for jp characters! (y/n): ")" fontschoice 
    if [ "$fontschoice" = 'y' ] || [ "$fontschoice" = 'Y' ]; then
    
    if [ -e "$HOME/${_file}" ]; then
    Info "Iso already exists; skipping download..."
    else
    wget -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" && wgetcheck2="$?"
    
     if [ ! "$wgetcheck2" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" ; fi
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
    fi

    Info "Configuring osu-mime and osu-handler:"
    #Installing osu-mime from https://aur.archlinux.org/packages/osu-mime
    wget -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" && wgetcheck3="$?"
    
    if [ ! "$wgetcheck3" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" ; fi
    
    tar -xf "/tmp/osu-mime.tar.gz" -C "/tmp"
    mkdir -p "$HOME/.local/share/mime"
    mkdir -p "$HOME/.local/share/mime/packages"
    cp "/tmp/osu-mime/osu-file-extensions.xml" "$HOME/.local/share/mime/packages"
    update-mime-database "$HOME/.local/share/mime"
    rm -f "/tmp/osu-mime.tar.gz"
    rm -rf "/tmp/osu-mime"
    
    #Installing osu-handler from https://github.com/openglfreak/osu-handler-wine / https://aur.archlinux.org/packages/osu-handler
    wget -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/openglfreak/osu-handler-wine/releases/download/v0.3.0/osu-handler-wine" && wgetcheck4="$?"
    
    if [ ! "$wgetcheck4" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/openglfreak/osu-handler-wine/releases/download/v0.3.0/osu-handler-wine" ; fi
    
    chmod +x "$HOME/.local/share/osuconfig/osu-handler-wine"

    echo "[Desktop Entry]
    Type=Application
    Name=osu!
    MimeType=application/x-osu-skin-archive;application/x-osu-replay;application/x-osu-beatmap-archive;
    Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %f
    NoDisplay=true
    StartupNotify=true
    Icon=/home/$USER/.local/share/icons/osu-wine.png" >> "$HOME/.local/share/applications/osu-file-extensions-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osu-file-extensions-handler.desktop"

    echo "[Desktop Entry]
    Type=Application
    Name=osu!
    MimeType=x-scheme-handler/osu;
    Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %u
    NoDisplay=true
    StartupNotify=true
    Icon=/home/$USER/.local/share/icons/osu-wine.png" >> "$HOME/.local/share/applications/osu-url-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osu-url-handler.desktop"
    update-desktop-database "$HOME/.local/share/applications"

    Info "Configuring Wineprefix:"
    mkdir -p "$HOME/.local/share/wineprefixes"
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then

        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        Info "Remember to skip Wine Mono:"
        #Install needed components
        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f dotnet48 gdiplus_winxp cjkfonts 

        #Fix for Linux Mint which doesn't accept gdiplus_winxp for some reason lol
        if [ -d "/etc/linuxmint" ] ; then
        Info "Mint detected; installing gdiplus to fix..."
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f gdiplus ; fi

        #Sets Windows version to 2003, seems to solve osu!.db problems etc.
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q win2k3
        
        #Hides Wine version (only with staging - needed to fix cursor and numbers)
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine" /v HideWineExports /t REG_SZ /d Y
        
        #Skips creating filetype associations and desktop entries
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\FileOpenAssociations" /v Enable /d N
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v winemenubuilder /t REG_SZ /d ""

        #Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""

        else
		if [ ! -e "$HOME/.local/share/osuconfig/folderfixosu" ] ; then
		cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu"
		fi
		
        Info "Skipping..." ; fi
    else
        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        Info "Remember to skip Wine Mono:"
        #Install needed components
        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f dotnet48 gdiplus_winxp cjkfonts
        
        #Fix for Linux Mint which doesn't accept gdiplus_winxp for some reason lol
        if [ -d "/etc/linuxmint" ] ; then
        Info "Mint detected; installing gdiplus to fix..."
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f gdiplus ; fi

        #Sets Windows version to 2003, seems to solve osu!.db problems etc.
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q win2k3

        #Hides Wine version (only with staging - needed to fix cursor and numbers)
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine" /v HideWineExports /t REG_SZ /d Y

        #Skips creating filetype associations and desktop entries
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\FileOpenAssociations" /v Enable /d N
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v winemenubuilder /t REG_SZ /d ""

        #Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""
        
    fi

    #Installing Winestreamproxy from https://github.com/openglfreak/winestreamproxy
    if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix/drive_c/winestreamproxy" ] ; then
    Info "Configuring Winestreamproxy (Discord RPC)"
    wget -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" && wgetcheck5="$?"
    
    if [ ! "$wgetcheck5" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" ; fi
    
    mkdir -p "/tmp/winestreamproxy"
    tar -xf "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" -C "/tmp/winestreamproxy"
    export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
    WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wineserver -k && WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" bash "/tmp/winestreamproxy/install.sh"
    rm -f "/tmp/winestreamproxy-2.0.3-amd64.tar.gz"
    rm -rf "/tmp/winestreamproxy"
    fi

    Info "Downloading osu!"
    if [ -s "$OSUPATH/osu!.exe" ]; then
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
    exit 0
    else
    wget -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" && wgetcheck6="$?"
    
    if [ ! "$wgetcheck6" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" ; fi
    
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
    fi
}

function uninstall() 
{
    
    Info "Uninstalling icons:"
    rm -f "$HOME/.local/share/icons/osu-wine.png"
    
    Info "Uninstalling .desktop:"
    rm -f "$HOME/.local/share/applications/osu-wine.desktop"
    
    Info "Uninstalling game script & folderfix:"
    rm -f "$HOME/.local/bin/osu-wine"
    rm -f "$HOME/.local/bin/folderfixosu"

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
        rm -rf "$HOME/.local/share/osuconfig"; fi
        else
        rm -rf "$HOME/.local/share/osuconfig"
        Info "Exiting.."
        fi
    else
    rm -rf "$HOME/.local/share/osuconfig"
    fi
    Info "Uninstallation completed!"
}

function update()
{   
    if [ "$CURRENTGLIBC" \< "$MINGLIBC" ]; then
    Info "1 - Ubuntu and derivatives (Linux Mint, Pop_OS, Zorin OS etc.)
          2 - openSUSE Tumbleweed
          3 - openSUSE Leap 15.3
          4 - exit"
    read -r -p "$(Info "Choose your distro: ")" distro
    case "$distro" in 
        '1')
        sudo apt update
        sudo apt install wine-osu
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig/wine-osu"

        if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
        read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
        if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
        rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu"
        cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
        else
        Info "Skipping...." ;fi
        fi

        Info "Update is completed!"
        ;;

        '2')
        zypper refresh
        zypper install wine-osu 
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig/wine-osu"
        
        if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
        read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
        if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
        rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu"
        cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
        else
        Info "Skipping...." ;fi
        fi

        Info "Update is completed!"
        ;;

        '3')
        zypper refresh
        zypper install wine-osu
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig/wine-osu"
        
        if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then   
        read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
        if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
        rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu"
        cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
        else
        Info "Skipping...." ;fi
        fi

        Info "Update is completed!"
        ;;

	'4')
	exit 0
	;;
    esac
    else
    LASTWINEVERSION=$(</"$HOME/.local/share/osuconfig/wineverupdate")
    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
    wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" "https://docs.google.com/uc?export=download&id=${GDRIVEID}" && wgetcheck7="$?"
    
    if [ ! "$wgetcheck7" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" "https://docs.google.com/uc?export=download&id=${GDRIVEID}" ; fi
    
    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C "$HOME/.local/share/"
    rm -rf "$HOME/.local/share/osuconfig/wine-osu"
    mv "$HOME/.local/share/opt/wine-osu" "$HOME/.local/share/osuconfig/"
    rm -rf "$HOME/.local/share/opt"
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    LASTWINEVERSION="$WINEVERSION"
    rm -f "$HOME/.local/share/osuconfig/wineverupdate"
    echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"

    if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
    read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
    if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
    rm -rf "$HOME/.local/share/lutris/runners/wine/wine-osu"
    cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
    else
    Info "Skipping...." ;fi
    fi
    
    Info "Update is completed!"
    else
    Error "Your wine-osu is already up-to-date!"
    fi
    fi

}

function help() 
{   

Info "To install the game, run ./osu-winello.sh
    To uninstall the game, run ./osu-winello.sh uninstall
    To update the wine-osu version, run ./osu-winello.sh update"
    
}

case "$1" in
    'uninstall')	
	uninstall
	exit 0
	;;
	
	'help')	
	help
	;;
	
	'update')	
	update
	;;
	
	'')				
	install
	;;
	
    'w10fonts')
    if [ -e "$HOME/${_file}" ]; then
    Info "Iso already exists; skipping download..."
    else
    wget -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" && wgetcheck8="$?" 
    
    if [ ! "$wgetcheck8" = 0 ] ; then
    Info "wget failed; trying with --no-check-certificate.."
    wget --no-check-certificate -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" ; fi
   
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
	*)				
	Error "Unknown argument, see ./osu-winello.sh help"
	;;
esac

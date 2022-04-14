#!/bin/bash
set -e

#Variables
WINEVERSION=7.0
LASTWINEVERSION=0 #example: changes when installing/updating
CURRENTGLIBC="$(ldd --version | tac | tail -n1 | awk '{print $(NF)}')"
MINGLIBC=2.32

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
    MimeType=x-scheme-handler/osu
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
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
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
    wget "https://software-download.microsoft.com/download/pr/${_file}" --output-document "$HOME/${_file}" ; fi
    
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

    Info "Configuring Wineprefix:"
    mkdir -p "$HOME/.local/share/wineprefixes"
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
        export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"

        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        Info "Remember to skip Wine Mono:"
        #Install needed components
        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f dotnet48 gdiplus_winxp comctl32 cjkfonts 

        #Fix for Linux Mint which doesn't accept gdiplus_winxp for some reason lol
        if [ -d "/etc/linuxmint" ] ; then
        Info "Mint detected; installing gdiplus to fix..."
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f gdiplus ; fi

        #Sets Windows version to 2003, seems to solve osu!.db problems etc.
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q win2k3
        
        #Hides Wine version (only with staging - needed to fix cursor and numbers)
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine" /v HideWineExports /t REG_SZ /d Y
        
        #Skips creating filetype associations
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\FileOpenAssociations" /v Enable /d N
        
        else
        Info "Skipping..." ; fi
    else
    export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        Info "Remember to skip Wine Mono:"
        #Install needed components
        WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q -f dotnet48 gdiplus_winxp comctl32 cjkfonts
        
        #Sets Windows version to 2003, seems to solve osu!.db problems etc.
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" winetricks -q win2k3

        #Hides Wine version (only with staging - needed to fix cursor and numbers)
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine" /v HideWineExports /t REG_SZ /d Y

        #Skips creating filetype associations
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\FileOpenAssociations" /v Enable /d N 
    fi

    Info "Downloading osu!"
    if [ -e "$OSUPATH/osu!.exe" ]; then
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    exit 0
    else
    wget  --output-document "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe"
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
    
    Info "Uninstalling game script:"
    rm -f "$HOME/.local/bin/osu-wine"
    
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
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C "$HOME/.local/share/"
    rm -rf "$HOME/.local/share/osuconfig/wine-osu"
    mv "$HOME/.local/share/opt/opt/wine-osu" "$HOME/.local/share/osuconfig/"
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
    wget "https://software-download.microsoft.com/download/pr/${_file}" --output-document "$HOME/${_file}" ; fi
    
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

#!/bin/bash
set -e

WINEVERSION=7.0
LASTWINEVERSION=7.0
HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
CURRENTGLIBC="$(ldd --version | tac | tail -n1 | awk '{print $(NF)}')"
MINGLIBC=2.32

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
    if [ "$EUID" -ne 0 ]; then Error "Run the script as root with sudo!" ; fi

    if [ -d "$HOME/.local/share/osu-wine/WINE.win32" ]; then #checking diamondburned's osu-wine
    rm -f "/usr/bin/osu-wine"
    rm -f "/usr/share/icons/hicolor/256x256/apps/osu-wine.png"
    rm -f "/usr/share/applications/osu-wine.desktop"
    fi

    if [ -e /usr/bin/osu-wine ] ; then Error "Please uninstall before installing!" ; fi
    
    Info "Installing icons:"    
    cp "./stuff/osu-wine.png" "/usr/share/icons/hicolor/256x256/apps/osu-wine.png" && chmod 644 "/usr/share/icons/hicolor/256x256/apps/osu-wine.png"
    
    Info "Installing .desktop:"
    cp "./stuff/osu-wine.desktop" "/usr/share/applications/osu-wine.desktop" && chmod 644 "/usr/share/applications/osu-wine.desktop"
    
    Info "Installing game script:"
    cp ./osu-wine "/usr/bin/osu-wine" && chmod 755 "/usr/bin/osu-wine"
    
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
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        fi
        ;;
        '2')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Tumbleweed/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu
        if [ -d "$HOME/.local/share/osuconfig" ]; then
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        fi
        ;;
        '3')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Leap_15.3/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu
        if [ -d "$HOME/.local/share/osuconfig" ]; then
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig"
        else
        mkdir "$HOME/.local/share/osuconfig"
        chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
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
    if [ -d "$HOME/.local/share/osuconfig" ]; then
    Info "Skipping osuconfig.."
    else
    mkdir "$HOME/.local/share/osuconfig" ; fi
    chown -R "$SUDO_USER:" "$HOME/.local/share/osuconfig"
    mv "$HOME/.local/share/opt/wine-osu" "$HOME/.local/share/osuconfig"
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    rm -rf "$HOME/.local/share/opt"
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
    case "$installpath" in
        '1')
        if [ -d "$HOME/.local/share/osu-wine" ]; then
        Info "osu-wine folder already exists: skipping.."
        else
        mkdir "$HOME/.local/share/osu-wine"
        chown -R "$SUDO_USER:" "$HOME/.local/share/osu-wine"
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

    Info "Configuring Wineprefix:"
    if [ -d "$HOME/.local/share/Wineprefixs" ]; then
    chown -R "$SUDO_USER:" "$HOME/.local/share/Wineprefixs"
    Info "Wineprefixs folder already exists: skipping"
    else
    mkdir "$HOME/.local/share/Wineprefixs"
    chown -R "$SUDO_USER:" "$HOME/.local/share/Wineprefixs"
    fi

    if [ -d "/usr/share/fonts/WindowsFonts" ]; then
    Info "Fonts already installed; skipping..."
    else
    read -r -p "$(Info "Do you want to install Windows fonts in your system? - Needed for jp characters! (y/n): ")" fontschoice # Fonts found at https://www.w7df.com/
    if [ "$fontschoice" = 'y' ] || [ "$fontschoice" = 'Y' ]; then
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1M5tGl5-g0ih8wc-w5-_Hs6kQcJLQwCEQ' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1M5tGl5-g0ih8wc-w5-_Hs6kQcJLQwCEQ" --output-document "/tmp/w10fonts.zip" && rm -rf /tmp/cookies.txt
    unzip -q "/tmp/w10fonts.zip" -d "/tmp/w10fonts"
    mkdir /usr/share/fonts/WindowsFonts
    mv -f /tmp/w10fonts/Windows10DefaultFonts/Fonts/* "/usr/share/fonts/WindowsFonts"
    chmod -R 755 "/usr/share/fonts/WindowsFonts" 
    rm -f "/tmp/w10fonts.zip"
    fc-cache -sf    
    fi
    fi

    Info "Downloading osu!"
    if [ -e "$OSUPATH/osu!.exe" ]; then
    chown -R "$SUDO_USER:" "$OSUPATH"
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    exit 0
    else
    wget  --output-document "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe"
    chown -R "$SUDO_USER:" "$OSUPATH"
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    fi
}

function uninstall() 
{
    if [ "$EUID" -ne 0 ]; then Error "Run the script as root with sudo!" ; fi
    
    Info "Uninstalling icons:"
    rm -f "/usr/share/icons/hicolor/256x256/apps/osu-wine.png"
    
    Info "Uninstalling .desktop:"
    rm -f "/usr/share/applications/osu-wine.desktop"
    
    Info "Uninstalling game script:"
    rm -f "/usr/bin/osu-wine"
    
    Info "Uninstalling wine-osu:"
    rm -rf "$HOME/.local/share/osuconfig/wine-osu"
    
    read -r -p "$(Info "Do you want to uninstall Wineprefix? (y/n)")" wineprch
    if [ "$wineprch" = 'y' ] || [ "$wineprch" = 'Y' ]; then
    rm -rf "$HOME/.local/share/Wineprefixs/osu-wineprefix"
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
        Info "Update is completed!"
        ;;
        '2')
        zypper refresh
        zypper install wine-osu 
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig/wine-osu"
        Info "Update is completed!"
        ;;
        '3')
        zypper refresh
        zypper install wine-osu
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        cp -r /opt/wine-osu "$HOME/.local/share/osuconfig/wine-osu"
        Info "Update is completed!"
        ;; 
	'4')
	exit 0
	;;
    esac
    else
    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C "$HOME/.local/share/"
    rm -rf "$HOME/.local/share/osuconfig/wine-osu"
    mv "$HOME/.local/share/opt/opt/wine-osu" "$HOME/.local/share/osuconfig/"
    rm -rf "$HOME/.local/share/opt"
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    LASTWINEVERSION="$WINEVERSION"
    read -r -p "$(Info "Do you want to update wine-osu in Lutris too? (y/n)")" lutrupdate
    if [ "$lutrupdate" = 'y' ] || [ "$lutrupdate" = 'Y' ]; then
    rm -rf "$HOME/.local/share/lutris/ruunners/wine/wine-osu"
    cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine"
    else
    Info "Skipping...." ;fi
    Info "Update is completed!"
    else
    Error "Your wine-osu is already up-to-date!"
    fi
    fi

}

function help() 
{   

Info "To install the game, run sudo ./osu-winello.sh
    To uninstall the game, run sudo ./osu-winello.sh uninstall
    To update the wine-osu version, run sudo ./osu-winello.sh update"
    
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
	
	*)				
	Error "Unknown argument, see ./osu-winello.sh help"
	;;
esac

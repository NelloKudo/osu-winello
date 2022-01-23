#!/bin/bash
set -e

WINEVERSION=7.0
LASTWINEVERSION=7.0
HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
SCRIPTDIR="$HOME/.local/share/osu-wine"
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

    if [ -e /usr/bin/osu-wine ]; then Error "Please uninstall before installing!" ; fi
    
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
        ;;
        '2')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Tumbleweed/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu 
        ;;
        '3')
        zypper addrepo https://download.opensuse.org/repositories/home:hwsnemo:packaged-wine-osu/openSUSE_Leap_15.3/home:hwsnemo:packaged-wine-osu.repo
        zypper refresh
        zypper install wine-osu
        ;; 
	    '4')
	    exit 0
	    ;;
    esac
    else
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C /opt
    mv '/opt/opt/wine-osu' /opt
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    fi

    Info "Configuring osu! folder:"
    if [ -d "$HOME/.local/share/osu-wine" ]; then
    Info "osu-wine folder already exists: skipping.."
    else
    mkdir "$HOME/.local/share/osu-wine"
    fi

    if [ -d "$HOME/.local/share/osu-wine/OSU" ] || [ -d "$HOME/.local/share/osu-wine/osu!" ]; then
    Info "osu! folder already exists: skipping.."
    else
    mkdir "$SCRIPTDIR/osu!"
    export OSUPATH="$SCRIPTDIR/osu!"
    fi

    Info "Downloading and configuring Wineprefix:"
    if [ -d "$HOME/.local/share/osu-wine/osu-wineprefix" ]; then
    export WINEPREFIX="$SCRIPTDIR/osu-wineprefix"
    Info "osu-wineprefix already exists: skipping.."
    else
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1O_iBywTIU4R85d74H1Am7cJ0uxMypM-_' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1O_iBywTIU4R85d74H1Am7cJ0uxMypM-_" --output-document "/tmp/osu-wineprefix.7z" && rm -rf /tmp/cookies.txt
    export WINEPREFIX="$SCRIPTDIR/osu-wineprefix"
    7z x -y -o"$SCRIPTDIR" "/tmp/osu-wineprefix.7z"
    chown -R "$SUDO_USER:" "$HOME/.local/share/osu-wine"
    rm -f "/tmp/osu-wineprefix.7z"
    fi

    Info "Downloading osu!"
    if [ -d "$HOME/.local/share/osu-wine/OSU" ]; then
    Info "Installation is completed! Run 'osu-wine' to play osu!"
    exit 0
    else
    wget  --output-document "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe"

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
    rm -rf /opt/wine-osu
    read -r -p "$(Info "Do you want to uninstall game files and Wineprefix? (y/n)")" choice
    if [ "$choice" = 'y' ] || [ "$choice" = 'Y' ]; then
		Info "Uninstalling game and Wineprefix:"
        rm -rf "$HOME/.local/share/osu-wine/osu-wineprefix"
        rm -rf "$HOME/.local/share/osu-wine/osu"
		rm -rf "$HOME/.local/share/osu-wine"
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
        ;;
        '2')
        zypper refresh
        zypper install wine-osu 
        ;;
        '3')
        zypper refresh
        zypper install wine-osu
        ;; 
	'4')
	exit 0
	;;
    esac
    else
    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
    rm -rf "/opt/wine-osu"
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst" -C /opt
    mv '/opt/opt/wine-osu' /opt
    rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    LASTWINEVERSION="$WINEVERSION"
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


#!/bin/bash
set -e

WINEVERSION=7.0
LASTWINEVERSION=7.0
HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
SCRIPTDIR="$HOME/.local/share/osu-wine"

Info()
{ 
    echo -e "Winello:\033[0m $*"; 
}

Error()
{  
    echo -e "Error:\033[0m $*"; exit 1; 
}

function install()
{
    if [ "$EUID" -ne 0 ]; then Error "Run the script as root with sudo!" ; fi
    if [ -e /usr/bin/osu-wine ]; then Error "Please uninstall before installing!" ; fi
    
    Info "Installing icons:"
    cp "./stuff/osu-wine.png" "/usr/share/icons/hicolor/256x256/apps/osu-wine.png" && chmod 644 "/usr/share/icons/hicolor/256x256/apps/osu-wine.png"
    
    Info "Installing .desktop:"
    cp "./stuff/osu-wine.desktop" "/usr/share/applications/osu-wine.desktop" && chmod 644 "/usr/share/applications/osu-wine.desktop"
    
    Info "Installing game script:"
    cp ./osu-wine "/usr/bin/osu-wine" && chmod 755 "/usr/bin/osu-wine"
    
    Info "Installing wine-osu:"
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "$HOME/osu-winello/stuff/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf ./stuff/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst -C /opt
    mv '/opt/opt/wine-osu' /opt
    
    Info "Downloading and configuring Wineprefix:"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1OrG2pueboJb-sR_8SfmjJn54bGGOAccu' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1OrG2pueboJb-sR_8SfmjJn54bGGOAccu" --output-document "$HOME/osu-winello/stuff/osu-wineprefix.tar.gz" && rm -rf /tmp/cookies.txt
    mkdir "$HOME/.local/share/osu-wine" && mkdir "$HOME/.local/share/osu-wine/osu"
    mkdir "$HOME/.local/share/osu-wine/osu-wineprefix"
    export WINEPREFIX="$SCRIPTDIR/osu-wineprefix"
    export OSUPATH="$SCRIPTDIR/osu"
    chown -R "$SUDO_USER:" "$HOME/.local/share/osu-wine"
    tar -xf ./stuff/osu-wineprefix.tar.gz -C "$SCRIPTDIR/osu-wineprefix"
    ln -s "$OSUPATH" "$WINEPREFIX/dosdevices/x:"
    ln -s "$HOME" "$WINEPREFIX/dosdevices/z:"
    
    Info "Downloading osu!"
    wget  --output-document "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe"
    
    Info "Installation is completed! Run 'osu-wine' to play osu!"
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
		rm -rf "$HOME/.local/share/osu-wine"
    fi
    
    Info "Uninstallation completed!"
}

function update()
{
    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
    rm -rf "/opt/wine-osu"
    wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1xgJIe18ccBx6yjPcmBxDbTnS1XxwrAcc' --output-document "$HOME/osu-winello/stuff/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst"
    tar -xf ./stuff/wine-osu-${WINEVERSION}-x86_64.pkg.tar.zst -C /opt
    mv '/opt/opt/wine-osu' /opt
    LASTWINEVERSION=$WINEVERSION
    else
    Error "Your wine-osu is already up-to-date!"
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

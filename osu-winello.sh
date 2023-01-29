#!/bin/bash

#Variables
WINEVERSION=7.16.0
LASTWINEVERSION=0 
CURRENTGLIBC="$(ldd --version | tac | tail -n1 | awk '{print $(NF)}')"
MINGLIBC=2.27
WINELINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-stable-7.16/wine-osu-7.16-x86_64.tar.xz"
WINEBACKUPLINK="https://www.dropbox.com/s/p7stmsx0zd2rn7o/wine-osu-7.16-x86_64.tar.xz?dl=0"

Info()
{ 
    echo -e '\033[1;34m'"Winello:\033[0m $*";
}

Revert()
{
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
}

Error()
{  
    echo -e '\033[1;31m'"Script failed:\033[0m $*"; Revert ; exit 1;
}

Install()
{

    if [ "$USER" = "root" ] ; then Error "Please run the script without root" ; fi
    
    Info "Welcome to the script! Follow it to install osu! 8)"
   
    if [ -e /usr/bin/osu-wine ] ; then Error "Please uninstall old osu-wine (/usr/bin/osu-wine) before installing!" ; fi #Checking DiamondBurned's osu-wine
    if [ -e "$HOME/.local/bin/osu-wine" ] ; then Error "Please uninstall osu-wine before installing!" ; fi

    #/.local/bin check
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
 
    # Checking for 'sudo' or 'doas'        
    if command -v doas >/dev/null 2>&1 ; then
      doascheck=$(doas id -u)
      if [ "$doascheck" = "0" ] ; then 
        root_var="doas"
      else
        root_var="sudo" ; fi
    else
      root_var="sudo"
    fi

    Info "Checking for internet connection.."
    ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && Error "Please connect to internet before continuing xd. Run the script again"

    Info "Dependencies time.."

    if command -v apt >/dev/null 2>&1 ; then
      if ! ( command -v apt >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1 ) ; then
        
        Info "Debian/Ubuntu detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"
        Info "Installing packages and wine-staging dependencies.."

        "$root_var" apt update && "$root_var" apt upgrade -y
        "$root_var" dpkg --add-architecture i386
        wget -nc https://dl.winehq.org/wine-builds/winehq.key
        "$root_var" apt-key add winehq.key
        "$root_var" apt-add-repository -y 'https://dl.winehq.org/wine-builds/ubuntu/'
        "$root_var" apt update
        "$root_var" apt install -y --install-recommends winehq-staging || if command -v wine >/dev/null 2>&1 ; then Info "Wine stable seems to be found, removing it.." && "$root_var" apt purge -y wine && "$root_var" apt install -y --install-recommends winehq-staging ; fi || Error "Some libraries didn't install for some reason, check apt or your connection" 
        "$root_var" apt install -y winetricks git curl steam build-essential zstd p7zip zenity || Error "Some libraries didn't install for some reason, check apt or your connection"
        
        Info "Dependencies done, skipping.."
      
      fi
    fi
      osid=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

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
      check=$(sudo touch -c /usr/ 2>&1)
    if echo "$check" | grep -q "touch: setting times of '/usr/': Read-only file system"; then
      echo -e '\033[1;31m'"The Steam Deck's file system is in read-only mode, preventing further action. To continue, you must disable read-only mode. More information can be found on GitHub.\033[0m"
    exit 1
  else
    Info "The steam deck's file system is in read-write mode."
  fi
        Info "Installing packages and wine-staging dependencies.."        
        "$root_var" pacman --needed -Sy libxcomposite lib32-libxcomposite gnutls lib32-gnutls wine winetricks || Error "Check your connection"

      fi

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
	    
      Info "Seems like your distro is too old and well, not supported by this wine build.."
      Info "Do you want to use your system's Wine and continue the install? (assuming you have that)"
      read -r -p "$(Info "Choose your option (Y/N):")" winechoice
        
      if [ "$winechoice" = 'y' ] || [ "$winechoice" = 'Y' ]; then
        
        mkdir -p "$HOME/.local/share/osuconfig/wine-osu"
        ln -sf "/usr/bin" "$HOME/.local/share/osuconfig/wine-osu/bin" 
    
      else
    
        Error "Exiting.."
      
      fi
	   
    else

      # Checking which link to use to download wine-osu
      if wget --spider "$WINELINK" 2>/dev/null; then
        Info "Wine link is working, skipping.."
      else
        Info "Wine download link seems to be down; using backup.."
        WINELINK="$WINEBACKUPLINK"
      fi

      wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" && wgetcheck1="$?"
    
      if [ ! "$wgetcheck1" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" || Error "Download failed, check your connection" 
      fi

      tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/"
      LASTWINEVERSION="$WINEVERSION"
    
      if [ -d "$HOME/.local/share/osuconfig" ]; then
        Info "Skipping osuconfig.."
      else
        mkdir "$HOME/.local/share/osuconfig"
      fi
    
      mv "$HOME/.local/share/wine-osu" "$HOME/.local/share/osuconfig"
      rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"
    
      Info "Installing script copy for updates.."
    
      mkdir -p "$HOME/.local/share/osuconfig/update"
      git clone https://github.com/NelloKudo/osu-winello.git "$HOME/.local/share/osuconfig/update" || Error "Git failed, check your connection.."
      echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"
    
    fi
    
    if [ -d "$HOME/.local/share/lutris" ]; then
      Info "Lutris was found, do you want to copy wine-osu there? (y/n)"
      read -r -p "$(Info "Choose your option: ")" lutrischoice
        if [ "$lutrischoice" = 'y' ] || [ "$lutrischoice" = 'Y' ]; then

            mkdir -p "$HOME/.local/share/lutris/runners/wine"
            if [ -d "$HOME/.local/share/lutris/runners/wine/wine-osu" ]; then
                Info "wine-osu is already installed in Lutris, skipping..."
            else
                cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.local/share/lutris/runners/wine" ; fi

            if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris" ]; then
                mkdir -p "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
                if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
                  Info "wine-osu is already installed in Flatpak Lutris, skipping..."
                else
                  cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine" ; fi
            fi

        else
          Info "Skipping.."; fi
    fi

    if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris" ] && [ ! -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
      Info "Flatpak Lutris was found, do you want to copy wine-osu there? (y/n)"
      read -r -p "$(Info "Choose your option: ")" lutrischoice2
        if [ "$lutrischoice2" = 'y' ] || [ "$lutrischoice2" = 'Y' ]; then
        
          mkdir -p "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
          if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ]; then
              Info "wine-osu is already installed in Flatpak Lutris, skipping..."
          else
              cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine" ; fi
        fi

    else
      Info "Skipping.."; fi

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

    Info "Configuring osu-mime and osu-handler:"
    
    # Installing osu-mime from https://aur.archlinux.org/packages/osu-mime
    wget -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" && wgetcheck3="$?"
    
    if [ ! "$wgetcheck3" = 0 ] ; then
      Info "wget failed; trying with --no-check-certificate.."
      wget --no-check-certificate -O "/tmp/osu-mime.tar.gz" "https://aur.archlinux.org/cgit/aur.git/snapshot/osu-mime.tar.gz" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"; fi
    
    tar -xf "/tmp/osu-mime.tar.gz" -C "/tmp"
    mkdir -p "$HOME/.local/share/mime"
    mkdir -p "$HOME/.local/share/mime/packages"
    cp "/tmp/osu-mime/osu-file-extensions.xml" "$HOME/.local/share/mime/packages/osuwinello-file-extensions.xml"
    update-mime-database "$HOME/.local/share/mime"
    rm -f "/tmp/osu-mime.tar.gz"
    rm -rf "/tmp/osu-mime"
    
    # Installing osu-handler from https://github.com/openglfreak/osu-handler-wine / https://aur.archlinux.org/packages/osu-handler
    # Binary was compiled from source on Ubuntu 18.04
    wget -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/NelloKudo/osu-winello/raw/main/stuff/osu-handler-wine" && wgetcheck4="$?"
    
    if [ ! "$wgetcheck4" = 0 ] ; then
      Info "wget failed; trying with --no-check-certificate.."
      wget --no-check-certificate -O "$HOME/.local/share/osuconfig/osu-handler-wine" "https://github.com/NelloKudo/osu-winello/raw/main/stuff/osu-handler-wine" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi
    
    chmod +x "$HOME/.local/share/osuconfig/osu-handler-wine"

    # Installing Winetricks from upstream
    wget -O "$HOME/.local/share/osuconfig/winetricks" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && wgetcheck41="$?"
    if [ ! "$wgetcheck41" = 0 ] ; then
      Info "wget failed; trying with --no-check-certificate.."
      wget --no-check-certificate -O "$HOME/.local/share/osuconfig/winetricks" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi
    
    chmod +x "$HOME/.local/share/osuconfig/winetricks"
    
    # Creating entries..
    echo "[Desktop Entry]
    Type=Application
    Name=osu!
    MimeType=application/x-osu-skin-archive;application/x-osu-replay;application/x-osu-beatmap-archive;
    Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %f
    NoDisplay=true
    StartupNotify=true
    Icon=/home/$USER/.local/share/icons/osu-wine.png" >> "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osuwinello-file-extensions-handler.desktop"

    echo "[Desktop Entry]
    Type=Application
    Name=osu!
    MimeType=x-scheme-handler/osu;
    Exec=/home/$USER/.local/share/osuconfig/osu-handler-wine %u
    NoDisplay=true
    StartupNotify=true
    Icon=/home/$USER/.local/share/icons/osu-wine.png" >> "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    chmod +x "$HOME/.local/share/applications/osuwinello-url-handler.desktop"
    update-desktop-database "$HOME/.local/share/applications"

    Info "Configuring Wineprefix:"
    mkdir -p "$HOME/.local/share/wineprefixes"
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
        if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
          rm -rf "$HOME/.local/share/wineprefixes/osu-wineprefix"
        
          Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
          manualprefix="false"

	        if [ ! -e "/tmp/WINE.win32.7z" ] ; then
            wget -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" && wgetcheckprefix="$?" ; fi

            if [ ! "$wgetcheckprefix" = 0 ] ; then
              Info "wget failed; trying with --no-check-certificate.."
              wget --no-check-certificate -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" || (Info "Download failed, maybe GitLab is down?")
        
          if [ ! -e "/tmp/WINE.win32.7z" ] ; then
            manualprefix="true" ; fi
          fi

          if [ "$manualprefix" = "false" ] ; then
            7z x -y -o/tmp/osu-wineprefix "/tmp/WINE.win32.7z"
            cp -r "/tmp/osu-wineprefix/.osuwine/" "$HOME/.local/share/wineprefixes/osu-wineprefix"
            rm -rf "/tmp/osu-wineprefix/" 
          else
            export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
            WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet48 gdiplus_winxp comctl32 win2k3 || Error "Winetricks failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi

          export WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix"

          # Time to remove all the bloat there lmao
          rm -rf "$WINEPREFIX/dosdevices"
          rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
          mkdir -p "$WINEPREFIX/dosdevices"
          ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
	        ln -s / "$WINEPREFIX/dosdevices/z:"
	
          export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"

          Info "Installing fonts..."
          # Using fonts from https://github.com/YourRandomGuy/ttf-ms-win10
          mkdir -p "/tmp/tempfonts"
          git clone "https://github.com/YourRandomGuy/ttf-ms-win10.git" "/tmp/tempfonts" || Error "Git failed, check your connection or open an issue at here: https://github.com/NelloKudo/osu-winello/issues"
          mkdir -p "$HOME/.local/share/fonts/W10Fonts"
          cp /tmp/tempfonts/*{.ttf,.ttc} "$HOME/.local/share/fonts/W10Fonts"
          rm -rf "/tmp/tempfonts"
          fc-cache -f "$HOME/.local/share/fonts/W10Fonts"

        #Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        (cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu") || (Info "Seems like the file wasn't found for some reason lol. Copying it from backup.." && cp "$HOME/.local/share/osuconfig/update/fixfolderosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu")
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""

        else
	        if [ ! -e "$HOME/.local/share/osuconfig/folderfixosu" ] ; then
	          (cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu") || (Info "Seems like the file wasn't found for some reason lol. Copying it from backup.." && cp "$HOME/.local/share/osuconfig/update/fixfolderosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu")
	        fi
		
          Info "Skipping..." ; fi
    
    else
        
        Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
        manualprefix="false"

	      if [ ! -e "/tmp/WINE.win32.7z" ] ; then
          wget -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" && wgetcheckprefix="$?" ; fi

          if [ ! "$wgetcheckprefix" = 0 ] ; then
            Info "wget failed; trying with --no-check-certificate.."
            wget --no-check-certificate -O "/tmp/WINE.win32.7z" "https://gitlab.com/NelloKudo/osu-winello-prefix/-/raw/master/osu-winello-prefix.7z" || (Info "Download failed, maybe GitLab is down?")
        
        if [ ! -e "/tmp/WINE.win32.7z" ] ; then
          manualprefix="true" ; fi
        fi

        if [ "$manualprefix" = "false" ] ; then
          7z x -y -o/tmp/osu-wineprefix "/tmp/WINE.win32.7z"
          cp -r "/tmp/osu-wineprefix/.osuwine/" "$HOME/.local/share/wineprefixes/osu-wineprefix"
          rm -rf "/tmp/osu-wineprefix/" 
        else
          export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
          WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet48 gdiplus_winxp comctl32 win2k3 || Error "Winetricks failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi

        export WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix"

        # Time to remove all the bloat there lmao
        rm -rf "$WINEPREFIX/dosdevices"
        rm -rf "$WINEPREFIX/drive_c/users/nellokudo"
        mkdir -p "$WINEPREFIX/dosdevices"
        ln -s "$WINEPREFIX/drive_c/" "$WINEPREFIX/dosdevices/c:"
	      ln -s / "$WINEPREFIX/dosdevices/z:"
	
        export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"

        Info "Installing fonts..."
        # Using fonts from https://github.com/YourRandomGuy/ttf-ms-win10
        mkdir -p "/tmp/tempfonts"
        git clone "https://github.com/YourRandomGuy/ttf-ms-win10.git" "/tmp/tempfonts" || Error "Git failed, check your connection or open an issue at here: https://github.com/NelloKudo/osu-winello/issues"
        mkdir -p "$HOME/.local/share/fonts/W10Fonts"
        cp /tmp/tempfonts/*{.ttf,.ttc} "$HOME/.local/share/fonts/W10Fonts"
        rm -rf "/tmp/tempfonts"
        fc-cache -f "$HOME/.local/share/fonts/W10Fonts"

        #Integrating native file explorer by Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
        (cp "./stuff/folderfixosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu") || (Info "Seems like the file wasn't found for some reason lol. Copying it from backup.." && cp "$HOME/.local/share/osuconfig/update/fixfolderosu" "$HOME/.local/share/osuconfig/folderfixosu" && chmod +x "$HOME/.local/share/osuconfig/folderfixosu")
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command"
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg delete "HKEY_CLASSES_ROOT\folder\shell\open\ddeexec" /f
        WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wine reg add "HKEY_CLASSES_ROOT\folder\shell\open\command" /f /ve /t REG_SZ /d "/home/$USER/.local/share/osuconfig/folderfixosu xdg-open \"%1\""
    fi

# Installing Winestreamproxy from https://github.com/openglfreak/winestreamproxy
    
    if [ ! -d "$HOME/.local/share/wineprefixes/osu-wineprefix/drive_c/winestreamproxy" ] ; then
      Info "Configuring Winestreamproxy (Discord RPC)"
      wget -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" && wgetcheck5="$?"
    
      if [ ! "$wgetcheck5" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" "https://github.com/openglfreak/winestreamproxy/releases/download/v2.0.3/winestreamproxy-2.0.3-amd64.tar.gz" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi  
    
      mkdir -p "/tmp/winestreamproxy"
      tar -xf "/tmp/winestreamproxy-2.0.3-amd64.tar.gz" -C "/tmp/winestreamproxy"
      (WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" wineserver -k && WINE="$HOME/.local/share/osuconfig/wine-osu/bin/wine" WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" bash "/tmp/winestreamproxy/install.sh") || Info "Installing Winestreamproxy failed, try to install it yourself later"
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
        wget --no-check-certificate -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues" ; fi  
    
      Info "Installation is completed! Run 'osu-wine' to play osu!"
      Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
    fi
}

Uninstall() 
{
    
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

Update()
{   
    if [ ! "$CURRENTGLIBC" \< "$MINGLIBC" ]; then
      LASTWINEVERSION=$(</"$HOME/.local/share/osuconfig/wineverupdate")
    
      if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
        wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" && wgetcheck7="$?"
    
        if [ ! "$wgetcheck7" = 0 ] ; then
          Info "wget failed; trying with --no-check-certificate.."
          wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" || Error "Download failed, check your connection or open an issue here: https://github.com/NelloKudo/osu-winello/issues"; fi
    
        tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/"
        rm -rf "$HOME/.local/share/osuconfig/wine-osu"
        mv "$HOME/.local/share/wine-osu" "$HOME/.local/share/osuconfig/"
        rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"
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

      if [ -d "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu" ] ; then
        read -r -p "$(Info "Do you want to update wine-osu in Flatpak Lutris too? (y/n)")" lutrupdate2
          if [ "$lutrupdate2" = 'y' ] || [ "$lutrupdate2" = 'Y' ]; then
            rm -rf "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu"
            cp -r "$HOME/.local/share/osuconfig/wine-osu" "$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine/wine-osu"
          else
            Info "Skipping...." ;fi
      fi
    
      Info "Update is completed!"
    
      else
        Info "Your wine-osu is already up-to-date!"
      fi

    else
      Info "Try updating your system.."
    fi

}

Basic()
{
    if [ "$USER" = "root" ] ; then Error "Please run the script without root" ; fi
    Info "This is the basic installer, it will only install basic features to get the game running.."
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

    Info "Checking for internet connection.."
    ! ping -c 1 1.1.1.1 >/dev/null 2>&1 && Error "Please connect to internet before continuing xd. Run the script again"

    Info "Dependencies time.."

    if command -v apt >/dev/null 2>&1 ; then
      if ! ( command -v apt >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1 ) ; then
        
        Info "Debian/Ubuntu detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "------------------------------------"
        Info "Installing packages and wine-staging dependencies.."

        "$root_var" apt update && "$root_var" apt upgrade -y
        "$root_var" dpkg --add-architecture i386
        wget -nc https://dl.winehq.org/wine-builds/winehq.key
        "$root_var" apt-key add winehq.key
        "$root_var" apt-add-repository -y 'https://dl.winehq.org/wine-builds/ubuntu/'
        "$root_var" apt update
        "$root_var" apt install -y --install-recommends winehq-staging || if command -v wine >/dev/null 2>&1 ; then Info "Wine stable seems to be found, removing it.." && "$root_var" apt purge -y wine && "$root_var" apt install -y --install-recommends winehq-staging ; fi || Error "Some libraries didn't install for some reason, check apt or your connection" 
        "$root_var" apt install -y winetricks git curl steam build-essential zstd p7zip zenity || Error "Some libraries didn't install for some reason, check apt or your connection"
        
        Info "Dependencies done, skipping.."
      
      fi
    fi

    osid=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
    if command -v pacman >/dev/null 2>&1 && [ "$osid" == "steamos" ]; then
        Info "SteamOS detected, installing dependencies..."
        Info "Please enter your password when asked"
        Info "Installing packages and wine-staging dependencies.."
        if command -v wine >/dev/null 2>&1 ; then
            Info "Wine (possibly) already found, removing it to replace with staging.."
            sudo pacman -Rdd --noconfirm wine || Info "Looks like staging is already installed"
            Info "Installing packages and wine-staging dependencies.."        
            sudo pacman -Sy libxcomposite lib32-libxcomposite gnutls lib32-gnutls wine-staging winetricks || Error "Check your connection or make sure you disabled read-only file system (read more at GitHub)"
        fi
    else
          Info "Arch Linux detected, installing dependencies..."
          Info "Please enter your password when asked"
          Info "------------------------------------"
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
    fi

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
	    
      Info "Seems like your distro is too old and well, not supported by this wine build.."
      Info "Do you want to use your system's Wine and continue the install? (assuming you have that)"
      read -r -p "$(Info "Choose your option (Y/N):")" winechoice
        
      if [ "$winechoice" = 'y' ] || [ "$winechoice" = 'Y' ]; then
        
        mkdir -p "$HOME/.local/share/osuconfig/wine-osu"
        ln -sf "/usr/bin" "$HOME/.local/share/osuconfig/wine-osu/bin" 
    
      else
    
        Error "Exiting.."
      
      fi
	   
    else

      # Checking which link to use to download wine-osu
      if wget --spider "$WINELINK" 2>/dev/null; then
        Info "Wine link is working, skipping.."
      else
        Info "Wine download link seems to be down; using backup.."
        WINELINK="$WINEBACKUPLINK"
      fi
      
      wget -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" && wgetcheck1="$?"
    
      if [ ! "$wgetcheck1" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" "$WINELINK" || Error "Download failed, check your connection" 
      fi

      tar -xf "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz" -C "$HOME/.local/share/"
      LASTWINEVERSION="$WINEVERSION"
    
      if [ -d "$HOME/.local/share/osuconfig" ]; then
        Info "Skipping osuconfig.."
      else
        mkdir "$HOME/.local/share/osuconfig"
      fi
    
      mv "$HOME/.local/share/wine-osu" "$HOME/.local/share/osuconfig"
      rm -f "/tmp/wine-osu-${WINEVERSION}-x86_64.pkg.tar.xz"
    
      Info "Installing script copy for updates.."
    
      mkdir -p "$HOME/.local/share/osuconfig/update"
      git clone https://github.com/NelloKudo/osu-winello.git "$HOME/.local/share/osuconfig/update" || Error "Git failed, check your connection.."
      echo "$LASTWINEVERSION" >> "$HOME/.local/share/osuconfig/wineverupdate"
    
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

    Info "Configuring Wineprefix:"
    mkdir -p "$HOME/.local/share/wineprefixes"
    
    if [ -d "$HOME/.local/share/wineprefixes/osu-wineprefix" ] ; then
        
        Info "Wineprefix already exists; do you want to reinstall it?"
        read -r -p "$(Info "Choose: (Y/N)")" prefchoice
          
          if [ "$prefchoice" = 'y' ] || [ "$prefchoice" = 'Y' ]; then
	
            Info "Downloading and configuring Wineprefix: (take a coffee and wait e.e)"
            export PATH="$HOME/.local/share/osuconfig/wine-osu/bin:$PATH"
	          WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/osu-wineprefix" "$HOME/.local/share/osuconfig/winetricks" -q -f dotnet40 
       
          else
        Info "Skipping..." ; fi

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
      
      wget -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" && wgetcheck6="$?"
    
        if [ ! "$wgetcheck6" = 0 ] ; then
          
          Info "wget failed; trying with --no-check-certificate.."
          wget --no-check-certificate -O "$OSUPATH/osu!.exe" "http://m1.ppy.sh/r/osu!install.exe" ; fi
    
      Info "Installation is completed! Run 'osu-wine' to play osu!"
      Info "WARNING: If 'osu-wine' doesn't work, just close and relaunch your terminal."
    fi

}

Help() 
{   

  Info "To install the game, run ./osu-winello.sh
        To uninstall the game, run ./osu-winello.sh uninstall
        To update the wine-osu version, run ./osu-winello.sh update"
    
}

case "$1" in

  'uninstall')	
	  Uninstall
  	exit 0
	;;
	
	'help')	
	  Help
	;;
	
	'update')	
	  Update
	;;
	
	'')				
	  Install
	;;
	
  'w10fonts')

    Info "Which way do you want to install fonts?
    1: GitHub (Faster, Small Download, Classic JP and KR fonts)
    2: Iso (5GBs, includes ALL fonts from W10 isos)"

    read -r -p "$(Info "Choose your option: ")" fontsch
    if [ "$fontsch" = 1 ] || [ "$fontsch" = 2 ] ; then  
    case "$installpath" in

    '1')
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
      wget -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" && wgetcheck8="$?" 
    
      if [ ! "$wgetcheck8" = 0 ] ; then
        Info "wget failed; trying with --no-check-certificate.."
        wget --no-check-certificate -O "$HOME/${_file}" "https://software-download.microsoft.com/download/pr/${_file}" || Error "Download keeps failing, check the code at line ~1000 or your connection" ; fi
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
    ;;

    '--basic')
      Basic
    ;;

	*)				
	  Info "Unknown argument, see ./osu-winello.sh help"
	;;

esac

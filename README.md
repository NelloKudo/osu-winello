# osu-winello
osu! installer for Linux with pre-packaged Wineprefix and patched wine-osu.

![HJuwGZG_840x480](https://user-images.githubusercontent.com/98063377/150559685-50bbfeb2-aecf-495f-86f6-cbd3f89f3b81.jpg)

# Installation

## Prerequisites 

This script is based on the [guide](https://osu.ppy.sh/community/forums/topics/1248084?n=1) I've written on the osu! website: more details, troubleshooting and tools can be found there.

### Packages:

<details>
  <summary> Debian (Ubuntu, Linux Mint, Pop!_OS etc..) </summary>
  <pre>sudo apt update && sudo apt upgrade && sudo apt install git curl build-essential zstd p7zip</pre>
</details>

<details>
  <summary> Arch Linux (Manjaro, Endeavour OS, etc.) </summary>
  <pre>sudo pacman -Syu git p7zip wget </pre>
</details>

<details>
  <summary> Fedora </summary>
  <pre>
  sudo dnf update
  sudo dnf install git zstd p7zip p7zip-plugins wget
  sudo dnf groupinstall "Development Tools" "Development Libraries"</pre>
</details>

### Wine and dependencies:

<details>
  <summary> Debian (Ubuntu, Linux Mint, Pop!_OS etc..) </summary>
  <pre>
  sudo dpkg --add-architecture i386
  wget -nc https://dl.winehq.org/wine-builds/winehq.key
  sudo apt-key add winehq.key
  sudo apt-add-repository 'https://dl.winehq.org/wine-builds/ubuntu/'
  sudo apt update
  sudo apt install --install-recommends winehq-staging
  sudo apt install winetricks
  </pre>
</details>

<details>
  <summary> Arch Linux (Manjaro, Endeavour OS, etc.) </summary>
  enable multilib first in /etc/pacman.conf
  <pre>
  sudo pacman -Sy
  sudo pacman -S wine-staging winetricks
  sudo pacman -S giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba dosbox
  </pre>
</details>

<details>
  <summary> Fedora </summary>
  <pre>
  sudo dnf install alsa-plugins-pulseaudio.i686 glibc-devel.i686 glibc-devel libgcc.i686 libX11-devel.i686 freetype-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXext-devel.i686 libXxf86vm-devel.i686 libXrandr-devel.i686 libXinerama-devel.i686 mesa-libGLU-devel.i686 mesa-libOSMesa-devel.i686 libXrender-devel.i686 libpcap-devel.i686 ncurses-devel.i686 libzip-devel.i686 lcms2-devel.i686 zlib-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686 cups-devel.i686 libxml2-devel.i686 openldap-devel.i686 libxslt-devel.i686 gnutls-devel.i686 libpng-devel.i686 flac-libs.i686 json-c.i686 libICE.i686 libSM.i686 libXtst.i686 libasyncns.i686 liberation-narrow-fonts.noarch libieee1284.i686 libogg.i686 libsndfile.i686 libuuid.i686 libva.i686 libvorbis.i686 libwayland-client.i686 libwayland-server.i686 llvm-libs.i686 mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 mesa-libgbm.i686 nss-mdns.i686 ocl-icd.i686 pulseaudio-libs.i686 sane-backends-libs.i686 tcp_wrappers-libs.i686 unixODBC.i686 samba-common-tools.x86_64 samba-libs.x86_64 samba-winbind.x86_64 samba-winbind-clients.x86_64 samba-winbind-modules.x86_64 mesa-libGL-devel.i686 fontconfig-devel.i686 libXcomposite-devel.i686 libtiff-devel.i686 openal-soft-devel.i686 mesa-libOpenCL-devel.i686 opencl-utils-devel.i686 alsa-lib-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 pulseaudio-libs-devel.i686 pulseaudio-libs-devel gtk3-devel.i686 libattr-devel.i686 libva-devel.i686 libexif-devel.i686 libexif.i686 glib2-devel.i686 mpg123-devel.i686 mpg123-devel.x86_64 libcom_err-devel.i686 libcom_err-devel.x86_64 libFAudio-devel.i686 libFAudio-devel.x86_64
  sudo dnf groupinstall "C Development Tools and Libraries"
  sudo dnf groupinstall "Development Tools"
  sudo dnf install wine
  </pre>
</details>

### Pipewire:

<details>
  <summary>Debian (Ubuntu, Linux Mint, Pop!_OS etc..) </summary>
  <pre>
  sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream
  sudo apt update
  sudo apt install pipewire
  sudo apt install libspa-0.2-bluetooth
  sudo apt install pipewire-audio-client-libraries
  systemctl --user daemon-reload
  systemctl --user --now disable pulseaudio.service pulseaudio.socket
  systemctl --user mask pulseaudio
  systemctl --user --now enable pipewire-media-session.service pipewire pipewire-pulse
  </pre>
</details>  

<details>
  <summary> Arch Linux (Manjaro, Endeavour OS, etc.) </summary>
  Remove PulseAudio:
  <pre>sudo pacman -Rdd pulseaudio</pre>
  And then install PipeWire:
  <pre>sudo pacman -S pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber</pre>
</details>

<details>
  <summary> Fedora </summary>
  Fedora's latest versions already ship with Pipewire ; you might want to check with this:
  <pre>
  sudo dnf install pulseaudio-utils
  pactl info
  </pre>
</details>

Rebooting your system is recommended e.e

## Installing osu!:
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
sudo ./osu-winello.sh
```

You can now launch osu! with:
```osu-wine```

## Flags:
**Installation script:** 
```
sudo ./osu-winello.sh # Installs the game
sudo ./osu-winello.sh uninstall # Uninstalls the game
sudo ./osu-winello.sh update" # Updates wine-osu version
sudo ./osu-winello.sh help # Shows the previous commands
```

**Game script:**
```
osu-wine: Runs osu!
osu-wine --winecfg # Runs winecfg on the osu! Wineprefix  
osu-wine --winetricks # Install packages on osu! Wineprefix
osu-wine --update # Updates wine-osu to latest version
```

And that's all. Have fun playing osu!

## Check the guide above for troubleshooting or extra tools!


#!/usr/bin/env bash

#   =======================================
#   Welcome to Winello!
#   The whole script is divided in different
#   functions to make it easier to read.
#   Feel free to contribute!
#   =======================================

# Wine-osu 当前版本用于更新
MAJOR=10
MINOR=15
PATCH=7
WINEVERSION=$MAJOR.$MINOR-$PATCH
LASTWINEVERSION=0

# Wine-osu 镜像
WINELINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-staging-${WINEVERSION}/wine-osu-winello-fonts-wow64-${WINEVERSION}-x86_64.tar.xz"
WINECACHYLINK="https://github.com/NelloKudo/WineBuilder/releases/download/wine-osu-cachyos-v10.0-3/wine-osu-cachy-winello-fonts-wow64-10.0-3-x86_64.tar.xz"

# 其他可供外部下载的版本
DISCRPCBRIDGEVERSION=1.2
GOSUMEMORYVERSION=1.3.9
TOSUVERSION=4.3.1
YAWLVERSION=0.8.2
MAPPINGTOOLSVERSION=1.12.27

# 其他下载链接
WINETRICKSLINK="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"                 # Winetricks 用于 --fixprefix
PREFIXLINK="https://github.com/NelloKudo/osu-winello/releases/download/winello-bins/osu-winello-prefix.tar.xz" # 默认 WINEPREFIX
OSUMIMELINK="https://github.com/NelloKudo/osu-winello/releases/download/winello-bins/osu-mime.tar.gz"          # osu-mime (文件关联)
YAWLLINK="https://github.com/whrvt/yawl/releases/download/v${YAWLVERSION}/yawl"                                # yawl (Steam运行时-Wine启动器)

OSUDOWNLOADURL="https://m1.ppy.sh/r/osu!install.exe"

DISCRPCLINK="https://github.com/EnderIce2/rpc-bridge/releases/download/v${DISCRPCBRIDGEVERSION}/bridge.zip"
GOSUMEMORYLINK="https://github.com/l3lackShark/gosumemory/releases/download/${GOSUMEMORYVERSION}/gosumemory_windows_amd64.zip"
TOSULINK="https://github.com/tosuapp/tosu/releases/download/v${TOSUVERSION}/tosu-windows-v${TOSUVERSION}.zip"
AKATSUKILINK="https://air_conditioning.akatsuki.gg/loader"
MAPPINGTOOLSLINK="https://github.com/OliBomby/Mapping_Tools/releases/download/v${MAPPINGTOOLSVERSION}/mapping_tools_installer_x64.exe"

# 仓库地址（我就不客气的换成我的fork了 ;) )
WINELLOGIT="https://github.com/DeminTiC/osu-winello_for_cn_fork.git"

# 根据用户选择返回镜像URL
get_mirror_url() {
    local url="$1"
    if [ "${USE_CDN:-0}" = "1" ] && [[ "$url" == *"github.com"* ]]; then
        # 使用 ghproxy.com 作为镜像前缀
        echo "https://cdn.gh-proxy.org/$url"
    else
        echo "$url"
    fi
}
# 剩下的注释我就不翻译了哈 ;）

# The directory osu-winello.sh is in
SCRDIR="$(realpath "$(dirname "$0")")"
# The full path to osu-winello.sh
SCRPATH="$(realpath "$0")"

# Exported global variables

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export BINDIR="${BINDIR:-$HOME/.local/bin}"

OSUPATH="${OSUPATH:-}" # Could either be exported from the osu-wine launcher, from the osuconfig/osupath, or empty at first install (will set up in installOrChangeDir)

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

# Make all paths visible to pressure-vessel
[ -z "${PRESSURE_VESSEL_FILESYSTEMS_RW}" ] && {
    _mountline="$(df -P "$SCRPATH" 2>/dev/null | tail -1)" && [ -n "${_mountline}" ] && _mainscript_mount="${_mountline##* }:"  # mountpoint to main script path
    _mountline="$(df -P "$LAUNCHERPATH" 2>/dev/null | tail -1)" && [ -n "${_mountline}" ] && _curdir_mount="${_mountline##* }:" # mountpoint to current directory
    _mountline="$(df -P "$XDG_DATA_HOME" 2>/dev/null | tail -1)" && [ -n "${_mountline}" ] && _home_mount="${_mountline##* }:"  # mountpoint to XDG_DATA_HOME
    PRESSURE_VESSEL_FILESYSTEMS_RW+="${_mainscript_mount:-}${_curdir_mount:-}${_home_mount:-}/mnt:/media:/run/media"
    [ -r "$XDG_DATA_HOME/osuconfig/osupath" ] && OSUPATH=$(</"$XDG_DATA_HOME/osuconfig/osupath") &&
        PRESSURE_VESSEL_FILESYSTEMS_RW+=":$(realpath "$OSUPATH"):$(realpath "$OSUPATH"/Songs 2>/dev/null)" # mountpoint to osu/songs directory
    export PRESSURE_VESSEL_FILESYSTEMS_RW="${PRESSURE_VESSEL_FILESYSTEMS_RW//\/:/:}"                       # clean any "just /" mounts, pressure-vessel doesn't like that
}

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

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
    echo -e '\033[1;31m'"回滚安装...:\033[0m"
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
    echo -e '\033[1;31m'"回滚成功,请再次尝试 ./osu-winello.sh\033[0m"
    exit 1
}

# Error function pointing at Revert(), but with an appropriate message
InstallError() {
    echo -e '\033[1;31m'"脚本执行失败:\033[0m $*"
    Revert
}

# Error function for other features besides install
Error() {
    echo -e '\033[1;31m'"脚本执行失败:\033[0m $*"
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
    wgetcommand='' # broken, use curl from now on
    return 1
}

DownloadFile() {
    local original_url="$1"
    local output="$2"
    local url
    url=$(get_mirror_url "$original_url")
    Info "下载 $original_url 到 $output (实际地址: $url)..."
    if [ -n "$wgetcommand" ] && command -v wget >/dev/null 2>&1; then
        _wget "$url" "$output" && return 0
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$url" -o "$output" && return 0
    fi
    Error "下载 $original_url 失败，请检查网络连接。"
    return 1
}

# detect the currently running shell by walking up the process tree
detectRunningShell() {
    local current_shell=""
    local ppid=$PPID
    local max_iterations=10
    local iteration=0
    
    while [ "$ppid" -gt 1 ] && [ $iteration -lt $max_iterations ]; do
        iteration=$((iteration + 1))
        
        if [ -f "/proc/$ppid/status" ]; then
            ppid=$(grep "^PPid:" /proc/$ppid/status | awk '{print $2}')
            
            if [ -f "/proc/$ppid/comm" ]; then
                local proc_name=$(cat /proc/$ppid/comm)
                
                case "$proc_name" in
                    bash|zsh|fish|ksh|mksh|dash|tcsh|csh) # i surely hope these are enough...
                        current_shell="$proc_name"
                        break
                        ;;
                esac
            fi
        else
            break
        fi
    done
    
    # fallback to $SHELL if detection failed
    if [ -z "$current_shell" ]; then
        current_shell=$(basename "$SHELL")
    fi
    
    echo "$current_shell"
}

# Function looking for basic stuff needed for installation
InitialSetup() {
    # Better to not run the script as root, right?
    if [ "$USER" = "root" ]; then InstallError "请不要使用sudo或者在root环境下运行该脚本"; fi

    # Checking for previous versions of osu-wine (mine or DiamondBurned's)
    if [ -e /usr/bin/osu-wine ]; then Quit "请在安装前卸载旧的 osu-wine (/usr/bin/osu-wine) !"; fi
    if [ -e "$BINDIR/osu-wine" ]; then Quit "请在安装前卸载 Winello (osu-wine --remove) !"; fi

    Info "欢迎使用该脚本! 以下步骤将帮助您快速部署运行 osu! 必备的环境！ 8)"

     # 询问下载镜像选择
    Info "选择下载源："
    Info "1) GitHub 直连 (默认，部分地区可能较慢)"
    Info "2) CDN 镜像 (使用 ghproxy.com 加速 GitHub 资源)"
    read -r -p "$(Info "请输入选择 [1/2]: ")" mirror_choice
    if [ "$mirror_choice" = "2" ]; then
        export USE_CDN=1
        Info "已启用 CDN 镜像 (GitHub 资源将通过 ghproxy.com 下载)。"
    else
        export USE_CDN=0
    fi

    # Checking if $BINDIR is in PATH:
    mkdir -p "$BINDIR"
    pathcheck=$(echo "$PATH" | grep -q "$BINDIR" && echo "y")

    # If $BINDIR is not in PATH:
    if [ "$pathcheck" != "y" ]; then
        current_shell=$(detectRunningShell)
        
    # 这里是面对不同shell添加路径的部分，暂不作翻译：
        case "$current_shell" in
            bash)
                touch -a "$HOME/.bashrc"
                echo "export PATH=$BINDIR:\$PATH" >>"$HOME/.bashrc"
                Info "Added $BINDIR to PATH in ~/.bashrc (restart shell or run: source ~/.bashrc)"
                ;;
            zsh)
                touch -a "$HOME/.zshrc"
                echo "export PATH=$BINDIR:\$PATH" >>"$HOME/.zshrc"
                Info "Added $BINDIR to PATH in ~/.zshrc (restart shell or run: source ~/.zshrc)"
                ;;
            fish)
                mkdir -p "$HOME/.config/fish" && touch -a "$HOME/.config/fish/config.fish"
                fish -c "fish_add_path $BINDIR/"
                Info "Added $BINDIR to PATH in fish config (restart shell)"
                ;;
            *)
                Warning "Could not detect shell ($current_shell). Please manually add $BINDIR to your PATH"
                ;;
        esac
    fi

    # Well, we do need internet ig...
    Info "检查您的网络连接中..."
    ! ping -c 2 114.114.114.114 >/dev/null 2>&1 && ! ping -c 2 www.bing.com >/dev/null 2>&1 && InstallError "互联网似乎因您而不同，请再次尝试运行该脚本吧！"

    # Looking for dependencies..
    deps=(pgrep realpath wget zenity unzip)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            InstallError "请在执行脚本前安装 $dep "
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
    Info "安装游戏脚本:"
    cp "${SCRDIR}/osu-wine" "$BINDIR/osu-wine" && chmod +x "$BINDIR/osu-wine"

    Info "安装图标:"
    mkdir -p "$XDG_DATA_HOME/icons"
    cp "${SCRDIR}/stuff/osu-wine.png" "$XDG_DATA_HOME/icons/osu-wine.png" && chmod 644 "$XDG_DATA_HOME/icons/osu-wine.png"

    Info "创建快捷方式:"
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
        Info "跳过 osuconfig.."
    else
        mkdir "$XDG_DATA_HOME/osuconfig"
    fi

    Info "安装 Wine-osu:"
    # Downloading Wine..
    DownloadFile "$WINELINK" "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" || InstallError "无法下载 wine-osu."

    # This will extract Wine-osu and set last version to the one downloaded
    tar -xf "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
    LASTWINEVERSION="$WINEVERSION"
    rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

    # Install and verify yawl ASAP, the wrapper mode does not download/install the runtime if no arguments are passed
    installYawl || Revert

    # The update function works under this folder: it compares variables from files stored in osuconfig
    # with latest values from GitHub and check whether to update or not
    Info "为脚本副本安装更新.."
    mkdir -p "$XDG_DATA_HOME/osuconfig/update"

    { git clone  "$XDG_DATA_HOME/osuconfig/update" || git clone "${WINELLOGIT}" "$XDG_DATA_HOME/osuconfig/update"; } ||
        InstallError "Git 失败，请检查您的网络连接.."

    git -C "$XDG_DATA_HOME/osuconfig/update" remote set-url origin "${WINELLOGIT}"

    echo "$LASTWINEVERSION" >>"$XDG_DATA_HOME/osuconfig/wineverupdate"
}

# Function configuring folders to install the game
InitialOsuInstall() {
    local installpath=1
    Info "您想将osu!安装在哪（或者选择已经安装过osu!stable的路径）?:
          1 - 默认路径 ($XDG_DATA_HOME/osu-wine)
          2 - 自定义路径"
    read -r -p "$(Info "输入您的选择: ")" installpath

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

    Info "配置 Wineprefix 中:"

    # Variable to check if download finished properly
    local failprefix="false"
    mkdir -p "$XDG_DATA_HOME/wineprefixes"
    if [ -r "$XDG_DATA_HOME/wineprefixes/osu-wineprefix/system.reg" ]; then
        Info "Wineprefix 已经存在，您想重装它吗?"
        Warning "高度推荐!!!除非你知道自己在做什么!!!"
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

    Info "配置并安装 osu!"
    InitialOsuInstall || Revert

    Info "安装完成! 在终端输入运行 'osu-wine' 即可游玩 osu!"
    Warning "如果 'osu-wine' 没有工作, 只需关闭并重新开启您的终端窗口即可."
    exit 0
}

#   =====================================
#   =====================================
#          POST-INSTALL FUNCTIONS
#   =====================================
#   =====================================

longPathsFix() {
    Info "为长歌名应用修复 (e.g. because of deeply nested osu! folder)..."

    # replace default wineprefix username with user's username
    sed -i -e "s|nellokudo|${USER}|g" "${WINEPREFIX}"/{userdef.reg,user.reg,system.reg}

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
            Error "找不到osu!路径!" && return 1
        }
    fi

    Info "为osu!路径保存一个副本..."

    PRESSURE_VESSEL_FILESYSTEMS_RW="$(realpath "$osupath"):$(realpath "$osupath"/Songs 2>/dev/null):${PRESSURE_VESSEL_FILESYSTEMS_RW}"
    export PRESSURE_VESSEL_FILESYSTEMS_RW

    local temp_winepath
    temp_winepath="$(waitWine winepath -w "$osupath")"
    [ -z "${temp_winepath}" ] && Error "无法从Wine路径中获取osu!路径... 请检查 $osupath/osu!.exe ?" && return 1

    echo -n "${temp_winepath}" >"$XDG_DATA_HOME/osuconfig/.osu-path-winepath"
    echo -n "${temp_winepath}osu!.exe" >"$XDG_DATA_HOME/osuconfig/.osu-exe-winepath"
    $okay
}

deleteFolder() {
    local folder="${1}"
    Info "您想移除之前的安装吗 ${folder}?"
    read -r -p "$(Info "请选择 (y/N): ")" dirchoice

    if [ "$dirchoice" = 'y' ] || [ "$dirchoice" = 'Y' ]; then
        read -r -p "$(Info "Are you sure? This will delete your osu! files! (y/N)")" dirchoice2
        if [ "$dirchoice2" = 'y' ] || [ "$dirchoice2" = 'Y' ]; then
            rm -rf "${folder}" || { Error "Couldn't remove folder!" && return 1; }
            return 0
        fi
    fi
    Info "跳过.."
    return 0
}

# Handle `osu-wine --changedir` and installation setup
installOrChangeDir() {
    local newdir="${1:-}"
    local lastdir="${OSUPATH:-}"
    if [ -z "${newdir}" ]; then
        Info "请选择您的osu!路径:"
        newdir="$(zenity --file-selection --directory)"
        [ ! -d "$newdir" ] && { Error "没有一个文件夹被选中, 请确保zenity已被安装.." && return 1; }
    fi

    [ ! -s "$newdir/osu!.exe" ] && newdir="$newdir/osu!" # Make it a subdirectory unless osu!.exe is already there
    if [ -s "$newdir/osu!.exe" ] || [ "$newdir" = "$lastdir" ]; then
        Info "已经存在完整的osu!..."
    else
        mkdir -p "$newdir"
        DownloadFile "${OSUDOWNLOADURL}" "$newdir/osu!.exe" || return 1

        [ -n "${lastdir}" ] && { deleteFolder "$lastdir" || return 1; }
    fi

    echo "${newdir}" >"$XDG_DATA_HOME/osuconfig/osupath" # Save it for later
    export OSUPATH="${newdir}"

    longPathsFix || return 1
    saveOsuWinepath || return 1
    Info "osu! 已被安装至 '$newdir'!"
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
        Info "检查您的网络连接中.." # The bundled prefix install already checks for internet, so no point checking again
        ! ping -c 2 1.1.1.1 >/dev/null 2>&1 && { Error "互联网似乎因您而不同，请再次尝试运行该脚本吧！" && return 1; }

        [ -d "${WINEPREFIX:?}" ] && rm -rf "${WINEPREFIX}"

        Info "D正在与winetricks下载并安装一个新的prefix. 这会花费一些时间，喝杯咖啡或做做其他事情吧."
        "$WINESERVER" -k
        PATH="${SCRDIR}/stuff:${PATH}" WINEDEBUG="fixme-winediag,${WINEDEBUG:-}" WINENTSYNC=0 WINEESYNC=0 WINEFSYNC=0 \
            "$WINETRICKS" -q nocrashdialog autostart_winedbg=disabled dotnet48 dotnet20 gdiplus_winxp meiryo dxvk win10 ||
            { Error "winetricks 严重失败!" && return 1; }
    }

    folderFixSetup || return 1
    discordRpc || return 1

    # save the osu winepath with the new folder, unless its a first-time install (need to install osu first)
    [ -z "${nowinepath}" ] && { saveOsuWinepath || return 1; }

    $okay
}

# Remember whether the user wants to overwrite their local files
askConfirmTimeout() {
    [ -z "${1:-}" ] && Info "缺少 ${FUNCNAME[0]} 的参数！？" && exit 1

    local rememberfile="${XDG_DATA_HOME}/osuconfig/rememberupdatechoice"
    touch "${rememberfile}"

    local lastchoice
    lastchoice="$(grep "${1}" "${rememberfile}" | grep -Eo '(y|n)' | tail -n 1)"

    if [ -n "$lastchoice" ] && [ "$lastchoice" = "n" ]; then
        Info "将不会更新 ${1}, 将从 ${rememberfile} 使用已保存的选择"
        Info "如果你改变主意了，请删除此文件."
        return 1
    elif [ -n "$lastchoice" ] && [ "$lastchoice" = "y" ]; then
        Info "将会更新 ${1}, 将从 ${rememberfile} 使用已保存的选择"
        Info "如果你改变主意了，请删除此文件."
        return 0
    fi

    local _timeout=${2:-7} # use a 7 second timeout unless manually specified
    echo -n "$(Info "选择: (Y/n) [${_timeout}s] ")"

    read -t "$_timeout" -r prefchoice

    if [[ "$prefchoice" =~ ^(n|N)(o|O)?$ ]]; then
        Info "好的, 将不会更新 ${1}, 将选择保存至 ${rememberfile}."
        echo "${1} n" >>"${rememberfile}"
        return 1
    fi
    Info "将会更新 ${1}, 将选择保存至${rememberfile}."
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
        Warning "没有找到更新源: $update_source"
        return 1
    fi

    if ! cp -f "$launcher" "$backup_path"; then
        Warning "无法在 $backup_path 中创建备份"
        return 1
    fi

    if ! cp -f "$update_source" "$launcher"; then
        Warning "为 $launcher 应用更新失败"
        Warning "尝试从备份中恢复..."

        if ! cp -f "$backup_path" "$launcher"; then
            Warning "恢复备份失败 - 系统可能处于不一致状态"
            Warning "需要手动恢复来自: $backup_path"
            return 1
        fi
        return 1
    fi

    if ! chmod --reference="$backup_path" "$launcher" 2>/dev/null; then
        chmod +x "$launcher" 2>/dev/null || {
            Warning "无法为 $launcher 设置可执行权限"
            return 1
        }
    fi
    $okay
}

installYawl() {
    Info "安装Yawl..."
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
        installYawl || Info "继续，但可能会有问题..."
    else
        local INSTALLED_YAWL_VERSION
        INSTALLED_YAWL_VERSION="$(env "YAWL_VERBS=version" "$WINE" 2>/dev/null)"
        if [[ "$INSTALLED_YAWL_VERSION" =~ 0\.5\.* ]]; then
            installYawl || Info "继续，但可能会有问题..."
        else
            Info "正在检查 yawl 更新.."
            YAWL_VERBS="update" "$WINE" "--version"
        fi
    fi

    # Reading the last version installed
    [ -r "$XDG_DATA_HOME/osuconfig/wineverupdate" ] && LASTWINEVERSION=$(</"$XDG_DATA_HOME/osuconfig/wineverupdate")

    if [ "$LASTWINEVERSION" \!= "$WINEVERSION" ]; then
        # Downloading Wine..
        DownloadFile "$WINELINK" "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" || return 1

        # This will extract Wine-osu and set last version to the one downloaded
        Info "更新 Wine-osu"...
        rm -rf "$XDG_DATA_HOME/osuconfig/wine-osu"
        tar -xf "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
        rm -f "/tmp/wine-osu-winello-fonts-wow64-$MAJOR.$MINOR-$PATCH-x86_64.tar.xz"

        echo "$WINEVERSION" >"$XDG_DATA_HOME/osuconfig/wineverupdate"
        Info "更新已完成!"
        waitWine wineboot -u
    else
        Info "你的 Wine-osu 已为最新版本!"
    fi

    mkdir -p "$XDG_DATA_HOME/osuconfig/configs" # make the configs directory and copy the example if it doesnt exist
    [ ! -r "$XDG_DATA_HOME/osuconfig/configs/example.cfg" ] && cp "${SCRDIR}/stuff/example.cfg" "$XDG_DATA_HOME/osuconfig/configs/example.cfg"

    # Will be required when updating from umu-launcher
    [ ! -r "$XDG_DATA_HOME/osuconfig/.osu-path-winepath" ] && { saveOsuWinepath || return 1; }

    [ -n "$NOLAUNCHERUPDATE" ] && Info "你的 osu-wine 启动器将不会被动" && $okay

    [ ! -x "${launcher_path}" ] && { Error "找不到 osu-wine 启动器的路径来更新它。请重新安装 osu-winello" && return 1; }

    if [ ! -w "${launcher_path}" ]; then
        Warning "注意：${launcher_path}不可写 - 无法更新 osu-wine 启动器"
        Warning "如果你想更新启动器，请尝试以适当的权限运行更新，"
        Warning "   或者将它移动到像 $BINDIR 这样的地方，然后从那里运行它。"
        return 0
    fi

    Info "正在更新启动器（${launcher_path}）..."
    if launcherUpdate "${launcher_path}"; then
        Info "启动器更新成功！"
        Info "备份已保存到：$XDG_DATA_HOME/osuconfig/osu-wine.bak"
    else
        Error "启动器更新失败" && return 1
    fi
    $okay
}

# Well, simple function to install the game (also implement in osu-wine --remove)
Uninstall() {
    Info "卸载 icons:"
    rm -f "$XDG_DATA_HOME/icons/osu-wine.png"

    Info "卸载 .desktop:"
    rm -f "$XDG_DATA_HOME/applications/osu-wine.desktop"

    Info "卸载游戏脚本、工具和文件夹修复:"
    rm -f "$BINDIR/osu-wine"
    rm -f "$BINDIR/folderfixosu"
    rm -f "$BINDIR/folderfixosu.vbs"
    rm -f "$XDG_DATA_HOME/mime/packages/osuwinello-file-extensions.xml"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-file-extensions-handler.desktop"
    rm -f "$XDG_DATA_HOME/applications/osuwinello-url-handler.desktop"

    Info "卸载 wine-osu:"
    rm -rf "$XDG_DATA_HOME/osuconfig/wine-osu"

    Info "卸载 yawl 和 Steam 运行时:"
    rm -rf "$XDG_DATA_HOME/yawl"

    read -r -p "$(Info "您想要卸载 Wineprefix 吗？ (y/N)")" wineprch

    if [ "$wineprch" = 'y' ] || [ "$wineprch" = 'Y' ]; then
        rm -rf "$XDG_DATA_HOME/wineprefixes/osu-wineprefix"
    else
        Info "跳过.."
    fi

    read -r -p "$(Info "您想要卸载游戏文件吗？ (y/N)")" choice

    if [ "$choice" = 'y' ] || [ "$choice" = 'Y' ]; then
        read -r -p "$(Info "你确定吗？这将删除你的文件！(y/N)")" choice2

        if [ "$choice2" = 'y' ] || [ "$choice2" = 'Y' ]; then
            Info "卸载游戏:"
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

    Info "卸载完成！"
    return 0
}

SetupReader() {
    local READER_NAME="${1}"
    Info "正在设置 $READER_NAME 包装器..."
    # get all the required paths first
    local READER_PATH
    local OSU_WINEDIR
    local OSU_WINEEXE
    READER_PATH="$(WINEDEBUG=-all "$WINE" winepath -w "$XDG_DATA_HOME/osuconfig/$READER_NAME/$READER_NAME.exe" 2>/dev/null)" || { Error "在预期位置没有找到 $READER_NAME..." && return 1; }
    { [ -r "$XDG_DATA_HOME/osuconfig/.osu-path-winepath" ] && read -r OSU_WINEDIR <<<"$(cat "$XDG_DATA_HOME/osuconfig/.osu-path-winepath")" &&
        [ -r "$XDG_DATA_HOME/osuconfig/.osu-exe-winepath" ] && read -r OSU_WINEEXE <<<"$(cat "$XDG_DATA_HOME/osuconfig/.osu-exe-winepath")"; } ||
        { Error "在尝试设置 $READER_NAME 之前，您需要先完整安装 osu-winello。
	（缺少 $XDG_DATA_HOME/osuconfig/.osu-path-winepath 或 .osu-exe-winepath） .)" && return 1; }

    # launcher batch file to open tosu/gosumemory together with osu in the container, and tries to stop hung gosumemory/tosu process when osu! exits (why does that happen!?)
    cat >"$OSUPATH/launch_with_memory.bat" <<EOF
@echo off
set NODE_SKIP_PLATFORM_CHECK=1
cd /d "$OSU_WINEDIR"
start "" osu!.exe %*
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

    Info "$READER_NAME 包装器已启用。请正常启动 osu! 以使用它！"
    return 0
}

# Simple function that downloads Gosumemory!
Gosumemory() {
    if [ ! -d "$XDG_DATA_HOME/osuconfig/gosumemory" ]; then
        Info "下载 gosumemory.."
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
        Info "下载 tosu.."
        mkdir -p "$XDG_DATA_HOME/osuconfig/tosu"
        DownloadFile "${TOSULINK}" "/tmp/tosu.zip" || return 1
        unzip -d "$XDG_DATA_HOME/osuconfig/tosu" -q "/tmp/tosu.zip"
        rm "/tmp/tosu.zip"
    fi
    SetupReader "tosu" || return 1
    $okay
}

# Installs Akatsuki patcher (https://akatsuki.gg/patcher)
akatsukiPatcher() {
    local AKATSUKI_PATH="$XDG_DATA_HOME/osuconfig/akatsukiPatcher"

    if ! grep -q 'dotnetdesktop6' "$WINEPREFIX/winetricks.log" 2>/dev/null; then
        Info "Akatsuki Patcher 需要 .NET 桌面运行时 6，可通过 winetricks 安装..."
        $WINETRICKS -q -f dotnetdesktop6
    fi

    if [ ! -d "$AKATSUKI_PATH" ]; then
        Info "下载 patcher.."
        mkdir -p "$AKATSUKI_PATH"
        wget --content-disposition -O "$AKATSUKI_PATH/akatsuki_patcher.exe" "$AKATSUKILINK"
    fi

    # Setup usual LaunchOsu settings
    export WINEDEBUG="+timestamp,+pid,+tid,+threadname,+debugstr,+loaddll,+winebrowser,+exec${WINEDEBUG:+,${WINEDEBUG}}"
    WINELLO_LOGS_PATH="${XDG_DATA_HOME}/osuconfig/winello.log"

    Info "正在打开 $AKATSUKI_PATH/akatsuki_patcher.exe .."
    Info "如果修补程序找不到 osu!，请点击定位 > 我的电脑 > D:，然后按打开并启动！"
    Info "运行日志位于 ${WINELLO_LOGS_PATH}。如果你在 GitHub 上提交问题或在 Discord 上寻求帮助，请附上此文件."
    "$WINE" "$AKATSUKI_PATH/akatsuki_patcher.exe" &>>"${WINELLO_LOGS_PATH}" || return 1
    return 0
}

# Installs osu! Mapping Tools (https://github.com/olibomby/mapping_tools)
mappingTools() {
    local MAPPINGTOOLSPATH="${WINEPREFIX}/drive_c/Program Files/Mapping Tools"
    local OSUPID

    export DOTNET_BUNDLE_EXTRACT_BASE_DIR="C:\\dotnet_tmp"
    export DOTNET_ROOT="C:\\Program Files\\dotnet"
    [ ! -d "${WINEPREFIX}/drive_c/dotnet_tmp" ] && mkdir -p "${WINEPREFIX}/drive_c/dotnet_tmp"
    [ ! -d "${WINEPREFIX}/drive_c/Program Files/dotnet" ] && mkdir -p "${WINEPREFIX}/drive_c/Program Files/dotnet"

    # Disable icu.dll to prevent issues
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};icu.dll=d"

    if [ ! -d "${MAPPINGTOOLSPATH}" ]; then
        if OSUPID="$(pgrep osu!.exe)"; then Quit "请在首次安装Mapping工具前关闭 osu！"; fi

        "$WINESERVER" -k

        Info "为Mapping工具设置注册表.."
        waitWine reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Avalon.Graphics" /v DisableHWAcceleration /t REG_DWORD /d 1 /f

        Info "正在下载Mapping工具，请确认安装程序提示.."
        DownloadFile "${MAPPINGTOOLSLINK}" /tmp/mapping_tools_installer_x64.exe

        waitWine /tmp/mapping_tools_installer_x64.exe
        rm /tmp/mapping_tools_installer_x64.exe
    fi

    if [ -x "$YAWL_INSTALL_PATH" ] && OSUPID="$(pgrep osu!.exe)"; then
        Info "启动 Mapping Tools.."
        YAWL_VERBS="enter=$OSUPID" "${WINE_INSTALL_PATH}/bin/wine" "$MAPPINGTOOLSPATH/"'Mapping Tools.exe'
    else
        Quit "请在启动 Mapping Tools 之前先启动 osu！"
    fi
}

# Installs rpc-bridge for Discord RPC (https://github.com/EnderIce2/rpc-bridge)
discordRpc() {
    Info "设置 Discord RPC integration..."
    if [ -f "${WINEPREFIX}/drive_c/windows/bridge.exe" ]; then
        Info "rpc-bridge (Discord RPC) 已经安装, 您想重装它吗?"
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
    longPathsFix || return 1
    # Integrating native file explorer (inspired by) Maot: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
    # This only involves regedit keys.
    Info "设置原生文件管理器集成..."

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

    # Associate .osu and .osb files with winebrowser
    waitWine reg add "HKEY_CLASSES_ROOT\\.osu" /f /ve /t REG_SZ /d "osu_winello_file"
    waitWine reg add "HKEY_CLASSES_ROOT\\.osb" /f /ve /t REG_SZ /d "osu_winello_file"

    waitWine reg add "HKEY_CLASSES_ROOT\\osu_winello_file" /f
    waitWine reg add "HKEY_CLASSES_ROOT\\osu_winello_file\\shell\\open\\command" /f
    if [ -z "${fallback:-}" ]; then
        waitWine reg add "HKEY_CLASSES_ROOT\\osu_winello_file\\shell\\open\\command" /f /ve /t REG_SZ /d "wscript.exe \"${VBS_WINPATH//\\/\\\\}\" \"%1\""
    else
        waitWine reg add "HKEY_CLASSES_ROOT\\osu_winello_file\\shell\\open\\command" /f /ve /t REG_SZ /d "${FALLBACK_PATH} xdg-open \"%1\""
    fi
    $okay
}

osuHandlerSetup() {
    Info "配置 osu-mime 和 osu-handler..."

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
    Info "设置文件（.osz/.osk）和网址关联..."

    # Adding the osu-handler.reg file to registry
    waitWine regedit /s "$XDG_DATA_HOME/osuconfig/update/stuff/osu-handler.reg"
    $okay
}

# Open files/links with osu-handler-wine
osuHandlerHandle() {
    local ARG="${*:-}" OSUPID
    local HANDLERRUN=("$XDG_DATA_HOME/osuconfig/update/stuff/osu-handler-wine")
    [ ! -x "${HANDLERRUN[0]}" ] && chmod +x "${HANDLERRUN[0]}"

    if [ -x "$YAWL_INSTALL_PATH" ] && OSUPID="$(pgrep osu!.exe)"; then
        HANDLERRUN=("env" "YAWL_VERBS=enter=$OSUPID" "$YAWL_INSTALL_PATH" "${HANDLERRUN[0]}")
        echo "尝试在正在运行的容器中为 osu! 打开 osu-handler-wine (PID=$OSUPID)" >&2
    else
        HANDLERRUN=("env" "${WINE}") # we don't actually need osu-handler if we're starting a new instance
        echo "尝试打开一个新的 osu! 实例来处理 ${ARG}" >&2
    fi

    case "$ARG" in
    osu://*)
        echo "正在尝试加载链接 ($ARG).." >&2
        exec "${HANDLERRUN[@]}" 'C:\\windows\\system32\\start.exe' "$ARG"
        ;;
    *.osr | *.osz | *.osk | *.osz2)
        local EXT="${ARG##*.}" FULLARGPATH FILEDIR
        FULLARGPATH="$(realpath "${ARG}")" || FULLARGPATH="${ARG}" # || for fallback if realpath failed

        # also, add the containing directory to the PRESSURE_VESSEL_FILESYSTEMS_RW, because it might be in some other location
        FILEDIR="$(realpath "$(dirname "${FULLARGPATH}")")"
        if [ -n "${FILEDIR}" ] && [ "${FILEDIR}" != "/" ]; then
            export PRESSURE_VESSEL_FILESYSTEMS_RW="${PRESSURE_VESSEL_FILESYSTEMS_RW}:${FILEDIR}"
        fi

        echo "正在尝试加载文件 ($FULLARGPATH).." >&2
        exec "${HANDLERRUN[@]}" 'C:\\windows\\system32\\start.exe' "/ProgIDOpen" "osustable.File.$EXT" "$FULLARGPATH"
        ;;
    esac
    # If we reached here, it must means osu-handler failed/none of the cases matched
    Error "不支持的 osu! 文件 ($ARG) !" >&2
    Error "请尝试运行 \"bash $SCRPATH fixosuhandler\" !" >&2
    return 1
}

installWinetricks() {
    if [ ! -x "$WINETRICKS" ]; then
        Info "安装 winetricks..."
        DownloadFile "$WINETRICKSLINK" "/tmp/winetricks" || return 1
        mv "/tmp/winetricks" "$XDG_DATA_HOME/osuconfig"
        chmod +x "$WINETRICKS"
        $okay
    fi
    return 0
}

FixUmu() {
    if [ ! -f "$BINDIR/osu-wine" ] || [ -z "${LAUNCHERPATH}" ]; then
        Error "看起来你还没有安装 osu-winello，所以你应该先运行 ./osu-winello.sh" && return 1
    fi
    Info "看起来你正在从 umu-launcher 版 osu-wine 更新，所以我们现在将尝试进行完整更新..."
    Info "当被要求更新 'osu-wine' 启动器时，请回答 '是'"

    Update "${LAUNCHERPATH}" || { Error "Updating failed... Please do a fresh install of osu-winello." && return 1; }
    $okay
}

FixYawl() {
    if [ ! -f "$BINDIR/osu-wine" ]; then
        Error "看起来你还没有安装 osu-winello，所以你应该先运行 ./osu-winello.sh" && return 1
    elif [ ! -f "$YAWL_INSTALL_PATH" ]; then
        Error "找不到 yawl，你应该先运行 ./osu-winello.sh." && return 1
    fi

    Info "修复 yawl..."
    YAWL_VERBS="update;verify;exec=/bin/true" "$YAWL_INSTALL_PATH" && chk=$?
    YAWL_VERBS="make_wrapper=winello;exec=$WINE_INSTALL_PATH/bin/wine;wineserver=$WINE_INSTALL_PATH/bin/wineserver" "$YAWL_INSTALL_PATH"
    if [ "${chk}" != 0 ]; then
        Error "那似乎没用……再试一次？" && return 1
    else
        Info "现在 yawl 应该可以用了."
    fi
    $okay
}

WineCachySetup() {
    # First time setup: yawl-winello-cachy
    if [ ! -d "$XDG_DATA_HOME/osuconfig/wine-osu-cachy-10.0" ]; then
        DownloadFile "$WINECACHYLINK" "/tmp/winecachy.tar.xz"
        tar -xf "/tmp/winecachy.tar.xz" -C "$XDG_DATA_HOME/osuconfig"
        rm -f "/tmp/winecachy.tar.xz"

        WINE_INSTALL_PATH="$XDG_DATA_HOME/osuconfig/wine-osu-cachy-10.0"
        YAWL_VERBS="make_wrapper=winello-cachy;exec=$WINE_INSTALL_PATH/bin/wine;wineserver=$WINE_INSTALL_PATH/bin/wineserver" "$YAWL_INSTALL_PATH"
    fi
}

# Help!
Help() {
    Info "要安装游戏，请运行 ./osu-winello.sh
            要卸载游戏，请运行 ./osu-winello.sh uninstall
            要重试安装 yawl 相关文件，请运行 ./osu-winello.sh fixyawl
            你可以在 README.md 或 https://github.com/NelloKudo/osu-winello 阅读更多信息"
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

'akatsukiPatcher')
    akatsukiPatcher || exit 1
    ;;

'mappingTools')
    mappingTools || exit 1
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

'winecachy-setup')
    WineCachySetup || exit 1
    ;;

# Also catch "fixosuhandler"
*osu*handler)
    osuHandlerSetup || exit 1
    ;;

'handle')
    # Should be called by the osu-handler desktop files (or osu-wine for backwards compatibility)
    osuHandlerHandle "${@:2}" || exit 1
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
    Info "未知参数: ${*}"
    Help
    ;;
esac

# Congrats for reading it all! Have fun playing osu!
# (and if you wanna improve the script, PRs are always open :3)

# osu-winello_for_cn——fork
此脚本由原版osu-winello修改而来，可实现加速下载，并且实现主要内容汉化。

针对本项目，您可以直接：
```
git clone https://github.com/DeminTiC/osu-winello_for_cn_fork.git
cd osu-winello_for_cn_fork
chmod +x ./osu-winello.sh
./osu-winello.sh
```
本人严格遵循GPL协议
以下内容翻译自osu-wine原项目

除此之外笔者还有关于这个脚本的草稿项目，感兴趣的话可以看看:)
https://github.com/DeminTiC/osu-winello_for_cn

# osu-winello
适用于 Linux 的 osu! stable 安装程序，带有打过补丁的 wine-osu 和其他功能。

![ezgif com-video-to-gif(1)](https://user-images.githubusercontent.com/98063377/224407211-70fa648c-b96f-442b-b5f5-eaf28a84670a.gif)

# 目录

- [安装](#安装)
    - [前提条件](#前提条件)
        - [驱动程序](#驱动程序)
        - [PipeWire](#pipewire)
    - [安装 osu!](#安装-osu)
- [功能特性](#功能特性)
- [自定义配置](#自定义配置)
- [性能优化](#性能优化)
- [故障排除](#故障排除)
- [命令行标志](#命令行标志)
- [Steam Deck 支持](#steam-deck-支持)
- [致谢](#致谢)

# 安装

## 前提条件

除了 **64位显卡驱动程序** 之外，唯一的依赖项是 `git`、`zenity`、`wget`、`unzip` 和 `xdg-desktop-portal-gtk`（用于游戏内链接）。

你可以这样轻松安装它们：

**Ubuntu/Debian：** `sudo apt install -y git wget unzip zenity xdg-desktop-portal-gtk`

**Arch Linux：** `sudo pacman -Syu --needed --noconfirm git wget unzip zenity xdg-desktop-portal-gtk`

**Fedora：** `sudo dnf install -y git wget unzip zenity xdg-desktop-portal-gtk`

**openSUSE：** `sudo zypper install -y git wget unzip zenity xdg-desktop-portal-gtk`

## 驱动程序：

这听起来可能很明显，但以**正确**的方式安装驱动程序对于获得整体良好的体验、避免性能不佳或其他问题是必要的。

请记住，osu! 需要 **64位显卡驱动程序** 才能正常运行，因此如果你遇到性能问题，很可能与此有关。

对于 NVIDIA 来说，这通常是类似 `nvidia-utils` 或 `nvidia-driver` 的包；对于 AMD/Intel 来说，则是 `libgl1-mesa-dri` 之类的包。

你可以在此处找到针对你的发行版的更多有用说明（仅需要 64 位）：
- [安装驱动程序](https://github.com/lutris/docs/blob/master/InstallingDrivers.md)

如果你仍然感到困惑，可以尝试使用包管理器安装 Steam。这将为你的发行版安装必要的驱动程序。

## PipeWire：

`PipeWire` **其实不是一个必需的依赖项，但强烈推荐使用，特别是配合此脚本时。**

使用以下命令检查你的系统上是否已安装：

```
LANG=C pactl info | grep "Server Name"
```

如果显示 `Server Name: PulseAudio (on Pipewire)`，那么就没问题了。

否则，请按照此处的说明进行安装：
- [安装 PipeWire](https://github.com/NelloKudo/osu-winello/wiki/Installing-PipeWire)

## 安装 osu!：
```
git clone https://github.com/NelloKudo/osu-winello.git
cd osu-winello
chmod +x ./osu-winello.sh
./osu-winello.sh
```

现在你可以使用以下命令启动 osu!：
```
osu-wine
```
### ⚠ **!! \o/ !!** ⚠ ：
- 你可能需要重新启动终端才能启动游戏。
- 使用 **-40/35ms** 全局偏移来弥补 Wine 的 quirks（如果使用音频兼容模式，则为 -25）。这些值适用于大多数设置，但你的情况可能有所不同。请留意打击误差计！

# 功能特性：
- 附带**可更新的打过补丁的** [wine-osu](https://github.com/NelloKudo/WineBuilder/releases) 二进制文件，包含最新的 osu! 补丁，可实现低延迟音频、更好的性能、Alt+Tab 行为、崩溃修复等。
- 使用 [yawl](https://github.com/whrvt/yawl) 在 Steam 运行时环境中运行 wine-osu，无需下载依赖项即可在每个系统上提供出色的性能。
- 提供 [osu-handler](https://aur.archlinux.org/packages/osu-handler) 用于导入谱面和皮肤、通过 [rpc-bridge](https://github.com/EnderIce2/rpc-bridge) 实现 Discord RPC，并支持原生文件管理器！
- 支持最新的 [tosu](https://github.com/KotRikD/tosu) 和旧版 [gosumemory](https://github.com/l3lackShark/gosumemory) 用于直播等场景，并可自动安装！（查看[命令行标志](#命令行标志)！）
- 将 osu! 安装到默认或自定义路径（通过 zenity GUI），也适用于已存在的来自 Windows 的 osu! 安装！
- 得益于 [我的 osu-wineprefix 分支](https://gitlab.com/NelloKudo/osu-winello-prefix)（原项目：[osu-wineprefix](https://gitlab.com/osu-wine/osu-wineprefix)），省去了下载 Wineprefix 的麻烦。
- 支持在 Wine 中预装 Windows 字体（日文字体、特殊字符等）。

如需更清晰地了解脚本所做的所有事情，DeepWiki 做了很好的总结。请查看：
- [deepwiki/osu-winello](https://deepwiki.com/NelloKudo/osu-winello)

# 自定义配置

Winello 允许你使用位于以下目录中的 `.cfg` 文件设置启动参数或自定义环境变量：

```
~/.local/share/osuconfig/configs
```

其中提供了一个 `example.cfg` 文件，其中包含所有支持的环境变量及使用说明。

### 示例
要将 `mangohud` 添加到启动参数中，请编辑配置文件：

```sh
nano ~/.local/share/osuconfig/configs/example.cfg
# 或者直接运行：osu-wine --edit-config
```

在文件中，取消注释现有的 `# PRE_LAUNCH_ARGS=""` 行（删除 #），或添加一个新行，如下所示：

```sh
PRE_LAUNCH_ARGS="mangohud"
```

如果你想始终在自定义服务器上运行，只需类似地编辑 `POST_LAUNCH_ARGS`。同一文件中提供了一个示例。

# 性能优化

由于发行版和设置千差万别，请遵循以下指南来优化你的 osu! 性能：
- [性能优化：osu! 性能](https://github.com/NelloKudo/osu-winello/wiki/Optimizing:-osu!-performance)

# 故障排除

有关任何类型的故障排除，请参考 [osu-winello 的 Wiki](https://github.com/NelloKudo/osu-winello/wiki)。

如果这没有帮助，可以：
- 加入 [ThePooN 的 Discord 服务器](https://discord.gg/bc4qaYjqyT)并在 #osu-linux 频道提问，他们会知道如何帮助！<3
- 在 Discord 上给我发消息（marshnello）

# 命令行标志：
**安装脚本：**
```
./osu-winello.sh: 安装游戏
./osu-winello.sh --no-deps: 安装游戏但跳过安装依赖项
./osu-winello.sh uninstall: 卸载游戏
./osu-winello.sh fix-yawl: 尝试修复 yawl 问题（部分下载、损坏等）
```

**游戏脚本：**

```
osu-wine: 运行 osu!
osu-wine --help: 显示此帮助信息
osu-wine --info: 故障排除和更多信息
osu-wine --edit-config: 打开你的配置文件以编辑启动参数和其他自定义设置
osu-wine --winecfg : 在 osu! Wineprefix 上运行 winecfg
osu-wine --winetricks: 在 osu! Wineprefix 上安装软件包
osu-wine --regedit: 在 osu! Wineprefix 上打开注册表编辑器
osu-wine --wine <参数>: 像运行普通 wine 一样运行 wine + 你的参数
osu-wine --kill: 杀死 osu! Wineprefix 中的 osu! 及相关进程
osu-wine --kill9: 使用 wineserver -k9 杀死 osu!
osu-wine --update: 将 wine-osu 更新到最新版本
osu-wine --fixprefix: 从系统重新安装 osu! Wineprefix
osu-wine --fixfolders: 重新配置 osu-handler 和原生文件集成（如果 osu!direct/.osz/.osk/从游戏内打开文件夹功能损坏，请运行此项）
osu-wine --fix-yawl: 在出现问题时重新安装与 yawl 和 Steam 运行时相关的文件
osu-wine --fixrpc: 如果需要，重新安装 rpc-bridge！
osu-wine --remove: 卸载 osu! 和此脚本
osu-wine --changedir: 根据用户输入更改安装目录
osu-wine --devserver <地址>: 使用替代服务器运行 osu（例如 --devserver akatsuki.gg）
osu-wine --runinprefix <文件>: 在 osu! 的 Wineprefix 内启动自定义可执行文件
osu-wine --osuhandler <谱面, 皮肤...>: 使用指定的文件/链接启动 osu-handler-wine
osu-wine --gosumemory: 安装并运行 gosumemory，无需任何配置！
osu-wine --tosu: 安装并运行 tosu，无需任何配置！
osu-wine --disable-memory-reader: 关闭 gosumemory 和 tosu
osu-wine --akatsuki: 安装并运行 Akatsuki 补丁工具
osu-wine --mappingtools: 安装并运行 osu! 作图工具（实验性，建议使用 WINE_USE_CACHY=true）
```

注意：任何命令都可以加上前缀字母 'n' 以避免在运行时更新。

例如：`osu-wine n --fixprefix` 将运行 `--fixprefix` 而不会用 osu-winello git 仓库中的任何文件覆盖你的文件。

# Steam Deck 支持

由于 osu! 在 Steam Linux 运行时（与 Proton 相同）中的 Wine 上运行，你应该也能在 Steam Deck 上玩！

建议不要在 Steam Deck 上手动安装 PipeWire，因为它默认已安装，尝试安装可能会导致音频问题。

# 致谢

特别感谢：

- [whrvt 又名 spectator](https://github.com/whrvt/wine-osu-patches) 在 Wine、Proton 及相关方面的帮助，总能解决任何问题 :')
- [ThePooN 的 Discord 服务器](https://discord.gg/bc4qaYjqyT) 从早期阶段就支持 Winello！
- [gonX 的 wine-osu](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
- [Maot 的原生文件管理器集成方案](https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2)
- [KatouMegumi 的指南](https://wiki.archlinux.org/title/User:Katoumegumi#osu!_(stable)_on_Arch_Linux)
- [hwsnemo 的 wine-osu](https://software.opensuse.org//download.html?project=home%3Ahwsnemo%3Apackaged-wine-osu&package=wine-osu)
- [diamondburned 的 osu-wine](https://gitlab.com/osu-wine/osu-wine)
- [openglfreak 的软件包](https://github.com/openglfreak)
- [EnderIce2 的 rpc-bridge](https://github.com/EnderIce2/rpc-bridge)
- 最后但同样重要的是，每一位贡献者。感谢你们让 Winello 变得更好！

以上就是全部内容。祝玩 osu! 愉快！

## 如需故障排除或使用额外工具，请查看上面的指南！

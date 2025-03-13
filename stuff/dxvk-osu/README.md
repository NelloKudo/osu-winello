## dxvk-osu

Temporary folder containing patched dxvk binaries from [proton-osu-9-16](https://github.com/whrvt/umubuilder/releases/tag/proton-osu-9-16), since upstream dxvk has a regression where osu! stays black when launched.

x64 files are from: `proton-osu/files/lib64/wine/dxvk`
x32 files are from: `proton-osu/files/lib/wine/dxvk`

The folder also contains a patch reverting the commit causing the issue, if anyone wants to build their dxvk themselves.

osu-winello installs this files in `InstallDxvk()`
#!/usr/bin/env bash
# HarnessOS — archiso profile definition

iso_name="harnessOS"
iso_label="HARNESS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="HarnessOS Project <https://github.com/Codigo-Free/HarnessOS>"
iso_application="HarnessOS — AI-Powered Development Environment"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
    ["/etc/sudoers.d/wheel"]="0:0:440"
    ["/root/customize_airootfs.sh"]="0:0:755"
    ["/usr/local/bin/harness-install"]="0:0:755"
    ["/usr/local/bin/harness-detect-gpu"]="0:0:755"
    ["/usr/local/bin/harness-welcome"]="0:0:755"
    ["/usr/local/bin/harness-online-setup"]="0:0:755"
    ["/usr/local/bin/harness-power"]="0:0:755"
    ["/usr/local/lib/harness/detect.sh"]="0:0:755"
)

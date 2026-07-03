#!/usr/bin/env bash
# HarnessOS — Sync the running (installed) system with this repo.
#
# Copies the system-level pieces that normally only arrive via a fresh
# ISO install: the harness-* CLI toolkit, branding, and the online-setup
# systemd unit. Run it after pulling repo changes to keep an installed
# SSD system identical to the repo:
#
#   sudo ./scripts/sync-system.sh
#
# User-level dotfiles are NOT touched (use scripts/deploy-dotfiles.sh /
# stow for those) so your personal ~/.config tweaks survive.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIROOTFS="${REPO}/archiso/airootfs"

if [[ ${EUID} -ne 0 ]]; then
    echo "Run as root:  sudo $0" >&2
    exit 1
fi

echo ">>> Syncing harness-* CLI toolkit → /usr/local/bin"
install -m755 "${AIROOTFS}"/usr/local/bin/harness* /usr/local/bin/

# lib (installer copy) and share (easter egg, profiles) live outside bin
for name in lib share; do
    src="${AIROOTFS}/usr/local/${name}/harness"
    [[ -d "${src}" ]] || continue
    echo ">>> Syncing ${src#${AIROOTFS}}"
    mkdir -p "/usr/local/${name}/harness"
    cp -r "${src}/." "/usr/local/${name}/harness/"
done

echo ">>> Syncing branding → /usr/share/harness"
if [[ -d "${AIROOTFS}/usr/share/harness" ]]; then
    mkdir -p /usr/share/harness
    cp -r "${AIROOTFS}"/usr/share/harness/. /usr/share/harness/
fi

# harness-online-setup: live ISO enables it via customize_airootfs.sh and
# the installer now deploys it, but systems installed before that fix
# don't have it at all. Its ConditionPathExists done-file guards re-runs.
echo ">>> Syncing harness-online-setup.service"
install -m644 "${AIROOTFS}/etc/systemd/system/harness-online-setup.service" \
    /etc/systemd/system/harness-online-setup.service
systemctl daemon-reload
systemctl enable harness-online-setup.service

echo ">>> Done. System files now match the repo."
echo "    Dotfiles are separate: see scripts/deploy-dotfiles.sh (stow)."

# Known Issues

Postmortems for installer/build bugs that caused real broken installs, kept here so fixes don't get lost and the failure mode is recognizable next time.

## 2026-06-26 — Failed install left unbootable SSD: kernel/loader written outside the ESP, empty fstab

### Symptom
Fresh install via the TUI installer to `/dev/sda` produced a system that wouldn't boot:
- `/boot/EFI/systemd/systemd-bootx64.efi` and `/boot/EFI/BOOT/BOOTX64.EFI` existed on the real ESP (`/dev/sda1`) — `bootctl install` had run successfully at some point.
- `/boot/loader/entries/` on the real ESP was **empty**. `loader.conf`, `harnessOS.conf`, `vmlinuz-linux-zen` and `initramfs-linux-zen.img` were instead sitting on the BTRFS root subvolume (`@`) at the same logical path `/boot`, because at the time those files were written the ESP partition was not mounted over `/boot` — so the writes landed on the underlying filesystem instead of failing loudly.
- `/etc/fstab` on the installed system was essentially empty (header comments only) — no entries for `/`, `/home`, `/var`, `/var/log`, `/boot`, or `/swap`.
- `pacstrap` had failed partway through (~173/300+ packages, per prior session notes) with **no error log surviving** — `harness_installer/core/chroot.py` writes its log to `/var/log/harness-install.log`, which is an absolute path on the *live* session, not under the target `$mountpoint`. That log lives in the live ISO's RAM-backed overlay and is gone on reboot.

### Root cause
Two distinct problems compounded:

1. **No state validation between install steps.** `progress.py` runs disk/pacstrap/bootloader/fstab steps in a single `try` with no per-step verification (e.g. nothing confirms `/mnt/boot` is actually a mounted vfat filesystem before `bootloader.install_bootloader()` writes to it). When `pacstrap` failed, the installer aborted (`except Exception` just logs and stops — see `progress.py:175-180`), so steps 9 (`install_bootloader`) and 13 (`generate_fstab`) never should have run automatically. The presence of (partially) bootloader files on disk means a manual recovery attempt was made afterward — almost certainly from a fresh live-USB chroot session where `/mnt/boot` (the ESP) was never re-mounted before re-running `bootctl install` / writing loader entries. `bootctl --path=/boot install` and `Path.write_text()` calls in `bootloader.py` have no check that `/boot` under the mountpoint is actually the ESP and not just a directory on root.
2. **Install log isn't persisted to the target disk.** `chroot.py:35` (`LOG_FILE = "/var/log/harness-install.log"`) and `disk.py:53-58` (`_log_to_file` → `/tmp/harness-install.log`) both write to the *live* environment, not `$mountpoint/var/log/`. A failure during install — exactly the scenario that needs the log most — loses it on reboot.

### Fix applied to this specific disk (not the installer)
Manually repaired via live-USB chroot: mounted the real ESP at `/mnt/boot`, copied kernel/initrd/loader.conf/entries onto it, confirmed `bootctl status` resolves the `HarnessOS` entry, remounted all subvolumes (`@home`, `@var_log`, `@swap`), regenerated `/etc/fstab` with `genfstab -U`, filtering out the live ISO's own `/dev/loop0` squashfs mount (genfstab picks up *whatever* is mounted under the target at call time, including bind-mounted live-environment paths if `/run` etc. were rbind-mounted for the chroot — worth remembering for any future manual recovery too).

### Recommended installer hardening (not yet implemented)
1. **Validate `/mnt/boot` is a real mountpoint before writing to it.** In `bootloader.py:install_bootloader()`, check `findmnt $mountpoint/boot` (or equivalent) resolves to the EFI partition before calling `bootctl install` or writing `loader.conf`/entries. Raise a clear error instead of silently writing to the underlying btrfs subvolume.
2. **Add a post-install verification step** before reporting success in `progress.py`: confirm `bootctl status` (chrooted) reports the `HarnessOS` entry sourced from the ESP, confirm `$mountpoint/etc/fstab` has non-empty, non-comment-only content with entries for `/`, `/home`, `/var`, `/boot`, `/var/log`.
3. **Write install logs under `$mountpoint`**, e.g. `$mountpoint/var/log/harness-install.log`, so a failed install's log survives on the target disk even if the live session is lost. Optionally also keep the live-session copy for convenience, but the on-disk copy is the one that matters for postmortems.
4. **Surface the failed package name explicitly.** `pacstrap` failing at package N of M should be parsed from stderr (or `pacman -Qq | wc -l` on the target diffed against expected) and stated plainly in the error message — "sin log de error" was the actual blocker the first time around.
5. **Document the manual-recovery checklist** for future live-USB chroot sessions (this file's section above can serve as the basis): always re-mount `@home`, `@var`, `@var_log`, `@swap`, and the ESP before running `bootctl`/`genfstab`/anything chroot-dependent — none of it persists across live-session reboots.

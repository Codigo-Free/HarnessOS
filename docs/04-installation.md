# Installing HarnessOS

## Prerequisites

- UEFI-capable machine (BIOS Legacy/CSM not supported)
- 40 GB disk space minimum (80 GB recommended)
- 4 GB RAM minimum (8 GB recommended)
- Internet connection (required to install NVIDIA drivers and online tools)

## Running the installer

Boot from the live USB and run:

```bash
harness-install
```

## Installer screens

### 1. Welcome
Shows detected hardware: CPU model, RAM, GPU vendor. Confirms you're running on supported hardware.

### 2. Disk Setup
Lists all available disks. Select the target disk. The installer uses a fixed BTRFS layout — no manual partitioning required.

**Partition layout:**
| Partition | Size | Filesystem | Purpose |
|-----------|------|-----------|---------|
| p1 | 512 MB | FAT32 | EFI System Partition |
| p2 | Remaining | BTRFS | System + data |

**BTRFS subvolumes:**
| Subvolume | Mount | Options |
|-----------|-------|---------|
| `@` | `/` | `noatime,compress=zstd:1,space_cache=v2` |
| `@home` | `/home` | `noatime,compress=zstd:1,space_cache=v2` |
| `@var` | `/var` | `noatime,compress=zstd:1,space_cache=v2` |
| `@var_log` | `/var/log` | `noatime,compress=zstd:1,space_cache=v2` |
| `@snapshots` | `/.snapshots` | Snapper snapshot storage |
| `@swap` | `/swap` | NoCoW (`chattr +C`) — required for swapfile on BTRFS |

### 3. User Setup
- Hostname
- Username and password
- Timezone (auto-detected by IP)
- Locale

### 4. GPU Setup
The installer auto-detects your GPU vendor.

| GPU | Driver installed |
|-----|-----------------|
| NVIDIA | `nvidia-dkms` + CUDA toolkit |
| AMD | `mesa` + `vulkan-radeon` |
| Intel | `mesa` + `vulkan-intel` |

For NVIDIA, `nvidia-dkms` is used instead of `nvidia` because HarnessOS uses the linux-zen kernel, which requires DKMS drivers.

### 5. Software Profile
Choose what to install:
- **Full AI Stack** (default): Claude CLI, Ollama, GitHub Copilot
- **CUDA/ROCm**: GPU compute libraries
- **Extra Languages**: Additional language runtimes

### 6. Confirm
Review all choices. **This is the last step before disk writes begin.** Cancelling here leaves your disk untouched.

### 7. Progress
Real-time log of `pacstrap`, chroot configuration, bootloader install, and dotfiles deployment.

## Post-installation

After reboot into the installed system:

1. Connect to the internet — `harness-online-setup` will run automatically and install Claude CLI, pnpm, TypeScript tools.
2. Authenticate Claude: `claude` — follow the login prompt.
3. Pull an Ollama model: `ollama pull llama3.2`
4. Open VS Code: `code .`

## Bootloader

HarnessOS installs **systemd-boot** as the bootloader. Entries are at `/boot/loader/entries/`. The default timeout is 4 seconds.

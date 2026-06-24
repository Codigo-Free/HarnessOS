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

```bash
# 1. Run the setup wizard (handles auth, models, and verification)
harness setup

# 2. Verify everything is working
harness doctor

# 3. Start coding
harness ai          # Ask the AI about your system
claude              # Pair programming with Claude
code .              # Open VS Code
```

`harness setup` will:
- Authenticate GitHub CLI if not already logged in
- Install Claude CLI if missing (requires internet)
- Prompt to pull `llama3.2` model for Ollama if no model is found

`harness doctor` checks: GPU driver, Docker, Ollama, Claude CLI, Git, Node.js, pnpm, Python, Docker Compose — and prints fix hints for anything missing.

### Installing developer profiles

After setup, install additional tool profiles as needed:

```bash
sudo harness install web      # pnpm, Bun, TypeScript, Vercel, Next.js, Tailwind
sudo harness install ml       # CUDA, PyTorch, Jupyter, pandas, transformers
sudo harness install devops   # Terraform, Ansible, Helm, kubectx, AWS CLI
sudo harness install security # nmap, wireshark, hashcat, sqlmap
```

## Bootloader

HarnessOS installs **systemd-boot** as the bootloader. Entries are at `/boot/loader/entries/`. The default timeout is 4 seconds.

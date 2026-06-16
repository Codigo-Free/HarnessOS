"""HarnessOS — GPU detection and driver installation"""
import subprocess
import json
from pathlib import Path


NVIDIA_PACKAGES = [
    "nvidia-dkms",         # DKMS — works with linux-zen (NOT nvidia which only targets mainline)
    "nvidia-utils",
    "nvidia-settings",
    "libvdpau",
    "libxnvctrl",
]

CUDA_PACKAGES = [
    "cuda",
    "cudnn",
    "nvidia-container-toolkit",
]

AMD_PACKAGES = [
    "mesa",
    "vulkan-radeon",
    "libva-mesa-driver",
    "xf86-video-amdgpu",
]


def detect_gpu_vendor() -> str:
    try:
        result = subprocess.run(["lspci"], capture_output=True, text=True, check=True)
        output = result.stdout.lower()
        if "nvidia" in output:
            return "nvidia"
        if "amd" in output or "radeon" in output:
            return "amd"
        return "intel"
    except (subprocess.SubprocessError, FileNotFoundError):
        return "unknown"


def detect_nvidia_model() -> str:
    try:
        result = subprocess.run(["lspci"], capture_output=True, text=True, check=True)
        for line in result.stdout.splitlines():
            if "nvidia" in line.lower() and any(k in line.lower() for k in ["vga", "3d", "display"]):
                if "[" in line and "]" in line:
                    return line[line.index("[") + 1: line.index("]")]
                return line.split(":")[-1].strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return "Unknown NVIDIA GPU"


def get_recommended_driver() -> str:
    model = detect_nvidia_model().lower()
    if any(k in model for k in ["rtx 40", "rtx 30", "rtx 20", "gtx 16", "gtx 10"]):
        return "nvidia-dkms"
    return "nvidia-470xx-dkms"


def install_nvidia_drivers(mountpoint: str, install_cuda: bool = True) -> None:
    packages = list(NVIDIA_PACKAGES)
    if install_cuda:
        packages.extend(CUDA_PACKAGES)

    subprocess.run(
        ["pacstrap", "-K", mountpoint] + packages,
        check=True,
    )

    # Add NVIDIA modules to mkinitcpio
    mkinitcpio = Path(mountpoint) / "etc" / "mkinitcpio.conf"
    if mkinitcpio.exists():
        content = mkinitcpio.read_text()
        if "MODULES=()" in content:
            content = content.replace(
                "MODULES=()",
                "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)",
            )
            mkinitcpio.write_text(content)

    # Configure Docker to use NVIDIA runtime
    docker_conf_dir = Path(mountpoint) / "etc" / "docker"
    docker_conf_dir.mkdir(parents=True, exist_ok=True)
    daemon_json = docker_conf_dir / "daemon.json"
    config = {
        "default-runtime": "nvidia",
        "runtimes": {
            "nvidia": {
                "path": "nvidia-container-runtime",
                "runtimeArgs": [],
            }
        },
    }
    daemon_json.write_text(json.dumps(config, indent=2))

    # Write NVIDIA env vars for Hyprland
    nvidia_env = Path(mountpoint) / "etc" / "profile.d" / "harness-nvidia.sh"
    nvidia_env.write_text(
        "#!/usr/bin/env bash\n"
        "# HarnessOS — NVIDIA Wayland environment\n"
        "export LIBVA_DRIVER_NAME=nvidia\n"
        "export GBM_BACKEND=nvidia-drm\n"
        "export __GLX_VENDOR_LIBRARY_NAME=nvidia\n"
        "export WLR_NO_HARDWARE_CURSORS=1\n"
        "export NVD_BACKEND=direct\n"
    )


def install_amd_drivers(mountpoint: str) -> None:
    subprocess.run(
        ["pacstrap", "-K", mountpoint] + AMD_PACKAGES,
        check=True,
    )

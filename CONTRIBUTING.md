# Contributing to HarnessOS

## Quick Setup

```bash
git clone https://github.com/Codigo-Free/HarnessOS.git
cd HarnessOS
```

## Adding Packages

Edit `archiso/packages.x86_64` — one package per line, grouped by section.

## Modifying Dotfiles

All dotfiles live in `dotfiles/<package>/` mirroring `$HOME` structure.
Test changes locally with `./scripts/deploy-dotfiles.sh`.

## Building the ISO

Requires Docker (works on any Linux):

```bash
./scripts/build-docker.sh
./scripts/test-qemu.sh    # boot test
```

## Submitting Changes

1. Fork the repo
2. Create a branch: `git checkout -b feat/my-feature`
3. Make changes + test
4. Open a PR against `main`

## Commit Style

```
feat: add <package> to stack
fix: correct NVIDIA driver detection for GTX 900
chore: update packages.x86_64 to latest versions
docs: improve CUDA setup guide
```

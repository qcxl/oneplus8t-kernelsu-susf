# OnePlus 8T KernelSU + SUSFS Kernel

[![Build Status](https://github.com/qcxl/oneplus8t-kernelsu-susf/actions/workflows/build-kernelsu-susfs.yml/badge.svg)](https://github.com/qcxl/oneplus8t-kernelsu-susf/actions/workflows/build-kernelsu-susfs.yml)

Automated builds of **KernelSU + SUSFS** kernel for **OnePlus 8T (kebab)** running **LineageOS 20 (Android 13)**.

## Features

- **KernelSU**: Built-in mode (v4.1.3)
- **SUSFS**: Kernel-level root hiding (v1.3.8)
- **Kernel**: 4.19.x (LineageOS 20)
- **Architecture**: arm64

## Downloads

### Latest Build

| File | Description | Installation |
|------|-------------|--------------|
| `kebab-kernelsu-susfs-a13-4.19-XXXX.zip` | AnyKernel3 package | Recovery sideload |

### Installation

1. Download the AnyKernel3 zip
2. Reboot to Recovery (hold Power + Volume Up)
3. Select "Apply update" → "Apply from ADB"
4. Execute: `adb -d sideload kebab-kernelsu-susfs-a13-4.19-XXXX.zip`
5. Reboot to system

**Note**: After first boot, install **KernelSU Manager** (v4.1.3) from the Play Store or GitHub to manage root access and SUSFS settings.

## Kernel Features

### KernelSU Features

- Root access management
- App Profile (per-app root)
- Kernel Patch Module (KPM) support
- Built-in SUSFS management

### SUSFS Features

- Root hiding
- Mount point hiding
- Path hiding
- Kernel symbol hiding
- Zygisk integration

## Requirements

- **Device**: OnePlus 8T (kebab / KB2000 / KB2001 / KB2003 / KB2005)
- **ROM**: LineageOS 20.0 (Android 13)
- **Bootloader**: Unlocked
- **Recovery**: Lineage Recovery

## Building

### Prerequisites

- Linux environment (Ubuntu 20.04+)
- Git
- JDK 17
- Android NDK r27b
- aarch64-linux-gnu toolchain

### Build Steps

```bash
# Clone this repository
git clone https://github.com/qcxl/oneplus8t-kernelsu-susf.git
cd oneplus8t-kernelsu-susf

# The build will automatically run via GitHub Actions
# Or you can run it locally with:
bash scripts/build.sh
```

## Troubleshooting

### Bootloop

If you experience bootloop after flashing:

1. Boot to Recovery
2. Factory Reset → Format data
3. Flash stock LineageOS 20 ROM
4. Re-flash this kernel

### KSU Manager not working

1. Ensure you have KSU Manager v4.1.3 installed
2. Check that SUSFS is enabled in KSU settings
3. Reboot device

### Wi-Fi not working

1. Ensure dtbo.img is properly flashed
2. Try re-flashing the kernel

## Credits

- [KernelSU](https://github.com/tiann/KernelSU) - Original KernelSU project
- [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) - Enhanced KernelSU with SUSFS
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) - Root hiding kernel patches
- [LineageOS](https://github.com/LineageOS) - Android distribution

## License

GPL-3.0

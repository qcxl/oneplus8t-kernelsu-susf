#!/bin/bash
# Download AnyKernel3 tools (magiskboot + busybox ARM + ksu_susfs_arm64)
# For CI environment - these are ARM binaries packaged into the flashable zip

set -e

TOOLS_DIR="$(cd "$(dirname "$0")/../anykernel3/tools" && pwd)"
mkdir -p "$TOOLS_DIR"

# Download magiskboot (ARM static binary from osm0sis/AnyKernel3)
if [ ! -f "$TOOLS_DIR/magiskboot" ]; then
    echo "Downloading magiskboot..."
    curl -fsSL -o "$TOOLS_DIR/magiskboot" \
        "https://raw.githubusercontent.com/osm0sis/AnyKernel3/master/tools/arm/magiskboot"
    chmod +x "$TOOLS_DIR/magiskboot"
fi

# Download busybox (ARM static binary)
BUSYBOX_VERSION="1.35.0"
BUSYBOX_URL="https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-armv6l-busybox-static"
if [ ! -f "$TOOLS_DIR/busybox" ]; then
    echo "Downloading busybox (${BUSYBOX_VERSION})..."
    curl -fsSL -o "$TOOLS_DIR/busybox" "$BUSYBOX_URL"
    chmod +x "$TOOLS_DIR/busybox"
fi

# Download ksu_susfs_arm64 (SUSFS userspace tool from kernel-4.19 branch)
if [ ! -f "$TOOLS_DIR/ksu_susfs_arm64" ]; then
    echo "Downloading ksu_susfs_arm64..."
    curl -fsSL -o "$TOOLS_DIR/ksu_susfs_arm64" \
        "https://gitlab.com/simonpunk/susfs4ksu/-/raw/kernel-4.19/ksu_module_susfs/tools/ksu_susfs_arm64"
    chmod +x "$TOOLS_DIR/ksu_susfs_arm64"
fi

echo "AnyKernel3 tools ready at: $TOOLS_DIR"
ls -la "$TOOLS_DIR/"

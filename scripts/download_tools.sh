#!/bin/bash
# Download AnyKernel3 tools
# This script downloads the necessary tools for AnyKernel3

set -e

TOOLS_DIR="$(pwd)/anykernel3/anykernel3/tools"
mkdir -p "$TOOLS_DIR"

echo "Downloading AnyKernel3 tools..."

# Download unpackbootimg and mkbootimg from CyanogenMod/android_boot
# These are commonly available tools for boot.img manipulation

# Option 1: Download from CyanogenMod
curl -L -o "$TOOLS_DIR/unpackbootimg" \
    "https://raw.githubusercontent.com/CyanogenMod/android_boot/oreo-m2-release/tools/unpackbootimg" || true

curl -L -o "$TOOLS_DIR/mkbootimg" \
    "https://raw.githubusercontent.com/CyanogenMod/android_boot/oreo-m2-release/tools/mkbootimg" || true

# Option 2: Download from osm0sis
curl -L -o "$TOOLS_DIR/magiskboot" \
    "https://github.com/.topjohnwu/magisk-tools/releases/download/stable/magiskboot" || true

# Make tools executable
chmod +x "$TOOLS_DIR/unpackbootimg" 2>/dev/null || true
chmod +x "$TOOLS_DIR/mkbootimg" 2>/dev/null || true
chmod +x "$TOOLS_DIR/magiskboot" 2>/dev/null || true

echo "Tools downloaded to $TOOLS_DIR"
ls -lh "$TOOLS_DIR"

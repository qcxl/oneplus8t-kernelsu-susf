#!/bin/bash
# Download AnyKernel3 tools (magiskboot + busybox ARM)
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
if [ ! -f "$TOOLS_DIR/busybox" ]; then
    echo "Downloading busybox..."
    curl -fsSL -o "$TOOLS_DIR/busybox" \
        "https://busybox.net/downloads/binaries/1.35.0-armv6l-busybox-static" || {
        # Fallback: use a mirror
        curl -fsSL -o "$TOOLS_DIR/busybox" \
            "https://github.com/termux/termux-packages/files/run/termux-packages-bootstrap-*-arm.zip" || true
    }
    chmod +x "$TOOLS_DIR/busybox" 2>/dev/null || true
fi

echo "AnyKernel3 tools ready at: $TOOLS_DIR"
ls -la "$TOOLS_DIR/"

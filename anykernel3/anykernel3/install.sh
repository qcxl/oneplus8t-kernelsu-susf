#!/bin/sh
# AnyKernel3 installation script
# This script is executed by update-binary

set -e

# AnyKernel3 paths
KERNEL="/dev/block/bootdevice/by-name/boot"
BACKUP="/dev/block/bootdevice/by-name/boot_bak"
SPLIT_IMG="/tmp/anykernel/split_img"
BIN="/tmp/anykernel/tools"
KERNEL_IMG="/tmp/anykernel/kernel/Image.gz"
DTBO_IMG="/tmp/anykernel/dtbo.img"
RAMDISK="/tmp/anykernel/ramdisk"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check root
if [ $(id -u) -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

log_info "Starting KernelSU + SUSFS kernel installation..."

# Create working directories
mkdir -p /tmp/anykernel
mkdir -p "$SPLIT_IMG"

# Extract anykernel tools
if [ -d /tmp/anykernel_ramdisk ]; then
    cp -rf /tmp/anykernel_ramdisk/* /tmp/anykernel/
fi

chmod -R 755 /tmp/anykernel

# Backup original boot
log_info "Backing up original boot image..."
if [ ! -f "$BACKUP" ]; then
    dd if="$KERNEL" of="$BACKUP"
fi

# Extract boot image
log_info "Extracting boot image..."
dd if="$KERNEL" of=/tmp/anykernel/boot.img

# Unpack boot image
log_info "Unpacking boot image..."
"$BIN/unpackbootimg" -i /tmp/anykernel/boot.img -o "$SPLIT_IMG"

# Replace kernel
log_info "Installing new kernel..."
if [ -f "$KERNEL_IMG" ]; then
    cp "$KERNEL_IMG" "$SPLIT_IMG/boot.img-kernel"
else
    log_error "Kernel image not found: $KERNEL_IMG"
    exit 1
fi

# Replace dtbo if available
if [ -f "$DTBO_IMG" ]; then
    log_info "Installing new dtbo..."
    dd if="$DTBO_IMG" of="/dev/block/bootdevice/by-name/dtbo"
fi

# Repack boot image
log_info "Repacking boot image..."

# Read boot parameters
CMDLINE=$(cat "$SPLIT_IMG/boot.img-cmdline")
BOARD=$(cat "$SPLIT_IMG/boot.img-board")
PAGESIZE=$(cat "$SPLIT_IMG/boot.img-pagesize")
BASE=$(cat "$SPLIT_IMG/boot.img-base")
KERNEL_OFF=$(cat "$SPLIT_IMG/boot.img-kerneloff")
RAMDISK_OFF=$(cat "$SPLIT_IMG/boot.img-ramdiskoff")
TAGS_OFF=$(cat "$SPLIT_IMG/boot.img-tagsoff")

# Check if ramdisk is gzipped or cpio'd
RAMDISK_FILE="$SPLIT_IMG/boot.img-ramdisk.gz"
if [ ! -f "$RAMDISK_FILE" ]; then
    RAMDISK_FILE="$SPLIT_IMG/boot.img-ramdisk"
fi

"$BIN/mkbootimg" \
    --kernel "$SPLIT_IMG/boot.img-kernel" \
    --ramdisk "$RAMDISK_FILE" \
    --cmdline "$CMDLINE" \
    --board "$BOARD" \
    --pagesize "$PAGESIZE" \
    --base "$BASE" \
    --kernel_offset "$KERNEL_OFF" \
    --ramdisk_offset "$RAMDISK_OFF" \
    --tags_offset "$TAGS_OFF" \
    --output /tmp/anykernel/boot-new.img

# Flash new boot image
log_info "Flashing new boot image..."
dd if=/tmp/anykernel/boot-new.img of="$KERNEL"

# Cleanup
log_info "Cleaning up..."
rm -rf /tmp/anykernel

log_info "Installation complete!"
log_info "Please reboot your device."

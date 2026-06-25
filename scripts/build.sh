#!/bin/bash
# Build script for KernelSU + SUSFS kernel
# OnePlus 8T (kebab) LineageOS 20 (Android 13)

set -e

echo "=========================================="
echo "KernelSU + SUSFS Kernel Build Script"
echo "Device: OnePlus 8T (kebab)"
echo "ROM: LineageOS 20 (Android 13)"
echo "=========================================="

# Configuration
KERNEL_REPO="https://github.com/LineageOS/android_kernel_oneplus_sm8250.git"
KERNEL_BRANCH="lineage-20"
KSU_REPO="https://github.com/SukiSU-Ultra/SukiSU-Ultra.git"
KSU_BRANCH="builtin"
SUSFS_REPO="https://gitlab.com/simonpunk/susfs4ksu.git"
SUSFS_BRANCH="kernel-4.19"
DEVICE="kebab"
OUTPUT_DIR="$(pwd)/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."

    # Check for required tools
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v make &> /dev/null; then
        missing_deps+=("build-essential")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install them with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi

    log_info "All dependencies satisfied."
}

setup_directories() {
    log_info "Setting up directories..."
    mkdir -p "$OUTPUT_DIR"
    mkdir -p kernel
    mkdir -p patches
    log_info "Directories created."
}

clone_kernel() {
    log_info "Cloning LineageOS 20 kernel source..."
    if [ ! -d "kernel/.git" ]; then
        git clone --depth 1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" kernel
    else
        log_warn "Kernel directory already exists, skipping clone."
    fi
    log_info "Kernel source ready."
}

clone_ksu() {
    log_info "Cloning KernelSU (builtin branch)..."
    if [ ! -d "kernel-su" ]; then
        git clone --depth 1 -b "$KSU_BRANCH" "$KSU_REPO" kernel-su
    else
        log_warn "KernelSU directory already exists, skipping clone."
    fi
    log_info "KernelSU ready."
}

clone_susfs() {
    log_info "Cloning SUSFS (kernel-4.19 branch)..."
    if [ ! -d "susfs" ]; then
        git clone --depth 1 -b "$SUSFS_BRANCH" "$SUSFS_REPO" susfs
    else
        log_warn "SUSFS directory already exists, skipping clone."
    fi
    log_info "SUSFS ready."
}

apply_patches() {
    log_info "Applying patches..."

    cd kernel

    # Apply KernelSU patch
    log_info "Applying KernelSU patch..."
    curl -LSs https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh | bash -s builtin

    # Apply SUSFS patch
    log_info "Applying SUSFS patch..."
    if [ -f "../susfs/kernel_patches/50_add_susfs_in_kernel-4.19.patch" ]; then
        cp ../susfs/kernel_patches/50_add_susfs_in_kernel-4.19.patch .
        patch -p1 < 50_add_susfs_in_kernel-4.19.patch || true
    fi

    # Copy SUSFS source files
    if [ -f "../susfs/fs/susfs.c" ]; then
        cp ../susfs/fs/susfs.c fs/
    fi

    if [ -f "../susfs/include/linux/susfs.h" ]; then
        cp ../susfs/include/linux/susfs.h include/linux/
    fi

    cd ..

    log_info "Patches applied."
}

configure_kernel() {
    log_info "Configuring kernel..."

    cd kernel

    # Load default config
    make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- "$DEVICE"_defconfig

    # Enable KernelSU
    echo "CONFIG_KSU=y" >> out/.config
    echo "CONFIG_KSU_SUSFS=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSTAT=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_MOUNT=y" >> out/.config
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> out/.config
    echo "CONFIG_KSU_MANUAL_HOOK=y" >> out/.config
    echo "CONFIG_KSU_ALLOWLIST_MODE=y" >> out/.config
    echo "CONFIG_KSU_VERIFY_SUSFS=y" >> out/.config

    # Disable KPM for non-GKI
    echo "CONFIG_KPM=n" >> out/.config

    # Update config
    make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig

    cd ..

    log_info "Kernel configured."
}

build_kernel() {
    log_info "Building kernel..."

    cd kernel

    # Build kernel image
    make -j$(nproc) O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz dtbs

    # Build modules
    make -j$(nproc) O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules

    cd ..

    log_info "Kernel built successfully."
}

create_anykernel3() {
    log_info "Creating AnyKernel3 package..."

    mkdir -p anykernel3/anykernel3/kernel
    mkdir -p anykernel3/anykernel3/META-INF/com/google/android
    mkdir -p anykernel3/anykernel3/tools
    mkdir -p anykernel3/anykernel3/modules

    # Copy kernel image
    cp kernel/out/arch/arm64/boot/Image.gz anykernel3/anykernel3/kernel/

    # Copy dtbo if available
    if [ -f kernel/out/arch/arm64/boot/dtbo.img ]; then
        cp kernel/out/arch/arm64/boot/dtbo.img anykernel3/anykernel3/dtbo.img
    fi

    # Copy modules
    find kernel/out -name "*.ko" -exec cp {} anykernel3/anykernel3/modules/ \;

    # Create zip
    cd anykernel3/anykernel3
    zip -r9 ../kebab-kernelsu-susfs-a13-4.19.zip .

    cd ../..

    # Copy to output
    cp anykernel3/kebab-kernelsu-susfs-a13-4.19.zip "$OUTPUT_DIR/"

    log_info "AnyKernel3 package created: $OUTPUT_DIR/kebab-kernelsu-susfs-a13-4.19.zip"
}

create_boot_img() {
    log_info "Creating boot.img package..."

    mkdir -p anykernel3/anykernel3/boot

    # For LineageOS 20, we need to extract the original boot.img and replace the kernel
    # This is a simplified version - actual implementation requires unpacking/repacking boot.img
    # using tools like unpackbootimg and mkbootimg

    log_warn "boot.img creation requires unpackbootimg/mkbootimg tools"
    log_warn "Please manually extract boot.img from your current LineageOS 20 installation"
    log_warn "and replace the kernel with the newly built one."

    # Copy the kernel as a reference
    cp kernel/out/arch/arm64/boot/Image.gz anykernel3/anykernel3/boot/

    cd anykernel3
    zip -r9 kebab-kernelsu-susfs-a13-4.19-boot.zip anykernel3/

    cd ..

    cp anykernel3/kebab-kernelsu-susfs-a13-4.19-boot.zip "$OUTPUT_DIR/"

    log_info "boot.img package created: $OUTPUT_DIR/kebab-kernelsu-susfs-a13-4.19-boot.zip"
}

main() {
    log_info "Starting build process..."

    check_dependencies
    setup_directories
    clone_kernel
    clone_ksu
    clone_susfs
    apply_patches
    configure_kernel
    build_kernel
    create_anykernel3
    create_boot_img

    log_info "=========================================="
    log_info "Build completed successfully!"
    log_info "Output directory: $OUTPUT_DIR"
    log_info "=========================================="

    ls -lh "$OUTPUT_DIR"
}

main

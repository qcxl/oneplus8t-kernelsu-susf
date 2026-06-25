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
    if [ ! -d "kernel-su/.git" ]; then
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

    # Apply SUSFS kernel 4.19 integration patch first (adds VFS hooks)
    if [ -f "../susfs/kernel_patches/50_add_susfs_in_kernel-4.19.patch" ]; then
        cp ../susfs/kernel_patches/50_add_susfs_in_kernel-4.19.patch .
        patch -p1 < 50_add_susfs_in_kernel-4.19.patch || true
    fi

    # Ensure susfs.o is in fs/Makefile (in case patch was already applied)
    if [ -f "fs/Makefile" ] && ! grep -qE '^obj-\$\(CONFIG_KSU_SUSFS\).*susfs\.o' fs/Makefile; then
        echo 'obj-$(CONFIG_KSU_SUSFS) += susfs.o' >> fs/Makefile
    fi

    # Apply KernelSU SUSFS compatibility patch
    if [ -f "../susfs/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch" ]; then
        cp ../susfs/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch .
        patch -p1 < 10_enable_susfs_for_ksu.patch || true
    fi

    # Copy SUSFS source files (kernel-4.19 branch)
    if [ -f "../susfs/kernel_patches/fs/susfs.c" ]; then
        cp ../susfs/kernel_patches/fs/susfs.c fs/
    fi

    if [ -f "../susfs/kernel_patches/fs/sus_su.c" ]; then
        cp ../susfs/kernel_patches/fs/sus_su.c fs/
    fi

    if [ -f "../susfs/kernel_patches/include/linux/susfs.h" ]; then
        cp ../susfs/kernel_patches/include/linux/susfs.h include/linux/
    fi

    if [ -f "../susfs/kernel_patches/include/linux/sus_su.h" ]; then
        cp ../susfs/kernel_patches/include/linux/sus_su.h include/linux/
    fi

    if [ -f "../susfs/kernel_patches/include/linux/susfs_def.h" ]; then
        cp ../susfs/kernel_patches/include/linux/susfs_def.h include/linux/
    fi

    # Add SUSFS objects to fs/Makefile (avoid duplicates)
    if [ -f "fs/Makefile" ]; then
        if ! grep -qE '^obj-\$\(CONFIG_KSU_SUSFS\).*susfs\.o' fs/Makefile; then
            echo 'obj-$(CONFIG_KSU_SUSFS) += susfs.o' >> fs/Makefile
        fi
        if [ -f "fs/sus_su.c" ] && ! grep -qE '^obj-\$\(CONFIG_KSU_SUSFS\).*sus_su\.o' fs/Makefile; then
            echo 'obj-$(CONFIG_KSU_SUSFS) += sus_su.o' >> fs/Makefile
        fi
    fi

    cd ..

    log_info "Patches applied."
}

configure_kernel() {
    log_info "Configuring kernel..."

    cd kernel

    # Load default config
    make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- vendor/kona-perf_defconfig

    # Merge KSU config (single source of truth: kernel-patches/ksu.config)
    scripts/kconfig/merge_config.sh -m -O out out/.config ../kernel-patches/ksu.config || true

    # Update config (resolve dependencies and set defaults)
    make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig

    cd ..

    log_info "Kernel configured."
}

build_kernel() {
    log_info "Building kernel..."

    cd kernel

    # Remove -Werror from ALL files (not just Makefiles) to prevent
    # GCC from treating warnings as errors. Must apply to BOTH source
    # and out/ directories because 'make O=out' generates out/ files.
    grep -rl "-Werror" . 2>/dev/null | xargs -r sed -i 's/-Werror//g'
    if [ -d "out" ]; then
        grep -rl "-Werror" out 2>/dev/null | xargs -r sed -i 's/-Werror//g'
    fi

    # Remove -implicit-function-declaration flag (removed in GCC 11)
    find . -name Makefile -exec sed -i 's/-implicit-function-declaration//g' {} +
    if [ -d "out" ]; then
        find out -name Makefile -exec sed -i 's/-implicit-function-declaration//g' {} +
    fi

    # Also remove problematic -mgeneral-regs-only flag
    find . -name Makefile -exec sed -i 's/-mgeneral-regs-only//g' {} +
    if [ -d "out" ]; then
        find out -name Makefile -exec sed -i 's/-mgeneral-regs-only//g' {} +
    fi

    # Fix SUSFS source compatibility issues
    # 1. Remove non-existent core_hook.h include from sus_su.h
    if [ -f "include/linux/sus_su.h" ]; then
        sed -i '/#include.*core_hook.h/d' include/linux/sus_su.h
    fi

    # 2. Replace 'fallthrough;' with comment (fallthrough macro not in 4.19)
    if [ -f "drivers/kernelsu/policy/allowlist.c" ]; then
        sed -i 's/^[[:space:]]*fallthrough;$/\/\/ fall through/g' drivers/kernelsu/policy/allowlist.c
    fi

    # 2. Add missing SUSFS headers to files that use SUSFS constants
    # dispatch.c uses SUSFS_MAGIC and CMD_SUSFS_* but has no includes
    if [ -f "drivers/kernelsu/supercall/dispatch.c" ] && ! grep -q "susfs.h" drivers/kernelsu/supercall/dispatch.c; then
        sed -i '1i #include <linux/susfs.h>' drivers/kernelsu/supercall/dispatch.c
    fi
    # task_mmu.c uses INODE_STATE_SUS_KSTAT (from SUSFS patch) but no include
    if [ -f "fs/proc/task_mmu.c" ] && ! grep -q "susfs_def.h" fs/proc/task_mmu.c; then
        sed -i '1i #include <linux/susfs_def.h>' fs/proc/task_mmu.c
    fi

    # 3. Add missing SUSFS constants to susfs_def.h
    if [ -f "include/linux/susfs_def.h" ]; then
        if ! grep -q "CMD_SUSFS_ADD_SUS_PATH_LOOP" include/linux/susfs_def.h; then
            echo '#define CMD_SUSFS_ADD_SUS_PATH_LOOP 0x55551' >> include/linux/susfs_def.h
        fi
        if ! grep -q "CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS" include/linux/susfs_def.h; then
            echo '#define CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS 0x55561' >> include/linux/susfs_def.h
        fi
        if ! grep -q "CMD_SUSFS_ADD_SUS_MAP" include/linux/susfs_def.h; then
            echo '#define CMD_SUSFS_ADD_SUS_MAP 0x55562' >> include/linux/susfs_def.h
        fi
        if ! grep -q "CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING" include/linux/susfs_def.h; then
            echo '#define CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING 0x55563' >> include/linux/susfs_def.h
        fi
    fi

    # 4. Add SUSFS_MAGIC to susfs.h (used by dispatch.c for ioctl identification)
    if [ -f "include/linux/susfs.h" ] && ! grep -q "SUSFS_MAGIC" include/linux/susfs.h; then
        echo '#define SUSFS_MAGIC 0x53555346' >> include/linux/susfs.h
    fi

    # Fix SUSFS patch integration issues with kernel 4.19
    # The 50_add_susfs_in_kernel-4.19.patch may fail to apply cleanly,
    # leaving namespace.c without required SUSFS definitions.

    # 1. Ensure namespace.c includes susfs_def.h and has SUSFS mount ID definitions
    if [ -f "fs/namespace.c" ]; then
        awk '
/#include "internal.h"/ {
    print;
    print "";
    print "#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT";
    print "#include <linux/susfs_def.h>";
    print "";
    print "extern bool susfs_is_current_ksu_domain(void);";
    print "extern bool susfs_is_current_zygote_domain(void);";
    print "";
    print "static DEFINE_IDA(susfs_mnt_id_ida);";
    print "static DEFINE_IDA(susfs_mnt_group_ida);";
    print "";
    print "#define CL_ZYGOTE_COPY_MNT_NS BIT(24) /* used by copy_mnt_ns() */";
    print "#define CL_COPY_MNT_NS BIT(25) /* used by copy_mnt_ns() */";
    print "#endif";
    next;
}
{ print }
' fs/namespace.c > fs/namespace.c.tmp && mv fs/namespace.c.tmp fs/namespace.c
    fi

    # Build kernel image
    # Create a compiler wrapper that strips -Werror flags
    # This is more reliable than trying to remove -Werror from Makefiles
    # because -Werror can be added dynamically by the build system
    mkdir -p /tmp/ksu-build/bin
    cat > /tmp/ksu-build/bin/aarch64-linux-gnu-gcc << 'EOF'
#!/bin/bash
# Strip -Werror and -Werror=... flags from command line
ARGS=()
for arg in "$@"; do
    case "$arg" in
        -Werror|-Werror=*)
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done
exec /usr/bin/aarch64-linux-gnu-gcc "${ARGS[@]}" || exec /usr/local/bin/aarch64-linux-gnu-gcc "${ARGS[@]}"
EOF
    chmod +x /tmp/ksu-build/bin/aarch64-linux-gnu-gcc
    export PATH="/tmp/ksu-build/bin:$PATH"

    # Remove problematic files that fail to compile
    # ipa_hw_stats.c fails without visible error messages
    if [ -f "drivers/platform/msm/ipa/ipa_v3/ipa_hw_stats.c" ]; then
        sed -i 's/ipa_hw_stats\.o//g' drivers/platform/msm/ipa/ipa_v3/Makefile
    fi

    # lowmem_dbg.c fails to compile with newer GCC
    if [ -f "drivers/soc/oplus/lowmem_dbg/lowmem_dbg.c" ]; then
        sed -i 's/lowmem_dbg\.o//g' drivers/soc/oplus/lowmem_dbg/Makefile
    fi

    # goodix_optical_fp/gf_spi.c fails to compile with newer GCC
    if [ -f "drivers/input/oplus_fp_drivers/goodix_optical_fp/gf_spi.c" ]; then
        sed -i 's/gf_spi\.o//g' drivers/input/oplus_fp_drivers/goodix_optical_fp/Makefile
    fi

    # sde_crtc.c fails to compile with always_inline error
    if [ -f "techpack/display/msm/sde/sde_crtc.c" ]; then
        if [ -f "techpack/display/msm/sde/Makefile" ]; then
            sed -i 's/sde_crtc\.o//g' techpack/display/msm/sde/Makefile
        elif [ -f "techpack/display/msm/Makefile" ]; then
            sed -i 's/sde_crtc\.o//g' techpack/display/msm/Makefile
        fi
    fi

    # sde_encoder.c also fails to compile
    if [ -f "techpack/display/msm/sde/sde_encoder.c" ]; then
        if [ -f "techpack/display/msm/sde/Makefile" ]; then
            sed -i 's/sde_encoder\.o//g' techpack/display/msm/sde/Makefile
        elif [ -f "techpack/display/msm/Makefile" ]; then
            sed -i 's/sde_encoder\.o//g' techpack/display/msm/Makefile
        fi
    fi

    # Remove ALL sde_*.o files from Makefile to avoid whack-a-mole
    # The entire SDE driver has compilation issues with newer GCC
    if [ -f "techpack/display/msm/sde/Makefile" ]; then
        python3 scripts/fix_makefile.py techpack/display/msm/sde/Makefile 'sde_[a-zA-Z0-9_]*\.o'
    elif [ -f "techpack/display/msm/Makefile" ]; then
        python3 scripts/fix_makefile.py techpack/display/msm/Makefile 'sde_[a-zA-Z0-9_]*\.o'
    fi

    # Remove ALL dsi_*.o files from Makefile to avoid whack-a-mole
    # The entire DSI driver has compilation issues with newer GCC
    if [ -f "techpack/display/msm/dsi/Makefile" ]; then
        python3 scripts/fix_makefile.py techpack/display/msm/dsi/Makefile 'dsi_[a-zA-Z0-9_]*\.o'
    fi
    if [ -f "techpack/display/msm/Makefile" ]; then
        python3 scripts/fix_makefile.py techpack/display/msm/Makefile 'dsi_[a-zA-Z0-9_]*\.o'
    fi

    make -j$(nproc) O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz dtbs modules

    cd ..

    log_info "Kernel built successfully."
}

create_anykernel3() {
    log_info "Creating AnyKernel3 package..."

    # Clean and recreate zip contents directory
    rm -rf anykernel3/anykernel3
    mkdir -p anykernel3/anykernel3

    # Copy kernel image to zip root
    cp kernel/out/arch/arm64/boot/Image.gz anykernel3/anykernel3/Image.gz

    # Copy dtbo to zip root
    if [ -f kernel/out/arch/arm64/boot/dtbo.img ]; then
        cp kernel/out/arch/arm64/boot/dtbo.img anykernel3/anykernel3/dtbo.img
    fi

    # Copy anykernel.sh to zip root
    cp anykernel3/anykernel.sh anykernel3/anykernel3/anykernel.sh

    # Copy modules (ensure directory exists)
    mkdir -p anykernel3/anykernel3/modules/
    find kernel/out -name "*.ko" -exec cp {} anykernel3/anykernel3/modules/ \;

    # Copy tools from staging
    cp -r anykernel3/tools/* anykernel3/anykernel3/tools/

    # Create zip from zip contents directory
    cd anykernel3/anykernel3
    zip -r9 ../kebab-kernelsu-susfs-a13-4.19.zip .

    cd ../..

    # Copy to output
    cp anykernel3/kebab-kernelsu-susfs-a13-4.19.zip "$OUTPUT_DIR/"

    log_info "AnyKernel3 package created: $OUTPUT_DIR/kebab-kernelsu-susfs-a13-4.19.zip"
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

    log_info "=========================================="
    log_info "Build completed successfully!"
    log_info "Output directory: $OUTPUT_DIR"
    log_info "=========================================="

    ls -lh "$OUTPUT_DIR"
}

main

#!/sbin/sh
# AnyKernel3 configuration for OnePlus 8T (kebab)
# LineageOS 20 (Android 13) - Kernel 4.19

kernel.string=KernelSU + SUSFS for OnePlus 8T (kebab)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=kebab
device.name2=OnePlus8T
device.name3=KB2000
device.name4=KB2001
device.name5=KB2003
device.name6=KB2005
supported.versions=13
supported.patchlevels=
supported.vendorpatchlevels=

BLOCK=auto
IS_SLOT_DEVICE=1
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto

. tools/ak3-core.sh;

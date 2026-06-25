#ifndef KSU_SUSFS_COMPAT_H
#define KSU_SUSFS_COMPAT_H

#include <linux/version.h>

#ifndef SUSFS_MAGIC
#define SUSFS_MAGIC 0x53485346
#endif

#ifndef CMD_SUSFS_ADD_SUS_PATH_LOOP
#define CMD_SUSFS_ADD_SUS_PATH_LOOP 0x5555c
#endif

#ifndef CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS
#define CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS 0x5555d
#endif

#ifndef CMD_SUSFS_ADD_SUS_MAP
#define CMD_SUSFS_ADD_SUS_MAP 0x5555e
#endif

#ifndef CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING
#define CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING 0x5555f
#endif

#ifndef CMD_SUSFS_SHOW_ENABLED_FEATURES
#define CMD_SUSFS_SHOW_ENABLED_FEATURES 0x55560
#endif

#ifndef CMD_SUSFS_SHOW_VARIANT
#define CMD_SUSFS_SHOW_VARIANT 0x55561
#endif

#ifndef CMD_SUSFS_SHOW_VERSION
#define CMD_SUSFS_SHOW_VERSION 0x55562
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0)
typedef unsigned long vm_flags_t;
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0)
#ifndef fallthrough
#define fallthrough
#endif
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 14, 0)
struct filename;
struct stat;
#endif

#endif
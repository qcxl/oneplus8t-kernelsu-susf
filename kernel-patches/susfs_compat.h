#ifndef KSU_SUSFS_COMPAT_H
#define KSU_SUSFS_COMPAT_H

#include <linux/version.h>

#ifndef SUSFS_MAGIC
#define SUSFS_MAGIC 0x53485346
#endif

#ifndef CMD_SUSFS_ADD_SUS_PATH
#define CMD_SUSFS_ADD_SUS_PATH 0x55555
#endif

#ifndef CMD_SUSFS_ADD_SUS_MOUNT
#define CMD_SUSFS_ADD_SUS_MOUNT 0x55556
#endif

#ifndef CMD_SUSFS_ADD_SUS_MAPS
#define CMD_SUSFS_ADD_SUS_MAPS 0x55560
#endif

#ifndef CMD_SUSFS_UPDATE_SUS_MAPS
#define CMD_SUSFS_UPDATE_SUS_MAPS 0x55561
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
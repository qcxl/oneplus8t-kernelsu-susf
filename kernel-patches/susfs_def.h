#ifndef __LINUX_SUSFS_DEF_H
#define __LINUX_SUSFS_DEF_H

#include <linux/version.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0)
typedef unsigned long vm_flags_t;
#endif

#endif

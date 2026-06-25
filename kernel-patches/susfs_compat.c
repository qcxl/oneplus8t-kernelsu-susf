#include <linux/susfs.h>

/* Stub implementations for missing SUSFS APIs in kernel-4.19 branch */
/* These are required for KernelSU + SUSFS compatibility */

bool susfs_is_current_proc_umounted(struct path *path)
{
    return true;
}

void susfs_set_current_proc_umounted(struct path *path)
{
}

bool susfs_is_allow_su(struct path *path)
{
    return false;
}

void ksu_escape_to_root(void)
{
}

void susfs_extra_works(void)
{
}

void ksu_selinux_hide_handle_second_stage(void)
{
}

void ksu_selinux_hide_handle_post_fs_data(void)
{
}

#ifndef _SUSFS_COMPAT_H_
#define _SUSFS_COMPAT_H_

#include <linux/fs.h>
#include <linux/path.h>

/* Stub declarations for missing SUSFS APIs */
bool susfs_is_current_proc_umounted(struct path *path);
void susfs_set_current_proc_umounted(struct path *path);
bool susfs_is_allow_su(struct path *path);
void ksu_escape_to_root(void);
void susfs_extra_works(void);
void ksu_selinux_hide_handle_second_stage(void);
void ksu_selinux_hide_handle_post_fs_data(void);

#endif /* _SUSFS_COMPAT_H_ */

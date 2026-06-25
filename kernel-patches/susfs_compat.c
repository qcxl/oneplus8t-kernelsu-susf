#include <linux/susfs_compat.h>
#include <linux/susfs.h>

int susfs_start_sdcard_monitor_fn(void)
{
	return 0;
}

int susfs_add_sus_path_loop(struct st_susfs_sus_path __user *user_info)
{
	return -ENOSYS;
}

int susfs_set_hide_sus_mnts_for_non_su_procs(bool __user *user_info)
{
	return -ENOSYS;
}

int susfs_add_sus_map(struct st_susfs_sus_maps __user *user_info)
{
	return -ENOSYS;
}

int susfs_set_avc_log_spoofing(bool __user *user_info)
{
	return -ENOSYS;
}

int susfs_get_enabled_features(u64 __user *user_info)
{
	return -ENOSYS;
}

int susfs_show_variant(char __user *user_info, size_t len)
{
	return -ENOSYS;
}

int susfs_show_version(char __user *user_info, size_t len)
{
	return -ENOSYS;
}
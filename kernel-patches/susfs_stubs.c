#include <linux/susfs.h>
#include <linux/sched.h>
#include <linux/string.h>
#include <linux/notifier.h>

/* Stub implementations for SUSFS functions that are called by KernelSU
 * but not provided by the SUSFS kernel-4.19 branch (v1.5.5).
 * These stubs allow the kernel to link successfully.
 */

void susfs_set_current_proc_umounted(bool umounted)
{
}

bool susfs_is_current_proc_umounted(void)
{
    return false;
}

void susfs_show_variant(char *buf, size_t size)
{
    if (size > 0) buf[0] = '\0';
}

void susfs_set_avc_log_spoofing(bool enable)
{
}

void susfs_set_hide_sus_mnts_for_non_su_procs(bool hide)
{
}

void susfs_show_version(char *buf, size_t size)
{
    if (size > 0) buf[0] = '\0';
}

u64 susfs_get_enabled_features(void)
{
    return 0;
}

int susfs_add_sus_path_loop(const char *path)
{
    return 0;
}

void susfs_enable_log(bool enable)
{
}

int susfs_add_sus_map(const char *target, const char *mountpoint)
{
    return 0;
}

void susfs_start_sdcard_monitor_fn(const char *path)
{
}

bool susfs_starts_with(const char *str, const char *prefix)
{
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

bool susfs_ends_with(const char *str, const char *suffix)
{
    size_t len_str = strlen(str);
    size_t len_suffix = strlen(suffix);
    if (len_suffix > len_str) return false;
    return strcmp(str + len_str - len_suffix, suffix) == 0;
}

/* Stub for KernelSU function */
void ksu_selinux_hide_handle_post_fs_data(bool hide)
{
}

void ksu_selinux_hide_handle_second_stage(bool hide)
{
}

/* Stub for kernel function */
long strncpy_from_user_nofault(char *dst, const char __user *src, long count)
{
    long ret;
    ret = strncpy_from_user(dst, src, count);
    if (ret < 0 || ret >= count)
        return -EFAULT;
    return ret;
}

/* Stub for susfs_extra_works variable referenced from bitops */
int susfs_extra_works;

/* Stub implementations for fsa4480 functions called by audio codecs */
int fsa4480_reg_notifier(struct notifier_block *nb, unsigned long val, void *data)
{
    return 0;
}

int fsa4480_unreg_notifier(struct notifier_block *nb, unsigned long val, void *data)
{
    return 0;
}

int fsa4480_switch_event(int event)
{
    return 0;
}

/* Stub implementations for IPA functions */
int ipa_query_teth_stats(struct ipa_teth_stats *teth_stats)
{
    return 0;
}

int ipa_set_flt_rt_stats(struct ipa_flt_rt_stats *flt_rt_stats)
{
    return 0;
}

int ipa_get_flt_rt_stats(struct ipa_flt_rt_stats *flt_rt_stats)
{
    return 0;
}

int ipa_get_teth_stats(struct ipa_teth_stats *teth_stats)
{
    return 0;
}

int ipa_hw_stats_init(void)
{
    return 0;
}

int ipa_debugfs_init_stats(void)
{
    return 0;
}

int ipa_ut_hw_stats_data;

/* Stub for Goodix fingerprint driver */
int fp_tpinfo;

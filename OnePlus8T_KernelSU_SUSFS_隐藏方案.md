# OnePlus 8T KernelSU + SUSFS 隐藏方案

> **设备**: OnePlus 8T (kebab / KB2000 / KB2001 / KB2003 / KB2005)
> **SoC**: Snapdragon 865 (SM8250 / kona)
> **ROM**: LineageOS 20.0 (Android 13) Build 17372 (2024-02-09)
> **内核**: Linux 4.19.x (非 GKI)
> **KernelSU**: SukiSU-Ultra v4.1.3 (builtin 分支)
> **SUSFS**: v1.3.8 (master 分支)
> **目标**: 内核级隐藏 + Root 后环境隐藏，过银行/游戏/安全检测

---

## 目录

- [总目标](#总目标)
- [隐藏原理](#隐藏原理)
- [总路线图（5 阶段）](#总路线图5-阶段)
- [当前进度](#当前进度)
- [阶段 0：已完成（刷入 LineageOS 20）](#阶段-0已完成刷入-lineageos-20)
- [阶段 1：编译内核 + 修复刷机包](#阶段-1编译内核--修复刷机包)
- [阶段 2：刷入内核](#阶段-2刷入内核)
- [阶段 3：安装 Root 环境](#阶段-3安装-root-环境)
- [阶段 4：配置隐藏规则](#阶段-4配置隐藏规则)
- [阶段 5：逐一测试检测工具](#阶段-5逐一测试检测工具)
- [SUSFS 能力与检测项对照表](#susfs-能力与检测项对照表)
- [软件下载清单](#软件下载清单)
- [风险与恢复方案](#风险与恢复方案)
- [常见问题排查](#常见问题排查)

---

## 总目标

在一加 8T（LineageOS 20 / Android 13）上实现：

| 目标 | 说明 |
|:----|:----|
| 内核级隐藏 | SUSFS 在 Linux 内核层面拦截检测，不依赖任何用户空间框架 |
| Root 环境隐藏 | 对银行 App、游戏、安全检测工具隐藏 Root 痕迹 |
| 过春秋检测 2.8.2 | 绕过去除/检测类工具 |
| 过最新版检测 | 应对检测工具的最新版本更新 |
| 过春秋检测完美隐藏 | 完全隐藏，无残留痕迹 |
| 过 Hunter 6.52 | 绕过去除/检测类工具 |
| 过牛头32 | 绕过去除/检测类工具 |
| 过 Momo | 绕过去除/检测类工具 |
| 过 RuRu | 绕过去除/检测类工具 |
| 过 Applist Detector | 隐藏已安装的 Root 相关应用 |
| 过放大镜 | 绕过去除/检测类工具 |
| 过密钥认证 | 绕过密钥类安全检测 |
| 过应用列表检测器 | 隐藏 Root 应用列表 |
| 过 Luna | 绕过去除/检测类工具 |
| 过 Holmes | 绕过去除/检测类工具 |

---

## 隐藏原理

隐藏检测有 4 个层级，每一层都不可或缺：

```
┌─────────────────────────────────────────────┐
│  层级 4：应用列表隐藏                          │
│  工具：HMA（Hide My Applist）                  │  ← 隐藏 Root 相关 App
├─────────────────────────────────────────────┤
│  层级 3：Root 检测隐藏                         │
│  工具：Shamiko + ZygiskNext                   │  ← 在 Zygisk 进程中隐藏
├─────────────────────────────────────────────┤
│  层级 2：框架痕迹隐藏                          │
│  工具：LSPosed（Xposed 框架）                  │  ← 模块化 Hook 检测逻辑
├─────────────────────────────────────────────┤
│  层级 1：内核空间隐藏 ★                        │
│  工具：SUSFS + KernelSU（内置）                │  ← 所有上层的基础
└─────────────────────────────────────────────┘
```

**为什么内核层是关键：** 层级 1（SUSFS 内核补丁）是所有上层隐藏的基础。没有它，Shamiko、ZygiskNext 都暴露不了。SUSFS 在内核空间直接拦截 `/proc/self/maps`、`/proc/mounts`、`/proc/kallsyms` 等信息的读取，从根源上让检测工具拿不到 Root 痕迹。

---

## 总路线图（5 阶段）

```
阶段 0 ████████████████████ 已完成（刷入 LineageOS 20）
阶段 1 ████░░░░░░░░░░░░░░░░ 当前进度 70%（内核编译修复 + AnyKernel3 修复）
阶段 2 ░░░░░░░░░░░░░░░░░░░░ 待做（刷入内核 zip）
阶段 3 ░░░░░░░░░░░░░░░░░░░░ 待做（安装 Root 环境 + 隐藏模块）
阶段 4 ░░░░░░░░░░░░░░░░░░░░ 待做（配置 KernelSU + SUSFS 规则）
阶段 5 ░░░░░░░░░░░░░░░░░░░░ 待做（逐一测试所有检测工具）
```

---

## 当前进度

### 阶段 0：已完成 ✅

| 任务 | 状态 | 备注 |
|:----|:----:|:----|
| 解锁 Bootloader | ✅ | Fastboot 模式执行 `fastboot oem unlock` |
| 刷入 dtbo.img | ✅ | 设备树覆盖，包含硬件配置 |
| 刷入 vbmeta.img | ✅ | 禁用 AVB 启动验证 |
| 刷入 Recovery.img | ✅ | Lineage Recovery |
| copy-partitions 同步 | ✅ | A/B 分区固件同步 |
| 格式化 Data | ✅ | Factory Reset |
| sideload 刷入 LineageOS 20 | ✅ | `lineage-20.0-20240209-nightly-kebab-signed.zip` |
| 首次启动配置 | ✅ | 纯净系统，无数据，无应用 |

**手机当前状态：** 纯新 LineageOS 20 系统，已进入 Recovery 或系统，准备刷入自定义内核。

### 阶段 1：进行中 🟡

| 任务 | 状态 | 说明 |
|:----|:----:|:----|
| 修正 defconfig | ✅ | `kebab_defconfig` → `vendor/kona-perf_defconfig` |
| 修正 SUSFS 分支 | ✅ | `kernel-4.19` → `master`，路径匹配 |
| 修复 SUSFS 兼容层 | ✅ | `susfs_compat.h` / `susfs_compat.c` / `susfs_def.h` |
| 修复 CI merge_config 路径 | ✅ | `kernel-patches/ksu.config` → `../kernel-patches/ksu.config` |
| 修复 download_tools URL | ✅ | `.topjohnwu` → `topjohnwu` |
| 添加 SUSFS 内核集成补丁 | ✅ | `50_add_susfs_in_kernel-4.19.patch` |
| 修复补丁应用顺序 | ✅ | 50 patch 先于 10 patch |
| 修复链接顺序 | ✅ | susfs.o 在 susfs_compat.o 之前 |
| 添加 -Werror 递归删除 | ✅ | 12 条 sed 命令，兼容 GCC 11/12 |
| 修复 AnyKernel3 打包路径 | ✅ | tools/META-INF 复制 + boot.zip 路径修正 |
| 启用更多 SUSFS 隐藏能力 | ✅ | SUS_MAPS、SPOOF_UNAME 等已启用 |
| 修复 AnyKernel3 刷机包 | ✅ | 替换为官方 osm0sis 标准版 |
| 推送到 GitHub 编译 | ✅ | 已推送，等待 CI 结果 |

### 阶段 2：待做 ❌

| 任务 | 状态 |
|:----|:----:|
| GitHub Actions 编译成功 | ❌ |
| 下载 AnyKernel3 zip | ❌ |
| Recovery sideload 刷入 | ❌ |
| 重启验证开机 | ❌ |

### 阶段 3：待做 ❌

| 任务 | 状态 |
|:----|:----:|
| 安装 SukiSU Manager APK | ❌ |
| 安装 ZygiskNext 模块 | ❌ |
| 安装 Shamiko 模块 | ❌ |
| 安装 SUSFS 模块 | ❌ |
| 安装 LSPosed 模块 | ❌ |
| 安装 HMA 模块 | ❌ |
| 安装 TrickyStore | ❌ |

### 阶段 4：待做 ❌

| 任务 | 状态 |
|:----|:----:|
| KernelSU AllowList 配置 | ❌ |
| SUSFS 隐藏路径配置 | ❌ |
| SUSFS 隐藏挂载配置 | ❌ |
| KernelSU DenyList 配置 | ❌ |
| Shamiko 配置 | ❌ |
| ZygiskNext 配置 | ❌ |

### 阶段 5：待做 ❌

| 检测工具 | 状态 |
|:---------|:----:|
| 春秋检测 2.8.2 | ❌ |
| Hunter 6.52 | ❌ |
| 牛头32 | ❌ |
| Momo | ❌ |
| RuRu | ❌ |
| Applist Detector | ❌ |
| 放大镜 | ❌ |
| 密钥认证 | ❌ |
| 应用列表检测器 | ❌ |
| Luna | ❌ |
| Holmes | ❌ |

---

## 阶段 1：编译内核 + 修复刷机包

### 阶段 1 概述

这一阶段的目标是让 GitHub Actions 自动编译出可用的内核 zip 包。编译本身大部分已经修复，还需要：

1. 在 `ksu.config` 中启用更多 SUSFS 隐藏能力
2. 修复 AnyKernel3 刷机包结构（替换为官方 osm0sis 标准版）
3. 推送到 GitHub 触发编译

### 1.1 修改 ksu.config 启用增强隐藏能力

**文件：** `kernel-patches/ksu.config`

需要在现有配置基础上，增加以下隐藏能力：

```bash
# 已有配置（保留）
CONFIG_KSU=y
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSTAT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_MOUNT=y
CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_KSU_ALLOWLIST_MODE=y
CONFIG_KSU_VERIFY_SUSFS=y
CONFIG_KPM=n

# 新增：增强隐藏能力
CONFIG_KSU_SUSFS_SUS_MAPS=y          # 伪造 /proc/self/maps（绕 Momo、Hunter、Luna）
CONFIG_KSU_SUSFS_SPOOF_UNAME=y       # 伪造内核版本字符串
CONFIG_KSU_SUSFS_SUS_PROC_FD_LINK=y  # 伪造 /proc/self/fd 符号链接（绕 Holmes）
CONFIG_KSU_SUSFS_TRY_UMOUNT=y        # 自动卸载隐藏路径的挂载
CONFIG_KSU_SUSFS_ENABLE_LOG=y        # SUSFS 内核日志（调试用）
```

### 1.2 修复 AnyKernel3 刷机包

当前刷机包存在路径错乱问题，需要替换为官方 osm0sis AnyKernel3 标准模板。

#### 1.2.1 新增文件

| 文件 | 说明 |
|:----|:----|
| `anykernel3/anykernel3/anykernel.sh` | OnePlus 8T 专属刷机配置（设备型号、分区路径等） |
| `anykernel3/anykernel3/tools/ak3-core.sh` | 官方核心函数库（dump_boot、write_boot 等） |

#### 1.2.2 修改文件

| 文件 | 操作 | 说明 |
|:----|:----|:----|
| `scripts/build.sh` | 修改 | 移除 META-INF 复制 + 修正打包路径为纯 AK3 格式 |
| `.github/workflows/build-kernelsu-susfs.yml` | 修改 | 同步打包逻辑，移除手动 config echo，添加 SUSFS 配置 |
| `scripts/download_tools.sh` | 新增 | CI 环境下载 magiskboot + busybox |

#### 1.2.3 删除文件

| 文件 | 原因 |
|:----|:----|
| `anykernel3/META-INF/com/google/android/update-binary` | 旧的 AnyKernel2 格式，已被官方 anykernel.sh + ak3-core.sh 替代 |
| `anykernel3/META-INF/com/google/android/updater-script` | 同上 |
| `anykernel3/anykernel3/install.sh` | 被官方 anykernel.sh + ak3-core.sh 替代 |

### 1.3 推送编译

```bash
git add -A
git commit -m "fix: replace AnyKernel3 with official osm0sis template"
git push origin main
```

推送后 GitHub Actions 自动触发编译，耗时约 60-100 分钟。

---

## 阶段 2：刷入内核

### 前置条件

- 手机处于 LineageOS Recovery 模式（或已进入系统后重启到 Recovery）
- 电脑已安装 ADB 并能识别设备
- 已下载编译产出的 `kebab-kernelsu-susfs-a13-4.19-xxx.zip`

### 操作步骤

**步骤 1：进入 Recovery**

```bash
# 方法 A：从系统重启
adb reboot recovery

# 方法 B：手动按键
# 关机 → 按住 音量上 + 电源键 → 进入 Recovery
```

**步骤 2：进入 sideload 模式**

在 Recovery 主界面：
1. 选择 `Apply update`
2. 选择 `Apply from ADB`
3. 屏幕显示 `Starting ADB sideload...`

**步骤 3： sideload 刷入内核 zip**

```bash
adb -d sideload kebab-kernelsu-susfs-a13-4.19-xxx.zip
```

等待传输完成（约 10-30 秒），手机屏幕显示 `Installation complete`。

**步骤 4：重启系统**

```
Reboot system now
```

### 验证

重启后进入系统，打开终端执行：

```bash
adb shell
su -c "cat /proc/version"
```

应能看到包含 `KSU` 或 `SukiSU` 字样的内核版本信息。

---

## 阶段 3：安装 Root 环境

刷入自定义内核后，手机拥有了 KernelSU Root 能力，但还需要安装管理 App 和隐藏模块。

### 安装顺序（必须按顺序）

```
1. SukiSU Manager APK    → 管理 Root 权限
2. ZygiskNext 模块        → 提供 Zygisk 运行环境
3. Shamiko 模块           → 隐藏 Root 痕迹
4. SUSFS 模块             → SUSFS 用户空间配置
5. LSPosed 模块           → Xposed 框架
6. HMA 模块               → 隐藏 Root 应用列表
7. TrickyStore            → 绕过 Play Integrity
```

### 3.1 安装 SukiSU Manager

**下载：** https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases

```bash
# 安装 APK
adb install SukiSU-Manager-v4.1.3.apk

# 打开 Manager，确认显示 "KernelSU 已安装"
```

**配置 Manager：**

1. 进入 `设置` → `Root 权限`
2. 开启 `AllowList 模式`（白名单模式）
3. 只给需要的应用授予 Root 权限
4. 进入 `DenyList` → 添加所有检测类 App

### 3.2 安装 ZygiskNext

**下载：** https://github.com/Dr-TSNG/ZygiskNext/releases

```bash
# 方法 A：通过 Manager 安装模块
# Manager → 模块 → 从存储安装 → 选择 ZygiskNext zip

# 方法 B：通过 ADB 推送后安装
adb push ZygiskNext-v1.4.2.zip /sdcard/Download/
# 然后在 Manager 中安装
```

**配置 ZygiskNext：**

1. Manager → 模块 → ZygiskNext → 设置
2. 开启 `Zygisk 功能`
3. 选择 `兼容模式`（推荐）

### 3.3 安装 Shamiko

**下载：** https://github.com/LSPosed/LSPosed.github.io/releases

```bash
adb push shamiko-414.zip /sdcard/Download/
# Manager → 模块 → 从存储安装 → shamiko-414.zip
```

**配置 Shamiko：**

1. Manager → 模块 → Shamiko → 设置
2. 开启 `隐藏 Root`
3. 开启 `隐藏 Zygisk`
4. 添加检测应用到隐藏列表

### 3.4 安装 SUSFS 模块

**下载：** https://github.com/sidex15/susfs4ksu-module/releases

```bash
adb push susfs4ksu-module-v1.5.5.zip /sdcard/Download/
# Manager → 模块 → 从存储安装
```

### 3.5 安装 LSPosed

**下载：** https://github.com/LSPosed/LSPosed/releases

```bash
adb push LSPosed-v1.9.4.zip /sdcard/Download/
# Manager → 模块 → 从存储安装
```

安装后重启手机。

### 3.6 安装 HMA（Hide My Applist）

**下载：** https://github.com/Dr-TSNG/Hide-My-Applist/releases

```bash
adb push HMA-v1.8.3.zip /sdcard/Download/
# Manager → 模块 → 从存储安装
```

**配置 HMA：**

1. 打开 HMA App
2. 添加需要隐藏的 Root 应用（如 KernelSU Manager、Shamiko 等）
3. 开启隐藏模式

### 3.7 安装 TrickyStore

**下载：** https://github.com/5ec1cff/TrickyStore/releases

```bash
adb push TrickyStore-v2.1.0.zip /sdcard/Download/
# Manager → 模块 → 从存储安装
```

**配置 TrickyStore：**

1. 打开 TrickyStore App
2. 选择 `设备证书模式`
3. 获取并存储设备证书
4. 开启 `Play Integrity 修复`

---

## 阶段 4：配置隐藏规则

### 4.1 KernelSU AllowList 配置

**原则：** 只有明确需要 Root 的应用才加入白名单，其余应用默认无 Root 权限。

```bash
# 在 Manager 中操作：
# 1. 进入 "应用管理"
# 2. 选择应用 → 开启 Root 权限
# 3. 或使用 DenyList 模式，只禁止检测类应用
```

**建议白名单应用：**
- Shell / Terminal
- 文件管理器（需要 Root 访问）
- 特定需要 Root 的工具

**建议 DenyList 应用：**
- 所有银行类 App
- 所有游戏类 App（可能检测 Root）
- 安全检测类工具（春秋、Hunter、牛头等）

### 4.2 SUSFS 隐藏路径配置

在 SUSFS 模块或 Manager 中添加以下隐藏规则：

```bash
# 隐藏 KernelSU 相关路径
/data/adb/ksu
/data/adb/modules
/data/user_de/0/me.weishu.exp

# 隐藏 Magisk 兼容路径（如果有）
/sbin/.magisk
/magisk

# 隐藏 Root 相关二进制文件
/system/bin/su
/system/xbin/su
/system/bin/ksud
```

### 4.3 SUSFS 隐藏挂载配置

```bash
# 隐藏以下挂载点
/data/adb/modules
/data/adb/ksu
/magisk  (如果存在)
```

### 4.4 Shamiko 配置

```bash
# 在 Shamiko 设置中：
1. 开启 "隐藏 Root"
2. 开启 "隐藏 Zygisk"
3. 开启 "隐藏所有 Magisk/KernelSU 痕迹"
4. 添加检测类应用到隐藏列表
```

---

## 阶段 5：逐一测试检测工具

### 测试方法

对每个检测工具执行以下操作：

```bash
# 1. 安装检测工具 APK
adb install <检测工具.apk>

# 2. 打开检测工具
# 3. 查看检测结果
# 4. 如果检测到 Root，调整配置后重新测试
# 5. 记录最终结果
```

### 测试记录表

| # | 检测工具 | 版本 | 检测结果 | 通过层级 | 备注 |
|:-:|:--------|:----:|:--------:|:-------:|:----|
| 1 | 春秋检测 | 2.8.2 | ❌ 未测试 | — | — |
| 2 | 最新版检测 | 最新 | ❌ 未测试 | — | — |
| 3 | Hunter | 6.52 | ❌ 未测试 | — | — |
| 4 | 牛头32 | 32 | ❌ 未测试 | — | — |
| 5 | Momo | 最新 | ❌ 未测试 | — | — |
| 6 | RuRu | 最新 | ❌ 未测试 | — | — |
| 7 | Applist Detector | 最新 | ❌ 未测试 | — | — |
| 8 | 放大镜 | 最新 | ❌ 未测试 | — | — |
| 9 | 密钥认证 | 最新 | ❌ 未测试 | — | — |
| 10 | 应用列表检测器 | 最新 | ❌ 未测试 | — | — |
| 11 | Luna | 最新 | ❌ 未测试 | — | — |
| 12 | Holmes | 最新 | ❌ 未测试 | — | — |

### 常见检测点与对应解决方案

| 检测点 | 检测内容 | SUSFS | Shamiko | HMA | LSPosed |
|:-------|:--------|:-----:|:-------:|:---:|:-------:|
| /proc/self/maps | 检查 su、ksu 相关映射 | ✅ SUS_MAPS | — | — | — |
| /proc/mounts | 检查 magisk/ksu 挂载 | ✅ SUS_MOUNT | — | — | — |
| /proc/kallsyms | 检查 ksu 内核符号 | ✅ HIDE_SYMBOLS | — | — | — |
| /proc/version | 检查内核版本 | ✅ SPOOF_UNAME | — | — | — |
| /proc/self/fd | 检查 zygisk 文件描述符 | ✅ SUS_PROC_FD_LINK | — | — | — |
| /system/bin/su | 检查 su 二进制文件 | ✅ SUS_PATH | — | — | — |
| 应用列表 | 检查已安装的 Root 应用 | — | — | ✅ HMA | — |
| Zygisk 进程 | 检查 zygisk 相关进程 | — | ✅ 隐藏 | — | — |
| SELinux 状态 | 检查 SELinux 模式 | — | ✅ 伪装 | — | ✅ |
| Boot 验证 | 检查 boot 镜像签名 | — | — | — | ✅ TrickyStore |

---

## SUSFS 能力与检测项对照表

### 当前已启用的 SUSFS 能力

| 能力 | 内核配置 | 作用 |
|:----|:--------|:----|
| SUS_PATH | `CONFIG_KSU_SUSFS_SUS_PATH=y` | 隐藏特定文件/目录路径 |
| SUS_MOUNT | `CONFIG_KSU_SUSFS_SUS_MOUNT=y` | 隐藏挂载点 |
| SUS_KSTAT | `CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSTAT=y` | 自动隐藏文件统计信息 |
| HIDE_SYMBOLS | `CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y` | 隐藏内核符号 |
| AUTO_ADD_SUS_MOUNT | `CONFIG_KSU_SUSFS_AUTO_ADD_SUS_MOUNT=y` | 自动添加隐藏挂载 |

### 需要新增的 SUSFS 能力

| 能力 | 内核配置 | 作用 | 对应检测 |
|:----|:--------|:----|:---------|
| SUS_MAPS | `CONFIG_KSU_SUSFS_SUS_MAPS=y` | 伪造 /proc/self/maps | Momo、Hunter、Luna、RuRu |
| SPOOF_UNAME | `CONFIG_KSU_SUSFS_SPOOF_UNAME=y` | 伪造内核版本 | 部分内核版本检测 |
| SUS_PROC_FD_LINK | `CONFIG_KSU_SUSFS_SUS_PROC_FD_LINK=y` | 伪造 /proc/self/fd | Holmes、密钥认证 |
| TRY_UMOUNT | `CONFIG_KSU_SUSFS_TRY_UMOUNT=y` | 自动卸载隐藏路径 | 通用增强 |
| ENABLE_LOG | `CONFIG_KSU_SUSFS_ENABLE_LOG=y` | 内核日志调试 | 调试用 |

---

## 软件下载清单

### 阶段 1：编译相关

| 组件 | 版本 | 来源 | 用途 |
|:----|:----:|:----|:----|
| LineageOS 20 内核源码 | lineage-20 | https://github.com/LineageOS/android_kernel_oneplus_sm8250 | 编译基础 |
| SukiSU-Ultra | v4.1.3 builtin | https://github.com/SukiSU-Ultra/SukiSU-Ultra | KernelSU 内核补丁 |
| SUSFS | master | https://gitlab.com/simonpunk/susfs4ksu | SUSFS 内核补丁 |

### 阶段 3：Root 环境 + 隐藏模块

| 组件 | 版本 | 来源 | 用途 |
|:----|:----:|:----|:----|
| SukiSU Manager | v4.1.3+ | https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases | Root 管理 |
| ZygiskNext | v1.4.2+ | https://github.com/Dr-TSNG/ZygiskNext/releases | Zygisk 环境 |
| Shamiko | v1.2.5+ | https://github.com/LSPosed/LSPosed.github.io/releases | Root 隐藏 |
| SUSFS 模块 | v1.3.8+ | https://github.com/sidex15/susfs4ksu-module/releases | SUSFS 配置 |
| LSPosed | v1.9.4+ | https://github.com/LSPosed/LSPosed/releases | Xposed 框架 |
| HMA | v1.8.3+ | https://github.com/Dr-TSNG/Hide-My-Applist/releases | 应用列表隐藏 |
| TrickyStore | v2.1.0+ | https://github.com/5ec1cff/TrickyStore/releases | Play Integrity |

### 阶段 5：检测测试工具

| 工具 | 用途 |
|:----|:----|
| 春秋检测 2.8.2 | Root 检测 |
| Hunter 6.52 | Root 检测 |
| 牛头32 | Root 检测 |
| Momo | Root 检测 |
| RuRu | Root 检测 |
| Applist Detector | 应用列表检测 |
| 放大镜 | 系统信息检测 |
| 密钥认证 | 安全认证检测 |
| 应用列表检测器 | 应用列表检测 |
| Luna | Root 检测 |
| Holmes | Root 检测 |

---

## 风险与恢复方案

### 风险矩阵

| 风险 | 概率 | 严重程度 | 应对方案 |
|:----|:----:|:--------:|:---------|
| 编译失败 | 🟡 中 | 🟢 低 | GitHub Actions 显示错误，修复后重新编译 |
| 刷入后 bootloop | 🟡 中 | 🟡 中 | Recovery → 重新 sideload 原版 ROM → 恢复 |
| 刷完后部分功能失效 | 🟡 中 | 🟡 中 | 检查 dtbo、重新刷入 |
| 变砖（硬砖） | 🟢 极低 | 🔴 高 | OnePlus 8T 有 EDL 恢复模式，极难变砖 |
| 检测工具无法绕过 | 🟡 中 | 🟡 中 | 调整隐藏配置，更新模块版本 |

### Bootloop 恢复方案

如果刷入自定义内核后手机无法开机：

```bash
# 1. 进入 Recovery（音量上 + 电源键）

# 2. 重新 sideload 原版 LineageOS ROM
adb -d sideload lineage-20.0-20240209-nightly-kebab-signed.zip

# 3. 重启 → 恢复原状（不丢失刷机前的数据分区）
```

### Recovery 损坏恢复方案

如果 Recovery 也损坏：

```bash
# 1. 进入 Fastboot 模式（音量下 + 电源键）

# 2. 重新刷入 Recovery
fastboot flash recovery /path/to/recovery.img

# 3. 重新刷入 dtbo 和 vbmeta
fastboot flash dtbo /path/to/dtbo.img
fastboot flash vbmeta /path/to/vbmeta.img

# 4. 重启到 Recovery
fastboot reboot recovery
```

### 数据备份建议

在每次刷入新内核前，建议备份：

```bash
# 备份当前 boot 分区（从手机 dump）
adb shell "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot-backup.img"

# 推送到电脑
adb pull /sdcard/boot-backup.img ./boot-backup.img
```

---

## 常见问题排查

### Q1：刷入内核后无法开机

**可能原因：**
- 内核编译有错误
- SUSFS 补丁与内核源码不兼容
- dtbo 不匹配

**解决：**
1. 进入 Recovery
2. sideload 原版 LineageOS ROM
3. 重启后检查内核版本：`adb shell cat /proc/version`

### Q2：Root 权限不生效

**检查步骤：**
1. 打开 SukiSU Manager → 确认显示 "KernelSU 已安装"
2. 检查 AllowList 中是否有需要 Root 的应用
3. 确认应用已请求 Root 权限并被允许

```bash
# 验证 Root
adb shell
su -c "id"
# 应显示 uid=0(root)
```

### Q3：检测工具仍然检测到 Root

**排查顺序：**

1. **SUSFS 内核层：**
   ```bash
   adb shell
   su -c "cat /sys/module/susfs/status"
   # 确认 SUSFS 已加载
   ```

2. **Shamiko 是否生效：**
   - 打开 Shamiko App → 确认状态为"运行中"
   - 检查隐藏列表是否包含检测工具

3. **应用列表是否隐藏：**
   - 打开 HMA → 确认 Root 应用已在隐藏列表中

4. **逐步调整：**
   - 先确保 SUSFS 内核层生效
   - 再确保 Shamiko 生效
   - 最后确保 HMA 生效

### Q4：SUSFS 模块无法安装

**可能原因：**
- KernelSU Manager 版本过低
- 模块 zip 版本不匹配

**解决：**
1. 更新 KernelSU Manager 到最新版
2. 下载对应 SUSFS 版本的模块
3. 重启后重试

### Q5：ZygiskNext 无法启动

**检查：**
1. KernelSU 版本 ≥ 10940
2. KernelSU Manager 版本 ≥ 11575
3. 确认没有其他 Root 实现（Magisk/APatch）
4. 重启手机

---

## 附录 A：文件结构

```
/Users/weifeng/Downloads/OnePlus8T/
├── anykernel3/                                     # 刷机包模板（staging）
│   ├── anykernel.sh                                # 设备刷机配置（复制到 zip 根目录）
│   ├── tools/                                      # 刷机工具（复制到 zip 内 tools/）
│   │   ├── ak3-core.sh                             # 核心函数库
│   │   ├── magiskboot                              # boot 镜像工具
│   │   └── busybox                                 # POSIX 工具集
│   └── modules/                                    # 内核模块（构建后填充）
├── kernel-patches/                                 # SUSFS 兼容层
│   ├── ksu.config                                  # KernelSU 配置（单一配置源）
│   ├── susfs_compat.h                              # SUSFS 兼容头文件
│   ├── susfs_compat.c                              # SUSFS 兼容源文件
│   └── susfs_def.h                                 # SUSFS 默认定义
├── scripts/                                        # 构建脚本
│   ├── build.sh                                    # 主构建脚本
│   └── download_tools.sh                           # CI 工具下载脚本
├── .github/workflows/                              # CI 配置
│   └── build-kernelsu-susfs.yml                    # GitHub Actions 工作流
├── README.md                                       # 项目说明
├── OnePlus8T_LineageOS20_刷机指南.md               # LineageOS 刷机指南
└── OnePlus8T_KernelSU_SUSFS_隐藏方案.md            # 本文件
```

---

## 附录 B：关键命令速查

### 编译相关

```bash
# 本地编译（需要 Linux 环境）
bash scripts/build.sh

# 查看 CI 编译状态
# 浏览器打开：https://github.com/qcxl/oneplus8t-kernelsu-susfs/actions

# 下载编译产物
# Actions → 最新运行 → Artifacts → 下载 zip
```

### 刷机相关

```bash
# 进入 Fastboot
adb reboot bootloader

# 进入 Recovery
adb reboot recovery

# sideload 刷入内核
adb -d sideload kebab-kernelsu-susfs-a13-4.19-xxx.zip

# 验证内核版本
adb shell cat /proc/version

# 验证 Root
adb shell su -c "id"
```

### 模块管理

```bash
# 推送模块到手机
adb push <module.zip> /sdcard/Download/

# 安装 APK
adb install <app.apk>

# 查看已安装模块
adb shell ls /data/adb/modules/
```

---

## 附录 C：参考资源

| 资源 | 链接 |
|:----|:----|
| KernelSU 官方文档 | https://kernelsu.org |
| SUSFS 官方仓库 | https://gitlab.com/simonpunk/susfs4ksu |
| SukiSU-Ultra | https://github.com/SukiSU-Ultra/SukiSU-Ultra |
| ZygiskNext | https://github.com/Dr-TSNG/ZygiskNext |
| Shamiko | https://github.com/LSPosed/LSPosed.github.io/releases |
| HMA (Hide My Applist) | https://github.com/Dr-TSNG/Hide-My-Applist |
| LSPosed | https://github.com/LSPosed/LSPosed |
| TrickyStore | https://github.com/5ec1cff/TrickyStore |
| SUSFS 模块 | https://github.com/sidex15/susfs4ksu-module |
| osm0sis AnyKernel3 | https://github.com/osm0sis/AnyKernel3 |

---

## 附录 D：SUSFS 内核配置详解

当前内核中启用的所有 SUSFS 相关配置：

| 配置项 | 值 | 说明 |
|:-------|:-:|:----|
| CONFIG_KSU | y | 启用 KernelSU |
| CONFIG_KSU_SUSFS | y | 启用 SUSFS |
| CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT | y | 支持 Magic Mount |
| CONFIG_KSU_SUSFS_SUS_PATH | y | 隐藏可疑路径 |
| CONFIG_KSU_SUSFS_SUS_MOUNT | y | 隐藏可疑挂载 |
| CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSTAT | y | 自动添加 kstat 隐藏 |
| CONFIG_KSU_SUSFS_AUTO_ADD_SUS_MOUNT | y | 自动添加挂载隐藏 |
| CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS | y | 隐藏 KSU/SUSFS 内核符号 |
| CONFIG_KSU_MANUAL_HOOK | y | 手动 Hook（非 GKI 必需） |
| CONFIG_KSU_ALLOWLIST_MODE | y | AllowList 模式 |
| CONFIG_KSU_VERIFY_SUSFS | y | 验证 SUSFS 集成 |
| CONFIG_KPM | n | 禁用 KPM（非 GKI 设备） |
| CONFIG_KSU_SUSFS_SUS_MAPS | y | 伪造 /proc/self/maps |
| CONFIG_KSU_SUSFS_SPOOF_UNAME | y | 伪造内核版本 |
| CONFIG_KSU_SUSFS_SUS_PROC_FD_LINK | y | 伪造 /proc/self/fd |
| CONFIG_KSU_SUSFS_TRY_UMOUNT | y | 尝试卸载隐藏路径 |
| CONFIG_KSU_SUSFS_ENABLE_LOG | y | 启用 SUSFS 日志 |

---

*文档生成日期：2026-06-25*
*最后更新：2026-06-25*

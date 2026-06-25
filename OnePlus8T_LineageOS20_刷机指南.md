# OnePlus 8T (kebab) LineageOS 20 刷机指南

> **ROM 版本**: LineageOS 20.0 (Android 13)  
> **Build ID**: 17372 (2024-02-09)  
> **设备**: OnePlus 8T (kebab / SM8250)  
> **适用型号**: KB2000 / KB2001 / KB2003 / KB2005  
> **编写日期**: 2026-06-25  

---

## 目录

- [1. 前置检查清单](#sec1)
- [2. 文件清单与校验](#sec2)
- [3. 环境准备](#sec3)
- [4. 解锁 Bootloader](#sec4)
- [5. 刷入 dtbo 和 vbmeta](#sec5)
- [6. 刷入 Recovery](#sec6)
- [7. 同步固件分区](#sec7)
- [8.  sideload 刷入 LineageOS 20](#sec8)
- [9. 首次启动配置](#sec9)
- [10. 验证安装](#sec10)
- [11. 常见问题排查](#sec11)
- [12. 下一步](#sec12)

---

## 1. 前置检查清单

### 1.1 设备要求

| 检查项 | 要求 | 你的状态 |
|--------|------|----------|
| 设备型号 | OnePlus 8T (KB2000 / KB2001 / KB2003 / KB2005) | ✅ KB2000 已确认 |
| 当前系统 | ColorOS 14 (Android 14) | 已知 |
| Bootloader 状态 | 未锁定（解锁后会清空数据） | 待确认 |
| ADB 连接 | macOS 已识别设备 | ✅ 已连接（序列号: 13cda54f） |
| USB 调试 | 已开启 | ✅ 已确认 |
| OEM 解锁 | 已开启 | ✅ 已确认 |

### 1.2 数据备份

**⚠️ 重要警告：解锁 bootloader 会清空设备上的所有数据！**

请确认以下数据已备份：

- [ ] 照片和视频（建议备份到电脑或云盘）
- [ ] 联系人（导出为 .vcf 文件或同步到 Google 账户）
- [ ] 短信（使用 SMS Backup & Restore 等应用）
- [ ] 应用数据（如有重要数据，使用对应应用的导出功能）
- [ ] 微信/QQ 聊天记录（使用官方备份功能）
- [ ] 其他重要文件

### 1.3 电脑准备

- [ ] macOS 13.7.8 (22H730) 已知
- [ ] USB 数据线（建议使用原装或质量好的线）
- [ ] 至少 5GB 可用磁盘空间

### 1.4 手机设置

需要在 ColorOS 14 上开启以下选项：

**开启 USB 调试：**
1. 打开「设置」
2. 找到「关于手机」
3. 连续点击「版本号」7 次，开启开发者模式
4. 返回「设置」→「系统」→「开发者选项」
5. 开启「USB 调试」
6. 开启「OEM 解锁」（如果可用）

**移除 Google 账户：**
1. 打开「设置」→「密码与安全」
2. 移除所有已登录的 Google 账户
3. 这是为了防止 FRP（工厂重置保护）锁定

---

## 2. 文件清单与校验

### 2.1 已下载文件

以下文件已确认存在并通过校验：

| 文件 | 大小 | 存放位置 | SHA256 | 状态 |
|------|------|----------|--------|------|
| lineage-20.0-20240209-nightly-kebab-signed.zip | 1.0 GB | /Users/weifeng/Downloads/OnePlus8T/ | 6f67fc2066ad9f68706ab2c7b7c6b995510b805eec446aea006af99955478700 | 校验通过 |
| dtbo.img | 24 MB | extracted_20260625_093241/ | 6434d62613d4147d5b5842e65c1b4cbce9cbc57f2a029660c20cbd75f3358126 | 校验通过 |
| recovery.img | 96 MB | extracted_20260625_093241/ | 483cfbe00f214a2fd8ac4bfb4f6b06965d0b277d3bb582607ab7085963e710a0 | 校验通过 |
| vbmeta.img | 8 KB | extracted_20260625_093241/ | 1002f17f886b2449afa179925bda104bbfcbb5cf8069c81c852f98dd3faa0cda | 校验通过 |
| copy-partitions-20220613-signed.zip | 4 KB | /Users/weifeng/Downloads/OnePlus8T/ | 92f03b54dc029e9ca2b68858c14b649974838d73fdb006f9a07a503f2eddd2cd | 校验通过 |

### 2.2 各文件作用说明

**lineage-20.0-20240209-nightly-kebab-signed.zip**
- 作用：这是 LineageOS 20.0 的完整系统镜像包，包含 Android 13 系统、内核、应用等所有内容
- 格式：A/B 分区的 OTA payload 包，需要通过 Recovery 的 sideload 模式刷入
- 注意：不能直接解压，也不能直接用 fastboot 刷入

**recovery.img**
- 作用：Lineage Recovery，是一个专门的 Recovery 系统，用于在手机无法启动时进行系统修复和刷机操作
- 为什么需要：刷入 ROM 必须在 Recovery 模式下通过 sideload 完成，不能用 fastboot 直接刷系统
- 刷入位置：设备的 recovery 分区

**dtbo.img**
- 作用：Device Tree Blob Overlay，包含设备的硬件配置信息（屏幕参数、摄像头配置、传感器布局等）
- 为什么需要：启动时内核需要加载正确的设备树才能识别硬件
- 刷入位置：设备的 dtbo 分区

**vbmeta.img**
- 作用：Verified Boot Metadata，用于控制 Android 的启动验证机制（AVB）
- 为什么需要：刷入自定义 ROM 需要禁用验证，否则会阻止启动
- 刷入位置：设备的 vbmeta 分区

**copy-partitions-20220613-signed.zip**
- 作用：同步 A/B 分区的固件版本，确保备用分区的固件与主分区一致
- 为什么需要：OnePlus 8T 使用 A/B 分区，如果 inactive slot 的固件过旧，可能导致 bootloop 甚至变砖
- 刷入方式：在 Recovery 中 sideload 安装

---

## 3. 环境准备

### 3.1 确认 ADB 和 Fastboot 可用

你的 macOS 已安装 Android SDK Platform-Tools，包含 adb 和 fastboot。

**验证方法：**

1. 打开「终端」（Terminal）
2. 输入以下命令并回车：

```
adb version
```

3. 如果显示类似 Android Debug Bridge version 1.0.41，说明正常
4. 输入以下命令：

```
fastboot --version
```

5. 如果显示版本信息，说明正常

### 3.2 连接手机

1. 使用 USB 数据线连接 OnePlus 8T 和 Mac
2. 手机上弹出「允许 USB 调试？」对话框
3. 勾选「允许」并点击「确定」
4. 在终端输入：

```
adb devices
```

5. 如果显示 xxxxx device，说明连接成功
6. 如果显示 unauthorized，检查手机上的授权弹窗并重新插拔 USB 线

### 3.3 ADB 连接问题排查

在 macOS 上连接 ADB 时可能遇到以下问题，这里提供完整的排查步骤。

**问题 1：adb devices 显示空列表**

症状：执行 adb devices 后显示 `List of devices attached`，但下面没有设备信息。

可能原因：
- 手机未开启 USB 调试
- 手机未授权 ADB 连接
- USB 连接模式不正确
- macOS 缺少 USB 访问权限

解决方案：

1. 确认手机已开启 USB 调试（参考 1.4 节）
2. 确认手机已开启 OEM 解锁（参考 1.4 节）
3. 从手机屏幕顶部下拉通知栏，找到 USB 连接通知
4. 点击通知，选择「文件传输」或「MIDI」模式
5. **不要选择「仅充电」**，该模式下 ADB 无法连接
6. 查看手机屏幕是否有「允许 USB 调试？」弹窗，如果有则点击「允许」
7. 在终端执行：
   ```
   adb kill-server
   adb start-server
   adb devices -l
   ```

**问题 2：ADB server didn't ACK / LIBUSB_ERROR_ACCESS**

症状：执行 adb start-server 时显示错误：
```
ADB server didn't ACK
failed to claim adb interface for device '13cda54f': LIBUSB_ERROR_ACCESS
```

可能原因：
- macOS 阻止了 ADB 访问 USB 设备
- 端口 5037 被占用
- 需要管理员权限

解决方案：

1. 完全关闭 ADB 服务：
   ```
   sudo killall -9 adb
   sudo killall -9 adb-server
   ```

2. 检查端口是否释放：
   ```
   lsof -i :5037
   ```

3. 拔掉 USB 线，等待 5 秒后重新插上

4. 解锁手机屏幕，查看是否有 ADB 授权弹窗并点击「允许」

5. 检查 macOS 权限设置：
   - 打开「系统设置」→「隐私与安全性」
   - 向下滚动找到「开发者工具」
   - 确认「终端」（Terminal）已开启
   - 如果没有终端选项，执行一次 adb devices，系统会弹出权限请求，点击「允许」

6. 使用管理员权限启动 ADB：
   ```
   sudo adb start-server
   sudo adb devices -l
   ```

7. 如果仍然失败，尝试重启电脑后重试

**问题 3：adb devices 显示 unauthorized**

症状：执行 adb devices 后显示设备但状态为 unauthorized。

解决方案：
1. 查看手机屏幕上的授权弹窗
2. 点击「允许」或「确定」
3. 建议勾选「始终允许」以避免重复授权
4. 如果弹窗消失，可以重新插拔 USB 线触发弹窗
5. 执行 adb kill-server 和 adb start-server 重启服务

**成功连接的标志：**

当 ADB 连接成功时，执行 adb devices -l 会显示类似以下内容：
```
List of devices attached
13cda54f  device usb:20-5.2 product:OnePlus8T_CH model:KB2000 device:OnePlus8T transport_id:1
```

其中：
- 第一列是设备序列号
- 第二列是状态（device 表示正常连接）
- 后续是设备详细信息

---

## 4. 解锁 Bootloader

### 4.1 什么是 Bootloader？

Bootloader 是手机启动时第一个运行的程序，它负责加载操作系统。默认情况下，OnePlus 的 Bootloader 是锁定的，只允许运行官方签名的系统。解锁 Bootloader 后才能安装自定义 ROM。

### 4.2 解锁步骤

**步骤 1：进入 Fastboot 模式**

1. 手机完全关机（长按电源键，选择「关机」）
2. 关机后，同时按住 音量上键 + 音量下键 + 电源键
3. 保持按住直到进入 Fastboot 模式（屏幕显示 FASTBOOT 字样）
4. 或者使用 ADB 命令进入：

```
adb reboot bootloader
```

**步骤 2：验证 Fastboot 连接**

1. 在终端输入：

```
fastboot devices
```

2. 如果显示设备序列号，说明 Mac 已识别手机
3. 如果无输出，尝试：
   - 更换 USB 端口
   - 使用原装数据线
   - 在终端前加 sudo（需要输入 Mac 密码）

**步骤 3：执行解锁**

1. 在终端输入以下命令：

```
fastboot oem unlock
```

2. 手机屏幕上会出现警告提示
3. 使用音量键选择「Yes」或「解锁 Bootloader」
4. 按电源键确认
5. 手机会自动重启并恢复出厂设置

**步骤 4：等待重启完成**

1. 解锁过程约 1-2 分钟
2. 手机会自动重启到初始设置界面
3. 此时手机数据已被清空，需要重新设置

### 4.3 解锁后重新设置

1. 进入初始设置界面（选择语言、WiFi 等）
2. 不要登录 Google 账户（防止 FRP）
3. 重新开启开发者选项和 USB 调试（同 1.4 节）
4. 重新连接电脑，确认 adb devices 能识别

---

## 5. 刷入 dtbo 和 vbmeta

### 5.1 进入 Fastboot 模式

1. 手机完全关机
2. 同时按住 音量上键 + 音量下键 + 电源键
3. 进入 Fastboot 模式

### 5.2 刷入 dtbo.img

**作用**: 设备树覆盖，包含硬件配置信息

1. 在终端执行：

```
fastboot flash dtbo /Users/weifeng/Downloads/OnePlus8T/extracted_20260625_093241/dtbo.img
```

2. 等待显示 Finished 或 OKAY

### 5.3 刷入 vbmeta.img

**作用**: 禁用启动验证，允许自定义 ROM 启动

1. 在终端执行：

```
fastboot flash vbmeta /Users/weifeng/Downloads/OnePlus8T/extracted_20260625_093241/vbmeta.img
```

2. 等待显示 Finished 或 OKAY

### 5.4 重启到 Fastboot

1. 执行：

```
fastboot reboot bootloader
```

2. 等待手机重启回 Fastboot 模式

---

## 6. 刷入 Recovery

### 6.1 刷入 Recovery.img

**作用**: 安装 Lineage Recovery，用于后续 sideload 刷机

1. 确保手机在 Fastboot 模式
2. 在终端执行：

```
fastboot flash recovery /Users/weifeng/Downloads/OnePlus8T/extracted_20260625_093241/recovery.img
```

3. 等待显示 Finished 或 OKAY

### 6.2 进入 Recovery 模式

**方法一：使用 Fastboot 命令**
1. 执行：

```
fastboot reboot recovery
```

**方法二：按键组合**
1. 手机关机
2. 同时按住 音量上键 + 电源键
3. 进入 Recovery 模式

### 6.3 验证 Recovery

1. 进入 Recovery 后，应看到 LineageOS 的 Recovery 界面（有 Android 机器人图标或 LineageOS logo）
2. 如果显示其他 Recovery（如 TWRP），说明刷入了错误的 Recovery
3. 重新执行 6.1 步骤确保刷入正确

---

## 7. 同步固件分区

### 7.1 什么是 copy-partitions？

OnePlus 8T 使用 A/B 分区系统，有两个系统分区（slot A 和 slot B）。copy-partitions 工具会将当前活跃分区的固件复制到非活跃分区，确保两个分区的固件版本一致，防止 bootloop。

### 7.2 进入 Sideload 模式

1. 在 Recovery 主界面
2. 使用音量键选择「Apply update」
3. 按电源键确认
4. 选择「Apply from ADB」
5. 此时屏幕显示「Starting ADB sideload...」

### 7.3  Sideload 安装 copy-partitions

1. 在 Mac 终端执行：

```
adb -d sideload /Users/weifeng/Downloads/OnePlus8T/copy-partitions-20220613-signed.zip
```

2. 等待传输完成（约几秒）
3. 手机屏幕显示「Installation complete」或类似提示
4. 选择「Reboot to recovery」或「Advanced」→「Reboot to recovery」

### 7.4 重新进入 Recovery

1. 确保手机回到 Recovery 主界面
2. 如果自动重启了系统，需要重新进入 Recovery：
   - 关机
   - 按住音量上键 + 电源键

### 7.5 重要提示：安装 copy-partitions 后必须重启 Recovery

**⚠️ 关键步骤：安装 copy-partitions 后，必须重启 Recovery 才能继续安装 ROM。**

原因：copy-partitions 会修改分区映射，Recovery 需要重启才能识别新的分区布局。

操作：
1. 在 Recovery 中选择「Advanced」→「Reboot to recovery」
2. 等待手机重启回 Recovery 主界面
3. 确认回到 Recovery 主界面后再继续下一步

**如果跳过此步骤，直接 sideload ROM 会报错：**
```
ERROR: recover: Logical partions are mapped
Please reboot recovery before installing an OTA update.
Install completed with status 1.
Installation aborted.
```

---

## 8.  Sideload 刷入 LineageOS 20

### 8.1 进入 Sideload 模式

1. 在 Recovery 主界面
2. 选择「Factory Reset」
3. 选择「Format data / factory reset」
4. 确认格式化（这会清除内部存储所有数据）
5. 等待格式化完成
6. 返回主界面
7. 选择「Apply update」→「Apply from ADB」
8. 屏幕显示「Starting ADB sideload...」

### 8.2  Sideload 刷入 ROM

1. 在 Mac 终端执行：

```
adb -d sideload /Users/weifeng/Downloads/OnePlus8T/lineage-20.0-20240209-nightly-kebab-signed.zip
```

2. 等待传输完成（约 10-15 分钟，取决于 USB 速度）
3. 终端会显示传输进度

**⚠️ 重要提示：**
- **不要中断 USB 连接**
- **不要关闭终端窗口**
- **不要操作手机**
- 即使显示进度卡住，也请耐心等待

### 8.3  Sideload 完成后的处理

1. 传输完成后，终端会显示结果
2. 手机屏幕可能显示：
   - 「Signature verification failed」→ 点击「Yes」（这是正常的，因为是非官方构建）
   - 「Installation complete」→ 说明刷入成功
3. **不要点击「Reboot system now」**
4. 选择「Go back」返回主界面

### 8.4 重启后进入系统

1. 在 Recovery 主界面选择「Reboot system now」
2. 手机开始启动 LineageOS

**如果手机提示「Do you want to reboot to recovery now?」：**
- 选择 **No**（如果你不需要安装其他 add-ons）
- 然后在 Recovery 主界面选择「Reboot system now」

**如果手机提示「Reboot to recovery」：**
- 选择「Reboot to recovery」回到 Recovery 主界面
- 然后选择「Reboot system now」

### 8.5 可选：安装 Google Apps

如果你需要 Google 服务框架：

1. 下载对应 A13 的 GApps 包（MindTheGapps 13.0 ARM64）
2. 在 Recovery 中选择「Apply update」→「Apply from ADB」
3. 执行：

```
adb -d sideload /path/to/gapps.zip
```

4. 注意：GApps 必须在首次启动前安装，否则可能导致系统问题

---

## 9. 首次启动配置

### 9.1 重启到系统

1. 在 Recovery 主界面
2. 选择「Reboot system now」
3. 手机开始启动 LineageOS

### 9.2 首次启动时间

**首次启动需要 5-15 分钟**，请耐心等待：
- 会出现 LineageOS logo
- 可能多次重启
- 进入系统后可能还需要优化应用

### 9.3 初始设置

1. **选择语言**：简体中文
2. **连接 WiFi**：必须连接 WiFi 进行后续设置
3. **日期和时间**：自动设置
4. **屏幕锁定**：建议设置 PIN 码或图案
5. **关于手机**：查看系统信息

---

## 10. 验证安装

### 10.1 检查系统信息

1. 打开「设置」→「关于手机」
2. 确认以下信息：
   - **LineageOS 版本**: 20.0
   - **Android 版本**: 13
   - **安全补丁级别**: 2024-02-05 左右
   - **内核版本**: 4.19.x

### 10.2 检查设备功能

| 功能 | 检查方法 | 预期结果 |
|------|----------|----------|
| 触摸屏 | 点击屏幕各位置 | 响应正常 |
| 按钮 | 音量键、电源键 | 正常响应 |
| WiFi | 连接 WiFi 网络 | 正常连接 |
| 移动网络 | 插入 SIM 卡，拨打电话 | 正常通话 |
| 蓝牙 | 开启蓝牙，搜索设备 | 正常搜索 |
| 摄像头 | 打开相机应用 | 正常拍照 |
| 指纹 | 录入指纹，解锁测试 | 正常识别 |
| NFC | 开启 NFC，测试支付 | 正常识别（如有） |
| 振动马达 | 开启振动，测试反馈 | 正常振动 |

### 10.3 检查存储

1. 打开「设置」→「存储」
2. 确认：
   - 系统分区大小约 3.5GB
   - 内部存储空间正确显示
   - 没有异常占用

---

## 11. 常见问题排查

### 11.1 刷机过程中出现错误

**问题：fastboot 命令无输出或报错**

解决方案：
1. 重新插拔 USB 线
2. 尝试不同的 USB 端口
3. 在命令前加 sudo（需要输入 Mac 密码）
4. 确保手机处于 Fastboot 模式

**问题：adb sideload 传输失败**

解决方案：
1. 检查 USB 连接稳定性
2. 重新执行 sideload 命令
3. 确保文件路径正确（建议将文件复制到简单路径如 ~/Downloads/）

**问题：Signature verification failed**

解决方案：
- 这是正常现象，点击「Yes」继续
- 非官方构建都会出现此提示

### 11.2 启动问题

**问题：手机卡在 bootloop（无限重启）**

解决方案：
1. 进入 Recovery
2. 选择「Factory Reset」→「Format data」
3. 重新 sideload 刷入 ROM

**问题：卡在 Fastboot 模式无法启动**

解决方案：
1. 检查是否刷入了正确的 dtbo 和 vbmeta
2. 重新刷入 Recovery
3. 重新执行 copy-partitions

**问题：WiFi 无法开启**

解决方案：
1. 进入 Recovery，重新格式化 data
2. 检查是否刷入了正确的 dtbo.img

### 11.3 其他问题

**问题：手机发热严重**

解决方案：
- 首次启动时系统正在优化应用，发热是正常的
- 首次启动完成后会恢复正常

**问题：应用闪退**

解决方案：
- 首次启动后系统正在优化，建议等待 10-15 分钟
- 重启手机后再次尝试

### 11.4 实际刷机流程记录

以下是我们为 OnePlus 8T (KB2000) 实际刷入 LineageOS 20.0 (Build 17372) 的完整流程记录，包括遇到的问题和解决方案，供后续参考。

**刷机环境：**
- 设备：OnePlus 8T (KB2000)
- 当前系统：ColorOS 14 (Android 14)
- 电脑系统：macOS 13.7.8 (22H730)
- ADB 版本：1.0.41 (Platform-Tools 35.0.2)
- ROM 版本：LineageOS 20.0 (Android 13) Build 17372 (2024-02-09)

**完整刷机流程：**

1. 解锁 Bootloader
   - 开启 USB 调试和 OEM 解锁
   - 执行 adb reboot bootloader 进入 Fastboot 模式
   - 执行 fastboot oem unlock
   - 手机自动清除数据并重启

2. 刷入 dtbo.img
   - 执行 fastboot flash dtbo <path>/dtbo.img
   - 输出：Sending 'dtbo' (24576 KB) OKAY [ 0.621s]
   - 输出：Writing 'dtbo' OKAY [ 0.087s]
   - 输出：Finished. Total time: 0.789s

3. 刷入 vbmeta.img
   - 执行 fastboot flash vbmeta <path>/vbmeta.img
   - 输出：Sending 'vbmeta' (8 KB) OKAY [ 0.005s]
   - 输出：Writing 'vbmeta' OKAY [ 0.002s]
   - 输出：Finished. Total time: 0.091s

4. 重启到 Fastboot
   - 执行 fastboot reboot bootloader
   - 输出：Rebooting into bootloader OKAY [ 0.000s]

5. 刷入 Recovery.img
   - 执行 fastboot flash recovery <path>/recovery.img
   - 输出：Sending 'recovery' (102400 KB) OKAY [ 2.561s]
   - 输出：Writing 'recovery' OKAY [ 0.291s]
   - 输出：Finished. Total time: 3.369s

6. 进入 Recovery 模式
   - 执行 fastboot reboot recovery
   - 手机进入 LineageOS Recovery 界面

7. 同步固件分区 (copy-partitions)
   - 在 Recovery 中选择 Apply update → Apply from ADB
   - 执行 adb -d sideload copy-partitions-20220613-signed.zip
   - 输出：Install completed with status 0

8. 格式化数据 (Factory Reset)
   - 在 Recovery 中选择 Factory Reset → Format data / factory reset
   - 确认格式化，等待完成

9. 刷入 ROM
   - 在 Recovery 中选择 Apply update → Apply from ADB
   - 执行 adb -d sideload lineage-20.0-20240209-nightly-kebab-signed.zip
   - 输出：Step 1/2 完成，Step 2/2 完成
   - 手机提示：Do you want to reboot to recovery now?
   - 选择 No
   - 在 Recovery 主界面选择 Reboot system now

10. 首次启动
    - 等待 5-15 分钟
    - 进入 LineageOS 20 系统

**遇到的问题及解决方案：**

**问题 1：ADB 无法识别设备**

症状：执行 adb devices 后显示 `List of devices attached`，但下面没有设备信息。

错误信息：
```
ADB server didn't ACK
failed to claim adb interface for device '13cda54f': LIBUSB_ERROR_ACCESS
```

原因：macOS 阻止了 ADB 访问 USB 设备，需要管理员权限。

解决方案：
1. 执行 sudo killall -9 adb 关闭 ADB 进程
2. 执行 sudo adb start-server 使用管理员权限启动
3. 执行 sudo adb devices -l 查看设备
4. 检查 macOS 系统设置 → 隐私与安全性 → 开发者工具 → 终端，确保已开启
5. 确认手机已开启 USB 调试，并且授权弹窗已点击「允许」

**问题 2：sideload ROM 时提示 Logical partitions are mapped**

症状：执行 adb sideload ROM.zip 后，手机显示：
```
ERROR: recover: Logical partions are mapped
Please reboot recovery before installing an OTA update.
Install completed with status 1.
Installation aborted.
```

原因：安装 copy-partitions 后，Recovery 的分区状态发生了变化，需要重启 Recovery 才能识别新的分区映射。

解决方案：
1. 在 Recovery 中选择 Advanced → Reboot to recovery
2. 等待手机重启回 Recovery 界面
3. 重新选择 Apply update → Apply from ADB
4. 重新执行 adb sideload 命令
5. 这次会正常显示 Step 1/2 和 Step 2/2，完成安装

**问题 3：sideload 完成后选择 No 还是 Yes**

症状：ROM  sideload 完成后，手机提示：
```
Do you want to reboot to recovery now?
```

解决方案：
- 如果不需要安装其他 add-ons（如 GApps），选择 **No**
- 然后在 Recovery 主界面选择 Reboot system now
- 手机将重启到 LineageOS 系统

---

## 12. 下一步

### 12.1 基础配置

刷入 LineageOS 20 后，建议进行以下配置：

1. **开启开发者选项和 USB 调试**（用于后续调试）
2. **安装必要应用**（浏览器、文件管理器等）
3. **配置 Frida 环境**（用于逆向工程）

### 12.2 KernelSU + SUSFS 内核编译

根据你的需求，下一步是编译集成 KernelSU + SUSFS 的自定义内核：

**前置条件：**
- 稳定的 LineageOS 20 系统
- Linux 编译环境（Ubuntu 20.04+）
- 下载 LineageOS 20 内核源码

**编译步骤概要：**
1. 获取 LineageOS 20 内核源码（android_kernel_oneplus_sm8250，lineage-20 分支）
2. 集成 SukiSU-Ultra v4.1.3（builtin 分支）
3. 打 SUSFS kernel-4.19 补丁
4. 配置内核选项（CONFIG_KSU=y, CONFIG_KSU_SUSFS=y 等）
5. 编译生成 boot.img
6. 刷入 boot.img

### 12.3 隐藏检测方案

编译完内核后，配置以下工具实现隐藏：

- **Shamiko**: 隐藏 Root 和 KSU
- **TrickyStore**: 伪造 Google Play Integrity
- **ZygiskNext**: Zygisk 兼容层
- **LSPosed**: 模块化框架

---

## 附录 A：文件存放位置汇总

为了方便后续操作，所有文件应存放于以下位置：

```
/Users/weifeng/Downloads/OnePlus8T/
├── lineage-20.0-20240209-nightly-kebab-signed.zip  # ROM 文件
├── copy-partitions-20220613-signed.zip              # 分区同步工具
└── extracted_20260625_093241/
    ├── dtbo.img                                      # 设备树覆盖
    ├── recovery.img                                  # Lineage Recovery
    └── vbmeta.img                                    # 验证启动元数据
```

## 附录 B：命令速查表

| 步骤 | 命令 | 说明 |
|------|------|------|
| 进入 Fastboot | adb reboot bootloader | 从系统重启到 Fastboot 模式 |
| 验证连接 | fastboot devices | 检查 Mac 是否识别手机 |
| 解锁 Bootloader | fastboot oem unlock | 解锁 bootloader（会清空数据） |
| 刷入 dtbo | fastboot flash dtbo <path>/dtbo.img | 刷入设备树覆盖 |
| 刷入 vbmeta | fastboot flash vbmeta <path>/vbmeta.img | 刷入验证启动元数据 |
| 刷入 Recovery | fastboot flash recovery <path>/recovery.img | 刷入 Recovery |
| 重启 Recovery | fastboot reboot recovery | 重启到 Recovery 模式 |
| Sideload | adb -d sideload <path>/file.zip | 在 Recovery 中 sideload 文件 |
| 验证 ADB | adb devices | 检查 ADB 连接状态 |

## 附录 C：重要提示

1. **不要中断刷机过程**：刷机过程中不要关闭终端、不要拔 USB 线、不要操作手机
2. **数据已丢失**：解锁 Bootloader 会清空所有数据，这是正常现象
3. **耐心等待**：首次启动需要 5-15 分钟，请耐心等待
4. **保持电量**：刷机前确保手机电量至少 50% 以上
5. **备份重要数据**：虽然你已经备份，但以后刷机前仍需确认

---

**刷机有风险，操作需谨慎。如有问题请参考常见问题排查章节或联系社区支持。**

**刷机完成后，欢迎回来继续下一步：KernelSU + SUSFS 内核编译。**

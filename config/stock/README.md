# config/stock

`audio_device.xml` 是本仓库**唯一的设备侧构建输入**：`build-module.ps1` 从它生成
`module/system/vendor/etc/audio_device.xml`（只追加 4 行 `kctl`），并校验哈希、
逐字节可还原性与严格语义差异。

这个文件是目标设备上 `/vendor/etc/audio_device.xml` 的原样拷贝，内容与下面钉住的
上游文件**逐字节相同**（35521 字节）。

## 钉住的来源

| 项目 | 值 |
| --- | --- |
| 上游仓库 | https://github.com/LineageOS/android_device_xiaomi_earth |
| 上游 commit | `87007ad3e1ada83423abe0d560809b9a1c8ffda9`（"earth: Configure Audio stack"，2024-03-28） |
| 上游路径 | `configs/audio/audio_device.xml` |
| Raw URL | https://raw.githubusercontent.com/LineageOS/android_device_xiaomi_earth/87007ad3e1ada83423abe0d560809b9a1c8ffda9/configs/audio/audio_device.xml |
| Git blob | `0601191b039b0a31fadea6700d84b2c412e0f1c1` |
| 字节数 | 35521 |
| SHA256 | `0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba` |

本文件与上游文件相同，因此**没有**被本项目修改；修改只发生在构建产物
`module/system/vendor/etc/audio_device.xml` 中（见 `provenance/NOTICE-audio_device_xml.txt`）。

## 许可说明（重要）

- 上游 device tree 仓库**没有** `LICENSE` / `COPYING` / `NOTICE` 文件，
  GitHub 上该仓库的 license 字段为 `null`。
- 该仓库 LineageOS 21 分支 HEAD（`20fda9b252de46ed4a08a3d66ccfbb92178a8def`）的
  `README.md` 声明：

  ```
  Copyright (C) 2023 The LineageOS Project
  SPDX-License-Identifier: Apache-2.0
  ```

- `audio_device.xml` 文件本身**没有**逐文件的版权或许可头。
  因此这里的许可是**依据 device tree README 的声明**认定为 Apache-2.0，
  而不是"XML 文件里写着 SPDX"。Apache-2.0 全文见
  `provenance/upstream/LICENSE-APACHE-2.0.txt`。
- 本项目不是 LineageOS 官方发布，也**未获** LineageOS 项目背书。
- 根目录 `LICENSE`（GPL-3.0）**不覆盖**本文件；详见 `NOTICE.md`。

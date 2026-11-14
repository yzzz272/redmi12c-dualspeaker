# NOTICE

本仓库包含三个来源不同的部分。下面只做事实性说明，**不改变**任何上游文件自身的许可，
也不声称根目录的 `LICENSE` 覆盖全部内容。

## 1. 本项目自行编写的代码 —— GPL-3.0

包括 `build-module.ps1`、`module/customize.sh`、`tests/`、`.github/`、`docs/`、
`README.md`、`CHANGELOG.md`、`CONTRIBUTING.md`、`NOTICE.md`、`.gitignore`、
`.gitattributes`，以及 ZIP 内的 `updater-script` 与两个 `*.NOTICE.txt`。

- Copyright (C) 2026 earth_dual_speaker contributors
- License: GNU General Public License v3.0（全文见根目录 `LICENSE`）

## 2. Magisk 模块安装器（vendored，未修改）—— 上游 GPL-3.0

| 项目 | 值 |
| --- | --- |
| ZIP 内路径 | `META-INF/com/google/android/update-binary` |
| 上游项目 | Magisk（topjohnwu/Magisk） |
| 上游 ref | tag `v31.1`，commit `0972f67d97f9b6302b67c5171283330c74114b4a` |
| 上游文件 | `scripts/module_installer.sh` |
| SHA256 | `bcf4b1d9913f3af17755569c853e0b5a75b8005f6a18eb3f86dadcc0e968c29d` |
| 仓库内副本 | `provenance/upstream/module_installer.sh`（逐字节相同） |
| 许可文本 | `provenance/upstream/LICENSE-GPL-3.0.txt`（逐字节相同），ZIP 内为 `update-binary.LICENSE-GPL-3.0.txt` |
| 通知 | `provenance/NOTICE-module_installer.txt`，ZIP 内为 `update-binary.NOTICE.txt` |
| Copyright | Copyright (C) topjohnwu and Magisk contributors |

该文件按上游原样分发，**未做任何修改**；本模块的逻辑在 `customize.sh` 中，
由安装器 source 执行。

## 3. 设备 vendor 音频配置 —— 上游 Apache-2.0（依据 device tree README）

| 项目 | 值 |
| --- | --- |
| 仓库内路径 | `config/stock/audio_device.xml`（上游原样，未修改） |
| 上游仓库 | https://github.com/LineageOS/android_device_xiaomi_earth |
| 上游 commit | `87007ad3e1ada83423abe0d560809b9a1c8ffda9`（"earth: Configure Audio stack"，2024-03-28） |
| 上游路径 | `configs/audio/audio_device.xml` |
| Git blob | `0601191b039b0a31fadea6700d84b2c412e0f1c1` |
| SHA256 | `0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba`（35521 字节） |
| 生成副本 | `module/system/vendor/etc/audio_device.xml`，SHA256 `11334e073a7d35b0151f6d4b912caa07544b320b3a4a637b8e5be6d90b06e50c` |
| 许可文本 | `provenance/upstream/LICENSE-APACHE-2.0.txt`，ZIP 内为 `audio_device.xml.LICENSE-Apache-2.0.txt` |
| 修改通知 | `provenance/NOTICE-audio_device_xml.txt`，ZIP 内为 `audio_device.xml.NOTICE.txt` |

许可证据与限定：

- 上游 device tree 仓库**没有** `LICENSE` / `COPYING` / `NOTICE` 文件，
  GitHub API 报告的 license 为 `null`。
- 该仓库 LineageOS 21 分支 HEAD（`20fda9b252de46ed4a08a3d66ccfbb92178a8def`）的
  `README.md` 声明 `Copyright (C) 2023 The LineageOS Project` 与
  `SPDX-License-Identifier: Apache-2.0`。
- `audio_device.xml` 文件本身**没有**逐文件版权或许可头。
- 因此这里的 Apache-2.0 是**依据 device tree README 的声明**认定的，
  不能说成"该 XML 文件带有 SPDX 标识"。
- 本项目不是 LineageOS 官方发布，也**未获** LineageOS 项目背书。

修改内容（ZIP 内 `system/vendor/etc/audio_device.xml`，相对上游只追加 4 行）：

```text
speaker_output/turnon   + <kctl name="Handset_PGA_GAIN" value="4Db" />
                        + <kctl name="RCV Mux" value="Voice Playback" />
speaker_output/turnoff  + <kctl name="RCV Mux" value="Open" />
                        + <kctl name="Handset_PGA_GAIN" value="8Db" />
```

其余字节（含 XML 声明）逐字节保持不变；`build-module.ps1` 在差异不是这 4 行时会让构建失败。

## 许可范围小结

| 部分 | 许可 |
| --- | --- |
| 本项目自行编写的代码与文档 | GPL-3.0（根目录 `LICENSE`） |
| `META-INF/com/google/android/update-binary` 及其许可副本 | 上游 GPL-3.0，原样分发 |
| `config/stock/audio_device.xml` 与生成的覆盖 XML | 上游 Apache-2.0（依据 device tree README），原样 / 修改后分发，**不**由本仓库的 GPL-3.0 重新授权 |

根目录的 `LICENSE` 只覆盖第 1 部分。第 2、3 部分各自按其上游许可分发，
本仓库不声称 GPL-3.0 覆盖所有上游文件。

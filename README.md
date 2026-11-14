# earth 双扬声器实验模块（Redmi 12C / earth）

一个**实验性** Magisk 模块：用 systemless 覆盖 `/vendor/etc/audio_device.xml`，
让外放时听筒（receiver）和主扬声器一起出声，并把听筒增益**设为** `4Db`。

只改一个 XML 文件里的两条路径，其余内容逐字节保持不变。

> 这是一个小范围、单机验证过的实验，**不是**通用音质改造方案。
> 未验证左右声道分离，不承诺"iPhone 音质"或硬件安全，也没有后台常驻进程。

## AI 生成声明

本项目新增的适配补丁、`customize.sh`、构建与测试脚本、CI 配置及文档由 **AI 生成并整理**。
设备持有者提供了真机低音量试听与反馈；这些反馈不等于完整的人工代码审查或硬件安全验证。

Magisk 安装器、LineageOS 原始音频配置及其许可证来自上游，**并非 AI 原创**；
它们的来源、版权与许可声明继续保留，详见 [NOTICE.md](NOTICE.md) 和 [provenance/](provenance/)。

## 改了什么

`speaker_output` 路径（HAL 的外放路由；媒体/铃声/免提在选择该路径时会打开听筒）：

| 路径 | 原有 | 追加 |
| --- | --- | --- |
| `turnon` | `DAC In Mux=Normal Path`、`LOL Mux=Playback`（顺序不变） | `Handset_PGA_GAIN=4Db`、`RCV Mux=Voice Playback` |
| `turnoff` | `LOL Mux=Open`（不变） | `RCV Mux=Open`、`Handset_PGA_GAIN=8Db`（写回真机采集到的 mixer 默认值） |

关于 `+4dB` 的准确含义：

- 这是**设置值**，不是相对基线的偏移量。上游配置基线 `config/stock/audio_device.xml`
  里**没有** `Handset_PGA_GAIN` 这一项；`8Db` 是从真机 mixer/driver 采集到的默认值，
  不是基线文件里的字段。模块在 `speaker_output/turnon` 时把增益**设为** `4Db`，
  在 `turnoff` 时写回采集到的 `8Db`。
- 也就是说不要把它读成"在上游配置之上再 +4dB"。`4Db` 只是试听后接受的一个实验值，
  **不是安全评级**，也没有做最大音量、长时间、老化测试。

其他事实：

- 不改麦克风（`PGA L/R Mux`、`ADC L/R Mux` 完全没动）、不改音量表、不改 audio policy、
  不改 `receiver_output` / 耳机 / 外置功放路径。
- 没有开机脚本、没有后台轮询、没有 `service.sh`。安装脚本本身不写 mixer，
  增益由 HAL 在路由到 `speaker_output` 时按这份配置应用；关闭走 HAL 正常的
  speaker 路由关闭流程，不是定时器。
- **补丁挂在 HAL 的 `speaker_output` 路径上**：媒体、铃声、免提通话在选择该路径时都会
  同时打开听筒；具体组合（某些铃声/闹钟/通话场景是否走该路径）**未逐一测试**。
- 普通通话和耳机路径的 XML 文本**没有改动**，但实际行为**未测试**，不保证不受影响。

## 兼容性

安装脚本会在安装时逐项校验，任何一项不匹配都会打印原因并中止，不会覆盖真实 vendor 文件。

| 项目 | 要求 / 实测值 |
| --- | --- |
| 机型 | Redmi 12C，`ro.product.device` = `earth` |
| 系统 | Android 14（API 34） |
| ROM 版本 | `ro.lineage.version` = `21.0-20240509-UNOFFICIAL-earth`（LineageOS 21） |
| 内核 | `uname -r` 含 `e1d7983c7a49`（实测 `4.19.306-perf-07808-ge1d7983c7a49`） |
| Magisk | 实测 **31.1**（`31.1:MAGISKSU`）；其他版本**未测试** |
| vendor 配置 | `/vendor/etc/audio_device.xml` 的 SHA256 必须是 `0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba`（上游配置基线）或 `11334e073a7d35b0151f6d4b912caa07544b320b3a4a637b8e5be6d90b06e50c`（本模块打补丁后的值，允许同版本重装） |

其他 ROM、其他内核、其他机型都**不支持**，也不会自动适配。

## 安装

1. 从本仓库的 **Releases** 页面下载模块 ZIP（`earth-dual-speaker-v0.1.0-experimental.zip`）
   和同名 `.sha256` 校验值。
   **不要**下载 GitHub 自动生成的 "Source code (zip/tar.gz)"，那不是可安装的模块包。
2. 校验：`sha256sum earth-dual-speaker-v0.1.0-experimental.zip`
3. Magisk 应用 → 模块 → 从本地安装 → 选择该 ZIP。
4. **重启**后生效（模块不会自动重启手机）。
5. 卸载或禁用后同样要**重启**才回滚。

## 已测试 / 未测试

已测试（真机，一次性手动操作）：

- 保持原 `LOL Mux=Playback` 通路不变，手动设 `Handset_PGA_GAIN=4Db` + `RCV Mux=Voice Playback`，
  听筒出声、音量可接受。
- 仅一次短时试听，媒体音量 **3/15**。

未测试：

- **本模块 ZIP 在真机上的安装/卸载全流程**（仓库内只做了静态校验和模拟安装校验）
- 安装后的重启行为
- 最大音量、长时间播放、发热与器件寿命
- 通话（听筒/免提）、耳机插入、蓝牙
- 铃声、闹钟等具体路由组合

## 风险

- 听筒（DACL/RCV）和扬声器（DACR/LOL）是不同的通路，但共享部分模拟供电与时钟资源；
  长时间大音量仍可能损伤器件，风险自负。
- 左右声道分离**未验证**；不承诺"iPhone 音质"之类的效果，两只喇叭尺寸和位置本来就不同。
- 不承诺对硬件安全。

## 换系统前必须先移除

安装脚本的校验**只在安装时执行一次**，开机时不会再校验任何东西，
所以模块不会在系统变化后自动失效或自动适配。

**换 ROM、OTA 升级、换内核之前，先禁用或删除本模块并重启**，
否则旧的覆盖文件可能与新系统不匹配。

## 回滚

Magisk 应用里禁用或删除 `earth_dual_speaker` → 重启 → `/vendor` 恢复原样。
（systemless 覆盖，真实分区文件从未被修改。）

## 从源码构建

需要 **PowerShell 7+**（`pwsh`）。

- Windows 本机实测可用。
- Ubuntu GitHub Actions 的构建及 9 项安装守卫测试已通过：[首次运行记录](https://github.com/yzzz272/redmi12c-dualspeaker/actions/runs/43637935762)。这不等于完成了真机安装或硬件安全验证。
- macOS、其他 Linux 发行版等平台**未测试**。

```powershell
pwsh -File ./build-module.ps1
```

脚本会：从 `config/stock/audio_device.xml`（公开的基线输入）生成补丁 XML →
校验基线哈希、行尾（LF / 无 BOM）、XML 合法性、严格语义差异（只允许这 4 个 kctl 节点）、
逐字节可还原性 → 打包 `dist/earth-dual-speaker-v0.1.0-experimental.zip`
（无顶层目录、正斜杠路径、可复现）并写出 `.sha256`。

`module/system/vendor/etc/audio_device.xml` 是构建产物，但仍然提交在仓库里方便审阅。
构建脚本每次都会重新生成并校验它（哈希、语义差异、逐字节可还原）；
脚本本身**不会**把已提交的旧文件当作基线来比对（它直接覆盖），
所以"提交的副本是否过期"由 CI 的 `git diff --exit-code` 步骤检测。

安装脚本的守卫逻辑有独立的免 root 测试（bash，Git Bash 也可以）：

```bash
bash tests/test-installer.sh
```

仓库结构：

```text
config/stock/audio_device.xml   公开的基线输入（构建的唯一设备输入）
module/                         模块内容（customize.sh、module.prop、生成的 XML）
build-module.ps1                构建脚本（PowerShell 7）
tests/test-installer.sh         安装守卫测试（bash，无需 root/真机）
provenance/                     上游来源、哈希与许可信息
LICENSE / NOTICE.md             许可文本与三部分许可范围说明
docs/                           发布、测试、发布说明
.github/workflows/              CI（构建 + 测试 + 草稿预发布）
```

## 许可证与来源

本仓库分三部分，各自许可不同，根目录 `LICENSE`（GPL-3.0）**只覆盖第一部分**。

- **本项目自行编写的代码**（构建脚本、`customize.sh`、测试、文档、CI 配置、
  ZIP 内的 `updater-script` 与两个 `*.NOTICE.txt`）：GNU General Public License v3.0，
  见 `LICENSE`。
- **Magisk 模块安装器**：`META-INF/com/google/android/update-binary` 是 Magisk 上游
  `scripts/module_installer.sh` 的**原样拷贝**（GPL-3.0，commit
  `0972f67d97f9b6302b67c5171283330c74114b4a`），来源与哈希见 `provenance/`，
  许可文本与通知随 ZIP 一起分发。
- **设备 vendor 音频配置**：`config/stock/audio_device.xml` 是 LineageOS device tree
  `LineageOS/android_device_xiaomi_earth` 在 commit
  `87007ad3e1ada83423abe0d560809b9a1c8ffda9` 的 `configs/audio/audio_device.xml`
  的原样拷贝（SHA256 `0d173c2b…b56ba`）。该仓库没有 `LICENSE` 文件，
  其 `README.md` 声明 `Copyright (C) 2023 The LineageOS Project` 与
  `SPDX-License-Identifier: Apache-2.0`；XML 文件本身没有逐文件许可头。
  因此按 **Apache-2.0（依据 device tree README）** 分发，全文见
  `provenance/upstream/LICENSE-APACHE-2.0.txt`。ZIP 内的覆盖 XML 相对上游只追加
  4 行 `kctl`，修改说明见 `provenance/NOTICE-audio_device_xml.txt`。
  本项目不是 LineageOS 官方发布，也**未获**其背书；**不声称**用 GPL-3.0 重新授权
  该文件，也不声称 GPL-3.0 覆盖所有上游文件。

ZIP 内共 9 个条目，逐条来源见 `provenance/README.md`，许可范围汇总见 `NOTICE.md`。

## English summary

**AI-generated project code:** The project-specific adaptation, `customize.sh`,
build/test scripts, CI workflows and documentation were generated and organized
by AI. The device owner supplied low-volume listening feedback, not a complete
code audit or hardware-safety validation. Vendored Magisk and LineageOS files are
upstream work, not AI-original, and retain their documented provenance and licenses.

An experimental Magisk module for the Redmi 12C (`earth`) running LineageOS 21
(`21.0-20240509-UNOFFICIAL-earth`, Android 14 / API 34, kernel tag
`e1d7983c7a49`, tested with Magisk 31.1). It systemlessly overlays
`/vendor/etc/audio_device.xml` and adds `Handset_PGA_GAIN=4Db` plus
`RCV Mux=Voice Playback` to the HAL `speaker_output` path, so the earpiece also
plays during speaker output. `4Db` is the value that is **set**, not a `+4dB` offset on
top of anything: the baseline XML contains no `Handset_PGA_GAIN` entry, and `8Db`
is the mixer/driver default captured from the device, written back on turnoff.

Only one short manual audition at media volume 3/15 was accepted. Installing the
ZIP on a real device, rebooting, calls, headphones, Bluetooth, maximum volume and
long-term behaviour are **UNTESTED**. No stereo-separation, audio-quality or
hardware-safety claims are made. The installer guard runs once at install time
only, so disable the module and reboot before any ROM, OTA or kernel change.

Build with `pwsh -File ./build-module.ps1` (PowerShell 7+); install the release
ZIP from Releases, never GitHub's autogenerated "Source code" archive.
Project-authored code is GPL-3.0. The vendored Magisk installer is unmodified
upstream GPL-3.0 code. The stock `audio_device.xml` baseline comes from
`LineageOS/android_device_xiaomi_earth` at commit
`87007ad3e1ada83423abe0d560809b9a1c8ffda9` and is distributed under Apache-2.0 as
declared by that device tree's README (the XML itself has no per-file license
header); the overlay ZIP carries the Apache-2.0 text and a modification notice.

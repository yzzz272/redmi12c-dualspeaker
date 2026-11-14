# Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循模块 `module.prop` 中的 `version`。

## [v0.1.0-experimental] - 2026-11-15

首个面向公开发布的实验版本（尚未发布）。仓库内容与真机验证状态如实记录如下。

### Added

- Magisk 模块内容：systemless 覆盖 `/vendor/etc/audio_device.xml`，
  在 `speaker_output` 的 `turnon` 追加 `Handset_PGA_GAIN=4Db`、`RCV Mux=Voice Playback`，
  在 `turnoff` 追加 `RCV Mux=Open`、`Handset_PGA_GAIN=8Db`（写回真机采集到的 mixer 默认值）。
- `module/customize.sh` 安装守卫：机型 `earth`、API 34、Lineage 版本
  `21.0-20240509-UNOFFICIAL-earth`、内核含 `e1d7983c7a49`、
  vendor 文件 SHA256 为基线或已打补丁值、包内覆盖 XML SHA256 校验。
  任一不匹配即中止，不写真实 vendor 文件。
- `build-module.ps1`（PowerShell 7）：从 `config/stock/audio_device.xml` 生成补丁 XML，
  校验哈希、LF/无 BOM、XML 合法性、严格语义差异（只允许 4 个 `kctl` 节点）、
  逐字节可还原性，并打包可复现的 ZIP 与 `.sha256`。
- `tests/test-installer.sh`：免 root 的安装守卫测试（9 个用例），
  用临时副本重定向 `VENDOR_XML`，不触碰真实 `/vendor`。
- `provenance/`：Magisk 安装器来源/哈希/GPL-3.0 信息；Apache-2.0 全文；
  覆盖 XML 的上游 commit、哈希与修改通知。
- 许可与来源：根目录 `LICENSE`（GPL-3.0，覆盖本项目自写代码）、`NOTICE.md`
  （三部分许可范围）、`config/stock/README.md`（基线来源与 Apache-2.0 依据）。
  ZIP 由 7 个条目增加到 9 个：新增 `audio_device.xml.LICENSE-Apache-2.0.txt`
  与 `audio_device.xml.NOTICE.txt`。
- `.github/workflows/`：CI 构建 + 守卫测试 + 版本 tag 的**草稿**预发布。
- 文档：`docs/PUBLISHING.md`、`docs/TESTING.md`、`docs/RELEASE_NOTES.md`、
  `CONTRIBUTING.md`、`NOTICE.md`。

### Verified

- 真机一次性手动操作：保持原 `LOL Mux=Playback` 不变，手动设
  `Handset_PGA_GAIN=4Db` + `RCV Mux=Voice Playback`，听筒出声、音量可接受。
- 仅一次短时试听，媒体音量 3/15。

### Not verified

- 本模块 ZIP 在真机上的安装 / 卸载全流程、安装后的重启行为。
- 最大音量、长时间播放、发热与器件寿命。
- 通话（听筒/免提）、耳机、蓝牙、铃声/闹钟的具体路由组合。
- 任何"左右声道分离""音质提升""硬件安全"结论。

### Notes

- `+4dB` 是**设置值**，不是相对基线的偏移量，也不是安全评级。上游配置基线
  `config/stock/audio_device.xml` 里**没有** `Handset_PGA_GAIN`；`8Db` 是从真机
  mixer/driver 采集到的默认值，不是基线文件里的字段。
- 补丁跟随 HAL 的 `speaker_output` 路径，因此铃声、免提等选择该路径时也会打开听筒；
  具体组合未逐一测试。
- 普通通话与耳机路径的 XML 文本未改动，但行为未测试。
- 安装守卫只在安装时执行一次；换 ROM / OTA / 换内核前必须先禁用或移除模块并重启。
- `config/stock/audio_device.xml` 来自 `LineageOS/android_device_xiaomi_earth`
  commit `87007ad3e1ada83423abe0d560809b9a1c8ffda9`，按 device tree README 声明的
  Apache-2.0 分发；本项目不声称用 GPL-3.0 重新授权该文件。
- `module.prop` 只调整了 `author` 元数据，`id`/`version`/`versionCode` 与实际音频行为未变。

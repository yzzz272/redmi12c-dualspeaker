# earth dual speaker v0.1.0-experimental

**实验性** Magisk 模块：在 Redmi 12C（`earth`）上让外放时听筒与主扬声器同时出声。
本版本只做过一次短时、低音量的手动试听，**不是**安全评级，也不是通用音质改造。

## 改了什么

systemless 覆盖 `/vendor/etc/audio_device.xml`，只在 HAL 的 `speaker_output` 路径追加 4 行：

```text
speaker_output/turnon   + <kctl name="Handset_PGA_GAIN" value="4Db" />
                        + <kctl name="RCV Mux" value="Voice Playback" />
speaker_output/turnoff  + <kctl name="RCV Mux" value="Open" />
                        + <kctl name="Handset_PGA_GAIN" value="8Db" />
```

- `4Db` 是**设置值**，不是相对基线的 `+4dB` 偏移。上游配置基线里**没有**
  `Handset_PGA_GAIN` 这一项；`8Db` 是从真机 mixer/driver 采集到的默认值，
  在 `turnoff` 时写回。
- 其余字节（含 XML 声明）逐字节保持不变；构建脚本会校验这一点。
- 没有开机脚本、没有后台轮询；安装脚本本身不写 mixer。

## 兼容性（安装脚本会逐项校验）

| 项目 | 要求 / 实测值 |
| --- | --- |
| 机型 | Redmi 12C，`ro.product.device` = `earth` |
| 系统 | Android 14（API 34） |
| ROM | `ro.lineage.version` = `21.0-20240509-UNOFFICIAL-earth` |
| 内核 | `uname -r` 含 `e1d7983c7a49` |
| Magisk | 实测 31.1；其他版本未测试 |
| vendor 配置 | SHA256 为 `0d173c2b…b56ba`（基线）或 `11334e07…e50c`（已打补丁） |

## 已测试

- 真机一次性手动操作：保持原 `LOL Mux=Playback`，设 `Handset_PGA_GAIN=4Db` +
  `RCV Mux=Voice Playback`，听筒出声、音量可接受（仅一次短时试听，媒体音量 3/15）。

## 未测试

- 本模块 ZIP 的真机安装 / 卸载、安装后重启
- 通话（听筒/免提）、耳机、蓝牙
- 铃声、闹钟等具体路由组合
- 最大音量、长时间播放、发热与器件寿命

## 安装

1. 下载本 release 的 `earth-dual-speaker-v0.1.0-experimental.zip` 与 `.sha256`，
   校验哈希。**不要**使用 GitHub 自动生成的 "Source code" 压缩包。
2. Magisk 应用 → 模块 → 从本地安装 → 选择该 ZIP。
3. **重启**后生效；禁用或删除后同样要重启才回滚。

## 注意

- 补丁挂在 HAL 的 `speaker_output` 路径上，铃声、免提等选择该路径时也会打开听筒；
  具体组合未逐一测试。普通通话与耳机路径的 XML 文本未改动，但行为未测试。
- 安装守卫**只在安装时执行一次**。换 ROM / OTA / 换内核之前，先禁用或删除模块并重启。
- 左右声道分离**未验证**；不承诺音质提升或硬件安全。

## 许可

- 本项目自写代码：GPL-3.0（ZIP 内 `customize.sh`、`updater-script`、两个 `*.NOTICE.txt`）。
- `update-binary`：Magisk 上游 GPL-3.0 原样拷贝。
- 覆盖 XML：来自 `LineageOS/android_device_xiaomi_earth`（commit
  `87007ad3e1ada83423abe0d560809b9a1c8ffda9`），按该 device tree README 声明的
  Apache-2.0 分发；ZIP 内附 Apache-2.0 全文与修改通知。
  本项目不是 LineageOS 官方发布，也未获其背书。

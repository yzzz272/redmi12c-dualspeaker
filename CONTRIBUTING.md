# Contributing

这是一个**单机型、单 ROM** 的实验项目，当前支持范围很窄。提交前请先读完本节。

## 适用范围

- 当前只针对 Redmi 12C（`earth`）+ LineageOS 21
  `21.0-20240509-UNOFFICIAL-earth`（Android 14 / API 34）+ 内核含 `e1d7983c7a49`。
- 本仓库的改动请保持在这个范围内。扩展到其他机型、其他 ROM 或其他音频设备
  需要单独讨论，并附上证据（原始 vendor 配置、哈希、实测记录）；
  这类改动不能用来声称当前模块已经通用。
- 不接受"让声音更响"的盲目增益提升（把 `4Db` 直接改成更大值之类）。
  没有测量、没有安全评估的增益改动不会被合并；`4Db` 是试听后接受的实验值，
  不是可随意放大的起点。

## 隐私（硬性要求）

提交 issue、PR、日志或截图时**不要**包含：

- 设备序列号、IMEI、手机号、账号、MAC 地址等任何标识信息
- 完整未脱敏的 `logcat` / `dumpsys` / `tinymix` 输出
- 完整 vendor 分区 dump、系统镜像、私有研究文件
- 含个人目录的绝对路径（如 `C:\Users\<name>\...`、`/home/<name>/...`）

日志请只贴与问题相关的片段，并先做脱敏。仓库通过 `.gitignore` 排除了
`device-snapshot/`、`reference/`、`earpiece-probe.sh`、`dist/` 等本地内容，
请不要用 `git add -f` 绕过。

## 构建与测试

```powershell
pwsh -File ./build-module.ps1        # 需要 PowerShell 7+
```

```bash
bash tests/test-installer.sh         # 免 root，Git Bash 也可以
```

- 构建脚本会校验基线哈希、行尾（LF / 无 BOM）、XML 合法性、严格语义差异
  （只允许 4 个 `kctl` 节点）、逐字节可还原性、ZIP 元数据。任何一项失败都要修代码，
  不要放宽校验。
- 所有文本文件必须保持 **LF**（见 `.gitattributes`），否则哈希会变。

## 不要改这些文件

- `module/META-INF/com/google/android/update-binary`：Magisk 上游原样拷贝，
  改了哈希校验就会失败（见 `provenance/`）。
- `config/stock/audio_device.xml`：上游 device tree 文件的原样拷贝，
  是唯一构建输入。要改行为请改 `build-module.ps1` 里的补丁定义，
  并同步更新 `module/customize.sh` 的哈希常量、`provenance/NOTICE-audio_device_xml.txt`
  与 `provenance/README.md`。
- `module/system/vendor/etc/audio_device.xml`：构建产物，由脚本重新生成。

## 提交内容

- 一个 PR 只做一件事；说明动机、验证方式、以及**没有**验证的部分。
- 不要提交来源或许可不明的第三方代码/文件。新增第三方内容必须附来源、commit、
  SHA256 与许可文本。
- 本项目自写代码以 **GPL-3.0** 授权；提交即表示你同意以此许可发布你的贡献。
  这**不**改变 `config/stock/audio_device.xml`（上游 Apache-2.0）与
  `update-binary`（上游 GPL-3.0）自身的许可状态，详见 `NOTICE.md`。
- 涉及真机行为的改动，请说明是否在真机上验证过；没验证就写没验证。

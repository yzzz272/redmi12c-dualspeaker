# 发布流程（维护者手动执行）

> 说明：本仓库**没有**执行过任何远端操作（没有创建远端仓库、没有 push、没有打 tag、
> 没有创建 release）。下面的命令只是给发布者参考的**示例**，请自己确认后再执行。
> 需要替换的地方用 `<...>` 占位。

## 0. 发布前检查

1. 隐私扫描：确认**没有把** `device-snapshot/`、`reference/`、`earpiece-probe.sh`、
   `dist/` 加进版本库（它们可以留在本地工作树里），也没有序列号、手机号、
   主机绝对路径、未脱敏日志。
2. `git status --short` 检查待提交的改动；`git status --short --ignored` 里这些本地研究/
   构建产物应显示为 `!!`。注意 `--ignored` 也会列出正常改动，它不能单独证明"只有忽略项"。
3. 本地构建与测试通过：

   ```powershell
   pwsh -File ./build-module.ps1
   ```

   ```bash
   bash tests/test-installer.sh
   ```

4. 确认 `module/module.prop` 的 `version` 就是要发布的版本号。

## 1. 本地初始化与首次提交（示例）

```bash
git init -b main
git add .gitignore .gitattributes LICENSE NOTICE.md README.md CHANGELOG.md \
        CONTRIBUTING.md build-module.ps1 config module provenance docs tests .github
git status --short
git commit -m "Initial public import: earth dual speaker v0.1.0-experimental"
```

- 不要用 `git add -f` 强行加入 `.gitignore` 里的本地研究文件。
- `dist/` 可以存在于本地工作树（构建产物），但**不提交**。
- `module/system/vendor/etc/audio_device.xml` 是构建产物，但**故意**提交，方便审阅；
  CI 会重新生成并检查是否与提交内容一致。

## 2. 创建远端仓库并推送（示例，需要你自己的账号）

```bash
# 先在 GitHub 网页上手动创建一个空仓库，例如：
#   https://github.com/<your-github-user>/<repo>
git remote add origin https://github.com/<your-github-user>/<repo>.git
git push -u origin main
```

## 3. 打 tag（示例）

tag 必须**与 `module/module.prop` 的 `version` 完全一致**（例如 `v0.1.0-experimental`），
否则 `.github/workflows/release.yml` 会直接失败，不会创建 release。

```bash
git tag -a v0.1.0-experimental -m "v0.1.0-experimental"
git push origin v0.1.0-experimental
```

## 4. GitHub Release：草稿 + 预发布

- tag push 会触发 `.github/workflows/release.yml`：构建 ZIP、跑守卫测试，
  然后用 `gh` CLI 创建 **draft** 且 **prerelease** 的 release，
  附上 `earth-dual-speaker-<version>.zip` 与 `.sha256`。
- 草稿**对外不可见**，直到维护者在 GitHub 上手动点 Publish。
  **请先人工核对** release notes、ZIP 哈希，以及有没有把未验证的行为写成已验证。
- 本项目目前是实验状态，不建议发布 stable release。

## 5. 不要做的事

- 不要把 GitHub 自动生成的 "Source code (zip/tar.gz)" 当成模块包发布或分发。
- 不要把 `dist/` 目录提交进仓库；release 只上传模块 ZIP 与 `.sha256` 作为 Release assets，
  不要上传日志、设备快照或本地研究文件。
- 不要在 release notes 里写"硬件安全""左右声道分离""iPhone 音质"之类的结论。
- 不要在未确认的情况下声称 CI 已经跑过；本地没有 GitHub runner。

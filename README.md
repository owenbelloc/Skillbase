# Skillbase

本地 Mac 应用：把 Cursor、Claude、Codex、Kimi 的 Agent Skills 收进一个知识库，自动发现本机已装技能，并一键部署到指定桌面端。

当前版本：**1.0.0**

安装包在 [Releases](https://github.com/owenbelloc/Skillbase/releases) 下载。未签名，第一次打开请右键 → 打开。

## 能做什么

- 自动识别 `/Applications` 里的 Cursor、Claude、Kimi、ChatGPT（Codex）以及对应的 `~/.cursor`、`~/.claude`、`~/.codex`、`~/.kimi-code` 配置
- 扫描用户技能、内置技能、插件技能（只读）
- 新建 / 导入 `SKILL.md` 到本地知识库 `~/Library/Application Support/Skillbase/Library`
- 用符号链接或复制，把技能部署到：
  - Cursor → `~/.cursor/skills`
  - Claude 桌面端 / Claude Code → `~/.claude/skills`
  - Codex 桌面端 / CLI → `~/.codex/skills`
  - Kimi 桌面端 / Kimi Code → `~/.kimi-code/skills` 与 `~/.kimi/skills`
  - 跨平台共享 → `~/.agents/skills`

部署完成后，**新开一轮对话**即可被对应桌面端加载。

## 构建

需要 macOS 14+ 和 Swift 命令行工具。

```bash
chmod +x scripts/package-app.sh
./scripts/package-app.sh
open dist/Skillbase.app
```

日常开发：

```bash
swift run Skillbase
```

## 发新版本

1. 改 `Info.plist` 里的 `CFBundleShortVersionString`（例如 `2.0.0`）
2. 在 `CHANGELOG.md` 写上这一版改了什么
3. 提交后打标签并推送：

```bash
git tag v2.0.0
git push origin main
git push origin v2.0.0
```

推送 `v*` 标签后，GitHub Actions 会打包 `Skillbase-macOS.zip` 并创建 Release。也可以本地打包后手动上传：

```bash
./scripts/package-app.sh
gh release create v2.0.0 dist/Skillbase-macOS.zip --title "Skillbase 2.0.0" --notes-file CHANGELOG.md
```

## 说明

Skillbase 不沙盒化，这样才能读写各 AI 的技能目录。所有数据都留在本机。

# First Love Sol · 初恋 Sol

用固定来源、哈希校验和可回滚配置，重放 GPT-5.6 Sol 首发日的 Codex harness instructions。

> 这个项目不会恢复旧模型快照或模型权重。它是在当前模型上使用固定提交中的 Day-1 Codex instructions。

[English](README.md)

## 项目内容

- `gpt-5.6-sol` 的 Day-1 instructions 原文；
- 固定到原始 OpenAI Codex 提交的 PowerShell 提取脚本；
- 上游文件和提取结果的 SHA-256 校验；
- Windows 安装、重启与回滚说明；
- 脱敏后的缓存和压缩实测。

## 来源

| 项目 | 值 |
|---|---|
| 仓库 | `openai/codex` |
| 提交 | `3380969a29134630d56feb6218e8e8dcc5e8196d` |
| 提交日期 | 2026-07-09 |
| 源文件 | `codex-rs/models-manager/models.json` |
| 模型 | `gpt-5.6-sol` |
| 字段 | `model_messages.instructions_template`、`base_instructions` |
| 提取文件 SHA-256 | `E9778714D505F3DD04D44DB4394024C5FAB5BF6554FC9FAA3CDF9CF776B63BB9` |

在固定提交中，这两个 instructions 字段逐字节相同。完整声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 安装

直接从固定的上游来源提取并校验：

```powershell
.\scripts\extract-day1-instructions.ps1 `
  -OutputPath "$env:USERPROFILE\.codex\sol-day1-2026-07-09.md"
```

先备份 `%USERPROFILE%\.codex\config.toml`，然后在任何 TOML 表头之前添加顶层配置：

```toml
model_instructions_file = "C:/Users/<you>/.codex/sol-day1-2026-07-09.md"
```

`model_instructions_file` 是当前 Codex 官方文档中用于替换内置模型 instructions 的配置项，参见 [OpenAI 官方配置参考](https://developers.openai.com/codex/config-reference#configtoml)。

Windows TOML 基础字符串建议使用正斜杠。完全退出 Codex Desktop，包括托盘进程；重新启动后新建任务测试。

## 回滚

从 `config.toml` 删除 `model_instructions_file`，完全重启 Codex，再新建任务。此后会恢复活动模型目录提供的现行 instructions。

## 预期现象

更换 instructions 会改变提示前缀，因此切换后的第一轮缓存变冷是正常现象。保持文件不变后，验证任务的后续请求恢复到了 97-99% 的缓存输入比例；测试中的自动压缩也保持了正常的压缩后缓存形态，没有重新归零。

这些结果受 Codex 版本和工作负载影响，具体范围见 [docs/validation.md](docs/validation.md)。

## 能力边界

- 项目和用户的 `AGENTS.md` 仍然生效；
- 服务端策略、工具、插件和 app-server 行为不会被冻结；
- 未来 Codex 版本可能改变或移除 `model_instructions_file`；
- 历史 instructions 未来可能与新工具协议不兼容；
- 本项目不代表 OpenAI 官方背书。

## 许可证

Apache-2.0。仓库中的 instructions 来自采用 Apache-2.0 的 OpenAI Codex 仓库；来源和归属见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

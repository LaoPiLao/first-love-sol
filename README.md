# First Love Sol

Replay the GPT-5.6 Sol Day-1 Codex harness instruction profile with a pinned, hash-verified, and reversible setup.

> This project does not restore an older model snapshot or model weights. It runs the current model with the Codex instructions that shipped in the pinned Day-1 catalog record.

[简体中文](README.zh-CN.md)

## What is included

- the verbatim Day-1 instruction profile for `gpt-5.6-sol`;
- a PowerShell extractor pinned to the original OpenAI Codex commit;
- source and output SHA-256 verification;
- safe Windows configuration and rollback instructions;
- sanitized cache and compaction observations.

## Provenance

| Item | Value |
|---|---|
| Repository | `openai/codex` |
| Commit | `3380969a29134630d56feb6218e8e8dcc5e8196d` |
| Commit date | 2026-07-09 |
| Source file | `codex-rs/models-manager/models.json` |
| Model | `gpt-5.6-sol` |
| Fields | `model_messages.instructions_template`, `base_instructions` |
| Extracted SHA-256 | `E9778714D505F3DD04D44DB4394024C5FAB5BF6554FC9FAA3CDF9CF776B63BB9` |

At the pinned commit, the two instruction fields are byte-for-byte identical. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Install

Extract a verified copy directly from the pinned upstream source:

```powershell
.\scripts\extract-day1-instructions.ps1 `
  -OutputPath "$env:USERPROFILE\.codex\sol-day1-2026-07-09.md"
```

Back up `%USERPROFILE%\.codex\config.toml`, then add this as a top-level key before any TOML table headers:

```toml
model_instructions_file = "C:/Users/<you>/.codex/sol-day1-2026-07-09.md"
```

`model_instructions_file` is the current documented Codex configuration key for replacing built-in model instructions. See the [official OpenAI configuration reference](https://developers.openai.com/codex/config-reference#configtoml).

Use forward slashes in a Windows TOML basic string. Completely exit Codex Desktop, including its tray process, restart it, and create a new task.

## Rollback

Remove `model_instructions_file` from `config.toml`, completely restart Codex, and create a new task. Codex will return to the instruction profile supplied by its active model catalog.

## Expected behavior

Changing the instruction file changes the prompt prefix, so the first request after switching is expected to have a cold cache. With the file held constant, subsequent requests in the validation task recovered to a 97-99% cached-input ratio. The tested automatic compaction retained a normal post-compaction cache profile rather than returning to zero.

These observations are version- and workload-specific. See [docs/validation.md](docs/validation.md) for the exact scope.

## Compatibility boundary

- project and user `AGENTS.md` instructions still apply;
- server-side policy, tools, plugins, and app-server behavior are not frozen;
- future Codex versions may change or remove `model_instructions_file` behavior;
- an old instruction profile can become incompatible with future tool protocols;
- OpenAI does not endorse this project.

## License

Apache-2.0. The bundled instruction text is derived from the Apache-2.0 OpenAI Codex repository. Attribution and pinned source details are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

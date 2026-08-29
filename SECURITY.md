# Security and disclosure hygiene

Do not attach or commit any of the following:

- a real `~/.codex/config.toml`;
- `auth.json`, OAuth files, account emails, access or refresh tokens;
- `experimental_bearer_token`, API keys, management keys, or `.env` files;
- Codex rollout/session JSONL files or exported chat histories;
- usage databases, WAL files, or screenshots containing account data;
- proxy subscription URLs or private network endpoints.

Before publishing:

```powershell
rg -n -i "bearer|refresh[_-]?token|access[_-]?token|api[_-]?key|management[_-]?key|sk-[A-Za-z0-9_-]+|authorization" .
git diff --check
git status --short
```

Review every match manually. A clean regex scan is not proof that no secret remains.

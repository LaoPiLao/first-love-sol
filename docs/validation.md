# Validation notes

## Extraction integrity

The extractor downloads one pinned `models.json`, checks its SHA-256, selects exactly one `gpt-5.6-sol` record, verifies that `model_messages.instructions_template` and `base_instructions` are identical, and then checks the extracted byte sequence before writing it.

| Artifact | SHA-256 |
|---|---|
| Upstream `models.json` | `DCAB00231A5178A9C84B7AEF4CC06A1E1359E37EE0DD7E69D5822C4B1DE723B1` |
| Extracted instructions | `E9778714D505F3DD04D44DB4394024C5FAB5BF6554FC9FAA3CDF9CF776B63BB9` |

## Prompt-cache observations

Changing the instruction profile invalidated the previous prompt prefix once. Keeping the file unchanged allowed the cache to re-warm normally:

| Stage | Input | Cached input | Cache ratio |
|---|---:|---:|---:|
| First request after switch | 138,669 | 12,032 | 8.68% |
| Second request | 141,882 | 137,856 | 97.16% |
| Third request | 142,406 | 140,928 | 98.96% |
| Later stable sample | 165,948 | 165,504 | 99.73% |

Repeatedly switching profiles will repeatedly invalidate the prefix.

## Compaction observation

One automatic compaction after the switch retained 43.5% cached input on the first post-compaction request, compared with 45.2% in the prior profile, and then recovered to 97.9%. The rollout contained one compaction item and no duplicate instruction layer. This single observation did not reproduce the post-compaction cache-zero failure.

## A/B scope

Under the same tested configuration, the then-current instruction profile used exactly 295 more input tokens than Day-1 on the tested Sol and Luna first-turn paths. This difference is not portable across changes in Codex version, tools, plugins, workspace instructions, reasoning settings, or model routing.

The validation establishes reproducibility and observed cache behavior. It does not establish that the historical profile is universally better, restore an older model snapshot, or guarantee future compatibility.

No account identifier, credential, bearer token, session ID, request body, chat transcript, or raw rollout is included in this repository.

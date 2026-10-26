# Codex in ChatGPT / GPT-5.6 compatibility audit

> Historical audit from 2026-07-12. These results describe that release and environment; see the [current plugin catalog](../README.md) for present maintenance and support information.

Checked: 2026-07-12

## Result

All eight marketplace plugins pass current manifest/path validation, are installed and enabled, and pass their available automated checks under the ChatGPT-hosted Codex environment. Two real compatibility defects were fixed:

1. Agent Handoff version drift: Codex advertised `0.2.0` while Claude/Kimi advertised `0.2.1`.
2. Plugin Forge hosted MCP status: Git subprocess collection could block in the ChatGPT host. Version `0.1.1` skips Git state by default for MCP calls while preserving opt-in Git state and full CLI status.

Standalone Codex was upgraded from `0.140.0` to `0.144.1`. `codex doctor` confirms `gpt-5.6-sol`, valid config, healthy state databases, working ChatGPT websocket authentication, and all eight marketplace plugins installed/enabled.

## Product changes affecting this marketplace

- Codex is now a mode inside ChatGPT desktop. Plugin management moved to Settings.
- `.agents/plugins/marketplace.json` remains correct for repo marketplaces. `.claude-plugin/marketplace.json` remains a supported legacy-compatible fallback.
- Required plugin entry point remains `.codex-plugin/plugin.json`. Skills, apps, MCP servers, hooks, and assets remain supported.
- ChatGPT installs local plugins into `~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/`; editing source alone does not refresh a running task.
- Reinstall or restart after plugin changes, then start a new task so skills/tools reload.
- GPT-5.6 requires ChatGPT desktop `26.707.30751+` or Codex CLI `0.144.0+`.
- Host sandbox/approval policy governs plugin execution. Connector/MCP authentication remains service-specific. Managed workspaces may restrict plugin/app availability by role.

## Verification evidence

| Plugin | Automated evidence | Runtime evidence | Result |
| --- | --- | --- | --- |
| Web.de Access 0.2.2 | 8 Node tests; secret scan | Live stdio MCP contract retained; 20-tool smoke passed before metadata-only bump | Pass |
| RECALL 1.5.2 | Full parallel `scripts/run_tests.py` suite | Skills discovered; provider/MCP metadata aligned | Pass |
| Plugin Evaluation Kimi 0.1.1 | 123 passed, 3 skipped | Skill discovered; marketplace artwork published | Pass |
| Agent Handoff 0.2.2 | 72 passed | Live hosted MCP status returned `isError=false`; new cache installed | Pass |
| Customization Control 0.1.1 | 3 Python tests | Six skills discovered; marketplace artwork published | Pass |
| Plugin Forge 0.2.0 | 91 passed; Ruff clean; Forge compile/sync clean | Installed-cache stdio MCP status contract retained from 0.1.1; provider hook round-trip tests added | Pass |
| Usage Pulse 0.1.1 | 5 passed; 87.07% coverage; ResourceWarnings treated as errors | Hosted MCP contract retained; provider-specific hook generation verified | Pass |
| Computer Custom 0.1.1 | TypeScript check; 10 Node tests | Skill discovered; Codex and Claude metadata aligned | Pass |

Marketplace-wide static audit also passed: eight unique IDs, all sources inside marketplace root, all required Codex manifests present, registry/manifest versions equal, and all declared component/asset paths exist.

## Remaining non-blocking observations

- Current running task loaded old Plugin Forge process before `0.1.1`; new tasks load installed `0.1.1` cache.
- `codex doctor` reports stale historical rollout rows and API-key HTTP reachability failure. ChatGPT websocket path works. These issues do not affect plugin verification.
- Destructive/write flows were not executed: sending email, deleting mail, wiping usage data, applying customization repairs, or controlling desktop apps. Their policy/unit paths passed; production mutation was intentionally avoided.

## Official sources

- [Codex changelog](https://learn.chatgpt.com/docs/changelog)
- [Plugins](https://learn.chatgpt.com/docs/plugins)
- [Build plugins](https://learn.chatgpt.com/docs/build-plugins)
- [GPT-5.6 in ChatGPT](https://help.openai.com/en/articles/20001354-gpt-56-in-chatgpt)
- [Using Codex with your ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-chatgpt)

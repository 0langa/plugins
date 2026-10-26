# Changelog

## 2026-10-26 (v1.0.27)

- Released Computer Custom 0.3.0 with prepared desktop batches, a shared queue
  across clients, countdown/Snooze/Cancel, isolated native workers, and complete
  helper packaging.
- Updated the Codex and Claude Code catalogs to the immutable 0.3.0 release tag
  and commit, with the matching submodule and plugin documentation.

## 2026-10-15 (v1.0.26)

- Released six plugin updates: RECALL 1.6.2, Web.de Access 0.2.12, Agent Handoff 0.2.7, Customization Control 0.1.8, Plugin Forge 0.2.15, and Usage Pulse 0.1.11.
- RECALL 1.6.2 hooks no longer create `.recall/` in projects where RECALL was never initialized (their turn state lives in a per-user folder), `doctor --repair` restores text garbled by the pre-1.6.1 Windows MCP bug, and several JSONL storage edge cases are fixed. A `.recall/` folder holding only `runtime/`, left by 1.6.1 in such a project, can be deleted.
- Web.de Access 0.2.12 adds Mark-of-the-Web to attachments and messages saved on Windows, so they open with the usual downloaded-file warning, and refuses to rename or delete a folder that holds a protected folder. Dependencies are unchanged since 0.2.11; installs on 0.2.10 or older still need `npm ci --omit=dev`.
- Agent Handoff 0.2.7 also redacts cookies, PEM private keys, `curl -u` passwords, and passwords written as prose. Existing records are redacted on the next capture.
- Customization Control 0.1.8 dedupes only within one scope, so a personal copy is no longer removed because a project copy of the same name exists. Re-run the planner before applying a plan made with 0.1.7 or earlier.
- Plugin Forge 0.2.15 lists forge-local Claude plugins in the `./plugins/<name>` form Claude Code accepts and generates Claude hooks that work on Windows without `commandWindows`. Run `forge install --provider claude` again for each plugin registered with Claude Code.
- Usage Pulse 0.1.11 takes tool-call durations from the host's hook payload, so hook startup no longer inflates them, and on first run merges the doubled tool-call rows recorded before 0.1.10.
- Pinned the Codex and Claude Code catalogs to each immutable release tag and full commit SHA, and moved the matching Kimi Code submodules to the same commits. No Codex hook definitions changed, so no `/hooks` re-trust is needed. Addonry 0.3.2, Computer Custom 0.2.3, and Plugin Evaluation Kimi 0.1.3 remain current.

## 2026-10-14 (v1.0.25)

- Released seven plugin updates from the 2026-10-14 audit: RECALL 1.6.1, Web.de Access 0.2.11, Agent Handoff 0.2.6, Customization Control 0.1.7, Plugin Forge 0.2.14, Usage Pulse 0.1.10, and Addonry 0.3.2.
- RECALL 1.6.1 hooks now run on Windows under Claude Code (`py -3` instead of the `python3` Store alias), keep Codex's strict hook output schema on memory-free turns, and close two path-traversal routes. Codex users must re-trust the changed hooks in `/hooks`.
- Web.de Access 0.2.11 closes several mail-loss paths (closing a folder no longer expunges mail other clients only flagged; a failed MOVE fallback no longer deletes the original), refuses plaintext IMAP, and moves to nodemailer 10. Existing installs need `npm ci --omit=dev`.
- Agent Handoff 0.2.6 redacts secrets on every write path. Customization Control 0.1.7 no longer removes the copy dedupe means to keep and works when the agent was started from PowerShell 7. Plugin Forge 0.2.14, Usage Pulse 0.1.10, and Addonry 0.3.2 patch vulnerable dependencies and fix smaller bugs.
- Pinned the Codex and Claude Code catalogs to each immutable release tag and full commit SHA, and moved the matching Kimi Code submodules to the same commits. Computer Custom 0.2.3 and Plugin Evaluation Kimi 0.1.3 remain current.

## 2026-09-19 (v1.0.24)

- Updated Computer Custom to 0.2.1 so Codex loads the bundled MCP server directly from the plugin manifest.
- Pinned the Codex and Claude Code catalogs to immutable tag `v0.2.1` and commit `136e1059de6d7629202a693ccc98d22046559939`.
- Updated the Computer Custom submodule to the same commit. Computer Custom remains intentionally unsupported on Kimi Code.

## 2026-09-19 (v1.0.23)

- Released Computer Custom 0.2.0 with a self-contained MCP server, native Windows helper, policy gates, saved flows, elevation support, and an activity overlay.
- Pinned the Codex and Claude Code catalogs to immutable tag `v0.2.0` and commit `91b2bd0c9bc7b2dbcc4c545aacbe10671730896e`.
- Updated the Computer Custom submodule to the same commit. Computer Custom remains intentionally unsupported on Kimi Code.

## 2026-09-17 (v1.0.22)

- Updated RECALL from 1.5.5 to the published 1.6.0 release.
- Pinned the Codex and Claude Code catalogs to immutable tag `v1.6.0` and commit `c2452a48845dfc72a3461076ec833f249326ba02`.
- Updated the RECALL submodule to the same commit for Kimi Code local installs.
- Kept every other plugin version and source pin unchanged.

## 2026-09-09 (v1.0.21)

- Released six confirmed-bug patches: Computer Custom 0.1.6, Usage Pulse 0.1.9, Plugin Forge 0.2.13, Customization Control 0.1.5, Addonry 0.3.1, and Web.de Access 0.2.10.
- Updated immutable release-tag/SHA catalog pins and matching Kimi submodules together. Agent Handoff 0.2.5, Plugin Evaluation Kimi 0.1.3, and RECALL 1.5.5 remain current.
- Repairs cover current Computer Use bootstrap, Usage Pulse MCP dispatch, installed-plugin inventory layouts, local runtime/cache placement, Windows fixture digests, and Web.de MCP version/dependency health.
- Fixed the native Windows install test's default path after MSIX AppData expansion exceeded Git's nested-clone path limit.
- Product polish and unfinished Addonry workflows remain separate from this maintenance release.

## 2026-08-27 (v1.0.20)

- Released Addonry 0.3.0 with shared Chrome and Firefox Manifest V3 targeting, acceptance-driven repair loops, source-bound browser proof, and deterministic local packaging.
- Pinned Codex and Claude Code catalogs plus the Kimi Code submodule to immutable `v0.3.0` / `9600198104e411c9284c873d6c36ccf51a737a3e`.
- Reconciled stale Plugin Forge and Usage Pulse documentation with their already-published 0.2.12 and 0.1.8 catalog versions.

## 2026-08-19 (v1.0.19)

- Released RECALL 1.5.5. Its Codex manifest now declares the MCP server inline, so a Codex
  install registers RECALL's tools instead of loading only its skills; users who worked around
  this with a hand-written `[mcp_servers.recall]` block in `~/.codex/config.toml` should delete
  it after updating.
- Pinned the Codex and Claude Code catalogs plus the Kimi Code submodule to immutable `v1.5.5` /
  `c07e9766e5cb079e08787a1145a75749050da7a6`.

## 2026-08-05 (v1.0.18)

- Released Agent Handoff 0.2.5. Its Kimi Code Windows launcher now creates the project environment under Kimi's cache, avoiding stale managed-copy `.venv` links; the release also restores the documented `agent-handoff verify` CLI command.
- Pinned Codex and Claude Code catalogs plus the Kimi Code submodule to immutable `v0.2.5` / `1f5a4f3ebb33783b676c9f7222f661931dadb477`.

## 2026-08-05 (v1.0.17)

- Released Kimi Code MCP launcher repairs: Agent Handoff 0.2.4, Plugin Forge 0.2.12, and Usage Pulse 0.1.8 resolve the user-level Windows uv.exe before starting their Python MCP servers.
- Pinned Codex and Claude Code catalogs plus Kimi Code submodules to each repaired immutable tag and full commit SHA.

## 2026-08-05

- Released Addonry 0.2.1, Agent Handoff 0.2.3, Computer Custom 0.1.5, Customization Control 0.1.4, Plugin Evaluation Kimi 0.1.3, Plugin Forge 0.2.11, RECALL 1.5.4, Usage Pulse 0.1.7, and Web.de Access 0.2.8.
- Pinned every Codex and Claude Code marketplace source to its immutable release tag and full commit SHA; Kimi Code consumes the matching submodule checkouts.
- Removed 22 empty tracked stderr logs and ignored local RECALL project state.
- Normalized GitHub shorthand to HTTPS in published E2E tests and install documentation so Claude Code does not fall back to SSH for private marketplace clones.
- Reused an inherited GitHub authorization header in E2E instead of appending a duplicate header.
- Re-pinned Plugin Forge catalog entries and Kimi submodule checkout to immutable `v0.2.11` / `82352d01ab13924725340677b4caa5d9f08eab8d`.

## 2026-08-01

- Updated Addonry to 0.2.0 with source-bound final-ready evidence, real toolbar-action and activeTab verification, broader security validation, and hardened MCP/provider startup.
- Pinned Codex and Claude Code marketplace entries to immutable tag `v0.2.0` and commit `0cabdc6b694bf03e54b1c087bba92f75904895ee`; Kimi Code consumes same checked-out submodule.

## 2026-07-30

- Updated Addonry to 0.1.4 after branded Chrome 137+ removal of `--load-extension`; install helper now fails closed without changing browser processes.
- Replaced obsolete normal-Chrome restart/install claims with supported `chrome://extensions` **Load unpacked** guidance and explicit isolated-browser boundaries.
- Updated Addonry to 0.1.3 with durable personal extension storage and authorized graceful Chrome restart/load automation.
- Verified normal Chrome session restoration, command-line extension load, isolated real-Chrome extension behavior, and Chrome DevTools MCP startup.
- Preserved caller Git config overrides and added focused-plugin selection in marketplace E2E so external exFAT clean-room runs remain usable.

## 2026-07-29

- Updated Addonry to 0.1.2 with verified manual Kimi skill fallback for Kimi 0.29.x Windows command-registry failures.
- Updated Addonry to 0.1.1 with provider-native manual activation, safe MCP root resolution, and identity-based external runtime routing.
- Added Addonry 0.1.0 for Codex, Claude Code, and Kimi Code, pinned to immutable tag and full commit SHA.
- Added manual-only Chrome extension workflow with pinned Chrome DevTools MCP and real-Chrome verification.

## 2026-07-28

- Updated Codex marketplace pins for Web.de Access 0.2.7, Plugin Forge 0.2.7, and Usage Pulse 0.1.6.
- Updated Claude and registry metadata for Plugin Forge 0.2.7 and refreshed provider documentation.
- Verified full marketplace validation plus isolated Codex installation of all eight plugins.

## 2026-07-27

- Privacy hotfix: Web.de Access 0.2.4 removes the last literal workstation identity marker from public regression code.
- Hotfix: Plugin Forge 0.2.4 and Usage Pulse 0.1.5 now launch generated MCP servers from cached plugin project roots without host-directory editable installs.
- Released Computer Custom 0.1.4 with reliable official-first bootstrap, live Computer Use guidance, and confirmation-based administrative policy gates.
- Updated Codex and Claude Code marketplace pins to immutable tag `v0.1.4` and commit `3f984b7f53c32c349c26a8edf5eaa4fd6b919e6f`.
- Released Web.de Access 0.2.3 with generic credential migration names, redacted smoke output, dependency updates, and public-safety regression coverage.
- Released Customization Control 0.1.3, removing tracked handoff artifacts containing workstation paths.
- Released Plugin Forge 0.2.3 with public-data cleanup and reliable direct hook entrypoints.
- Released Usage Pulse 0.1.4, fixing Codex/Claude MCP startup and direct hook entrypoints.
- Released RECALL 1.5.3, removing workstation identity from manuals, baselines, and tests.
- Updated every changed Codex and Claude marketplace entry to immutable release tags and full commit SHAs.

## 2026-07-13

- Released Plugin Evaluation Kimi 0.1.2, Customization Control 0.1.2, Plugin Forge 0.2.2, Usage Pulse 0.1.3, and Computer Custom 0.1.3.
- Corrected duplicate Claude hook registration found by clean-room installation and made E2E fail on client-reported plugin load errors.
- Replaced Codex and Claude submodule-relative marketplace sources with HTTPS release refs pinned to full commit SHAs, allowing GitHub marketplace installs without submodule initialization.
- Added isolated Codex and Claude marketplace E2E installation coverage for all eight plugins.
- Expanded marketplace validation for remote source parity, immutable pins, safe subdirectories, and embedded-credential rejection.
- Updated install documentation for direct `0langa/0langas-plugin-marketplace` registration.
- Released Computer Custom 0.1.2 with restored Codex runtime compatibility, safer confirmation fallback, and expanded policy/audit tests.

## 2026-07-12

- Added ChatGPT-hosted Codex and GPT-5.6 compatibility evidence.
- Published visual metadata and assets across all eight plugins.
- Bumped artwork-bearing plugin releases so immutable caches receive metadata updates.
- Fixed Agent Handoff version parity and released Plugin Forge 0.2.0.
- Released Usage Pulse 0.1.1 with lossless provider hook generation.
- Added deterministic marketplace validation and GitHub Actions enforcement.
- Removed user-specific install paths and reconciled Computer Custom provider metadata.
- Recorded the 2026-07-06 PluginEval baseline artifacts.

## 2026-07-05

- Added marketplace registration for `plugin-forge`, `usage-pulse`, and `computer-custom`.
- Documented install commands for newly registered plugins.
- Synced submodule pointers after publish-readiness fixes in touched plugins.

# PluginEval Baseline Matrix

Purpose: record the first full PluginEval baseline for every plugin in this marketplace, then use later runs to measure drift and improvement. This file is a results ledger, not a quality gate.

This is historical evidence from 2026-07-06. Version and drift fields describe that run, not current marketplace state. The [July compatibility audit](codex-chatgpt-compatibility-2026-07-12.md) is also historical. See the [current plugin catalog](../README.md) for present maintenance and support information.

No evaluations were run while preparing this matrix.

## Evaluator Contract

PluginEval `certify` runs deep evaluation for a single skill directory:

```powershell
Set-Location C:\path\to\0langas-plugin-marketplace\plugins\plugin-evaluation-kimi
uv run plugin-eval certify <skill-dir> --output json
```

Important behavior found in the evaluator:

- Deep evaluation is per skill. Plugin-level `score` only runs the static layer and is downgraded to `quick`/`Estimated`.
- A marketplace baseline should certify every `skills/<name>/SKILL.md`, then roll results up by plugin.
- Deep layers are `static`, `judge`, and `monte_carlo`.
- `certify` uses `Depth.DEEP`, which means Monte Carlo defaults to 50 runs.
- `Depth.THOROUGH` exists in code with 100 Monte Carlo runs, but the public `certify` command uses deep/50.
- JSON output is the canonical artifact to store for future comparisons.

## Fields To Capture

Store one raw JSON result per skill per run, then transcribe key values into the tables below.

Suggested artifact path:

```text
docs/eval-baselines/YYYY-MM-DD/<plugin>/<skill>.json
```

Run metadata:

| Field | Value |
|---|---|
| Run ID |  |
| Run date |  |
| Marketplace commit |  |
| PluginEval commit |  |
| PluginEval version | 0.1.0 |
| Provider |  |
| Model |  |
| Depth | deep |
| Monte Carlo runs | 50 |
| Concurrency |  |
| Operator |  |
| Notes |  |

Top-level result fields:

| JSON path | Meaning |
|---|---|
| `plugin_path` | Skill directory evaluated |
| `timestamp` | Evaluator timestamp |
| `config.depth` | Requested depth |
| `config.provider` | Backend provider |
| `config.model` | Model override/default |
| `layers[].layer` | Actual layers run |
| `layers[].score` | Layer score, 0.0 to 1.0 |
| `layers[].anti_patterns` | Static anti-pattern flags |
| `layers[].metadata` | Layer metadata such as line count, run count, error samples |
| `composite.score` | Composite score, 0 to 100 |
| `composite.badge` | `platinum`, `gold`, `silver`, `bronze`, or `no_badge` |
| `composite.anti_pattern_penalty` | Multiplicative anti-pattern penalty |
| `composite.confidence_label` | `Certified` for deep skill runs |
| `composite.dimensions[]` | Weighted dimension scores |
| `total_duration_ms` | Total duration, if populated |

Monte Carlo fields:

| JSON path | Meaning |
|---|---|
| `layers[monte_carlo].metadata.n_runs` | Number of simulations |
| `layers[monte_carlo].metadata.n_activated` | Activated simulation count |
| `layers[monte_carlo].metadata.n_errored` | Errored simulation count |
| `layers[monte_carlo].metadata.error_samples` | Deduplicated error samples |
| `layers[monte_carlo].sub_scores.triggering.activation_rate` | Activation rate |
| `layers[monte_carlo].sub_scores.triggering.wilson_lower` | Activation CI lower |
| `layers[monte_carlo].sub_scores.triggering.wilson_upper` | Activation CI upper |
| `layers[monte_carlo].sub_scores.output_consistency.mean_quality` | Mean activated output quality |
| `layers[monte_carlo].sub_scores.output_consistency.std_dev` | Output quality standard deviation |
| `layers[monte_carlo].sub_scores.output_consistency.cv` | Coefficient of variation |
| `layers[monte_carlo].sub_scores.output_consistency.bootstrap_lower` | Quality CI lower |
| `layers[monte_carlo].sub_scores.output_consistency.bootstrap_upper` | Quality CI upper |
| `layers[monte_carlo].sub_scores.failure_rate.p_fail` | Error probability |
| `layers[monte_carlo].sub_scores.failure_rate.cp_lower` | Failure CI lower |
| `layers[monte_carlo].sub_scores.failure_rate.cp_upper` | Failure CI upper |
| `layers[monte_carlo].sub_scores.token_efficiency.median` | Median tokens |
| `layers[monte_carlo].sub_scores.token_efficiency.iqr` | Token IQR |
| `layers[monte_carlo].sub_scores.token_efficiency.outlier_count` | Token outlier count |
| `layers[monte_carlo].sub_scores.token_efficiency.efficiency_norm` | Normalized token efficiency |

## Dimensions

| Dimension | Weight | Static | Judge | Monte Carlo | Capture |
|---|---:|---:|---:|---:|---|
| `triggering_accuracy` | 0.25 | 0.15 | 0.25 | 0.60 | Score, grade, CI, evidence |
| `orchestration_fitness` | 0.20 | 0.10 | 0.70 | 0.20 | Score, grade, CI, evidence |
| `output_quality` | 0.15 | 0.00 | 0.40 | 0.60 | Score, grade, CI, evidence |
| `scope_calibration` | 0.12 | 0.30 | 0.55 | 0.15 | Score, grade, CI, evidence |
| `progressive_disclosure` | 0.10 | 0.80 | 0.20 | 0.00 | Score, grade, CI, evidence |
| `token_efficiency` | 0.06 | 0.40 | 0.10 | 0.50 | Score, grade, CI, evidence |
| `robustness` | 0.05 | 0.00 | 0.20 | 0.80 | Score, grade, CI, evidence |
| `structural_completeness` | 0.03 | 0.90 | 0.10 | 0.00 | Score, grade, CI, evidence |
| `code_template_quality` | 0.02 | 0.30 | 0.70 | 0.00 | Score, grade, CI, evidence |
| `ecosystem_coherence` | 0.02 | 0.85 | 0.15 | 0.00 | Score, grade, CI, evidence |

Badge thresholds:

| Badge | Composite | Elo |
|---|---:|---:|
| Platinum | >= 90 | >= 1600 |
| Gold | >= 80 | >= 1500 |
| Silver | >= 70 | >= 1400 |
| Bronze | >= 60 | >= 1300 |
| No badge | < 60 | Any |

Elo is not currently populated by the `score`/`certify` path inspected here, so capture it only if future PluginEval output includes it.

## Plugin Surface Inventory

| Plugin | Baseline root | Providers | Version observed | Skills | Agents | Commands | Hooks | Notes |
|---|---|---|---|---:|---:|---:|---:|---|
| webde-access | `plugins/webde-access` | Codex, Claude Code, Kimi Code | 0.2.1 | 1 | 0 | 0 | 0 | Node MCP mailbox connector. |
| recall | `plugins/RECALL/plugins/recall` | Codex, Claude Code, Kimi Code | 1.3.0 | 7 | 0 | 0 | 1 | Local project memory with hooks and MCP. |
| plugin-evaluation-kimi | `plugins/plugin-evaluation-kimi` | Codex, Claude Code, Kimi Code | 0.1.0 | 1 | 2 | 3 | 0 | Evaluator being used for this baseline. |
| agent-handoff | `plugins/agent-handoff` | Codex, Claude Code, Kimi Code | 0.2.0/0.2.1 drift | 1 | 2 | 8 | 0 | Codex/pyproject show 0.2.0; Claude/Kimi show 0.2.1. |
| customization-control | `plugins/customization-control` | Codex, Claude Code, Kimi Code | 0.1.0 | 6 | 0 | 0 | 0 | Skills use `when_to_use`; PluginEval parser scores `description`. |
| plugin-forge | `plugins/plugin-forge` | Codex, Claude Code, Kimi Code | 0.1.0 | 3 | 0 | 1 | 2 | Forge-managed lifecycle automation. |
| usage-pulse | `plugins/usage-pulse` | Codex, Claude Code, Kimi Code | 0.1.0 | 2 | 0 | 1 | 7 | Hook-driven local usage telemetry. |
| computer-custom | `plugins/computer-custom/dist/computer-custom` | Codex, Claude Code | 0.1.0 | 1 | 0 | 0 | 1 | Dist output only; short passive skill description. |

## Skill Target Matrix

Fill one row per certified skill. Keep artifact paths relative to repository root.

| Plugin | Skill | Skill path | Lines | Refs | Assets | Static | Judge | Monte Carlo | Composite | Badge | Anti-patterns | Artifact | Baseline notes |
|---|---|---|---:|---|---|---:|---:|---:|---:|---|---|---|---|
| webde-access | webde-access | `plugins/webde-access/skills/webde-access` | 120 | yes | no | 0.745 | 0.837 | 0.751 | 75.72 | silver | 0 | `docs/eval-baselines/2026-07-06/webde-access/webde-access.json` | Baseline captured with `--provider codex`; Kimi-provider attempts failed from hook JSON pollution/broken RECALL hook path. |
| recall | define-category | `plugins/RECALL/plugins/recall/skills/define-category` | 142 | yes | yes | 0.934 | 0.910 | 0.896 | 89.17 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/define-category.json` | Baseline captured with `--provider codex`; 50/50 MC activation, 0 errors. |
| recall | manage-memory | `plugins/RECALL/plugins/recall/skills/manage-memory` | 194 | yes | yes | 0.917 | 0.845 | 0.829 | 82.55 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/manage-memory.json` | Baseline captured with `--provider codex`; 45/50 MC activation, 5 errors. |
| recall | memory-hygiene | `plugins/RECALL/plugins/recall/skills/memory-hygiene` | 216 | yes | yes | 0.856 | 0.818 | 0.785 | 80.17 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/memory-hygiene.json` | Baseline captured with `--provider codex`; 41/50 MC activation, 9 errors. |
| recall | retrieve-memory | `plugins/RECALL/plugins/recall/skills/retrieve-memory` | 158 | yes | yes | 0.936 | 0.810 | 0.801 | 81.07 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/retrieve-memory.json` | Baseline captured with `--provider codex`; 42/50 MC activation, 8 errors. |
| recall | review-memory | `plugins/RECALL/plugins/recall/skills/review-memory` | 158 | yes | yes | 0.916 | 0.805 | 0.823 | 81.36 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/review-memory.json` | Baseline captured with `--provider codex`; 44/50 MC activation, 6 errors. |
| recall | save-insight | `plugins/RECALL/plugins/recall/skills/save-insight` | 198 | yes | yes | 0.937 | 0.810 | 0.896 | 84.28 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/save-insight.json` | Baseline captured with `--provider codex`; 50/50 MC activation, 0 errors. |
| recall | using-recall | `plugins/RECALL/plugins/recall/skills/using-recall` | 224 | yes | yes | 0.869 | 0.798 | 0.859 | 82.21 | gold | 0 | `docs/eval-baselines/2026-07-06/recall/using-recall.json` | Baseline captured with `--provider codex`; 47/50 MC activation, 3 errors. |
| plugin-evaluation-kimi | evaluation-methodology | `plugins/plugin-evaluation-kimi/skills/evaluation-methodology` | 551 | yes | no | 0.720 | 0.960 | 0.980 | 80.44 | gold | 3 | `docs/eval-baselines/2026-07-06/plugin-evaluation-kimi/evaluation-methodology.json` | Baseline captured. Static flags: two `ORPHAN_REFERENCE` from example `references/filename(.md)` text and one `DEAD_CROSS_REF` for `skill/agent`; likely parser false positives, still part of baseline. |
| agent-handoff | agent-handoff | `plugins/agent-handoff/skills/agent-handoff` | 111 | yes | no | 0.675 | 0.795 | 0.811 | 74.77 | silver | 0 | `docs/eval-baselines/2026-07-06/agent-handoff/agent-handoff.json` | Baseline captured with `--provider codex`; Kimi-provider attempt failed from broken RECALL hook path. |
| customization-control | customization-audit | `plugins/customization-control/skills/customization-audit` | 113 | no | no | 0.597 | 0.790 | 0.501 | 59.31 | no_badge | 1 | `docs/eval-baselines/2026-07-06/customization-control/customization-audit.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER`, 33 MC errors. |
| customization-control | customization-dedupe | `plugins/customization-control/skills/customization-dedupe` | 100 | no | no | 0.506 | 0.837 | 0.464 | 47.42 | no_badge | 5 | `docs/eval-baselines/2026-07-06/customization-control/customization-dedupe.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER` plus 4 dead cross refs, 36 MC errors. |
| customization-control | customization-repair | `plugins/customization-control/skills/customization-repair` | 83 | no | no | 0.494 | 0.798 | 0.584 | 58.18 | no_badge | 1 | `docs/eval-baselines/2026-07-06/customization-control/customization-repair.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER`, 26 MC errors. |
| customization-control | customization-sync | `plugins/customization-control/skills/customization-sync` | 71 | no | no | 0.406 | 0.798 | 0.597 | 44.27 | no_badge | 6 | `docs/eval-baselines/2026-07-06/customization-control/customization-sync.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER` plus 5 dead cross refs, 25 MC errors. |
| customization-control | marketplace-manager | `plugins/customization-control/skills/marketplace-manager` | 78 | no | no | 0.521 | 0.798 | 0.476 | 55.21 | no_badge | 1 | `docs/eval-baselines/2026-07-06/customization-control/marketplace-manager.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER`, 35 MC errors. |
| customization-control | windows-customization-guard | `plugins/customization-control/skills/windows-customization-guard` | 118 | no | no | 0.575 | 0.798 | 0.379 | 55.30 | no_badge | 1 | `docs/eval-baselines/2026-07-06/customization-control/windows-customization-guard.json` | Baseline captured with `--provider codex`; `MISSING_TRIGGER`, 43 MC errors. |
| plugin-forge | import-existing | `plugins/plugin-forge/skills/import-existing` | 178 | yes | yes | 0.917 | 0.842 | 0.655 | 75.95 | silver | 0 | `docs/eval-baselines/2026-07-06/plugin-forge/import-existing.json` | Baseline captured with `--provider codex`; 20 MC errors. |
| plugin-forge | release-plugin | `plugins/plugin-forge/skills/release-plugin` | 255 | yes | yes | 0.912 | 0.845 | 0.753 | 80.37 | gold | 0 | `docs/eval-baselines/2026-07-06/plugin-forge/release-plugin.json` | Baseline captured with `--provider codex`; 12 MC errors. |
| plugin-forge | using-forge | `plugins/plugin-forge/skills/using-forge` | 194 | yes | yes | 0.920 | 0.845 | 0.740 | 79.17 | silver | 0 | `docs/eval-baselines/2026-07-06/plugin-forge/using-forge.json` | Baseline captured with `--provider codex`; 13 MC errors. |
| usage-pulse | pulse:usage-report | `plugins/usage-pulse/skills/usage-report` | 146 | yes | yes | 0.904 | 0.845 | 0.835 | 81.86 | gold | 0 | `docs/eval-baselines/2026-07-06/usage-pulse/usage-report.json` | Baseline captured with `--provider codex`; 5 MC errors. |
| usage-pulse | pulse:using-pulse | `plugins/usage-pulse/skills/using-pulse` | 152 | yes | yes | 0.898 | 0.823 | 0.641 | 74.71 | silver | 0 | `docs/eval-baselines/2026-07-06/usage-pulse/using-pulse.json` | Baseline captured with `--provider codex`; low MC activation and 21 MC errors. |
| computer-custom | computer-custom | `plugins/computer-custom/dist/computer-custom/skills/computer-custom` | 54 | no | no | 0.510 | 0.820 | 0.990 | 72.38 | silver | 1 | `docs/eval-baselines/2026-07-06/computer-custom/computer-custom.json` | Baseline captured. Static flag: `MISSING_TRIGGER`; judge/MC still route it well. |

## Per-Skill Dimension Matrix

Use one block per skill when transcribing detailed results. Duplicate this template for every skill or keep detailed data in JSON and use this table only for exceptions.

| Plugin | Skill | Triggering | Orchestration | Output | Scope | Progressive disclosure | Token efficiency | Robustness | Structure | Code templates | Ecosystem | Notes |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| plugin-evaluation-kimi | evaluation-methodology | 0.966 | 0.981 | 0.891 | 1.000 | 0.850 | 0.984 | 1.000 | 0.850 | 0.000 | 0.830 | `code_template_quality` unmeasured in composite output (`—` grade), represented as 0.000 by current model. |
| computer-custom | computer-custom | 0.904 | 0.750 | 0.858 | 0.750 | 0.200 | 1.000 | 1.000 | 0.400 | 0.000 | 0.500 | MC strong despite static weakness; short skill and passive description drive low static dimensions. |
| webde-access | webde-access | 0.799 | 0.756 | 0.890 | 0.750 | 0.650 | 0.425 | 0.760 | 0.800 | 0.000 | 0.750 | Current artifact: 38/50 MC activation, 12 errors; earlier Codex run scored higher but was overwritten by rerun. |
| agent-handoff | agent-handoff | 0.808 | 0.762 | 0.898 | 0.750 | 0.650 | 0.442 | 0.860 | 0.300 | 0.000 | 0.500 | MC 43/50 activation, 7 errors. |
| usage-pulse | pulse:usage-report | 0.927 | 0.781 | 0.899 | 0.750 | 0.800 | 0.401 | 0.900 | 0.850 | 0.000 | 0.750 | MC 45/50 activation, 5 errors. |
| usage-pulse | pulse:using-pulse | 0.712 | 0.781 | 0.909 | 0.750 | 0.800 | 0.417 | 0.580 | 0.750 | 0.000 | 0.750 | MC 29/50 activation, 21 errors; strongest current instability. |
| plugin-forge | import-existing | 0.748 | 0.781 | 0.891 | 0.750 | 0.800 | 0.423 | 0.600 | 0.900 | 0.000 | 0.750 | MC 30/50 activation, 20 errors. |
| plugin-forge | release-plugin | 0.844 | 0.769 | 0.908 | 0.750 | 0.900 | 0.419 | 0.760 | 0.950 | 0.000 | 0.750 | MC 38/50 activation, 12 errors. |
| plugin-forge | using-forge | 0.832 | 0.781 | 0.910 | 0.750 | 0.800 | 0.411 | 0.740 | 0.950 | 0.000 | 0.750 | MC 37/50 activation, 13 errors. |
| customization-control | customization-audit | 0.493 | 0.769 | 0.862 | 0.750 | 0.500 | 0.444 | 0.340 | 0.400 | 0.000 | 0.500 | Parser sees `MISSING_TRIGGER`; MC 17/50 activation, 33 errors. |
| customization-control | customization-dedupe | 0.480 | 0.781 | 0.887 | 0.750 | 0.500 | 0.439 | 0.280 | 0.500 | 0.000 | 0.750 | 5 static flags; MC 14/50 activation, 36 errors. |
| customization-control | customization-repair | 0.577 | 0.744 | 0.870 | 0.750 | 0.200 | 0.444 | 0.480 | 0.200 | 0.000 | 0.500 | MC 24/50 activation, 26 errors. |
| customization-control | customization-sync | 0.589 | 0.750 | 0.867 | 0.750 | 0.200 | 0.434 | 0.500 | 0.550 | 0.000 | 0.750 | 6 static flags; MC 25/50 activation, 25 errors. |
| customization-control | marketplace-manager | 0.469 | 0.750 | 0.865 | 0.750 | 0.200 | 0.426 | 0.300 | 0.400 | 0.000 | 0.500 | MC 15/50 activation, 35 errors. |
| customization-control | windows-customization-guard | 0.373 | 0.756 | 0.868 | 0.750 | 0.500 | 0.422 | 0.140 | 0.450 | 0.000 | 0.500 | Internal skill still evaluated; MC 7/50 activation, 43 errors. |
| recall | define-category | 0.965 | 1.000 | 0.930 | 0.750 | 0.800 | 0.413 | 1.000 | 0.950 | 0.000 | 0.990 | Strongest RECALL result; 50/50 activation, 0 errors. |
| recall | manage-memory | 0.919 | 0.781 | 0.896 | 0.750 | 0.800 | 0.420 | 0.900 | 0.950 | 0.000 | 1.000 | MC 45/50 activation, 5 errors. |
| recall | memory-hygiene | 0.830 | 0.769 | 0.896 | 0.750 | 0.900 | 0.424 | 0.820 | 0.950 | 0.000 | 0.750 | Lowest RECALL score; MC 41/50 activation, 9 errors. |
| recall | retrieve-memory | 0.869 | 0.781 | 0.902 | 0.750 | 0.800 | 0.420 | 0.840 | 0.950 | 0.000 | 1.000 | MC 42/50 activation, 8 errors. |
| recall | review-memory | 0.884 | 0.781 | 0.885 | 0.750 | 0.800 | 0.415 | 0.880 | 0.950 | 0.000 | 0.990 | MC 44/50 activation, 6 errors. |
| recall | save-insight | 0.965 | 0.781 | 0.896 | 0.750 | 0.800 | 0.424 | 1.000 | 0.950 | 0.000 | 1.000 | 50/50 activation, 0 errors. |
| recall | using-recall | 0.902 | 0.781 | 0.872 | 0.750 | 0.900 | 0.427 | 0.940 | 0.850 | 0.000 | 0.750 | Session contract skill; MC 47/50 activation, 3 errors. |
|  |  |  |  |  |  |  |  |  |  |  |  |  |

## Plugin Rollup Matrix

Rollup should be computed after all skill rows for a plugin are complete. Recommended rollup fields:

- `skill_count`
- `mean_composite`
- `median_composite`
- `min_composite`
- `max_composite`
- `mean_triggering_accuracy`
- `mean_orchestration_fitness`
- `mean_output_quality`
- `mean_robustness`
- `total_anti_patterns`
- `mc_total_runs`
- `mc_total_errors`
- `lowest_skill`
- `highest_skill`
- `baseline_decision`

| Plugin | Skills done | Mean | Median | Min | Max | Mean trigger | Mean orchestration | Mean output | Mean robustness | Anti-patterns | MC runs | MC errors | Lowest skill | Highest skill | Baseline decision | Notes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| webde-access | 1/1 | 75.72 | 75.72 | 75.72 | 75.72 | 0.799 | 0.756 | 0.890 | 0.760 | 0 | 50 | 12 | webde-access | webde-access | Captured | Silver; current Codex rerun has 38/50 activation and 12 MC errors. |
| recall | 7/7 | 82.97 | 82.21 | 80.17 | 89.17 | 0.905 | 0.811 | 0.897 | 0.911 | 0 | 350 | 31 | memory-hygiene | define-category | Captured | All Gold; strongest plugin rollup so far. |
| plugin-evaluation-kimi | 1/1 | 80.44 | 80.44 | 80.44 | 80.44 | 0.966 | 0.981 | 0.891 | 1.000 | 3 | 50 | 0 | evaluation-methodology | evaluation-methodology | Captured | Gold despite 0.85 anti-pattern penalty; MC activation 50/50. |
| agent-handoff | 1/1 | 74.77 | 74.77 | 74.77 | 74.77 | 0.808 | 0.762 | 0.898 | 0.860 | 0 | 50 | 7 | agent-handoff | agent-handoff | Captured | Silver; Codex provider used after Kimi hook failure. |
| customization-control | 6/6 | 53.28 | 55.26 | 44.27 | 59.31 | 0.497 | 0.758 | 0.870 | 0.340 | 15 | 300 | 198 | customization-sync | customization-audit | Captured | All no_badge; frontmatter `when_to_use` not credited by parser; high MC error rate. |
| plugin-forge | 3/3 | 78.50 | 79.17 | 75.95 | 80.37 | 0.808 | 0.777 | 0.903 | 0.700 | 0 | 150 | 45 | import-existing | release-plugin | Captured | Release-plugin Gold; import-existing most unstable. |
| usage-pulse | 2/2 | 78.29 | 78.29 | 74.71 | 81.86 | 0.820 | 0.781 | 0.904 | 0.740 | 0 | 100 | 26 | pulse:using-pulse | pulse:usage-report | Captured | Mixed: report skill Gold, using skill Silver with 21 MC errors. |
| computer-custom | 1/1 | 72.38 | 72.38 | 72.38 | 72.38 | 0.904 | 0.750 | 0.858 | 1.000 | 1 | 50 | 0 | computer-custom | computer-custom | Captured | Silver; static-only weakness does not match MC routing behavior. |

## Baseline Run Checklist

Before running:

- Confirm dirty submodule state is intentional.
- Record marketplace commit and each plugin commit/submodule SHA.
- Confirm provider backend and model.
- Create `docs/eval-baselines/YYYY-MM-DD/`.
- Run one skill first and inspect JSON shape before starting batch.
- Do not use plugin-level deep score as baseline; certify skill paths.

During run:

- Save stdout JSON directly to per-skill artifact.
- Capture stderr warnings separately if any.
- Preserve failed JSON/error output; failures are baseline data.
- Do not edit skill files between first and last baseline run unless restarting baseline.

After run:

- Validate every artifact parses as JSON.
- Fill skill target matrix.
- Fill plugin rollup matrix.
- Record evaluator/runtime anomalies.
- Mark this baseline as comparison anchor, not release approval.

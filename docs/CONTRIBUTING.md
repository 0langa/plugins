# Development and publishing

This is a personal plugin collection. Maintained plugins receive updates as needed; dormant plugins remain available without planned updates. Kimi compatibility is legacy.

## Development checkout

```shell
git clone --recurse-submodules https://github.com/0langa/plugins.git
cd plugins
```

For an existing checkout, run `git submodule update --init --recursive`. Submodules are needed for development, validation, and local Kimi installs. Codex and Claude Code fetch their plugins directly from the pinned source repositories.

The existing local checkout may keep its old directory name. Repository URLs and local directory names are independent.

## Catalog ownership

Edit the canonical registry, `plugins.json`. It owns marketplace branding, plugin IDs, maintenance and provider-support status, descriptions, release pins, requirements, examples, and artwork references. Existing `installPaths` and `installCommands` fields remain available to older tools; `installCommands` is derived output.

Regenerate the three provider catalogs, derived install commands, README, and plugin pages:

```powershell
pwsh -NoProfile -File scripts/generate-marketplace.ps1 -Write
```

Use `-Check` (the default) to detect drift without changing files. Do not hand-edit generated output.

Plugin versions must agree with their source manifests. A source ref is the immutable release tag v&lt;version&gt;; sha is its full lowercase commit SHA. Optional source.path locates a plugin subdirectory inside its source repository. Keep the matching submodule pinned to that same commit.

Maintenance values are maintained and dormant. Provider support matches maintenance for Codex and Claude Code, and is legacy for Kimi. Functional categories remain in the registry; native catalog categories expose the maintenance groups. Plugin IDs and the marketplace ID 0langas-plugins are stable.

The generator uses PowerShell 7 and no additional modules. Source plugin authoring stays in the source repository. Where a source already has forge.yaml, update its canonical metadata before regenerating manifests. Forge registration can update existing registry metadata, but the marketplace generator must still run afterward.

## Validation

Run `scripts/validate-marketplace.ps1` for generated-file drift, catalog membership, release pins, source manifests, assets, and secret hygiene. `-CatalogOnly` skips source-repository and Git pin checks; it does not replace full validation before publication.

```powershell
pwsh -NoProfile -File scripts/validate-marketplace.ps1
python -m unittest discover -s tests -q
```

The Python unittest suite in `tests/` exercises generator regressions. Fixtures live in temporary directories and never start plugin runtimes. CI runs these checks on pushes and pull requests.

Use `scripts/test-marketplace-e2e.ps1` to install the catalog into disposable Codex and Claude profiles. It compares installed IDs and versions with the registry and checks Claude's reported loading errors. `-MarketplaceSource` accepts a local checkout or Git URL; `-AlsoVerifySource` compares both addresses’ Git HEADs, then refreshes the registered catalogs while checking that the marketplace identity stays unchanged. `-KeepTemp` retains profiles for inspection. Otherwise they are removed after the run.

```powershell
pwsh -NoProfile -File scripts/test-marketplace-e2e.ps1 -MarketplaceSource https://github.com/0langa/plugins.git -AlsoVerifySource https://github.com/0langa/0langas-plugin-marketplace.git
```

For migration testing, register the old address in a disposable profile before a release, then refresh that registration after publication. Confirm that the marketplace ID, installed plugins, and enablement are unchanged.

Windows isolation defaults to a short path on the system drive to avoid nested Git/MSIX path expansion. `-IsolationRoot` selects another short directory. These scripts do not modify your normal plugin installations.

Catalog tools are silent on success. Use `-Verbose` for diagnostic output. Failures include the relevant command or file.

## Release sequence

1. Prepare source documentation and metadata changes on isolated branches. Preserve unrelated work.
2. Run the source repository's relevant checks. Do not run model evaluations, send email, or perform paid calls as part of catalog validation.
3. Publish patch releases for modified source packages. Never move an existing release tag.
4. Update registry versions, refs, SHAs, and corresponding submodule commits.
5. Regenerate, run full marketplace validation, and run isolated Codex/Claude installation tests.
6. Commit and publish the marketplace release. Verify its published catalog and fresh installation paths.
7. Refresh already registered marketplaces without adding missing plugins or changing plugin enablement.

## Repository rename and compatibility

The public address is https://github.com/0langa/plugins. The former 0langa/0langas-plugin-marketplace address redirects here. Do not reuse that old repository name: doing so would remove GitHub's redirect.

Codex has a separate marketplace display title, 0langa’s Plugins. Claude Code uses the stable marketplace ID as its label; its description carries the friendly title. The Kimi catalog does not invent a separate marketplace-title field.

The marketplace retains nine Codex/Claude entries and eight legacy Kimi entries. Dormant does not mean removed, disabled, or archived on GitHub.

## Historical records

CHANGELOG.md records past releases. Dated files in docs/audits/, docs/eval-baselines/, and the older compatibility notes record evidence at the stated date; they are not current support promises. Design artwork under docs/logo-explorations/ is historical source material. Current plugin information is generated from the registry.

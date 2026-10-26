[CmdletBinding(DefaultParameterSetName = 'Check')]
param(
    [Parameter(ParameterSetName = 'Check')][switch]$Check,
    [Parameter(Mandatory, ParameterSetName = 'Write')][switch]$Write,
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Root = [IO.Path]::GetFullPath($Root)
$registryPath = Join-Path $Root 'plugins.json'
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json -AsHashtable
$tick = [string][char]96
$fence = $tick * 3
$providerNames = @{ codex = 'Codex'; 'claude-code' = 'Claude Code'; 'kimi-code' = 'Kimi Code' }

function Require-Text($Object, [string]$Key, [string]$Context) {
    if (-not $Object.Contains($Key) -or $Object[$Key] -isnot [string] -or [string]::IsNullOrWhiteSpace($Object[$Key])) {
        throw "$Context requires a nonempty '$Key' string."
    }
}

function Resolve-ContainedPath([string]$Relative, [string]$Context) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[/\\])\.\.([/\\]|$)') {
        throw "$Context must stay inside the marketplace: $Relative"
    }
    $resolved = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $resolved.StartsWith($Root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Context escapes the marketplace: $Relative"
    }
    return $resolved
}

function As-Json($Value) {
    return ($Value | ConvertTo-Json -Depth 30).Replace("$([char]13)$([char]10)", "$([char]10)") + "$([char]10)"
}

function Inline-Code([string]$Value) { return "$tick$Value$tick" }

function Provider-List($Plugin) {
    return (@($Plugin.providers | ForEach-Object {
        $label = $providerNames[$_]
        if ($Plugin.providerSupport[$_] -eq 'legacy') { $label += ' (legacy)' }
        $label
    }) -join ', ')
}

function Catalog-Description($Plugin) {
    if ($Plugin.maintenance -eq 'dormant') { return "Dormant: $($Plugin.description) Available as-is, with no planned updates." }
    return [string]$Plugin.description
}

if ($registry.schemaVersion -ne 1) { throw 'Unsupported registry schemaVersion; expected 1.' }
$marketplace = $registry.marketplace
foreach ($key in @('name', 'displayName', 'repository', 'version', 'description')) { Require-Text $marketplace $key 'Marketplace' }
if ($marketplace.name -ne '0langas-plugins') { throw 'Marketplace identity must remain 0langas-plugins.' }
if ($marketplace.repository -notmatch '^https://github\.com/[^/]+/[^/]+$') { throw 'Marketplace repository must be an HTTPS GitHub repository URL.' }
if (@($registry.plugins).Count -eq 0) { throw 'The registry must contain plugins.' }
$seen = @{}
foreach ($plugin in $registry.plugins) {
    foreach ($key in @('name', 'displayName', 'description', 'repository', 'version', 'license', 'pluginRoot', 'maintenance', 'category', 'platforms', 'example')) {
        Require-Text $plugin $key 'Plugin'
    }
    $name = [string]$plugin.name
    if ($name -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Invalid plugin ID: $name" }
    if ($seen.ContainsKey($name)) { throw "Duplicate plugin ID: $name" }
    $seen[$name] = $true
    if ($plugin.maintenance -notin @('maintained', 'dormant')) { throw "$name has an invalid maintenance status." }
    if ($plugin.version -notmatch '^\d+\.\d+\.\d+$') { throw "$name requires a semantic release version." }
    if ($plugin.repository -notmatch '^https://github\.com/[^/]+/[^/]+$') { throw "$name requires an HTTPS GitHub repository URL." }
    $null = Resolve-ContainedPath $plugin.pluginRoot "$name pluginRoot"
    foreach ($field in @('prerequisites', 'setup')) {
        if (-not $plugin.Contains($field) -or $plugin[$field] -isnot [array] -or @($plugin[$field]).Count -eq 0) {
            throw "$name requires a nonempty '$field' array."
        }
        foreach ($item in $plugin[$field]) {
            if ($item -isnot [string] -or [string]::IsNullOrWhiteSpace($item)) { throw "$name has an empty or invalid '$field' item." }
        }
    }
    if ($plugin.providers -isnot [array] -or @($plugin.providers).Count -eq 0) { throw "$name requires providers." }
    if (@($plugin.providers | Select-Object -Unique).Count -ne @($plugin.providers).Count) { throw "$name has duplicate providers." }
    if (@($plugin.providerSupport.Keys).Count -ne @($plugin.providers).Count) { throw "$name providerSupport disagrees with providers." }
    foreach ($provider in $plugin.providers) {
        if (-not $providerNames.ContainsKey($provider)) { throw "$name has an unknown provider: $provider" }
        if (-not $plugin.providerSupport.Contains($provider)) { throw "$name is missing support status for $provider." }
        $expected = if ($provider -eq 'kimi-code') { 'legacy' } else { $plugin.maintenance }
        if ($plugin.providerSupport[$provider] -ne $expected) { throw "$name has an inconsistent support status for $provider." }
    }
    foreach ($key in @('ref', 'sha')) { Require-Text $plugin.source $key "$name source" }
    if ($plugin.source.ref -ne "v$($plugin.version)" -or $plugin.source.sha -notmatch '^[0-9a-f]{40}$') {
        throw "$name has an inconsistent release pin; use v<version> and a full commit SHA."
    }
    if ($plugin.source.Contains('path')) { $null = Resolve-ContainedPath $plugin.source.path "$name source.path" }
    foreach ($key in @('icon', 'logo')) {
        Require-Text $plugin.assets $key "$name assets"
        $asset = Resolve-ContainedPath $plugin.assets[$key] "$name asset"
        if (-not (Test-Path -LiteralPath $asset -PathType Leaf)) { throw "$name asset is missing: $($plugin.assets[$key])" }
    }
}

$plugins = @($registry.plugins | Sort-Object @{ Expression = { if ($_.maintenance -eq 'maintained') { 0 } else { 1 } } }, @{ Expression = { $_.displayName.ToLowerInvariant() } })
$registry.plugins = $plugins
$codex = [ordered]@{ name = $marketplace.name; interface = [ordered]@{ displayName = $marketplace.displayName }; plugins = @() }
$claude = [ordered]@{
    name = $marketplace.name
    description = "$($marketplace.displayName): $($marketplace.description) Maintained and dormant plugins; Kimi compatibility is legacy."
    owner = [ordered]@{ name = '0langa'; url = 'https://github.com/0langa' }
    version = $marketplace.version
    plugins = @()
}
$kimi = [ordered]@{ version = '2'; plugins = @() }
$outputs = [ordered]@{}
$generatedNotice = '<!-- Generated by scripts/generate-marketplace.ps1 from plugins.json. -->'

foreach ($plugin in $plugins) {
    $name = $plugin.name
    $group = if ($plugin.maintenance -eq 'maintained') { 'Maintained' } else { 'Dormant' }
    $commands = [ordered]@{}
    if ('codex' -in $plugin.providers) { $commands.codex = "codex plugin add $name@$($marketplace.name)" }
    if ('claude-code' -in $plugin.providers) { $commands.'claude-code' = "claude plugin install $name@$($marketplace.name)" }
    if ('kimi-code' -in $plugin.providers) {
        $commands.'kimi-code-marketplace' = '/plugins marketplace C:\path\to\plugins\kimi-marketplace.json'
        $commands.'kimi-code' = '/plugins install C:\path\to\plugins\' + $plugin.pluginRoot.Replace('/', '\')
    }
    $plugin.installCommands = $commands
    $source = [ordered]@{ source = 'url'; url = "$($plugin.repository).git"; ref = $plugin.source.ref; sha = $plugin.source.sha }
    if ($plugin.source.Contains('path')) { $source.source = 'git-subdir'; $source.path = $plugin.source.path }
    if ('codex' -in $plugin.providers) {
        $codex.plugins += [ordered]@{
            name = $name; source = $source
            policy = [ordered]@{ installation = 'AVAILABLE'; authentication = 'ON_INSTALL' }
            category = $group
        }
    }
    if ('claude-code' -in $plugin.providers) {
        $claude.plugins += [ordered]@{
            name = $name; source = $source; displayName = $plugin.displayName
            description = (Catalog-Description $plugin); version = $plugin.version
            repository = $plugin.repository; homepage = "$($marketplace.repository)/blob/main/docs/plugins/$name/README.md"
            license = $plugin.license; category = $group
            tags = @($plugin.maintenance, $plugin.category.ToLowerInvariant().Replace(' ', '-'))
        }
    }
    if ('kimi-code' -in $plugin.providers) {
        $label = $plugin.displayName
        if ($plugin.maintenance -eq 'dormant') { $label += ' (Dormant)' }
        $kimi.plugins += [ordered]@{ id = $name; displayName = $label; source = "./$($plugin.pluginRoot)" }
    }

    $doc = [Collections.Generic.List[string]]::new()
    $doc.Add($generatedNotice)
    $doc.Add("# $($plugin.displayName)")
    $doc.Add('')
    $doc.Add($plugin.description)
    $doc.Add('')
    $doc.Add("| Maintenance | $group |")
    $doc.Add('|---|---|')
    $doc.Add("| Version | $($plugin.version) |")
    $doc.Add("| Clients | $(Provider-List $plugin) |")
    $doc.Add("| License | $($plugin.license) |")
    $doc.Add("| Source | [Repository]($($plugin.repository)) |")
    $doc.Add('')
    $doc.Add($(if ($group -eq 'Dormant') { '**Dormant:** Available as-is, with no planned updates. Existing releases remain installable.' } else { 'Personally used and maintained as needed, without a release schedule or support guarantee.' }))
    $doc.Add('')
    $doc.Add('## Example request')
    $doc.Add('')
    $doc.Add("> $($plugin.example)")
    $doc.Add('')
    $doc.Add('## Requirements')
    $doc.Add('')
    $doc.Add($plugin.platforms)
    $doc.Add('')
    foreach ($item in $plugin.prerequisites) { $doc.Add("- $item") }
    $doc.Add('')
    $doc.Add('## Install')
    $doc.Add('')
    foreach ($provider in @('codex', 'claude-code')) {
        if ($provider -notin $plugin.providers) { continue }
        $cli = if ($provider -eq 'codex') { 'codex' } else { 'claude' }
        $doc.Add("### $($providerNames[$provider])")
        $doc.Add('')
        $doc.Add($fence + 'shell')
        $doc.Add("$cli plugin marketplace add $($marketplace.repository).git")
        $doc.Add($commands[$provider])
        $doc.Add($fence)
        $doc.Add('')
    }
    $doc.Add('## Setup and use')
    $doc.Add('')
    foreach ($item in $plugin.setup) { $doc.Add("- $item") }
    $doc.Add('')
    if ('kimi-code' -in $plugin.providers) {
        $doc.Add('## Legacy Kimi compatibility')
        $doc.Add('')
        $doc.Add('Kimi compatibility is retained but is not actively tested. First prepare a [recursive checkout](../../CONTRIBUTING.md#development-checkout). Replace the example path with your checkout.')
        $doc.Add('')
        $doc.Add($fence + 'text')
        $doc.Add($commands.'kimi-code-marketplace')
        $doc.Add($commands.'kimi-code')
        $doc.Add('/reload')
        $doc.Add($fence)
        $doc.Add('')
    }
    $doc.Add("[Full source documentation]($($plugin.repository)#readme) · [All plugins](../../../README.md)")
    $outputs["docs/plugins/$name/README.md"] = ($doc -join "$([char]10)") + "$([char]10)"
}

$readme = [Collections.Generic.List[string]]::new()
$readme.Add($generatedNotice)
$readme.Add("# $($marketplace.displayName)")
$readme.Add('')
$readme.Add($marketplace.description)
$readme.Add('')
$readme.Add('**Maintained** plugins are still part of my workflow and receive updates as needed, without a release schedule or support guarantee. **Dormant** plugins remain available as-is, with no planned updates.')
$readme.Add('')
$readme.Add('Codex and Claude Code are the current clients for maintained plugins. Kimi compatibility is legacy and is not actively tested.')
$readme.Add('')
foreach ($status in @('maintained', 'dormant')) {
    $readme.Add($(if ($status -eq 'maintained') { '## Maintained plugins' } else { '## Dormant plugins' }))
    $readme.Add('')
    $readme.Add('| Plugin | What it does |')
    $readme.Add('|---|---|')
    foreach ($plugin in @($plugins | Where-Object maintenance -eq $status)) {
        $readme.Add(('| <img src="{0}" width="24" height="24" alt=""> [{1}](docs/plugins/{2}/README.md) | {3} |' -f $plugin.assets.icon, $plugin.displayName, $plugin.name, $plugin.description.Replace('|', '\|')))
    }
    $readme.Add('')
}
$readme.Add('## Install a plugin')
$readme.Add('')
$readme.Add('Add the marketplace once, then install the plugin you want. Each plugin page lists its setup and operating-system requirements.')
$readme.Add('')
foreach ($cli in @('codex', 'claude')) {
    $label = if ($cli -eq 'codex') { 'Codex' } else { 'Claude Code' }
    $verb = if ($cli -eq 'codex') { 'add' } else { 'install' }
    $readme.Add("### $label")
    $readme.Add('')
    $readme.Add($fence + 'shell')
    $readme.Add("$cli plugin marketplace add $($marketplace.repository).git")
    $readme.Add("$cli plugin $verb recall@$($marketplace.name)")
    $readme.Add($fence)
    $readme.Add('')
}
$readme.Add('Start a new session after installing. Installing this marketplace does not install every plugin.')
$readme.Add('')
$readme.Add('## Names and existing installations')
$readme.Add('')
$readme.Add("The repository is $(Inline-Code '0langa/plugins'); the stable marketplace ID is $(Inline-Code $marketplace.name). Codex displays **$($marketplace.displayName)**. Claude Code uses the stable ID as its marketplace label. Existing plugin IDs and installation commands remain unchanged.")
$readme.Add('')
$readme.Add('The previous GitHub repository address redirects here. Existing registrations can continue using that address; use the new address for new installations.')
$readme.Add('')
$readme.Add('## Legacy Kimi compatibility')
$readme.Add('')
$readme.Add("The eight Kimi entries remain in $(Inline-Code 'kimi-marketplace.json'). Computer Custom is Codex/Claude-only. Kimi setup is documented on each plugin page and requires a recursive local checkout.")
$readme.Add('')
$readme.Add('## Project information')
$readme.Add('')
$readme.Add('- [Development, validation, and publishing](docs/CONTRIBUTING.md)')
$readme.Add('- [Release history](CHANGELOG.md)')
$readme.Add('- Report a catalog or installation problem in this repository; report plugin behavior in its source repository. Dormant plugins have no planned fixes.')
$readme.Add('')
$readme.Add('Individual plugins retain their own licenses. This repository is MIT licensed.')
$outputs['README.md'] = ($readme -join "$([char]10)") + "$([char]10)"
$outputs['plugins.json'] = As-Json $registry
$outputs['.agents/plugins/marketplace.json'] = As-Json $codex
$outputs['.claude-plugin/marketplace.json'] = As-Json $claude
$outputs['kimi-marketplace.json'] = As-Json $kimi

# Reject leftover generated plugin pages instead of silently leaving removed entries visible.
if (Test-Path -LiteralPath (Join-Path $Root 'docs/plugins')) {
    foreach ($directory in Get-ChildItem -LiteralPath (Join-Path $Root 'docs/plugins') -Directory) {
        if (-not $seen.ContainsKey($directory.Name)) { throw "Orphan plugin documentation: $($directory.Name)" }
    }
}
$drift = [Collections.Generic.List[string]]::new()
foreach ($relative in $outputs.Keys) {
    $path = Resolve-ContainedPath $relative 'Generated output'
    $expected = $outputs[$relative]
    $current = if (Test-Path -LiteralPath $path -PathType Leaf) { [IO.File]::ReadAllText($path).Replace("$([char]13)$([char]10)", "$([char]10)") } else { $null }
    if ($current -ceq $expected) { continue }
    if ($Write) {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
        [IO.File]::WriteAllText($path, $expected, [Text.UTF8Encoding]::new($false))
        Write-Verbose "Updated $relative"
    }
    else { $drift.Add($relative) }
}
if ($drift.Count) { throw "Generated files are stale: $($drift -join ', '). Run scripts/generate-marketplace.ps1 -Write." }

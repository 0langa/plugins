[CmdletBinding()]
param(
    [ValidateSet('all', 'codex', 'claude')][string]$Provider = 'all',
    [string]$MarketplaceSource,
    [string]$AlsoVerifySource,
    [string]$IsolationRoot,
    [string[]]$Plugins,
    [switch]$KeepTemp
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
& (Join-Path $PSScriptRoot 'validate-marketplace.ps1')
$registry = Get-Content -LiteralPath (Join-Path $repoRoot 'plugins.json') -Raw | ConvertFrom-Json
$marketplaceName = [string]$registry.marketplace.name
if (-not $Plugins) { $Plugins = @($registry.plugins.name) }
foreach ($name in $Plugins) { if ($name -notin $registry.plugins.name) { throw "Unknown requested plugin: $name" } }
if (@($Plugins | Select-Object -Unique).Count -ne $Plugins.Count) { throw 'Duplicate requested plugins.' }
if ([string]::IsNullOrWhiteSpace($MarketplaceSource)) { $MarketplaceSource = $repoRoot }
foreach ($variable in @('MarketplaceSource', 'AlsoVerifySource')) {
    $value = Get-Variable -Name $variable -ValueOnly
    if ($value -match '^[^/:]+/[^/]+$') { Set-Variable -Name $variable -Value "https://github.com/$value.git" }
}
if ([string]::IsNullOrWhiteSpace($IsolationRoot)) {
    $IsolationRoot = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        Join-Path ([IO.Path]::GetPathRoot([Environment]::SystemDirectory)) 'mp-e2e'
    } else { Join-Path ([IO.Path]::GetTempPath()) 'mp-e2e' }
}
$isolationRootPath = [IO.Path]::GetFullPath($IsolationRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
$testRoot = [IO.Path]::GetFullPath((Join-Path $isolationRootPath ([guid]::NewGuid().ToString('N'))))
if (-not $testRoot.StartsWith($isolationRootPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe temporary test root: $testRoot" }
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$codexHome = Join-Path $testRoot 'codex'
$claudeHome = Join-Path $testRoot 'claude'
foreach ($path in @($codexHome, $claudeHome)) { [IO.Directory]::CreateDirectory($path) | Out-Null }
$log = Join-Path $testRoot 'commands.log'

function Invoke-Client([string]$Command, [string[]]$Arguments, [switch]$Capture) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command $Command -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    # Prevent a local source-checkout catalog from masking the published catalog.
    $start.WorkingDirectory = $testRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.Environment['CODEX_HOME'] = $codexHome
    $start.Environment['CLAUDE_CONFIG_DIR'] = $claudeHome
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(600000)) {
            $process.Kill($true)
            throw "$Command $($Arguments -join ' ') timed out."
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        [IO.File]::AppendAllText($log, "$Command $($Arguments -join ' ')$([char]10)$stdout$stderr$([char]10)")
        if ($process.ExitCode -ne 0) { throw "$Command $($Arguments -join ' ') failed ($($process.ExitCode)):$([char]10)$stdout$stderr" }
        Write-Verbose "$Command $($Arguments -join ' ')"
        if ($Capture) { return $stdout }
    } finally { $process.Dispose() }
}

function Assert-Installed($Items, [string]$IdProperty, [string]$Client) {
    $matching = @($Items | Where-Object { $_.$IdProperty -like "*@$marketplaceName" })
    if ($matching.Count -ne $Plugins.Count) { throw "$Client installed plugin count differs from the requested catalog." }
    foreach ($name in $Plugins) {
        $entry = @($matching | Where-Object { $_.$IdProperty -eq "$name@$marketplaceName" })
        $expected = @($registry.plugins | Where-Object name -eq $name)[0]
        if ($entry.Count -ne 1 -or $entry[0].version -ne $expected.version -or -not $entry[0].enabled) {
            throw "$Client has a missing, duplicate, disabled, or wrong-version plugin: $name"
        }
    }
}

function Assert-CodexMarketplace {
    $list = (Invoke-Client codex @('plugin', 'marketplace', 'list', '--json') -Capture | ConvertFrom-Json).marketplaces
    $matching = @($list | Where-Object name -eq $marketplaceName)
    if ($matching.Count -ne 1) { throw 'Codex marketplace identity is missing or duplicated.' }
    $catalog = Get-Content -LiteralPath (Join-Path $matching[0].root '.agents/plugins/marketplace.json') -Raw | ConvertFrom-Json
    if ($catalog.interface.displayName -cne $registry.marketplace.displayName) { throw 'Codex marketplace title differs from the registry.' }
    foreach ($plugin in $registry.plugins) {
        $entries = @($catalog.plugins | Where-Object name -eq $plugin.name)
        if ($entries.Count -ne 1 -or $entries[0].source.sha -ne $plugin.source.sha) { throw "Codex catalog pin differs for $($plugin.name)." }
        if ($plugin.name -in $Plugins -and $plugin.maintenance -eq 'dormant') {
            $manifestPath = Join-Path $codexHome "plugins/cache/$marketplaceName/$($plugin.name)/$($plugin.version)/.codex-plugin/plugin.json"
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($manifest.interface.shortDescription -notlike 'Dormant:*') { throw "Installed dormant notice missing: $($plugin.name)" }
        }
    }
}

try {
    Invoke-Client claude @('plugin', 'validate', $repoRoot)
    if ($AlsoVerifySource) {
        $firstHead = Invoke-Client git @('ls-remote', $MarketplaceSource, 'HEAD') -Capture
        $secondHead = Invoke-Client git @('ls-remote', $AlsoVerifySource, 'HEAD') -Capture
        if (($firstHead.Trim() -split '\s+')[0] -ne ($secondHead.Trim() -split '\s+')[0]) { throw 'Marketplace addresses resolve to different Git commits.' }
    }
    if ($Provider -in @('all', 'codex')) {
        Invoke-Client codex @('plugin', 'marketplace', 'add', $MarketplaceSource)
        foreach ($plugin in $Plugins) { Invoke-Client codex @('plugin', 'add', "$plugin@$marketplaceName") }
        Assert-Installed ((Invoke-Client codex @('plugin', 'list', '--json', '--marketplace', $marketplaceName) -Capture | ConvertFrom-Json).installed) 'pluginId' 'Codex'
        Assert-CodexMarketplace
        if ($AlsoVerifySource) {
            Invoke-Client codex @('plugin', 'marketplace', 'upgrade', $marketplaceName)
            Assert-CodexMarketplace
            Assert-Installed ((Invoke-Client codex @('plugin', 'list', '--json', '--marketplace', $marketplaceName) -Capture | ConvertFrom-Json).installed) 'pluginId' 'Codex'
        }
    }
    if ($Provider -in @('all', 'claude')) {
        Invoke-Client claude @('plugin', 'marketplace', 'add', $MarketplaceSource)
        foreach ($plugin in $Plugins) { Invoke-Client claude @('plugin', 'install', "$plugin@$marketplaceName", '--scope', 'user') }
        $installed = @(Invoke-Client claude @('plugin', 'list', '--json') -Capture | ConvertFrom-Json)
        Assert-Installed $installed 'id' 'Claude'
        foreach ($entry in $installed) {
            if ($entry.PSObject.Properties['errors'] -and @($entry.errors).Count) { throw "Claude plugin load errors for $($entry.id): $($entry.errors -join '; ')" }
        }
        foreach ($plugin in @($registry.plugins | Where-Object { $_.name -in $Plugins -and $_.maintenance -eq 'dormant' })) {
            $installedRoot = Join-Path $claudeHome "plugins/cache/$marketplaceName/$($plugin.name)/$($plugin.version)"
            $manifest = Get-Content -LiteralPath (Join-Path $installedRoot '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json
            $readme = Get-Content -LiteralPath (Join-Path $installedRoot 'README.md') -Raw
            if ($manifest.description -notlike 'Dormant:*' -or $readme -notmatch 'Dormant') { throw "Claude installed dormant notice missing: $($plugin.name)" }
        }
        if ($AlsoVerifySource) { Invoke-Client claude @('plugin', 'marketplace', 'update', $marketplaceName) }
        $list = @(Invoke-Client claude @('plugin', 'marketplace', 'list', '--json') -Capture | ConvertFrom-Json)
        if (@($list | Where-Object name -eq $marketplaceName).Count -ne 1) { throw 'Claude marketplace identity is missing or duplicated.' }
        Assert-Installed @(Invoke-Client claude @('plugin', 'list', '--json') -Capture | ConvertFrom-Json) 'id' 'Claude'
    }
} finally {
    if ($KeepTemp) { Write-Verbose "Kept isolated client homes at $testRoot" }
    else {
        $resolved = [IO.Path]::GetFullPath($testRoot)
        if (-not $resolved.StartsWith($isolationRootPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to remove unsafe test path: $resolved" }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

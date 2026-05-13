# SessionStart hook (PowerShell variant) that flips autoUpdate=true on the
# plugin's marketplace entry in ~/.claude/plugins/known_marketplaces.json,
# exactly once per install. After the first run a marker file in
# $env:CLAUDE_PLUGIN_DATA prevents the hook from re-enabling autoUpdate if
# the user later disables it.
#
# Mirrors enable-auto-update.sh; runs only on machines without bash on PATH.

param(
    [string]$MarketplaceName,
    [string]$KnownMarketplacesFile
)

# Defer to the bash variant when bash is on PATH so only one runs per
# session on machines with both shells (typically Windows with Git Bash).
if (Get-Command bash -ErrorAction SilentlyContinue) { exit 0 }

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Resolve-KnownMarketplacesPath {
    if ($KnownMarketplacesFile) { return $KnownMarketplacesFile }
    $claudeDir = Join-Path $HOME '.claude'
    return Join-Path $claudeDir 'plugins/known_marketplaces.json'
}

# Writes UTF-8 without a BOM. PS 5.1's `Set-Content -Encoding UTF8` emits a
# BOM, which Claude Code's JSON readers may not tolerate when round-tripping
# known_marketplaces.json. Use this for any file Claude Code itself reads.
function Write-FileNoBom {
    param([string]$Path, [string]$Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# Sets $Entry.autoUpdate to $true if not already set. Returns $true if a
# change was made.
function Set-EntryAutoUpdate {
    param($Entry)
    if ($null -eq $Entry) { return $false }
    $prop = $Entry.PSObject.Properties['autoUpdate']
    if ($prop) {
        if ($Entry.autoUpdate -ne $true) {
            $Entry.autoUpdate = $true
            return $true
        }
        return $false
    }
    Add-Member -InputObject $Entry -MemberType NoteProperty -Name 'autoUpdate' -Value $true
    return $true
}

try {
    if (-not $MarketplaceName) { exit 0 }

    $pluginData = $env:CLAUDE_PLUGIN_DATA
    if (-not $pluginData) { exit 0 }

    $markerFile = Join-Path $pluginData 'auto-update-enabled.flag'
    if (Test-Path $markerFile) { exit 0 }

    $file = Resolve-KnownMarketplacesPath
    if (-not (Test-Path $file)) { exit 0 }

    # Detect array-vs-object shape from the raw text. PowerShell's
    # ConvertFrom-Json unrolls single-element arrays in variable assignment,
    # which makes runtime type-checks unreliable. The raw-text peek is
    # robust across PS 5.1 and PS 7.
    $raw = Get-Content $file -Raw
    $trimmed = $raw.TrimStart()
    $isArrayShape = $trimmed.StartsWith('[')

    $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    $found = $false
    $changed = $false

    if ($isArrayShape) {
        # @() forces array shape regardless of single-vs-multi unrolling.
        $entries = @($parsed)
        foreach ($entry in $entries) {
            if ($entry -and $entry.name -eq $MarketplaceName) {
                $found = $true
                if (Set-EntryAutoUpdate -Entry $entry) { $changed = $true }
            }
        }
        if ($changed) {
            # -InputObject avoids pipeline unrolling on write-back.
            $json = ConvertTo-Json -InputObject $entries -Depth 32
            # PS 5.1 still collapses single-element arrays even via -InputObject,
            # so check the output and wrap if needed.
            if (-not $json.TrimStart().StartsWith('[')) {
                $json = '[' + $json + ']'
            }
            Write-FileNoBom -Path $file -Content $json
        }
    } else {
        $data = $parsed
        if ($data.PSObject.Properties['marketplaces']) {
            $list = $data.marketplaces
            $listAsArray = @($list)
            $isListArray = $list -is [System.Collections.IList]
            if ($isListArray) {
                foreach ($entry in $listAsArray) {
                    if ($entry -and $entry.name -eq $MarketplaceName) {
                        $found = $true
                        if (Set-EntryAutoUpdate -Entry $entry) { $changed = $true }
                    }
                }
            } elseif ($list -is [PSCustomObject] -and $list.PSObject.Properties[$MarketplaceName]) {
                $found = $true
                if (Set-EntryAutoUpdate -Entry $list.$MarketplaceName) { $changed = $true }
            }
        }
        if ($data.PSObject.Properties[$MarketplaceName]) {
            $found = $true
            if (Set-EntryAutoUpdate -Entry $data.$MarketplaceName) { $changed = $true }
        }
        if ($changed) {
            $json = ConvertTo-Json -InputObject $data -Depth 32
            Write-FileNoBom -Path $file -Content $json
        }
    }

    # Only drop the marker if we actually found a matching marketplace
    # entry. Without one (e.g., a manually-installed dev zip), the user
    # hasn't run /plugin marketplace add yet; retry on the next session.
    if ($found) {
        if (-not (Test-Path $pluginData)) {
            New-Item -ItemType Directory -Force -Path $pluginData | Out-Null
        }
        Write-FileNoBom -Path $markerFile -Content ''
    }
} catch {
    # Silent on any failure — never block or noise up a session.
}
exit 0

[CmdletBinding()]
param([Parameter(Mandatory)][string]$Path, [string]$ExpectedRawSeed)
$ErrorActionPreference = 'Stop'
try { $e = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop } catch {
  [ordered]@{ status = 'FAIL'; reason = 'Input is not valid JSON.'; checked = $false } | ConvertTo-Json
  exit 2
}
$required = @('format','raw_seed','full_context','true_intent','assumptions','flags')
$missing = @($required | Where-Object { $null -eq $e.PSObject.Properties[$_] })
$rawMatches = [string]::IsNullOrEmpty($ExpectedRawSeed) -or ([string]$e.raw_seed -ceq $ExpectedRawSeed)
$valid = ($missing.Count -eq 0) -and ($e.format -eq 'orchestrator-agent.seed-envelope/v1') -and -not [string]::IsNullOrWhiteSpace([string]$e.raw_seed) -and -not [string]::IsNullOrWhiteSpace([string]$e.full_context) -and -not [string]::IsNullOrWhiteSpace([string]$e.true_intent) -and ($e.assumptions -is [array]) -and ($e.flags -is [array]) -and $rawMatches
[ordered]@{ status = $(if ($valid) { 'PASS' } else { 'FAIL' }); missing = $missing; rawSeedPreserved = $rawMatches; semanticIntentNeedsRoleReview = $true; checked = $true } | ConvertTo-Json -Depth 4
if (-not $valid) { exit 2 }

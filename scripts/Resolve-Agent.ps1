[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('ORCHESTRATE','PLAN','MAKE','CHECK','REFLECT')][string]$Phase,
  [Parameter(Mandatory)][string[]]$AvailableAgentId,
  [string]$CatalogPath = $env:ORCHESTRATOR_AGENT_MARKETPLACE_CATALOG
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($CatalogPath)) {
  $provider = Get-Content -LiteralPath (Join-Path $root 'providers\pmcro-agent-marketplace.json') -Raw | ConvertFrom-Json
  $CatalogPath = Join-Path $root $provider.catalogPath
}
if (-not (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
  [ordered]@{ status = 'BLOCKED'; phase = $Phase; reason = 'Marketplace catalog is missing.'; catalogPath = $CatalogPath; invoked = $false; executed = $false } | ConvertTo-Json -Depth 6
  exit 2
}
$catalogPathResolved = (Resolve-Path -LiteralPath $CatalogPath).Path
$catalog = Get-Content -LiteralPath $catalogPathResolved -Raw | ConvertFrom-Json
$entry = @($catalog.agents | Where-Object { $_.phase -eq $Phase -and $AvailableAgentId -contains $_.id } | Select-Object -First 1)
if ($entry.Count -eq 0) {
  [ordered]@{ status = 'BLOCKED'; phase = $Phase; reason = 'No matching catalog agent was reported available by the host.'; catalogPath = $catalogPathResolved; invoked = $false; executed = $false } | ConvertTo-Json -Depth 6
  exit 2
}

# Catalog repository paths are relative to the PMCR-O repository root, the parent of its catalog directory.
$catalogDirectory = Split-Path -Parent $catalogPathResolved
$catalogRoot = if ((Split-Path -Leaf $catalogDirectory) -eq 'catalog') { Split-Path -Parent $catalogDirectory } else { $catalogDirectory }
$item = $entry[0]
$repositoryPath = $catalogRoot
$entrypointRelative = $item.entrypoint
$inputSchemaRelative = $item.inputSchema
$outputSchemaRelative = $item.outputSchema
if ($item.sourceRepositoryPath) {
  $repositoryPath = Join-Path $catalogRoot $item.sourceRepositoryPath
  $entrypointRelative = $item.sourceEntrypoint
  $inputSchemaRelative = $item.sourceInputSchema
  $outputSchemaRelative = $item.sourceOutputSchema
}
$entrypoint = Join-Path $repositoryPath $entrypointRelative
$inputSchema = Join-Path $repositoryPath $inputSchemaRelative
$outputSchema = Join-Path $repositoryPath $outputSchemaRelative
$pathsToCheck = @($repositoryPath, $entrypoint, $inputSchema, $outputSchema)
$missing = @($pathsToCheck | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missing.Count -gt 0) {
  [ordered]@{ status = 'BLOCKED'; phase = $Phase; agentId = $item.id; reason = 'The catalogued source repository, skill, or schema is missing.'; missing = $missing; catalogPath = $catalogPathResolved; invoked = $false; executed = $false } | ConvertTo-Json -Depth 6
  exit 2
}
[ordered]@{
  status = 'ROUTE_RESOLVED'; phase = $Phase; agentId = $item.id; pluginMention = $item.pluginMention
  identityPrefix = $item.invocationPrefix; command = $item.commandAlias; canonicalHostCommand = $item.canonicalHostCommand
  skillId = $item.skillId; repositoryPath = $repositoryPath; inputMode = $item.inputMode
  inputSchema = $inputSchema; outputSchema = $outputSchema; apiReplySchema = (Join-Path $root $item.apiReplySchema)
  trailKind = $item.trailKind; entrypoint = $entrypoint; projectionEntrypoint = $item.projectionEntrypoint
  invoked = $false; executed = $false
} | ConvertTo-Json -Depth 6
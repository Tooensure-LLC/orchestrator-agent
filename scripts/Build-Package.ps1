param(
    [string]$Repo = (Split-Path -Parent $PSScriptRoot),
    [string]$OutDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist')
)
# Builds an Agent Plugins 1.0 package for the orchestrator plugin (seed skill only).
# Sources are never modified: a staged copy is patched so every path stays inside the package.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$src = Join-Path $Repo 'plugins\orchestrator'
$meta = Get-Content (Join-Path $src 'plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$stage = Join-Path $env:TEMP ("orchestrator-stage-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null

# 1. portable manifest (closed schema: only portable top-level fields)
$manifest = [ordered]@{
    '$schema'   = 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json'
    name        = $meta.name
    version     = $meta.version
    description = $meta.description
}
[IO.File]::WriteAllText("$stage\plugin.json", (($manifest | ConvertTo-Json) + "`n"), $utf8)

# 2. the seed skill, plus vendored copies of the files it reads from outside the plugin dir
Copy-Item (Join-Path $src 'skills') "$stage\skills" -Recurse
$ref = "$stage\skills\seed\references"
Copy-Item (Join-Path $Repo 'schemas\phase-reply.schema.json') "$ref\phase-reply.schema.json"
Copy-Item (Join-Path $Repo 'docs\handoff-contract.md')        "$ref\project-handoff-contract.md"
Copy-Item (Join-Path $Repo 'providers\pmcro-agent-marketplace.json') "$ref\pmcro-agent-marketplace.json"

function Patch($path, $from, $to) {
    $t = [IO.File]::ReadAllText($path)
    if (-not $t.Contains($from)) { throw "Patch target not found in $path : $from" }
    [IO.File]::WriteAllText($path, $t.Replace($from, $to), $utf8)
}
Patch "$stage\skills\seed\SKILL.md" '`../../../../providers/pmcro-agent-marketplace.json`' '`references/pmcro-agent-marketplace.json`'
Patch "$ref\handoff-contract.md" '(../../../../../docs/handoff-contract.md)' '(project-handoff-contract.md)'
Patch "$ref\output.schema.json" '../../../../../../schemas/phase-reply.schema.json' 'phase-reply.schema.json'

# 3. validate staged package
$problems = @()
Get-ChildItem $stage -Recurse -Filter *.json | ForEach-Object { try { Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null } catch { $problems += "invalid JSON: $($_.FullName)" } }
Get-ChildItem $stage -Recurse -File -Include SKILL.md,*.schema.json,handoff-contract.md | ForEach-Object {
    if ((Get-Content $_.FullName -Raw) -match '\(\.\./|"\$ref":\s*"\.\./|`\.\./') { $problems += "path escapes package: $($_.FullName.Replace($stage,''))" }
}
$skill = Get-Content "$stage\skills\seed\SKILL.md" -Raw
if ($skill -notmatch '(?m)^name: seed$') { $problems += 'SKILL.md name is not seed' }
if (-not (Test-Path "$stage\plugin.json")) { $problems += 'missing plugin.json' }
if (Test-Path "$stage\agents") { $problems += 'unexpected agents/' }
if (Test-Path "$stage\commands") { $problems += 'unexpected commands/' }
if ((Get-ChildItem "$stage\skills" -Directory).Count -ne 1) { $problems += 'plugin must contain exactly one skill' }
if ($problems.Count) { $problems | ForEach-Object { Write-Error $_ -ErrorAction Continue }; Remove-Item $stage -Recurse -Force; exit 2 }

# 4. zip with forward-slash entry names, plugin.json at archive root
New-Item -ItemType Directory -Force $OutDir | Out-Null
$zipPath = Join-Path $OutDir "orchestrator-agent.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($zipPath, 'Create')
try {
    Get-ChildItem $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
        $name = $_.FullName.Substring($stage.Length + 1).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $name, 'Optimal') | Out-Null
    }
} finally { $zip.Dispose() }
Remove-Item $stage -Recurse -Force
"BUILT $zipPath"

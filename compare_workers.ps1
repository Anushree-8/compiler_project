param(
    [Parameter(Mandatory = $true)][string]$InputFile,
    [ValidateRange(2, 256)][int]$Workers = 4
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $projectRoot 'plex.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "plex.exe not found. Build the project first: $exe" }
if ([System.IO.Path]::IsPathRooted($InputFile)) { $source = $InputFile }
else { $source = Join-Path (Get-Location).Path $InputFile }
if (-not (Test-Path -LiteralPath $source)) { throw "Input file not found: $source" }

function Get-TokenRows([int]$ThreadCount) {
    $output = @(& $exe $source --threads $ThreadCount --tokens)
    if ($LASTEXITCODE -ne 0) { throw "Plex exited with code $LASTEXITCODE for $ThreadCount workers." }
    return @($output | Where-Object { $_ -match '^\s*\d+:\d+\s+[A-Z_]+' })
}

$single = @(Get-TokenRows 1)
$parallel = @(Get-TokenRows $Workers)
$differences = @(Compare-Object -ReferenceObject $single -DifferenceObject $parallel)
Write-Output "Input: $source"
Write-Output "One-worker token rows: $($single.Count)"
Write-Output "$Workers-worker token rows: $($parallel.Count)"
if ($differences.Count -eq 0) {
    Write-Output 'PASS: token rows match exactly, including locations, types, and printed lexemes.'
    exit 0
}
Write-Output "FAIL: $($differences.Count) differing token rows. First differences:"
$differences | Select-Object -First 12 | Format-Table -AutoSize | Out-String | Write-Output
exit 1

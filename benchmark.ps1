param(
    [ValidateRange(3, 31)][int]$RepeatCount = 7,
    [int[]]$Workers = @(1, 2, 4, 8),
    [string[]]$InputFiles = @(
        '.\review2_evaluation\samples\large_token_dense_1mb.c',
        '.\review2_evaluation\samples\large_token_dense_5mb.c',
        '.\review2_evaluation\samples\large_comment_string_1mb.c',
        '.\review2_evaluation\samples\large_comment_string_5mb.c'
    )
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $projectRoot 'plex.exe'
$resultsDir = Join-Path $PSScriptRoot 'results'
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
if (-not (Test-Path -LiteralPath $exe)) { throw "plex.exe not found. Build the project first: $exe" }

$rows = New-Object System.Collections.Generic.List[object]
foreach ($input in $InputFiles) {
    if ([System.IO.Path]::IsPathRooted($input)) { $source = $input }
    else { $source = Join-Path (Get-Location).Path $input }
    if (-not (Test-Path -LiteralPath $source)) { throw "Input not found: $source. Run generate_large_samples.ps1 first." }
    $bytes = (Get-Item -LiteralPath $source).Length

    foreach ($workerCount in $Workers) {
        # One untimed warm-up, then repeated timed invocations.
        $summary = @(& $exe $source --threads $workerCount)
        if ($LASTEXITCODE -ne 0) { throw "Warm-up failed for $source with $workerCount workers." }
        $tokenLine = $summary | Where-Object { $_ -match '^Tokens:' } | Select-Object -First 1
        $errorLine = $summary | Where-Object { $_ -match '^Lexical errors:' } | Select-Object -First 1
        $chunkLine = $summary | Where-Object { $_ -match '^Chunks processed:' } | Select-Object -First 1
        $tokenCount = if ($tokenLine) { [int](($tokenLine -split ':')[1].Trim()) } else { -1 }
        $errorCount = if ($errorLine) { [int](($errorLine -split ':')[1].Trim()) } else { -1 }
        $chunks = if ($chunkLine) { [int](($chunkLine -split ':')[1].Trim()) } else { -1 }

        for ($trial = 1; $trial -le $RepeatCount; $trial++) {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            & $exe $source --threads $workerCount | Out-Null
            $exitCode = $LASTEXITCODE
            $timer.Stop()
            if ($exitCode -ne 0) { throw "Timed run failed for $source with $workerCount workers." }
            $rows.Add([pscustomobject]@{
                File = [System.IO.Path]::GetFileName($source)
                Bytes = $bytes
                RequestedWorkers = $workerCount
                ChunksProcessed = $chunks
                Tokens = $tokenCount
                LexicalErrors = $errorCount
                Trial = $trial
                Milliseconds = [math]::Round($timer.Elapsed.TotalMilliseconds, 3)
            })
        }
    }
}

$rawPath = Join-Path $resultsDir 'benchmark.csv'
$rows | Export-Csv -LiteralPath $rawPath -NoTypeInformation -Encoding UTF8
$medians = foreach ($group in ($rows | Group-Object File, RequestedWorkers)) {
    $sorted = @($group.Group | ForEach-Object { [double]$_.Milliseconds } | Sort-Object)
    $middle = [int][math]::Floor($sorted.Count / 2)
    $median = if ($sorted.Count % 2) { $sorted[$middle] } else { ($sorted[$middle - 1] + $sorted[$middle]) / 2 }
    $first = $group.Group[0]
    [pscustomobject]@{
        File = $first.File
        Bytes = $first.Bytes
        RequestedWorkers = $first.RequestedWorkers
        ChunksProcessed = $first.ChunksProcessed
        Tokens = $first.Tokens
        LexicalErrors = $first.LexicalErrors
        Trials = $sorted.Count
        MedianMilliseconds = [math]::Round($median, 3)
        MinMilliseconds = [math]::Round($sorted[0], 3)
        MaxMilliseconds = [math]::Round($sorted[-1], 3)
    }
}
$medianPath = Join-Path $resultsDir 'benchmark_medians.csv'
$medians | Export-Csv -LiteralPath $medianPath -NoTypeInformation -Encoding UTF8
foreach ($row in $medians) {
    Write-Output ("{0,-30} workers={1} chunks={2} bytes={3} tokens={4} errors={5} median={6} ms range={7}-{8} ms" -f `
        $row.File, $row.RequestedWorkers, $row.ChunksProcessed, $row.Bytes, $row.Tokens, $row.LexicalErrors, `
        $row.MedianMilliseconds, $row.MinMilliseconds, $row.MaxMilliseconds)
}
Write-Output "Raw trials: $rawPath"
Write-Output "Medians and spread: $medianPath"

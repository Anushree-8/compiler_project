param()

$ErrorActionPreference = 'Stop'
$samples = Join-Path $PSScriptRoot 'samples'
New-Item -ItemType Directory -Force -Path $samples | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Workload([string]$Name, [int]$TargetBytes, [bool]$CommentHeavy) {
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine('#include <stdio.h>')
    [void]$builder.AppendLine('')
    $index = 0
    while ($builder.Length -lt $TargetBytes) {
        if ($CommentHeavy) {
            [void]$builder.Append("/* block note for routine $index`n   comment markers // and quotes `" stay inside this comment`n   operators + - * / and braces { } remain comment text */`n")
            [void]$builder.Append("int routine_$index(int value) {`n")
            [void]$builder.Append("    const char *label_$index = `"routine $index; // string text /* still string */`";`n")
            [void]$builder.Append("    char mark_$index = 'A';`n")
            [void]$builder.Append("    return value + $index;`n}")
        } else {
            [void]$builder.Append("int routine_$index(int value) {`n")
            [void]$builder.Append("    int result = value + $index;`n")
            [void]$builder.Append("    result = (result * 3) ^ ($index & 255);`n")
            [void]$builder.Append("    if (result >= 100) result -= 7;`n")
            [void]$builder.Append("    return result;`n}")
        }
        [void]$builder.AppendLine('')
        $index++
    }
    $path = Join-Path $samples $Name
    [System.IO.File]::WriteAllText($path, $builder.ToString(), $utf8NoBom)
    $bytes = (Get-Item -LiteralPath $path).Length
    Write-Output ("Created {0}: {1:N0} bytes, {2:N0} generated routines" -f $path, $bytes, $index)
}

Write-Workload 'large_token_dense_1mb.c' 1048576 $false
Write-Workload 'large_token_dense_5mb.c' 5242880 $false
Write-Workload 'large_comment_string_1mb.c' 1048576 $true
Write-Workload 'large_comment_string_5mb.c' 5242880 $true

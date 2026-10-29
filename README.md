# Review 2 evaluation pack

This pack adds repeatable inputs for checking token consistency, safe chunking, Unicode audit behavior, and larger-file timings. It does not modify `plex.c` or replace the original `sample.c`.

## Run from the project folder

Open PowerShell in the folder containing `plex.exe` and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& .\build.bat
& .\plex.exe .\review2_evaluation\samples\baseline.c --threads 1 --tokens
& .\plex.exe .\review2_evaluation\samples\baseline.c --threads 4 --tokens
& .\plex.exe .\review2_evaluation\samples\boundary_state.c --threads 4 --tokens
& .\plex.exe .\review2_evaluation\samples\unicode_audit.c --threads 4 --tokens --audit
```

The Unicode sample intentionally includes selected mixed-script identifiers, a non-ASCII identifier, and invisible formatting characters. It is an audit demonstration, not a claim that all such identifiers are invalid or malicious.

## Compare one worker with four

```powershell
& .\review2_evaluation\compare_workers.ps1 -InputFile .\review2_evaluation\samples\boundary_state.c -Workers 4
& .\review2_evaluation\compare_workers.ps1 -InputFile .\review2_evaluation\samples\unicode_audit.c -Workers 4
```

The script compares every printed token row, including line and column, type, and lexeme. A `PASS` means the two displayed token streams match for that input. It does not compare the summary lines, because worker and chunk counts are expected to differ.

## Generate larger workloads and benchmark them

```powershell
& .\review2_evaluation\generate_large_samples.ps1
& .\review2_evaluation\benchmark.ps1 -RepeatCount 7
```

The generator creates four UTF-8 files: token-dense and comment/string-heavy sources near 1 MB and 5 MB. The benchmark warms each configuration, runs 1, 2, 4, and 8 requested workers seven times, and saves individual observations plus medians to `review2_evaluation\results\benchmark.csv` and `benchmark_medians.csv`. Each row includes the actual file size and the token/error summary from an untimed check. A low worker count may process fewer chunks than requested if there are not enough safe newline boundaries.

These timings include process startup and the lexer's planning, worker, join, and merge work. Compare runs on the same machine, with the same build and power conditions. If timings are close, repeat the benchmark and report the variation. Do not describe a single result as a general speedup.

## Recommended screenshots

Capture the terminal showing:

1. The `PASS` comparison for `boundary_state.c`.
2. The Unicode audit output for `unicode_audit.c`.
3. The benchmark medians for both 1 MB workloads.
4. The benchmark medians for both 5 MB workloads, including `Bytes`, `Tokens`, and `LexicalErrors`.

For Review 2, report the input bytes, tokens, errors, requested workers, chunks actually processed, median time, and spread across the seven trials. Keep the raw CSV with the screenshots.

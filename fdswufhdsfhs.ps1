$in = "C:\path\nocheat.checker.exe"
$out = "C:\path\nocheat.checker.enc.b64"
$keyB64 = "gu2koIlU7CZc/688IiTjF7zHemZgBINLWrnhn2LBpk4="
$ivB64 = "ZIdLvAC84tJ3L5hxoOLCGw=="

$bytes = [IO.File]::ReadAllBytes($in)

$ms = New-Object IO.MemoryStream
$ds = New-Object IO.Compression.DeflateStream($ms, [IO.Compression.CompressionMode]::Compress)
$ds.Write($bytes,0,$bytes.Length)
$ds.Close()
$compressed = $ms.ToArray()

$aes = [Security.Cryptography.Aes]::Create()
$aes.Mode = [Security.Cryptography.CipherMode]::CBC
$aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
$aes.Key = [Convert]::FromBase64String($keyB64)
$aes.IV = [Convert]::FromBase64String($ivB64)
$enc = $aes.CreateEncryptor().TransformFinalBlock($compressed,0,$compressed.Length)
[IO.File]::WriteAllText($out, [Convert]::ToBase64String($enc))
Write-Host "готово $out"
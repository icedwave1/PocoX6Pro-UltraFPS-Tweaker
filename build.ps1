# Build script for Poco X6 Pro 5G Ultra FPS Tweaker KernelSU Module
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleDir = Join-Path $scriptDir "module"
$outputZip = Join-Path $scriptDir "PocoX6Pro-UltraFPS-Tweaker.zip"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Building Poco X6 Pro 5G Ultra FPS Tweaker (KernelSU)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure UNIX LF line endings for all scripts and text files
Write-Host "[-] Normalizing line endings (CRLF -> LF)..." -ForegroundColor Yellow
$extensions = @("*.sh", "*.prop", "*.ini", "*.html", "*.css", "*.js", "updater-script", "update-binary")
Get-ChildItem -Path $moduleDir -Recurse -File | Where-Object {
    $file = $_
    $extensions | ForEach-Object { if ($file.Name -like $_) { return $true } }
} | ForEach-Object {
    $filePath = $_.FullName
    $content = [System.IO.File]::ReadAllText($filePath)
    $contentLf = $content -replace "\r\n", "`n"
    [System.IO.File]::WriteAllText($filePath, $contentLf, (New-Object System.Text.UTF8Encoding($false)))
}

# 2. Remove existing zip if any
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# 3. Create zip package with standard POSIX forward slashes '/' for Android compatibility
Write-Host "[-] Packaging into $outputZip (with POSIX path separators)..." -ForegroundColor Yellow

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($outputZip, [System.IO.FileMode]::Create)
$zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

Get-ChildItem -Path $moduleDir -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($moduleDir.Length + 1).Replace("\", "/")
    $entry = $zipArchive.CreateEntry($relativePath, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $fileBytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $entryStream.Write($fileBytes, 0, $fileBytes.Length)
    $entryStream.Close()
}

$zipArchive.Dispose()
$zipStream.Dispose()

$zipItem = Get-Item $outputZip
$fileSizeKb = [Math]::Round($zipItem.Length / 1KB, 2)
$hash = (Get-FileHash $outputZip -Algorithm SHA256).Hash

Write-Host "[+] Build successful!" -ForegroundColor Green
Write-Host "    File: $outputZip" -ForegroundColor White
Write-Host "    Size: $fileSizeKb KB" -ForegroundColor White
Write-Host "    SHA256: $hash" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

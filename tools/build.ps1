# Builds build\windows\ReverendInsanity.exe on Windows (PowerShell 5+).
# Downloads Godot 4.5.1 and its Windows export templates on first run.
# Usage:  powershell -ExecutionPolicy Bypass -File tools\build.ps1
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Ver = "4.5.1"
$Cache = Join-Path $Root "tools\.godot-cache"
$Url = "https://github.com/godotengine/godot/releases/download/$Ver-stable"
New-Item -ItemType Directory -Force -Path $Cache | Out-Null
$Godot = Join-Path $Cache "Godot_v$Ver-stable_win64_console.exe"
if ($env:GODOT) { $Godot = $env:GODOT }
if (-not (Test-Path $Godot)) {
    Write-Host "Downloading Godot $Ver..."
    $zip = Join-Path $Cache "godot.zip"
    Invoke-WebRequest "$Url/Godot_v$Ver-stable_win64.exe.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $Cache -Force
    Remove-Item $zip
}
$TplDir = Join-Path $env:APPDATA "Godot\export_templates\$Ver.stable"
if (-not (Test-Path (Join-Path $TplDir "windows_release_x86_64.exe"))) {
    Write-Host "Downloading export templates (about 1 GB, once)..."
    $tpz = Join-Path $Cache "templates.zip"
    Invoke-WebRequest "$Url/Godot_v$Ver-stable_export_templates.tpz" -OutFile $tpz
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [System.IO.Compression.ZipFile]::OpenRead($tpz)
    New-Item -ItemType Directory -Force -Path $TplDir | Out-Null
    foreach ($e in $z.Entries) {
        if ($e.FullName -in @("templates/windows_release_x86_64.exe", "templates/windows_debug_x86_64.exe", "templates/version.txt")) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $TplDir $e.Name), $true)
        }
    }
    $z.Dispose()
    Remove-Item $tpz
}
$Game = Join-Path $Root "game"
$Out = Join-Path $Root "build\windows"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Write-Host "Importing assets..."
& $Godot --headless --path $Game --import | Out-Null
Write-Host "Exporting..."
& $Godot --headless --path $Game --export-release "Windows Desktop" (Join-Path $Out "ReverendInsanity.exe")
if (-not (Test-Path (Join-Path $Out "ReverendInsanity.exe"))) { throw "Export failed" }
Write-Host "Done: build\windows\ReverendInsanity.exe"

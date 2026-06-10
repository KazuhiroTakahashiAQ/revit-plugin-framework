# uninstall.ps1
# このスクリプトはプラグインフォルダ内で実行してください。
# RevitのAddinsフォルダからDLLと.addinファイルを削除します。

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ----- プラグイン名とRevitバージョンを自動検出 -----
$csproj = Get-ChildItem -Path $PSScriptRoot -Filter "*.csproj" | Select-Object -First 1
if (-not $csproj) {
    Write-Host "[ERROR] .csproj が見つかりません。このスクリプトはプラグインフォルダ内に置いてください。" -ForegroundColor Red
    exit 1
}
$PluginName = $csproj.BaseName

$csprojContent = Get-Content $csproj.FullName -Raw
$RevitVersion = "2024"
if ($csprojContent -match 'Revit (\d{4})') {
    $RevitVersion = $Matches[1]
}

Write-Host ""
Write-Host "=== アンインストール: $PluginName ===" -ForegroundColor Cyan
Write-Host "対象Revitバージョン: $RevitVersion"
Write-Host ""

$addinsFolder = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$RevitVersion"
if (-not (Test-Path $addinsFolder)) {
    Write-Host "[INFO] Addins フォルダが見つかりません: $addinsFolder" -ForegroundColor Yellow
    Write-Host "すでにアンインストール済みか、Revit $RevitVersion がインストールされていません。" -ForegroundColor Yellow
    exit 0
}

$removed = $false

$dllPath = Join-Path $addinsFolder "$PluginName.dll"
if (Test-Path $dllPath) {
    Remove-Item $dllPath -Force
    Write-Host "[OK] 削除しました: $dllPath" -ForegroundColor Green
    $removed = $true
} else {
    Write-Host "[INFO] DLL が見つかりません（スキップ）: $dllPath" -ForegroundColor Gray
}

$addinPath = Join-Path $addinsFolder "$PluginName.addin"
if (Test-Path $addinPath) {
    Remove-Item $addinPath -Force
    Write-Host "[OK] 削除しました: $addinPath" -ForegroundColor Green
    $removed = $true
} else {
    Write-Host "[INFO] .addin が見つかりません（スキップ）: $addinPath" -ForegroundColor Gray
}

Write-Host ""
if ($removed) {
    Write-Host "アンインストール完了！次回Revit起動時からプラグインは読み込まれません。" -ForegroundColor Cyan
} else {
    Write-Host "削除対象ファイルが見つかりませんでした。すでにアンインストール済みです。" -ForegroundColor Yellow
}
Write-Host ""

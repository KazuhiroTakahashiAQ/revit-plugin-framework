# build_and_deploy.ps1 (hello-world サンプル用)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$csproj = Get-ChildItem -Path $PSScriptRoot -Filter "*.csproj" | Select-Object -First 1
if (-not $csproj) { Write-Host "[ERROR] .csproj が見つかりません。" -ForegroundColor Red; exit 1 }
$PluginName = $csproj.BaseName

$csprojContent = Get-Content $csproj.FullName -Raw
$RevitVersion = "2024"
if ($csprojContent -match 'Revit (\d{4})') { $RevitVersion = $Matches[1] }

Write-Host ""
Write-Host "=== ビルド & デプロイ: $PluginName ===" -ForegroundColor Cyan
Write-Host "対象Revitバージョン: $RevitVersion"
Write-Host ""

$dotnetExe  = Get-Command "dotnet" -ErrorAction SilentlyContinue
$msbuildExe = $null

if (-not $dotnetExe) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $msbuildExe = & $vswhere -latest -requires Microsoft.Component.MSBuild `
            -find "MSBuild\**\Bin\MSBuild.exe" 2>$null | Select-Object -First 1
    }
    if (-not $msbuildExe) {
        Write-Host "[ERROR] ビルドツールが見つかりません。.NET SDK または Visual Studio をインストールしてください。" -ForegroundColor Red
        exit 1
    }
}

Push-Location $PSScriptRoot
try {
    if ($dotnetExe) {
        & dotnet build $csproj.FullName -c Release --nologo -v minimal
    } else {
        & $msbuildExe $csproj.FullName /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    }
    if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] ビルドに失敗しました。" -ForegroundColor Red; exit 1 }
} finally {
    Pop-Location
}

$dll = Get-ChildItem -Path (Join-Path $PSScriptRoot "bin\Release") -Recurse -Filter "$PluginName.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dll) { Write-Host "[ERROR] $PluginName.dll が見つかりません。" -ForegroundColor Red; exit 1 }
Write-Host "[OK] ビルド成功: $($dll.FullName)" -ForegroundColor Green

$addinsFolder = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$RevitVersion"
if (-not (Test-Path $addinsFolder)) {
    Write-Host "[ERROR] Revit $RevitVersion の Addins フォルダが見つかりません: $addinsFolder" -ForegroundColor Red; exit 1
}

Copy-Item $dll.FullName $addinsFolder -Force
Write-Host "[OK] DLL をコピーしました → $addinsFolder" -ForegroundColor Green

$addin = Get-ChildItem -Path $PSScriptRoot -Filter "*.addin" | Select-Object -First 1
if ($addin) {
    Copy-Item $addin.FullName $addinsFolder -Force
    Write-Host "[OK] .addin をコピーしました → $addinsFolder" -ForegroundColor Green
}

Write-Host ""
Write-Host "デプロイ完了！Revitを起動（または再起動）してください。" -ForegroundColor Cyan
Write-Host ""

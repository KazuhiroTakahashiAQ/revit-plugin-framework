# build_and_deploy.ps1
# このスクリプトはプラグインフォルダ内で実行してください。
# ビルドしてRevitのAddinsフォルダにコピーします。

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
Write-Host "=== ビルド & デプロイ: $PluginName ===" -ForegroundColor Cyan
Write-Host "対象Revitバージョン: $RevitVersion"
Write-Host ""

# ----- ビルドツールを探す -----
$dotnetExe  = Get-Command "dotnet" -ErrorAction SilentlyContinue
$msbuildExe = $null

if (-not $dotnetExe) {
    # vswhere.exe で Visual Studio の MSBuild を探す
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $msbuildExe = & $vswhere -latest -requires Microsoft.Component.MSBuild `
            -find "MSBuild\**\Bin\MSBuild.exe" 2>$null | Select-Object -First 1
    }
    if (-not $msbuildExe) {
        Write-Host "[ERROR] ビルドツールが見つかりません。" -ForegroundColor Red
        Write-Host ""
        Write-Host "以下のいずれかをインストールしてください:" -ForegroundColor Yellow
        Write-Host "  .NET SDK (無料):  https://dotnet.microsoft.com/download"
        Write-Host "  Visual Studio Community (無料): https://visualstudio.microsoft.com/ja/vs/community/"
        exit 1
    }
}

# ----- ビルド -----
Push-Location $PSScriptRoot
try {
    if ($dotnetExe) {
        Write-Host "[INFO] dotnet build を使用します" -ForegroundColor Gray
        & dotnet build $csproj.FullName -c Release --nologo -v minimal
    } else {
        Write-Host "[INFO] MSBuild を使用します: $msbuildExe" -ForegroundColor Gray
        & $msbuildExe $csproj.FullName /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ビルドに失敗しました。" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

# ----- DLL を探す -----
$dll = Get-ChildItem -Path (Join-Path $PSScriptRoot "bin\Release") -Recurse -Filter "$PluginName.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dll) {
    Write-Host "[ERROR] $PluginName.dll が見つかりません。ビルドログを確認してください。" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] ビルド成功: $($dll.FullName)" -ForegroundColor Green

# ----- Addins フォルダへコピー -----
$addinsFolder = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$RevitVersion"
if (-not (Test-Path $addinsFolder)) {
    Write-Host "[ERROR] Revit $RevitVersion の Addins フォルダが見つかりません: $addinsFolder" -ForegroundColor Red
    Write-Host "Revit $RevitVersion がインストールされているか確認してください。" -ForegroundColor Yellow
    exit 1
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

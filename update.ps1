# update.ps1
# テンプレートの更新内容を plugins/ 配下の全プラグインに反映します。
# PluginLogic.cs / PluginUI.cs はユーザー実装のため更新しません。
# App.cs はリボン設定（定数）を既存値から引き継いで上書きします。

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$FrameworkRoot = $PSScriptRoot
$TemplateDir   = Join-Path $FrameworkRoot "template"
$PluginsDir    = Join-Path $FrameworkRoot "plugins"

if (-not (Test-Path $PluginsDir)) {
    Write-Host "[INFO] plugins/ フォルダが存在しません。更新対象なし。" -ForegroundColor Yellow
    exit 0
}

$plugins = Get-ChildItem -Path $PluginsDir -Directory
if ($plugins.Count -eq 0) {
    Write-Host "[INFO] plugins/ 配下にプラグインが見つかりません。" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  テンプレート更新ウィザード" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "更新対象プラグイン:" -ForegroundColor DarkCyan
foreach ($p in $plugins) { Write-Host "  - $($p.Name)" }
Write-Host ""

$confirm = (Read-Host "上記プラグインを更新しますか？ [y/N]").Trim().ToLower()
if ($confirm -ne 'y') {
    Write-Host "キャンセルしました。" -ForegroundColor Yellow
    exit 0
}

# 単純上書きするファイル（内容は PluginName プレースホルダーなし）
$simpleFiles = @(
    "build_and_deploy.bat",
    "uninstall.bat"
)

# PluginName プレースホルダーを含むファイル（namespace 置換が必要）
$codeFiles = @(
    "Command.cs"
)

# ps1 は UTF-8 BOM で保存する必要があるため別扱い
$ps1Files = @(
    "build_and_deploy.ps1",
    "uninstall.ps1"
)

$utf8bom = New-Object System.Text.UTF8Encoding($true)
$utf8    = [System.Text.Encoding]::UTF8

foreach ($plugin in $plugins) {
    $pluginName = $plugin.Name
    $outDir     = $plugin.FullName

    # csproj からRevitバージョンを取得
    $csproj = Get-ChildItem -Path $outDir -Filter "*.csproj" | Select-Object -First 1
    $revitVersion = "2024"
    if ($csproj) {
        $csprojContent = [System.IO.File]::ReadAllText($csproj.FullName, $utf8)
        if ($csprojContent -match 'Revit (\d{4})') { $revitVersion = $Matches[1] }
    }

    # App.cs の既存定数値を読み取る
    $appPath = Join-Path $outDir "App.cs"
    $tabName     = $pluginName
    $panelName   = $pluginName
    $buttonLabel = $pluginName
    $toolTip     = "${pluginName}を実行します。"
    if (Test-Path $appPath) {
        $existing = [System.IO.File]::ReadAllText($appPath, $utf8)
        if ($existing -match 'TabName\s*=\s*"([^"]*)"')     { $tabName     = $Matches[1] }
        if ($existing -match 'PanelName\s*=\s*"([^"]*)"')   { $panelName   = $Matches[1] }
        if ($existing -match 'ButtonLabel\s*=\s*"([^"]*)"') { $buttonLabel = $Matches[1] }
        if ($existing -match 'ToolTip\s*=\s*"([^"]*)"')     { $toolTip     = $Matches[1] }
    }

    Write-Host ""
    Write-Host "--- $pluginName (Revit $revitVersion) ---" -ForegroundColor Green

    # 単純上書き（bat）
    foreach ($file in $simpleFiles) {
        $src = Join-Path $TemplateDir $file
        if (Test-Path $src) {
            Copy-Item $src $outDir -Force
            Write-Host "  [OK] $file"
        }
    }

    # ps1: UTF-8 BOM で保存
    foreach ($file in $ps1Files) {
        $src = Join-Path $TemplateDir $file
        if (Test-Path $src) {
            $content = [System.IO.File]::ReadAllText($src, $utf8)
            [System.IO.File]::WriteAllText((Join-Path $outDir $file), $content, $utf8bom)
            Write-Host "  [OK] $file"
        }
    }

    # .cs: namespace 置換して上書き
    foreach ($file in $codeFiles) {
        $src = Join-Path $TemplateDir $file
        if (Test-Path $src) {
            $content = [System.IO.File]::ReadAllText($src, $utf8)
            $content = $content -replace 'namespace PluginName;', "namespace $pluginName;"
            [System.IO.File]::WriteAllText((Join-Path $outDir $file), $content, $utf8bom)
            Write-Host "  [OK] $file"
        }
    }

    # App.cs: テンプレートに既存の定数値を当てはめて上書き
    $appSrc = Join-Path $TemplateDir "App.cs"
    if (Test-Path $appSrc) {
        $appContent = [System.IO.File]::ReadAllText($appSrc, $utf8)
        $appContent = $appContent -replace 'namespace PluginName;',                           "namespace $pluginName;"
        $appContent = $appContent -replace '(?<=private const string TabName\s*=\s*")[^"]*',     $tabName
        $appContent = $appContent -replace '(?<=private const string PanelName\s*=\s*")[^"]*',   $panelName
        $appContent = $appContent -replace '(?<=private const string ButtonLabel\s*=\s*")[^"]*', $buttonLabel
        $appContent = $appContent -replace '(?<=private const string ToolTip\s*=\s*")[^"]*',     $toolTip
        [System.IO.File]::WriteAllText($appPath, $appContent, $utf8bom)
        Write-Host "  [OK] App.cs (定数値を引き継ぎ)"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  更新完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

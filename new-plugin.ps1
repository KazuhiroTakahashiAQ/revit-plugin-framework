# new-plugin.ps1
# revit-plugin-framework のルートフォルダで実行してください。
# 対話式で設定を入力すると plugins/<PluginName>/ にプラグインを生成します。

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$FrameworkRoot = $PSScriptRoot
$TemplateDir   = Join-Path $FrameworkRoot "template"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Revit Plugin 新規作成ウィザード" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ----- プラグイン名 -----
do {
    $PluginName = (Read-Host "プラグイン名（英数字のみ、例: WallColorizer）").Trim()
    if ($PluginName -notmatch '^[A-Za-z][A-Za-z0-9]+$') {
        Write-Host "  英字始まり・英数字のみで入力してください（スペース・日本語不可）" -ForegroundColor Red
        $PluginName = $null
    }
} while (-not $PluginName)

# ----- Revitバージョン -----
$rvInput = (Read-Host "Revitバージョン（例: 2024 / 2025）[Enter で 2024]").Trim()
$RevitVersion = if ($rvInput -match '^\d{4}$') { $rvInput } else { "2024" }

# ----- リボン設定（すべてデフォルト値あり） -----
Write-Host ""
Write-Host "--- リボン設定（Enter で括弧内のデフォルト値を使用） ---" -ForegroundColor DarkCyan

$tabInput = (Read-Host "タブ名 [MyPlugins]").Trim()
$TabName = if ($tabInput) { $tabInput } else { "MyPlugins" }

$panelInput = (Read-Host "パネル名 [$PluginName]").Trim()
$PanelName = if ($panelInput) { $panelInput } else { $PluginName }

$btnInput = (Read-Host "ボタンラベル（\n で改行、例: 壁\n集計）[$PluginName]").Trim()
$ButtonLabel = if ($btnInput) { $btnInput } else { $PluginName }

$tipInput = (Read-Host "ツールチップ [${PluginName}を実行します。]").Trim()
$ToolTip = if ($tipInput) { $tipInput } else { "${PluginName}を実行します。" }

# ----- 確認 -----
Write-Host ""
Write-Host "=== 設定確認 ===" -ForegroundColor Green
Write-Host "  プラグイン名    : $PluginName"
Write-Host "  Revitバージョン  : $RevitVersion"
Write-Host "  タブ名           : $TabName"
Write-Host "  パネル名         : $PanelName"
Write-Host "  ボタンラベル     : $ButtonLabel"
Write-Host "  ツールチップ     : $ToolTip"
Write-Host ""

$confirm = (Read-Host "この内容で作成しますか？ [y/N]").Trim().ToLower()
if ($confirm -ne 'y') {
    Write-Host "キャンセルしました。" -ForegroundColor Yellow
    exit 0
}

# ----- 出力先を作成 -----
$PluginsDir = Join-Path $FrameworkRoot "plugins"
$OutDir     = Join-Path $PluginsDir $PluginName

if (Test-Path $OutDir) {
    $overwrite = (Read-Host "$OutDir は既に存在します。上書きしますか？ [y/N]").Trim().ToLower()
    if ($overwrite -ne 'y') { Write-Host "キャンセルしました。" -ForegroundColor Yellow; exit 0 }
    Remove-Item $OutDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutDir | Out-Null

# ----- テンプレートファイルをコピー -----
$templateFiles = @("App.cs", "Command.cs", "PluginLogic.cs", "PluginUI.cs",
                   "PluginName.csproj", "PluginName.addin",
                   "build_and_deploy.ps1", "build_and_deploy.bat",
                   "uninstall.ps1", "uninstall.bat")

foreach ($file in $templateFiles) {
    $src = Join-Path $TemplateDir $file
    if (Test-Path $src) {
        Copy-Item $src $OutDir
    }
}

# ----- ファイルリネーム -----
Rename-Item (Join-Path $OutDir "PluginName.csproj") "$PluginName.csproj"
Rename-Item (Join-Path $OutDir "PluginName.addin")  "$PluginName.addin"

# ----- .cs ファイルの namespace を置換 -----
Get-ChildItem -Path $OutDir -Filter "*.cs" | ForEach-Object {
    $raw = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $raw = $raw -replace 'namespace PluginName;', "namespace $PluginName;"
    [System.IO.File]::WriteAllText($_.FullName, $raw, [System.Text.Encoding]::UTF8)
}

# ----- App.cs の定数を更新 -----
$appPath = Join-Path $OutDir "App.cs"
$appRaw  = [System.IO.File]::ReadAllText($appPath, [System.Text.Encoding]::UTF8)
$appRaw  = $appRaw -replace '(?<=private const string TabName\s*=\s*")[^"]*', $TabName
$appRaw  = $appRaw -replace '(?<=private const string PanelName\s*=\s*")[^"]*', $PanelName
$appRaw  = $appRaw -replace '(?<=private const string ButtonLabel\s*=\s*")[^"]*', $ButtonLabel
$appRaw  = $appRaw -replace '(?<=private const string ToolTip\s*=\s*")[^"]*', $ToolTip
[System.IO.File]::WriteAllText($appPath, $appRaw, [System.Text.Encoding]::UTF8)

# ----- .csproj の HintPath を更新 -----
$csprojPath = Join-Path $OutDir "$PluginName.csproj"
$csprojRaw  = [System.IO.File]::ReadAllText($csprojPath, [System.Text.Encoding]::UTF8)
$csprojRaw  = $csprojRaw -replace 'Revit \d{4}\\', "Revit $RevitVersion\"
[System.IO.File]::WriteAllText($csprojPath, $csprojRaw, [System.Text.Encoding]::UTF8)

# ----- .addin を更新 -----
$ClientId  = [System.Guid]::NewGuid().ToString()
$addinPath = Join-Path $OutDir "$PluginName.addin"
$addinRaw  = [System.IO.File]::ReadAllText($addinPath, [System.Text.Encoding]::UTF8)
$addinRaw  = $addinRaw -replace 'PluginName(?=\.dll)',   $PluginName
$addinRaw  = $addinRaw -replace '<Name>PluginName</Name>', "<Name>$PluginName</Name>"
$addinRaw  = $addinRaw -replace 'PluginName\.App',       "$PluginName.App"
$addinRaw  = $addinRaw -replace 'REPLACE-WITH-NEW-GUID', $ClientId
[System.IO.File]::WriteAllText($addinPath, $addinRaw, [System.Text.Encoding]::UTF8)

# ----- 完了メッセージ -----
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  プラグインを作成しました！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  フォルダ: $OutDir"
Write-Host ""
Write-Host "【次のステップ】" -ForegroundColor Yellow
Write-Host "  1. AIチャット（Gemini/Claude）に FOR_AI.md の内容を渡し、"
Write-Host "     プラグインの仕様をヒアリングしてコードを生成してもらう"
Write-Host ""
Write-Host "  2. 生成された PluginLogic.cs と PluginUI.cs を"
Write-Host "     $OutDir"
Write-Host "     に上書き保存する"
Write-Host ""
Write-Host "  3. $OutDir\build_and_deploy.bat"
Write-Host "     をダブルクリックしてビルド & デプロイする"
Write-Host ""
Write-Host "  4. Revit $RevitVersion を起動する"
Write-Host ""

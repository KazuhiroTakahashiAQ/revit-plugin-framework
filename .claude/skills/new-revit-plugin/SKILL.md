---
name: new-revit-plugin
description: Revit 2024+ プラグインを対話式ヒアリングで生成する。プラグインの目的・UIスタイルを質問し、PluginLogic.cs と PluginUI.cs を plugins/ フォルダに書き込む。new-plugin.bat 実行後に使う。
---

# Revit Plugin Generator スキル

このスキルはFOR_AI.mdに記載された手順に従い、Claude Code CLIで対話的にRevitプラグインを生成します。

## 前提

`new-plugin.bat` を実行済みで `plugins/<PluginName>/` ディレクトリが存在すること。  
まだの場合はユーザーに `new-plugin.bat` の実行を促してください。

## フェーズ 1：ヒアリング

AskUserQuestion を使って以下を確認します（まとめて一度に聞く）。

**必須質問：**
- プラグイン名（`plugins/` 内のフォルダ名）
- このプラグインは何をするか（平易な言葉で）
- モデルを変更するか（読み取り専用 / 書き込みあり）
- 対象要素（全要素 / 選択要素 / 特定カテゴリ）
- UI スタイル（TaskDialog / WPFウィンドウ）
- WPFの場合：必要なコントロール・入力欄の説明

## フェーズ 2：生成

FOR_AI.md の「ステップ2：生成ルール」に厳密に従ってコードを生成します。

**チェックリスト：**
- [ ] 名前空間はプラグイン名と一致している
- [ ] `PluginLogic(UIDocument uiDoc)` シグネチャが正しい
- [ ] `PluginUI(PluginLogic logic)` シグネチャが正しい
- [ ] `Show()` は `Result` を返している
- [ ] async/await を使っていない
- [ ] WPFの場合、`MainWindow` は `PluginUI.cs` 内に定義されている（XAMLなし）
- [ ] 書き込みがある場合、`Transaction` を使っている
- [ ] 1ファイルあたり300行以内

## フェーズ 3：ファイルへの書き込み

生成したコードを以下のパスに書き込みます：
- `plugins/<PluginName>/PluginLogic.cs`
- `plugins/<PluginName>/PluginUI.cs`

## フェーズ 4：完了報告

書き込み後、以下を出力します：

1. プラグインの概要（1〜2文）
2. 次のステップ：
   - `plugins/<PluginName>/build_and_deploy.bat` をダブルクリックしてデプロイ
   - Revitを起動して動作確認

## Revit APIクイックリファレンス

```csharp
// カテゴリ別取得
new FilteredElementCollector(Doc).OfClass(typeof(Wall)).Cast<Wall>()
new FilteredElementCollector(Doc).OfCategory(BuiltInCategory.OST_Rooms)
    .WhereElementIsNotElementType().Cast<SpatialElement>()

// 選択要素取得
UiDoc.Selection.GetElementIds().Select(id => Doc.GetElement(id))

// 要素選択ピッカー（ESCで OperationCanceledException）
var ref_ = UiDoc.Selection.PickObject(ObjectType.Element, "要素を選択");
var elem = Doc.GetElement(ref_);

// 単位変換（Revit内部単位はフィート）
UnitUtils.ConvertFromInternalUnits(val, UnitTypeId.Meters)
UnitUtils.ConvertToInternalUnits(val, UnitTypeId.Meters)

// 書き込みトランザクション
using var tx = new Transaction(Doc, "操作名");
tx.Start();
/* 変更処理 */
tx.Commit();
```

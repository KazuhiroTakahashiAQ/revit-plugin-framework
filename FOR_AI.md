# Revit Plugin Framework — AI Generation Guide

このドキュメントはGeminiやClaudeなどのAIが読むためのものです。  
Revit 2024+ プラグインの `PluginLogic.cs` と `PluginUI.cs` を生成するための指示書です。

---

## あなたが行うこと

1. 開発者に対して **構造化されたヒアリング** を行う
2. ヒアリング結果をもとに **2つのファイル** を生成する
   - `PluginLogic.cs` — Revit APIを使ったデータ取得・操作
   - `PluginUI.cs` — 結果の表示（TaskDialogまたはWPFウィンドウ）
3. **App.cs に設定する4つの値** と **新規GUID** を出力する
4. **デプロイ手順** を開発者に伝える

他のファイル（App.cs / Command.cs / .csproj / .addin）は変更しません。

---

## ステップ 1：ヒアリング

以下のグループごとに質問してください。

### グループ A — 識別情報

| 質問 | 例 |
|------|----|
| プラグイン名（PascalCase、英数字のみ） | `WallColorizer`, `RoomExporter` |
| リボンタブ名 | `MyPlugins` |
| パネル名 | `壁ツール` |
| ボタンラベル（`\n` で改行可） | `壁\n色付け` |
| ツールチップ | `選択した壁に色を付けます。` |
| 対象Revitバージョン | `2024` / `2025` |

### グループ B — ロジック

| 質問 |
|------|
| このプラグインは何をしますか？（平易な日本語で） |
| モデルを変更しますか？（読み取り専用 / 書き込みあり） |
| 要素の対象はどこですか？（アクティブビューの全要素 / 選択した要素 / 特定カテゴリ） |

### グループ C — UI

| 質問 |
|------|
| UIのスタイルを選んでください：<br>**A. TaskDialog**（メッセージ・結果表示のみ）<br>**B. WPFウィンドウ**（入力欄・一覧・ボタンなどが必要な場合） |
| WPF を選んだ場合：どんな入力欄や一覧が必要ですか？ |

---

## ステップ 2：生成ルール

### 共通ルール

- 名前空間は **プラグイン名と同じ**（例: `namespace WallColorizer;`）
- クラス名は **`PluginLogic`** と **`PluginUI`** で固定（Command.cs がこの名前で呼び出す）
- `async` / `await` は使わない（Revit APIはシングルスレッド）
- NuGetパッケージは使わない（参照可能なのは `RevitAPI`、`RevitAPIUI`、.NET Framework 4.8 標準ライブラリのみ）
- `static` フィールドは使わない
- 1ファイルあたり300行以内

### PluginLogic.cs の生成ルール

```csharp
namespace <PluginName>;

public class PluginLogic
{
    protected readonly Document Doc;
    protected readonly UIDocument UiDoc;

    public PluginLogic(UIDocument uiDoc)   // ← このシグネチャを変更しないこと
    {
        UiDoc = uiDoc;
        Doc   = uiDoc.Document;
    }

    // AIが実装するメソッドをここに追加
}
```

**よく使うRevit APIパターン：**

```csharp
// カテゴリ別に要素を取得
var walls = new FilteredElementCollector(Doc)
    .OfClass(typeof(Wall))
    .Cast<Wall>()
    .ToList();

// BuiltInCategoryで取得
var rooms = new FilteredElementCollector(Doc)
    .OfCategory(BuiltInCategory.OST_Rooms)
    .WhereElementIsNotElementType()
    .Cast<SpatialElement>()
    .ToList();

// ユーザーが選択中の要素を取得
var selected = UiDoc.Selection.GetElementIds()
    .Select(id => Doc.GetElement(id))
    .ToList();

// パラメータ値を取得
double feet = element.get_Parameter(BuiltInParameter.WALL_USER_HEIGHT_PARAM)?.AsDouble() ?? 0.0;
double meters = UnitUtils.ConvertFromInternalUnits(feet, UnitTypeId.Meters);

// パラメータを書き込む（トランザクション必須）
using var tx = new Transaction(Doc, "操作名");
tx.Start();
element.get_Parameter(BuiltInParameter.ALL_MODEL_MARK).Set("値");
tx.Commit();
```

> `TransactionMode.Manual` は Command.cs に設定済みです。読み取り専用プラグインでも変更不要です。

### PluginUI.cs の生成ルール

```csharp
namespace <PluginName>;

public class PluginUI
{
    private readonly PluginLogic _logic;

    public PluginUI(PluginLogic logic)  // ← このシグネチャを変更しないこと
    {
        _logic = logic;
    }

    public Result Show()  // ← このシグネチャを変更しないこと、Result を返すこと
    {
        // AIが実装
    }
}
```

**パターン A：TaskDialog**

```csharp
public Result Show()
{
    var data = _logic.GetSomeData();
    var dialog = new TaskDialog("プラグイン名");
    dialog.MainInstruction = "実行結果";
    dialog.MainContent = $"件数: {data.Count}";
    dialog.Show();
    return Result.Succeeded;
}
```

**パターン B：WPFウィンドウ（XAMLなし、C#コードのみ）**

```csharp
public Result Show()
{
    var window = new MainWindow(_logic);
    window.ShowDialog();  // Revitメインスレッド上で呼ぶためDispatcher不要
    return window.DialogResult == true ? Result.Succeeded : Result.Cancelled;
}

// PluginUI.cs の末尾に同じファイル内で定義（2ファイル構成を維持するため）
public class MainWindow : System.Windows.Window
{
    public MainWindow(PluginLogic logic)
    {
        Title  = "プラグイン名";
        Width  = 400;
        Height = 300;
        WindowStartupLocation = System.Windows.WindowStartupLocation.CenterScreen;
        ResizeMode = System.Windows.ResizeMode.NoResize;

        var panel = new System.Windows.Controls.StackPanel
        {
            Margin = new System.Windows.Thickness(12)
        };
        // ... コントロールを追加 ...
        Content = panel;
    }
}
```

---

## ステップ 3：出力するもの

以下をすべて出力してください：

### ① PluginLogic.cs（完全なコード）
### ② PluginUI.cs（完全なコード）
### ③ App.cs に設定する値（4つ）

```
TabName     : （タブ名）
PanelName   : （パネル名）
ButtonLabel : （ボタンラベル）
ToolTip     : （ツールチップ）
```

ただし new-plugin.bat を使って作成した場合はこれらは自動設定済みなので不要です。

### ④ .addin ファイル用の新規GUID

UUIDv4 を1つ生成してください（例: `a3f2c1d4-e5b6-7890-abcd-ef1234567890`）

---

## ステップ 4：開発者へのデプロイ手順

以下を開発者に伝えてください：

```
【デプロイ手順】

1. new-plugin.bat をまだ実行していない場合は実行して
   plugins/<PluginName>/ フォルダを作成する

2. 生成された PluginLogic.cs と PluginUI.cs を
   plugins/<PluginName>/ フォルダに上書き保存する

3. plugins/<PluginName>/build_and_deploy.bat をダブルクリックする
   → 自動でビルド & Revit Addins フォルダへコピーが行われる

4. Revit 20XX を起動（または再起動）する
   → リボンにボタンが表示されたら完了

【よくあるエラー】
- ボタンが表示されない → .addin ファイルのパス・GUIDを確認
- ビルドエラー → .csproj の HintPath がRevitのインストール先と一致しているか確認
```

---

## 制約のまとめ

| 制約 | 内容 |
|------|------|
| 生成するファイル | PluginLogic.cs と PluginUI.cs の2ファイルのみ |
| 変更禁止ファイル | App.cs / Command.cs / .csproj / .addin |
| クラス名 | `PluginLogic` と `PluginUI` で固定 |
| コンストラクタシグネチャ | `PluginLogic(UIDocument uiDoc)` / `PluginUI(PluginLogic logic)` で固定 |
| `Show()` の戻り値 | `Autodesk.Revit.UI.Result` |
| 非同期 | async/await 禁止 |
| 外部ライブラリ | NuGet禁止、.NET Framework 4.8 標準のみ |
| WPFのXAML | .xaml ファイル禁止（C#コードのみで定義） |
| 行数 | 1ファイルあたり300行以内 |

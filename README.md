# Revit Plugin Framework

Revit 2024 以降のプラグインを素早く作るためのフレームワーク。  
GeminiやClaudeなどのAIチャットにこのリポジトリのURLを渡すだけで、プラグインのコードを生成できる。

---

## 動作要件

| ソフトウェア | バージョン | 入手先 |
|---|---|---|
| Autodesk Revit | 2024 以降 | ライセンス購入 |
| .NET SDK **または** Visual Studio | .NET SDK 6+ / VS 2022 | [.NET SDK（無料）](https://dotnet.microsoft.com/download) または [Visual Studio Community（無料）](https://visualstudio.microsoft.com/ja/vs/community/) |

> **.NET Framework 4.8 は Windows 11 に標準搭載**されているため追加インストール不要です。  
> ビルドのためだけなら Visual Studio の代わりに **Build Tools for Visual Studio**（軽量版）でも構いません。

---

## 仕組み

```
① AIチャットに FOR_AI.md のURLを渡す → ヒアリング → 回答例を確認 → コード生成
        ↓
② new-plugin.bat をダブルクリック → プラグイン名・設定を入力
        ↓
③ AIが生成した 2ファイルを plugins/<名前>/ にコピペ
        ↓
④ build_and_deploy.bat をダブルクリック → ビルド & Revit へコピー
        ↓
⑤ Revit を起動 → リボンにボタンが表示
```

---

## 初回セットアップ

### 1. AIチャットでコードを生成する

GeminiまたはClaudeのWebチャットを開き、次のメッセージを送ります：

```
このリポジトリのFOR_AI.mdを読んで、指示に従ってRevitプラグインを作ってください。
https://github.com/KazuhiroTakahashiAQ/revit-plugin-framework
```

AIがヒアリングを進め、まず **回答例（プレビュー）** を出力します。  
内容を確認して「この通りに作成して」と返信すると、`PluginLogic.cs` と `PluginUI.cs` が生成されます。  
生成されたコードは次のステップのためにコピーしておきます。

### 2. new-plugin.bat を実行する

リポジトリのルートにある `new-plugin.bat` をダブルクリックします。  
対話形式でプラグイン名・設定を入力すると `plugins/<プラグイン名>/` が自動生成されます。

```
プラグイン名（英数字のみ、例: WallColorizer）: WallColorizer
Revitバージョン（例: 2024 / 2025）[Enter で 2024]:
タブ名 [MyPlugins]:
パネル名 [WallColorizer]:
ボタンラベル [WallColorizer]:
ツールチップ [WallColorizerを実行します。]:
```

> Revitバージョンは 2024 / 2025 など対象環境に合わせて入力してください。

### 3. 生成ファイルを配置する

AIが生成した2ファイルを `plugins/<プラグイン名>/` に上書き保存します：

```
plugins/
└── WallColorizer/
    ├── PluginLogic.cs  ← AIが生成したコードをコピペ
    └── PluginUI.cs     ← AIが生成したコードをコピペ
```

### 4. build_and_deploy.bat を実行する

`plugins/<プラグイン名>/build_and_deploy.bat` をダブルクリックします。  
ビルドが成功すると `%AppData%\Autodesk\Revit\Addins\<バージョン>\` へ自動コピーされます。

### 5. Revitを起動する

リボンにボタンが表示されたら完了です。

---

## プラグインを改良する

一度作成したプラグインに機能を追加・変更する手順です。

### AIチャットで修正を依頼する場合

1. 現在の `PluginLogic.cs` と `PluginUI.cs` の内容をAIチャットに貼り付ける
2. 「〇〇の機能を追加してほしい」と伝える
3. AIが修正済みファイルを出力する
4. `plugins/<プラグイン名>/` に上書き保存する
5. `build_and_deploy.bat` を再実行する
6. Revitを再起動する

### 自分で直接編集する場合

1. `plugins/<プラグイン名>/PluginLogic.cs` または `PluginUI.cs` を直接編集する
2. `build_and_deploy.bat` を実行する
3. Revitを再起動する

> **ヒント**: App.cs の定数（タブ名・ボタンラベルなど）を変更した場合も  
> `build_and_deploy.bat` を再実行するだけで反映されます。

---

## リポジトリ構成

```
revit-plugin-framework/
├── README.md                  # このファイル
├── FOR_AI.md                  # AI向け指示書（AIはこれを読んでコードを生成する）
├── new-plugin.bat             # 新規プラグイン作成ウィザード（ダブルクリックで起動）
├── new-plugin.ps1             # 上記の実体（PowerShellスクリプト）
├── template/                  # プラグインのひな形（new-plugin.bat がコピーする）
│   ├── PluginName.csproj
│   ├── App.cs                 # リボンボタン登録（編集不要）
│   ├── Command.cs             # エントリポイント（編集不要）
│   ├── PluginLogic.cs         # ← AIが生成
│   ├── PluginUI.cs            # ← AIが生成
│   ├── PluginName.addin
│   ├── build_and_deploy.bat   # ビルド & デプロイ（ダブルクリックで起動）
│   └── build_and_deploy.ps1   # 上記の実体
├── plugins/                   # new-plugin.bat で生成したプラグインが入る
│   └── <PluginName>/          # 各プラグインのフォルダ
└── examples/
    └── hello-world/           # 動作サンプル（壁の数を表示）
```

---

## アーキテクチャ

| クラス | 役割 |
|--------|------|
| `App.cs` | リボンボタンを登録する（IExternalApplication） |
| `Command.cs` | ボタン押下時に実行される（IExternalCommand） |
| `PluginLogic` | Revit APIを使ったデータ取得・操作 ← **AIが生成** |
| `PluginUI` | 結果の表示（TaskDialogまたはWPF） ← **AIが生成** |

```
Revit 起動時
  └─ App.cs → リボンにボタンを登録

ボタン押下時
  └─ Command.cs
       ├─ new PluginLogic(uiDoc)
       └─ new PluginUI(logic) → ui.Show()
```

---

## トラブルシューティング

**リボンにボタンが表示されない**  
→ `%AppData%\Autodesk\Revit\Addins\<バージョン>\` に `.dll` と `.addin` の両方があるか確認。  
→ `.addin` の `ClientId` が他のプラグインと重複していないか確認。

**ビルドエラー：RevitAPI が見つからない**  
→ `.csproj` の HintPath がRevitのインストール先と一致しているか確認。  
→ デフォルト: `C:\Program Files\Autodesk\Revit 2024\RevitAPI.dll`

**ビルドツールが見つからないエラー**  
→ [.NET SDK](https://dotnet.microsoft.com/download) または [Visual Studio Community](https://visualstudio.microsoft.com/ja/vs/community/) をインストールしてください。

**エラーダイアログが出てプラグインが動かない**  
→ `%AppData%\Autodesk\Revit\Journals\` 内の最新ジャーナルファイルでエラー詳細を確認。

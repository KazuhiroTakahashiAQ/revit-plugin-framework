using Autodesk.Revit.UI;

namespace PluginName;

// このファイルはAIが生成したファイルで上書きしてください。
public class PluginUI
{
    private readonly PluginLogic _logic;

    public PluginUI(PluginLogic logic)
    {
        _logic = logic;
    }

    public Result Show()
    {
        // このスタブをAI生成コードで置き換えてください。
        TaskDialog.Show("PluginName", "PluginLogic.cs と PluginUI.cs をAI生成ファイルで置き換えてください。");
        return Result.Succeeded;
    }

    // ===== AIが実装するUIの例 =====
    //
    // 【パターンA：TaskDialog（テキスト表示のみ）】
    // public Result Show()
    // {
    //     var message = _logic.GetSomeData();
    //     var dialog = new TaskDialog("プラグイン名");
    //     dialog.MainInstruction = "実行結果";
    //     dialog.MainContent = message;
    //     dialog.Show();
    //     return Result.Succeeded;
    // }
    //
    // 【パターンB：WPFウィンドウ（入力・一覧表示など）】
    // public Result Show()
    // {
    //     var window = new MainWindow(_logic);
    //     window.ShowDialog();  // Revitメインスレッドで呼ぶのでDispatcher不要
    //     return window.DialogResult == true ? Result.Succeeded : Result.Cancelled;
    // }
    //
    // WPFウィンドウはXAMLファイルなしでC#コードのみで定義する（2ファイル構成を維持）:
    // public class MainWindow : System.Windows.Window
    // {
    //     public MainWindow(PluginLogic logic)
    //     {
    //         Title = "プラグイン名";
    //         Width = 400; Height = 300;
    //         WindowStartupLocation = System.Windows.WindowStartupLocation.CenterScreen;
    //         var panel = new System.Windows.Controls.StackPanel { Margin = new System.Windows.Thickness(10) };
    //         // ... コントロールを追加 ...
    //         Content = panel;
    //     }
    // }
}

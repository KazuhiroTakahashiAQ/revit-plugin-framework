using Autodesk.Revit.Attributes;
using Autodesk.Revit.UI;

namespace PluginName;

// このファイルは編集不要です。下の4つの定数だけ書き換えてください。
[Regeneration(RegenerationOption.Manual)]
public sealed class App : IExternalApplication
{
    private const string TabName     = "MyPlugins";
    private const string PanelName   = "PluginName";
    private const string ButtonLabel = "Run\nPlugin";
    private const string ToolTip     = "プラグインを実行します。";

    public Result OnStartup(UIControlledApplication application)
    {
        try
        {
            application.CreateRibbonTab(TabName);
        }
        catch
        {
            // 同名タブが他のプラグインによって既に作成されている場合は無視する
        }

        var panel = application.CreateRibbonPanel(TabName, PanelName);
        var buttonData = new PushButtonData(
            nameof(Command),
            ButtonLabel,
            typeof(Command).Assembly.Location,
            typeof(Command).FullName!);
        buttonData.ToolTip = ToolTip;
        panel.AddItem(buttonData);

        return Result.Succeeded;
    }

    public Result OnShutdown(UIControlledApplication application) => Result.Succeeded;
}

using Autodesk.Revit.Attributes;
using Autodesk.Revit.UI;

namespace HelloWorld;

[Regeneration(RegenerationOption.Manual)]
public sealed class App : IExternalApplication
{
    private const string TabName     = "MyPlugins";
    private const string PanelName   = "Hello World";
    private const string ButtonLabel = "Hello\nWorld";
    private const string ToolTip     = "現在のモデルの壁の数を表示します。";

    public Result OnStartup(UIControlledApplication application)
    {
        try
        {
            application.CreateRibbonTab(TabName);
        }
        catch { }

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

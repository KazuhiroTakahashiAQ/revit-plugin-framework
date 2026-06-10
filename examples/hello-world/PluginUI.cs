using Autodesk.Revit.UI;

namespace HelloWorld;

public class PluginUI
{
    private readonly PluginLogic _logic;

    public PluginUI(PluginLogic logic)
    {
        _logic = logic;
    }

    public Result Show()
    {
        var (title, wallCount) = _logic.GetSummary();

        var dialog = new TaskDialog("Hello World");
        dialog.MainInstruction = "ドキュメント情報";
        dialog.MainContent =
            $"ドキュメント: {title}\n" +
            $"壁の数: {wallCount} 個";
        dialog.Show();

        return Result.Succeeded;
    }
}

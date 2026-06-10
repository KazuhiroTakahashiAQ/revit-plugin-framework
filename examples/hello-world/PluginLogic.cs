using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace HelloWorld;

public class PluginLogic
{
    protected readonly Document Doc;
    protected readonly UIDocument UiDoc;

    public PluginLogic(UIDocument uiDoc)
    {
        UiDoc = uiDoc;
        Doc   = uiDoc.Document;
    }

    public (string DocumentTitle, int WallCount) GetSummary()
    {
        var wallCount = new FilteredElementCollector(Doc)
            .OfClass(typeof(Wall))
            .GetElementCount();

        return (Doc.Title, wallCount);
    }
}

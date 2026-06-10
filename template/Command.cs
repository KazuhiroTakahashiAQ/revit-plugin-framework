using System;
using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace PluginName;

// このファイルは編集不要です。
[Transaction(TransactionMode.Manual)]
public sealed class Command : IExternalCommand
{
    public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
    {
        var uiDoc = commandData.Application.ActiveUIDocument;
        if (uiDoc is null)
        {
            TaskDialog.Show("エラー", "ドキュメントが開かれていません。");
            return Result.Failed;
        }

        try
        {
            var logic = new PluginLogic(uiDoc);
            var ui    = new PluginUI(logic);
            return ui.Show();
        }
        catch (Autodesk.Revit.Exceptions.OperationCanceledException)
        {
            return Result.Cancelled;
        }
        catch (Exception ex)
        {
            message = ex.Message;
            TaskDialog.Show("エラー", ex.Message);
            return Result.Failed;
        }
    }
}

using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace PluginName;

// このファイルはAIが生成したファイルで上書きしてください。
public class PluginLogic
{
    protected readonly Document Doc;
    protected readonly UIDocument UiDoc;

    public PluginLogic(UIDocument uiDoc)
    {
        UiDoc = uiDoc;
        Doc   = uiDoc.Document;
    }

    // ===== AIが実装するメソッドの例 =====
    //
    // 【読み取り：壁を全件取得】
    // public IList<Wall> GetAllWalls()
    // {
    //     return new FilteredElementCollector(Doc)
    //         .OfClass(typeof(Wall))
    //         .Cast<Wall>()
    //         .ToList();
    // }
    //
    // 【読み取り：選択中の要素を取得】
    // public IList<Element> GetSelectedElements()
    // {
    //     return UiDoc.Selection.GetElementIds()
    //         .Select(id => Doc.GetElement(id))
    //         .ToList();
    // }
    //
    // 【書き込み：パラメータをセット（トランザクション必須）】
    // public void SetMark(ElementId id, string value)
    // {
    //     using var tx = new Transaction(Doc, "マーク設定");
    //     tx.Start();
    //     Doc.GetElement(id).get_Parameter(BuiltInParameter.ALL_MODEL_MARK).Set(value);
    //     tx.Commit();
    // }
    //
    // 【単位変換】
    // double meters = UnitUtils.ConvertFromInternalUnits(feetValue, UnitTypeId.Meters);
}

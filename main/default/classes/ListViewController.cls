global class ListViewController extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow defaultVal = new VisualEditor.DataRow('None', '');
        return defaultVal;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows result = new VisualEditor.DynamicPickListRows();
        String folderName = 'Sales_and_Marketing_Reports';
        // get all report
        List <Report> reportList = [SELECT Id,Name FROM Report WHERE OwnerId IN (
                                        SELECT ID FROM Folder WHERE DeveloperName =:folderName)];
        for (Report item : reportList) {
            VisualEditor.DataRow picklistRowVal = new VisualEditor.DataRow(item.Name, (String)item.Id);            
            result.addRow(picklistRowVal);
        }

        return result;
    }
}
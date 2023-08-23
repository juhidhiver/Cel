/**
 * @File Name          : TreeStructure.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 5/18/2020, 2:45:41 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/18/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public class TreeStructure{
    @AuraEnabled public String label;
    @AuraEnabled public String name;
    @AuraEnabled public Boolean expanded;
    @AuraEnabled public List<TreeStructure> items;
    public TreeStructure(String label, String name, Boolean expanded, List<TreeStructure> items){
        this.label = label;
        this.name = name;
        this.expanded = expanded;
        if(items != null && items.size() > 0){
            this.items = items;
        }else{
            this.items = new List<TreeStructure>();
        }
    }
}
public with sharing class AccountSetupController {
    @AuraEnabled
    public static List <List<String>> getselectOptions(sObject objObject, string fld) {
        system.debug('objObject --->' + objObject);
        system.debug('fld --->' + fld);
        List<List<String>> allOpts = new list<list<String>> ();
        // Get the object type of the SObject.
        Schema.sObjectType objType = objObject.getSObjectType();

        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();

        // Get a map of fields for the SObject
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();

        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values =
                fieldMap.get(fld).getDescribe().getPickListValues();

        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a : values) {
            allOpts.add(new list<string>{a.getLabel(), a.getValue()});
        }
        system.debug('allOpts ---->' + allOpts);
        return allOpts;
    }
}
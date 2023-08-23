public with sharing class CountrySelectController {
    @AuraEnabled(cacheable=true)
    public static Id getRecordTypeIdFromDeveloperName(String developerName)
    {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(developerName)
            .getRecordTypeId();
    }
}
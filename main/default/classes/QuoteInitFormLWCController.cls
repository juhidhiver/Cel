public with sharing class QuoteInitFormLWCController {
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(String oppId) {
        List<Opportunity> opps = [SELECT Id, Name, AccountId, Product_Name__c, StageName,
                    Effective_Date__c, Expiration_Date__c, CloseDate, Policy__c
				FROM Opportunity 
                WHERE Id =: oppId ];
        return opps.isEmpty() ? new Opportunity() : opps[0];
    }
}
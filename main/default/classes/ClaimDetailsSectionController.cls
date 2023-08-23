public with sharing class ClaimDetailsSectionController {
    

    @AuraEnabled(cacheable=true)
        public static List<Claim_Data__c> getSubmissionRelatedToAccount(String oppId) {
            system.debug('accId >> ' + oppId);

            List<Opportunity> oppRecordwithAccountId = [SELECT ID, AccountId from Opportunity WHERE Id =: oppId ];
            system.debug('oppRecordwithAccountId----'+oppRecordwithAccountId);
           // system.debug('claimslist'+ [ SELECT ID, Account__c, Name, Policy_Number__c, Insured_name__c from Claim_Data__c WHERE Account__c =: oppRecordwithAccountId[0].AccountId]);
           return [SELECT ID, Account__c, Name , Policy_Number__c, Insured_name__c , Policy__r.Policy_Number__c , 
                    Claim_status__c ,Indemnity_Paid__c , Indemnity_Reserve__c ,
                    Fees_Paid__c , Fees_Reserve__c, Policy__c ,Total_Incurred__c, Policy_Effective_Date__c
                    from Claim_Data__c WHERE Account__c =: oppRecordwithAccountId[0].AccountId] ;
        }
        
        
    
}
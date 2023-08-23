/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 09-20-2021
 * @last modified by  : Vinayesh
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-18-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class ClearanceLwcController {
    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';
    
    @AuraEnabled(cacheable = true)
    public static String getProductId(Id recordId) {
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            system.debug('sObjName:' + sObjName);
            String productId = null;
            if(sObjName == QUOTE_PROCESS_OBJ) {
               
                List<Quote_Process__c> listQuoteProcess = [SELECT Id,Product__c FROM Quote_Process__c
                                                             WHERE Id = :recordId];
                List<Product2> prodId = [SELECT Id FROM Product2
                                            WHERE Name = :listQuoteProcess[0].Product__c];
                if(prodId.size() > 0){
                    productId = prodId[0].Id;
                }
                
            }
            if(sObjName == OPPORTUNITY_OBJ) {
                List<Opportunity> listOpp = [SELECT Id, StageName, Product__c, Product__r.Name,
                                                (SELECT Id, Account__c,Record_Type__c,Submission__r.StageName, 
                                                  Submission__c, Status__c FROM Quote_Process__r LIMIT 1) 
                                                     FROM Opportunity WHERE Id = :recordId];
                productId =  listOpp[0].Product__c;                
            }
            System.debug('productName:' + productId);
        return productId;
    }

    @AuraEnabled(cacheable = true)
    public static String getAccountId(Id recordId) {
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            system.debug('sObjName:' + sObjName);
            String accId = null;
            if(sObjName == QUOTE_PROCESS_OBJ) {
               
                List<Quote_Process__c> listQuoteProcess = [SELECT Id,Account__c FROM Quote_Process__c
                                                             WHERE Id = :recordId];
                
                accId = listQuoteProcess[0].Account__c;
            }
            if(sObjName == OPPORTUNITY_OBJ) {
                List<Opportunity> listOpp = [SELECT Id, StageName, Product__c, AccountId, Product__r.Name,
                                                (SELECT Id, Account__c,Record_Type__c,Submission__r.StageName, 
                                                  Submission__c, Status__c FROM Quote_Process__r LIMIT 1) 
                                                     FROM Opportunity WHERE Id = :recordId];
             accId =  listOpp[0].AccountId;                
            }
            System.debug('accName:' + accId);
        return accId;
    }

    @AuraEnabled
    public static Boolean CheckBoundSubmission(String oppId) {
        Boolean isBoundSubmission = false;
        List<Quote> oppQuotes = [Select Status from Quote Where OpportunityId =:oppId];
        for(Quote qt : oppQuotes){
            if(qt.Status == 'Bound'){
                isBoundSubmission= true;
            }
        }
        return isBoundSubmission;
    }
    
    @AuraEnabled
    public static String getSubmissionId(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        String oppId;
        ResultResponse result = new ResultResponse();
        system.debug('sObjName:::' + sObjName);
        if(sObjName == QUOTE_PROCESS_OBJ) {
            List<Quote_Process__c> quotePrs = [SELECT Id, Submission__c FROM Quote_Process__c WHERE Id = :recordId];
            if(!quotePrs.isEmpty()){
                if(quotePrs[0].Submission__c != null){
                    oppId = quotePrs[0].Submission__c;
                }
            }
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            oppId = recordId;
        }
        //tuan.d.nguyen added 24-Jun-2020 
        // Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id =: oppId LIMIT 1];
        // result.isSuccess = true;
        // result.data = opp;
        return oppId;
    }
}
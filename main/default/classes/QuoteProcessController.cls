/**
 * @File Name          : QuoteProcessController.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Vinayesh
 * @Last Modified On   : 02-18-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public with sharing class QuoteProcessController {

    public static final String QUOTE_PROCESS_OBJ = 'Quote_Process__c';
    public static final String OPPORTUNITY_OBJ = 'Opportunity';
    @AuraEnabled(cacheable=true)
    public static Quote_Process__c getSingleQuoteProcess() {
        return [SELECT Id, Account__c, Submission__c, Status__c FROM Quote_Process__c WITH SECURITY_ENFORCED LIMIT 1];
    }   
    
    @AuraEnabled(cacheable=true)
    public static Quote_Process__c getRecordInfos(Id recordId) {
        System.debug('recordId '+recordId);
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if(sObjName == QUOTE_PROCESS_OBJ) {
            return [SELECT Id, Account__c,Submission__r.StageName,Submission__r.Type, Submission__c, Status__c, Submission_Product__c, Product__c FROM Quote_Process__c WHERE Id = :recordId];
        }
        if(sObjName == OPPORTUNITY_OBJ) {
            List<Opportunity> listOpp = [SELECT Id,StageName,AccountId,Type,
                                        (SELECT Id, Account__c,Submission__r.StageName,Submission__r.Type, Submission__c, Status__c, Submission_Product__c FROM Quote_Process__r LIMIT 1)
                                        FROM Opportunity WHERE Id = :recordId];
            if(listOpp[0].Quote_Process__r.isEmpty()){
                return new Quote_Process__c(Submission__c = listOpp[0].Id, Account__c = listOpp[0].AccountId, Status__c = 'Submission Info');
            }else{
                return listOpp[0].Quote_Process__r[0];
            }
        }
        return null;
    }

    @AuraEnabled
    public static Boolean checkExistQuoteStatusBoundOrBoundPending(String submissionId){
        // List<String> lstStatusToLock = new List<String>{'Bound','Bound Pending'};
        List<Quote> lockedQuotes =  [SELECT Id, Name, Status, Rating_Status__c, Last_Quote_Version__c
											FROM Quote
											WHERE OpportunityId = :submissionId
                                            AND (Status = 'Bound' OR Status = 'Bound Pending')];
        List<Quote> lstQuote  = [SELECT Id, Name, Status, Rating_Status__c, Last_Quote_Version__c
                                        FROM Quote
                                        WHERE OpportunityId = :submissionId
                                        AND (Status = 'Rated' OR Status = 'Referred' OR Status ='Quoted')];
        return lockedQuotes.size() > 0 || lstQuote.size() == 0;
    }
    @AuraEnabled
    public static ResultResponse updateAllQuoteToInProgress(String submissionId){
        // List<String> lstStatusToLock = new List<String>{'Bound','Bound Pending'};
        ResultResponse response = new ResultResponse();
        List<Quote> updatedQuotes =  [SELECT Id, Name, Status, Rating_Status__c, Last_Quote_Version__c
											FROM Quote
											WHERE OpportunityId = :submissionId
											AND (Status = 'Rated' OR Status = 'Referred' OR Status ='Quoted')];
        Savepoint sp = Database.setSavepoint();
        for (Quote quote : updatedQuotes) {
            quote.Status = 'In Progress';
        }
        try {
            update updatedQuotes;
            response.isSuccess = true;
        } catch (Exception ex) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors.add(ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        return response;
    }

    @AuraEnabled
    public static String createSubmission(String quoteProcessId,String accountId) {
        List<Account> listAccount = [SELECT Id,Name FROM Account WHERE Id = : accountId];
        if(!listAccount.isEmpty()) {
            List<Quote_Process__c> listQuoteProcess = [SELECT Id,Name,Status__c,Submission__c,Account__c,Submission__r.RecordType.Name,Submission__r.AccountId 
                                        FROM Quote_Process__c WHERE Id = :quoteProcessId];
            if(!listQuoteProcess.isEmpty()) {
                if(String.isBlank(listQuoteProcess[0].Submission__c)) {
                    return null;
                    /*
                    Opportunity opp = new Opportunity(AccountId = accountId, Name = listAccount[0].Name + ' Submission', StageName = 'New');
                    insert opp;
                    return opp.Id;*/
                }
                if(listQuoteProcess[0].Submission__r.RecordType.Name == 'Aqueous' && listAccount[0].Id != listQuoteProcess[0].Submission__r.AccountId){
                    List<Opportunity> lstOppToUpdate = [SELECT Id, AccountId FROM Opportunity WHERE Id = :listQuoteProcess[0].Submission__c];
                    lstOppToUpdate[0].AccountId = listAccount[0].Id;
                    update lstOppToUpdate;
                }
                return listQuoteProcess[0].Submission__c; 
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static boolean checkRatingModifiersValidityForOpp(String opportunityId) {

        List<Product_Option_Line_Item__c> poliList =  [SELECT Id, Product__c, Product__r.Name, Notes__c, Submission__c, Clearance_Date__c,
                                                       Clearance_Status__c, Is_Selected__c, Account__c, IsManualClearance__c
                                                       FROM Product_Option_Line_Item__c
                                                       WHERE Submission__c = :opportunityId];
        Set<String> selProds = new Set<String>();
        for(Product_Option_Line_Item__c poli : poliList){
            if(poli.Clearance_Status__c == 'Cleared'){
                selProds.add(poli.Product__r.Name);
            }
        }
        boolean isRatingValid = true;
        for(Rating_Modifiers__c eachRatingModifier : [SELECT Id, Name,Product__c, Format__c, Picklist_Values__c, Is_Required__c,Eligibility_Status__c,
                            Page_Section__c, Opportunity__c, Rating_Modifier_Code__c,Rating_Modifier_Value__c,Controlling_Picklist_API_Name__c,Dependent_Picklist_API_Name__c,
                            Object_API_Name_of_Picklist__c,Controlling_Picklist_Value__c,Dependent_Picklist_Value__c, Sub_Section__c, Sort_Sub_Section__c, Profile_Name_for_Read_Only__c,
                            Submission_Field_API_Name__c, Factor_Default_Value__c
                            FROM Rating_Modifiers__c where Opportunity__c =: opportunityId AND Display_Format__c = 'Clearance'
                            AND (Rating_Modifier_Code__c = 'PSDO00000121212' OR Rating_Modifier_Code__c = 'PSFID000005989890' OR
                                 Rating_Modifier_Code__c = 'PSEPL000005232421' OR Rating_Modifier_Code__c = 'PSEPL000005232422')]){
             if(eachRatingModifier.Rating_Modifier_Code__c == 'PSDO00000121212' && selProds.contains(eachRatingModifier.Product__c)){
                 if(eachRatingModifier.Rating_Modifier_Value__c == null || decimal.valueOf(eachRatingModifier.Rating_Modifier_Value__c) == 0){
                    isRatingValid = false;
                 }
             }
             if(eachRatingModifier.Rating_Modifier_Code__c == 'PSFID000005989890' && selProds.contains(eachRatingModifier.Product__c)){
                if(eachRatingModifier.Rating_Modifier_Value__c == null || decimal.valueOf(eachRatingModifier.Rating_Modifier_Value__c) == 0){
                   isRatingValid = false;
                }
            }
            if(eachRatingModifier.Rating_Modifier_Code__c == 'PSEPL000005232421' && selProds.contains(eachRatingModifier.Product__c)){
                if(eachRatingModifier.Rating_Modifier_Value__c == null || decimal.valueOf(eachRatingModifier.Rating_Modifier_Value__c) == 0){
                   isRatingValid = false;
                }
                else isRatingValid = true;
            }
            if(eachRatingModifier.Rating_Modifier_Code__c == 'PSEPL000005232422' && selProds.contains(eachRatingModifier.Product__c)){
                if(eachRatingModifier.Rating_Modifier_Value__c == null || decimal.valueOf(eachRatingModifier.Rating_Modifier_Value__c) == 0){
                   isRatingValid = false;
                }
                else isRatingValid = true;
            }
        }
        return isRatingValid;
    }

    public class ItemWrapper{
		@AuraEnabled public String Id {get; set;}
		@AuraEnabled public String QpId {get; set;}
		@AuraEnabled public String Name {get; set;}
        @AuraEnabled public String Policy_Status {get; set;}
        @AuraEnabled public String Policy_Number {get; set;}
		@AuraEnabled public Decimal Total_Premium {get; set;}
		@AuraEnabled public Datetime Effective_Date {get; set;}
		@AuraEnabled public Datetime Expiration_Date {get; set;}
        public ItemWrapper() {
            Id = '';
			QpId = '';
            Policy_Status = '';
            Policy_Number = '';
			Total_Premium = 0;
			Effective_Date = null;
			Expiration_Date = null;
        }
    }
}
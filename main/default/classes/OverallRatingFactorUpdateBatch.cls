/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 05-30-2022
 * @last modified by  : Vinayesh
**/
global class OverallRatingFactorUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global OverallRatingFactorUpdateBatch() {
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // String query = 'SELECT Id,Master_Binder__c,RetroDate__c,Retroactive_Date__c, Status, Azure_Id__c, Policy__c, AccountId,' +
        // 'Account.Name, QuotePremium__c, Effective_Date__c, ExpirationDate,Endorsement_Reason__c,' +
        // 'Total_Premium__c,Total_Cost_To_Client__c,Policy_Wording_Document__c, OpportunityId, Rating_Status__c, Product_Name__c,'+
        // 'Endorsement_Quote_Bound_Date__c,Quote_Type__c, Layer__c,Endorsement_Effective_Date__c ' +
        // 'FROM Quote Where Product_Name__c = \'Cyber Standalone\' ' +
        // 'And Status != \'Closed\' And Status != \'Rejected\' ' +
        // 'And Status != \'Correction\' And Status != \'Cancelled\' and Azure_Id__c = \'0a735f17-b60e-43f9-a78a-ca233f3ae97e\' order by createddate desc Limit 1'; 

        String query = 'SELECT Id,Master_Binder__c,RetroDate__c,Retroactive_Date__c, Status, Azure_Id__c, Policy__c, AccountId,' +
        'Account.Name, QuotePremium__c, Effective_Date__c, ExpirationDate,Endorsement_Reason__c,' +
        'Total_Premium__c,Total_Cost_To_Client__c,Policy_Wording_Document__c, OpportunityId, Rating_Status__c, Product_Name__c,'+
        'Endorsement_Quote_Bound_Date__c,Quote_Type__c, Layer__c,Endorsement_Effective_Date__c  ' +
        'FROM Quote Where Product_Name__c = \'Private Company Combo\' And  Status != \'In Progress\'';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Quote> quoteList) {
        for(Quote qt : quoteList){
            try{
                CommonUtil.updateOverallRatingFactorForPccQuote(qt.Id);
            }
            catch(Exception ex){

            }
        }
    }

    public void finish(Database.BatchableContext info) {}    
    
}
/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 06-29-2022
 * @last modified by  : Vinayesh
**/
global class CyberCliUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global CyberCliUpdateBatch() {
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
        'Account.Name, Account.BillingStateCode, QuotePremium__c, Effective_Date__c, ExpirationDate,Endorsement_Reason__c,' +
        'Total_Premium__c,Total_Cost_To_Client__c,Policy_Wording_Document__c, OpportunityId, Rating_Status__c, Product_Name__c,'+
        'Endorsement_Quote_Bound_Date__c,Quote_Type__c, Layer__c,Endorsement_Effective_Date__c  ' +
        //'FROM Quote Where Opportunity.RecordType.Name = \'Celerity\' And Product_Name__c like \'%Cyber%\' order by CreatedDate desc limit 175';
       'FROM Quote Where Opportunity.RecordType.Name = \'Celerity\' And (Product_Name__c like \'%Cyber%\' Or Product_Name__c like \'%MPL%\') order by CreatedDate desc';
       //'FROM Quote Where Opportunity.RecordType.Name = \'Celerity\' And (Product_Name__c like \'%Cyber%\' Or Product_Name__c like \'%MPL%\')' + 
       //' And (OpportunityId = \'0064J00000KcuY2QAJ\' Or OpportunityId = \'0064J00000Kso69QAB\' Or OpportunityId = \'0064J00000LAQTnQAP\' or OpportunityId = \'0064J00000DmrhHQAR\' or Azure_ID__c = \'Test Az 1\')';
       //' And (OpportunityId = \'0068E00000SWthVQAT\' Or OpportunityId = \'0068E00000SWk4XQAT\' Or OpportunityId = \'0064J00000LAQTnQAP\' or OpportunityId = \'0064J00000DmrhHQAR\' or Azure_ID__c = \'Test Az 1\')';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Quote> quoteList) {
        try {
       
                    List<CoveragesLineItem__c> existCLis = [Select Id, Coverage_Premium__c, Non_Prorated_Coverage_Premium__c, Coverage__r.Coverage_Code__c,
                                                            Coverage__c, Coverage__r.Id, Quote__c, Azure_ID__c
                                                            From CoveragesLineItem__c
                                                            Where Quote__c in :quoteList And Azure_ID__c = null];

                    if(existCLis.size() > 0){
                        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
                        GlobalStaticVar.byPassQuoteTrigger = true;
                        CommonUtil.generateExternalID('Azure_ID__c', existCLis);
                        update existCLis;
                        GlobalStaticVar.byPassCoverageLineItemTrigger = false;
                        GlobalStaticVar.byPassQuoteTrigger = false;   
                    }

        } catch (Exception ex) {
            ErrorLogsUtilityHelper.logError(ex, 'Azure Id Data Fix', ex.getMessage(), quoteList[0].Id, 'Quote', 'Update', 'None');
            System.debug('Cli Update Batch');
            System.debug(ex.getMessage());
            System.debug(quoteList);
        }
        
    }

    public void finish(Database.BatchableContext info) {
    }    
}
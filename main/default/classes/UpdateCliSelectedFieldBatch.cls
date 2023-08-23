/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 07-02-2022
 * @last modified by  : Vinayesh
**/
global class UpdateCliSelectedFieldBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Quote quoteRec;
    global UpdateCliSelectedFieldBatch() {
    }
    global UpdateCliSelectedFieldBatch(Quote newQuote) {
        quoteRec = newQuote;
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
        'FROM Quote Where Opportunity.RecordType.Name = \'Celerity\' And (Quote_Type__c = \'Renewal\' Or Quote_Type__c = \'Amendment\')';

        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Quote> quoteList) {
        try{
            syncQuote(quoteRec);
        }
        catch(Exception ex){

        }
        quoteRec = null;
        try{
       
        for(Quote qt : quoteList){
            if(qt.Quote_Type__c == 'Amendment' && !qt.Product_Name__c.contains('Private')){

                List<CoveragesLineItem__c> covList = [Select Id, IsSelected__c, Coverage_Effective_Date__c, 
                                                        Coverage__r.Coverage_Type__c, Coverage__r.Id, Quote__c
                                                        From CoveragesLineItem__c where Quote__c =: qt.Id And Coverage__r.Coverage_Code__c in ('CyberDec',
                                            'AcceleratorCyberInsuredPolicy',
                                            'ServiceOfProcess',
                                            'ServiceOfProcessIL',
                                            'ServiceOfProcessPA',
                                            'PolicyTRIADisc',
                                            'CapOnLossesTRIA',
                                            'MPLDec',
                                            'MPLCoverageForm',
                                            'ExcessDec',
                                            'ExcessPolicyForm',
                                            'ExcessSignatureEndorsement',
                                            'ExcessTRIA',
                                            'ExcessSOP',
                                            'ExcessSOPIL',
                                            'ExcessSOPPA',
                                            'ExcessOFACNotice',
                                            'ExcessLossNotice',
                                            'OFAC',
                                            'LossReporting') And LastModifiedBy.Username like '%vinayesh%'];
                
                    List<CoveragesLineItem__c> dateUpdateClis = new List<CoveragesLineItem__c>();
                    for(CoveragesLineItem__c cliItem : covList){
                        cliItem.Coverage_Effective_Date__c = qt.Effective_Date__c;
                        dateUpdateClis.add(cliItem);
                    }
                    if(dateUpdateClis.size() > 0){
                        GlobalStaticVar.byPassCoverageLineItemTrigger = true;
                        GlobalStaticVar.byPassQuoteTrigger = true;
                        update dateUpdateClis;
                        GlobalStaticVar.byPassCoverageLineItemTrigger = false;
                        GlobalStaticVar.byPassQuoteTrigger = false;
                        quoteRec = quoteList[0];      
                    }
            }
                List<CoveragesLineItem__c> existCli = [Select Id, IsSelected__c, Coverage_Effective_Date__c, 
                                                       Coverage__r.Coverage_Type__c, Coverage__r.Id, Quote__c
                                                       From CoveragesLineItem__c
                                                       Where Quote__c = :qt.Id And Quote__r.Quote_Type__c = 'Renewal'];
                
                List<CoveragesLineItem__c> cliToUpdate = new List<CoveragesLineItem__c>();

                for(CoveragesLineItem__c currCLi : existCli){
                    if(currCLi.Coverage__r.Coverage_Type__c == 'Endorsement'){
                        currCLi.Coverage_Effective_Date__c = quoteList[0].Effective_Date__c;
                        cliToUpdate.add(currCLi);
                    }
                }
                //CoverageLineItemTriggerHandler_CEL.filterEndorsement(existCli);
                if(existCli.size() > 0){
                    GlobalStaticVar.byPassCoverageLineItemTrigger = true;
                    GlobalStaticVar.byPassQuoteTrigger = true;
                    update cliToUpdate;
                    GlobalStaticVar.byPassCoverageLineItemTrigger = false;
                    GlobalStaticVar.byPassQuoteTrigger = false;   
                    quoteRec = quoteList[0];
                }                     
        }
      
    }
        catch(Exception ex){
            ErrorLogsUtilityHelper.logError(ex, 'Update Renewal Date Data Fix', ex.getMessage(), quoteList[0].Id, 'Quote', 'Update', 'None');
        }
    }

    public void finish(Database.BatchableContext info) {
        syncQuote(quoteRec);
    }    

    private static void syncQuote(Quote qt){
        API_Configuration__mdt apiSetting = CommonUtil.getAPIconfiguration('Quote_Sync');
        if(qt != null){
            List<Quote> qtToUpdate = [SELECT Id, Status, Name, Rating_Status__c,Accept_Terror_Premium__c,
                                Endorsement_Quote_Bound_Date__c,
                                Quote_Type__c,Non_Prorated_Quote_Premium__c, Parent_Quote__c, Product_Name__c, Opportunity.Id
                                FROM Quote WHERE Id =: qt.Id];
            if(qtToUpdate.size() > 0){
                Quote qt1 = qtToUpdate[0];
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();

                req = SyncQuoteBatch.getHttpRequest(apiSetting, qt1);  
                Http h = new Http();
                if(!Test.isRunningTest())
                    res = h.send(req);

                //ApiUtil.logAPICall(req,res,'Sync Quote Status','SyncQuoteBatch', apiSetting.HeaderParams__c, 'Outbound');
            }
        }
    }
    
}
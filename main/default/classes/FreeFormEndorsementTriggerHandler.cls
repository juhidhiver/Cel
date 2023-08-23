/**************************************************************************************************
* Class Name: FreeFormEndorsementTriggerHandler
* Author: Sarthak Roy
* Created date: 31-March-2021
* Description: TriggerHandler for Free_Form_Endorsements__c Object
**************************************************************************************************/
public with sharing class FreeFormEndorsementTriggerHandler extends TriggerHandler{
    private List<Free_Form_Endorsements__c> oldDataList;
    private List<Free_Form_Endorsements__c> newDataList;
    private Map<Id, Free_Form_Endorsements__c> newDataMap;
    private Map<Id, Free_Form_Endorsements__c> oldDataMap;

    public FreeFormEndorsementTriggerHandler() {
        this.oldDataList = (List<Free_Form_Endorsements__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Free_Form_Endorsements__c>) Trigger.oldMap;
        
        this.newDataList = (List<Free_Form_Endorsements__c>) Trigger.new;
        this.newDataMap = (Map<Id, Free_Form_Endorsements__c>) Trigger.newMap;
    }
    public override void afterinsert(){
		updateQuoteStatusAQ(newDataList);
    }
    public override void afterupdate(){
        updateQuoteStatusAQ(newDataList);
    }
    public override void afterdelete(){
        updateQuoteStatusAQ(oldDataList);
    }

    private static void updateQuoteStatusAQ(List<Free_Form_Endorsements__c> freeEndorsements){
        Set<Id> quoteIds = new Set<Id>();
        for(Free_Form_Endorsements__c endorsement:freeEndorsements){
            quoteIds.add(endorsement.Quote__c);
        }

        List<Quote> updateQuote = new List<Quote>();
        for(Quote quote:[SELECT Id, Status, OpportunityId, Product_Name__c FROM Quote WHERE Id IN:quoteIds]){
            if(quote.status != 'In Progress' && quote.Product_Name__c == 'Professional Indemnity'){
                quote.status = 'In Progress';
            }
            updateQuote.add(quote);
        }

        if(updateQuote.size()>0){
            update updateQuote;
        }
    }
}
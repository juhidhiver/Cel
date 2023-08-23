/**************************************************************************************************
* Class Name: UWAnalysisTriggerHandler
* Author: Sarthak Roy
* Created date: 06-April-2021
* Description: TriggerHandler for UWAnalysisTrigger
**************************************************************************************************/
public class UWAnalysisTriggerHandler extends TriggerHandler{
    private List<UW_Analysis__c> oldDataList;
    private List<UW_Analysis__c> newDataList;
    private Map<Id, UW_Analysis__c> newDataMap;
    private Map<Id, UW_Analysis__c> oldDataMap;

    public UWAnalysisTriggerHandler() {
        this.oldDataList = (List<UW_Analysis__c>) Trigger.old;
        this.oldDataMap = (Map<Id, UW_Analysis__c>) Trigger.oldMap;
        
        this.newDataList = (List<UW_Analysis__c>) Trigger.new;
        this.newDataMap = (Map<Id, UW_Analysis__c>) Trigger.newMap;
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

    private static void updateQuoteStatusAQ(List<UW_Analysis__c> uwList){
        Set<Id> submissionIds = new Set<Id>();
        List<Quote> quoteList = new List<Quote>();
        List<Quote> updateQuotes = new List<Quote>();
        Set<Id> updateReferredQuotes = new Set<Id>();
        
        for(UW_Analysis__c uwAnalysis:uwList){
            submissionIds.add(uwAnalysis.Submission__c);
        }
        
     system.debug('submissionIds: '+submissionIds);
        if(submissionIds != null){
            quoteList = [Select Id,OpportunityId, Status from Quote where OpportunityId IN:submissionIds
                         AND (Status != 'Closed' AND Status != 'Rejected')];
        }
        
        if(!quoteList.isEmpty()){
            for(Quote quote : quoteList){
                if(quote.Status == 'Referred'){
                    updateReferredQuotes.add(quote.Id);
                }
                else{
                    if(quote.Status != 'In Progress'){quote.Status = 'In Progress';}
                    updateQuotes.add(quote);
                }
            }
        }
        
        if(updateQuotes.size() > 0){
            GlobalStaticVar.byPassQuoteTrigger = true;
            update updateQuotes;
        }

        if(!updateReferredQuotes.isEmpty()){
            CommonUtilAQ.removeApprovalRequestsAndUnlockQuote(updateReferredQuotes);
        }
    }
}
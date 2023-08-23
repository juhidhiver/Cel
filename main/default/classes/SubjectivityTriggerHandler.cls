/**************************************************************************************************
* Class Name: SubjectivityTriggerHandler
* Author: Sarthak Roy
* Created date: 17-Dec-2020
* Description: TriggerHandler for Subjectivity__c Trigger
**************************************************************************************************/
public class SubjectivityTriggerHandler extends TriggerHandler{
    private List<Subjectivity__c> oldDataList;
    private List<Subjectivity__c> newDataList;
    private Map<Id, Subjectivity__c> newDataMap;
    private Map<Id, Subjectivity__c> oldDataMap;
    
    public SubjectivityTriggerHandler(){
        this.oldDataList = (List<Subjectivity__c>) Trigger.old;
        this.oldDataMap = (Map<Id, Subjectivity__c>) Trigger.oldMap;
        
        this.newDataList = (List<Subjectivity__c>) Trigger.new;
        this.newDataMap = (Map<Id, Subjectivity__c>) Trigger.newMap;
    }
    public static boolean checkProfile = True;
    
    public override void beforeupdate() {
       checkUWProfile();
       populateClearedDate(newDataList, oldDataMap);
    }
    public override void beforeinsert(){
		checkUWProfile();  
        populateClearedDate(newDataList, oldDataMap);
    }   
    public override void beforedelete(){
		checkUWProfile(); 
    }
    public override void afterinsert(){
		updateQuoteStatusAQ(newDataList);
        clearSubjectivityStatus(newDataList, oldDataMap);
    }
    public override void afterupdate(){
        updateQuoteStatusAQ(newDataList);
        clearSubjectivityStatus(newDataList, oldDataMap);
    }
    public override void afterdelete(){
        updateQuoteStatusAQ(oldDataList);
    }


    private static void checkUWProfile(){
        Id profileId = userinfo.getProfileId();       
        
        String profileName = [Select Id, Name from Profile where Id =: profileId].Name;   
        system.debug('ProfileName' + profileName);
        if( profileName == 'Celerity Senior Underwriter' || profileName == 'Celerity Junior Underwriter'){
			checkProfile = False;           
        }
    }
    
    public static void populateClearedDate(List<Subjectivity__c> newDataList, Map<Id, Subjectivity__c> oldDataMap){
       for (Subjectivity__c subRec : newDataList){
            if (subRec.Cleared__c == true)
            {
                subRec.Cleared_Date__c = Date.today();
            }
            else{
                subRec.Cleared_Date__c = null;
            }
        } 
    }
    private static void updateQuoteStatusAQ(List<Subjectivity__c> subjectivities){
        Set<Id> quoteIds = new Set<Id>();
         List<Quote> syncQuotes = new List<Quote>();
        for(Subjectivity__c sub:subjectivities){
            quoteIds.add(sub.Quote__c);
        }

        List<Quote> updateQuote = new List<Quote>();
        for(Quote quote:[SELECT Id, Status, OpportunityId, Product_Name__c FROM Quote WHERE Id IN:quoteIds]){
            if(quote.status == 'Quoted' ){
                quote.status = 'Rated';
                updateQuote.add(quote);
            }
            else if(quote.status == 'Bound' && quote.Product_Name__c != 'Professional Indemnity' ){
               syncQuotes.add(quote);
            }
        }
        
         if(!syncQuotes.isEmpty())   
        {
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(syncQuotes));
        }

        if(updateQuote.size()>0){
            update updateQuote;
        }
    }
/**************************************************************************
* Method Name: clearSubjectivityStatus
* Author: Ashik Zahir
* Date: 12-July-2021
* Params: List<Subjectivity__c> subjectivities, Map<Id, Subjectivity__c> oldDataMap
* Description:  When Subjectivity Status is marked as Completed or Waived, It will be cleared
***************************************************************************/
    private static void clearSubjectivityStatus(List<Subjectivity__c> subjectivities, Map<Id, Subjectivity__c> oldDataMap ){
        Set<Id> subIds = new Set<Id>();
        List<Subjectivity__c> subList = new List<Subjectivity__c>();
        List<Subjectivity__c> subChangeList = new List<Subjectivity__c>();
        Boolean isUpdate = false;
        for(Subjectivity__c sub:subjectivities){
            subIds.add(sub.Id);
        }
            subList = [select Id,Subjectivity_Status__c,Cleared__c,Cleared_Date__c,Quote__c, Quote__r.Product_Name__c from Subjectivity__c
                       WHERE Id IN: subIds];
        
        
        if(!subList.isEmpty()){
            for(Subjectivity__c sub:subList){
                if(sub.Quote__r.Product_Name__c != 'Professional Indemnity'){
                    if(Trigger.isInsert){
                        if((sub.Subjectivity_Status__c == 'Completed' || sub.Subjectivity_Status__c == 'Waived')){
                            sub.Cleared__c = true ;
                            sub.Cleared_Date__c = Date.today();
                            isUpdate = true;
                        }
                    }else{
                        if((sub.Subjectivity_Status__c == 'Completed' || sub.Subjectivity_Status__c == 'Waived') && 
                           (oldDataMap.get(sub.Id).Subjectivity_Status__c != 'Completed' && oldDataMap.get(sub.Id).Subjectivity_Status__c != 'Waived')){
                               sub.Cleared__c = true ;
                               sub.Cleared_Date__c = Date.today();  
                               isUpdate = true;
                           }
                    }
                }
            }
            try {
                if(!subList.isEmpty() && isUpdate){
                    GlobalStaticVar.byPassSubjectivityTrigger = true;
                    update subList;
                }
            } catch (Exception ex) {
                system.debug('ex-->'+ex.getLineNumber()+' '+ex.getMessage());
            }
            
        }

        
    }
}
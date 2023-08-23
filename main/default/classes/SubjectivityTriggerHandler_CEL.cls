/**************************************************************************************************
 * Class Name: SubjectivityTriggerHandler_CEL
 * Author: 
 * Date: 
 * Description: handle Celerity record Type logic
 **************************************************************************************************/
public class SubjectivityTriggerHandler_CEL extends TriggerHandler{
    private List<Subjectivity__c> oldDataList;
    private List<Subjectivity__c> newDataList;
    private Map<Id, Subjectivity__c> newDataMap;
    private Map<Id, Subjectivity__c> oldDataMap;

    
    public SubjectivityTriggerHandler_CEL(List<Subjectivity__c> newDataList, List<Subjectivity__c> oldDataList, 
                                            Map<Id, Subjectivity__c> newDataMap, Map<Id, Subjectivity__c> oldDataMap){
                                                this.oldDataList = oldDataList;
                                                this.newDataList = newDataList;
                                                this.newDataMap = newDataMap;
                                                this.oldDataMap = oldDataMap;
                                            }
    
    
    public override void beforeupdate() {

        //set clear date
        CommonSubjectivityUtil.populateClearedDate(newDataList, oldDataMap);
    }
    public override void beforeinsert(){
 
        //set clear date
        CommonSubjectivityUtil.populateClearedDate(newDataList, oldDataMap);
    }   
    public override void beforedelete(){

    }
    public override void afterinsert(){
        //update quote if status = Quoted to Rated
        list<Quote> updatedQuote = CommonSubjectivityUtil.updateQuoteStatus(newDataList);
        //sync bound celerity quotes
        syncQuotes(updatedQuote);

        //clear subjectivity
        clearSubjectivityStatus(newDataList, oldDataMap, true/*trigger.isInsert*/);
    }
    public override void afterupdate(){
        //update quote if status = Quoted to Rated
        list<Quote> updatedQuote = CommonSubjectivityUtil.updateQuoteStatus(newDataList);
        //sync bound celerity quotes
        syncQuotes(updatedQuote);

        //clear subjectivity
        clearSubjectivityStatus(newDataList, oldDataMap, false/*trigger.isInsert*/);
    }
    public override void afterdelete(){
        //update quote if status = Quoted to Rated
        list<Quote> updatedQuote = CommonSubjectivityUtil.updateQuoteStatus(oldDataList);
        //sync bound celerity quotes
        syncQuotes(updatedQuote);
    }

    

    /*************************************************
    * Method Name: syncQuotes
    * Author:
    * Date: 
    * Params: list<Quote>
    * Return: 
    * Exceptions:
    * Description: checks if current user is celerity senior or junior under writter
    * Revision: 
    *************************************************/
    public static void syncQuotes( list<Quote> quoteList ){
        list<Quote> syncQuotes = new list<Quote>();
        for(Quote q : quoteList){
            if(q.status == 'Bound' && q.Product_Name__c != GlobalVariables.PROD_NAME_FOR_PI ){
               syncQuotes.add(q);
            }
        }
        
        if(!syncQuotes.isEmpty())  {
            ID jobID = System.enqueueJob(new SyncQuoteQueueable(syncQuotes));
        }
    }

    /**************************************************************************
    * Method Name: clearSubjectivityStatus
    * Author: 
    * Date: 
    * Params: List<Subjectivity__c> subjectivities, Map<Id, Subjectivity__c> oldDataMap
    * Description:  When Subjectivity Status is marked as Completed or Waived, It will be cleared
    ***************************************************************************/
    public static void clearSubjectivityStatus(List<Subjectivity__c> subjectivities, Map<Id, Subjectivity__c> oldDataMap, boolean isInsert ){
        Set<Id> subIds = new Set<Id>();
        List<Subjectivity__c> subList = new List<Subjectivity__c>();
        List<Subjectivity__c> subChangeList = new List<Subjectivity__c>();
        Boolean isUpdate = false;
        for(Subjectivity__c sub : subjectivities){
            subIds.add(sub.Id);
        }
        String queryFields = 'Id,Subjectivity_Status__c,Cleared__c,Cleared_Date__c,Quote__c, Quote__r.Product_Name__c';
        subList = SubjectivityQueryUtil.fetchSubjectivitiesForSubjectivityIds(subIds, queryFields);
        
        
        if(!subList.isEmpty()){
            for(Subjectivity__c sub:subList){
                if(sub.Quote__r.Product_Name__c != GlobalVariables.PROD_NAME_FOR_PI){
                    if( isInsert ){
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
                    GlobalStaticVar.byPassQuoteTrigger= true;
                    update subList;
                }
            } catch (Exception ex) {
                system.debug('ex-->'+ex.getLineNumber()+' '+ex.getMessage());
            }
            
        }        
    }
}
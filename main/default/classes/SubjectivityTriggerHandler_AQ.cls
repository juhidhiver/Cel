/**************************************************************************************************
 * Class Name: SubjectivityTriggerHandler_AQ
 * Author: 
 * Date: 
 * Description: handle Aqueous record Type logic
 **************************************************************************************************/
public class SubjectivityTriggerHandler_AQ extends TriggerHandler{
    private List<Subjectivity__c> oldDataList;
    private List<Subjectivity__c> newDataList;
    private Map<Id, Subjectivity__c> newDataMap;
    private Map<Id, Subjectivity__c> oldDataMap;
    
    public SubjectivityTriggerHandler_AQ(List<Subjectivity__c> newDataList, List<Subjectivity__c> oldDataList, 
                                           Map<Id, Subjectivity__c> newDataMap, Map<Id, Subjectivity__c> oldDataMap){
                                               this.oldDataList = oldDataList;
                                               this.newDataList = newDataList;
                                               this.newDataMap = newDataMap;
                                               this.oldDataMap = oldDataMap;
                                           }
    public static boolean checkProfile = True;
    
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
		CommonSubjectivityUtil.updateQuoteStatus(newDataList);
       
    }
    public override void afterupdate(){
        //update quote if status = Quoted to Rated
        CommonSubjectivityUtil.updateQuoteStatus(newDataList);
        
    }
    public override void afterdelete(){
        //update quote if status = Quoted to Rated
        CommonSubjectivityUtil.updateQuoteStatus(oldDataList);
    }
}